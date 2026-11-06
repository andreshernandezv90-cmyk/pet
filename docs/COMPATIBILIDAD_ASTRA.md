# Compatibilidad entre implementaciones: repositorio principal ↔ Astra/Codex v0.6

**Decisión oficial:** este repositorio es la **dirección única de desarrollo**. La implementación de Astra/Codex (v0.6, validada en Studio, esquema 4) **se conserva intacta**. No se mezclan sistemas de persistencia ni se sobrescriben datos. **El repositorio principal no se considera validado hasta probarlo en Roblox Studio.**

## 1. Lo que sabemos de cada una

| | Repositorio principal | Astra/Codex v0.6 |
|---|---|---|
| Código disponible en esta sesión | Sí | **No.** Ningún repositorio accesible la contiene; la información sale del GDD Maestro (§17, §20, §24, Anexo B) |
| Validación en Studio | Pendiente (Fases A–D y L0) | v0.1–v0.6, incluida una prueba con dos clientes |
| Esquema de perfil | `schemaVersion` 2 → **3** desde la Fase D, con `lineage = "main"` | `schemaVersion` 4 (según el GDD) |
| DataStore | `PortalPets_Perfiles_v1`, clave `u_<UserId>`, envoltorio `{ data = perfil, lock = {...} }` | **Desconocido** |
| Modelo de PETs | Pilas `stacks.tank`/`storage` + individuos `units[id] = { id, s, r, lv, st, lock, loc }` | `petInstances[id, speciesId, rarityId, isShiny, level, status, lockFlag, traits?]` (GDD §17) |
| Esencias | `essence[speciesId]` | `essenceBySpecies` |
| Otros | `zones`, `world` (faros), `stations`, `fusion`, `receipts`… | `caveGuardianProgress`, `caveBossFlags`, `battleStatistics`, `processedOperationIds`… |

Los nombres y las estructuras **no coinciden**. Una migración automática sin el código de Astra sería una suposición, así que **no se hace**.

## 2. Riesgo principal: compartir el DataStore

Si las dos versiones se publicaran en la **misma experiencia de Roblox** (el DataStore es por experiencia) con el mismo nombre y la misma clave, una podría sobrescribir los perfiles de la otra.

Desde la Fase D, el repositorio principal se protege así (`DataService` + `ProfileSchema.Classify`):

| Lo que encuentra al cargar | Qué hace |
|---|---|
| Clave vacía | Crea un perfil nuevo (como antes) |
| `{ data = perfil }` con `schemaVersion` ≤ 2 y sin `lineage` | Perfil propio antiguo: lo migra a v3 de forma aditiva (como antes) |
| `{ data = perfil }` con `lineage = "main"` y `schemaVersion` ≤ 3 | Perfil propio: lo carga |
| Cualquier otra forma: sin envoltorio `data`, `lineage` ajeno, `schemaVersion` mayor que el propio, o ≥ 3 sin `lineage` | **Perfil ajeno o futuro: no lo migra ni lo guarda.** En un servidor publicado expulsa al jugador con un aviso; en Studio juega con un perfil temporal que no se guarda |

Así, un perfil de esquema 4 de Astra **nunca** se toca, aunque las dos versiones compartan almacén. Lo cubren las pruebas de `tools/sim/mines.lua` (sección de persistencia).

**Recomendación:** publicar el repositorio principal en una experiencia **distinta** a la de Astra mientras dure la validación, o confirmar que sus `DataStoreName` son diferentes.

## 3. Si en el futuro se quiere traer el progreso de Astra

Hace falta, en este orden:

1. Acceso al código de Astra v0.6 (o a su `ProfileSchema`): nombre del DataStore, clave, envoltorio y campos.
2. Una tabla de equivalencias campo por campo. Ejemplos: `petInstances` → `units` y `stacks`; `essenceBySpecies` → `essence`; `isShiny` → el campo Shiny de la fase S.
3. Un importador **de solo lectura** que lea el perfil de Astra y escriba en el almacén propio con `lineage = "main"`, conservando una copia del original. Nunca debe escribir sobre el de Astra.
4. Pruebas con perfiles reales exportados (anonimizados) y aprobación tuya antes de activarlo.

Hasta entonces, las dos implementaciones conviven sin tocarse.
