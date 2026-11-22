# Artemis PC 2026

Cliente de escritorio para **Apollo/Sunshine**, basado en **Moonlight Qt 6.2.0**.
Es la versión PC del proyecto **Artemis 2026**, con la interfaz y los temas de Apollo 2026.

> **Versión:** `1.0.0`
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

1. Descarga `ArtemisSetup-1.0.0-win64.exe`.
2. Ejecútalo y sigue el asistente.
3. Se instala en `Program Files\Artemis 2026` y crea acceso directo.
4. Desinstala desde **Configuración → Aplicaciones**.

> El instalador no está firmado con un certificado comercial. Windows SmartScreen
> puede pedir confirmación la primera vez.

### Versión portable

1. Descarga `Artemis-1.0.0-win64.zip`.
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
- Si prefieres capturar manualmente, desactiva
  **“Capture keyboard and mouse automatically when the stream starts”** en Ajustes → Entrada.

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
- **7-Zip** solo si se generan instaladores.

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

`scripts\build-artemis.bat` automatiza la compilación y el despliegue en este equipo.
Ajusta las rutas de Qt y Visual Studio al principio del archivo si cambian.

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
├─ moonlight-common-c/  # Núcleo (submódulo)
├─ qmdnsengine/         # Descubrimiento mDNS (submódulo)
├─ libs/windows/        # Dependencias precompiladas (no versionadas)
├─ scripts/             # Scripts de compilación
├─ wix/                 # Instalador WiX
├─ dist/                # Salida portable (no versionada)
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
