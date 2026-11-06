# Hoja de ruta — Rediseño visual y Mundo PET continuo (GDD 1.1)

| Fase | Contenido | Estado |
|---|---|---|
| A | Arquitectura del nuevo mundo: `WorldConfig` por región, requisitos configurables, requisitos derivados de materiales en recetas, migración de perfil v2, división de `World` en módulos, GDD 1.1 en `docs/`. | ✅ Hecha |
| B | Santuario y parcelas: terreno con desniveles, bosque por parcela, casa rústica deteriorada, caminos de tierra, espacios de extractores. | ✅ Hecha |
| B2 | Ajuste tras prueba en Studio: pasto corto, césped limpio, caminos claros, áreas de trabajo con identidad, portal central único en la plaza, hacha por niveles, HUD de progreso, sistema de regalos. | ✅ Hecha |
| C0 | Propuesta concreta del layout del Mundo PET (`docs/MUNDO_PET_LAYOUT.md`). | ✅ Aprobada |
| C | Mundo PET continuo (cinco regiones), campamento con Comerciante (intercambios), Guía y Tienda premium, arena en el campamento, barreras translúcidas por jugador validadas en el servidor, cinco faros de viaje rápido, retos opcionales con cofre, regalos con cupo por hora. Se retiran el Reino de islas y los portales por zona. Las Minas de Zuar separadas siguen accesibles desde el Mapa hasta la Fase D. | ✅ Hecha (pendiente de verificación en Studio) |
| C.1 | Rediseño compacto del Mundo PET: 1.530 studs (antes ≈ 2.550), una arena de incursiones temática por zona con un único sistema de incursiones parametrizado (sin cambios de recompensas ni equilibrio), claros de PETs más cercanos al camino y aparición sesgada hacia los claros cercanos (mismas entidades activas), cinco retos de parkour con mecánicas distintas, iluminación más suave (Bloom, reflejos, partículas) y pruebas de layout, arenas y parkours. | ✅ Hecha (pendiente de verificación en Studio) |
| L0 | Preparación para modelos importados: `PetAssets` (plantillas en `ReplicatedStorage.PetAssets` desde `assets/pets/`), `PetModels` con respaldo procedural, `PetAnimator` (Idle, Walk, Run, Jump, CaptureReaction) conectado a PETs salvajes, compañeros, trabajadores y jefe; `docs/ART_PIPELINE.md` para coordinar con la sesión de Blender. Sin modelo de Lumi importado todavía. | ✅ Hecha (pendiente del modelo y de verificación en Studio) |
| — | GDD Maestro 1.1 (6 nov) recibido y analizado: duelos por turnos, cuevas con guardianes y Shiny. Propuesta de fases D → S → B1 → G → B2 en `docs/GDD_MAESTRO_ANALISIS.md`. | ⏸️ Esperando decisiones |
| D | Cinco Minas de Zuar con cuevas reales y nodos minerales privados por jugador según `WorldConfig.Regions[i].mine.chances`. | Pendiente |
| E | Apariciones de PETs en puntos naturales válidos por región; NPC guía y NPC comerciante (MarketplaceService, confirmación en servidor). | Pendiente |
| F | Nuevo Taller (nombre, icono, descripción, tienes/necesitas, requisitos, estado), HUD de orientación y señalización. | Pendiente |
| G | Integración, persistencia y reconexión, multijugador, conteo de partes y rendimiento móvil. | Pendiente |

## Decisiones aprobadas

1. Santuario + Mundo PET; las cinco minas conservan el nombre Minas de Zuar.
2. Zona 2: pico de piedra + santuario 2 + extractor de piedra. Zonas 3–5 según el GDD.
3. Se conservan los costos del pico; ninguna herramienta pide materiales aún no recolectables (verificado por `tools/sim/shared.lua`).
4. ~~Un portal frente a cada casa~~ → (1.1b) un único portal central en la plaza + faros de viaje rápido.
5. Parkours como actividades secundarias opcionales con cofres; desde C.1, uno por zona con mecánica propia (troncos, engranajes, rebote, hielo, caminos temporales).
6. Nodos minerales privados por jugador (aparición, agotamiento y regeneración independientes).
7. Estética fantástica estilizada con siluetas naturales, optimizada para móviles.
8. (C.1) Una arena de incursiones por zona en lugar de la arena del campamento; solo pueden ir quienes tengan esa zona desbloqueada.
