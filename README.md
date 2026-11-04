# Portal Pets: Rescate Dimensional

Juego de aventura, colección y automatización de criaturas para **Roblox**, construido en **Luau** y sincronizado con **Rojo**.
Implementa el *Documento Maestro de Diseño* (GDD, ahora versión **1.1** en [`docs/GDD.md`](docs/GDD.md); hoja de ruta del rediseño en [`docs/ROADMAP.md`](docs/ROADMAP.md)): tres mundos, quince especies, captura por jugador, minería,
crafting, extractores, huerto, cebos, alquimia, Reactor de Esencias, niveles 0–5, pilas de 50, fusiones, incursiones
cooperativas, persistencia segura y tienda ética.

> Todo el mundo se genera con primitivas al iniciar el servidor: **no necesitas modelos ni assets externos**.

---

## 1. Requisitos

- **Roblox Studio**
- **Rojo 7.4 o superior**: la herramienta de línea de comandos y el plugin de Studio, con la misma versión.
  - Con [Rokit](https://github.com/rojo-rbx/rokit): `rokit install` (usa `rokit.toml`)
  - O con [Aftman](https://github.com/LPGhatguy/aftman): `aftman install` (usa `aftman.toml`)
  - O descarga Rojo desde https://github.com/rojo-rbx/rojo/releases
  - Plugin de Studio: `rojo plugin install`, o búscalo como "Rojo" en la tienda de plugins.

## 2. Cómo ejecutarlo en Roblox Studio

### Opción A: sincronización en vivo (recomendada para editar)

1. Descomprime el zip y abre una terminal dentro de la carpeta `PortalPets`.
2. Arranca el servidor de Rojo:
   ```bash
   rojo serve
   ```
3. En Roblox Studio crea un lugar nuevo (la plantilla **Baseplate** sirve; el juego retira el Baseplate solo).
4. En la pestaña **Plugins → Rojo**, pulsa **Connect** (localhost:34872).
5. Pulsa **Play** (F5).

### Opción B: generar un archivo de lugar

```bash
rojo build -o PortalPets.rbxlx
```

Después abre `PortalPets.rbxlx` con Roblox Studio y pulsa **Play**.

### Opción C: sin Rojo

El zip incluye `PortalPets.rbxlx`, generado con `python3 tools/build_rbxlx.py` siguiendo las reglas de Rojo.
Ábrelo directamente con Roblox Studio. Para seguir desarrollando, usa la opción A.

### Ajustes recomendados (Home → Game Settings)

| Ajuste | Valor | Para qué |
|---|---|---|
| Security → **Enable Studio Access to API Services** | Activado | Guardar el progreso con DataStore. Si está apagado, el juego funciona igual en **modo prueba** (sin guardar) y lo avisa en pantalla. |
| Places → **Max Players** | 8 | Hay 8 parcelas en el Hogar. |
| Workspace → **StreamingEnabled** | Activado (recomendado en celular) | El santuario tiene unas 7.000 partes estáticas más unas 450 por parcela ocupada; con streaming el celular solo carga lo cercano. El juego funciona con o sin streaming. |

Para guardar datos, el lugar debe estar **publicado** (File → Publish to Roblox).

## 3. Cómo se juega

| Acción | PC | Celular / tablet |
|---|---|---|
| Minar / talar / recoger | Mantén **E** junto al recurso | Mantén el botón que aparece |
| Capturar un PET | Mantén **F** junto al PET: el succionador lo atrae | Mantén el botón del PET |
| Abrir estaciones del santuario | **E** junto a la estación | Botón en pantalla |
| Paneles | Barra inferior: Mapa, PETs, Mochila, Taller, Estaciones, Alquimia, Reactor, Fusión, Tienda | Igual |

**Primeros 20 minutos (GDD 01):**

1. Apareces en tu parcela, con tu casa deteriorada.
2. **Mapa → Zona 1**: completa el parkour con checkpoints y captura tu primer **Lumi**.
3. **Mapa → Minas de Zuar**: consigue piedra con el pico de madera.
4. Tala árboles del **bosque** que rodea el Hogar para conseguir madera.
5. En el **Taller**, mejora el **Santuario a nivel 2** y fabrica el **Pico de piedra**: se desbloquea la Zona 2.

El HUD siempre muestra **dónde estás, qué hacer ahora y qué te falta para avanzar**.

### Herramientas de prueba (solo en Studio)

En Studio aparece el botón **🛠️ Dev** con estos atajos:

- +500 de cada recurso
- Desbloquearlo todo
- +3 de cada una de las 63 variantes y +2000 esencias por especie
- Iniciar una incursión ahora
- Reiniciar el perfil

En un servidor publicado estos atajos no funcionan.

## 4. Estructura del proyecto

```
default.project.json        Mapa de Rojo
src/shared/   → ReplicatedStorage.Shared
  Config.luau               Parámetros de balance, tiempos, IDs de productos
  PetCatalog.luau           15 especies, rarezas, habilidades, trabajos, costos de nivel
  Items.luau                Recursos, picos, succionadores, nodos, cultivos, cebos, pociones
  Recipes.luau              Fabricación y construcciones (herramientas, santuario, extractores…)
  WorldConfig.luau          Configuración por región: requisitos, especies, minas y probabilidades
  Progression.luau          Evaluador de requisitos, capacidades, objetivos del HUD, colección
  Stats.luau                Bonos de compañero/apoyo/fusión/pociones con topes; parámetros de captura
  PetStore.luau             Lógica pura de inventario: pilas de 50, individuos, tanque, almacén, mochila
  ProfileSchema.luau        Perfil persistente, valores por defecto y migraciones
  PetModels.luau            Modelos de PETs procedurales (silueta por especie, efectos por rareza)
src/server/   → ServerScriptService.Server
  init.server.luau          Arranque y entrada de jugadores
  Services/
    World/                  Construcción del mundo en módulos:
      init.luau             Registro del mundo y detección de áreas
      Terrain.luau          Terreno de Roblox: suelo, colinas, caminos de tierra, estanques
      Props.luau            Biblioteca visual: robles, abetos, abedules, arbustos, flores, hongos,
                            rocas, faroles, cercas, cajas, barriles, letreros, luciérnagas, portal mágico
      House.luau            Casa rústica por niveles (deteriorada → dimensional)
      StationArt.luau       Aspecto de cada estación (forja, caldero, reactor, torres de extracción, huerto)
      PlotLayout.luau       Distribución de la parcela y reservas (nada tapa estaciones ni caminos)
      Lighting.luau         Atmósfera, cielo, bloom y rayos de sol
      Home.luau             Santuario: plaza con fuente, 8 parcelas-bosque con su portal, bosque exterior
      Mines.luau, Realm.luau  Minas y Reino actuales (se rediseñan en las fases C y D)
    DataService.luau        DataStore: bloqueo de sesión, reintentos, autosave, BindToClose
    Net.luau                Remotos, límite de frecuencia y sincronización de estado
    Plots.luau              Parcelas: la casa cambia con el nivel, estaciones, trabajadores visibles
    Inventory.luau          Equipo, protección, depósito, cebos y pociones
    Mining.luau             Nodos con durabilidad individual por jugador
    Capture.luau            Apariciones privadas (7–12 cada 60 s), succionador y validación
    Progress.luau           Áreas, portales, viajes, desbloqueos, checkpoints, cofres secretos
    Crafting.luau           Recetas validadas en servidor
    Production.luau         Extractores, huerto automatizado y producción desconectado (2 h al 50%)
    Alchemy.luau            Pociones y cebos
    Essence.luau            Reactor determinista y mejoras 50/200/500/1000/5000 con nonce
    Fusion.luau             Resonancia Dimensional (20 min, recarga 30 min, VIP 2 simultáneas y 24 min)
    Raid.luau               Incursiones: barrera → pilares y ondas → resonancia final → recompensa privada
    Commerce.luau           Recibos idempotentes, VIP y cosméticos
    DevTools.luau           Atajos de prueba (solo Studio)
src/client/   → StarterPlayerScripts.Client
  init.client.luau          Arranque del cliente
  UI.luau, UIKit.luau       HUD móvil, avisos, ventana de paneles
  Panels/*.luau             Mapa, PETs (inventario, equipo, PETdex), Mochila, Taller, Estaciones,
                            Alquimia, Reactor, Fusión, Tienda, Dev
  Encounters.luau           PETs salvajes locales + captura con ProximityPrompt
  Followers.luau            Compañeros y fusiones de todos los jugadores, estela, alas, VIP
  WorldFx.luau              Iluminación por zona, gravedad, poderes de los PETs, trampolines, ondas
```

## 5. Correspondencia con el GDD

| GDD | Implementación |
|---|---|
| 02 Tres mundos | Hogar (0,0,0), Minas de Zuar (2000,0,0), Reino de los PETs (-2000,0,0). Portales y mapa. |
| 03 Desbloqueo de zonas | `WorldConfig.Regions[i].requirements` (configurable): Z2 pico de piedra + santuario 2 + extractor de piedra; Z3 pico de cobre + extractor; Z4 pico de hierro + huerto 2 + succionador mejorado; Z5 equipo avanzado + santuario 4 + misión de las 10 especies. |
| 04 Quince especies | `PetCatalog.Species`: zonas 1+2+3+4+5. Lumi, Nox y Eclipsar tienen mítico: 63 variantes. |
| 05 Roles | Cada PET individual está en un solo estado: libre, equipado, trabajando o fusionado. Equipo 1/2/3 (herrería 2, santuario 3); el apoyo aplica 50%. |
| 06 Captura | Encuentros privados por jugador (7–12, renovación 60 s). La rareza y el éxito se calculan por separado. Fortuna ×2 solo afecta la aparición. |
| 07 Minería y fabricación | 5 picos y 5 minerales; los nodos tienen durabilidad por jugador. Las recetas usan recursos de varios mundos. |
| 08 Extractores | Niveles 1–5: puestos 2/3/5/7/10 y depósito 1k/3k/10k/30k/100k. Offline hasta 2 h al 50%. |
| 09 Huerto, cebos, alquimia | Se desbloquean en la Zona 3. Musguito riega, Florín cosecha, Brumí resiembra, Chispa ayuda en alquimia. 6 pociones y 4 cebos. |
| 10 Fusiones | 20 min, recarga 30 min (VIP 24 min), 1 simultánea (VIP 2). Los PETs no se pierden y hay registro de combinaciones descubiertas. |
| 11 Incursiones | Cada hora (cada 5 min en Studio). Contribución por disparos, pilares y círculo. Rangos Bronce/Plata/Oro/Diamante con esencia y tirada de captura individual. |
| 12 Reactor | Conversión determinista 2/3/5/10/15, con vista previa exacta, confirmación y nonce idempotente. |
| 13 Niveles | Costos por salto 50/200/500/1000/5000 = 6750, iguales para todas las rarezas. |
| 14 Mochila y tanque | Mochila 5/10/15/20/25 y tanque 3/6/9/12/15 por zona. Pilas de 50 PETs y de 100 recursos. Almacén del santuario ampliable sin pagar. |
| 15 Monetización | Solo cosméticos y comodidad. No se vende azar. VIP y espacios con tope. |
| 17 Seguridad | El servidor recalcula todo y aplica límite de frecuencia, proximidad y validación de estado. Recibos idempotentes y guardado sin sobrescribir perfiles ajenos. |

## 6. Configurar la monetización

En `src/shared/Config.luau`:

- `Config.VipGamePassId`: el ID de tu Game Pass VIP.
- `Config.Products[i].productId`: el ID de cada Developer Product.

Mientras valgan `0`, en Studio se otorgan gratis para probar. En un servidor publicado aparecen como "No disponible".

## 7. Pruebas recomendadas antes de publicar (GDD 20)

1. Entrar, capturar, salir y volver: el perfil debe restaurarse (con API Services activado y el lugar publicado).
2. Llenar el tanque y la mochila: no deben perderse ni duplicarse PETs, recursos ni esencias.
3. En el Reactor, convertir 5 Lumi comunes y 1 raro: debe dar exactamente 13 esencias.
4. Subir un PET del nivel 0 al 5: deben descontarse 50 + 200 + 500 + 1000 + 5000.
5. Hacer una compra en Studio dos veces con el mismo recibo: no debe otorgarse dos veces.
6. Jugar en Studio con **Test → Clients and Servers** (2 a 8 jugadores): cada jugador tiene su parcela y sus PETs salvajes, y la incursión es compartida.
7. Completar todos los caminos esenciales sin Robux.

### Vistas previas sin abrir Studio

`tools/preview/` exporta la escena que construye el servidor y la dibuja de forma aproximada. Sirve para revisar la composición y las proporciones; no reemplaza a Studio. Requiere Python 3, numpy y Pillow.

```bash
lua5.4 tools/preview/export.lua scene.json 1 1
```

```bash
python3 tools/preview/render.py scene.json vista.png --plot 1 --view spawn
```

Vistas disponibles: `spawn`, `house`, `house2`, `front`, `aerial`, `plaza`, `overview`. En `docs/previews/` hay ejemplos.

### Pruebas automáticas fuera de Roblox

`tools/sim/` contiene un simulador mínimo de la API de Roblox para ejecutar el juego real con Lua 5.4. Ejecuta las pruebas desde la raíz del proyecto:

```bash
lua5.4 tools/sim/shared.lua
```

```bash
lua5.4 tools/sim/smoke.lua
```

```bash
lua5.4 tools/sim/raid.lua
```

```bash
lua5.4 tools/sim/sanctuary.lua
```

Qué cubre cada prueba:

- `shared.lua`: reglas del GDD (63 variantes, 6750 esencias, pilas de 50, mochila, recetas y topes).
- `smoke.lua`: arranque del servidor, entrada de un jugador, captura, todas las recetas, estaciones, offline, huerto, alquimia, equipo, Reactor con nonce, niveles 0→5, fusiones con VIP, tienda, guardado con bloqueo y los 10 paneles de la interfaz.
- `raid.lua`: bucles reales (áreas, caídas, zonas bloqueadas) y una incursión completa con recompensa.
- `sanctuary.lua`: distribución de la parcela sin superposiciones, bosque, árboles talables y portal en las 8 parcelas, casa en los 5 niveles, estaciones con interacción, trabajadores visibles, viaje por el portal de la casa y presupuesto de partes.

## 8. Pendiente para fases posteriores (según el GDD)

- Talentos individuales de PETs (GDD 04/13, "fase posterior").
- Ampliar las pilas de 50 a 75/100 (GDD 14, "actualización posterior").
- Publicar las probabilidades oficiales cuando las tablas estén cerradas.
- Arte final, animaciones y sonidos. Hoy los PETs y edificios usan primitivas procedurales.
- Calibrar el balance con métricas de sesiones reales: todas las cifras están en `Config`, `PetCatalog`, `Items` y `Recipes`.
