# Roadmap de DreeRally

Fork de [enriquesomolinos/DreeRally](https://github.com/enriquesomolinos/DreeRally), rama `0.3.x`.

## Estado

La v1 está lista: una campaña completa se juega en Windows, en Debug y en Release, desde una partida
nueva hasta ganarle al Adversary, sin cierres y con la memoria estable. Casi todo lo corregido eran
errores de la traducción del decompilado, cotejados con el `dr.exe` 1.0 de Windows.

- Qué se arregló: [doc/CHANGELOG.md](doc/CHANGELOG.md).
- Compilar, probar, diagnosticar y trampas del decompilado: [doc/DEVELOPMENT.md](doc/DEVELOPMENT.md).
- Formato de las partidas: [doc/SAVEGAME.md](doc/SAVEGAME.md).

## 1. Devolución a upstream

PR a `enriquesomolinos/DreeRally`, rama `0.3.x`, con la base fiel al original. Quedan fuera los
cambios propios del fork: este ROADMAP, la configuración de VS Code para Windows y Alt+Enter
desactivado.

## 2. Fidelidad pendiente

- `dr.cfg`: `fread`/`fwrite` de 4 bytes sobre `word_462D54` (2 bytes).
- Fundido de paleta de la carrera (`sub_404C30`, `sub_4055A0`), con su tabla de floats en 0x4B3400.
- Titileo del menú (`sub_4220D0`): el bucle de paleta corre una sola vez.
- Buffer de teclas `dword_4A7D20` a 64 bytes, y `int debug = 1` en `dr.c`.
- `BYTE` sin signo en `defs.h`; tipos de los polígonos 3D del escenario (casos 0x80–0x8A).
- Restos de memoria (~0,3 MB por carrera) y tres `free` comentados en los gráficos del menú.
- Multijugador: mismos patrones (`previewRaceScreen`, corrimiento de noticias); fuera de alcance por
  ahora.

## 3. Mejoras propias

Cambian el comportamiento del original, así que van después del PR y en commits separados.

- **Pantalla completa en 4:3.** Alt+Enter alterna ventana y pantalla completa (0x43BCD9), que pasa
  el monitor a 640×480 y en uno ancho se ve estirada. En la v1 está desactivado (`dr.c`, `SDL_KEYUP`);
  vuelve cuando la pantalla completa respete el 4:3 (franjas o fondo a los costados). Escalado y
  relación de aspecto de la ventana.
- **IA trabada contra una pared.** De frente a un borde sigue acelerando hasta que otro coche la
  empuja; el modo de retroceso (`dword_4A7E80`) nunca se activa, tampoco en `dr.exe`. Por ejemplo,
  marcha atrás girando tras unos segundos sin avanzar.
- **Joystick.** Conexión en caliente (SDL 1.2 lo abre una vez al arrancar) y mando apagado (el eje
  queda en un extremo y las pantallas que esperan una tecla avanzan solas). Más botones: hoy solo se
  leen los 0 a 3; mapear hombros, gatillos y pad digital.
- **Racha de victorias entre partidas.** `consecutiveWins_456BA8` no se guarda y al cargar vuelve a 0.
  Guardarla en uno de los campos sin uso del registro del jugador (`unk_460860..68`), sin cambiar el
  formato; lo mismo para `noPaintJob` y `allCarsCrash`.
- **Nombre del piloto de 11 letras.** La licencia limita a 10, pero `name` mide 12 bytes en todas
  partes. Más de 11 cambia el formato del guardado.
- **Grises, blanco y negro para el auto del jugador.** `COPPER.PAL` no tiene grises; pisar en memoria
  los índices 248–254 después de `extractFromBpa("copper.pal")`. Cuidado con `sub_418B00`, que tiñe
  los menús con ese color: probar un gris muy oscuro.
- **Capturas en PNG**, con fecha en el nombre y una por pulsación (hoy PCX, una por cuadro mientras
  F6 sigue apretada, hasta 100 por carpeta).
- **Todos los circuitos en cualquier dificultad**, quizás como opción.
- **Evento "todos hongos"**: ya existe como prueba (`DREERALLY_FORCE_MUSHROOM=1`); darle un lugar en
  el juego.
- Rutas de datos y guardados configurables; organización e idioma de los menús.

## 4. Base mantenible

- CMake con presets para MSVC x86, comparado con el proyecto actual.
- Actualizar el CI heredado (rutas de Visual Studio 2019 y acciones antiguas).
- Bajar la línea base de advertencias (`scripts/warnings-baseline.txt`).
- Más pruebas de carga de archivos y serialización; reducir globales de a poco.
- Linux, después de Windows. Migración de SDL/audio, motor nuevo y 64 bits quedan para más adelante.

## Forma de trabajar

- Antes de tocar física o reglas, comprobar en el ensamblador del original qué hacía; si el original
  hace lo mismo, no es un arreglo sino una mejora propia (sección 3). Un error evidente que el
  original también tiene (el final en negro) sí se corrige.
- Un cambio de comportamiento por vuelta, para poder atribuir las regresiones. Probar también en
  Release.
- Commits de fidelidad separados de las mejoras; ramas para cada tanda. Conservar la atribución a
  upstream.
