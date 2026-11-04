# Hoja de ruta — Rediseño visual y Mundo PET continuo (GDD 1.1)

| Fase | Contenido | Estado |
|---|---|---|
| A | Arquitectura del nuevo mundo: `WorldConfig` por región, requisitos configurables, requisitos derivados de materiales en recetas, migración de perfil v2, división de `World` en módulos, GDD 1.1 en `docs/`. | ✅ Hecha |
| B | Santuario y parcelas: terreno con desniveles, bosque por parcela, casa rústica deteriorada, caminos de tierra, espacios de extractores, portal frente a la casa. | Pendiente |
| C | Mundo PET continuo (cinco regiones), campamento de bienvenida, barreras translúcidas por jugador, faros de viaje rápido, retiro del mundo de minas separado y de los portales por zona. Parkours como actividades opcionales. | Pendiente |
| D | Cinco Minas de Zuar con cuevas reales y nodos minerales privados por jugador según `WorldConfig.Regions[i].mine.chances`. | Pendiente |
| E | Apariciones de PETs en puntos naturales válidos por región; NPC guía y NPC comerciante (MarketplaceService, confirmación en servidor). | Pendiente |
| F | Nuevo Taller (nombre, icono, descripción, tienes/necesitas, requisitos, estado), HUD de orientación y señalización. | Pendiente |
| G | Integración, persistencia y reconexión, multijugador, conteo de partes y rendimiento móvil. | Pendiente |

## Decisiones aprobadas

1. Santuario + Mundo PET; las cinco minas conservan el nombre Minas de Zuar.
2. Zona 2: pico de piedra + santuario 2 + extractor de piedra. Zonas 3–5 según el GDD.
3. Se conservan los costos del pico; ninguna herramienta pide materiales aún no recolectables (verificado por `tools/sim/shared.lua`).
4. Un portal frente a cada casa hacia la entrada del Mundo PET + faros de viaje rápido.
5. Parkours actuales como actividades secundarias opcionales con cofres.
6. Nodos minerales privados por jugador (aparición, agotamiento y regeneración independientes).
7. Estética fantástica estilizada con siluetas naturales, optimizada para móviles.
