**PORTAL / PETS**

**RESCATE  
DIMENSIONAL**

**DOCUMENTO MAESTRO DE DISEÑO DEL VIDEOJUEGO**

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p>Explora · Captura · Produce · Construye · Evoluciona</p>
<p>Un juego de aventura, colección y automatización de criaturas para Roblox.</p>
<p>ESTADO DEL DOCUMENTO • DISEÑO CONSOLIDADO 1.1</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

Versión: 1.1 \| Fecha: 6 de noviembre de 2026 \| Estado: diseño consolidado, prototipo funcional hasta v0.6

Alcance: visión de producto, mundos, especies, capturas, economía, combates, cuevas, progresión, arquitectura y hoja de ruta.

Nota de control: se distinguen reglas aprobadas, ejemplos de balance y sistemas futuros aún no implementados. Las pruebas del prototipo no equivalen a lanzamiento.

# Guía rápida del documento

Este GDD consolida las decisiones del proyecto hasta el 6 de noviembre de 2026. Es la referencia de diseño para Astra/Codex, Luau, Rojo y Roblox Studio. La base funcional está validada hasta la v0.6; duelos, guardianes y Shiny quedan especificados para futuras iteraciones.

| **Bloque**           | **Secciones**                                                                                   |
|----------------------|-------------------------------------------------------------------------------------------------|
| Visión y estructura  | 01–04: concepto, mundos, zonas y especies                                                       |
| Mecánicas esenciales | 05–11: PETs, captura, minería, producción, huerto, fusiones e incursiones                       |
| Economía y mejoras   | 12–15: esencias, niveles, inventarios y monetización                                            |
| Entrega técnica      | 16–24: redes sociales, datos, interfaz, balance, ruta técnica, duelos, cuevas y variantes Shiny |
| Referencia operativa | Anexos: reglas cerradas y parámetros por afinar                                                 |
| Combate y expansión  | 21–24: duelos, guardianes de cuevas, Shiny, integración y pruebas nuevas                        |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th>ELEVATOR PITCH<br />
Empiezas con una casita deteriorada, un pico de madera y un succionador. Capturas criaturas únicas que exploran, trabajan y combaten por turnos; derrotas guardianes para abrir cuevas, reúnes esencias para mejorarlas, construyes tu santuario y avanzas hacia Eclipsar.</th>
</tr>
</thead>
<tbody>
</tbody>
</table>

## Principios de diseño

- Cada especie debe ser útil como compañera y como trabajadora; ninguna existe solo para completar una lista.

- Los tres mundos dependen unos de otros: hogar y bosque, minas y reino de PETs.

- Los PETs salvajes se generan de forma individual por jugador; las incursiones son cooperativas.

- La progresión es posible sin Robux; las compras mejoran principalmente comodidad y apariencia.

- Las primeras acciones deben entenderse sin leer manuales: aprender jugando y celebrar pequeñas victorias.

- La economía no debe romperse por producción pasiva, mascotas legendarias o multiplicadores acumulados.

- Las mejoras, capturas, intercambios y recompensas se validan del lado del servidor.

- Los combates son por turnos, opcionales en PvP, sin pérdida de PETs y con estadísticas competitivas equilibradas por especie.

# 01. Identidad y fantasía del jugador

Nombre: Portal Pets: Rescate Dimensional. Plataforma: Roblox. Género: aventura, colección de criaturas, simulación de producción, minería, agricultura, fabricación, exploración y cooperación.

Estilo visual: 70% adorable, 20% fantasía y 10% misterio. Las criaturas deben tener siluetas reconocibles, animaciones expresivas y variantes de rareza visualmente diferenciables, sin depender de efectos excesivos que reduzcan el rendimiento en celulares.

Audiencia de diseño: niños a partir de aproximadamente 9 años, adolescentes y adultos. El juego deberá ofrecer rutas principales accesibles y desafíos opcionales para quien busque dominar los sistemas.

## Fantasía de progresión

La experiencia comienza con una casita deteriorada y un santuario pequeño. A lo largo del juego, el jugador transforma la propiedad en un recinto vivo con huertos, PETs trabajando, laboratorios, extractores y decoraciones. Las mejoras son visibles en el mundo, no solo números de interfaz.

## Ciclo principal

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th>LOOP CENTRAL<br />
Explorar y superar desafíos → capturar PETs y combatir guardianes → extraer materiales → volver al hogar → fabricar, construir y asignar trabajadores → mejorar PETs con esencias → desbloquear la próxima zona → repetir.</th>
</tr>
</thead>
<tbody>
</tbody>
</table>

## Primeros 20 minutos ideales

> 1\. 0–3 min: aparece en su casa deteriorada y entiende cómo usar el portal al Reino de los PETs.
>
> 2\. 3–7 min: completa un parkour sencillo con checkpoints y captura su primer Lumi.
>
> 3\. 7–12 min: vuelve al hogar, visita las Minas de Zuar y obtiene piedra con el pico de madera.
>
> 4\. 12–16 min: recoge madera en el bosque y comienza una mejora visible del santuario.
>
> 5\. 16–20 min: descubre los requisitos para la zona 2 y el valor de encontrar otro Lumi con mejor rareza.

# 02. Los tres mundos

| **Mundo**             | **Función**                  | **Sistemas principales**                                                                         |
|-----------------------|------------------------------|--------------------------------------------------------------------------------------------------|
| 1\. Hogar Dimensional | Base y progresión doméstica  | Casa, bosque, madera, santuario, almacenes, huerto, alquimia, fusiones, extractores.             |
| 2\. Minas de Zuar     | Recursos minerales y mejoras | Picos, piedra, cobre, hierro, cristal lunar, Zuarita, minería y crafting.                        |
| 3\. Reino de los PETs | Captura y aventuras          | Cinco zonas, quince especies, parkour, puzles, succionador, materiales especiales e incursiones. |

## Mundo 1 — Hogar Dimensional

Cada jugador posee una parcela y un santuario. Empieza con una casa en mal estado, herramientas básicas y pocas estaciones. El bosque permite obtener madera y materiales de construcción; el huerto y la alquimia se desbloquean más adelante en la zona 3 del Reino de los PETs.

Construcciones previstas: casa ampliable, almacén de recursos, almacén de PETs, extractores, huertos, invernadero, estación de cebos, laboratorio de alquimia, taller de herramientas, Reactor de Esencias, laboratorio de fusiones, hábitats y decoraciones.

## Mundo 2 — Minas de Zuar

| **Herramienta** | **Recurso habilitado** | **Utilidad principal**                       |
|-----------------|------------------------|----------------------------------------------|
| Pico de madera  | Piedra                 | Primeras reparaciones y mejoras.             |
| Pico de piedra  | Cobre                  | Máquinas y herramientas iniciales.           |
| Pico de cobre   | Hierro                 | Construcciones reforzadas.                   |
| Pico de hierro  | Cristal lunar          | Dispositivos mágicos y estaciones avanzadas. |
| Pico de cristal | Zuarita                | Tecnología dimensional y mejoras finales.    |

Los nodos minerales tienen durabilidad, tiempo de extracción y recompensas validadas por servidor. Algunos depósitos especiales pueden revelar encuentros o materiales exclusivos; la captura principal de especies sucede en el Reino de los PETs.

## Mundo 3 — Reino de los PETs

Las quince especies residen en un único mundo organizado en cinco zonas. Cada zona contiene un área central, desafío propio, materiales especiales y un conjunto de PETs salvajes que reaparecen para cada jugador. Las zonas anteriores permanecen útiles y repetibles.

# 03. Desbloqueo del Reino de los PETs

| **Zona**                    | **Especies**                             | **Actividad**                                                                      | **Puerta de acceso**                                         |
|-----------------------------|------------------------------------------|------------------------------------------------------------------------------------|--------------------------------------------------------------|
| 1 · Praderas Luminosas      | Lumi                                     | Parkour tutorial con checkpoints y capturas básicas.                               | Abierta desde el principio.                                  |
| 2 · Valle de los Engranajes | Rocón, Chispa                            | Bloques móviles y circuitos; desbloqueo del disparo de resonancia.                 | Pico de piedra + santuario nivel 2.                          |
| 3 · Cavernas Olvidadas      | Talpa, Nox, Zuri                         | Cuevas oscuras, laberintos, captura avanzada. Desbloquea huerto, alquimia y cebos. | Pico de cobre + primer extractor.                            |
| 4 · Jardines Elementales    | Musguito, Flamín, Florín, Brumí          | Mecánicas elementales, trampas, cultivos y plataformas móviles.                    | Pico de hierro + huerto nivel 2 + succionador mejorado.      |
| 5 · Templo del Eclipse      | Venti, Prisma, Gravix, Astrael, Eclipsar | Gravedad, puzles combinados, cooperación y misión final.                           | Equipo avanzado + santuario desarrollado + misiones previas. |

## Regla de dificultad

Las rutas principales deben ser superables por jugadores jóvenes: instrucciones visuales, checkpoints, intentos ilimitados, objetivos cortos y ausencia de penalizaciones duras. Los secretos, rutas rápidas y logros de precisión ofrecerán desafío adicional para jugadores experimentados.

# 04. Las quince especies iniciales

Todas las especies tienen: identificador estable, nombre, rarezas disponibles, zona de origen, habilidad como compañero, trabajo compatible, material asociado, preferencias de cebo y parámetros de captura.

| **\# · Especie** | **Compañero**                                | **Trabajo / producción**                 |
|------------------|----------------------------------------------|------------------------------------------|
| 01 Lumi          | Acelera minería y aporta luz.                | Extractor de piedra.                     |
| 02 Rocón         | Mayor fuerza en minerales duros.             | Extractor de piedra.                     |
| 03 Chispa        | Detecta cobre y mecanismos eléctricos.       | Extractor de cobre; apoyo en alquimia.   |
| 04 Talpa         | Mejora el rendimiento al minar.              | Extractor de hierro.                     |
| 05 Zuri          | Detecta vetas raras de Zuarita.              | Produce polvo de Zuarita.                |
| 06 Musguito      | Activa raíces y facilita desafíos naturales. | Riega cultivos y acelera crecimiento.    |
| 07 Flamín        | Derrite obstáculos y supera calor ambiental. | Ayuda en herrería y estaciones de calor. |
| 08 Nox           | Visión nocturna y secretos en cuevas.        | Produce cristal lunar.                   |
| 09 Florín        | Mejora el rendimiento de cebos vegetales.    | Cosecha cultivos y guarda alimentos.     |
| 10 Brumí         | Reduce la dificultad de capturas salvajes.   | Transporta materiales al almacén.        |
| 11 Venti         | Permite planear distancias cortas.           | Produce cuarzo aéreo.                    |
| 12 Prisma        | Revela símbolos y luz oculta.                | Produce fragmentos prismáticos.          |
| 13 Gravix        | Manipula mecanismos gravitacionales.         | Produce fragmentos gravitacionales.      |
| 14 Astrael       | Localiza anomalías y rescates secretos.      | Produce energía astral.                  |
| 15 Eclipsar      | Resonancia temporal de varios beneficios.    | Produce fragmentos del eclipse.          |

## Rarezas y colección

Rarezas oficiales: común, raro, épico (también llamado “muy raro”), legendario y mítico. Solo Lumi, Nox y Eclipsar tendrán variante mítica en el lanzamiento; las otras doce especies tendrán cuatro rarezas.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p><strong>TAMAÑO DE COLECCIÓN</strong></p>
<p>15 especies × 4 rarezas base + 3 variantes míticas exclusivas = 63 variantes de especie/rareza. Los individuos pueden diferenciarse además por nivel y, en una fase posterior, por talento.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

La rareza modifica apariencia y bonificaciones de exploración, minería y trabajo. En combate competitivo, a igual especie y nivel máximo, todas las rarezas tienen las mismas cuatro estadísticas; Shiny es puramente visual. La rareza nunca modifica el costo de esencias.

# 05. Roles: compañeros, trabajadores y colección

Cada PET individual ocupa un único estado persistente: disponible, equipado, trabajador o fusionado/reservado. Participar en un duelo añade un bloqueo temporal de combate del servidor, que impide usarlo como trabajador o consumirlo mientras dura la batalla. Protegido/bloqueado es una marca de seguridad y no una profesión.

## Equipo de exploración

| **Progreso**      | **Espacios de PETs equipados**    |
|-------------------|-----------------------------------|
| Inicio            | 1 espacio principal.              |
| Herrería nivel 2  | 2 espacios: principal + apoyo.    |
| Santuario nivel 3 | 3 espacios: principal + 2 apoyos. |

La habilidad del compañero principal aplica al 100%. En apoyos, las bonificaciones numéricas usan inicialmente el 50%; los poderes de navegación se mantienen si el diseño del acertijo lo requiere. Se establecerán límites de bonificación por categoría para impedir explosiones de estadísticas.

## Trabajo y colecciones

Cuando se asigna a una estación, el PET activa su profesión de trabajo. Los duplicados permiten automatizar más puestos. Completar colecciones específicas ofrece bonificaciones permanentes pequeñas de cuenta, que se desbloquean una sola vez por colección; las copias repetidas no acumulan porcentajes ilimitados.

# 06. Apariciones, captura y succionador

## Apariciones individuales dentro de mundo compartido

- Cada jugador tiene su propio conjunto de criaturas salvajes en la zona que visita: objetivo inicial de 7 a 12 PETs por ciclo.

- Renovación aproximada de cada 60 segundos; cifra configurable según pruebas de rendimiento y dificultad.

- Las especies y rarezas se determinan individualmente; una captura de otro jugador no elimina tu PET.

- El servidor decide quién es propietario del encuentro y valida capturas; la visualización puede generarse de forma local para ahorrar recursos.

- Los PETs equipados o trabajando sí pueden ser visibles para otros jugadores, aunque no puedan capturarlos.

## Dos cálculos distintos

A\) Aparición/rareza: decide qué especie y variante encuentra el jugador. B) Éxito de captura: depende del succionador, resistencia, cebos, estado del encuentro y habilidades. Una poción de suerte modifica la rareza de aparición; un cebo especial mejora la atracción o la captura, no altera automáticamente la rareza.

## Succionador de Resonancia

| **Nivel de herramienta** | **Función**                                |
|--------------------------|--------------------------------------------|
| Básico                   | Aprendizaje y captura de PETs iniciales.   |
| Reforzado                | Mayor fuerza de succión.                   |
| Magnético                | Mejora alcance y estabilidad.              |
| Dimensional              | Mejor rendimiento en especies resistentes. |
| Maestro                  | Mayor capacidad y eficiencia de captura.   |

Desde la zona 2 se desbloquea un modo alternativo de disparo de resonancia usado en incursiones. Durante una incursión de la zona 1, el juego puede prestar un modo de disparo básico para que participantes nuevos puedan colaborar.

## Trampas y alimentos favoritos

Los cebos, trampas y cultivos permiten preparar expediciones. Mejorar la máquina no garantiza atrapar un PET legendario; reduce la dificultad. Si se falla una captura, la criatura puede escapar, sin pérdida de mascotas que ya pertenecen al jugador.

# 07. Minería, recursos y fabricación

La minería manual es la fuente temprana de materiales y habilita progresión mediante puertas de herramienta. Los nodos tienen durabilidad, resistencia, temporizadores y botines por tipo. Las herramientas mejoran daño de minería, velocidad y acceso a nuevos materiales.

Se mantienen recursos diferenciados por mundo: minerales en Minas de Zuar; madera y cultivos en el Hogar; ingredientes únicos y componentes raros en el Reino de los PETs. Algunas mejoras requieren al menos dos mundos para que ninguno pierda importancia.

## Fabricación y destino de recursos

- Casa y santuario: madera, piedra y componentes estructurales.

- Picos y extractores: materiales minerales y piezas fabricadas.

- Succionador, cebos y trampas: minerales, cultivos e ingredientes de zona.

- Alquimia: mezclas de cultivos, cristales y materiales especiales.

- Fusiones y estaciones avanzadas: energía dimensional y materiales raros.

# 08. Extractores, huerto y trabajos automáticos

## Extractores de recursos

Cada extractor tiene tipo, nivel, número de puestos, capacidad de depósito, energía/eficiencia y lista de trabajadores asignados. La producción depende de especie, rareza, nivel del PET, talento si se habilita, nivel de la estación y topes de equilibrio.

| **Nivel de extractor** | **Puestos propuestos** | **Capacidad de ejemplo** |
|------------------------|------------------------|--------------------------|
| 1                      | 2                      | 1,000                    |
| 2                      | 3                      | 3,000                    |
| 3                      | 5                      | 10,000                   |
| 4                      | 7                      | 30,000                   |
| 5                      | 10                     | 100,000                  |

Ejemplo de diseño: un Lumi raro puede producir 1 piedra/segundo y un legendario puede alcanzar una producción mucho mayor, pero se ajustarán las tasas y requerimientos de maquinaria para que una sola captura no salte toda la economía. No se fija como definitiva una tasa de 50 piedra/segundo hasta probar los costos.

## Huerto y automatización

Se desbloquea tras superar la zona 3. El jugador siembra y recoge manualmente al principio; después asigna PETs para riego, cosecha y transporte. Musguito mejora el crecimiento, Florín cosecha, Brumí transporta, Chispa acelera algunos procesos alquímicos. Las tareas deben representarse con animaciones en el santuario.

## Producción desconectado

- Horizonte inicial: hasta dos horas de producción no reclamada.

- Eficiencia inicial: 50% de la producción activa.

- Nunca supera la capacidad del depósito de cada estación.

- Los cultivos avanzan mientras el jugador está fuera; la recolección requiere trabajadores compatibles.

- El servidor calcula el tiempo transcurrido al volver a entrar, sin simular un servidor activo en segundo plano.

# 09. Huerto, cebos y alquimia

La zona 3 desbloquea las tres instalaciones. El bosque provee madera desde el inicio, pero los cultivos avanzados, cebos y pociones necesitan la nueva estación y sus materiales.

| **Sistema** | **Qué produce**                   | **Para qué sirve**                                |
|-------------|-----------------------------------|---------------------------------------------------|
| Huerto      | Bayas, raíces, flores y semillas. | Alimentación, cebos y recetas.                    |
| Cebos       | Alimentos preparados por especie. | Atraer PETs y facilitar capturas.                 |
| Alquimia    | Pociones temporales.              | Suerte, recursos, succión, minería y crecimiento. |

| **Poción**         | **Efecto inicial ilustrativo**         | **Duración ilustrativa** |
|--------------------|----------------------------------------|--------------------------|
| Fortuna            | ×2 modificador de suerte de aparición. | 15 min                   |
| Minería abundante  | +30% recursos extraídos.               | 20 min                   |
| Succión veloz      | +25% velocidad de captura.             | 15 min                   |
| Impulso de Zuar    | +20% velocidad de minería.             | 20 min                   |
| Instinto salvaje   | Revela PETs cercanos.                  | 10 min                   |
| Crecimiento mágico | ×1.5 velocidad de cultivos.            | 30 min                   |

Los modificadores de suerte no garantizan rareza. Por ejemplo, una probabilidad base mítica de 0.05% puede pasar a 0.10% bajo un efecto ×2 si el sistema de distribución así lo define. Se publicarán probabilidades oficiales cuando las tablas estén cerradas.

# 10. Fusiones temporales: Resonancia Dimensional

Dos PETs compatibles se combinan temporalmente en una forma única que conserva y mezcla atributos de ambos. Sus ejemplares originales no se consumen y quedan reservados hasta que finalice la fusión.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p><strong>EJEMPLO</strong></p>
<p>Lumi legendario + Talpa raro = Lumital. Bonos provisionales combinados: ×1.5 velocidad de minería y +12.5% recursos. La fórmula real deberá respetar límites por atributo.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

| **Parámetro**         | **Regla inicial**                                  |
|-----------------------|----------------------------------------------------|
| Duración activa       | 20 minutos.                                        |
| Recarga normal        | 30 minutos.                                        |
| Simultáneas gratis    | 1 fusión.                                          |
| Simultáneas VIP       | 2 fusiones.                                        |
| Recarga VIP           | 20% más rápida: 24 min para base de 30 min.        |
| Pérdida de PETs       | Ninguna: regresan al inventario.                   |
| Colección de fusiones | Registro permanente de combinaciones descubiertas. |

El VIP debe ser una comodidad, no requisito de desbloqueo. Se evitarán demoras artificiales que hagan desagradable el juego gratuito. Si el beneficio competitivo resulta demasiado marcado, se ajustarán los tiempos durante las pruebas.

# 11. Incursiones Dimensionales cooperativas

Aproximadamente una vez por hora por servidor se activa un evento en una zona elegible, elegida de forma aleatoria. Se anuncia con antelación y utiliza una arena central. Aparece un jefe gigante y brillante de una especie de esa zona; la recompensa capturable es un PET de tamaño normal, con su rareza correspondiente.

## Fases

> 1\. Anuncio y reunión: cuenta regresiva corta para desplazarse a la arena.
>
> 2\. Barrera: el grupo utiliza el disparo de resonancia para romper escudos.
>
> 3\. Prueba de entorno: esquivar ondas, activar pilares y resolver mecánicas del jefe.
>
> 4\. Resonancia final: estabilizar al PET mediante contribución cooperativa.
>
> 5\. Recompensa privada: cada participante elegible recibe esencia y oportunidad individual de captura.

## Contribución, equidad y rareza

La puntuación debe considerar daño, objetivos, apoyo y dificultad relativa, no solo equipamiento bruto. Más jugadores hacen el evento más fácil de completar en términos cooperativos, aunque la resistencia se adapte al grupo. Quien participa en forma significativa siempre gana algo.

| **Nivel de contribución** | **Ejemplo esencia de incursión avanzada** | **Ejemplo prob. Lumi mítico\*** |
|---------------------------|-------------------------------------------|---------------------------------|
| Bronce                    | 50                                        | 0.20%                           |
| Plata                     | 150                                       | 0.40%                           |
| Oro                       | 400                                       | 0.70%                           |
| Diamante                  | 1,000                                     | 1.00%                           |

\*Ejemplos provisionales. La variante mítica de Lumi en encuentros normales se plantea en 0.05%; en la incursión especial, Diamante puede alcanzar 1% en el sorteo de rareza, sujeto a una captura exitosa. No mezclar el cálculo de rareza con el éxito de captura. La esencia se entrega según la especie de la incursión.

Las recompensas de 1,000 esencias corresponden a un objetivo de diseño para contenido avanzado; en zonas iniciales se escalan para mantener significativo el costo de mejorar PETs.

# 12. Reactor de Esencias — sistema definitivo de duplicados

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p><strong>CAMBIO DE DISEÑO APROBADO</strong></p>
<p>Se elimina el antiguo gacha de materiales. El Reactor de Esencias hace conversiones deterministas de PETs repetidos a esencias específicas de su misma especie. No hay premios aleatorios en esta máquina.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

| **Rareza consumida** | **Esencias por cada PET** |
|----------------------|---------------------------|
| Común                | 2                         |
| Raro                 | 3                         |
| Épico / muy raro     | 5                         |
| Legendario           | 10                        |
| Mítico               | 15                        |

Ejemplo A: 5 Chispa comunes → 10 esencias de Chispa. Ejemplo B: 5 Lumi comunes + 1 Lumi raro → (5×2) + (1×3) = 13 esencias de Lumi. No se pueden usar esencias de Chispa para mejorar un Lumi.

## Seguridad de la conversión

- El jugador elige cantidades y visualiza la recompensa exacta antes de confirmar.

- Se excluyen por defecto ejemplares equipados, trabajadores, fusionados, evolucionados o protegidos.

- El servidor vuelve a calcular la cantidad y verifica propiedad, rareza e identificadores.

- El descuento de PETs y acreditación de esencias forman una única operación lógica persistente e idempotente.

- Los errores, desconexiones y reintentos no pueden duplicar ni perder recompensas.

# 13. Cinco niveles de mejora por PET

Cada ejemplar individual parte del nivel 0 y puede alcanzar el nivel 5. El precio en esencias es idéntico para cualquier rareza; solo cambia la estadística base y la potencia máxima según la rareza y especie.

| **Evolución** | **Costo de esa evolución** | **Gastado total hasta ese nivel** |
|---------------|----------------------------|-----------------------------------|
| 0 → 1         | 50                         | 50                                |
| 1 → 2         | 200                        | 250                               |
| 2 → 3         | 500                        | 750                               |
| 3 → 4         | 1,000                      | 1,750                             |
| 4 → 5         | 5,000                      | 6,750                             |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p><strong>REGLA DE COSTO POR SALTO</strong></p>
<p>Cada paso consume su costo íntegro del saldo de esencias. Haber pagado 50 para llegar a nivel 1 NO reduce el siguiente paso de 200 a 150. El costo acumulado para subir un mismo PET del nivel 0 al 5 es exactamente 6,750 esencias de su especie.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

## Escalado ilustrativo de Lumi

| **Nivel** | **Lumi común: multiplicador de minería** | **Lumi mítico: multiplicador de minería** |
|-----------|------------------------------------------|-------------------------------------------|
| 0         | ×1.10                                    | ×2.00                                     |
| 1         | ×1.20                                    | ×2.40                                     |
| 2         | ×1.35                                    | ×2.80                                     |
| 3         | ×1.55                                    | ×3.20                                     |
| 4         | ×1.75                                    | ×3.60                                     |
| 5         | ×2.00                                    | ×4.00                                     |

Las cifras intermedias son de diseño, no definitivas. Un PET mejorado se considera un individuo único y debe persistir con su nivel. El máximo de minería efectiva total entre herramienta, apoyo, pociones y fusiones tendrá límites para prevenir acumulación descontrolada.

# 14. Mochilas, tanque y pilas

## Capacidad portátil gratuita por zona

| **Zona desbloqueada** | **Mochila de recursos** | **Tanque de PETs** |
|-----------------------|-------------------------|--------------------|
| 1                     | 5 espacios              | 3 espacios         |
| 2                     | 10 espacios             | 6 espacios         |
| 3                     | 15 espacios             | 9 espacios         |
| 4                     | 20 espacios             | 12 espacios        |
| 5                     | 25 espacios             | 15 espacios        |

Los espacios representan categorías o pilas, no individuos. Por ejemplo, 30 Lumi comunes sin mejoras pueden compartir una pila; un Lumi raro ocupa otra pila. La pila normal tendrá un máximo inicial de 50 PETs idénticos.

## Reglas del apilamiento

- Para criaturas ordinarias sin mejoras, se agrupa por especie + rareza; 50 ejemplares iguales consumen 1 espacio.

- Los ejemplares evolucionados, con talentos únicos, bloqueados o asignados a un trabajo deben conservar identidad individual y un tratamiento de espacio explícito.

- Cuando una pila llega a 50, el excedente ocupa otra pila, se envía a almacenamiento si hay lugar o se bloquea el ingreso de forma segura.

- La colección de 63 variantes debe ser alcanzable gratis mediante un almacén de santuario con capacidad ampliable por materiales del juego.

- El tanque es portátil; cofres y almacenes del hogar permiten guardar materiales y PETs sin ocupar el tanque de expedición.

## Mejoras de pago — precios de prueba

| **Ampliación permanente**      | **Precio sugerido** |
|--------------------------------|---------------------|
| +1 espacio de mochila o tanque | 9 Robux             |
| +5 espacios                    | 39 Robux            |
| +10 espacios                   | 69 Robux            |
| +20 espacios                   | 119 Robux           |

Se podrán vender ambos tipos de espacios por separado. Se definirá un tope razonable de ampliación, controles para compras repetibles y persistencia por recibo. La posible ampliación de pila de 50 a 75/100 ejemplares se reserva para una actualización posterior.

# 15. Monetización y progresión justa

La monetización prioriza la estética y la comodidad. El juego y su colección completa serán obtenibles sin Robux. Los precios son hipótesis sujetas a pruebas y a la configuración efectiva en Roblox.

| **Producto**          | **Precio tentativo** | **Tipo**                          |
|-----------------------|----------------------|-----------------------------------|
| Sombrero para PET     | 29 Robux             | Cosmético                         |
| Estela mágica         | 49 Robux             | Cosmético                         |
| Alas                  | 79 Robux             | Cosmético                         |
| Paquete de bienvenida | 99 Robux             | Cosmético + recursos garantizados |
| Portal decorativo     | 129 Robux            | Cosmético                         |
| PET visual adicional  | 149 Robux            | Cosmético                         |
| VIP                   | 249 Robux            | Pase permanente                   |
| Ampliación +1 espacio | 9 Robux              | Compra permanente repetible       |

VIP propuesto: etiqueta y decoración exclusiva, dos fusiones simultáneas y 20% menos recarga. Todos los mundos, PETs, herramientas necesarias, extractor, huerto y mejora al nivel 5 deben estar disponibles gratuitamente.

## Límites éticos y de cumplimiento

- No vender PETs aleatorios ni conversiones de esencia aleatorias por Robux durante el lanzamiento.

- No vender tiradas de rareza ni aumentar probabilidades mediante gastos en Robux.

- Las pociones de suerte y cebos se obtienen mediante juego y crafting.

- Mostrar valores, probabilidades pertinentes y efectos reales con claridad; revisar las políticas actuales de Roblox antes de publicar.

- Evitar mensajes de urgencia manipulativa dirigidos a menores y no bloquear el avance básico por comprar almacenamiento.

# 16. Experiencia social y cooperación

Los jugadores comparten el mundo, pero conservan parcelas, perfiles, almacenamiento y apariciones individuales. Pueden visitar santuarios, admirar PETs trabajadores, cooperar en incursiones y, cuando se habilite, desafiarse voluntariamente en duelos por turnos.

Las incursiones son eventos cooperativos globales por servidor con recompensas individuales. El PvP por turnos es voluntario; no existe robo de PETs ni pérdida de criaturas por derrotas. Los compañeros de otros jugadores no pueden capturarse.

# 17. Arquitectura técnica para Astra / Codex

Tecnología: Roblox Studio, Luau, Rojo y DataStoreService. La v0.6 ha sido probada por el usuario en flujo individual y en una sesión de dos clientes: capturas separadas, rarezas independientes, compañeros visibles y persistencia básica. Falta QA formal de latencia, móvil, seguridad y cargas simultáneas.

## Módulos sugeridos

| **Módulo de dominio**                | **Responsabilidades principales**                                               |
|--------------------------------------|---------------------------------------------------------------------------------|
| ProfileService / DataManager interno | Carga/guardado DataStore, versión de esquema, migraciones, bloqueos por sesión. |
| PetCatalog                           | Definiciones inmutables de especies, rarezas, habilidades y trabajos.           |
| PetInventoryService                  | Unidades, pilas, tanque, cofre, asignaciones y protección de individuos.        |
| CaptureService                       | Spawn por jugador, intentos, cebos, probabilidades y validaciones.              |
| WorldProgression                     | Zonas, requisitos, portales, misiones y desbloqueos.                            |
| MiningAndCrafting                    | Nodos minerales, picos, recetas, mejoras y recursos.                            |
| WorkerProduction                     | Asignación, extractores, huerto, offline y capacidades.                         |
| AlchemyAndBait                       | Cultivos, recetas, pociones, ingredientes y límites de efectos.                 |
| EssenceAndLeveling                   | Conversión determinista, monederos por especie y costos de nivel.               |
| FusionService                        | Resonancia, duración, cooldown y elegibilidad.                                  |
| RaidService                          | Programación, combate cooperativo, contribución y recompensa individual.        |
| CommerceService                      | Pases, recibos idempotentes y capacidad permanente comprada.                    |

## Modelo conceptual mínimo de datos

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th>PERFIL PERSISTENTE<br />
schemaVersion; resources; progress; tools; petInstances[id, speciesId, rarityId, isShiny, level, status, lockFlag, traits?]; essenceBySpecies; storage; extractors; crops; fusionStates; caveGuardianProgress; caveBossFlags; dungeonRewardsClaimed; battleStatistics; processedOperationIds; receipts.</th>
</tr>
</thead>
<tbody>
</tbody>
</table>

Guardar identificadores estables para cada PET singular y estación. Las pilas son una vista agregada del inventario, no una excusa para perder la identidad de ejemplares evolucionados. Las esencias son enteros no negativos, con tipo de especie validado.

## Criterios de seguridad

- No confiar en cantidades de daño, rareza, recompensas, moneda, PETs, tiempos o niveles enviados por el cliente.

- Limitar frecuencia de remotos y comprobar proximidad, elegibilidad de zona, inventario y estado en cada operación.

- Aplicar guardados con reintentos, autosave y BindToClose, sin sobrescribir perfiles válidos si la carga falla.

- Diseñar transacciones idempotentes para compras, mejora de nivel, reciclaje y recompensas de incursión.

- Controlar particiones de sesión, reconexiones y versiones del esquema de datos.

- Evitar replicar cientos de NPCs por jugador: usar estado confiable de servidor y representación local cuando sea posible.

# 18. Interfaz y experiencia móvil

El HUD debe comunicar con claridad tres cosas: dónde estás, qué puedes hacer ahora y qué te falta para avanzar. Usar iconos claros, botones grandes, textos breves y accesibilidad al color.

- Pantalla principal: zona, objetivo, mochila de recursos, tanque de PETs, acceso al hogar y a mapas.

- PETdex / inventario: especie, rareza, nivel, estado, habilidad, trabajo, apilar, proteger y asignar.

- Reactor: selección de duplicados + previsualización exacta de esencias + confirmación.

- Mejoras: nivel actual, potencia anterior/nueva, esencias disponibles, costo de ese paso.

- Estaciones: trabajadores, producción/s, almacenamiento, tiempo offline y botón de recoger.

- Captura: resistencia del PET, batería/energía del succionador, cebo activo y feedback visual de éxito o fallo.

- Incursiones: aviso, participantes, fases, contribución, recompensa garantizada y tirada individual.

# 19. Balance: cifras propuestas vs reglas aprobadas

Los números exactos deben probarse con sesiones de juego y métricas. Este documento diferencia las reglas que conforman la identidad del juego y los valores ajustables.

| **Reglas a preservar**                                      | **Parámetros por calibrar**                           |
|-------------------------------------------------------------|-------------------------------------------------------|
| Tres mundos con funciones distintas.                        | Duración de misiones y tiempos de traslado.           |
| Quince especies / cinco zonas / 63 variantes.               | Dificultad, recompensas y estadísticas concretas.     |
| Spawn privado por jugador.                                  | 7–12 PETs y 60 segundos por renovación.               |
| Dos roles por PET.                                          | Velocidades de producción y límites de habilidad.     |
| Esencias por especie y cinco niveles.                       | Curvas estadísticas por rareza y especie.             |
| Costos de nivel 50/200/500/1000/5000 = 6750.                | Recompensas de incursión y frecuencia de esencia.     |
| Pilas iniciales de 50 y almacenamiento gratis en santuario. | Capacidades de cofres y máximos de tienda.            |
| Incursión cooperativa con recompensa personal.              | Escalado de escudos, rareza y rangos de contribución. |
| No comercializar azar con Robux al lanzamiento.             | Precios cosméticos y conversión comercial.            |

## Riesgos de diseño que deben medirse

- Si aparecen demasiados PETs por minuto, la colección y sus esencias pueden perder valor.

- Si 1,000 esencias Diamante se obtienen fácilmente en la zona 1, un PET alcanza nivel alto demasiado rápido.

- Si la producción pasiva supera la minería activa, los mundos de exploración pierden utilidad.

- Si la mochila de tres pilas iniciales impide jugar varios minutos seguidos, hay que ofrecer un almacén accesible y un envío sencillo al hogar.

- Si la rareza determina todo el poder, los comunes pierden encanto; habilidades y evoluciones deben mantener relevancia.

- Si los efectos de fusión, apoyo, pociones y niveles se multiplican sin límites, la economía se rompe.

- Si la contribución depende únicamente de DPS, niños y jugadores nuevos quedan excluidos de las recompensas buenas.

- Si se mezcla rareza con poder competitivo, el PvP favorece el azar; PvP normalizado y esencias obtenibles jugando deben evitarlo.

# 20. Plan de implementación y aceptación

| **Versión** | **Objetivo verificable**                                      | **Estado**                                                      |
|-------------|---------------------------------------------------------------|-----------------------------------------------------------------|
| 0.1         | Santuario inicial, portal, Lumi y primer rescate.             | Validado en Studio (flujo básico).                              |
| 0.2         | Inventario, equipar y guardar a Lumi.                         | Validado en Studio.                                             |
| 0.3         | Persistencia DataStore, seguridad y arquitectura modular.     | Probado en Studio: Lumi guardada entre sesiones.                |
| 0.4         | Minas de Zuar, minerales, picos y fabricación.                | 8/8 pruebas manuales reportadas, con persistencia.              |
| 0.5         | Extractor, trabajadores, almacenamiento y producción offline. | 10/10 pruebas manuales reportadas.                              |
| 0.6         | Cinco rarezas, captura privada de Lumi, tanque y pilas.       | 10/10 pruebas individuales + prueba de dos clientes reportadas. |
| 0.7         | Huerto, cebos y alquimia: zona 3 cuando sea accesible.        | Planificado; sujeto a priorización de progresión.               |
| 0.8         | Reactor de Esencias, niveles 0–5, inventario y cofres.        | Planificado.                                                    |
| 0.9         | Fusiones, zonas restantes, jefes e incursiones.               | Planificado; alcance sujeto a dividirse.                        |
| 1.0         | UX móvil, rendimiento, economía, seguridad y publicación.     | Planificado: no hay fecha de lanzamiento.                       |

## Pruebas obligatorias antes de lanzamiento

> 1\. Entrar, capturar, salir y volver: el perfil restaura todos los datos.
>
> 2\. Intentar capturar un PET que no pertenece al jugador: el servidor rechaza la acción.
>
> 3\. Saturar inventario y pila: no se pierden ni duplican PETs ni esencias.
>
> 4\. Convertir ejemplares heterogéneos: el reactor acredita exactamente la suma de sus valores.
>
> 5\. Subir niveles consecutivos: se descuentan 50 + 200 + 500 + 1,000 + 5,000, no el costo neto entre pasos.
>
> 6\. Reiniciar a mitad de una compra, fusión o incursión: no aparecen recompensas duplicadas.
>
> 7\. Todos los caminos esenciales se pueden completar sin gastar Robux.
>
> 8\. Pruebas con distintos dispositivos, latencias y diez jugadores simultáneos.
>
> 9\. Activar privacidad, controles de edad y publicación conforme a reglas vigentes de Roblox.

# 21. Duelos de Resonancia: combate por turnos

Sistema de combate adicional, no sustitutivo de exploración, captura o producción. Cada especie conserva su rol no bélico y recibe cuatro estadísticas de combate y cuatro movimientos propios. Los duelos son voluntarios; nunca se arriesga la propiedad del PET.

## 21.1 Formatos y reglas de turno

- Cada entrenador elige hasta 3 PETs; 1 activo y hasta 2 en reserva. No puede escoger ejemplares trabajando, fusionados, consumidos o bloqueados por otra operación.

- Al inicio del turno ambos eligen una acción privada: uno de cuatro movimientos, cambiar el PET activo, defender o rendirse. Tiempo objetivo: 20 segundos; si expira, el servidor aplica defensa automática.

- El servidor resuelve acciones tras recibir ambas: primero prioridad del movimiento; en empate, iniciativa alterna por turno con desempate determinista. No se agrega por defecto una quinta estadística de velocidad.

- Cambiar PET ocupa la acción del turno. Las habilidades 2 y 3 tienen recarga por turnos; la cuarta usa energía ganada durante el combate. Se prohíben bucles de curación o bloqueo infinito.

- El combate termina cuando un equipo pierde sus 3 PETs, se rinde o se alcanza el límite seguro de turnos. Las derrotas nunca eliminan ni degradan mascotas.

## 21.2 Estadísticas y rareza

| Estadística | Uso en combate                                                       |
|-------------|----------------------------------------------------------------------|
| Ataque      | Daño de movimientos físicos o de contacto.                           |
| Vida (PV)   | Puntos de resistencia antes de quedar fuera de combate.              |
| Defensa     | Reduce el daño recibido y mejora ciertas posturas protectoras.       |
| Poder       | Intensidad de movimientos elementales, escudos y efectos especiales. |

REGLA DE IGUALDAD: Lumi común nivel 5 y Lumi legendario nivel 5 comparten los mismos valores de Ataque, Vida, Defensa y Poder en PvP. El mismo principio aplica a cualquier especie. La rareza sí conserva diferencias visuales y ventajas fuera de PvP (minería, producción, exploración); Shiny no concede estadísticas extra. En clasificatorias, los equipos se normalizan al nivel competitivo estándar (propuesta: nivel 5) para priorizar decisiones tácticas. En duelos libres se puede ofrecer modo con niveles reales si ambos aceptan.

Los polvos o esencias de cada especie son el único material de nivel: 50 / 200 / 500 / 1,000 / 5,000 para progresar de nivel 0 a 5 (total 6,750). Un PET común y uno legendario pagan lo mismo. No crear una segunda moneda de combate que duplique este progreso.

## 21.3 Siete tipos elementales

| Tipo       | Especies                   | Identidad táctica                          |
|------------|----------------------------|--------------------------------------------|
| Luz        | Lumi, Prisma, Astrael      | Escudos, apoyo y daño luminoso.            |
| Tierra     | Rocón, Talpa, Zuri, Gravix | Resistencia, alteraciones del campo.       |
| Eléctrico  | Chispa                     | Presión ofensiva y estados temporales.     |
| Naturaleza | Musguito, Florín, Brumí    | Curación, raíces, control.                 |
| Fuego      | Flamín                     | Daño progresivo y ofensiva directa.        |
| Sombra     | Nox, Eclipsar              | Debilitaciones y daño especial.            |
| Aire       | Venti                      | Evasión estratégica y movilidad narrativa. |

Balance inicial de afinidades: ventaja elemental = +25% de daño; no hay inmunidades absolutas. La matriz completa de ventajas debe aprobarse tras pruebas de combate; las habilidades defensivas y las estrategias de cambio pueden contrarrestar desventajas.

## 21.4 Cuatro movimientos por especie

Estructura obligatoria: 1) ataque básico sin recarga; 2) técnica elemental de daño o control; 3) protección, curación o efecto táctico; 4) movimiento distintivo de especie que consume energía. La siguiente tabla propone nombres y funciones, NO daños definitivos.

| PET / tipo            | Mov. 1 y 2                                    | Mov. 3 y 4                                             |
|-----------------------|-----------------------------------------------|--------------------------------------------------------|
| Lumi · Luz            | Destello (básico) · Rayo lumínico (elemental) | Escudo de luz (protección) · Nova celestial (especial) |
| Rocón · Tierra        | Golpe rocoso · Avalancha corta                | Caparazón pétreo · Muralla de Zuar                     |
| Chispa · Eléctrico    | Chisporroteo · Descarga en arco               | Carga estática · Tormenta de cobre                     |
| Talpa · Tierra        | Zarpazo minero · Excavación                   | Refugio subterráneo · Derrumbe preciso                 |
| Zuri · Tierra         | Cristalazo · Espinas de Zuarita               | Armadura mineral · Prisma de Zuar                      |
| Musguito · Naturaleza | Golpe de hoja · Raíces enredadoras            | Rocío curativo · Jardín protector                      |
| Flamín · Fuego        | Chispa ardiente · Llamarada                   | Piel de brasas · Círculo ígneo                         |
| Nox · Sombra          | Eco oscuro · Pulso nocturno                   | Velo de penumbra · Eclipse sonoro                      |
| Florín · Naturaleza   | Pétalo veloz · Semillas silvestres            | Néctar reparador · Primavera viva                      |
| Brumí · Naturaleza    | Golpe de bruma · Niebla espesa                | Manto protector · Bosque velado                        |
| Venti · Aire          | Ala cortante · Ráfaga                         | Corriente evasiva · Torbellino ascendente              |
| Prisma · Luz          | Destello facetado · Haz refractado            | Prisma protector · Lluvia iridiscente                  |
| Gravix · Tierra       | Impacto orbital · Tirón gravitatorio          | Campo pesado · Singularidad suave                      |
| Astrael · Luz         | Astilla estelar · Haz astral                  | Constelación guardiana · Juicio celeste                |
| Eclipsar · Sombra     | Pulso umbral · Sombra creciente               | Manto del eclipse · Resonancia final                   |

## 21.5 Modos de juego y premios

- Tutorial PvE: Arena del Santuario tras zona 2. Primera prueba: Lumi contra Rocón, sin PvP todavía.

- Guardianes PvE: encuentros por turnos en cuevas, con materiales y esencias específicas como recompensa.

- Duelos amistosos PvP: invitación y aceptación expresa; 1 contra 1 por equipos de tres. Sin robo de PETs, pérdida de inventario ni daño permanente.

- Liga Dimensional (futura): clasificatorias con estadísticas normalizadas; recompensas cosméticas, títulos, trofeos y decoración, no aumentos de fuerza competitiva.

- Las Incursiones Dimensionales siguen usando su modo cooperativo de disparo/resonancia; no se convierten en combates por turnos para no confundir sistemas.

# 22. Cuevas protegidas y Guardianes Dimensionales

Las cuevas de recursos avanzados son pequeñas expediciones repetibles de minería + combate PvE. Su acceso inicial puede estar condicionado por herramientas y progreso de santuario. La cantera de tutorial debe seguir permitiendo extraer la piedra necesaria para fabricar el primer pico: los guardianes no bloquearán la primera experiencia de minería.

## 22.1 Secuencia de una cueva

> 1\. Entrada: el jugador acepta el desafío y se guarda un punto de retorno seguro.
>
> 2\. Guardianes: derrota 2 o 3 enemigos dimensionales por turnos; cada victoria entrega materiales garantizados.
>
> 3\. Jefe: al vencer a los guardianes aparece un guardián mayor con mecánica elemental específica.
>
> 4\. Minería liberada: al derrotar al jefe se desbloquean los depósitos internos para ese jugador o grupo elegible; no debe bloquearse la cueva de otros.
>
> 5\. Progresión: la primera victoria contra el jefe marca una bandera persistente que forma parte de los requisitos de la siguiente zona, junto a pico/santuario/otras misiones.
>
> 6\. Repetición: el contenido puede reiniciarse para obtener más materiales y esencias; nunca concede infinitas recompensas por reconexión, cancelación o cambio de servidor.

## 22.2 Progresión de guardianes

| Tramo                | Tema de guardianes                                  | Desbloqueo previsto                                                          |
|----------------------|-----------------------------------------------------|------------------------------------------------------------------------------|
| Minas iniciales      | Pequeños centinelas de piedra; jefe Rocón ancestral | Primeras cuevas profundas y refuerzo de herramientas.                        |
| Ruta de cobre/hierro | Engranajes eléctricos y constructos mineros         | Acceso a vetas y componentes para zona 2–3.                                  |
| Cristal lunar        | Sombras, espejos y guardianes nocturnos             | Ingredientes para huerto/alquimia y equipos avanzados.                       |
| Zuarita              | Constructos dimensionales y jefe de Zuarita         | Materiales para progresión final; zona 5 cuando se cumplan otros requisitos. |

La tabla describe arquetipos, no una promesa de cuatro mapas completamente desarrollados en la primera versión. El requisito de derrotar jefes se añadirá a nuevas puertas sin romper los desbloqueos que ya haya obtenido un perfil de prueba migrado.

## 22.3 Accesibilidad y cooperación

- Niños y adultos deberán entender qué objetivo falta: marcadores claros, pistas visuales, recompensas por intento y checkpoints antes del jefe.

- No quitar materiales ya adquiridos cuando el jugador pierda; mantener al menos un circuito gratuito de reintento.

- Cualquier jugador podrá completar cuevas importantes en solitario; la ayuda de amigos acorta tiempo o facilita tácticas, sin monopolizar el botín.

- En cooperativo, cada participante elegible obtiene su propia recompensa validada por servidor. Las banderas de progreso y recursos son por jugador.

- Durante una cueva liberada no reaparecen enemigos para interrumpir constantemente la minería. Un reinicio de expedición es explícito o programado claramente.

# 23. Variantes Shiny (brillantes)

Shiny es un atributo de apariencia independiente de la rareza y del nivel. Por ejemplo: Lumi común Shiny, Lumi legendario Shiny y Lumi mítico Shiny. No es una sexta rareza y no reemplaza los 63 pares especie/rareza del lanzamiento.

| Aspecto               | Regla de diseño                                                                                              |
|-----------------------|--------------------------------------------------------------------------------------------------------------|
| Obtención             | Posibilidad independiente y baja durante generación de PETs; el valor exacto aún NO está fijado.             |
| Apariencia            | Paleta alternativa y efectos ligeros, identificables sin depender de un resplandor muy costoso para móviles. |
| Combate               | Mismas estadísticas, movimientos y éxito de combate que su equivalente no Shiny al mismo nivel.              |
| Trabajo / exploración | Mismos multiplicadores y rendimiento que su equivalente no Shiny.                                            |
| Colección             | Registro de hallazgos Shiny por especie y rareza, con emblemas cosméticos opcionales.                        |
| Datos                 | Cada individuo almacena isShiny: boolean; nunca decidir Shiny del lado del cliente.                          |
| Reactor               | Antes de reciclar, advertir y proteger Shiny por defecto; recompensa de esencia no arbitrariamente superior. |

No implementar una tienda de rerolls Shiny con Robux. Publicar las probabilidades pertinentes de los sistemas aleatorios conforme a las reglas vigentes de Roblox, especialmente si algún día intervienen compras con moneda pagada.

# 24. Integración, seguridad y estado de implementación

## 24.1 Precedencia de reglas

- El diseño de combate por turnos sustituye ideas previas de combate en tiempo real. Los combates se resuelven por acciones y turnos; la exploración y captura normales siguen siendo en tiempo real.

- La rareza mejora habilidades no competitivas y apariencias, pero no crea ventaja en PvP a igual especie y nivel. A nivel 5, las estadísticas de combate de una especie son las mismas para común, raro, épico, legendario y mítico.

- Los polvos y esencias de especie son el mismo recurso para subir niveles. No existe un progreso de nivel que se arrastre como descuento: cada salto consume su costo íntegro.

- Shiny es una dimensión visual independiente, y el jefe gigante de las incursiones no se convierte en PET gigante permanente al capturarse.

- Las cuevas de guardianes son una capa nueva sobre las minas y el progreso: la cantera inicial de piedra permanece libre para evitar bloquear el tutorial.

## 24.2 Dominio técnico para Astra

| Sistema futuro              | Responsabilidades del servidor                                                                                      |
|-----------------------------|---------------------------------------------------------------------------------------------------------------------|
| BattleService / BattleRules | Colas PvE/PvP, selección por turnos, orden, daño, efectos y premios; validación de equipo, límites y desconexiones. |
| GuardianCaveService         | Oleadas, jefe, flags personales de desbloqueo, recursos sellados y recompensa idempotente.                          |
| PetStats / MoveCatalog      | Cuatro atributos, 4 movimientos por especie, escalado por nivel y normalización de PvP por especie.                 |
| ShinyTraits                 | isShiny, probabilidad al generar, seguridad de reciclaje y variaciones visuales ligeras.                            |
| EssenceAndLeveling          | Conversión definitiva de duplicados, costos 6,750, mejoras y trazabilidad de operaciones.                           |

- Nunca confiar en daño, ganador, rareza, Shiny, recompensa, polvos/esencias ni resultado de batalla enviados por cliente. El servidor calcula y guarda.

- Una caída durante combate no puede duplicar materiales, esencias ni otorgar múltiples premios. Registrar operación y recompensa antes de anunciar la victoria final.

- Verificar sesiones concurrentes, compatibilidad del esquema DataStore (v0.6 reporta esquema 4) y migración segura antes de activar nuevos campos persistentes.

- Los PETs deben estar bloqueados para operaciones incompatibles mientras están en un duelo, sin alterar arbitrariamente los estados que mantienen extractores y acompañantes.

## 24.3 Plan progresivo después de v0.6

| Tramo       | Entregable mínimo comprobable                                                                                       |
|-------------|---------------------------------------------------------------------------------------------------------------------|
| Diseño / QA | Conservar v0.6 y probar capturas privadas, persistencia, dos clientes, carga y errores antes de nuevas migraciones. |
| Economía    | Reactor determinista de esencia + niveles 0–5 por especie + Shiny como campo independiente (visual después).        |
| Combate PvE | Prototipo por turnos Lumi vs Rocón, con cuatro estadísticas, cuatro acciones y pruebas de desconexión.              |
| Cuevas      | Primera cueva con guardianes, jefe, puerta de minerales y bandera persistente para progreso.                        |
| Expansión   | Huerto/alquimia/cebos zona 3; otras especies y zonas; tareas de PETs, fusiones, raids y PvP voluntario.             |
| Lanzamiento | QA móvil/multijugador, economía, cumplimiento, monetización y pruebas de retención. Sin fecha pública fijada.       |

Los nombres de tramos NO reemplazan automáticamente las etiquetas internas 0.7, 0.8 y siguientes del repositorio: Astra debe proponer una secuencia viable y actualizar el registro de versiones cuando se apruebe cada entrega.

## 24.4 Pruebas de aceptación nuevas

> 1\. Dos Lumi misma especie/nivel 5 de rarezas distintas registran Ataque, Vida, Defensa y Poder exactamente iguales en PvP competitivo.
>
> 2\. Un Shiny y un no Shiny iguales en especie, nivel y equipamiento tienen estadísticas idénticas; cambia solo la presentación.
>
> 3\. Una victoria en cueva desbloquea minería solo para los participantes elegibles; otros jugadores no heredan el progreso.
>
> 4\. Repetir jefe, reconectar y perder conexión en recompensa no genera materiales ni esencias duplicadas.
>
> 5\. Un PET trabajando o fusionado no puede ser convocado a combate; al salir, se libera cualquier bloqueo transitorio sin pérdida de estado.
>
> 6\. Se puede ganar la primera pelea usando un Lumi común sin comprar ni conseguir un legendario.
>
> 7\. Los controles de batalla funcionan en PC, móvil, tablet y bajo latencia; las acciones del cliente fuera de turno se rechazan.

# Anexo A. Reglas de negocio cerradas

> 1\. Hay exactamente tres mundos funcionales: hogar, minas y Reino de los PETs.
>
> 2\. El Reino tiene cinco zonas con especies distribuidas 1 + 2 + 3 + 4 + 5.
>
> 3\. Hay quince especies iniciales; solo Lumi, Nox y Eclipsar tienen mítico en la primera temporada.
>
> 4\. Cada PET individual se usa como compañero o trabajador, nunca ambos a la vez.
>
> 5\. Los PETs normales aparecen individualmente para cada jugador; las incursiones son de grupo.
>
> 6\. La zona 3 desbloquea huerto, cebos y alquimia.
>
> 7\. El reciclaje de PETs es determinista y genera esencias de la misma especie.
>
> 8\. Esencias por PET consumido: 2, 3, 5, 10, 15 según rareza.
>
> 9\. Un PET puede mejorar hasta nivel 5 con costos separados 50, 200, 500, 1,000 y 5,000.
>
> 10\. El costo total por PET desde nivel 0 hasta 5 es 6,750 esencias.
>
> 11\. Un espacio de tanque agrupa hasta 50 PETs idénticos no evolucionados de especie y rareza.
>
> 12\. Mochila de recursos por zonas: 5, 10, 15, 20 y 25 espacios gratis.
>
> 13\. Tanque de PETs por zonas: 3, 6, 9, 12 y 15 espacios gratis.
>
> 14\. Las ampliaciones de almacenamiento de pago son opcionales y permanentes.
>
> 15\. Los jefes de incursión son gigantes solo durante el evento; el PET capturado es de tamaño normal.
>
> 16\. La colección debe poder completarse sin compras gracias al almacenamiento del santuario.
>
> 17\. Duelos por turnos voluntarios: equipos de hasta tres PETs, cuatro movimientos y cuatro estadísticas por especie.
>
> 18\. En PvP a especie y nivel 5 iguales, todas las rarezas tienen las mismas estadísticas; clasificatorias normalizadas.
>
> 19\. Shiny es apariencia alternativa independiente de rareza y nivel, sin ventajas estadísticas.
>
> 20\. Las cuevas avanzadas se desbloquean con guardianes y jefe; la cantera inicial del tutorial permanece disponible.
>
> 21\. Las victorias contra jefes generan progreso y recompensas personales, protegidos contra repetición indebida.

# Anexo B. Guía de entrega para Astra

Antes de comenzar una versión nueva, Astra debe leer este GDD y el repositorio real, identificar el esquema de perfil vigente (v0.6: esquema 4, según informe de implementación), comparar con los tests existentes y proponer un cambio pequeño y comprobable. No debe reescribir mecánicas que ya funcionan.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th>PRÓXIMA MISIÓN TÉCNICA RECOMENDADA<br />
Conservar v0.6 como base estable. Antes de añadir nuevos sistemas, validar su guardado y seguridad. Implementar los próximos módulos por etapas: esencias y niveles; progreso de cueva/guardianes; combate por turnos PvE con Lumi y Rocón; posteriormente PvP voluntario, Shiny y contenido visual.</th>
</tr>
</thead>
<tbody>
</tbody>
</table>

Cada entrega deberá especificar archivos modificados, decisiones de arquitectura, criterios de prueba, pruebas ejecutadas realmente y riesgos pendientes. Mantener código Luau modular, sincronización Rojo y validación del lado del servidor.

FIN DEL DOCUMENTO MAESTRO · PORTAL PETS GDD 1.1
