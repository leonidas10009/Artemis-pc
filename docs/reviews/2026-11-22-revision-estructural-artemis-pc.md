# Revisión estructural — Artemis PC 2026

> **Documento:** revisión técnica independiente (estática) del cliente Artemis PC 2026.
> **Fecha:** 2026-11-22
> **Commit revisado:** `c5ae0a0` (`main`)
> **Versión del producto:** `1.0.0` (revisión); las correcciones se publicaron en `1.1.0`
> **Base:** Moonlight Qt `6.2.0` (commit upstream `de2467e`)
> **Alcance:** código de `app/`, build qmake, CI de GitHub Actions, scripts de despliegue, WiX, documentación y artefactos de `Release/`.
> **Naturaleza:** revisión de arquitectura y calidad. **No se modificó código de producción**; este documento es el único artefacto generado.

---

## 1. Resumen ejecutivo

Artemis PC 2026 es un fork de Moonlight Qt 6.2.0 que funciona, compila y se distribuye con portable e instalador. La integración con Apollo (comandos de energía, pantalla virtual, portapapeles y permisos de entrada) está implementada y es coherente con la UI. La base de streaming, el pipeline de vídeo/audio y el endurecimiento del binario se conservan correctamente.

El producto, sin embargo, **todavía no tiene el nivel de ingeniería de un ciclo de releases profesional**. Los riesgos principales no son de funcionalidad visible sino de:

1. **Concurrencia y ciclo de vida** en la sincronización de portapapeles (posible uso después de liberar memoria y carreras de datos).
2. **Fiabilidad del modo portable**, que depende del directorio de trabajo y no del directorio del ejecutable.
3. **Ausencia total de pruebas automatizadas** y de CI en pull requests.
4. **Divergencia del upstream sin historial común**, lo que dificulta absorber correcciones de seguridad de Moonlight.
5. **Entrega sin firma ni verificación de integridad**, y **cumplimiento de licencias incompleto** en el portable.
6. **Validación incompleta de errores de aplicación** en los endpoints Apollo.

### Veredicto

**Nota global: 6,0 / 10.** Es un fork funcional, bien encaminado y con una UI cuidada, pero con deuda significativa en pruebas, aislamiento de la lógica Apollo, trazabilidad de releases y cumplimiento de distribución. No se identificó una vulnerabilidad crítica explotable en esta revisión estática; sí defectos de corrección y riesgos de memoria y de cadena de suministro que deben resolverse antes de escalar el proyecto.

### Top 7 riesgos

| # | Riesgo | Prioridad |
|---|---|---|
| 1 | Uso de `NvComputer*` sin sincronizar en hilos de portapapeles; posible UAF y carreras | P1 |
| 2 | Modo portable detectado con `QDir::currentPath()` en lugar de `applicationDirPath()` | P1 |
| 3 | Cero tests y CI que no compila en PRs; un commit roto puede etiquetarse y publicarse | P1 |
| 4 | Historial upstream eliminado; las correcciones de Moonlight no se pueden fusionar | P1 |
| 5 | Portable sin `LICENSE` ni avisos de terceros; obligaciones GPL/LGPL incompletas | P1 |
| 6 | Releases sin firma y sin `SHA256SUMS` publicado | P1 |
| 7 | Endpoints Apollo no validan `status_code` de aplicación (errores silenciosos) | P1 |

---

## 2. Alcance y método

### 2.1 Qué se revisó

- **Código:** 143 archivos, **34.642 líneas** en `app/` (30.667 en C/C++, 3.975 en 20 archivos QML).
- **Build:** `moonlight-qt.pro`, `globaldefs.pri`, `app/app.pro`, scripts `setup-deps.*`, `scripts/*.ps1`, `scripts/build-artemis.bat`.
- **CI/CD:** `.github/workflows/windows.yml`, cachés, permisos, publicación de artefactos.
- **Instalador:** WiX 7 (`wix/Moonlight/Product.wxs`, `wix/MoonlightSetup/Bundle.wxs`, `.wixproj`).
- **Entrega:** contenido del ZIP portable, MSI, bootstrapper, firmas Authenticode, hashes.
- **Documentación:** `README.md`, `MEMORIA_ARTEMIS_PC.md`, `LEEME.txt`, plantillas de issues, AppStream, `Info.plist`.
- **Git:** historia, ramas, submódulos, relación con `v6.2.0`.
- **Calidad QML:** `qmllint` de Qt 6.11.3 sobre las vistas principales.

### 2.2 Cómo se revisó

- Lectura estática de los módulos nuevos y de las zonas modificadas respecto a Moonlight.
- Verificación de artefactos: fechas, contenido del ZIP, hashes, firmas y versión de recurso del EXE.
- Comprobación de la historia de Git (`git rev-list`, `git merge-base`, `git log`).
- Ejecución de `qmllint` con las importaciones de Qt 6.11.3.
- Inspección del contenido del staging del instalador y del flujo de instalación/desinstalación definido en WiX.
- Búsqueda de secretos, cadenas heredadas, código muerto y constantes duplicadas.

### 2.3 Limitaciones

- **No se ejecutó streaming real** contra Apollo ni Sunshine; no hay host disponible en el entorno de revisión. Las conclusiones funcionales son por inspección y por el contrato del código.
- **No se probó el instalador en una VM limpia** ni una actualización mayor real.
- **No es una auditoría de seguridad formal** ni incluye fuzzing, análisis dinámico, pentesting de red o revisión de binarios de terceros.
- `qmllint` no resuelve los singletons C++ (`Theme`, `ComputerManager`, etc.), por lo que muchos avisos de “unqualified access” son falsos positivos y se han filtrado.

---

## 3. Arquitectura actual

### 3.1 Capas

```text
┌─────────────────────────────────────────────────────────────┐
│ QML                                                         │
│ main.qml · PcView · AppView · SettingsView · ThemeMenu      │
│ SidebarButton · StreamSegue · diálogos                      │
└──────────────────────────────┬──────────────────────────────┘
                               │ propiedades, señales, Q_INVOKABLE
┌──────────────────────────────▼──────────────────────────────┐
│ Modelos y singletons de UI                                  │
│ ComputerModel · AppModel · Theme · StreamingPreferences     │
│ SystemProperties · SdlGamepadKeyNavigation                  │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ Backend                                                     │
│ ComputerManager · NvComputer · NvHTTP · NvPairingManager    │
│ IdentityManager · BoxArtManager · AutoUpdateChecker         │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ Streaming                                                   │
│ Session · Input · Video (FFmpeg/D3D11VA/plvk) · Audio       │
│ Overlay · Bandwidth                                         │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ Núcleo y plataforma                                         │
│ moonlight-common-c · SDL2/SDL3-compat · FFmpeg · libplacebo │
│ OpenSSL · D3D11 · DXGI · AntiHooking (Detours)              │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Flujo principal

1. `ComputerManager` descubre hosts por mDNS o alta manual y los sondea en hilos.
2. `NvComputer` serializa el `serverinfo` y expone capacidades de Apollo.
3. `ComputerModel`/`AppModel` alimentan la UI.
4. `Session` negocia el stream, crea el decodificador y arranca `moonlight-common-c`.
5. `Session::exec()` gestiona el ciclo de vida; el renderizado y la entrada viven en SDL/FFmpeg.

### 3.3 Integración Apollo: dispersión actual

La lógica Apollo está repartida en cinco capas:

| Capa | Elemento | Responsabilidad |
|---|---|---|
| `NvComputer` | `isApolloHost`, `virtualDisplayCapable`, `serverPermission`, `serverCommands` | Parseo del `serverinfo` |
| `NvHTTP` | `execServerCmd`, `getClipboardText`, `setClipboardText`, `virtualDisplay` en `startApp` | Transporte |
| `ComputerManager` | `PendingServerCmdTask` | Ejecución en hilo |
| `Session` | `startClipboardSync`, `pollHostClipboard`, `sendLocalClipboard`, `validateLaunch` | Orquestación y polling |
| QML | `PcView` (regex de energía, permisos), `SettingsView` (toggles), `main.qml` (tema) | Presentación y parte de la regla de negocio |

Esto funciona, pero **no hay una capa que aísle el protocolo Apollo**. Un cambio de nombre de comando, un nuevo bit de permisos o un endpoint adicional obliga a tocar C++ y QML en varios sitios.

### 3.4 Evaluación arquitectónica

**Fortalezas**

- Separación razonable entre backend, streaming y UI, heredada de Moonlight.
- `Theme` como singleton QML con tokens JSON es una solución limpia y extensible.
- `StreamingPreferences` centraliza las preferencias y su persistencia.
- El pipeline de vídeo conserva la arquitectura de renderers de Moonlight, con soporte D3D11VA y libplacebo en Windows.

**Debilidades**

- `Session` es un “god object” de 2.236 líneas; la sincronización de portapapeles añade responsabilidades de red, timers, hilos y estado de UI.
- `NvHTTP` crece con endpoints Apollo sin una abstracción de dominio.
- La regla de negocio de energía está en QML (regex sobre nombres localizados).
- Las constantes de permisos (`0x1800`) están duplicadas en `ComputerModel` y `Session`.
- El código de plataformas no soportadas (Linux/macOS/SteamLink) sigue presente y aumenta la superficie de mantenimiento.

---

## 4. Métricas

| Métrica | Valor |
|---|---:|
| Archivos de código en `app/` | 143 |
| Líneas de código en `app/` | 34.642 |
| C/C++ | 30.667 líneas |
| QML | 3.975 líneas / 20 archivos |
| Archivos rastreados por Git | 337 |
| Commits en `main` | 7 |
| Tamaño de `.git` | 3,3 MB |
| Tests propios en `app/` | **0** |
| Traducciones | 30 `.ts` |
| Español (`qml_es.ts`) | 308/308 mensajes actuales, 0 sin traducir |
| Temas | 22 |
| Tokens por tema | 38 (10 usados por QML) |
| Ifdefs de plataforma en C/C++ | 137 |
| Usos de `QT_VERSION` | 28 (15 comprobaciones de Qt 5) |
| Portable | 100,8 MB / 1.409 archivos |
| ZIP portable | 38,2 MB |
| Instalador | 30,5 MB |
| Firmas Authenticode | EXE y setup: **NotSigned** |

### 4.1 Archivos más grandes

| Archivo | Líneas | Observación |
|---|---:|---|
| `app/streaming/session.cpp` | 2.236 | Incluye la lógica nueva de portapapeles; candidato a dividir |
| `app/streaming/video/ffmpeg.cpp` | 1.931 | Núcleo upstream; no tocar sin motivo |
| `app/streaming/video/ffmpeg-renderers/drm.cpp` | 1.830 | Linux; no se compila en Windows |
| `app/gui/SettingsView.qml` | 1.658 | 14 `GroupBox`; candidato a dividir |
| `app/streaming/video/ffmpeg-renderers/d3d11va.cpp` | 1.646 | Renderer Windows; estable |
| `app/streaming/video/ffmpeg-renderers/plvk.cpp` | 1.195 | Vulkan/libplacebo; estable |
| `app/main.cpp` | 940 | Arranque, logging, CLI y SDL |
| `app/backend/computermanager.cpp` | 890 | Polling y tareas |
| `app/gui/main.qml` | 729 | Shell, sidebar y menú de temas |

---

## 5. Hallazgos priorizados

### 5.1 P1 — Antes del próximo release

#### F-01. Los endpoints Apollo no validan el estado de aplicación

**Evidencia**

- `app/backend/nvhttp.cpp:251-263` — `execServerCmd()` envía el POST y registra la respuesta, pero **no llama a `verifyResponseStatus()`**.
- `app/backend/nvhttp.cpp:266-285` — `getClipboardText()` y `setClipboardText()` tampoco validan el `status_code` del cuerpo.
- `app/backend/nvhttp.cpp:392-428` — `verifyResponseStatus()` existe y se usa correctamente en `startApp()` y `quitApp()`, pero no en los endpoints Apollo.

**Impacto**

GameStream/Apollo codifica muchos errores de aplicación en un HTTP 200 con un XML `<root status_code="...">`. Sin validación:

- Un comando de energía denegado por permisos puede reportarse como exitoso en la UI.
- Un error de portapapeles puede devolverse como texto y terminar en el portapapeles local.
- Los fallos quedan solo en el log y son difíciles de diagnosticar.

No se afirma que todos los errores usen HTTP 200; los errores HTTP 4xx/5xx sí son detectados por `QNetworkReply::error()`. El riesgo es el patrón de error de aplicación dentro de una respuesta 200.

**Recomendación**

- Llamar a `verifyResponseStatus(response)` en `execServerCmd()`.
- Para portapapeles, validar explícitamente el estado HTTP y el tamaño del cuerpo; no interpretar un cuerpo de error como texto.
- Añadir pruebas con un `QNetworkAccessManager` simulado para 200/403/500 y para XML con `status_code` distinto de 200.

**Esfuerzo:** S · **Prioridad:** P1

---

#### F-02. Concurrencia y ciclo de vida en la sincronización de portapapeles

**Evidencia**

- `app/streaming/session.cpp:1838-1873` — `pollHostClipboard()` captura un `QPointer<Session>` y un `NvComputer*` crudo, y lanza un `QRunnable` en el pool global.
- `app/streaming/session.cpp:1890-1897` — `sendLocalClipboard()` hace lo mismo con `NvComputer*`.
- `app/backend/nvhttp.cpp:43-45` — el constructor `NvHTTP(NvComputer*)` lee `activeAddress`, `activeHttpsPort`, `serverCert` e `isNvidiaServerSoftware` **sin tomar el `QReadWriteLock`** de `NvComputer` (`app/backend/nvcomputer.h:124`).
- `app/backend/computermanager.cpp` actualiza esos campos en hilos de polling; `ComputerModel::deleteComputer()` puede destruir el `NvComputer`.

**Impacto**

- **Carrera de datos** sobre miembros no atómicos: comportamiento indefinido en C++.
- **Uso después de liberar** si el host se elimina mientras una petición de portapapeles sigue en vuelo.
- La comprobación `if (!session)` sobre un `QPointer` desde otro hilo **no es una sincronización segura**; `QPointer` no está diseñado para acceso concurrente.
- En el mejor caso, una petición se envía al host equivocado; en el peor, crash.

**Recomendación**

Crear una instantánea inmutable bajo lock y capturarla por valor:

```cpp
struct ConnectionSnapshot {
    NvAddress address;
    uint16_t httpsPort;
    QSslCertificate serverCert;
    bool useTrueUid;
};

ConnectionSnapshot snap;
{
    QReadLocker locker(&computer->lock);
    snap = { computer->activeAddress, computer->activeHttpsPort,
             computer->serverCert, !computer->isNvidiaServerSoftware };
}

QThreadPool::globalInstance()->start(QRunnable::create([session, snap] {
    NvHTTP http(snap.address, snap.httpsPort, snap.serverCert, snap.useTrueUid);
    // ...
}));
```

Además:

- No capturar `NvComputer*` en tareas de vida incierta.
- Cancelar o esperar las tareas al cerrar la sesión.
- Mantener el `QPointer` solo en el hilo GUI y usar `QMetaObject::invokeMethod` con contexto para el retorno.
- Añadir un test de estrés que elimine el host mientras hay polling.

**Esfuerzo:** M · **Prioridad:** P1

---

#### F-03. El modo portable depende del directorio de trabajo

**Evidencia**

- `app/main.cpp:436-439` — detecta `portable.dat` con `QDir::currentPath()` y configura `QSettings` con ese mismo directorio.
- `app/path.cpp:107-115` — `Path::initialize(true)` usa `QDir::currentPath()` para logs, caché, box art y qmlcache.

**Impacto**

Si el usuario lanza `Artemis.exe` desde otro directorio (acceso directo con “Iniciar en” distinto, script, terminal, lanzador de terceros), `portable.dat` no se encuentra:

- La configuración se va al registro de Windows o al perfil del usuario.
- Los logs/caché se escriben en un directorio inesperado.
- Si el directorio de trabajo es de solo lectura (p. ej. `System32`), fallan escrituras silenciosamente.
- El usuario cree que está en modo portable, pero no lo está.

**Recomendación**

Usar siempre `QCoreApplication::applicationDirPath()` para detectar `portable.dat` y para calcular las rutas portables. Añadir un helper `Path::isPortable()` y una prueba que lance el ejecutable desde `C:\` y desde un acceso directo.

**Esfuerzo:** S · **Prioridad:** P1

---

#### F-04. Sin pruebas automatizadas y CI sin compilación en PRs

**Evidencia**

- No hay archivos de test propios en `app/` (0 tests).
- `.github/workflows/windows.yml:3-7` — solo `workflow_dispatch` y tags `v*`; no hay `pull_request` ni `push` a `main`.
- El workflow compila solo Release (`nmake release`), sin `qmllint`, sin tests, sin build Debug.
- No hay `.clang-format`, `.editorconfig`, `SECURITY.md`, `CONTRIBUTING.md` ni `CHANGELOG.md`.

**Impacto**

- Cualquier refactor (especialmente los P1 anteriores) se valida solo manualmente.
- Un commit roto puede llegar a `main` y etiquetarse como release sin que CI lo detecte.
- No hay forma de verificar que los 22 temas, las preferencias o el clasificador de comandos sigan funcionando.

**Recomendación**

- Añadir `on: pull_request` y `push: branches: [main]` con build Debug y Release.
- Introducir tests con Qt Test (`QTEST_MAIN`) para:
  - `Theme`: carga de `themes.json`, 22 temas, 10 tokens obligatorios, orden y persistencia.
  - `StreamingPreferences`: defaults, guardado/recarga, idioma.
  - `AutoUpdateChecker::compareVersion` y parseo de tags.
  - Clasificación de comandos Apollo y máscara de permisos.
  - Validación de respuestas HTTP/XML con un `QNetworkAccessManager` simulado.
- Añadir `qmllint` con un `.qmllint.ini` y `QML_IMPORT_PATH`.
- Ejecutar `lrelease` en CI y fallar si un `.ts` no compila.
- Crear un target `make check` y exigirlo antes del release.

**Esfuerzo:** M/L · **Prioridad:** P1

---

#### F-05. Releases sin firma y sin verificación de integridad publicada

**Evidencia**

- `Get-AuthenticodeSignature` sobre `Release/ArtemisSetup-1.0.0-win64.exe` y `build/.../Artemis.exe`: **NotSigned**.
- `.github/workflows/windows.yml:83-90` — la release solo sube `Release/*.zip` y `Release/*.exe`.
- `MEMORIA_ARTEMIS_PC.md:40` afirma que el SHA-256 “se publica junto a cada asset”, pero no existe `SHA256SUMS` en `Release/` ni paso de generación en CI.
- El ZIP portable no incluye `LICENSE` (ver F-06).

**Impacto**

- SmartScreen y antivirus muestran advertencias; la adopción se resiente.
- El usuario no puede verificar que el binario descargado es el que produjo el proyecto.
- Un asset sustituido en la release no sería detectable.
- La afirmación de la memoria no se cumple de forma reproducible.

**Recomendación**

- Firmar `Artemis.exe`, el MSI y el bootstrapper con un certificado OV/EV; usar el hook `SIGN` que ya existe en los `.wixproj`.
- Generar en CI un `SHA256SUMS.txt` con todos los assets y un `BUILD_INFO.txt` con commit, Qt, MSVC y fecha.
- Publicar hashes en la release y enlazarlos desde el README.
- Opcional: firmar los hashes con minisign/GPG.
- Añadir atestación de procedencia (GitHub Artifact Attestations) si se quiere un nivel SLSA básico.

**Esfuerzo:** S (hashes) / M (certificado) · **Prioridad:** P1

---

#### F-06. Cumplimiento de licencias incompleto en la distribución

**Evidencia**

- El ZIP portable contiene `README.md`, `LEEME.txt` y `MEMORIA_ARTEMIS_PC.md`; **no contiene `LICENSE` ni avisos de terceros**.
- El bootstrapper muestra la GPL en `wix/MoonlightSetup/license.rtf`, pero los archivos instalados no incluyen el texto de licencia.
- El portable y el MSI incluyen Qt, FFmpeg, OpenSSL, SDL2/SDL3-compat, libplacebo, dav1d, Opus y Discord RPC, sin `THIRD_PARTY_NOTICES`.
- El proyecto es GPL-3.0; la distribución de binarios exige el texto de la licencia y la correspondiente fuente.

**Impacto**

- Riesgo de incumplimiento GPL/LGPL y de las licencias de terceros.
- Un usuario o distribuidor no puede conocer sus derechos ni las obligaciones del proyecto.
- Si se publica en GitHub Releases, la obligación de “corresponding source” debe estar explícita.

**Recomendación**

- Incluir `LICENSE` en el ZIP y en el MSI.
- Añadir `THIRD_PARTY_NOTICES.md` con versión, licencia y enlace de cada dependencia.
- Incluir el texto de GPL/LGPL de Qt y FFmpeg/libplacebo según corresponda.
- Añadir un diálogo “Acerca de → Licencias” en la app.
- Enlazar la fuente exacta (tag/commit) desde la release.
- Automatizar una comprobación en CI que verifique que `LICENSE` y `THIRD_PARTY_NOTICES.md` están en el portable.

**Esfuerzo:** S/M · **Prioridad:** P1

---

#### F-07. Historial upstream eliminado y sin estrategia de sincronización

**Evidencia**

- `git rev-list --count HEAD` = **7**.
- El commit inicial `99a218e` es un commit raíz (sin padres).
- `git merge-base HEAD v6.2.0` no devuelve nada; no hay ancestro común con el tag upstream.
- `MEMORIA_ARTEMIS_PC.md:380` lo confirma: “commit inicial limpio (sin historial de Moonlight)”.
- El remoto `upstream` existe y el tag `v6.2.0` está disponible localmente.

**Impacto**

- No se pueden fusionar correcciones de seguridad de Moonlight con un `merge` normal.
- No se puede usar `git bisect` contra la base upstream.
- La atribución y la trazabilidad de cambios son débiles.
- Cada actualización de Moonlight exige un diff manual y propenso a errores.

**Recomendación**

- Crear una rama `vendor/upstream` desde `v6.2.0` y aplicar los cambios Artemis como commits encima, aunque sea con `git replace`/graft o un rebase inicial.
- Alternativa pragmática: mantener una serie de parches (`git format-patch v6.2.0..main`) y un documento `UPSTREAM.md` con el procedimiento de sincronización.
- Documentar en `README`/`CONTRIBUTING` cómo absorber un nuevo tag de Moonlight y cómo ejecutar la suite de pruebas.
- Suscribirse a los avisos de seguridad/CVE de Moonlight.

**Esfuerzo:** M/L · **Prioridad:** P1

---

### 5.2 P2 — Próximas 1-2 releases

#### F-08. Integración Apollo sin capa de dominio

**Evidencia**

- `app/backend/nvcomputer.h:103-107` — campos Apollo mezclados con el estado del host.
- `app/backend/nvhttp.h:184-190` — endpoints Apollo añadidos al transporte.
- `app/gui/computermodel.cpp:97-99` y `app/streaming/session.cpp:1006-1007` — máscara `0x1800` duplicada.
- `app/gui/PcView.qml:142-149` — clasificación de comandos por regex.

**Impacto**

- Cambios de protocolo dispersos; difícil testear.
- Heurística `isApolloHost` (`nvcomputer.cpp:225-227`) puede clasificar como Apollo un Sunshine que exponga uno de esos campos.
- La UI y el streaming pueden discrepar en la interpretación de permisos.

**Recomendación**

- Crear `apollo/ApolloCapabilities` (parseo y constantes) y `apollo/ApolloClient` (servercmd, clipboard, virtual display) sobre `NvHTTP`.
- Definir `enum Permission : quint32 { Mouse = 0x800, Keyboard = 0x1000 }` en un único sitio.
- Exponer a QML un modelo de comandos ya clasificado, no una lista de strings.
- Añadir tests de parseo con `serverinfo` de Apollo y Sunshine.

**Esfuerzo:** M/L · **Prioridad:** P2

---

#### F-09. Comandos de energía por regex y por índice

**Evidencia**

- `app/gui/PcView.qml:142-149` — `isPowerCommand()` busca `apagar|shutdown|poweroff|...` en el nombre.
- `app/gui/PcView.qml:280-295` — `Repeater` sobre `apolloCommands` y envío por `commandIndex`.
- `app/gui/computermodel.cpp:240-246` — traduce `computerIndex` a `NvComputer*` en el momento de ejecutar.

**Impacto**

- Comandos con nombres en otro idioma o personalizados no aparecen.
- “cancel” puede coincidir con comandos que no son de apagado.
- Si la lista de hosts o de comandos cambia mientras el diálogo está abierto, se puede ejecutar un comando en el host equivocado. Es una acción destructiva.
- La lógica de negocio vive en QML, difícil de testear.

**Recomendación**

- Mostrar **todos** los comandos del servidor bajo un submenú “Comandos del host”, con icono y confirmación para los destructivos.
- Usar un identificador estable (UUID del host + índice/nombre del comando) y resolverlo al confirmar, verificando que sigue existiendo.
- Si Apollo expone un tipo/código de comando, usarlo; si no, permitir una tabla de mapeo configurable y no un regex hardcodeado.
- Mover la clasificación a C++ y testearla.

**Esfuerzo:** M · **Prioridad:** P2

---

#### F-10. QML monolítico y duplicación

**Evidencia**

- `SettingsView.qml`: 1.658 líneas, 14 `GroupBox`, 7 títulos con HTML `<font color=...>`.
- `main.qml`: 729 líneas; los bloques de temas oscuros y claros son casi idénticos (`624-737`).
- `PcView.qml`: 470 líneas; incluye tarjeta, menú contextual, diálogos y regex.
- `AppView.qml`: 387 líneas.

**Impacto**

- Difícil de revisar, testear y mergear.
- Las vinculaciones y la navegación por teclado/gamepad son frágiles.
- La duplicación de temas invita a divergencias.

**Recomendación**

- Dividir `SettingsView` en `sections/BasicSettings.qml`, `AudioSettings.qml`, `HostSettings.qml`, `UiSettings.qml`, `InputSettings.qml`, `GamepadSettings.qml`, `AdvancedSettings.qml`.
- Extraer de `main.qml`: `Sidebar.qml`, `ThemeMenu.qml`, `AppToolbar.qml`, `StatusBar.qml`.
- Extraer `PcCard.qml`, `PcContextMenu.qml`, `AppCard.qml`.
- Un único `ThemeList`/`ThemeSelector` para oscuros y claros.
- Sustituir los títulos HTML por un `Label` con color de tema.

**Esfuerzo:** L · **Prioridad:** P2

---

#### F-11. Portapapeles: rendimiento, límites y diagnóstico

**Evidencia**

- `app/streaming/session.cpp:1792-1795` — polling cada 1.500 ms durante todo el stream.
- `app/streaming/session.cpp:1843` y `1892` — se crea un `NvHTTP` (y su `QNetworkAccessManager`) por cada petición.
- `app/streaming/session.cpp:1883` — límite de 256 KB solo para el envío local; **no hay límite para el texto recibido** (`1860-1870`).
- `app/streaming/session.cpp:1845-1847` y `1894-1896` — `catch (...)` vacío; los fallos no se registran.
- `app/streaming/session.cpp:1887` — se actualiza `m_LastHostClipboard` antes de que el POST tenga éxito.

**Impacto**

- Tráfico y consumo constantes aunque el portapapeles no cambie.
- Un host malicioso o con un portapapeles enorme puede congelar la UI al hacer `setText`.
- Los fallos son invisibles; difícil saber por qué no sincroniza.
- Un envío fallido puede impedir reintentos hasta que cambie el texto local.

**Recomendación**

- Reutilizar un cliente/QNAM persistente y aplicar backoff adaptativo; pausar el polling cuando la ventana no tiene foco.
- Limitar el tamaño entrante (p. ej. 256 KB) y validar UTF-8.
- Registrar fallos con `qWarning()` limitado por tasa.
- Separar `m_LastLocalClipboard` y `m_LastRemoteClipboard`; actualizar el estado remoto solo tras un POST exitoso.
- Considerar un canal de eventos del host si Apollo lo ofrece.

**Esfuerzo:** M · **Prioridad:** P2

---

#### F-12. Geometría de ventana y restauración

**Evidencia**

- `app/gui/main.qml:110-114` — guarda `window.width/height` incluso maximizada.
- `app/backend/systemproperties.cpp:282-303` — persiste solo x/y/width/height/maximized.
- `main.qml:49-61` — `isGeometryOnScreen()` acepta cualquier intersección, aunque sea de 1 px.

**Impacto**

- Tras maximizar, cerrar y reabrir, el tamaño “normal” puede quedar igual al maximizado; al desmaximizar, la ventana puede ocupar toda la pantalla.
- Una ventana casi fuera de pantalla se considera válida.
- Cambios de DPI/monitor pueden dejar la ventana en una posición incómoda.

**Recomendación**

- Guardar `normalGeometry` y `windowState`; al restaurar, aplicar la geometría normal y luego el estado.
- Validar contra `QScreen::availableGeometry()` con un margen mínimo visible.
- Limitar width/height a valores positivos y al mínimo de la ventana.

**Esfuerzo:** S · **Prioridad:** P2

---

#### F-13. Traducciones: `.qm` versionados y sin `lrelease` en build

**Evidencia**

- `app/app.pro:458-488` declara `TRANSLATIONS`, pero no hay `CONFIG += lrelease`.
- `app/resources.qrc` incluye tanto `.ts` como `.qm`.
- `app/settings/streamingpreferences.cpp:227` carga `:/languages/qml_<sufijo>`.
- Los `.qm` están versionados y se regeneran manualmente (p. ej. `qml_es.qm` cambió en `f525590`).

**Impacto**

- Editar un `.ts` no actualiza la app salvo que alguien ejecute `lrelease` y commitice el binario.
- Los `.ts` se embeben en el ejecutable sin necesidad, aumentando el tamaño.
- Es fácil publicar una traducción desincronizada.

**Recomendación**

- Añadir `CONFIG += lrelease` y generar los `.qm` en el build; o usar `qt_add_translations`/`embed_translations`.
- Sacar los `.ts` de `resources.qrc`; embeber solo los `.qm`.
- Añadir una comprobación de CI que falle si `lrelease` no puede compilar un `.ts`.
- Documentar el flujo de traducción (Weblate/Crowdin o `lupdate`).

**Esfuerzo:** S · **Prioridad:** P2

---

#### F-14. Cadena de suministro sin verificación de hashes

**Evidencia**

- `setup-deps.ps1:16-28` descarga `windows-x64.zip` y `windows-ARM64.zip` del tag `v19` y los extrae sin verificar SHA-256.
- `scripts/install-qt-ci.ps1` descarga archivos de Qt desde `download.qt.io` sin checksum.
- `.github/workflows/windows.yml:23-33` cachea Qt y `libs/windows` con claves estáticas (`v1`, `moonlight-deps-v19`).

**Impacto**

- Un asset comprometido o un cache envenenado puede introducir código en el binario.
- Los builds no son reproducibles ni auditables.
- Un cambio en el contenido con la misma clave de caché no se detecta.

**Recomendación**

- Fijar SHA-256 de cada archivo descargado y verificarlo antes de extraer.
- Incluir el hash del script/versión en la clave de caché.
- Generar un SBOM (CycloneDX/SPDX) con las versiones de Qt, FFmpeg, OpenSSL, SDL y libplacebo.
- Usar Dependabot/Renovate para acciones y submódulos, o un proceso manual documentado.

**Esfuerzo:** S/M · **Prioridad:** P2

---

#### F-15. Endurecimiento de CI

**Evidencia**

- `.github/workflows/windows.yml:9-10` — `permissions: contents: write` para todo el workflow.
- Acciones fijadas por tag (`actions/checkout@v4`, `softprops/action-gh-release@v2`, `ilammy/msvc-dev-cmd@v1`), no por SHA.
- No hay `concurrency`, ni entorno protegido, ni build en PR.
- La release se publica desde el mismo job que compila.

**Impacto**

- Una acción comprometida puede escribir en el repositorio.
- No hay separación entre “compilar” y “publicar”.
- builds duplicados/obsoletos pueden pisar artefactos.

**Recomendación**

- `permissions: contents: read` por defecto; `contents: write` solo en el job de release.
- Fijar acciones a SHA completo y actualizarlas con Dependabot.
- Usar `environment: release` con aprobación y `concurrency`.
- Separar jobs: `build` (PR/push) y `release` (tag, depende de `build`).
- Añadir `timeout-minutes` por job y retención de artefactos.

**Esfuerzo:** S · **Prioridad:** P2

---

#### F-16. Instalador: runtime VC++ y limpieza en upgrades

**Evidencia**

- `scripts/deploy-artemis.ps1:38-48` copia `msvcp140*.dll`, `vcruntime140*.dll` y `concrt140.dll` desde `%SystemRoot%\System32`.
- `wix/Moonlight/Product.wxs:44-46` — `util:RemoveFolderEx` sobre `%LOCALAPPDATA%\Artemis 2026 Project` sin condición de upgrade.
- `wix/MoonlightSetup/Bundle.wxs:38-46` define búsquedas y variables de VCRedist, pero la cadena (`58-68`) solo instala el MSI.

**Impacto**

- Copiar el runtime desde `System32` no es el origen soportado; puede mezclar versiones y fallar en equipos limpios.
- En una actualización mayor, la limpieza puede borrar caché/logs de la versión anterior (y potencialmente datos de usuario si en el futuro se mueven ahí).
- Las definiciones de VCRedist son código muerto y confunden el mantenimiento.

**Recomendación**

- Usar `windeployqt --compiler-runtime` o los merge modules oficiales `Microsoft.VC143.CRT`; no copiar desde `System32`.
- Condicionar la limpieza a `NOT UPGRADINGPRODUCTCODE` o eliminarla y dejar que el usuario limpie.
- Eliminar las definiciones de VCRedist no usadas o añadir el paquete a la cadena.
- Probar install → upgrade → uninstall en una VM limpia de Windows 10 y 11.

**Esfuerzo:** M · **Prioridad:** P2

---

#### F-17. Metadatos y plantillas heredadas de Moonlight

**Evidencia**

- `.github/ISSUE_TEMPLATE/bug_report.md` pide logs de `Moonlight-###.log`, versión de Moonlight, Discord de Moonlight y tipo de paquete Linux.
- `.github/auto-comment.yml`, `no-response.yml` y `stale.yml` siguen apuntando a Moonlight/Discord.
- `app/deploy/linux/com.leonidas10009.Artemis.appdata.xml` anuncia la versión **6.2.0** y capturas en `appstream_resources/` que no existen.
- `app/Info.plist` tiene `NSAllowsArbitraryLoads=true` (ATS desactivado).

**Impacto**

- Los usuarios reportan con datos incorrectos; el soporte se degrada.
- La metadata de Linux anuncia una versión que no es la del producto y enlaces rotos.
- Si algún día se compila macOS, la app queda con ATS desactivado, una práctica insegura.

**Recomendación**

- Reescribir las plantillas para Artemis: logs en `%TEMP%\Artemis-*.log` o en la carpeta portable, versión de Apollo, permisos, si es Apollo o Sunshine.
- Eliminar los configs de Probot que no se usen.
- Actualizar AppStream a 1.0.0 y a capturas reales, o eliminar el empaquetado Linux si no es un objetivo.
- Eliminar `NSAllowsArbitraryLoads` o restringirlo a dominios locales.

**Esfuerzo:** S · **Prioridad:** P2

---

### 5.3 P3 — Deuda técnica y limpieza

| ID | Hallazgo | Evidencia | Recomendación |
|---|---|---|---|
| F-18 | Residuos de marca Moonlight | `moonlight-qt.pro`, `app/Moonlight.exe.manifest`, `moonlight.ico/icns/wix.png`, `wix/Moonlight*`, `app/deploy/linux/com.moonlight_stream.*`, `app/res/moonlight.svg`, `app/deploy/steamlink/moonlight.*`, `app/qt_qt5.conf` | Renombrar a Artemis o eliminar lo no usado. El proyecto raíz debería llamarse `artemis-pc.pro`. |
| F-19 | Código muerto | `Theme::keyForIndex` sin usos; `Session::handleClipboardFromHost` sin llamadas; `filterText` sin uso en QML | Eliminar o conectar; si el filtrado es “para el futuro”, documentarlo y testearlo. |
| F-20 | Constantes y listas duplicadas | `0x1800` en `ComputerModel` y `Session`; orden de temas en `theme.cpp:115-123` y en `README` | Una sola fuente (enum/JSON con metadatos `order`/`group`). |
| F-21 | Avisos de layout QML | `main.qml:210,242,269` (`height` en `ColumnLayout`), `651-652`, `713-714` (`width/height` en `RowLayout`) | Usar `Layout.preferredHeight`, `Layout.preferredWidth`, `implicitWidth/Height`. |
| F-22 | Índices QML sin validación en release | `computermodel.cpp:201-254` usa `Q_ASSERT(computer != nullptr)` y luego desreferencia; `NDEBUG` desactiva el assert | Devolver error/booleano y comprobar `nullptr` en runtime; usar UUID en lugar de índices. |
| F-23 | Nombres de temas no traducibles | `Theme::displayName()` devuelve el `label` de `themes.json` (español) sin `qsTr` | Usar claves i18n o nombres neutros; añadir los labels a los `.ts`. |
| F-24 | ComboBox de tema desincronizado | `SettingsView.qml:1070-1091` solo fija `currentIndex` en `Component.onCompleted` | Enlazar `currentIndex` a `Theme.name` o reaccionar a `Theme.themeChanged`. |
| F-25 | Mensajes y enlaces heredados | `PcView.qml:332` habla de GeForce Experience; `main.qml:745,753,771` y `NavigableMessageDialog.qml:13` enlazan a docs de Moonlight | Reescribir para Apollo/Artemis y enlazar a la documentación propia. |
| F-26 | Dependencia de infraestructura Moonlight | `session.cpp:51`, `computermanager.cpp:853,934` usan `*.moonlight-stream.org` | Documentarlo; permitir configuración o alojar endpoints propios. |
| F-27 | Sin observabilidad de soporte | No hay botón “Abrir logs”, no hay minidumps, `catch (...)` vacíos | Añadir “Abrir logs”, cabecera de build en el log y avisos limitados. |
| F-28 | Accesibilidad parcial | 78 `font.pointSize`, botones solo-icono sin `Accessible.name`, sin auditoría de contraste en 22 temas | Añadir nombres accesibles, foco visible y pruebas de contraste. |
| F-29 | Alcance de plataforma difuso | `app.pro` compila Linux/macOS/SteamLink; README dice Windows; CI solo Windows; 137 ifdefs | Decidir: Windows-only y podar, o soportar otras plataformas con CI y docs. |
| F-30 | Sin CMake | Build qmake de la app, aunque Qt recomienda CMake | Evaluar migración a CMake a medio plazo; no urgente mientras qmake funcione. |
| F-31 | Sin SBOM ni inventario de dependencias | No hay `sbom`, `NOTICE` ni manifiesto de versiones | Generar CycloneDX/SPDX y publicarlo con la release. |
| F-32 | Sin `SECURITY.md`/`CONTRIBUTING.md`/`CHANGELOG.md` | Confirmado en la raíz | Añadir políticas y guía de contribución; enlazar desde README. |
| F-33 | Documentación con rutas locales | `README.md:146`, `MEMORIA` con `E:\...` y VS 2026 | Usar placeholders y mover la memoria técnica a `docs/development/`; no incluirla en el portable. |
| F-34 | Instalador y MSI sin probar en VM limpia | No hay job de instalación/desinstalación/upgrade | Añadir prueba manual o automatizada con Windows Sandbox/VM. |

---

## 6. Seguridad

### 6.1 Lo que está bien

- **TLS con certificate pinning** en `NvHTTP::handleSslErrors()`: solo ignora errores si el certificado coincide con el fijado (`nvhttp.cpp:497-517`).
- **Endurecimiento del binario**: `/DYNAMICBASE`, `/NXCOMPAT`, `/guard:cf`, `/guard:ehcont`, `/cetcompat`, `/permissive-`, `/utf-8`, `/MD`, `/OPT:REF`, `/OPT:ICF` (`globaldefs.pri`, `Makefile.Release`).
- **Redacción de claves de sesión** (`rikey`, `rikeyid`) en el logger (`main.cpp:132-134`).
- **Portapapeles y pantalla virtual opt-in** (por defecto `false`), con avisos si el host no es Apollo.
- **Confirmación de comandos destructivos** en `powerCmdDialog` (Sí/No).
- **Actualizador que solo abre el navegador**, no descarga ni ejecuta binarios.
- **Sin secretos evidentes** en el código revisado; el certificado/clave del cliente se generan localmente.

### 6.2 Riesgos y recomendaciones

| Riesgo | Detalle | Mitigación |
|---|---|---|
| Firma ausente | EXE/setup `NotSigned` | Certificado OV/EV y firma en CI |
| Integridad | Sin `SHA256SUMS` publicado | Generar y publicar hashes; firmarlos |
| Cadena de suministro | Descargas sin hash, caches estáticas | Verificar SHA-256 y SBOM |
| Portapapeles | Puede transportar contraseñas; polling constante | Opt-in (ya), límite de tamaño, no loguear contenido, backoff |
| Hilos | UAF/carreras en tareas de portapapeles | Snapshot inmutable y cancelación |
| macOS | ATS desactivado en `Info.plist` | Eliminar `NSAllowsArbitraryLoads` si se soporta macOS |
| AntiHooking | DLL con hooks de Detours; posible falso positivo de AV | Firmar, documentar, permitir desactivarlo |
| Logs | Guardan URLs y respuestas; `rikey` redactado, pero no todo | Revisar qué se registra; no loguear cuerpos de portapapeles |

### 6.3 Privacidad

- El chequeo de actualizaciones contacta `api.github.com` en cada arranque, sin opción de desactivarlo. Es aceptable, pero debe documentarse y ofrecer un toggle.
- El test de red y STUN usan infraestructura de Moonlight (`qt.conntest.moonlight-stream.org`, `stun.moonlight-stream.org`). Para un fork Apollo, conviene documentarlo o usar endpoints propios.
- No hay telemetría ni analytics; es un punto positivo.

---

## 7. Build, CI/CD y distribución

### 7.1 Build

- **qmake** con `CONFIG += c++17`, coherente con Moonlight. Qt 6.11.3 MSVC 2022 x64.
- `qtquickcompiler` en Release para Windows/macOS; correcto para evitar qmlcache en portable.
- `globaldefs.pri` aplica hardening solo a MSVC; correcto para el objetivo Windows.
- `setup-deps.ps1` descarga dependencias precompiladas de `moonlight-qt-deps` v19. **Sin hashes.**
- `setup-deps.py` solo soporta macOS/Linux y descarga SteamLink/mac; no se usa en Windows.
- `scripts/build-artemis.bat` hardcodea `E:\Qt\6.11.3` y VS 2026; útil para el autor, no portable para otros.
- `scripts/deploy-artemis.ps1` y `build-installer.ps1` funcionan y generan ZIP/MSI/EXE.
- **No hay CMake** para la app; no es un bloqueo, pero es deuda a medio plazo.

### 7.2 CI

- Un solo job en `windows-2025`; `workflow_dispatch` y tags `v*`.
- Cachea Qt y `libs/windows`; claves estáticas.
- Compila Release, despliega portable y genera instalador.
- Sube artefactos y publica release en tags.
- **No compila PRs**, no ejecuta tests, no hace `qmllint`, no firma, no genera hashes.
- **Permisos excesivos** (`contents: write` global) y acciones por tag.

### 7.3 Instalador

- WiX 7, MSI x64 + bootstrapper.
- Instala en `Program Files\Artemis 2026`, crea accesos directos, permite desinstalar.
- `Version` del MSI se enlaza al file version del EXE; correcto.
- `MajorUpgrade` configurado.
- El MSI cosecha todos los archivos de `dist\ArtemisPortable` menos EXE/docs/marcador portable.
- **Riesgos**: runtime VC++ desde `System32`, `RemoveFolderEx` en upgrades, VCRedist definido pero no instalado, sin firma, sin prueba en VM limpia.
- **Fortaleza**: el flujo portable/instalador está separado y automatizado; el instalador incluye icono, licencia y condiciones de Windows 10/11 x64.

### 7.4 Versionado y trazabilidad

- `app/version.txt` es la fuente única para el EXE, el ZIP y el instalador; bien.
- `README`, `MEMORIA` y `LEEME` hardcodean `1.0.0`; se desincronizarán.
- No hay commit SHA, fecha de build ni versión de Qt/MSVC en el binario o en un `BUILD_INFO.txt`.
- Los artefactos actuales son coherentes entre sí (mismo hash del EXE en ZIP y `dist`), pero no se puede demostrar qué commit exacto los produjo.

---

## 8. Calidad de código

### 8.1 C++

**Fortalezas**

- Estilo consistente con Moonlight; RAII y smart pointers en la mayoría del código upstream.
- `QReadWriteLock` en `NvComputer` para el estado compartido.
- Uso de `QPointer` en algunos callbacks, aunque no en los nuevos hilos.
- Separación clara de renderers y decodificadores.

**Debilidades**

- `Session` y `NvHTTP` crecen sin límites; la lógica Apollo aumenta su responsabilidad.
- `catch (...)` vacíos en el camino de portapapeles.
- `Q_ASSERT` como validación de entrada en `ComputerModel` (se compila fuera en Release).
- Constantes mágicas (`0x1800`, intervalos de 1.500/350 ms, 256 KB) sin nombres.
- Uso de `delete reply` manual en `openConnectionToString`; correcto pero frágil ante futuras excepciones.
- `NvHTTP` lee `NvComputer` sin lock en el constructor usado por tareas nuevas.

**Recomendación**

- Extraer `ClipboardSyncController` y `ApolloClient`.
- Introducir un `Result<T>`/`expected` para los endpoints Apollo en lugar de excepciones + retorno de texto.
- Sustituir `catch (...)` por capturas concretas y logging.
- Convertir constantes en `constexpr` con nombre.
- Añadir `Q_DISABLE_COPY` donde aplique y revisiones de ownership.

### 8.2 QML

**Fortalezas**

- UI coherente, temas consistentes, navegación por teclado/gamepad presente.
- `Theme` centraliza colores y modos claro/oscuro.
- Uso de `Navigable*` reutilizables.

**Debilidades**

- Vistas monolíticas (Settings 1.658 líneas).
- Duplicación de bloques de temas.
- Reglas de negocio en QML (regex de energía).
- Avisos de layout (`width`/`height` en layouts).
- Imports versionados antiguos (`QtQuick 2.9`, `Controls 2.2`).
- Mezcla de HTML en títulos (`<font color=...>`).
- Accesibilidad parcial.

**Recomendación**

- Modernizar imports a `import QtQuick`, `import QtQuick.Controls`, etc. (Qt 6.11 no necesita versiones).
- Extraer componentes y usar `Layout.*`.
- Añadir `qmllint` con configuración y resolver avisos reales.
- Unificar el selector de temas.
- Añadir `Accessible.name` a botones icono.

### 8.3 i18n

- 30 `.ts`, español completo (308/308 actuales).
- Los temas tienen nombres en español no traducibles.
- Varias cadenas siguen mencionando Moonlight/GFE.
- Los `.qm` se versionan y no se regeneran en build.
- Los `.ts` se embeben en el recurso, innecesariamente.

---

## 9. Pruebas

### 9.1 Estado actual

**No hay pruebas automatizadas propias.** Los únicos tests del árbol son los de `qmdnsengine` (submódulo) y los compile-tests de `config.tests` (EGL/SL), que no cubren la app.

### 9.2 Plan mínimo recomendado

| Nivel | Qué probar | Herramienta | Prioridad |
|---|---|---|---|
| Unitario | `Theme`: carga, 22 temas, tokens, orden, persistencia | Qt Test | P1 |
| Unitario | `StreamingPreferences`: defaults, save/reload, idioma | Qt Test | P1 |
| Unitario | `AutoUpdateChecker`: parseo y comparación de versiones | Qt Test | P2 |
| Unitario | Permisos Apollo (`0x1800`) y clasificación de comandos | Qt Test | P1 |
| Unitario | `verifyResponseStatus` y errores de clipboard con QNAM simulado | Qt Test | P1 |
| Integración | `ClipboardSyncController` con un host falso (HTTP local) | Qt Test + QTcpServer | P2 |
| QML | Selección de tema, ComboBox, diálogo de energía, navegación | `qmltestrunner` | P2 |
| Manual | Stream real Apollo: energía, portapapeles, pantalla virtual, permisos | Checklist | P1 |
| Manual | Instalación/upgrade/uninstall en Windows 10/11 limpio | VM/Sandbox | P1 |
| Manual | Portable desde otro directorio y desde acceso directo | Checklist | P1 |

### 9.3 Puertas de CI propuestas

1. `build-debug` y `build-release` en cada PR.
2. `qmllint` sobre `app/gui/*.qml`.
3. `lrelease` sobre todos los `.ts`.
4. Tests unitarios (`make check`).
5. `clang-tidy`/`clazy` opcional sobre archivos nuevos.
6. `release` solo en tag, dependiente de todos los anteriores, con firma y hashes.

---

## 10. Documentación, i18n y licencias

### 10.1 Documentación

**Fortalezas**

- `README.md` y `MEMORIA_ARTEMIS_PC.md` son detallados y explican la compilación, el despliegue y las funciones Apollo.
- Atribución a Moonlight, Apollo y el fork Android.
- `LEEME.txt` útil para el usuario final.

**Debilidades**

- README en español únicamente; para un repo público conviene una versión en inglés o bilingüe.
- Rutas locales absolutas (`E:\...`) y versiones de VS/Qt en la documentación de build.
- `MEMORIA` es un documento de desarrollo, no de usuario; se incluye en el portable.
- Afirmaciones no automatizadas: “SHA-256 se publica”, “CI verificada”.
- No hay `CHANGELOG`, `SECURITY`, `CONTRIBUTING` ni guía de arquitectura.
- Plantillas de issues heredadas de Moonlight.

### 10.2 i18n

- El español está completo y las cadenas nuevas están traducidas.
- Los nombres de temas no pasan por `qsTr`.
- Varias traducciones están incompletas (28 idiomas con ~251 mensajes; español con 308). Es esperable, pero conviene un flujo de traducción y no versionar `.qm` a mano.
- El instalador está en inglés (WiX `Language=1033`); si el público es español, valorar localizarlo.

### 10.3 Licencias

- `LICENSE` GPL-3.0 en la raíz; correcto.
- Falta en el portable y en los archivos instalados.
- No hay avisos de terceros.
- El bootstrapper muestra GPL; insuficiente para el ZIP portable.
- Añadir `THIRD_PARTY_NOTICES.md`, textos de Qt/FFmpeg/libplacebo/OpenSSL/SDL/Discord RPC y enlace a la fuente.

---

## 11. Plan de acción

### 11.1 Quick wins (24-48 h)

| Acción | Impacto | Esfuerzo |
|---|---|---|
| Corregir `portable.dat` y rutas portables con `applicationDirPath()` | Alto | S |
| Validar `verifyResponseStatus()` en `servercmd` y clipboard | Alto | S |
| Incluir `LICENSE` y `THIRD_PARTY_NOTICES.md` en el portable/MSI | Alto | S |
| Generar `SHA256SUMS.txt` y `BUILD_INFO.txt` en CI | Alto | S |
| Añadir `pull_request` y `push` a `main` al workflow | Alto | S |
| Añadir `qmllint` y `lrelease` al CI | Medio | S |
| Corregir avisos de layout de `main.qml` | Bajo | S |

### 11.2 Semanas 1-2

| Acción | Impacto | Esfuerzo |
|---|---|---|
| Snapshot inmutable de conexión y eliminar `NvComputer*` de los hilos | Alto | M |
| Tests unitarios de Theme, preferencias, permisos y versiones | Alto | M |
| Plantillas de issues y `SECURITY.md`/`CONTRIBUTING.md` | Medio | S |
| Sincronizar ComboBox de tema y catálogo desde JSON | Medio | S |
| Revisar `RemoveFolderEx` y runtime VC++ | Medio | M |
| Probar install/upgrade/uninstall en VM limpia | Alto | M |

### 11.3 30 días

| Acción | Impacto | Esfuerzo |
|---|---|---|
| `ApolloClient` + `ApolloCapabilities` + `ClipboardSyncController` | Alto | L |
| Comandos de energía con IDs estables y todos los comandos | Alto | M |
| Dividir `SettingsView`, `main.qml`, `PcView` | Medio | L |
| Verificación SHA-256 de dependencias y SBOM | Alto | M |
| Endurecer CI (permisos, SHA de acciones, entorno de release) | Medio | S |
| Firmar binarios o, como mínimo, hashes | Alto | M |
| Documentar política de sincronización upstream | Alto | M |

### 11.4 60-90 días

| Acción | Impacto | Esfuerzo |
|---|---|---|
| Crear rama vendor/upstream y absorber correcciones | Alto | L |
| Decidir alcance Windows-only vs multiplataforma y podar | Medio | L |
| Migración a CMake (evaluación) | Medio | L |
| Accesibilidad y contraste de los 22 temas | Medio | M |
| Limpieza de marca Moonlight y archivos muertos | Bajo | S |
| Crash reporting/minidumps opcional | Medio | M |
| AppStream/paquetes Linux o retirada definitiva | Bajo | S |

---

## 12. Checklist de release

- [ ] `git status` limpio y tag `vX.Y.Z` creado sobre el commit revisado.
- [ ] CI verde en el commit del tag (build Debug + Release + tests + qmllint + lrelease).
- [ ] `app/version.txt`, README, LEEME y MEMORIA con la misma versión.
- [ ] `LICENSE` y `THIRD_PARTY_NOTICES.md` dentro del ZIP y del MSI.
- [ ] `SHA256SUMS.txt` y `BUILD_INFO.txt` generados y publicados.
- [ ] EXE, MSI y setup firmados (o hashes firmados si no hay certificado).
- [ ] Instalación limpia en Windows 10 x64 y Windows 11 x64.
- [ ] Actualización desde la versión anterior conserva preferencias.
- [ ] Desinstalación limpia (Program Files, accesos directos, registro, caché).
- [ ] Portable ejecutado desde otro directorio detecta `portable.dat`.
- [ ] Stream real con Apollo 1.0.1+: energía, portapapeles, pantalla virtual, permisos.
- [ ] Stream real con Sunshine: las funciones Apollo se ignoran sin errores.
- [ ] Teclado/ratón: captura automática, `Ctrl+Alt+Shift+Z/M/K`.
- [ ] Gamepad: navegación y mando en juego.
- [ ] 22 temas: selección, persistencia, contraste y reinicio.
- [ ] Español e inglés: cadenas nuevas traducidas.
- [ ] Logs sin `rikey`, sin contraseñas y sin contenido de portapapeles.
- [ ] Assets de release con nombres y hashes correctos.

---

## 13. Lo que está bien

1. **Producto funcional**: compila, arranca, se despliega y tiene portable e instalador.
2. **Identidad cuidada**: iconos, manifiesto, metadatos del EXE, WiX y nombres de producto.
3. **Sistema de temas**: 22 temas, tokens JSON consistentes, 10 tokens usados en toda la UI.
4. **Integración Apollo clara para el usuario**: toggles, avisos y confirmaciones.
5. **Seguridad de red**: pinning de certificado, HTTPS y redacción de claves de sesión.
6. **Hardening del binario**: CFG, EHCont, CET, ASLR, NX, `/permissive-`, `/utf-8`.
7. **Portapapeles opt-in** y con aviso de permisos; no se activa por defecto.
8. **Confirmación de comandos destructivos** antes de apagar/reiniciar.
9. **Traducción española completa** (308/308 actuales) y cadenas nuevas incluidas.
10. **Documentación de build y despliegue** muy por encima de la media de un fork personal.
11. **Sin telemetría** y actualizador que no ejecuta binarios descargados.
12. **Artefactos coherentes**: el EXE del ZIP coincide con el de `dist`; el versionado se centraliza en `version.txt`.

---

## 14. Anexos

### A. Comandos y comprobaciones ejecutadas

```powershell
# Historia y relación con upstream
git -C <repo> log --oneline -8
git -C <repo> rev-list --count HEAD
git -C <repo> merge-base HEAD v6.2.0
git -C <repo> submodule status

# Artefactos y firmas
Get-AuthenticodeSignature Release\ArtemisSetup-1.0.0-win64.exe
Get-AuthenticodeSignature build\build-x64-release\app\release\Artemis.exe
Get-FileHash dist\ArtemisPortable\Artemis.exe -Algorithm SHA256

# Contenido del ZIP
[System.IO.Compression.ZipFile]::OpenRead("Release\Artemis-1.0.0-win64.zip")

# QML
qmllint --ignore-settings app\gui\main.qml app\gui\PcView.qml app\gui\AppView.qml app\gui\SettingsView.qml

# Métricas
Get-ChildItem app -Recurse -File -Include *.cpp,*.h,*.qml | ...
```

### B. Evidencias clave

| Tema | Archivo:línea |
|---|---|
| Endpoints Apollo sin validar | `app/backend/nvhttp.cpp:251-285` |
| Validación existente | `app/backend/nvhttp.cpp:392-428` |
| Hilos de portapapeles | `app/streaming/session.cpp:1838-1897` |
| Lectura sin lock | `app/backend/nvhttp.cpp:43-45` |
| Lock del host | `app/backend/nvcomputer.h:124` |
| Portable con CWD | `app/main.cpp:436-439`; `app/path.cpp:107-115` |
| CI solo tags | `.github/workflows/windows.yml:3-7` |
| Permisos de CI | `.github/workflows/windows.yml:9-10` |
| Release sin hashes | `.github/workflows/windows.yml:83-90` |
| Sin tests | `app/` (0 archivos de test) |
| Raíz sin padre | `git cat-file -p 99a218e` |
| Licencia en portable | ZIP sin `LICENSE` |
| Runtime desde System32 | `scripts/deploy-artemis.ps1:38-48` |
| Limpieza en upgrade | `wix/Moonlight/Product.wxs:44-46` |
| AppStream 6.2.0 | `app/deploy/linux/com.leonidas10009.Artemis.appdata.xml` |
| Plantillas Moonlight | `.github/ISSUE_TEMPLATE/bug_report.md` |
| ATS desactivado | `app/Info.plist` (`NSAllowsArbitraryLoads`) |
| Layout QML | `app/gui/main.qml:210,242,269,651-652,713-714` |
| Comandos por regex | `app/gui/PcView.qml:142-149` |

### C. Glosario

- **P1/P2/P3**: prioridad de corrección (P1 antes del próximo release; P2 próximas 1-2 releases; P3 deuda/limpieza).
- **UAF**: use-after-free, uso de memoria después de liberarla.
- **SBOM**: Software Bill of Materials, inventario de dependencias y versiones.
- **ATS**: App Transport Security de macOS.
- **CFG/EHCont/CET**: mecanismos de mitigación de explotación en Windows/MSVC.
- **QNAM**: `QNetworkAccessManager` de Qt.

---

> **Conclusión:** Artemis PC 2026 es un fork sólido para ser un proyecto personal: la UI, los temas y el empaquetado están por encima de lo habitual. Para convertirlo en un producto mantenible y distribuible con confianza, el orden correcto es: **corregir los P1 de portapapeles/portable/errores, añadir pruebas y CI en PRs, resolver licencias/firma/hashes y establecer una estrategia de sincronización con Moonlight**. La deuda de arquitectura (Apollo disperso, QML monolítico) puede abordarse después sin bloquear el próximo release.

---

## 15. Estado de correcciones aplicadas

### 15.1 Aplicado en esta iteración

| Hallazgo | Estado | Detalle |
|---|---|---|
| F-01 — validación Apollo | **Corregido** | `execServerCmd`, `getClipboardText` y `setClipboardText` validan documentos XML de error; el portapapeles entrante se limita a 256 KB. |
| F-02 — concurrencia del portapapeles | **Corregido** | Instantánea inmutable de conexión, estado compartido con mutex y eliminación de `NvComputer*`/`Session*` en los hilos. |
| F-03 — modo portable | **Corregido** | `Path::getExecutableDir()` y detección de `portable.dat` junto al ejecutable, no en el directorio de trabajo. |
| F-04 — pruebas y CI | **Parcial** | CI en push/PR, `qmllint`, `lrelease` y primera suite Qt Test del sistema de temas. Faltan más pruebas de integración. |
| F-05 — firma y hashes | **Parcial** | Se generan y publican `SHA256SUMS.txt` y `BUILD_INFO.txt`; la firma Authenticode sigue pendiente de certificado. |
| F-06 — licencias | **Corregido** | `LICENSE` y `THIRD_PARTY_NOTICES.md` se incluyen en portable y MSI. |
| F-07 — historial upstream | **Pendiente** | Requiere una rama vendor o una serie de parches; no se resuelve con un cambio de código. |
| F-09 — comandos de energía | **Parcial** | Se añadió “Resume Running App” y se mantiene la confirmación; falta migrar la clasificación por regex a IDs estables. |
| F-10 — QML monolítico | **Parcial** | Se corrigieron avisos de layout, se sincronizó el selector de tema y se añadieron componentes de diálogo; falta dividir `SettingsView`. |
| F-12 — geometría de ventana | **Pendiente** | Sin cambios. |
| F-13 — traducciones | **Corregido** | `qml_es.ts` actualizado y `qml_es.qm` regenerado; CI ejecuta `lrelease`. |
| F-14/F-15 — cadena de suministro y CI | **Parcial** | Permisos de CI separados y release en job propio; faltan hashes de dependencias y pinning por SHA. |
| F-16 — instalador | **Parcial** | Runtime VC++ desde el redistributable oficial; queda condicionar `RemoveFolderEx` en upgrades. |

### 15.2 Actualización 1.2.0

- Atajos cortos `Ctrl+F5…F10` **solo para Remote desktop / app Desktop**.
- En juegos y apps normales se mantienen los atajos largos
  `Ctrl+Alt+Shift+…`, evitando interferencias con `Ctrl+F5…F10`.
- Opción en Ajustes → Entrada para desactivar los atajos cortos.
- Detección centralizada de la app Desktop en `NvApp::isDesktopApp()`.

### 15.3 Nuevas funciones de escritorio remoto

- Botón **Remote desktop** en la tarjeta del PC y entrada en el menú contextual.
- Apertura automática de la app **Desktop** del host en modo de ratón absoluto.
- Entrada **Open in remote desktop mode** en el menú contextual de cualquier app.
- Un clic en una tarjeta de app la lanza o reanuda directamente.
- Diálogo **Stream shortcuts** y guía de atajos en Ajustes → Entrada y en la pantalla de inicio del stream.
- Documentación de `Ctrl+Alt+Shift+Q/E/Z/M/X/D/S/V` en README y LEEME.
