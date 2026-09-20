# Desarrollo en Windows con VS Code

## Requisitos y base comprobada

- Git y VS Code, con la extensión Microsoft C/C++ (`ms-vscode.cpptools`).
- Visual Studio Build Tools 2019 o 2022 con las herramientas C++ x86/x64 y Windows SDK 10.
- El IDE completo de Visual Studio no es necesario.
- Compilar **Win32/x86**: las bibliotecas heredadas y el código no se han validado para x64.

Las compilaciones Debug y Release se verificaron inicialmente con MSVC 14.29 (v142) y SDK 10.0.19041.0. El 20/09/2026 se validaron también con Build Tools 2022 estable, MSVC 14.44 (v143) y SDK 10.0.26100.0. El script detecta instalaciones Build Tools además del IDE y selecciona v142/v143.

## Preparar y abrir

Desde la raíz del repositorio, en PowerShell:

```powershell
.\scripts\Setup-VSCode.ps1 -AssetSource "$PWD\.local\windows-original" -Open
```

La ruta anterior corresponde al paquete Windows extraído localmente; no se distribuye en Git. En otra máquina, indicar la carpeta que contenga los datos originales. Ver [ASSETS.md](ASSETS.md).

El comando genera `.local/DreeRally.code-workspace` con la ruta del compilador detectado y guarda la ruta de assets en `.local/settings.json`. Ambos quedan fuera de Git. Para continuar otro día, abrir ese workspace.

## Compilar y depurar

- **Ctrl+Shift+B**: compilar Debug.
- **Terminal → Run Task → DreeRally: build Release**: compilar Release.
- **DreeRally: check assets**: revisar la fuente local configurada.
- **F5 → DreeRally: Windows Debug**: compilar, comprobar datos, preparar `runtime/` y depurar en ventana.

Equivalentes sin editor:

```powershell
.\scripts\Build.ps1 -Configuration Debug
.\scripts\Build.ps1 -Configuration Release
.\scripts\Check-Assets.ps1 -ReportOnly
.\scripts\Prepare-Runtime.ps1 -Configuration Debug
```

El build usa `DreeRally.vcxproj`, reemplazando en la invocación el toolset y SDK antiguos. No reescribe el proyecto original ni cambia el motor.

La preparación copia exclusivamente los datos y DLL permitidos, idiomas/mods y el ejecutable compilado a `runtime/`. Las nuevas partidas/configuración se generan allí. No se copian ni se editan guardados originales. El control de nombres no garantiza compatibilidad de formatos o DLL.

## Diagnóstico de cierres

En VS Code: **Terminal → Run Task → DreeRally: run with crash diagnostics**.
También se puede iniciar desde PowerShell:

```powershell
.\scripts\Start-Diagnostics.ps1
```

Compila Debug, prepara `runtime/` y abre el juego con ProcDump de Microsoft.
La primera ejecución descarga la herramienta portátil a `.local/procdump`,
verifica su firma y acepta su licencia Sysinternals. No registra un depurador
global. Cerrar la instancia anterior antes de iniciar otra sesión.

Cada ejecución del juego escribe `runtime/logs/session-*.log`: arranque,
cambios de foco, entrada del nombre, carga de carrera y excepciones.
El lanzador agrega `runtime/logs/diagnostic-*/` con el ejecutable, símbolos,
metadatos y un volcado `.dmp` si hay una excepción no controlada. Los archivos
quedan locales y fuera de Git. Conservar esa carpeta junto con el log de sesión.
El handler interno es de mejor esfuerzo; para corrupción de memoria conviene
usar el lanzador externo. No ejecutarlo simultáneamente con F5.

Pruebas de regresión de las paletas y del humo de carrera, sin abrir el juego:

```powershell
.\scripts\Test-RacePalette.ps1
```

Validación del 18/09/2026: Mariano confirmó nombre, Backspace y selección de
carrera. El primer volcado ubicó el fallo en `showSmoke_40F070`. La paleta
procesaba 257 colores en un buffer de 256 y sobrescribía el contador de sombras
(242 puntos en TR0 pasaban a 64495). La inversión del circuito extendía la
corrupción a otros datos y punteros. Las cinco pruebas de paleta fallaron antes
de corregir el límite y pasan después; también pasan las pruebas de humo para
los cuatro participantes. Debug y Release compilan. La carrera completa queda
pendiente de la siguiente prueba manual.

Revalidación del 20/09/2026 con Build Tools 2022: pasan las cinco pruebas de
paleta y las pruebas de humo; Debug y Release compilan. Ejecutar
`Setup-VSCode.ps1` después de cambiar el compilador actualiza el workspace local.

## Remotos e identidad

- `origin`: https://github.com/marianoluzza/DreeRally.git
- `upstream`: https://github.com/enriquesomolinos/DreeRally.git
- Rama inicial: `0.3.x`.
- Identidad configurada sólo en este clon: Mariano Luzza, marianoluzza@gmail.com.

Para futuras tareas, crear una rama desde la base propia. Inspeccionar cambios upstream antes de integrarlos; no sobrescribir la rama personal.

## Límites actuales

- El proceso arrancó con los assets Windows y responde; Mariano confirmó que pasó la intro y llegó al menú. Falta probar depuración y completar carreras. Cerrar la instancia abierta antes de F5 para liberar el ejecutable.
- El proyecto silencia muchas advertencias; build exitoso no equivale a ausencia de errores.
- Los builds muestran advertencias de mezcla de runtime MSVCRT/MSVCRTD (LNK4098) y de la opción antigua /Gm (D9035); se conservan para estudiar después de obtener una referencia funcional.
- CI heredado y migración a CMake quedan registrados en el [roadmap](../ROADMAP.md).
