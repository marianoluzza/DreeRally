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
- [ ] Cerrar normalmente y verificar que no queden procesos.
- [ ] Confirmar un breakpoint en VS Code.
- [ ] Registrar versión de datos, argumentos, errores y resultado en una ficha de prueba local.

Assets preparados desde el instalador Windows. Corrección: TRX.BPA era una referencia genérica; se usan TR0.BPA a TR9.BPA, cuyos hashes coinciden con la copia DOS examinada. Las animaciones y DLL x86 ya están presentes. El proceso propio arrancó y responde; Mariano confirmó la intro y el menú. Falta validar jugabilidad. Ver [assets](doc/ASSETS.md).

Salida: menú visible y controles básicos estables.

## 2. Completar una carrera

Prioridad P0; depende del arranque.

- [ ] Seleccionar piloto, coche y circuito.
- [ ] Verificar aceleración, freno, dirección, colisiones y límites de pista.
- [ ] Comprobar vueltas, posiciones, oponentes, armas, daño y finalización.
- [ ] Terminar una carrera y volver a resultados/tienda.
- [ ] Repetir en varios circuitos y coches, incluyendo abandono y destrucción.
- [ ] Registrar fallos reproducibles con circuito, coche, pasos y resultado esperado.
- [ ] Comparar comportamiento con el original antes de modificar física o tiempos.

Salida: tres carreras consecutivas completas sin bloqueo, pérdida de controles ni resultados incoherentes. Corregir primero cierres y corrupción de memoria; luego fidelidad.

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
