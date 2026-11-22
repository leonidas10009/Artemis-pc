# MEMORIA ARTEMIS PC 2026

> Documento técnico permanente del cliente **Artemis PC 2026**.
> Última actualización: **2026-11-22**.
> Ruta del proyecto: `E:\ProyectoProgramacion\apolo_V2026\artemis_pc_V2026\artemis-pc-2026`
> Repositorio: <https://github.com/leonidas10009/Artemis-pc>
> Versión actual: **1.0.0**.

---

## 0. Resumen ejecutivo

- **Producto:** cliente de escritorio Artemis PC 2026.
- **Base:** Moonlight Qt **6.2.0** (tag `v6.2.0`, commit upstream `de2467e`).
- **Interfaz:** réplica del lenguaje visual de la Web UI de **Apollo 2026**.
- **Temas:** 22 (10 oscuros, 12 claros) con tokens copiados de `sunshine.css` de Apollo.
- **Funciones Apollo:** comandos de energía, pantalla virtual, portapapeles y detección de permisos.
- **Entrada:** captura automática de teclado/ratón al iniciar el stream.
- **Estado:** compila y arranca en Windows 11. Paquete portable 1.0.0 generado;
  falta publicar release e instalador MSI.

---

## 1. Identidad y rutas

| Elemento | Valor |
|---|---|
| Nombre | Artemis PC 2026 |
| Ejecutable | `Artemis.exe` |
| Versión | 1.0.0 |
| Repositorio | `https://github.com/leonidas10009/Artemis-pc` |
| Proyecto | `E:\ProyectoProgramacion\apolo_V2026\artemis_pc_V2026\artemis-pc-2026` |
| Salida de compilación | `build\build-x64-release\app\release\Artemis.exe` |
| Distribución portable | `dist\ArtemisPortable` |
| Paquete de usuario | `dist\ArtemisPortable\Artemis-1.0.0-win64.zip` |
| Paquete de release | `E:\ProyectoProgramacion\apolo_V2026\artemis_pc_V2026\Release\Artemis-1.0.0-win64.zip` |
| SHA-256 | Se publica junto a la release en GitHub |
| Config portable | `dist\ArtemisPortable\Artemis 2026 Project\Artemis.ini` |
| Host Apollo | `E:\ProyectoProgramacion\apolo_V2026\_update\Release` |

### 1.1 Entorno de compilación

| Elemento | Versión / ruta |
|---|---|
| Qt | 6.11.3 MSVC 2022 64-bit, `E:\Qt\6.11.3\msvc2022_64` |
| Visual Studio | 2026 Community, MSVC 14.52.37025 |
| Windows SDK | 10.0.28000.0 |
| qmake | `E:\Qt\6.11.3\msvc2022_64\bin\qmake.exe` |
| NMake | `...\VC\Tools\MSVC\14.52.37025\bin\Hostx64\x64\nmake.exe` |
| windeployqt | `E:\Qt\6.11.3\msvc2022_64\bin\windeployqt.exe` |

---

## 2. Base y decisiones de diseño

### 2.1 Base Moonlight Qt 6.2.0

Se partió del código de Moonlight Qt 6.2.0. El árbol inicial no tenía `.git`, por lo
que se clonó el tag `v6.2.0` y se copió su `.git` al proyecto. Los submódulos se
inicializaron con `git submodule update --init --recursive`.

Submódulos:

- `moonlight-common-c/moonlight-common-c` (`f900dd4...`)
- `qmdnsengine/qmdnsengine`
- `app/SDL_GameControllerDB`

### 2.2 Rebranding

Cambios de identidad:

- `app/version.txt` → `1.0.0`.
- `app/app.pro`: `TARGET = Artemis`, icono `artemis.ico`, empresa y descripción.
- `app/main.cpp`: nombre de organización, dominio, aplicación, logs `Artemis-*.log`,
  icono `:/res/artemis.png`, `com.leonidas10009.Artemis`.
- `app/Info.plist`, `app/Artemis.exe.manifest`.
- `app/resources.qrc`: nuevos iconos y `themes.json`.
- `wix/Moonlight/Product.wxs` y `wix/MoonlightSetup/Bundle.wxs`: nombre, rutas,
  iconos y GUIDs nuevos.
- `app/deploy/linux/com.leonidas10009.Artemis.desktop` y `.appdata.xml`.
- `README.md` propio.

Iconos generados desde `artemis_V2026\iconos\artemis_icon_source.png`:

- `app/artemis.ico` (16–256 px).
- `app/res/artemis.png` (256 px).
- `app/artemis_wix.png` (128 px).
- `app/artemis.icns`.

### 2.3 Compatibilidad

El código mantiene la estructura de Moonlight Qt. Los cambios están concentrados en:

- `app/backend/theme.*` (nuevo).
- `app/backend/nvcomputer.*`, `nvhttp.*`, `computermanager.*`.
- `app/gui/main.qml`, `PcView.qml`, `AppView.qml`, `SettingsView.qml`, `SidebarButton.qml`.
- `app/settings/streamingpreferences.*`.
- `app/streaming/session.cpp`.
- `app/themes.json` (nuevo).

---

## 3. Interfaz Apollo 2026

### 3.1 Estructura visual

`main.qml` ahora tiene:

- `ToolBar` superior con título, búsqueda, añadir PC, ayuda, tema y ajustes.
- `RowLayout` central con **sidebar** de 220 px (visible a partir de 1100 px de ancho)
  y `StackView`.
- Sidebar: logo Artemis, “PC 2026”, Equipos, Ajustes, Ayuda, tema actual y versión.
- `footer` de estado: número de PCs/apps, filtro activo y atajos.

### 3.2 Sistema de temas

`app/backend/theme.h/.cpp` es un singleton QML (`import Artemis 1.0`).

- Carga `:/data/themes.json` (generado desde `sunshine.css` de Apollo).
- Guarda la selección en `QSettings` (`ui/theme`).
- Expone:
  - `Theme.name`
  - `Theme.isDark`
  - `Theme.colors` (`QVariantMap`)
  - `Theme.darkThemeKeys` / `Theme.lightThemeKeys`
  - `Theme.displayName(key)`
  - `Theme.colorsFor(key)`
  - `Theme.alpha(color, alpha)`
  - `Theme.setTheme(key)`
- Propiedades enlazadas en `main.qml`:
  - `Material.theme`, `Material.background`, `Material.foreground`, `Material.accent`,
    `Material.primary`.
  - `ApplicationWindow.color`.
- Selector de tema:
  - Menú de dos columnas (`Popup`) desde el botón de paleta.
  - `Ctrl+T`: siguiente tema.
  - `Ctrl+Shift+T`: abrir selector.
  - ComboBox en Ajustes → UI.
- Iconos claros/oscuras: variantes `*-light.svg` para monitor, candado, aviso,
  ajustes y GitHub.

### 3.3 Temas incluidos

Oscuros: Apollo, Oscuro, Drácula, Moca, Ember, Pino rosado, Luz Lunar, Pizarra,
Medianoche, Nord.

Claros: Claro, Alucardo, Latte, Ember claro, Alba de pino, Resplandor, Índigo,
Océano, Bosque, Rosa, Lavanda, Monocromo.

Los tokens se extrajeron de `Apollo-git\src_assets\common\assets\web\sunshine.css`.
No se modificó ningún archivo del servidor.

---

## 4. Búsqueda, ventana y comodidad de escritorio

### 4.1 Búsqueda

- `ComputerModel` y `AppModel` tienen `filterText` con notificación.
- `ComputerModel` mantiene `m_Computers` (todos) y `m_FilteredComputers` (visibles).
  Los índices de QML se mapean con `computerAt()`.
- `AppModel` reconstruye `m_VisibleApps` al cambiar el filtro.
- La barra superior expone un `TextField` contextual:
  - `Ctrl+F` enfoca y selecciona.
  - `Esc` limpia el filtro.
- Los modelos emiten `filterTextChanged` y reinician filas.

### 4.2 Ventana

- Tamaño inicial 1280×800, mínimo 960×600.
- `SystemProperties::loadWindowGeometry()` / `saveWindowGeometry()`.
- Se guarda en `QSettings` (`ui/windowX`, `ui/windowY`, `ui/windowWidth`,
  `ui/windowHeight`, `ui/windowMaximized`).
- Al arrancar se restaura solo si la geometría intersecta algún monitor.
- Se guarda en `onClosing`.

### 4.3 Tarjetas

- PC: fondo `surface`, borde `border`, resaltado `primary`, icono del monitor,
  subtítulo “Apollo 2026”, número de apps y aviso de permisos.
- Apps: portada a sangre, fondo desenfocado, degradado, nombre siempre visible,
  hover con escala y botones de reanudar/salir.

---

## 5. Integración con Apollo

### 5.1 Detección de host Apollo

`NvComputer` lee del `serverinfo`:

- `VirtualDisplayCapable`
- `VirtualDisplayDriverReady`
- `ServerCommand` (lista)
- `Permission` (entero decimal)

`isApolloHost` es true si alguno de esos campos está presente. `serverPermission`
guarda el valor de `Permission`.

### 5.2 Comandos de energía

- `NvHTTP::execServerCmd(index)` hace `POST /servercmd?index=N`.
- `ComputerManager::execServerCmd()` lo ejecuta en un `QRunnable`.
- `PcView.qml` filtra `serverCommands` por nombres de apagar/reiniciar/cancelar y
  muestra las acciones en el menú contextual.
- Confirmación con `powerCmdDialog`; error con `powerResultDialog`.
- Requiere permiso `server_cmd`.

### 5.3 Pantalla virtual

- `StreamingPreferences.virtualDisplay` (por defecto `false`).
- `NvHTTP::startApp()` añade `&virtualDisplay=1`.
- Solo se envía si `virtualDisplayCapable` y `virtualDisplayDriverReady`.
- `Session::validateLaunch()` avisa si Apollo no la soporta o el driver no está listo.
- Requiere SudoVDA en Apollo.

### 5.4 Portapapeles

- `StreamingPreferences.clipboardSync` (por defecto `false`).
- `Session::startClipboardSync()` inicia un `QTimer` de 1,5 s.
- `NvHTTP::getClipboardText()` → `GET /actions/clipboard?type=text`.
- `NvHTTP::setClipboardText()` → `POST /actions/clipboard?type=text`.
- Cambios locales con debounce de 350 ms y supresión de ecos.
- Requiere los permisos `clipboard_set` / `clipboard_read`.

### 5.5 Permisos de entrada

Apollo solo da permisos completos al primer cliente. Artemis comprueba:

- Máscara `0x1800` = `input_mouse | input_kbd`.
- Si faltan, muestra “Input permissions missing” en la tarjeta del PC y un aviso
  al iniciar el stream.
- Instrucciones en el diálogo: Apollo → Clients → seleccionar cliente → Mouse/Keyboard.

---

## 6. Entrada de teclado y ratón

### 6.1 Problema detectado

Moonlight 6.2 cambió el comportamiento: **en modo ventana el cursor ya no se captura
automáticamente**. El usuario debe hacer clic en la ventana o pulsar
`Ctrl+Alt+Shift+Z`. Además, Apollo no concede permisos de entrada al cliente nuevo
por defecto.

### 6.2 Solución aplicada

- Nueva preferencia `autoCaptureInput` (por defecto `true`).
- `Session` captura teclado/ratón después de crear el decodificador aunque el stream
  esté en modo ventana.
- Ajuste en Ajustes → Entrada:
  “Capture keyboard and mouse automatically when the stream starts”.
- `Ctrl+Alt+Shift+Z` sigue liberando/recapturando.
- Aviso de permisos de Apollo en la UI y al iniciar el stream.
- El modo absoluto de escritorio remoto se mantiene igual.

### 6.3 Diagnóstico rápido

1. ¿La tarjeta del PC muestra “Input permissions missing”? → conceder permisos.
2. ¿La ventana del stream tiene foco? → hacer clic una vez.
3. ¿`Ctrl+Alt+Shift+Z` recupera el cursor? → captura manual.
4. ¿Solo falla en un juego? → probar `always_send_scancodes` o el driver de entrada
   virtual de Apollo/Sunshine.
5. ¿Falla solo el teclado? → revisar distribución del teclado y captura de atajos.

---

## 7. Compilación y despliegue

### 7.1 Dependencias

```powershell
cd artemis-pc-2026
powershell -ExecutionPolicy Bypass -File .\setup-deps.ps1
```

### 7.2 Compilación

```powershell
$env:PATH = "E:\Qt\6.11.3\msvc2022_64\bin;$env:PATH"
mkdir build\build-x64-release
cd build\build-x64-release
qmake ..\..\moonlight-qt.pro CONFIG+=release
nmake release
```

### 7.3 Despliegue

`scripts\build-artemis.bat` realiza compilación y despliegue. Manualmente:

```powershell
windeployqt --dir dist\ArtemisPortable --release --qmldir app\gui `
  --no-opengl-sw --no-compiler-runtime --no-sql `
  --no-system-d3d-compiler --no-system-dxc-compiler --no-ffmpeg `
  --skip-plugin-types qmltooling,generic `
  dist\ArtemisPortable\Artemis.exe
```

Copiar también:

- `libs\windows\lib\x64\*.dll`
- `build\build-x64-release\AntiHooking\release\AntiHooking.dll`
- `app\SDL_GameControllerDB\gamecontrollerdb.txt`
- DLL del runtime VC++ (`msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`)
- `portable.dat` (modo portable)

---

## 8. Estado y pendientes

### Hecho

- Rebranding completo.
- Temas Apollo (22) y selector persistente.
- Sidebar y barra de estado.
- Búsqueda de PCs/apps.
- Geometría de ventana.
- Comandos de energía Apollo.
- Pantalla virtual.
- Portapapeles.
- Aviso de permisos de entrada.
- Captura automática de entrada.
- Iconos claros/oscuras.
- README y esta memoria.
- Paquete portable `Artemis-1.0.0-win64.zip` con hash SHA-256.
- Traducciones al español de las cadenas nuevas.

### Pendiente

- Publicar la release en GitHub (`Artemis-pc`).
- Probar el instalador WiX (`wix\Moonlight.sln`) y renombrar la carpeta interna si se desea.
- Traducir al español las cadenas nuevas de C++ (las de QML ya están).
- Verificar el menú de temas con navegación completa por teclado/gamepad.
- Añadir capturas reales al README.
- Probar energía, portapapeles y pantalla virtual end-to-end con Apollo.
- Revisar el aviso `ToolTip attached property must be attached to an object deriving from Item`
  (preexistente, no bloqueante).
- Silenciar el log 404 del actualizador mientras no haya releases.

---

## 9. Git y publicación

El repositorio remoto es <https://github.com/leonidas10009/Artemis-pc>.

Recomendación:

```powershell
git remote rename origin upstream
git remote add origin https://github.com/leonidas10009/Artemis-pc.git
git add -A
git commit -m "Artemis PC 2026 1.0.0"
git push -u origin main
```

Antes de publicar, comprobar que no se suben:

- `build/`
- `dist/`
- `libs/windows/`
- `*.log`
- `*.ini` de configuración
- capturas temporales

---

## 10. Licencia

GPL-3.0. Moonlight Qt, Moonlight Common C y Apollo mantienen sus licencias y
atribuciones originales. Artemis PC 2026 es un fork no oficial.
