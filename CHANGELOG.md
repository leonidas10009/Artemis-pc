# Changelog — Artemis PC 2026

## 1.1.0 — 2026-11-22

### Añadido

- **Remote desktop**: botón en la tarjeta del PC y entrada en el menú contextual.
  Abre la app Desktop del host con ratón absoluto, sin capturar el cursor.
- Entrada **Open in remote desktop mode** en el menú contextual de cualquier app.
- Entrada **Resume Running App** para reanudar la app que ya está ejecutándose.
- Diálogo **Stream shortcuts...** con todos los atajos del stream.
- Guía de atajos en Ajustes → Entrada y aviso en la pantalla de inicio del stream.
- Traducciones españolas de todas las cadenas nuevas.
- Pruebas unitarias con Qt Test para el sistema de temas.
- `THIRD_PARTY_NOTICES.md` y texto de licencia en el portable y el MSI.
- `SHA256SUMS.txt` y `BUILD_INFO.txt` en cada release.

### Corregido

- Un clic en una tarjeta de app lanza o reanuda la app; antes se ignoraba si
  estaba en ejecución.
- El modo portable se detecta por el directorio del ejecutable, no por el
  directorio de trabajo.
- Los endpoints Apollo validan errores de aplicación en respuestas XML.
- El portapapeles ya no captura punteros a `NvComputer`/`Session` en sus hilos.
- Límite de 256 KB para el texto recibido del portapapeles.
- El selector de tema de Ajustes se sincroniza con el tema global.
- El aviso de `ToolTip` y los avisos de layout de QML.
- El runtime VC++ se toma del redistributable oficial de Visual Studio.
- CI en push/PR con `lrelease`, `qmllint` y pruebas.

### Notas

- El instalador sigue sin firma comercial; SmartScreen puede avisar.
- Requiere Apollo 1.0.1 o posterior para las funciones Apollo.
- La app Desktop debe existir en el host para Remote desktop.

## 1.0.0 — 2026-11-22

- Primera versión pública: base Moonlight Qt 6.2.0, temas Apollo 2026,
  comandos de energía, pantalla virtual, portapapeles, permisos de entrada,
  captura automática de teclado/ratón, portable e instalador WiX.
