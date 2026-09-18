# Assets originales y ejecución local

## Fuente preparada

Los archivos se extrajeron del instalador clásico para Windows `DeathRallyWin_10.exe` aportado por Mariano, usando 7-Zip sin ejecutar el instalador.

- Fuente local: `.local/windows-original/`.
- Copia de ejecución: `runtime/`.
- Configuración local: `.local/settings.json`.
- La licencia original se conserva junto a los archivos extraídos.
- Las tres ubicaciones permanecen ignoradas por Git.

La copia DOS original y sus partidas no se modificaron.

## Archivos comprobados

| Grupo | Estado |
| --- | --- |
| ENGINE.BPA, IBFILES.BPA, MENU.BPA, MUSICS.BPA | Presentes |
| TR0.BPA a TR9.BPA | Los diez circuitos presentes |
| ENDANI.haf, ENDANI0.HAF, SANIM.haf | Presentes |
| SDL.dll, fmod.dll, msvcr71.dll | Presentes; formato PE x86 verificado |

**Corrección del inventario inicial:** `TRX.BPA` en el README upstream representa la familia de circuitos; no se necesita un archivo llamado literalmente TRX.BPA. El código forma el nombre del circuito y le agrega `.BPA` (ver `dr.c`). Los scripts comprueban y copian los diez archivos TR0–TR9.

Los 14 archivos BPA de esta descarga coinciden por SHA-256 con los de la copia DOS examinada. En este caso faltaban las animaciones y DLL del paquete Windows, no otros contenedores de circuitos. Esta comparación no demuestra compatibilidad de todas las ediciones ni de los guardados.

## Prueba inicial

El ejecutable Debug propio arrancó con `-window`, permaneció activo y Windows lo reportó respondiendo con título DreeRally. Generó su configuración en `runtime/dr.cfg`. Mariano confirmó visualmente que la ventana pasó la intro y llegó al menú. La inspección automatizada quedó pendiente de autorización. Aún faltan navegación completa, audio, depuración y una carrera completa.

## Uso

```powershell
.\scripts\Setup-VSCode.ps1 -AssetSource "$PWD\.local\windows-original"
.\scripts\Check-Assets.ps1
.\scripts\Prepare-Runtime.ps1 -Configuration Debug
```

En VS Code, F5 compila Debug, prepara el runtime y lanza el juego. Cerrar la instancia anterior antes de F5, porque Windows bloquea la sustitución del ejecutable mientras está abierto.

Los scripts copian datos, DLL, idiomas y mods. No importan ni sobrescriben partidas de la carpeta original. No añadir BPA, HAF, DLL ni partidas originales a commits o releases. Mantener atribución upstream y revisar licencias de cada dependencia antes de redistribuir.
