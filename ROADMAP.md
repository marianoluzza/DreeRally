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

Método que funcionó y conviene repetir: lanzar el juego con
`scripts/Start-Diagnostics.ps1`, que Mariano pruebe y reporte con capturas, y resolver cada
volcado con símbolos antes de tocar código. Un cambio de comportamiento por vuelta, para
poder atribuir las regresiones.

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

Multijugador, motor nuevo, conversión a 64 bits y contenido adicional quedan para una etapa posterior; no son condiciones del primer hito.

## Forma de avanzar

Cada cambio debe tener un objetivo verificable, instrucciones de prueba y evidencia del resultado. Mantener mejoras de infraestructura separadas de cambios de gameplay. Trabajar en ramas para las siguientes modificaciones y conservar siempre la atribución upstream.

Próximo paso concreto: completar la primera carrera y comprobar depuración en VS Code. Assets, intro y llegada al menú confirmados; los assets no se publican en el repositorio.
