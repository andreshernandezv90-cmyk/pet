# Arquitectura de los tres mundos (decisión oficial GDD 1.1)

**Decisión del 6 de noviembre de 2026:** el juego tiene tres mundos diferenciados.

| Mundo | Función | Sistemas |
|---|---|---|
| **Hogar Dimensional** | Base y progresión doméstica | Casa, santuario, huerto, extractores, laboratorios, bosque y madera |
| **Minas de Zuar** | Minería | Cantera inicial, cinco galerías, minerales privados y, en el futuro, cuevas con guardianes |
| **Reino de los PETs** | Captura y aventura | Campamento, cinco zonas, quince especies, parkour, acertijos, arenas e incursiones |

Las galerías de las minas están **vinculadas a la progresión del Reino**: la galería *k* se abre cuando el jugador desbloquea la zona *k*.

## 1. Estado antes de la Fase D (auditoría)

| Pieza | Dónde | Estado |
|---|---|---|
| Mundo de minas separado y temporal | `World/Mines.luau` en (2000, 0, 0), con 50 nodos en franjas por mineral | Funciona; se accede desde el Mapa (`dest = "mines"`) |
| Bocas de mina en el Reino | `PetWorld.buildMineEntrance`: una por zona, **selladas** con tablas | Decorativas; sin función |
| Probabilidades por galería | `WorldConfig.Regions[k].mine` (`chances`, `slots`, `cycle`, `size`) | Definidas, pero no se usaban |
| Nodos y durabilidad | `Helpers.MakeNode`, `Mining.luau`: durabilidad y reaparición **por jugador**; el tipo de cada nodo es fijo y compartido | Funciona |
| Áreas | `World.AreaAt`: `home`, `mines`, `camp` y `z1`–`z5` | Funciona |
| Datos guardados de minería | Solo `story.visitedMines`. La durabilidad y las vetas son de la sesión | — |

**Conclusión:** las minas **no** estaban dentro del Reino; el plan anterior era integrarlas. Por eso, convertirlas en un mundo propio **no mueve datos guardados**. Basta con reemplazar el mundo temporal por el definitivo en el mismo lugar y con el mismo destino `mines`.

## 2. Reorganización (Fase D)

```
              MINAS DE ZUAR (2000, 0, 0) — montaña de terreno real
   ┌──────────────────────────────────────────────────────────────┐
   │   Gal. I      Gal. II        Gal. V (Gran Mina)     Gal. III     Gal. IV  │
   │   (cámara)   (cámara)          (gran cámara)        (cámara)    (cámara)  │
   │      │          │                   │                  │           │      │
   │  ════╪══════════╪═══ cara de la montaña ═══╪══════════╪═══════════╪════  │
   │    boca I     boca II            boca V              boca III    boca IV │
   │                     HUB: Campamento minero                              │
   │   Cantera de Zuar (libre)   ·   portal al Hogar · portal al Reino       │
   └──────────────────────────────────────────────────────────────┘
```

- **Hub (`mines`):** campamento minero al aire libre con la **Cantera de Zuar**, siempre libre, con la piedra del primer pico (regla del GDD §22). Tiene portales al Hogar y al Reino.
- **Galerías I–V (`m1`–`m5`):** cada boca tiene una cortina translúcida por jugador (la misma lógica que las barreras del Reino) y lleva por un túnel a una cámara excavada en el terreno. El tamaño de cada cámara sale de `mine.size` y el número de vetas por jugador, de `mine.slots`. Cada cámara tiene una salida al Reino.
- **Vetas privadas por jugador:** cada `mine.cycle` segundos, el servidor tira el dado de cada mineral con `mine.chances` y reparte los minerales presentes entre las vetas de la galería, con pesos configurables. Cada jugador ve solo **sus** minerales (el cliente los pinta localmente) y el servidor valida cada golpe contra **su** reparto.
- **Vínculo con el Reino:**
  - Las bocas de mina de cada zona del Reino dejan de estar selladas y llevan a su galería.
  - Desde la galería se vuelve a esa boca.
  - El Mapa permite viajar al hub y a las galerías desbloqueadas.
- **Guardianes (futuro):** cada galería tiene un sello configurable `mine.guardian` (desactivado). Cuando exista el combate por turnos, activarlo bloqueará los depósitos de esa galería hasta vencer al jefe, sin tocar la Cantera ni el código de las minas.

## 3. Compatibilidad con el progreso guardado

| Dato | Efecto |
|---|---|
| `zones.unlocked` | Ahora también abre las galerías. Un perfil con la zona 3 desbloqueada entra a las galerías I–III sin hacer nada más |
| `tools.pick` | Sigue decidiendo qué minerales se pueden extraer |
| `story.visitedMines` | Se marca al entrar al hub o a cualquier galería, como antes |
| Recursos, mochila y almacén | Sin cambios |
| Esquema | v2 → v3 **aditivo**: añade `lineage = "main"` (protección frente a otras implementaciones, ver `COMPATIBILIDAD_ASTRA.md`) y `mines.visited`. No borra ni renombra nada |

La durabilidad y las vetas siguen siendo de la sesión, como antes. Ningún perfil pierde recursos por la reorganización.

## 4. Riesgos

- **Terreno excavado:** las cámaras y los túneles se crean con `FillBlock`/`FillCylinder`/`FillBall` de aire. La geometría de terreno solo puede verificarse en Studio (el simulador registra las operaciones, no los vóxeles).
- **Iluminación interior:** dentro de la montaña no entra el sol; la legibilidad depende de los faroles y del ambiente por área (`WorldFx`). Hay que revisarla con capturas.
- **Bocas del Reino:** pasan de selladas a activas. Las barreras del Reino siguen mandando, porque solo se llega a la boca de la zona *k* si esa zona está desbloqueada.
- **Clientes antiguos:** no aplica; servidor y cliente se publican juntos.
