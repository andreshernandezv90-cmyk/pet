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

Versión: 1.1 \| Fecha: 4 de noviembre de 2026 (1.0 → 1.1: reestructuración del mundo)

Alcance: visión de producto, reglas de juego, economía, progresión, especificación técnica y plan de desarrollo.

Nota de control: números de producción, probabilidades, tiempos y precios son parámetros iniciales para equilibrar en pruebas; las reglas centrales se consideran aprobadas.

# Registro de cambios 1.1 — Reestructuración del mundo (aprobado)

| Tema | 1.0 | 1.1 (vigente) |
|---|---|---|
| Mundos | Tres mundos: Hogar, Minas de Zuar y Reino de los PETs. | **Dos mundos: Santuario y Mundo PET.** Las Minas de Zuar se integran en el Mundo PET como **cinco minas, una por región**, y conservan su nombre (la de la zona 5 es la **Gran Mina de Zuar**). |
| Mundo PET | Cinco zonas como mapas separados con portales independientes. | **Un único bosque continuo y alargado**, dividido en cinco regiones consecutivas separadas por barreras mágicas translúcidas. |
| Acceso | Varios portales. | **Un portal frente a la casa de cada parcela**, conectado con la entrada del Mundo PET (campamento de bienvenida con NPCs). |
| Viaje rápido | — | **Faros** en cada región: se activan al visitarla por primera vez y permiten viajar a regiones ya desbloqueadas, siempre validado por el servidor. |
| Barreras | Puertas de acceso por zona. | Barrera translúcida por región: se ve la región siguiente, se cruza solo con los requisitos cumplidos. Desbloqueo **individual y permanente** por jugador. |
| Zona 2 | Pico de piedra + santuario nivel 2. | Pico de piedra + santuario nivel 2 **+ extractor de piedra construido**. |
| Zona 3 | Pico de cobre + primer extractor. | Sin cambios (el "primer extractor" queda cubierto por la zona 2 y se mantiene como respaldo). |
| Minería | Nodos compartidos con durabilidad. | **Minerales privados por jugador**: aparición, disponibilidad, agotamiento y regeneración independientes. Las cuevas son compartidas; los nodos no. |
| Parkours | Actividad de cada zona. | Se conservan como **actividades secundarias opcionales** con recompensas y cofres; no bloquean el progreso principal. |
| Fabricación | — | **Ninguna receta puede exigir materiales que el jugador todavía no pueda recolectar**; los requisitos derivados se muestran en el Taller. |

## Ajustes 1.1b (aprobados tras probar la Fase B)

| Tema | Antes (1.1) | Vigente (1.1b) |
|---|---|---|
| Acceso al Mundo PET | Un portal frente a cada casa. | **Un único gran portal central** en la plaza del santuario, punto social de reunión. Las parcelas ya no tienen portal; frente a la casa hay una fogata. |
| Hacha | — | Nueva herramienta con **5 niveles** (rústica, piedra, cobre, hierro, cristal): más daño al talar y más madera. Sus costos respetan la regla de materiales recolectables. |
| Regalos | — | **Regalos aleatorios privados** por zona del Mundo PET, poco frecuentes y con recompensas configurables (`WorldConfig.Gifts`). |
| Legibilidad del santuario | — | Pasto animado corto y solo en bordes boscosos; césped limpio en zonas transitables; caminos claros; áreas de trabajo con suelo, borde y letrero propios. |
| Layout del Mundo PET | Bosque continuo de 5 regiones. | Concretado en `docs/MUNDO_PET_LAYOUT.md` (≈ 2.550 studs): campamento con NPCs al oeste, zonas de oeste a este, minas al norte, bosque y retos al sur. |
| Comerciante | — | Intercambio de materiales por semillas, cebos e ingredientes, **sin moneda**, con tasas configurables (`WorldConfig.Trades`), disponibles según la zona desbloqueada y validados en el servidor. |
| Arena de incursiones | Lugar aparte. | En un claro del campamento del Mundo PET, como punto de reunión (preparada para arenas especiales futuras). |
| Regalos | — | Tope de 1 regalo activo y 4 por hora por jugador, configurables. |

## Ajustes 1.1c (Fase C.1 — Mundo PET compacto)

| Tema | Antes (1.1b) | Vigente (1.1c) |
|---|---|---|
| Largo del Mundo PET | ≈ 2.550 studs. | **1.530 studs**: campamento de 140 y zonas de 250, 260, 270, 280 y 330 studs. |
| Arena de incursiones | Una en el campamento. | **Una por zona**, temática: Arena del Sakura, Coliseo Mecánico, Círculo de las Esporas, Arena del Cristal y Altar del Eclipse. La incursión ocurre en la arena de la zona del jefe con el mismo sistema, las mismas recompensas y el mismo equilibrio. Solo pueden viajar a ella quienes tengan esa zona desbloqueada. |
| Parkours | Retos opcionales genéricos. | **Cinco mecánicas distintas**: troncos y ramas, engranajes y plataformas giratorias, hongos con rebote, cristales y plataformas heladas, y plataformas flotantes con caminos temporales. Todos tienen checkpoints y conservan sus recompensas. |
| PETs salvajes | Claros en la pradera central. | Claros más pequeños junto al camino. El 60% de las apariciones usa uno de los dos claros más cercanos al jugador; el número de PETs activos (7–12) no cambia. |
| Iluminación | Bloom y reflejos marcados. | Más suave: bloom, reflejos del agua y partículas reducidos, sobre todo en el santuario. |

## Minerales por región (probabilidad por ciclo de generación, configurable)

Los porcentajes indican la probabilidad de que un recurso aparezca en un ciclo de generación de nodos de esa mina. No son excluyentes ni deben sumar 100%.

| Zona | Piedra | Cobre | Hierro | Cristal lunar | Zuarita |
|---|---|---|---|---|---|
| 1 · Bosque de Lumi | 100% | 15% | — | — | — |
| 2 · Valle de los Engranajes | 100% | 40% | 15% | — | — |
| 3 · Cavernas Olvidadas | 100% | 65% | 40% | 10% | — |
| 4 · Jardines Elementales | 100% | 85% | 75% | 40% | 10% |
| 5 · Templo del Eclipse (Gran Mina) | 100% | 100% | 100% | 75% | 25% |

Las puertas de herramienta de la sección 02 siguen vigentes: un mineral solo se puede extraer con el pico correspondiente.

# Guía rápida del documento

Este GDD reúne las decisiones del proyecto en un único punto de referencia. Está diseñado para orientar el trabajo de programación en Luau y Rojo, las pruebas de Roblox Studio y las futuras tareas de Astra/Codex.

| **Bloque**           | **Secciones**                                                             |
|----------------------|---------------------------------------------------------------------------|
| Visión y estructura  | 01–04: concepto, mundos, zonas y especies                                 |
| Mecánicas esenciales | 05–11: PETs, captura, minería, producción, huerto, fusiones e incursiones |
| Economía y mejoras   | 12–15: esencias, niveles, inventarios y monetización                      |
| Entrega técnica      | 16–20: multijugador, datos, interfaz, balance y versiones                 |
| Referencia operativa | Anexos: reglas cerradas y parámetros por afinar                           |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p><strong>ELEVATOR PITCH</strong></p>
<p>Empiezas con una casa deteriorada, un pico de madera y un succionador básico. Capturas criaturas con habilidades reales, las asignas a trabajos, exploras minas y desafíos, construyes tu santuario y formas un equipo cada vez más poderoso para alcanzar a Eclipsar.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

## Principios de diseño

- Cada especie debe ser útil como compañera y como trabajadora; ninguna existe solo para completar una lista.

- El Santuario y el Mundo PET dependen uno del otro: el hogar produce y construye; el bosque y sus minas proveen PETs y minerales.

- Los PETs salvajes se generan de forma individual por jugador; las incursiones son cooperativas.

- La progresión es posible sin Robux; las compras mejoran principalmente comodidad y apariencia.

- Las primeras acciones deben entenderse sin leer manuales: aprender jugando y celebrar pequeñas victorias.

- La economía no debe romperse por producción pasiva, mascotas legendarias o multiplicadores acumulados.

- Las mejoras, capturas, intercambios y recompensas se validan del lado del servidor.

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
<th><p><strong>LOOP CENTRAL</strong></p>
<p>Explorar una zona → capturar PETs y recolectar materiales → volver al hogar → mejorar herramientas, almacenes y edificios → asignar trabajadores y potenciar PETs → superar el siguiente desafío → repetir.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

## Primeros 20 minutos ideales

1.  0–3 min: aparece en su casa deteriorada y entiende cómo usar el portal al Reino de los PETs.

2.  3–7 min: completa un parkour sencillo con checkpoints y captura su primer Lumi.

3.  7–12 min: vuelve al hogar, visita las Minas de Zuar y obtiene piedra con el pico de madera.

4.  12–16 min: recoge madera en el bosque y comienza una mejora visible del santuario.

5.  16–20 min: descubre los requisitos para la zona 2 y el valor de encontrar otro Lumi con mejor rareza.

# 02. Los dos mundos (actualizado en 1.1)

| **Mundo** | **Función** | **Sistemas principales** |
|---|---|---|
| 1\. Santuario (Hogar Dimensional) | Base y progresión doméstica | Parcela con bosque propio, casa rústica, madera, almacenes, huerto, alquimia, fusiones, extractores y el portal al Mundo PET. |
| 2\. Mundo PET | Captura, exploración y minería | Bosque continuo de cinco regiones, quince especies, cinco Minas de Zuar, barreras, faros, campamento con NPCs, parkours opcionales e incursiones. |

> En la versión 1.0 las Minas de Zuar eran un mundo aparte. Desde la 1.1 forman parte del Mundo PET: cada región tiene su propia mina, a la que se entra caminando.

## Mundo 1 — Santuario (Hogar Dimensional)

Cada jugador posee una parcela y un santuario. Empieza con una casa en mal estado, herramientas básicas y pocas estaciones. El bosque permite obtener madera y materiales de construcción; el huerto y la alquimia se desbloquean más adelante en la zona 3 del Reino de los PETs.

Construcciones previstas: casa ampliable, almacén de recursos, almacén de PETs, extractores, huertos, invernadero, estación de cebos, laboratorio de alquimia, taller de herramientas, Reactor de Esencias, laboratorio de fusiones, hábitats y decoraciones.

## Minas de Zuar (dentro del Mundo PET desde 1.1)

| **Herramienta** | **Recurso habilitado** | **Utilidad principal**                       |
|-----------------|------------------------|----------------------------------------------|
| Pico de madera  | Piedra                 | Primeras reparaciones y mejoras.             |
| Pico de piedra  | Cobre                  | Máquinas y herramientas iniciales.           |
| Pico de cobre   | Hierro                 | Construcciones reforzadas.                   |
| Pico de hierro  | Cristal lunar          | Dispositivos mágicos y estaciones avanzadas. |
| Pico de cristal | Zuarita                | Tecnología dimensional y mejoras finales.    |

Los nodos minerales tienen durabilidad, tiempo de extracción y recompensas validadas por servidor. Desde 1.1 los nodos son **privados por jugador**: cada jugador ve, agota y regenera sus propios minerales dentro de la cueva compartida. Algunos depósitos especiales pueden revelar encuentros o materiales exclusivos; la captura principal de especies sucede en el Reino de los PETs.

## Mundo 2 — Mundo PET (antes Reino de los PETs)

Las quince especies residen en un único bosque continuo organizado en cinco regiones consecutivas, separadas por barreras translúcidas. Cada zona contiene un área central, desafío propio, materiales especiales y un conjunto de PETs salvajes que reaparecen para cada jugador. Las zonas anteriores permanecen útiles y repetibles.

# 03. Desbloqueo de las regiones del Mundo PET

| **Zona**                    | **Especies**                             | **Actividad**                                                                      | **Puerta de acceso**                                         |
|-----------------------------|------------------------------------------|------------------------------------------------------------------------------------|--------------------------------------------------------------|
| 1 · Bosque de Lumi (antes Praderas Luminosas) | Lumi                                     | Bosque tutorial, Mina de Zuar I y parkour opcional con checkpoints.                | Abierta desde el principio.                                  |
| 2 · Valle de los Engranajes | Rocón, Chispa                            | Bloques móviles y circuitos; desbloqueo del disparo de resonancia.                 | Pico de piedra + santuario nivel 2 + extractor de piedra (1.1). |
| 3 · Cavernas Olvidadas      | Talpa, Nox, Zuri                         | Cuevas oscuras, laberintos, captura avanzada. Desbloquea huerto, alquimia y cebos. | Pico de cobre + primer extractor.                            |
| 4 · Jardines Elementales    | Musguito, Flamín, Florín, Brumí          | Mecánicas elementales, trampas, cultivos y plataformas móviles.                    | Pico de hierro + huerto nivel 2 + succionador mejorado.      |
| 5 · Templo del Eclipse      | Venti, Prisma, Gravix, Astrael, Eclipsar | Gravedad, puzles combinados, cooperación y misión final.                           | Equipo avanzado + santuario desarrollado + misiones previas. |

Desde 1.1 los parkours de cada región son actividades secundarias opcionales con cofres y recompensas; nunca bloquean el camino principal. Los requisitos de cada región están en `src/shared/WorldConfig.luau` y son configurables.

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

La rareza modifica la apariencia, estadísticas y eficiencia de trabajo, no los requisitos de esencia para subir de nivel. Los nuevos PETs deben seguir siendo útiles incluso cuando el jugador ya haya desbloqueado otros mundos.

# 05. Roles: compañeros, trabajadores y colección

Cada PET individual ocupa un solo estado funcional al mismo tiempo. Los estados previstos son: disponible, equipado, trabajador asignado, fusionado o protegido/bloqueado. El jugador nunca puede usar la misma unidad en dos sistemas de manera simultánea.

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

Se mantienen recursos diferenciados: minerales en las Minas de Zuar de cada región del Mundo PET; madera y cultivos en el Santuario; ingredientes únicos y componentes raros en las regiones del Mundo PET. Algunas mejoras requieren al menos dos mundos para que ninguno pierda importancia.

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

6.  Anuncio y reunión: cuenta regresiva corta para desplazarse a la arena.

7.  Barrera: el grupo utiliza el disparo de resonancia para romper escudos.

8.  Prueba de entorno: esquivar ondas, activar pilares y resolver mecánicas del jefe.

9.  Resonancia final: estabilizar al PET mediante contribución cooperativa.

10. Recompensa privada: cada participante elegible recibe esencia y oportunidad individual de captura.

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

Los jugadores comparten los mundos, pero tienen progresión, parcelas, almacenamiento y apariciones normales individuales. Se pueden visitar santuarios, admirar mejoras, ver PETs trabajadores y participar juntos en desafíos cooperativos.

Las incursiones son globales por servidor con recompensas individuales. No habrá robo de PETs de otros usuarios como mecánica central ni PvP obligatorio. Los compañeros visibles de otros jugadores no son capturables.

# 17. Arquitectura técnica para Astra / Codex

Tecnología existente: Roblox Studio, Luau, Rojo y un proyecto base ya funcional. La versión 0.3 trabaja en persistencia de inventario y equipamiento; antes de ampliar el alcance se deben revisar esos cambios y probar cargas y guardados en Studio.

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
<th><p><strong>PERFIL PERSISTENTE</strong></p>
<p>schemaVersion; currencies/resources; storyProgress; unlocks; toolLevels; petInstances[id, speciesId, rarityId, level, status, lockFlag, traits?]; essenceBySpecies; portableCapacities; paidSlotEntitlements; storage; stations[levels, workers, inventories, updatedAt]; crops; discoveredFusions; cooldowns; processedPurchaseReceipts.</p></th>
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

# 20. Plan de implementación y aceptación

| **Versión** | **Objetivo verificable**                                          | **Estado**                               |
|-------------|-------------------------------------------------------------------|------------------------------------------|
| 0.1         | Santuario, portal, bosque prototipo, rescate de Lumi.             | Probado funcional.                       |
| 0.2         | Inventario visual y equipar/guardar Lumi.                         | Probado funcional.                       |
| 0.3         | Persistencia, seguridad de perfiles y arquitectura modular.       | En trabajo con Astra; requiere revisión. |
| 0.4         | Mina, 5 recursos, picos y crafting inicial.                       | Pendiente.                               |
| 0.5         | Hogar mejorable, extractor inicial y asignaciones de trabajo.     | Pendiente.                               |
| 0.6         | Zona 1–2, captura por jugador, succionador y rarezas.             | Pendiente.                               |
| 0.7         | Zona 3, agricultura, cebos y alquimia.                            | Pendiente.                               |
| 0.8         | Reactor de Esencias, niveles, pilas, cofres y capacidad portátil. | Pendiente.                               |
| 0.9         | Fusiones, zonas 4–5, quince especies e incursiones.               | Pendiente.                               |
| 1.0         | Balance, UX móvil, QA multijugador, seguridad y tienda.           | Pendiente.                               |

## Pruebas obligatorias antes de lanzamiento

11. Entrar, capturar, salir y volver: el perfil restaura todos los datos.

12. Intentar capturar un PET que no pertenece al jugador: el servidor rechaza la acción.

13. Saturar inventario y pila: no se pierden ni duplican PETs ni esencias.

14. Convertir ejemplares heterogéneos: el reactor acredita exactamente la suma de sus valores.

15. Subir niveles consecutivos: se descuentan 50 + 200 + 500 + 1,000 + 5,000, no el costo neto entre pasos.

16. Reiniciar a mitad de una compra, fusión o incursión: no aparecen recompensas duplicadas.

17. Todos los caminos esenciales se pueden completar sin gastar Robux.

18. Pruebas con distintos dispositivos, latencias y diez jugadores simultáneos.

19. Activar privacidad, controles de edad y publicación conforme a reglas vigentes de Roblox.

# Anexo A. Reglas de negocio cerradas

20. Hay exactamente dos mundos funcionales: Santuario y Mundo PET. Las Minas de Zuar forman parte del Mundo PET, una por región. *(modificada en 1.1; en 1.0 eran tres mundos)*

21. El Reino tiene cinco zonas con especies distribuidas 1 + 2 + 3 + 4 + 5.

22. Hay quince especies iniciales; solo Lumi, Nox y Eclipsar tienen mítico en la primera temporada.

23. Cada PET individual se usa como compañero o trabajador, nunca ambos a la vez.

24. Los PETs normales aparecen individualmente para cada jugador; las incursiones son de grupo.

25. La zona 3 desbloquea huerto, cebos y alquimia.

26. El reciclaje de PETs es determinista y genera esencias de la misma especie.

27. Esencias por PET consumido: 2, 3, 5, 10, 15 según rareza.

28. Un PET puede mejorar hasta nivel 5 con costos separados 50, 200, 500, 1,000 y 5,000.

29. El costo total por PET desde nivel 0 hasta 5 es 6,750 esencias.

30. Un espacio de tanque agrupa hasta 50 PETs idénticos no evolucionados de especie y rareza.

31. Mochila de recursos por zonas: 5, 10, 15, 20 y 25 espacios gratis.

32. Tanque de PETs por zonas: 3, 6, 9, 12 y 15 espacios gratis.

33. Las ampliaciones de almacenamiento de pago son opcionales y permanentes.

34. Los jefes de incursión son gigantes solo durante el evento; el PET capturado es de tamaño normal.

35. La colección debe poder completarse sin compras gracias al almacenamiento del santuario.

36. *(1.1b)* Hay un único gran portal central en la plaza del santuario que conecta con la entrada del Mundo PET (reemplaza al portal por parcela de la 1.1).

37. *(1.1)* Las barreras entre regiones son individuales y permanentes por jugador; el servidor impide el paso a regiones no desbloqueadas.

38. *(1.1)* Los nodos minerales son privados por jugador (aparición, agotamiento y regeneración independientes).

39. *(1.1)* Los faros de viaje rápido se activan al visitar una región y solo llevan a regiones desbloqueadas.

40. *(1.1)* Ninguna receta exige materiales que el jugador todavía no pueda recolectar.

41. *(1.1b)* El hacha tiene cinco niveles; el pico, el hacha y el succionador se muestran siempre en el HUD.

42. *(1.1b)* Los regalos del Mundo PET son privados por jugador, poco frecuentes y validados por el servidor.

# Anexo B. Guía de entrega para Astra

Antes de comenzar una versión nueva, Astra debe leer este documento y el repositorio real, revisar el estado de la versión anterior y proponer una modificación pequeña y comprobable. No debe reemplazar sistemas funcionales sin necesidad ni intentar implementar todo el GDD en una sola tarea.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p><strong>PRÓXIMA MISIÓN TÉCNICA RECOMENDADA</strong></p>
<p>Terminar y probar correctamente la versión 0.3. Después desarrollar el loop de piedra + madera + pico de piedra + santuario nivel 2 + portal a zona 2. Las demás mecánicas deberán crecer sobre estos módulos y la persistencia existente.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

Cada entrega deberá especificar archivos modificados, decisiones de arquitectura, criterios de prueba, pruebas ejecutadas realmente y riesgos pendientes. Mantener código Luau modular, sincronización Rojo y validación del lado del servidor.

**FIN DEL DOCUMENTO MAESTRO · PORTAL PETS 1.1**
