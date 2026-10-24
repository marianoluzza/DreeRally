# Partidas guardadas (DR.SG0 a DR.SG9)

Formato de la versión completa para Windows, verificado contra `dr.exe` y contra partidas reales del
fork. La versión shareware (`DR.SWn`) es distinta: mide 2195 bytes y usa otro cifrado (ver
`tools/sharewareSavegameDecrypt.py`).

Herramienta: [tools/savegame.py](../tools/savegame.py) muestra, descifra, cifra y edita campos.

```text
python tools/savegame.py show runtime/DR.SG2 --all
python tools/savegame.py set runtime/DR.SG2 name="Light Gaby" money=5000
```

## Archivo

`DR.SGn` corresponde a la ranura `n` del menú. `DR.SG7` es además la ranura del guardado rápido
("Quicksave Slot"). Cada archivo mide siempre 2179 bytes (0x883) y contiene una cabecera y la tabla
`drivers[]` copiada tal cual de memoria. No guarda nada más: ni el mercado negro, ni las carreras que
se ofrecen, ni las rachas de los sponsors.

| Bytes | Tamaño | Contenido |
| --- | --- | --- |
| 0 | 1 | Clave del cifrado (`rand() % 255`). Se guarda sin cifrar |
| 1 | 1 | `driverId`: posición del jugador en `drivers[]` |
| 2 | 1 | `useWeapons` (0 o 1) |
| 3 | 1 | Dificultad: 0 fácil, 1 media, 2 difícil |
| 4–18 | 15 | Nombre de la partida, relleno con ceros. Con 15 letras no lleva cero final |
| 19–2178 | 2160 | `drivers[20]`, 20 registros de 108 bytes (struct `Driver` de `drivers.h`) |

Escriben el archivo `saveGame` (`ui/loadSaveGameScreen.c`, 0x42F6E0) y el guardado rápido
(`dr.c`). Lo leen `decryptEntireSavegame` (`savegame.c`, 0x41C910) y la pantalla de carga.

## Cifrado

El byte 0 queda como está. Para cada byte `i` entre 1 y 2178:

- Cifrar: `b = (b - clave + 17·i) mod 256` y después rotar `b` a la derecha `i mod 6` bits.
- Descifrar: rotar `b` a la izquierda `i mod 6` bits y después `b = (b - 17·i + clave) mod 256`.

Al editar se puede conservar la clave, porque el juego acepta cualquier valor.

## Registro de piloto (108 bytes)

Todos los campos después del nombre son `int32` con signo, little endian. El desplazamiento se cuenta
desde el inicio del registro, que en el archivo está en `19 + 108·n`. La dirección es la de
`drivers[0]` en `dr.exe` (la tabla empieza en 0x460840).

| Desp. | Dirección | Campo | Valores |
| --- | --- | --- | --- |
| 0 | 0x460840 | `name` | 12 bytes terminados en cero. La licencia admite 10 letras y guarda el nombre en minúsculas con la inicial en mayúscula. Los rivales van en mayúsculas |
| 12 | 0x46084C | `damage` | Daño del coche, de 0 a 100 |
| 16 | 0x460850 | `engine` | Nivel de motor, de 0 a `cars[carType].engineUpgrades` |
| 20 | 0x460854 | `tire` | Nivel de neumáticos, de 0 a `cars[carType].tireUpgrades` |
| 24 | 0x460858 | `armour` | Nivel de blindaje, de 0 a `cars[carType].armourUpgrades` |
| 28 | 0x46085C | `carType` | 0 Vagabond, 1 Dervish, 2 Sentinel, 3 Shrieker, 4 Wraith, 5 Deliverator |
| 32 | 0x460860 | `unk_460860` | Sin accesos en `dr.exe`; siempre 0 |
| 36 | 0x460864 | `unk_460864` | Sin accesos en `dr.exe`; siempre 0 |
| 40 | 0x460868 | `unk_460868` | Sin accesos en `dr.exe`; siempre 0 |
| 44 | 0x46086C | `colour` | Jugador: índice en `COPPER.PAL` (también es la posición del deslizador de la licencia). Rival: índice en `CARCOL.PAL`, igual al de su nombre |
| 48 | 0x460870 | `money` | Dinero. Una partida nueva empieza con 495 |
| 52 | 0x460874 | `loanType` | Jugador: −1 sin préstamo, 0 a 4 según el préstamo tomado (`LoanType`). Rivales: 0, sin uso |
| 56 | 0x460878 | `loanRaces` | Jugador: carreras desde el préstamo, de 1 a 4; −1 sin préstamo. Rivales: 0 |
| 60 | 0x46087C | `carMoneyCost` | Valor del coche actual |
| 64 | 0x460880 | `face` | Retrato, de 0 a 19 (`face01` a `face20`). Para los rivales es también el índice de su nombre |
| 68 | 0x460884 | `points` | Puntos del campeonato |
| 72 | 0x460888 | `rank` | Puesto en el ranking, de 1 a 20. Los empatados comparten puesto |
| 76 | 0x46088C | `racesWon` | Carreras ganadas |
| 80 | 0x460890 | `totalRaces` | Carreras corridas |
| 84 | 0x460894 | `lastRaceIncome` | Ingresos de la última carrera |
| 88 | 0x460898 | `totalIncome` | Ingresos acumulados |
| 92 | 0x46089C | `mines` | Minas compradas para la próxima carrera (8 por compra) |
| 96 | 0x4608A0 | `spikes` | Púas compradas, 0 o 1 |
| 100 | 0x4608A4 | `rocket` | Cohete comprado, 0 o 1 |
| 104 | 0x4608A8 | `sabotage` | Sabotaje comprado, 0 o 1. Se consume en la carrera siguiente |

## Para editar

- Después de cada carrera, `drivers[]` se reordena por puntos y se recalcula `rank`. Por eso el
  jugador no está en un lugar fijo y hay que buscarlo con `driverId`. Al cambiar puntos conviene
  dejar `rank` coherente (el juego lo recalcula al terminar la próxima carrera).
- Los rivales no compran mejoras. Su motor, sus neumáticos y su blindaje se sortean al empezar la
  partida, entre 0 y el máximo del coche menos uno.
- La cara y el color del jugador no deberían repetir los de un rival. Las partidas creadas antes del
  24/10/2026 pueden tener ese defecto: `initDrivers` no se llamaba después de la licencia, así que un
  rival podía tener la misma cara que el jugador y faltaba otro de los 20 pilotos.
- Las armas (`mines`, `spikes`, `rocket`, `sabotage`) de los rivales se ignoran: en cada carrera se
  sortean de nuevo.
