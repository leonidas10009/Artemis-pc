# Artemis PC 2026

Cliente de escritorio para **Apollo/Sunshine**, basado en **Moonlight Qt 6.2.0**.
Es la versión PC del proyecto **Artemis 2026**, con la interfaz y los temas de Apollo 2026.

> **Versión:** `1.1.0`
> **Base:** Moonlight Qt `6.2.0`
> **Repositorio:** <https://github.com/leonidas10009/Artemis-pc>
> **Host recomendado:** [Apollo 2026](https://github.com/leonidas10009/Apollo_2026)
> **Licencia:** GPL-3.0

Este es un fork no oficial. No está afiliado a Moonlight Stream, LizardByte ni ClassicOldSong.

---

## Novedades principales

- **Interfaz Apollo 2026:** barra superior, sidebar, tarjetas, tipografía y estados inspirados en la Web UI de Apollo.
- **22 temas claros y oscuros:** Apollo, Oscuro, Drácula, Moca, Ember, Pino rosado, Luz Lunar, Pizarra, Medianoche, Nord, Claro, Alucardo, Latte, Ember claro, Alba de pino, Resplandor, Índigo, Océano, Bosque, Rosa, Lavanda y Monocromo.
  - Selector de tema en la esquina superior derecha y en Ajustes.
  - `Ctrl+T` cambia al siguiente tema.
  - `Ctrl+Shift+T` abre el selector.
  - El tema se guarda y se restaura al reiniciar.
- **Navegación lateral:** Equipos, Ajustes, Ayuda y Añadir PC en la sidebar; la barra superior queda limpia con atrás, título y tema.
- **Ventana de escritorio:** tamaño mínimo, geometría recordada y barra de estado con información contextual.
- **Tarjetas de apps:** portada completa, fondo oscurecido, nombre integrado en la parte inferior y efecto hover.
- **Lanzamiento directo:** un clic en una tarjeta de app la lanza o reanuda; botón **Remote desktop** en la tarjeta del PC.
- **Reanudar app en ejecución:** menú contextual del PC → **Resume Running App**.
- **Funciones Apollo:**
  - **Comandos de energía** desde el menú contextual del PC: apagar, reiniciar y cancelar apagado.
  - **Pantalla virtual Apollo** (SudoVDA) al iniciar el stream.
  - **Sincronización de portapapeles** entre cliente y host.
  - Detección de host Apollo y visualización de la versión.
  - Aviso claro si faltan permisos de entrada (ratón/teclado).
- **Entrada corregida:** captura automática de teclado y ratón al iniciar el stream (Moonlight 6.2 dejó de hacerlo en modo ventana).
- **Icono y metadatos Artemis** en ejecutable, ventana, instalador y recursos.

---

## Requisitos

### Cliente

- Windows 10/11 de 64 bits.
- GPU con decodificación por hardware para la mejor experiencia (D3D11VA en Windows).
- Red local o conexión adecuada para streaming.
- Para las funciones Apollo: Apollo 1.0.1 o posterior.

### Host

- **Apollo 2026** recomendado: <https://github.com/leonidas10009/Apollo_2026>
- Sunshine también funciona, pero las funciones marcadas como Apollo se ignoran.
- Para pantalla virtual: Apollo con el controlador **SudoVDA** instalado y listo.
- Para energía y portapapeles: permisos concedidos al cliente en la Web UI de Apollo.

---

## Instalación

La versión portable y el instalador se publican en
[GitHub Releases](https://github.com/leonidas10009/Artemis-pc/releases).

### Instalador (recomendado)

1. Descarga `ArtemisSetup-1.1.0-win64.exe`.
2. Ejecútalo y sigue el asistente.
3. Se instala en `Program Files\Artemis 2026` y crea acceso directo.
4. Desinstala desde **Configuración → Aplicaciones**.

> El instalador no está firmado con un certificado comercial. Windows SmartScreen
> puede pedir confirmación la primera vez.

### Versión portable

1. Descarga `Artemis-1.1.0-win64.zip`.
2. Extrae en una carpeta propia.
3. Ejecuta `Artemis.exe`.
4. Añade tu PC Apollo por descubrimiento automático o manualmente.
5. Empareja el cliente e introduce el PIN en la Web UI de Apollo.

> El modo portable guarda la configuración en `Artemis 2026 Project\Artemis.ini`,
> junto al ejecutable. No comparte datos con Moonlight.

---

## Configuración de Apollo

### Permisos de entrada (teclado y ratón)

Apollo solo concede permisos completos al primer cliente emparejado. Si el teclado
o el ratón no llegan al host:

1. Abre la Web UI de Apollo.
2. Entra en **Clients**.
3. Selecciona **Artemis PC**.
4. Activa **Mouse** y **Keyboard** en los permisos de entrada.
5. Reinicia el stream.

Artemis PC muestra **“Input permissions missing”** en la tarjeta del PC y un aviso
al iniciar el stream cuando detecta que faltan estos permisos.

### Teclado y ratón

- Por defecto, Artemis captura teclado y ratón al iniciar el stream.
- `Ctrl+Alt+Shift+Z` libera o vuelve a capturar el ratón y el teclado.
- `Ctrl+Alt+Shift+M` cambia entre modo ratón para juegos y modo escritorio remoto.
- `Ctrl+Alt+Shift+K` activa o desactiva la captura de atajos del sistema.
- `Ctrl+Alt+Shift+Q` desconecta la sesión (la app del host sigue abierta).
- `Ctrl+Alt+Shift+E` cierra la app del host y desconecta.
- `Ctrl+Alt+Shift+X` alterna pantalla completa.
- `Ctrl+Alt+Shift+D` minimiza la ventana del stream.
- `Ctrl+Alt+Shift+S` muestra u oculta el overlay de rendimiento.
- `Ctrl+Alt+Shift+V` pega el texto del portapapeles local en el host.
- Con mando: `Start+Select+L1+R1` desconecta.
- Si prefieres capturar manualmente, desactiva
  **“Capture keyboard and mouse automatically when the stream starts”** en Ajustes → Entrada.

### Escritorio remoto

Para usar Artemis como un acceso remoto sencillo:

1. En la tarjeta del PC, pulsa el botón **Remote desktop** que aparece al pasar
   el ratón, o usa el menú contextual → **Remote desktop**.
2. Artemis abrirá la app **Desktop** del host y activará el modo de ratón
   absoluto. El cursor del cliente se mueve directamente por el escritorio del
   host, sin quedar atrapado en la ventana.
3. Si el host no tiene una app Desktop, créala en Apollo/Sunshine o lanza
   cualquier app desde la parrilla.
4. Para salir: `Ctrl+Alt+Shift+Q` (desconectar) o `Ctrl+Alt+Shift+E` (cerrar
   la app del host y salir). `Ctrl+Alt+Shift+Z` libera el ratón si necesitas
   usar la barra de título o el botón de cerrar.
5. `Ctrl+Alt+Shift+M` vuelve al modo de ratón para juegos y
   `Ctrl+Alt+Shift+X` alterna pantalla completa.
6. También puedes usar el menú contextual de cualquier app →
   **Open in remote desktop mode**.

También puedes activar **“Optimize mouse for remote desktop instead of games”**
en Ajustes → Entrada para usar ese modo por defecto en cualquier app.

### Comandos de energía

El menú contextual del PC muestra las órdenes de energía configuradas en Apollo
(`server_cmd`) que coincidan con apagar, reiniciar o cancelar apagado. Requiere:

- Apollo 1.0.1 o posterior.
- Permiso `server_cmd` para el cliente.

### Pantalla virtual

Activa **“Use an Apollo virtual display”** en Ajustes → Host. Apollo creará una
pantalla temporal con la resolución y frecuencia del stream. Requiere SudoVDA.
Si el host no la soporta, Artemis muestra un aviso y continúa sin ella.

### Portapapeles

Activa **“Synchronize clipboard with the host”** en Ajustes → Host. Mientras
transmites, el texto se sincroniza en ambos sentidos. Requiere Apollo y los
permisos `clipboard_set` / `clipboard_read` para el cliente.

---

## Compilación en Windows

### Requisitos

- **Qt 6.11.3 MSVC 2022 64-bit** (probado con Qt 6.11.3).
- **Visual Studio 2026** con cargas de trabajo de C++ y Windows SDK.
- **PowerShell** para descargar las librerías precompiladas.
- **7-Zip** no es necesario en local; el script de CI lo usa para instalar Qt en el runner (GitHub ya lo incluye).

Rutas usadas en este equipo:

| Elemento | Ruta |
|---|---|
| Qt | `E:\Qt\6.11.3\msvc2022_64` |
| Visual Studio | `C:\Program Files\Microsoft Visual Studio\18\Community` |
| Proyecto | `E:\ProyectoProgramacion\apolo_V2026\artemis_pc_V2026\artemis-pc-2026` |

### 1. Dependencias

```powershell
cd artemis-pc-2026
powershell -ExecutionPolicy Bypass -File .\setup-deps.ps1
```

Descarga SDL2, FFmpeg, OpenSSL, Opus, libplacebo y Discord RPC en `libs\windows`.

Los submódulos (`moonlight-common-c`, `qmdnsengine`, `SDL_GameControllerDB`) deben
estar inicializados:

```powershell
git submodule update --init --recursive
```

### 2. Compilar

```powershell
$env:PATH = "E:\Qt\6.11.3\msvc2022_64\bin;$env:PATH"
mkdir build\build-x64-release
cd build\build-x64-release
qmake ..\..\moonlight-qt.pro CONFIG+=release
nmake release
```

Salida:

```
build\build-x64-release\app\release\Artemis.exe
```

### 3. Desplegar la versión portable

```powershell
cd ..\..
mkdir dist\ArtemisPortable
copy libs\windows\lib\x64\*.dll dist\ArtemisPortable
copy build\build-x64-release\AntiHooking\release\AntiHooking.dll dist\ArtemisPortable
copy app\SDL_GameControllerDB\gamecontrollerdb.txt dist\ArtemisPortable
copy build\build-x64-release\app\release\Artemis.exe dist\ArtemisPortable

windeployqt --dir dist\ArtemisPortable --release --qmldir app\gui `
  --no-opengl-sw --no-compiler-runtime --no-sql `
  --no-system-d3d-compiler --no-system-dxc-compiler --no-ffmpeg `
  --skip-plugin-types qmltooling,generic `
  --no-quickcontrols2fusion --no-quickcontrols2imagine --no-quickcontrols2universal `
  dist\ArtemisPortable\Artemis.exe

# Modo portable
New-Item -ItemType File dist\ArtemisPortable\portable.dat
```

Copia también las DLL del runtime de Visual C++ (`msvcp140.dll`,
`vcruntime140.dll`, `vcruntime140_1.dll`) si el equipo destino no las tiene.

### Script rápido

`scripts\build-artemis.bat` automatiza la compilación y el despliegue portable.
Ajusta las rutas de Qt y Visual Studio al principio del archivo si cambian.

### 4. Generar el instalador

Con el portable ya desplegado:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-artemis.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build-installer.ps1
```

Genera:

- `build\build-x64-release\Artemis.msi`
- `dist\installer\ArtemisSetup.exe`
- `Release\ArtemisSetup-1.1.0-win64.exe`
- `Release\SHA256SUMS.txt`
- `Release\BUILD_INFO.txt`

### 5. Pruebas

El proyecto incluye una primera suite de pruebas con Qt Test:

```powershell
$env:PATH = "E:\Qt\6.11.3\msvc2022_64\bin;$env:PATH"
mkdir build\tests
cd build\tests
qmake ..\..\tests\tests.pro CONFIG+=release
nmake release
.\release\artemis_tests.exe -o test-results.txt,txt
Get-Content test-results.txt
```

Cubre el catálogo de temas, los tokens obligatorios, los nombres visibles,
la selección persistente y la señal `themeChanged`. La suite se ejecuta en CI
en cada push y pull request.

### 6. CI en GitHub Actions

`.github/workflows/windows.yml` compila en un runner `windows-2025` con
Qt 6.11.3, MSVC y WiX. En cada push a `main` y en cada pull request:

- valida las traducciones con `lrelease`;
- ejecuta `qmllint` sobre todas las vistas QML;
- compila y ejecuta las pruebas unitarias;
- compila el portable y el instalador.

En tags `v*` publica la release con el ZIP, el instalador, `SHA256SUMS.txt` y
`BUILD_INFO.txt`. El workflow se puede lanzar manualmente con
`workflow_dispatch`.

GitHub Actions es gratuito para repositorios públicos con uso razonable.

---

## Solución de problemas

### No llegan teclado o ratón

1. Comprueba los permisos del cliente en Apollo → Clients (Mouse/Keyboard).
2. Pulsa `Ctrl+Alt+Shift+Z` dentro del stream para capturar el ratón y el teclado.
3. Asegúrate de que la ventana del stream tiene el foco.
4. Revisa que **“Capture keyboard and mouse automatically”** esté activo.
5. Comprueba que el juego no use solo Raw Input. Apollo/Sunshine puede necesitar
   su driver de entrada virtual para algunos juegos.

### El cursor no sale de la ventana

Pulsa `Ctrl+Alt+Shift+Z` o `Ctrl+Alt+Shift+M`. En modo ventana, Moonlight 6.2
no captura por defecto; Artemis lo activa automáticamente si la opción está marcada.

### Error 409 al emparejar

Apollo tiene una sesión de emparejamiento pendiente con el mismo `uniqueid`.
Cancela la sesión en la Web UI de Apollo o espera a que caduque, y vuelve a intentar.

### El actualizador no encuentra versiones

El repositorio debe tener releases publicadas. Mientras no exista ninguna,
Artemis no mostrará actualizaciones.

---

## Estructura del proyecto

```
artemis-pc-2026/
├─ app/
│  ├─ backend/          # NvHTTP, NvComputer, ComputerManager, Theme, SystemProperties
│  ├─ gui/              # main.qml, PcView, AppView, SettingsView, SidebarButton
│  ├─ settings/         # StreamingPreferences
│  ├─ streaming/        # Session, entrada, vídeo, audio
│  ├─ res/              # Iconos y recursos
│  ├─ themes.json       # Tokens de los 22 temas
│  └─ app.pro
├─ tests/               # Pruebas unitarias con Qt Test
├─ moonlight-common-c/  # Núcleo (submódulo)
├─ qmdnsengine/         # Descubrimiento mDNS (submódulo)
├─ libs/windows/        # Dependencias precompiladas (no versionadas)
├─ scripts/             # Scripts de compilación
├─ wix/                 # Instalador WiX
├─ dist/                # Salida portable (no versionada)
├─ docs/reviews/        # Revisiones técnicas
├─ CHANGELOG.md          # Historial de versiones
├─ THIRD_PARTY_NOTICES.md
├─ LEEME.txt             # Guía rápida para el usuario
└─ MEMORIA_ARTEMIS_PC.md
```

---

## Atribución

- **Moonlight Qt:** <https://github.com/moonlight-stream/moonlight-qt>
- **Moonlight Common C:** <https://github.com/moonlight-stream/moonlight-common-c>
- **Apollo:** <https://github.com/ClassicOldSong/Apollo>
- **Apollo 2026:** <https://github.com/leonidas10009/Apollo_2026>
- **Artemis Android:** <https://github.com/leonidas10009/Artemis-2026>
- **Este fork PC:** <https://github.com/leonidas10009/Artemis-pc>

Consulta `LICENSE` para la licencia GPL-3.0.
