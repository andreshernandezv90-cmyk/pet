# Análisis del GDD Maestro 1.1 (6 nov 2026) frente al repositorio

**Fuente:** `docs/gdd/PortalPets_GDD_Maestro_v1.1.md` (y `.docx`), entregado el 6 de noviembre de 2026.

**Comparado con:** el estado real de la rama `claude/loving-fermi-8p6ket`, en el commit `b8e1a0b`, y con `docs/GDD.md`, que es el GDD 1.1 del 4 de noviembre más los ajustes 1.1b–1.1d aprobados en este proyecto.

**Estado:** solo es un análisis. **No se cambió código ni mecánicas.** Las decisiones marcadas con ❓ esperan tu aprobación.

---

## 1. Resumen

El maestro añade cuatro bloques nuevos:
- **§21 Duelos de Resonancia:** combate por turnos.
- **§22 Cuevas protegidas con Guardianes:** encima de las minas, con un jefe que forma parte de los requisitos de la zona siguiente.
- **§23 Variantes Shiny.**
- **§24 Precedencia de reglas,** pruebas nuevas y orden recomendado.

El resto (§01–§20) coincide casi por completo con lo implementado. Hay **cuatro discrepancias** que conviene resolver antes de seguir:

| # | Tema | Maestro 1.1 | Repositorio y ajustes aprobados aquí | Decisión |
|---|---|---|---|---|
| A | Base del proyecto | "Prototipo validado hasta v0.6, **esquema 4**" (Astra/Codex) | Este repositorio usa el **esquema 2** y ya implementa el Reactor, los niveles 0–5, las fusiones, las incursiones, el huerto, la alquimia, los cebos y el Mundo PET (Fases A–C.1 y L0) | ❓ ¿Cuál es la base oficial? |
| B | Mundos | "Exactamente tres mundos: hogar, minas y Reino" (Anexo A.1) | Aprobado en 1.1: Santuario + Mundo PET continuo, con **una Mina de Zuar dentro de cada zona** (Fase D). Las minas separadas son temporales hasta la Fase D | ❓ ¿Minas dentro del Mundo PET o como mundo aparte? |
| C | Arena de incursiones | "Utiliza una arena central" (§11) | Aprobado en C.1: **una arena temática por zona** | ❓ ¿Se mantiene la arena por zona? |
| D | Nombre de la zona 1 | Praderas Luminosas | Bosque de Lumi (1.1). El nombre antiguo se conserva como `legacyName` | ❓ ¿Qué nombre se usa? |

Sobre **A**: el esquema 4 del maestro no corresponde a este código. Si existe otra implementación (v0.6, de Astra) con perfiles reales de jugadores, mezclar las dos bases exige un plan de migración. Si la base es este repositorio, hay que tomar el maestro como **diseño** y no su tabla de estado (§20 y Anexo B).

Sobre **B**: es compatible leer "tres mundos **funcionales**" como hogar, minas y Reino, aunque físicamente las minas estén dentro del Mundo PET. La función de cada mundo se mantiene: minerales en las minas, madera y cultivos en el hogar, captura en el Reino. Propuesta: **mantener lo aprobado** y redactar el Anexo A.1 como "tres mundos funcionales".

## 2. Lo que ya coincide (sin cambios necesarios)

| Sección del maestro | En el repositorio |
|---|---|
| §03 Puertas de zona | Coinciden: Z2 pide pico de piedra y santuario 2 (más extractor de piedra, aprobado en 1.1); Z3 pide pico de cobre y una estación; Z4 pide pico de hierro, huerto 2 y succionador 2; Z5 pide equipo y santuario avanzados más especies. Están en `WorldConfig.Regions` |
| §04 15 especies, 63 variantes, mítico solo en Lumi, Nox y Eclipsar | `PetCatalog` (lo comprueba `shared.lua`) |
| §05 Estados (disponible, equipado, trabajador, fusionado) y espacios de equipo 1/2/3 | `PetStore` y `Stats` |
| §06 Apariciones privadas 7–12 cada 60 s, dos cálculos separados, 5 succionadores | `Config.Spawn*`, `Capture` e `Items.Vacuums` |
| §08 Producción offline de 2 h al 50% con tope de depósito | `Config.Offline*` |
| §09 Huerto, cebos y alquimia en la zona 3, y las 6 pociones | `Items` y `Recipes` |
| §10 Fusiones: 20 min de duración, 30 min de recarga, 1 gratis / 2 VIP, recarga 20% menor con VIP | `Config.Fusion*` |
| §11 Incursión aproximadamente cada hora, con 5 fases y niveles Bronce a Diamante | `Raid` y `Config.Raid*` |
| §12 Reactor determinista 2/3/5/10/15, con exclusión de equipados, trabajadores y fusionados, y nonce idempotente | `Reactor` (`smoke.lua`) |
| §13 Niveles 50/200/500/1000/5000 = 6.750, cobrados íntegros por salto | `PetCatalog.LevelCosts` (`shared.lua`) |
| §14 Mochila 5–25, tanque 3–15, pilas de 50 y ampliaciones a 9/39/69/119 Robux | `Config` y `PetStore` |
| §15 Productos y límites éticos (sin azar por Robux) | `Config.Products` |
| §17 Seguridad: servidor autoritativo, límite de frecuencia, bloqueo de sesión, BindToClose e idempotencia | `Net` y `DataService` |

Pendiente de cotejar en detalle (son cifras ilustrativas): la tabla de extractores de §08 (2/3/5/7/10 puestos; 1.000–100.000 de capacidad) y la escala de minería de Lumi de §13 (común ×1,10→×2,00; mítico ×2,00→×4,00). Ninguna de las dos es una regla cerrada.

## 3. Lo nuevo y su impacto

### 3.1 Shiny (§23) — impacto bajo, recomendado primero
- **Datos:** `isShiny` por individuo. Es una **migración aditiva** (v2 → v3): los PETs existentes quedan como `isShiny = false` y no se pierde nada.
- **Comportamiento:**
  - La probabilidad se decide al generar el encuentro, en el servidor. El valor exacto **no está fijado** en el GDD y hace falta decidirlo.
  - Sin efecto en las estadísticas.
  - El Reactor protege a los Shiny por defecto.
  - Se registra en la colección.
- **Pilas:** un Shiny no debe apilarse con los normales. Hay que conservar su identidad, ya sea como clave de pila propia (`lumi:common:shiny`) o como individuo.
- **Visual:** una paleta alternativa ligera. Encaja con `PetModels` y `PetAssets` (variante `Lumi_shiny`, o tinte sobre el procedural).

### 3.2 Combate por turnos (§21) — impacto alto, sistema nuevo
- Hacen falta `PetStats`/`MoveCatalog` (4 estadísticas y 4 movimientos por especie, 7 tipos, +25% de ventaja de tipo) y un `BattleService` en el servidor. Este servicio gestiona turnos privados de 20 s, prioridades, recargas, energía, cambios de PET, rendición, límite de turnos y desconexiones.
- **Bloqueo temporal de combate** (§05): no altera los estados persistentes.
- PvP normalizado: misma especie y nivel 5 → mismas estadísticas sin importar la rareza.
- Primer entregable del maestro: **tutorial PvE Lumi contra Rocón** en una "Arena del Santuario" tras la zona 2.
- Las incursiones **no** cambian: siguen siendo cooperativas en tiempo real.

### 3.3 Cuevas con Guardianes (§22) — afecta directamente a la Fase D
- Cada cueva sigue esta secuencia:
  1. entrada con punto de retorno;
  2. 2–3 guardianes por turnos;
  3. jefe;
  4. **minería liberada por jugador**;
  5. bandera persistente.
- La victoria contra el jefe pasa a ser **requisito de la zona siguiente**, sin romper los desbloqueos que ya tiene un perfil migrado.
- La **cantera inicial** (piedra del primer pico) sigue libre.
- Depende de §21: sin el combate por turnos, los guardianes no se pueden implementar como dice el GDD.

**Consecuencia para el roadmap:** la Fase D (minas dentro del Mundo PET con minerales privados) puede hacerse ya, porque su geografía y sus nodos no dependen del combate. Hay que dejar preparado un **"sello de guardián"** opcional y desactivado por configuración, que se activa cuando exista el combate.

### 3.4 Modelo de datos (§17)
El maestro propone `petInstances[...]`, `caveGuardianProgress`, `caveBossFlags`, `dungeonRewardsClaimed`, `battleStatistics` y `processedOperationIds`. El repositorio ya tiene unidades individuales, pilas, nonces y recibos.

Los campos nuevos se añadirán **solo cuando cada sistema exista**, con migraciones aditivas y probadas (perfil antiguo → nuevo, como en `petworld.lua`).

## 4. Propuesta de orden (pendiente de aprobación)

| Fase | Contenido | Depende de |
|---|---|---|
| **D** | Cinco Minas de Zuar dentro del Mundo PET, con minerales privados por jugador, cantera inicial libre y punto de enganche (desactivado) para el sello de guardián | Decisión B |
| **S** | Shiny: dato, probabilidad configurable, protección en el Reactor, colección y visual ligero | Valor de probabilidad |
| **B1** | Combate por turnos PvE: `PetStats`, `MoveCatalog` y `BattleService`; tutorial Lumi contra Rocón | — |
| **G** | Primera cueva con guardianes y jefe; bandera persistente; requisito de zona (con migración que respeta lo ya desbloqueado) | B1 y D |
| **B2** | Duelos PvP voluntarios normalizados | B1 |
| **E–G** | Las fases E/F/G del roadmap actual (spawns naturales, nuevo Taller, integración y móvil) se mantienen y se reordenan cuando apruebes | — |

La sesión de Blender (Lumi) sigue en paralelo y no depende de estas fases.

## 5. Decisiones que necesito

1. **A — Base oficial:** ¿este repositorio (esquema 2) o la v0.6 de Astra (esquema 4)?
2. **B — Minas:** ¿se mantienen dentro del Mundo PET, como se aprobó en 1.1, o vuelven a ser un mundo aparte?
3. **C — Arena:** ¿una por zona (C.1) o una central?
4. **D — Nombre de la zona 1:** ¿Bosque de Lumi o Praderas Luminosas?
5. **Orden:** ¿empiezo por la Fase D, por Shiny o por el combate por turnos?
6. **Shiny:** si va antes, ¿qué probabilidad base quieres? Propuesta de prueba: 1/500 por encuentro, configurable.
