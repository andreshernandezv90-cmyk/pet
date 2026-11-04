# Mundo PET — propuesta de layout final (para aprobar antes de la Fase C)

Basada en el esquema que enviaste: un bosque grande, largo y continuo, dividido en zonas consecutivas con barreras translúcidas, PETs salvajes en el centro, una mina por zona hacia el norte y puestos de NPC al inicio.

Plano a escala: [`previews/mundo-pet-layout.png`](previews/mundo-pet-layout.png).

## 1. Estructura general

```
 NORTE  ── montaña con las cinco Minas de Zuar (la quinta, la Gran Mina, es la más grande) ──
        ┌──────────┬────────────┬────────────┬────────────┬────────────┬──────────────┐
        │CAMPAMENTO│  ZONA 1    ║  ZONA 2    ║  ZONA 3    ║  ZONA 4    ║   ZONA 5     │
 OESTE  │ portal   │  Bosque    ║  Valle de  ║  Cavernas  ║  Jardines  ║  Templo del  │  ESTE
        │ NPCs     │  de Lumi   ║  Engranajes║  Olvidadas ║ Elementales║  Eclipse     │
        │ arena    │ ═camino principal serpenteante═══════════════════════════════════│
        └──────────┴────────────╨────────────╨────────────╨────────────╨──────────────┘
 SUR    ── bosque denso: senderos secundarios, retos opcionales (parkour) con cofres ──
                    ║ = barrera translúcida con puerta mágica (individual por jugador)
```

| Tramo | Largo (studs) | Contenido principal |
|---|---|---|
| Campamento de bienvenida | 220 | Llegada desde el portal central del santuario, portal de regreso, 3 puestos de NPC, fogata, tablón de avisos, faro de la zona 1, arena de incursiones en un claro al sur. |
| Zona 1 · Bosque de Lumi | 420 | Primavera: flores y árboles claros. Lumi. Mina de Zuar I (piedra 100%, cobre 15%). Parkour tutorial opcional. |
| Zona 2 · Valle de los Engranajes | 430 | Ruinas mecánicas y engranajes gigantes. Rocón y Chispa. Mina II (+ hierro). Reto de plataformas móviles. |
| Zona 3 · Cavernas Olvidadas | 450 | Bosque oscuro con hongos gigantes luminosos y niebla. Talpa, Nox y Zuri. Mina III (+ cristal lunar). Túnel oscuro. |
| Zona 4 · Jardines Elementales | 470 | Jardines frondosos, estanques de cristal, fuego y hielo. Musguito, Flamín, Florín y Brumí. Mina IV (+ Zuarita). Muros de hielo y trampolines. |
| Zona 5 · Templo del Eclipse | 560 | Crepúsculo, ruinas flotantes y el templo final. Venti, Prisma, Gravix, Astrael y Eclipsar. **Gran Mina de Zuar**. Gravedad baja y plataformas ocultas. |

- **Total:** unos 2.550 studs de largo.
- **Franja transitable:** unos 320 studs de ancho de norte a sur:
  - una pradera central de unos 170 studs con el camino principal;
  - bosque a ambos lados.
- **Bordes:** montaña al norte y acantilado con bosque al sur, de terreno real. Además hay muros invisibles como respaldo, para no salir del mapa.

## 2. Las piezas del dibujo

| En el dibujo | En el juego |
|---|---|
| Cuadros a la izquierda | **Campamento** con 3 puestos de madera con toldo, letrero e iluminación. **Norte: Comerciante.** **Centro: Guía**, que explica captura, rarezas, minas, recursos, pico, hacha, barreras y extractores. **Sur: Tienda premium**, que muestra los productos de `Config` con su precio real de MarketplaceService; la compra se confirma solo en el servidor. |
| Puntos de colores | **PETs salvajes privados** en claros de la pradera central. Usan puntos de aparición validados (sin árboles, rocas ni pendientes) y conservan las probabilidades de rareza actuales. |
| Franjas negras | **Barreras translúcidas**: una cortina mágica de borde a borde con pilares de runas cada ~20 studs. En el camino principal hay una **puerta-arco** con letrero que muestra los requisitos que te faltan. |
| Círculos naranjas | **Minas de Zuar** excavadas en la montaña norte. Una boca de cueva con vigas de madera y faroles da a un túnel y a una o varias cámaras. Los minerales son **privados por jugador** y siguen la tabla de probabilidades acordada. La Gran Mina tiene varias cámaras y una caverna central con cristales. |

## 3. Barreras (cómo funcionan)

- **Se ve, pero no se cruza.** Es un material de campo de fuerza translúcido, con el color de la zona siguiente y partículas suaves.
- **Por jugador:**
  - Para todos es sólida.
  - Solo tu cliente la vuelve atravesable cuando tienes la zona desbloqueada (`zones.unlocked`, guardado permanente).
  - El servidor es la autoridad: si apareces del otro lado sin haber desbloqueado la zona, por un error de colisión, un salto o un rodeo, te devuelve a la puerta.
- Al acercarte, la puerta muestra **✅/❌ por requisito**. Al cumplirlos, se abre con un efecto solo para ti.

## 4. Minas (diseño)

| Mina | Tamaño | Vetas por jugador y ciclo | Minerales posibles |
|---|---|---|---|
| I | 1 cámara (≈ 45 studs) | 14 | Piedra, cobre |
| II | 1 cámara + túnel | 16 | + hierro |
| III | 2 cámaras | 18 | + cristal lunar (cristales luminosos) |
| IV | 2 cámaras + galería | 20 | + Zuarita |
| V · Gran Mina | 3 cámaras + caverna central (≈ 110 studs) | 28 | Todos, con más vetas de lo valioso |

Cada mina tiene **puntos de veta fijos** en paredes y suelo. Cada ciclo, el servidor tira el dado de cada mineral por separado para cada jugador y le asigna vetas. Cada jugador ve solo sus vetas: lo que tú agotas no afecta a nadie más.

## 5. Regalos aleatorios

- Aparecen en el **bosque a los lados del camino** y en los claros de cada zona.
- Son **privados**, de baja frecuencia (uno cada ~5 minutos en promedio) y se configuran por zona en `WorldConfig.Gifts`.
- La estructura ya está implementada (ver el commit de este ajuste). En la Fase C solo hay que darles las áreas del nuevo bosque.

## 6. Faros de viaje rápido

Hay uno en la entrada de cada zona, más el del campamento. Se activan la primera vez que pasas cerca. El Mapa permite viajar a faros activados de zonas desbloqueadas, siempre con validación del servidor. Aparece un botón "Volver al santuario" en el HUD y en cada faro.

## 7. Identidad visual por zona

| Zona | Paleta y elementos |
|---|---|
| 1 | Verdes claros, abedules rosados, flores, luciérnagas, praderas abiertas. |
| 2 | Tierra dorada, ruinas de piedra, engranajes gigantes semienterrados, faroles de latón. |
| 3 | Verde azulado oscuro, hongos gigantes luminosos, niebla baja, árboles retorcidos. |
| 4 | Verde agua, estanques, flores enormes, cristales de hielo y braseros de fuego. |
| 5 | Violeta crepuscular, columnas y ruinas flotantes, runas, el Templo del Eclipse al final. |

## 8. Rendimiento

- **Presupuesto:** unas 3.000 a 3.500 partes por zona, más el terreno. Uso árboles livianos en el bosque lejano, efectos moderados y **StreamingEnabled recomendado**: solo se carga lo cercano.
- **Construcción:** el mundo se genera en el servidor por zonas (módulos separados), así que se puede ampliar una zona sin rehacer las demás.

## 9. Qué se retira al implementarlo

- El mundo "Minas de Zuar" separado y sus nodos.
- Las islas de zona actuales.
- El hub del Reino.
- Los portales por zona.

Los parkours actuales se reubican como retos opcionales del bosque sur de cada zona. Los datos guardados no cambian: zonas desbloqueadas, parkours completados, faros y PETs se conservan.

## 10. Preguntas antes de implementar

1. **Comerciante normal.** El juego no tiene moneda blanda. Propongo un **intercambio de materiales** a tasas fijas, por ejemplo semillas, cebos básicos o ingredientes a cambio de recursos. ¿Te parece, o prefieres que por ahora sea solo un NPC informativo?
2. **Arena de incursiones.** ¿La dejo en el claro sur del campamento, para que todos se reúnan ahí, o prefieres que cada incursión ocurra dentro de la zona del jefe?
3. **Largo del mundo.** ¿Te sirven ~2.550 studs (unos 3 a 4 minutos caminando de punta a punta), o lo quieres más largo o más corto?
