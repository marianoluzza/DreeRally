# Roadmap de DreeRally

Fork personal: https://github.com/marianoluzza/DreeRally
Base: https://github.com/enriquesomolinos/DreeRally, rama `0.3.x`, commit `bb0712748a658d00b0bb9672d78a61f367e53fde`.

## Objetivo

Una versión jugable en Windows actual que preserve el manejo, las carreras y la progresión de Death Rally. Primer hito funcional: arrancar, navegar el menú, completar una carrera y volver a los resultados sin fallos.

Se conserva el historial upstream. VS Code es el editor; la compilación inicial usa el proyecto existente con MSVC Win32. CMake y los cambios grandes vienen después de una referencia jugable.

## 0. Preparar el proyecto

- [x] Crear el fork en la cuenta personal marianoluzza.
- [x] Clonar y separar remotos `origin` (personal) y `upstream` (original).
- [x] Configurar identidad Git local con el correo personal.
- [x] Preparar tareas de compilación y depuración en VS Code.
- [x] Compilar Debug y Release con MSVC v142 y Windows SDK 10.
- [x] Revisar el inventario de assets DOS indicado por Mariano.
- [x] Aislar assets, partidas y configuración local de Git.
- [ ] Validar ejecución y depuración con datos compatibles.

Salida: checkout reproducible y ejecutable compilado. Esto todavía no acredita que el juego sea jugable.

## 1. Resolver los datos y lograr el primer arranque

Prioridad P0; bloquea todas las pruebas del juego.

- [x] Extraer los datos y DLL de la edición Windows aportada por Mariano, manteniéndolos fuera de Git.
- [ ] Validar formatos y arquitectura x86 de SDL 1.2 y FMOD 3.x; no reemplazarlas por SDL2/SDL3 o FMOD modernas sin adaptar el código.
- [ ] Comprobar las animaciones `SANIM.haf`, `ENDANI.haf` y el uso condicional de `ENDANI0.HAF`.
- [ ] Revisar rutas de carga y errores cuando faltan archivos.
- [x] Arrancar con `-window`, pasar la intro y llegar al menú (confirmado por Mariano).
- [x] Cerrar normalmente y verificar que no queden procesos (sesión del 18/09: SDL_QUIT y salida 0).
- [ ] Confirmar un breakpoint en VS Code.
- [x] Registrar argumentos, build, eventos y fallos por sesión; conservar binario, símbolos y volcado con ProcDump.

Assets preparados desde el instalador Windows. Corrección: TRX.BPA era una referencia genérica; se usan TR0.BPA a TR9.BPA, cuyos hashes coinciden con la copia DOS examinada. Las animaciones y DLL x86 ya están presentes. El proceso propio arrancó y responde; Mariano confirmó la intro y el menú. Falta validar jugabilidad. Ver [assets](doc/ASSETS.md).

Salida: menú visible y controles básicos estables.

## 2. Completar una carrera

Prioridad P0; depende del arranque.

- [x] Seleccionar piloto, coche y circuito; nombre y Backspace probados el 18/09.
- [ ] Verificar aceleración, freno, dirección, colisiones y límites de pista.
- [x] Comprobar vueltas, posiciones, oponentes y finalización (dos carreras seguidas el 20/09).
- [x] Terminar una carrera y volver a resultados/tienda.
- [ ] Comprobar armas y daño (el porcentaje de daño todavía no se lee bien en el HUD).
- [ ] Repetir en varios circuitos y coches, incluyendo abandono y destrucción.
- [ ] Registrar fallos reproducibles con circuito, coche, pasos y resultado esperado.
- [ ] Comparar comportamiento con el original antes de modificar física o tiempos.

Salida: tres carreras consecutivas completas sin bloqueo, pérdida de controles ni resultados incoherentes. Corregir primero cierres y corrupción de memoria; luego fidelidad.

Diagnóstico del 18/09: el primer volcado detectó un fallo en el dibujo de humo. Se corrigieron accesos fuera de límites en las paletas y referencias antiguas a los participantes. Las pruebas de regresión cubren cinco rutinas de paleta y el humo de los cuatro participantes. Los logs posteriores muestran carga de TR8/TR1 y salida normal, pero todavía no acreditan una carrera completa.

### Sesión del 20/09

Se completaron dos carreras seguidas con vuelta a resultados y tienda. Los fallos encontrados
y su causa, todos errores de la traducción del decompilado (índices, tipos y llamadas
perdidas), no del diseño original:

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| Los coches se atraviesan | La detección de colisión coche-contra-coche estaba comentada desde 0.2 | `dr.c`, llamada a `recalculateRaceCarWithOrientation` |
| ↳ y por eso se comentó | `v5/4` residual y límite de barrido en Y sin inicializar hacían que indexara fuera de `participantCarBpk` | `recalculateRaceCarWithOrientation` |
| Coches clavados contra las paredes | El bucle de recuperación iba de `N` a `1`: leía `raceParticipantIngame[4]` y saltaba al participante 0 | `startRace` |
| La IA no compensaba su motor | Constantes float declaradas `int` (truncaban a 0) y el factor se aplicaba al participante siguiente, con escritura en `raceParticipant2[4]` | `balanceIAEngineInRace_40B920` |
| Cuelgue al elegir circuito | `ceil` sin prototipo: el valor se leía de `eax` en vez del FPU | `carRightSide.c`, faltaba `math.h` |
| ↳ mismo defecto | `sqrt`/`floor`/`ceil` sin prototipo en cinco archivos más | `3dSystem.c`, `lightSystem.c`, `leftBar.c`, `powerup.c`, `shopScreen.c` |
| Cierre al terminar la carrera | `v95`/`v103` sin inicializar usados como puntero; tabla de récords indexada sobre tres enteros sueltos | `raceResultsScreen.c` |
| Basura persistente sobre la pista | Campos de interpolación `int` leídos con `*(float*)&`, y escritura sin comprobar límites | `recalculateCarBoundary_411D10` |
| Los cuatro coches iguales en la parrilla | El recálculo de circuito invertido perdía el banco de sprites por participante | `calculateCircuitReversed_40A9A0` |
| Coches del mismo color en resultados | Índice de rampa de paleta `3*a1-1` en vez de `3*a1-48` | `raceResultsScreen.c`, `sub_424240` |
| Cierre al comprar sin dinero | `strcat` sobre un literal de cadena (memoria de solo lectura) | `hasInsuficientMoneyToBuy` |
| Minutos del tiempo de vuelta | División mágica por 60 con `>> 32` sobre un valor de 32 bits | `leftBar.c` |
| Entrada del jugador perdida | Escritura fuera del array de participantes y doble incremento del índice de frame | `startRace` |

Cambios de infraestructura en la misma sesión:

- `DreeRally.vcxproj` pasó de `TurnOffAllWarnings` a `Level3`. Ese ajuste era lo que
  ocultaba los `ceil`/`sqrt`/`floor` sin prototipo.
- `scripts/Check-Warnings.ps1`: compila con `/W3`, clasifica y compara contra
  `scripts/warnings-baseline.txt`. Bloquea si aparece una advertencia nueva de la lista
  peligrosa. Normaliza el número de línea y compara conteos, para que mover código no
  genere falsos positivos.
- `scripts/Test-RacePalette.ps1` estaba roto: `vcvars32.bat` escribe en stderr aunque
  funcione y con `ErrorActionPreference = 'Stop'` abortaba antes de compilar.
- Registro por pantalla (`pantalla: <nombre>`) y por etapa de carga y de compra, para
  acotar cuelgues sin volver a instrumentar.
- ProcDump con `-h`: los cuelgues no generan excepción, así que `-e` solo no los capturaba.
- `sanitizeValue` en `dr.c`: corta la propagación de NaN/infinito en las cuatro divisiones
  de la física y registra la primera vez que salta. Todavía no saltó en ninguna corrida.

Pendiente, en orden sugerido:

1. **Superposición residual.** Dos coches pueden quedar pegados unos segundos y luego
   despegarse. La separación depende hoy solo de revertir la posición; falta el impulso.
2. **Tipos de la física.** `unk_4A7DFC`, `unk_4A7E00`, `unk_4A7E04`, `dword_4A7DBC`,
   `dword_4A7DC0`, `dword_4A7DC4`, `dword_4A7DF4` y `dword_4A7DF8` son `int` pero se usan
   como float, así que el impulso de choque se trunca. Pasarlos a float el 20/09 hizo que
   los coches salieran disparados: el truncado a `int` estaba absorbiendo un NaN. Las
   guardas ya están puestas; reintentar **de a un grupo**, empezando por los tres de choque.
3. **Buffer de teclas.** `dword_4A7D20` es `char[16]` pero se escribe con `*(_DWORD*)`,
   así que cada `|=` pisa los tres frames siguientes. Debería ser `int[16]` (64 bytes,
   que es lo que ocupa en el binario original). Afecta a la entrada de la IA.
4. **`int debug = 1;`** en `dr.c`. La bandera de depuración está encendida y la única
   escritura correcta del buffer de teclas del jugador está detrás de un `if(debug)`.
5. **Daño en el HUD.** El cálculo es correcto; falta ver qué dibuja `drawSprite_402590`.
6. **Deuda restante del gate**: 5 `C4739` en `ui/menu.c` (escritura fuera del
   almacenamiento de una variable) y 2 `C4700` en `ui/hallOfFame.c`.

### Sesión del 26/09

Tres carreras seguidas (easy, medium, hard) con tienda entre medio. Resuelto, otra vez
todo en la traducción del decompilado:

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| Coches pegados tras chocar | Banderas `c0`/`c2` de `fcomp` perdidas y fijadas a 0: el empuje ignoraba qué coche estaba a cada lado | `recalculateRaceCarWithOrientation` |
| Cierre al empezar la 2ª carrera | Bucle de copia residual pisaba `"TRn"` con una tabla local sin inicializar | `previewRaceScreen` |
| Daño por choque siempre 0 | Bucle con offsets crudos desde el valor (no la dirección) de `damageBar` | `startRace` |
| El HUD solo mostraba `%` | `drawSprite_402590` sin prototipo recibía un `__int64` y corría los argumentos | `leftBar.c`, `dr.h` |
| Cartel de salida/llegada invisible y cierre al salir | `malloc(4)` para pedazos de 16 bytes; `&unk_460000` usado como constante `0x460000` (70 en 16.16) | `dr.c`, `dr.h` |
| Fuego del disparo en un solo coche | Globales por participante indexadas con la zancada `216 * i` (y fuera de `int[256]`) | `drawGunFlames`, `drawShots`, otros |
| Cierre al salir de una carrera media | Textos armados sobre locales supuestamente contiguos en la pila | `drawStadistics` |
| Colores cruzados en resultados, coche oscuro en la tienda | Prototipo `float` contra definición `double`; rampa en `a1-16` en lugar de `a1` | `sub_424240`, `sub_418B00` |
| Cierre al cargar con drogas en pista | Valor de `posX` usado como puntero | `generateBigPowerUps` |
| Cierre al salir del juego | Falta `end.bmp` | `showEndScreen` |

Infraestructura: `diagnostics.c` registra los carteles del CRT de Debug con la pila, y el
gate trata `C4028` (parámetro distinto de la declaración) como peligroso.

Pendiente, en orden sugerido:

1. **Resultados de tu carrera.** La tabla de la carrera propia muestra al jugador y a
   Jane Honda repetida tres veces; los puntos y la posición del ranking no se actualizan
   bien.
2. **Estadísticas.** "Races won 9" tras dos carreras, "Position 20", y los ingresos de la
   carrera en `$0`.
3. **Tipos de la física** (`unk_4A7DFC`, `unk_4A7E00`, ...): el impulso truncado a `int`
   hace que el daño por choque casi nunca sume. De a un grupo, con `sanitizeValue`.
4. **Iluminación.** Sectores oscuros de la pista y el haz de luz de los coches se ven con
   un tramado de puntos.
5. **Tienda.** Los logos de los sponsors salen oscuros (el color del coche ya quedó bien
   con el arreglo de `sub_418B00`, verificado el 26/09).
6. Buffer de teclas `dword_4A7D20` a `int[16]` y apagar `debug` (pasos 2 y 3 del plan).

### Resultados, ranking y textos (26/09, segunda tanda)

Pendientes 1 y 2 resueltos y verificados por Mariano con dos carreras (media 2.º, fácil 1.º):
6 puntos, 1 ganada de 2, del puesto 20 al 18, textos de sponsor y prestamista completos.

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| Jane Honda repetida en la tabla de la carrera | Puesto inicial tomado como índice en lugar de la dirección del puesto | `recalculateRacePositions_413380` |
| El ranking no se actualizaba | `sub_423C90`/`recalcRank` quitados; `recalcRank` copiaba `drivers` sobre sí mismo y el intercambio usaba `unk_4611E0` (un byte) como buffer | `postRaceMain`, `dr.c` |
| "Races won" mostraba el daño | El daño del coche se guardaba en `racesWon` | `previewRaceScreen` |
| Ingresos de la carrera en `$0` | Asignación de `v126` absorbida por un `if` comentado; máximo de puntos leído de un array suelto | `previewRaceScreen`, `getMaxDriverPoints` |
| Parrilla con basura, jugador en otro coche | Orden de la parrilla armado sobre locales supuestamente contiguos en la pila | `selectRaceScreen` |
| Textos de sponsor, préstamo, tienda y reparación cortados o con basura | Tablas por coche transcritas como una sola cadena e indexadas `&cadena[800 * n]` | `originalTexts.c`, generado desde `dr.exe` por `tools/originalTexts.py` |
| Cierre al comprar un coche | `malloc` sin sitio para el `$` | `showCarBought` |
| El hongo duraba un cuadro | `=-` en lugar de `-=` | `startRace` |
| La IA disparaba hacia atrás | Paréntesis perdidos en grados→radianes | sensores de disparo de la IA |
| Dejaban de aparecer power-ups | El conteo leía `powerups[16..20]` | `generatePowerUps` |

Herramienta nueva: el `dr.exe` original (`.local/original-exe/`) se desensambla con `dumpbin
/disasm` y las direcciones coinciden con las del decompilado. Sirve para confirmar tipos y
lógica: las ocho globales de física del punto 3 son todas `float` en el original (`fld`/`fstp
dword`, nunca `fild` ni `mov`).

Pendiente, en orden sugerido:

1. **Tipos de la física** (ver arriba), ahora contrastando con el ensamblador.
2. **Coche del jugador demasiado bueno.** Acelera, dobla y aguanta como con todas las mejoras;
   explicaría en parte el poco daño. Revisar qué nivel de motor/gomas/blindaje lee la carrera.
3. **Distancia del sonido.** Disparos y choques de la IA visibles en pantalla que no suenan:
   el cálculo de distancia al jugador los da por lejanos.
4. **Pintura del coche en la tienda** mal hasta que aparece el primer cartel.
5. Iluminación, logos de sponsors y buffer de teclas/`debug` (puntos 4 a 6 anteriores).

### Sesión del 27/09

Todo verificado por Mariano en pantalla, salvo lo marcado. Otra vez, errores de la traducción;
lo del Dervish (10000 en vez de 12000) parecía un error del original y no lo era.

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| Coche del jugador "con todas las mejoras", casi sin daño | `arrayv59` (blindaje por coche) corrida cuatro lugares | `initParticipantValues_401060` |
| Ningún coche derrapaba | `efectiveTire` era `int` (0,5/0,3/0,1 → 0); dos `fabs` perdidos en `c0`/`c2` | idem, `0x40BAB0` |
| Hitman, drogas, sabotaje y préstamo sin nombre ni importe | Líneas armadas sobre locales contiguos en la pila; objetivo de `dword_45EB50` | `popup.c`, `blackMarketScreen.c` |
| El contrato del hitman fallaba siempre | Búsqueda del objetivo en `dword_45EB50`, que ya no se llena | `previewRaceScreen` |
| Sabotaje: cierre al aparecer | `drivers[108 * id]` | `sabotageScreen` |
| Oferta y pago de premios distintos | Constante del Dervish mal leída; ahora una tabla compartida | `popup.c` |
| Rueda de más sobre el cartel de compra; luego quieta | `updateCursor(0)` que no está en el original; faltaban los incrementos de cuadro | `enterShop` |
| Recuadros de menú de 2576 px | Tres altos mal copiados | `dword_445704` |
| Tu fila no se resaltaba en el ranking | Contador que no avanzaba | `writeDriverList` |
| Sombras estiradas por la pantalla | Parche `if (v2 > 200) v2 = 0` sobre índices válidos | `drawShadows_40D7B0` |
| Drogas y power-ups grandes parpadeaban y se esfumaban | Los huecos 12..15 no caducan en el original (solo 0..11) | `powerup.c` |
| Conos de luz con puntos cian/negro/color de coche | `BYTE` con signo en `defs.h`: píxeles ≥ 128 leían antes de la tabla | `iluminateTriangle_43D530` |
| Hongo: franjas negras | Onda de senos desplazada como `_DWORD` sin signo | `sub_404730` |
| Hongo: 50 KB pisados por cuadro; pausa restauraba basura | `unk_481F20`..`unk_491920` eran bytes sueltos de un único buffer | `dr.c` |

Herramientas nuevas (fuera de Git, en `.local/`):

- `original-exe/dr.asm`: desensamblado completo; `tools/origtables.py` y `stackinit.py`
  reconstruyen tablas locales de una función; `tools/sym.py <diagnostic-*> <rva...>` resuelve
  la pila de un volcado con dbghelp.
- `probe/`: sondas que descifran BPK/paletas/sombras con el `decryptTexture` del juego.
- Mapa del linker: `LINK=/MAP:<ruta sin espacios>` antes de `Build.ps1`.
- Variables de prueba: `DREERALLY_FORCE_EVENTS=1` (un cartel por carrera: hitman, drogas,
  sabotaje), `DREERALLY_FORCE_TRACK=TR4` (`TR4R` invertido) y `DREERALLY_FORCE_MUSHROOM=1`.
  Circuitos: `TRn` con n = (índice % 9) + 1, invertido si el índice > 8 (TR4 = Rock Zone,
  TR6 = Oasis de día).

Pendiente para la próxima sesión, en orden sugerido:

1. **Corrupción de `drivers[]` (cierre del 27/09 en `drawRightPositions`).** Bloques escritos
   cada 150 bytes y nombres corridos; no se reprodujo con los canarios puestos (tabla de luz y
   nombres, 14 puntos por cuadro y al entrar a resultados). Pasó con la pista forzada, que se
   cambia después de armar la carrera: descartar eso primero. Quitar los canarios al resolverlo.
2. **`BYTE` con signo.** `defs.h` lo define `char` salvo que se incluya `windows.h`, así que
   cambia de significado según el archivo. Pasarlo a `uint8` en una vuelta propia.
3. **Polígonos 3D del escenario.** El tipo se lee como `char` en vez de `dword` (0x4118BF):
   los casos 0x80–0x8A no se ejecutan y esas caras salen planas. Sus tablas (`unk_46ED00`,
   `unk_4A7BC0`, `unk_4AA400`) son 256 bytes en el original, no un byte. Puede explicar el
   ancho del cono según la zona.
4. **Animación de largada** (`sub_404C30`, comentada): el ángulo `dword_4450A0` queda en 1°.
5. Tipos de la física, coches trabados tras un choque, distancia del sonido de la IA, pintura
   del coche en la tienda, logos de sponsors, buffer de teclas y `debug`.
6. `hallOfFame.c`: cuatro cadenas de un carácter sin terminador (`{ 'A' }`, …).

### Sesión del 03/10

Todo verificado por Mariano en pantalla. Otra vez, globales que en el original eran posiciones de
un mismo buffer y en el port quedaron sueltas, y campos `float` declarados `int`.

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| Corrupción de `drivers[]` tras una carrera (cierre del 27/09) | Las noticias del menú (22 líneas × 150 bytes en 0x462000 y su color en 0x461EC0) estaban partidas en ~35 globales sueltas; el desplazamiento corría hasta `&blacktx1Bpk` y pisaba memoria cada 150 bytes. No tenía que ver con la pista forzada. Ahora son dos buffers y las globales, alias en `dr.h` | `sub_4279C0`, `sub_427BC0` |
| Humo de derrape "corrido" a la altura del jugador | La Y de la rueda trasera derecha de cada coche usaba la posición del jugador | `recalculateCarBoundary_411D10` |
| Textos de otro menú al volver con Escape | `sub_41ACF0` leía la tabla vieja de 50 bytes por texto; además "Continue Racing" (16 bytes) en `char[13]` | `ui/menu.c` |
| Cierre al cargar partida (en la inscripción) | La tabla de ranuras (10 × 50 bytes, 0x446C32) era un byte: "Empty Slot" pisaba `graphics4` | `loadSaveGameScreen.c` |
| El prompt de guardar decía "Empty Slot" / no ofrecía el nombre | Copia del nombre comentada (0x41C9D0) y comparación con un `int` en vez de "Empty Slot" | `savegame.c` |
| Coche del color del fondo en el Underground al cargar | La rampa del fondo iba a `palette1[192]` (color 64, la del coche) y no a `[576]` (color 192) | `sub_4224E0` |
| Coches enganchados tras chocar | Impulso, giro y posición anterior del choque son `float` en el original; como `int` el impulso < 1,4 px se perdía. El intento del 20/09 fallaba porque los coches 1–3 guardaban `LODWORD` (los bits) de la posición | `unk_4A7DFC/E00/E04`, `dword_4A7E50/54` |
| Memoria creciendo ~1 MB/s hasta 1,4 GB | `decryptTexture` no liberaba sus tres tablas (el original sí); el menú de carga descifraba la partida en cada dibujado; 100 bytes por cuadro en `refreshAndCheckConnection_42A570`; `hash_index` copiaba todas las claves en cada búsqueda | `dr.c`, `savegame.c`, `util/hash.c` |

Canarios del 27/09 retirados. Prueba nueva: `DREERALLY_FORCE_OPPONENT_LIFE=40` arranca a los
rivales con esa vida (no guardar encima de la partida buena: el daño queda en su ficha).

Herramienta nueva para memoria: volcado completo con `procdump -ma -r <pid>` (clona el proceso,
casi no lo congela) y recorrer el heap de depuración del CRT. Cada bloque va precedido por
`next, prev, file, line, blockUse, dataSize, request` (7 × 4 bytes) y `FD FD FD FD`; agrupar por
`dataSize` con `blockUse == 1` da el culpable al instante (script en el scratchpad de la sesión,
fácil de rehacer).

Pendiente para la próxima sesión, en orden sugerido:

1. **Física, segundo grupo**: `dword_4A7DBC`, `dword_4A7DC0`, `dword_4A7DC4`, `dword_4A7DF4` y
   `dword_4A7DF8` son `float` en el original. Luego las ocho posiciones de rueda
   (`front/backLeft/RightAbsoluteX/YPosition_4A7E10..44`), también `float`: al pasarlas,
   restaurar el redondeo del humo desde 0,5 (0x412745).
2. **IA contra una pared**: si un choque la deja de frente a un borde, sigue acelerando contra él
   hasta que otro coche la mueve (TR8, bajo el puente). Ver si el original tiene recuperación.
3. **Memoria por carrera** (~15–25 MB): `free` comentados al terminar la carrera (imágenes del
   circuito, escenario 3D, `genflaBpk`, cohetes, humo…). Restaurarlos de a uno. Quedan además
   `malloc(100)` sin liberar en `drawRightPositions` y otras pantallas, y `Str` (global
   compartida) se reserva en cada `decryptEntireSavegame`.
4. **Titileo del menú** (`sub_4220D0`): el bucle compara una dirección con
   `maxPaletteEntries*3` y corre una sola vez; en el original recorre `palette2` hasta 0x461424.
5. "Continue Racing" / "Enter The Shop": el original cambia esos textos al empezar partida, pero
   `getMenuText` siempre devuelve los de inicio (faltaría también su traducción).
6. Siguen los pendientes del 27/09: `BYTE` con signo, polígonos 3D, animación de largada,
   distancia del sonido, logos de sponsors, buffer de teclas, `debug` y `hallOfFame.c`.

### Sesión del 03/10, segunda tanda

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| Derrape corto, coleadas pobres | Deslizamiento lateral `dword_4A7DBC` declarado `int` (se truncaba); también `DC0`, `DC4`, `DF4`, `DF8`, que son `float` en el original | `RaceParticipantIngame`, `calculateUserMovements_40BAB0` |
| Marcas y chirrido de derrape según el lado | `fabs` del deslizamiento (0x4124A2) traducido como "negar si DC0 o DC4 no son 0" | `recalculateCarBoundary_411D10` |
| Los pinchos casi no hacían daño | Paréntesis perdidos: el segundo sensor sumaba la posición en lugar de restarla (0x40D457) | `recalculateRaceCarWithOrientation` |
| En dificil salian los circuitos faciles; Downtown, Bogota y Velodrome (y sus invertidos) nunca | Las tres dificultades tomaban la tabla de circuitos desde el principio; el original usa los tramos 0..4, 2..7 y 5..8 | `selectRaceScreen` |
| Animación del motor que "se corre y vuelve" tras comprar | Tablas de tamaños de cuadro copiadas a mano con tres valores mal (motor 37, reparación 22, continue 1); cotejadas con la `.data` | `anim.c` |
| La bandera de "continue" aleteaba rapidísimo en la tienda y quedaba quieta al entrar al Underground | Avanzaba módulo 2 en la tienda y no avanzaba en la transición; el original recorre 23 cuadros en los seis lugares. Reparación: 24 cuadros, no 23 | `shopScreen.c`, `blackMarketScreen.c` |
| Interferencia en voces y explosiones, efectos a destiempo | El stream de efectos se creaba con `FSOUND_UNSIGNED` (0x80); el original usa 0x50, 16 bits estéreo con signo, que es lo que entrega el mezclador. Para compensar, upstream dividía el volumen de los efectos por 32 (`>>5`), fijaba la envolvente en 64 y la inicializaba en 32; el original multiplica por `envvol` sin correr y lo arranca en 64 (0x43E994, 0x43EB36). Además el período se multiplicaba por 0,62 (sube la nota ~×4) para compensar que FMOD leía el stream como 8 bits mono, cuatro veces más lento (0x43EC2E) | `loadMusic`, `soundSystem.c` |
| El menú seguía diciendo "Start Racing" / "Start A New Game" con una partida en curso, y tras cargar una partida "Start A New Game" llevaba a la licencia | Cada pantalla escribía "Continue Racing" / "Enter The Shop" en su propia copia del texto y `getMenuText` leía otra tabla; ahora es un único par de buffers, con traducción | `menus.c`, `menu.c`, `loadSaveGameScreen.c`, `prevRaceScreen.c`, `shopScreen.c` |
| Cierre en la tienda con blindaje ≥ 1 | Tabla de cuadros del blindaje indexada de a 16 bytes en vez de 64 (0x420ADB); el tope comparaba con las mejoras de motor | `reloadArmourAnimation2` |

Mariano confirmó que las coleadas andan mejor; tres carreras sin valores no finitos en la física. El sonido quedó "impecable" (Mariano, 03/10). Circuitos por dificultad: diez rondas registradas en el log (`circuitos:`), todas dentro de las listas del original. El cierre de
la tienda las animaciones de la tienda y los textos del menú también verificados.

Revisado sin cambios: la IA contra una pared (pendiente 2 del 03/10) es fiel al original. El
modo "retroceder girando" (`dword_4A7E80`) nunca se activa, ni siquiera en `dr.exe`; la única
recuperación es el rebote y la búsqueda de hueco al azar con `E94 > 3`, que conserva el rumbo,
así que un coche de frente al muro sigue trabado hasta que otro lo empuja. Salir de esa traba
queda como mejora propia (sección 5). Sonido de la IA lejana: el volumen cae lineal con la distancia (36864 − 75·d, se corta a ~430 px)
igual que en el original, así que en pantalla suena muy bajo; los choques entre coches de la IA
no tienen sonido en el original. Tampoco importa el `abs` que upstream agregó al sensor
`LR1`: el mapa vale 0..15 en los diez circuitos.

Pendiente para la próxima sesión, en orden sugerido:

1. **Memoria por carrera** (~20–30 MB por carrera; el 03/10 subió de 100 a 168 MB en una sesión):
   `free` comentados al terminar la carrera (imágenes del circuito, escenario 3D, `genflaBpk`,
   cohetes, humo…), `malloc(100)` sin liberar en `drawRightPositions`, `reloadArmourAnimation2` y
   otras pantallas, y `Str` reservado en cada `decryptEntireSavegame`. Restaurarlos de a uno,
   cotejando con el original, y medir con `procdump -ma -r` + heap de depuración.
2. **Titileo del menú** (`sub_4220D0`): el bucle de paleta corre una sola vez (ver arriba).
3. **`BYTE` con signo** en `defs.h`, en una vuelta propia.
4. **Polígonos 3D del escenario** (tipo leído como `char`, casos 0x80–0x8A sin ejecutar).
5. Animación de largada (`sub_404C30`), logos de sponsors en la tienda, buffer de teclas
   `dword_4A7D20` a `int[16]` (el original lo indexa de a 4 bytes) y `debug`, `hallOfFame.c`.
6. Antes del PR a upstream: decidir qué infraestructura local va (ver "Forma de avanzar").

### Sesión del 04/10

Todo verificado por Mariano en pantalla. La memoria privada subía ~50 MB por carrera; ahora queda
plana (124,4 → 127 MB en seis carreras, las tres últimas sin cambio). La mayor parte eran `malloc`
cuyo puntero se pisaba enseguida, y varios `free` restaurados destaparon desbordes viejos.

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| ~20–30 MB por carrera | El original libera 34 buffers al terminar la carrera (0x4179CE) y el port 21: circuito, escenario 3D, pantalla, bandera, mensajes, cohetes, humo… | `dr.c` (fin de carrera) |
| Una copia de los gráficos del menú por cada vuelta | `extractFromBpa` reservaba un buffer del tamaño de cada archivo extraído y leía en el destino del que llama | `asset/bpaUtil.c` |
| 11 MB en un rato de tienda | `autoLoadSave` (F2/F3, 0x4221A0) reservaba dos partidas al declarar variables, y la tienda lo llama en cada cuadro | `dr.c` |
| Pérdidas menores en cada carrera y pantalla | La pausa reservaba tres copias de pantalla y no liberaba ninguna (0x40696F); `malloc(10)` por cuadro sin su `free` (0x416478); la tabla del BPA (4 KB) en cada `getFileSizeFromBpa`; HAF sin liberar un buffer de 64 KB; unos 20 `malloc(100)` que en el original eran buffers locales | `dr.c`, `bpaUtil.c`, `haf.c`, pantallas |
| ~4–7 MB por canción cargada | `FMUSIC_FreeSong` (0x43D940) solo detenía la canción; `loadMusic` perdía los dos archivos (0x43CD3B los libera); el archivo en memoria de minifmod copiaba el banco de efectos a un `calloc` que no usaba | `soundSystem.c`, `sound.c` |
| Cierre en la intro al liberar la música | La música la carga `fmod.dll` y el original la libera con su `FMUSIC_FreeSong` (0x43F89A), no con el de minifmod; el cargador MOD procesaba dos instrumentos de más (`v53 <= numinsts`), las muestras de un instrumento se leían todas sobre la última y la tabla de patrones se dimensionaba antes de calcular `numpatternsmem` | `sound.c`, `soundSystem.c` |
| Quick save: la ranura decía "Quic" y F3 no cargaba la partida | `byte_460840` es `drivers[]` en el original y aquí una global suelta (F2 grababa una tabla vacía); el nombre se armaba con locales contiguos de la pila (esp+18h..26h) | `autoLoadSave` |
| El reintegro del auto no seguía al original | Restaba 5 en vez de `ceil` y no ponía en 0 la última cifra (0x437480). Crece con cada reparación y mejora porque suman al valor del auto | `shopScreen.c` |
| Manchas bajo la descripción de Shrieker, Wraith y Deliverator | Quinta línea leída de `&unk_44E118 + 1760 * auto` (un byte suelto); en el original está vacía en los seis | `reloadCarAnimation2` |
| Llama del turbo rara | El original elige `rocket1Bpk`/`rocket2Bpk` según el cuadro (0x40F592); el port sumaba el cuadro como un byte y leía columnas de `&rocket1Bpk` | `drawRocket_40F450` |

Revisado sin cambios: el original tampoco libera el `Str` de `decryptEntireSavegame` (2 KB por
ranura al abrir el menú de carga). La línea de log `tienda:` (valor del auto, daño, reintegro) se
agregó para diagnosticar; decidir antes del PR si queda.

Pendiente para la próxima sesión, en orden sugerido:

1. **Restos de memoria** (~0,3 MB por carrera): bloques de 4096 bytes que se reservan al cargar
   cada carrera intercalados con reservas de 2 bytes (origen sin encontrar), y tres `free`
   comentados "porque petaban" en los gráficos del menú (`dword_461EA4`, `carnameBpk`,
   `shoptxt1/2Bpk`); el original los libera y el port reserva igual o más, así que no es por tamaño.
2. **Nombres de teclas en el menú de pausa**: `unk_4A6B20` y `unk_479E40` (de a 15 bytes) son bytes
   sueltos en el port, el mismo patrón que la tienda.
3. **Titileo del menú** (`sub_4220D0`), **`BYTE` con signo** y **polígonos 3D**, como antes.
4. Animación de largada, logos de sponsors, buffer de teclas, `debug`, `hallOfFame.c`.
5. `byte_460840` en el multijugador (fuera de alcance por ahora).
6. Antes del PR a upstream: decidir qué infraestructura local va (ver "Forma de avanzar").

Método que funcionó y conviene repetir: lanzar el juego con
`scripts/Start-Diagnostics.ps1`, que Mariano pruebe y reporte con capturas, y resolver cada
volcado con símbolos antes de tocar código. Un cambio de comportamiento por vuelta, para
poder atribuir las regresiones.

### Sesión del 11/10

Herramientas nuevas, locales en `.local/` (no van al repo): **Ghidra 12.1.4** y
`.local/tools/decomp.py`, que descompila funciones del `dr.exe` original con los nombres y el
archivo:línea de nuestra traducción (`-x` referencias, `--dump` todo a un archivo). El análisis
corrige el CRT que Ghidra no reconoce (`_ftol2`, `__alldiv`, `__allshr`), sin lo cual el código
con floats sale roto. Y `.local/tools/sweep.py`, que cruza los accesos del original con las
direcciones reales del PDB de Debug y dice qué variable del port pisa cada uno: tablas que el
decompilado partió en globales de un byte, bucles hasta `&otraGlobal` y copias más grandes que su
destino. Lo que coincide con el layout del original por suerte lo descarta.

Verificado por Mariano en pantalla, salvo el joystick (sin conectar todavía):

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| Entrar a definir teclado o joystick pisaba cientos de KB de globales | La tabla de nombres de teclas (0x462DA0, 256 × 15) era un byte y se llenaba con "UNAVAILABLE " hasta `&numberOfLaps`, que en el port está a ~340 KB | `sub_41CA40` |
| Precios del mercado negro pisados al pasar por esos menús | Las opciones de los menús 5 a 8 (líneas de 50 bytes desde 0x446C32) eran globales sueltas y los títulos se copiaban (24–32 bytes) sobre `rocketCost`, `sabotageCost`, `spikesCost` | `redefineControls`, `defineGamepadJoystickMenu` |
| Los menús de teclado y joystick no mostraban la tecla de cada acción | El port reemplazó las líneas del original ("Steer Left … left arrow") por etiquetas fijas | `getMenuText` |
| La pantalla de teclas en carrera (F1) mostraba las teclas de fábrica, con basura sobre ACCELERATE | No armaba la tabla de 0x4A6B20 ni componía las líneas; dibujaba texto fijo | `keyMenuInRace_407330` |

Los nombres de teclas salen de emular las funciones originales en Ghidra
(`tools/ghidra/DumpKeyNames.java` → `ui/util/keyNames.c`) y las líneas de los menús de
`tools/originalTexts.py`, con las globales viejas como alias (`ui/util/menuTexts.h`). Con la
etiqueta traducida no sirve el relleno del original: se muestra la traducción y la tecla.

Pendiente para la próxima sesión, en orden sugerido (lo demás del barrido, todo vivo):

1. **Probar el joystick**: menú Define Gamepad/Joystick y la parte de joystick de F1.
2. **Récords por circuito** (`drawRecordByCircuit`, `hallOfFame.c:645`): lee los nombres de
   `unk_45F8BC + 24 * i`, un byte suelto.
3. **Mensaje al ganar el juego** (`sub_427BC0`): las cuatro líneas de 70 bytes ("Ah, fortune and
   glory! …", desde 0x456618) quedaron reducidas a su primera letra; van a `originalTexts.py`.
4. **`dr.cfg`**: `fread`/`fwrite` de 4 bytes sobre `word_462D54` (2 bytes) pisa dos bytes de
   configuración recién leídos. Hoy no se nota.
5. **Capturas** (`makeSnapshot_429DC0`): la cabecera PCX de 128 bytes (0x456848) es un byte.
6. **Release no enlaza**: `diagnostics.c` usa `_CrtSetReportHook2`, que solo existe en Debug.
7. `sub_404C30` y `sub_4055A0` no se llaman, y el original sí las llama desde la carrera
   (0x41787C, 0x417963): falta un fundido de paleta. Antes de conectarlas hay que arreglarles la
   tabla de 3 KB de floats (0x4B3400, `unk_4B3404` es un byte) y una docena de bucles hasta
   `&otraGlobal`.
8. Siguen los del 04/10: restos de memoria, titileo del menú, `BYTE` con signo, polígonos 3D,
   animación de largada, logos de sponsors, buffer de teclas, `debug`.

### Sesión del 11/10, segunda tanda

Pruebas hacia la 1.0 desde un save cerca de la final, hasta ganarle al Adversary. Mariano confirmó
que F2/F3 (silenciar música y efectos) andan, que el joystick navega los menús, la voz de la
dificultad, el final (animación, Hall of Fame y mensaje, con `DREERALLY_FORCE_ENDING=1`), las
noticias, el espaciado de las letras, MUSIC VOLUME con su `%` y las capturas F6 (menú y carrera). Sin
verificar todavía: récords por circuito y la escena `ENDANI0` (primera vez 1.º en puntos).

Casi todo fue la misma trampa: locales que en la pila del original eran contiguas (un texto se
completaba buscando su final desde la variable anterior). En el port caen sobre otras locales.

| Síntoma | Causa | Dónde |
| --- | --- | --- |
| Cierre al entrar a MUSIC VOLUME después de usar SOUND | El `%` se agregaba buscando el final del texto desde `&v19`; caía sobre `v18`, la posición del deslizador de música (0x25252540). En la rama de música estaba comentado "porque peta" | `showAdjustOptions` (`menu.c`) |
| Cierre al entrar contra el Adversary; su nombre bien, el del jugador no | El "." del puesto se escribía desde `&v246` sobre `raceIdParticipants` (un rival basura, cierre al leer su color); el nombre se copiaba de `byte_460840`, que aquí no es `drivers[]` | `previewRaceScreen` |
| En carrera el Adversary se llamaba "A" | El original escribe "ADVERSARY"; el port lo cambió a "Adversary" y la fuente de carrera no tiene minúsculas | `previewRaceScreen` |
| Cierre al ganarle al Adversary | "endani.haf" se armaba desde `&v23` sobre un `char Filename`; lo mismo en `openAnimation`, `checkAndOpenAnimation` y en la escena `ENDANI0` (dos copias en `postRaceMain`) | `showEndAnim_4312D0`, `haf.c`, `raceResultsScreen.c` |
| Hall of Fame al ganar: punteros sin inicializar (`v8`, `v17`) | El decompilado quedó a medio pasar a `hallOfFameEntries`; reescrita como el original | `showHallOfFameEndGame_430FA0` |
| Hall of Fame del menú con una sola fila | El "." del puesto desde `&v21` pisaba el contador del bucle | `seeHallOfFame` |
| Mensaje del final reducido a "A", "S", "f", "k" | Las cuatro líneas (0x456618) eran de un carácter | `sub_427BC0` |
| No se veía ninguna noticia en los menús | Upstream (2020) cambió la franja por tres líneas fijas propias. Vuelve el dibujo original de las líneas 16 a 21; la bienvenida original más una línea de crédito a DreeRally (la web de upstream está caída, va su GitHub) | `drawBottomMenuText`, `initMenuNews` (`bottomText.c`) |
| Noticias de True Tom tras cada carrera: solo había la primera de 19 | La tabla (0x455150, 19 × 4 × 70) era una sola; los usados se marcaban en un `int` escribiendo de más (19 bytes desde 0x45F000, ahora un buffer con alias) | `sub_4279C0` |
| Colores de las noticias corridos | Los corrimientos del decompilado perdían las banderas 4, 8, 12, 16 y 20; una sola `scrollMenuNews` corre líneas y colores | `bottomText.c` |
| Huecos entre letras ("ENRIQ UE", "HORIZ ON", Z-I) y la fuente mediana de ancho fijo | Las tablas de espaciado (0x445848..: grande, chica, precios, mediana, contiguas) estaban tipeadas a mano, compensadas con `- 24`, un caso para 'Z', otro para 'z' y `-23`. Ahora es el bloque del original con alias; `drawTextWithFont` lee `tabla[c - 30]` como el original | `imageUtil.c`/`.h` |
| Las teclas reservadas (P, Tab, F1-F12, Esc) se comparaban con basura | Las 15 eran locales contiguas en el original | `sub_4284E0` (`menu.c`) |
| El panel derecho copiaba el dinero sobre la pila | Mismo patrón, resultado sin uso | `drawCarRightSide` |
| Cierre en VCRUNTIME al salir | El original cierra FMOD en `freeMusic` (0x43C4D0); estaba comentado y el hilo de `fmod.dll` mezclaba sobre memoria liberada | `sound.c` |
| Récords por circuito: minutos "10" en vez de "01" y `malloc` sin liberar | El original rellena los tres campos a dos cifras | `drawRecordByCircuit` |
| Capturas F6 corruptas | Cabeceras PCX de un byte, paleta sobre un `char` de la pila, RLE que comparaba con -64 | `makeSnapshot_429DC0`, `makeSnapshot_4092B0`, `sub_426460` |

Más allá del original (commits aparte):

- El primer resultado se salteaba con el Enter que cierra el cartel de fin de carrera: queda en
  `dword_456BF8` también en el original. Se vacía al cerrar el cartel (`racePauseMenu_4064A0`) y se
  quitó el parche de upstream que ignoraba el Enter en esa pantalla (`|| v54==28`).
- Al correr las noticias, la última línea conservaba su texto y se repetía arriba y abajo de cada
  noticia nueva (en DOS se ven renglones vacíos). Ahora se vacía.
- Prueba: `DREERALLY_FORCE_ENDING=1` pasa una vez por el final al cargar o crear una partida
  (detiene la música antes, como al terminar la carrera, y sale al menú principal). Escribe el Hall
  of Fame en `dr.cfg` como el final real.

Revisado sin cambios (comportamiento del original, ver sección 5): el joystick se abre una sola vez
al arrancar y no se detecta apagado; `SDLCheckJoystick` lee solo cuatro botones; la voz del final
suena igual que en el original (nota relativa +12, ~21 kHz). La "voz rara" y un cierre fueron del
atajo de prueba: con la música del taller sonando quedaban dos streams de efectos.

Pendiente, en orden sugerido:

1. **Ver en pantalla**: récords por circuito y `ENDANI0`.
2. **Release no enlaza** (`_CrtSetReportHook2` solo existe en Debug): bloquea la 1.0.
3. Multijugador fuera de alcance, con el mismo patrón: `previewRaceScreen` (`&v246`), los
   corrimientos de noticias comentados.
4. Siguen `dr.cfg` (`word_462D54`), el fundido de paleta (`sub_404C30`/`sub_4055A0`) y los del 04/10.

## 3. Sonido, campaña y guardados

Prioridad P1; depende de una carrera estable.

- [ ] Validar música y efectos, volumen y opciones de silencio.
- [ ] Revisar economía, tienda, mejoras, reparaciones y mercado negro.
- [ ] Avanzar varias carreras de campaña y comprobar clasificación.
- [ ] Guardar, cerrar, volver a abrir y cargar una partida nueva del fork.
- [ ] Probar slots vacíos y archivos inválidos sin sobreescribir datos.
- [ ] Investigar compatibilidad DOS/Windows de guardados sólo sobre copias.
- [ ] Validar finales y animaciones usadas en cada ruta de progresión.

Salida: una sesión de campaña se conserva correctamente entre ejecuciones; audio estable.

## 4. Hacer reproducible y mantenible la base

Prioridad P1; tras conservar una referencia jugable.

- [ ] Agregar CMake con presets para MSVC x86 y comparar resultados con el proyecto original.
- [ ] Actualizar el CI heredado, que fija rutas de Visual Studio 2019 y acciones antiguas.
- [ ] Automatizar builds Debug/Release y publicar sólo binarios propios autorizados.
- [ ] Inventariar licencias/procedencia de bibliotecas y créditos antes de redistribuir.
- [ ] Resolver advertencias de runtime y activar advertencias del compilador progresivamente.
- [ ] Agregar pruebas útiles de carga de archivos, serialización y lógica extraíble.
- [ ] Reducir dependencias globales por cambios pequeños con pruebas de regresión.
- [ ] Evaluar Linux después de estabilizar Windows.

Salida: build desde un checkout limpio, instrucciones verificadas y automatización sin assets originales.

## 5. Mejoras de experiencia

Prioridad P2; después de la base estable.

- [ ] Ventana/pantalla completa, escalado y relación de aspecto.
- [ ] Configuración de teclado y gamepad.
- [ ] Rutas de datos y guardados configurables, con mensajes claros.
- [ ] Mejorar organización e idioma de menús sin alterar reglas.
- [ ] Evaluar migración de SDL/audio con comparaciones de jugabilidad.
- [ ] Evento especial "todos hongos": cada power-up chico aparece como hongo. Ya existe como
      prueba (`DREERALLY_FORCE_MUSHROOM=1`) y, según Mariano, es muy divertido; darle un lugar
      en el juego (carrera especial u opción).

- [ ] IA trabada contra una pared: si queda de frente a un borde sigue acelerando contra él
      hasta que otro coche la empuja. Pasa también en el original. Mejora propia, por ejemplo
      marcha atrás girando tras unos segundos sin avanzar. Hacerla después de terminar la
      fidelidad con el original.

- [ ] Joystick conectado en caliente: SDL 1.2 lo abre una sola vez al arrancar
      (`SDL_JoystickOpen` en `dr.c`), así que si se prende después no se toma. Igual que el
      original. Mejora propia, después del PR. Al revés también: si el mando se apaga solo
      (ahorro de energía), SDL 1.2 no avisa y el eje queda en un extremo que se lee como
      "izquierda" 36 veces por segundo; cada pantalla que espera una tecla avanza sola (11/10:
      se saltearon la animación final y el Hall of Fame). Detectar el mando apagado y
      desactivarlo.

- [ ] Más botones del joystick: `SDLCheckJoystick` (0x43C650) lee solo los botones 0 a 3
      (acelerar, turbo, disparo, mina) y el stick para dirección y freno; L/R y los gatillos no
      se leen. Igual que el original. Mejora propia: mapear hombros, gatillos (ejes) y el pad
      digital, por ejemplo freno en un gatillo.

- [ ] Nombre del piloto de 11 letras: la licencia lo limita a 10 (`readKeyboard(..., 0xA, 300, ...)`
      en `licenseScreen.c`), pero `name` mide 12 bytes en `drivers[]`, en el Hall of Fame y en
      los récords, y "MATT MILLER" ya ocupa 11 en todas las pantallas. Pasar a 11 no cambia
      partidas ni configuración; más de 11 sí (cambia el formato del guardado). Revisar el ancho
      con letras anchas en carrera, resultados y ranking.

- [ ] Grises, blanco y negro para el auto del jugador: el jugador sale de `COPPER.PAL`
      (una rueda de tonos sin grises, índices pares 0–254 en el taller) y los rivales de
      `CARCOL.PAL` (ahí están Greg Peck, 20,20,20, y Bogus Bill, 45,45,45). Mariano ya probó
      parchear `MENU.BPA` (índices 248–254, que repiten el rojo del 0). En el fork conviene
      pisarlos en memoria después de `extractFromBpa("copper.pal")` y no tocar los datos. Ojo:
      `sub_418B00` tiñe los menús con el color del jugador, así que un negro puro puede dejar
      los resaltados del menú invisibles; probar un gris muy oscuro.

- [ ] Capturas en PNG: F6 guarda `HS-PICnn.PCX` (menús 640×480, carrera 320×200), que Windows no
      abre, y hasta 100 por carpeta. Guardar PNG (sin pérdida, ideal para imágenes de 256 colores;
      JPG mancharía los bordes del texto), quizás al tamaño de la ventana y con fecha en el nombre,
      y una sola por pulsación (hoy guarda una por cuadro mientras F6 sigue apretada, como el
      original). Mejora propia, después del PR.

- [ ] Todos los circuitos en cualquier dificultad (quizás como opción). En el original cada
      nivel tiene su lista (Rock Zone, por ejemplo, no sale en Hard), así que hay pistas que no
      se pueden correr ni pelear su récord en algunos niveles. Mejora propia, después del PR.

Multijugador, motor nuevo, conversión a 64 bits y contenido adicional quedan para una etapa posterior; no son condiciones del primer hito.

## Forma de avanzar

Plan con upstream: primero terminar la base fiel al original (errores de traducción del
decompilado, cierres y pérdidas de memoria) y ofrecerla como PR a
`enriquesomolinos/DreeRally`, rama `0.3.x`. Después vienen las features propias (sección 5),
que ya no son arreglos del original. Por eso cada commit de fidelidad va separado de cualquier
mejora propia, y la infraestructura local (scripts, diagnóstico, variables `DREERALLY_FORCE_*`,
este ROADMAP) se decide aparte antes de armar el PR.

Cada cambio debe tener un objetivo verificable, instrucciones de prueba y evidencia del resultado. Mantener mejoras de infraestructura separadas de cambios de gameplay. Trabajar en ramas para las siguientes modificaciones y conservar siempre la atribución upstream.

Próximo paso concreto: completar la primera carrera y comprobar depuración en VS Code. Assets, intro y llegada al menú confirmados; los assets no se publican en el repositorio.
