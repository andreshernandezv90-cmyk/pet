# Mundo PET — layout vigente (Fase C.1, compacto)

Bosque continuo dividido en zonas consecutivas con barreras translúcidas, PETs salvajes en claros junto al camino, una boca de mina por zona hacia el norte (lleva a su galería de las Minas de Zuar), una arena de incursiones temática por zona y un reto opcional de parkour por zona en el bosque sur.

Plano a escala, generado con `tools/preview/layout_map.py` a partir de las mismas fórmulas de `PetWorld.luau`: [`previews/mundo-pet-layout.png`](previews/mundo-pet-layout.png).

> **Fase C.1:** el mundo pasó de ≈ 2.550 a **1.530 studs** de largo. Se conservan el campamento y sus NPCs, las barreras, los faros, los regalos y sus topes, el Templo del Eclipse, las entradas de mina selladas y todos los datos guardados.

## 1. Estructura general

```
 NORTE  ── montaña con las bocas de mina (cada una lleva a su galería de las Minas de Zuar) ──
        ┌────────┬───────────┬───────────┬───────────┬───────────┬────────────┐
        │CAMPAM. │  ZONA 1   ║  ZONA 2   ║  ZONA 3   ║  ZONA 4   ║  ZONA 5    │
 OESTE  │ portal │  claros ● ║  claros ● ║  claros ● ║  claros ● ║  claros ●  │  ESTE
        │ NPCs   │ ═camino principal serpenteante══════════════════════════════│
        │        │  (arena)  ║  (arena)  ║  (arena)  ║  (arena)  ║  (altar)   │
        └────────┴───────────╨───────────╨───────────╨───────────╨────────────┘
 SUR    ── bosque: un reto opcional por zona (checkpoints + cofre) ──
                    ║ = barrera translúcida con puerta mágica (individual por jugador)
```

| Tramo | Largo (studs) | Contenido principal |
|---|---|---|
| Campamento de bienvenida | 140 | Portal de regreso al santuario, Comerciante, Guía, Tienda premium, fogata, faroles, faro del campamento y arco de salida. |
| Zona 1 · Bosque de Lumi | 250 | Abedules rosados y flores. **Arena del Sakura**. Reto: troncos y ramas. Mina de Zuar I (sellada). |
| Zona 2 · Valle de los Engranajes | 260 | Ruinas doradas y engranajes. **Coliseo Mecánico**. Reto: engranajes y plataformas giratorias. Mina II (sellada). |
| Zona 3 · Cavernas Olvidadas | 270 | Hongos luminosos y niebla. **Círculo de las Esporas**. Reto: hongos con rebote. Mina III (sellada). |
| Zona 4 · Jardines Elementales | 280 | Estanques, cristales de hielo y braseros. **Arena del Cristal**. Reto: cristales y plataformas heladas. Mina IV (sellada). |
| Zona 5 · Templo del Eclipse | 330 | Crepúsculo, ruinas flotantes y el templo final. **Altar del Eclipse**. Reto: plataformas flotantes y caminos temporales. Gran Mina (sellada). |

- **Total:** 1.530 studs de largo (antes ≈ 2.550), unos 2 minutos caminando de punta a punta.
- **Franja transitable:** unos 320 studs de ancho de norte a sur. El camino principal serpentea con una amplitud de ±30 studs.
- **Bordes:** montaña al norte y acantilado con bosque al sur, de terreno real, con muros invisibles como respaldo.

## 1b. Arenas de incursión (una por zona)

Cada zona tiene su arena junto al camino, al 30% del largo de la zona y unos 15 studs al sur del borde del camino, con un sendero corto, un arco con su nombre y decoración propia:

| Zona | Arena | Radio | Tema |
|---|---|---|---|
| 1 | Arena del Sakura | 30 | Abedules en flor, asientos de piedra, pétalos. |
| 2 | Coliseo Mecánico | 30 | Columnas doradas y engranajes. |
| 3 | Círculo de las Esporas | 31 | Hongos gigantes luminosos y esporas. |
| 4 | Arena del Cristal | 32 | Cristales de hielo y suelo helado. |
| 5 | Altar del Eclipse | 36 | Piedras rúnicas y círculo de neón. |

- **Un solo sistema de incursiones parametrizado:** `Raid` toma centro, radio, pilares y punto de llegada de `World.Arenas[zona]`. Las recompensas, la vida del jefe, las oleadas y el equilibrio no cambian.
- **Participación:** se cuenta por posición (distancia horizontal al centro ≤ radio + 14). La zona de área del jugador no cambia, así que entrar a la arena no regenera sus PETs.
- **Viaje:** el botón "Ir a la incursión activa" del Mapa solo lleva a la arena si hay una incursión abierta y el jugador tiene esa zona desbloqueada; el servidor lo valida y las barreras siguen aplicándose.

## 1c. Retos opcionales (parkour)

Uno por zona, en el bosque sur (entre el 58% y el 92% del largo de la zona). Todos tienen checkpoints intermedios, checkpoint final y cofre con las recompensas de antes. Ninguno bloquea el progreso.

| Zona | Mecánica | Detalle |
|---|---|---|
| 1 | Troncos y ramas | Tocones y puentes de tronco caminables. Tutorial suave. |
| 2 | Engranajes | Discos de engranaje con dientes; la mitad gira (tween) y algunos están de canto. |
| 3 | Hongos con rebote | Tres repisas (10, 19 y 28 studs) a las que se sube con hongos saltarines (`JumpPad`, potencia 80). |
| 4 | Cristal y hielo | Pilares de cristal y losas heladas de baja fricción, con un muro de hielo que obliga a rodear. |
| 5 | Caminos temporales | Plataformas flotantes (algunas oscilan) y caminos que aparecen y desaparecen cada 2,5 s; atajo con plataformas ocultas. |

`tools/sim/petworld.lua` comprueba que cada paso sea alcanzable (subida ≤ 4,5 studs y hueco ≤ 9 studs; con rebote, la altura del salto), que el reto quede dentro de su zona y que no pise la arena.

## 1d. PETs salvajes

- Cada zona tiene entre 5 y 6 claros de 22 studs de radio (24 en la zona 5), alternados a ±30 studs del camino y alejados de la arena.
- Siguen apareciendo 7–12 PETs por jugador. No hay más entidades activas, pero el 60% de las veces la aparición se elige en uno de los dos claros más cercanos al jugador, así que al explorar se encuentran PETs con más frecuencia.
- Las probabilidades de especie y rareza no cambian.

## 2. Las piezas del dibujo

| En el dibujo | En el juego |
|---|---|
| Cuadros a la izquierda | **Campamento** con 3 puestos de madera con toldo, letrero e iluminación. **Norte: Comerciante.** **Centro: Guía**, que explica captura, rarezas, minas, recursos, pico, hacha, barreras y extractores. **Sur: Tienda premium**, que muestra los productos de `Config` con su precio real de MarketplaceService; la compra se confirma solo en el servidor. |
| Puntos de colores | **PETs salvajes privados** en claros junto al camino. Usan puntos de aparición validados (sin árboles, rocas ni pendientes) y conservan las probabilidades de rareza actuales. |
| Franjas negras | **Barreras translúcidas**: una cortina mágica de borde a borde con pilares de runas cada ~20 studs. En el camino principal hay una **puerta-arco** con letrero que muestra los requisitos que te faltan. |
| Círculos naranjas | **Bocas de mina** en la montaña norte, que llevan a las galerías del mundo Minas de Zuar. Una boca de cueva con vigas de madera y faroles da a un túnel y a una o varias cámaras. Los minerales son **privados por jugador** y siguen la tabla de probabilidades acordada. La Gran Mina tiene varias cámaras y una caverna central con cristales. |

## 3. Barreras (cómo funcionan)

- **Se ve, pero no se cruza.** Es un material de campo de fuerza translúcido, con el color de la zona siguiente y partículas suaves.
- **Por jugador:**
  - Para todos es sólida.
  - Solo tu cliente la vuelve atravesable cuando tienes la zona desbloqueada (`zones.unlocked`, guardado permanente).
  - El servidor es la autoridad: si apareces del otro lado sin haber desbloqueado la zona, por un error de colisión, un salto o un rodeo, te devuelve a la puerta.
- Al acercarte, la puerta muestra **✅/❌ por requisito**. Al cumplirlos, se abre con un efecto solo para ti.

## 4. Minas (Fase D: mundo propio)

Por decisión oficial (GDD 1.1), las Minas de Zuar son **un mundo diferenciado**. En el Reino, la boca de mina de cada zona (al norte del camino) lleva a su galería; desde la galería se vuelve a esa boca. El diseño completo está en `docs/ARQUITECTURA_TRES_MUNDOS.md`.

| Galería | Radio de la cámara | Vetas por jugador y ciclo | Minerales posibles | Se abre con |
|---|---|---|---|---|
| I · Galería del Musgo | 30 | 14 | Piedra, cobre | Zona 1 (abierta) |
| II · Túneles de Cobre | 36 | 16 | + hierro | Zona 2 |
| III · Grieta de Cristal | 42 | 18 | + cristal lunar | Zona 3 |
| IV · Caverna Elemental | 48 | 20 | + Zuarita | Zona 4 |
| V · Gran Mina | 66 | 28 | Todos | Zona 5 |

Cada ciclo (120 s), el servidor tira el dado de cada mineral por separado para cada jugador y reparte las vetas entre los minerales presentes. Cada jugador ve solo sus vetas: lo que tú agotas no afecta a nadie más. La **Cantera de Zuar** del hub siempre está abierta.

## 5. Regalos aleatorios

- Aparecen en el **bosque a los lados del camino** y en los claros de cada zona.
- Son **privados**, de baja frecuencia (uno cada ~5 minutos en promedio) y se configuran por zona en `WorldConfig.Gifts`.
- Tope por jugador: 1 regalo activo y 4 por hora (configurable). Los puntos de aparición se recalcularon para el mundo compacto y nunca caen sobre arenas ni retos.

## 6. Faros de viaje rápido

Hay uno a 22 studs de la entrada de cada zona, más el del campamento. Se activan la primera vez que pasas cerca. El Mapa permite viajar a faros activados de zonas desbloqueadas, siempre con validación del servidor. Aparece un botón "Volver al santuario" en el HUD y en cada faro.

## 7. Identidad visual por zona

| Zona | Paleta y elementos |
|---|---|
| 1 | Verdes claros, abedules rosados, flores, luciérnagas, praderas abiertas. |
| 2 | Tierra dorada, ruinas de piedra, engranajes gigantes semienterrados, faroles de latón. |
| 3 | Verde azulado oscuro, hongos gigantes luminosos, niebla baja, árboles retorcidos. |
| 4 | Verde agua, estanques, flores enormes, cristales de hielo y braseros de fuego. |
| 5 | Violeta crepuscular, columnas y ruinas flotantes, runas, el Templo del Eclipse al final. |

## 8. Rendimiento

Conteo medido con la simulación (`tools/sim/petworld.lua`): unas **6.500 partes** en todo el Mundo PET (zona 1 ≈ 1.420, zona 2 ≈ 1.040, zona 3 ≈ 800, zona 4 ≈ 1.090, zona 5 ≈ 1.170), más el terreno. El santuario estático tiene ≈ 7.770 partes.

Recomendaciones (se aplican al publicar; ver el informe de la Fase C.1):

- **StreamingEnabled** en `Workspace`, con `StreamingTargetRadius` ≈ 384 y `StreamingMinRadius` ≈ 128. Cada zona es un `Model`/carpeta propia; las arenas y retos pueden marcarse `ModelStreamingMode = Atomic` para que se carguen completos.
- **Móviles:** sombras desactivadas en partes decorativas pequeñas (`CastShadow = false`), menos partículas cuando `GraphicsQualityLevel` es bajo y nada de luces dinámicas fuera de faroles y cristales.
- **Construcción:** el mundo se genera en el servidor por zonas (módulos separados), así que se puede ampliar una zona sin rehacer las demás.

## 9. Qué se retiró

- Las islas de zona, el hub del Reino y los portales por zona (Fase C).
- La arena única del campamento (Fase C.1): ahora hay una arena por zona.
- Fase D: las Minas de Zuar pasan a ser un mundo propio, con hub, Cantera y cinco galerías.

Los datos guardados no cambian: zonas desbloqueadas, parkours completados, faros y PETs se conservan.
