# Assets originales y ejecución local

DreeRally upstream declara que usa archivos de **Death Rally para Windows**. La carpeta DOS aportada por Mariano no es una fuente completa para este runtime.

## Inventario inicial

Inspección de `D:\DOS\Drally2`, 17 de septiembre de 2026 (hora de Argentina):

| Archivo | Estado |
| --- | --- |
| ENGINE.BPA, IBFILES.BPA, MENU.BPA, MUSICS.BPA | Presentes; compatibilidad binaria pendiente |
| TRX.BPA | Ausente; hay TR0.BPA a TR9.BPA de DOS |
| ENDANI.haf, SANIM.haf | Ausentes |
| SDL.dll, fmod.dll | Ausentes |
| msvcr71.dll | Ausente; figura en la lista upstream, revisar dependencias de sus DLL |
| ENDANI0.HAF | Ausente; referenciado en rutas de resultados del código |

No se modificaron archivos ni partidas de esa carpeta.

## Resolver el bloqueo

Usar una copia legítima de la edición Windows indicada por el [README upstream](https://github.com/enriquesomolinos/DreeRally#installing), o investigar de forma separada cómo adaptar contenedores DOS. No asumir que renombrar o concatenar TR0–TR9 produce TRX. No descargar DLL sueltas de sitios desconocidos.

El ejecutable Debug compilado importa SDL.dll y fmod.dll, además de bibliotecas de Windows y el runtime de depuración de MSVC. Se requieren DLL x86 compatibles con las bibliotecas de enlace de este repositorio. Los nombres por sí solos no prueban versión ni compatibilidad.

## Separación local

- `.local/settings.json`: ruta de la copia fuente, ignorada.
- `runtime/`: copia para ejecutar y guardar partidas nuevas, ignorada.
- `Debug/` y `Release/`: resultados de compilación, ignorados.
- No añadir BPA, HAF, DLL o partidas originales a commits o releases.
- Mantener avisos/licencias de upstream y revisar cada dependencia antes de redistribuir.

`Check-Assets.ps1` comprueba el inventario mínimo declarado; las animaciones adicionales y la compatibilidad real deben verificarse durante las pruebas de campaña.
