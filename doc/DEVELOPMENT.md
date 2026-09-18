# Desarrollo en Windows con VS Code

## Requisitos y base comprobada

- Git y VS Code, con la extensión Microsoft C/C++ (`ms-vscode.cpptools`).
- Visual Studio Build Tools 2019 o 2022 con las herramientas C++ x86/x64 y Windows SDK 10.
- El IDE completo de Visual Studio no es necesario.
- Compilar **Win32/x86**: las bibliotecas heredadas y el código no se han validado para x64.

Las compilaciones Debug y Release se verificaron con MSVC 14.29 (v142) y SDK 10.0.19041.0. El script detecta instalaciones Build Tools además del IDE y selecciona v142/v143. v143 requiere su propia validación.

## Preparar y abrir

Desde la raíz del repositorio, en PowerShell:

```powershell
.\scripts\Setup-VSCode.ps1 -AssetSource 'D:\DOS\Drally2' -Open
```

La ruta anterior corresponde a la copia DOS examinada: aún faltan archivos; ver [ASSETS.md](ASSETS.md). Cuando haya una fuente compatible, ejecutar nuevamente con su ruta.

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

## Remotos e identidad

- `origin`: https://github.com/marianoluzza/DreeRally.git
- `upstream`: https://github.com/enriquesomolinos/DreeRally.git
- Rama inicial: `0.3.x`.
- Identidad configurada sólo en este clon: Mariano Luzza, marianoluzza@gmail.com.

Para futuras tareas, crear una rama desde la base propia. Inspeccionar cambios upstream antes de integrarlos; no sobrescribir la rama personal.

## Límites actuales

- Falta probar arranque, depuración y carreras con datos compatibles.
- El proyecto silencia muchas advertencias; build exitoso no equivale a ausencia de errores.
- Los builds muestran advertencias de mezcla de runtime MSVCRT/MSVCRTD (LNK4098) y de la opción antigua /Gm (D9035); se conservan para estudiar después de obtener una referencia funcional.
- CI heredado y migración a CMake quedan registrados en el [roadmap](../ROADMAP.md).
