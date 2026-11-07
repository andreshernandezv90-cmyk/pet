# Pipeline de arte: de Blender a Roblox (Lumi)

Este documento coordina dos trabajos independientes:

| Quién | Trabaja en | No toca |
|---|---|---|
| **Claude de arte** (sesión local con Blender MCP) | `art/lumi/**`: `.blend`, `.fbx`, texturas y animaciones fuente | `src/**`, `tools/**`, `default.project.json`, `assets/pets/**` |
| **Claude del juego** (esta sesión) | `src/**`, `tools/**`, `docs/**` (salvo `art/`), `default.project.json` | Nada dentro de `art/**` ni los modelos guardados en `assets/pets/` |
| **Tú, en Roblox Studio** | Importar el FBX, publicar las animaciones y guardar `assets/pets/Lumi.rbxmx` | — |

Las rutas no se pisan, así que las dos sesiones pueden trabajar en ramas distintas y fusionarse sin conflictos. Recomendación: rama `art/lumi` para el arte y la rama de desarrollo para el código. Para archivos binarios grandes (`.blend`, `.fbx`, `.png`) conviene Git LFS; lo decides tú antes de subir el primer binario.

Estados de cada asset (regla de `roblox-visual-director`). Nunca se da por integrado algo que aún no se importó:

`Propuesto → Exportado desde Blender → Importado en Studio → Guardado en assets/pets → Referenciado en código con respaldo → Verificado en Studio`

**Estado actual de Lumi Común V1.0:**
- Animaciones: `Referenciado en código con respaldo`. Los 7 ids publicados están en `PetAssets.AnimationSets.Lumi_v7` (sección 10).
- Modelo: `Guardado en assets/pets`, como `assets/pets/Lumi.rbxm` (binario). Su estructura se comprobó con `rojo build` (sección 11).
- **Nada está verificado todavía dentro de Portal Pets en Studio.**

---

## 1. Cómo lo usa el juego

```
ReplicatedStorage
├─ Shared
│  ├─ PetModels      construye el PET: modelo importado si existe; si no, procedural
│  ├─ PetAssets      registro por especie (nombre de plantilla, alto, giro, animaciones)
│  └─ PetAnimator    Idle / Walk / Run / Jump / CaptureReaction con respaldos
└─ PetAssets         ← carpeta de plantillas (Rojo la sincroniza desde assets/pets/)
   └─ Lumi           ← modelo importado (todavía no existe)
```

- Solo cambia **el aspecto**. La especie (`lumi`), la rareza, la evolución (niveles y fusiones), el inventario, las estadísticas, la captura y los datos guardados no dependen del modelo.
- Clientes y servidor usan la misma plantilla: PETs salvajes (`Encounters`), compañeros y fusiones (`Followers`), trabajadores de la parcela (`Plots`) y jefe de incursión (`Raid`).
- El modelo importado se escala solo para medir lo mismo que el procedural: alto = 2 × escala × tamaño de rareza. Un Lumi común mide 2 studs y uno mítico, 3.
- Sobre el modelo importado se añaden los mismos efectos de rareza que hoy: luz de Lumi, destellos, luz extra, contorno, etiqueta y sombrero VIP.

## 2. Formatos

| Qué | Formato | Notas |
|---|---|---|
| Fuente de modelado | `.blend` | Solo para Blender; Roblox no lo lee. |
| Malla con rig | `.fbx` (binario) | Es la entrada del importador 3D de Studio. |
| Animaciones | `.fbx`, una por animación | Se importan desde el Animation Editor de Studio. |
| Texturas | `.png` | Color (sRGB), Normal (OpenGL, Y+), Roughness y Metalness (lineales). |
| Modelo listo para el juego | `.rbxmx` (XML, recomendado) o `.rbxm` | Se guarda desde Studio. Rojo admite los dos; `tools/build_rbxlx.py` solo incrusta `.rbxmx`. |

## 3. Nombres de archivos y animaciones

```
art/lumi/
├─ Lumi.blend
├─ export/
│  ├─ Lumi_Rig.fbx               malla + esqueleto, en pose de reposo
│  └─ anims/
│     ├─ Lumi_Idle.fbx
│     ├─ Lumi_Walk.fbx
│     ├─ Lumi_Run.fbx
│     ├─ Lumi_Jump.fbx
│     └─ Lumi_CaptureReaction.fbx
└─ textures/
   ├─ Lumi_BaseColor.png
   ├─ Lumi_Normal.png
   ├─ Lumi_Roughness.png
   └─ Lumi_Metalness.png         (opcional; Lumi casi no tiene metal)
```

**Nombres de las acciones en Blender y de los objetos `Animation` en Roblox** (exactos, con mayúsculas):

| Estado | Capa | Bucle | Prioridad | Cuándo lo usa el juego |
|---|---|---|---|---|
| `Idle` | base | sí | Idle | Quieto: PET salvaje, compañero parado y jefe de incursión |
| `Walk` | base | sí | Movement | Se mueve a ≥ 0,6 studs/s. Si falta, `Idle` |
| `Run` | base | sí | Movement | Se mueve a ≥ 7 studs/s (compañero de un jugador que corre). Si falta, `Walk` |
| `Work` | base | sí | Action | PET asignado a una estación de la parcela (estado `working`). Si falta, `Idle` |
| `Happy` | acción | no | Action | **Preparada, sin mecánica todavía** (`anim:Celebrate()`). Al terminar vuelve a la capa de debajo |
| `Sleep_Enter` | sueño | no | Action | **Preparada, sin mecánica todavía** (`anim:Sleep()`); enlaza sola con `Sleep_Loop` |
| `Sleep_Loop` | sueño | sí | Action | Mientras duerme, hasta `anim:Wake()` o hasta que el PET se desplace |
| `Jump` | base | no | Action | Compañero con el jugador en el aire, **solo si el PET tiene `Jump`**; si no, sigue con su locomoción |
| `CaptureReaction` | base | sí | Action | Mientras el jugador lo succiona. Si falta, `Idle` (Lumi Común no la tiene) |

Variantes opcionales por rareza: `Lumi_common`, `Lumi_rare`, `Lumi_epic`, `Lumi_legendary` y `Lumi_mythic`. Si existe `Lumi_<rareza>`, se usa esa; si no, `Lumi`.

## 4. Estructura esperada del rig

- **Una malla principal deformada por huesos** (skinned mesh). Puede haber 1–3 piezas rígidas extra (por ejemplo, el halo) emparentadas a un hueso.
- Esqueleto (armature `Lumi_Armature`):
  ```
  Root            (en el suelo, en el centro; no deforma)
  └─ Body
     ├─ Head
     │  ├─ Ear_L / Ear_R        (según el diseño)
     │  └─ Halo                 (pieza luminosa, opcional)
     ├─ Tail_01 → Tail_02 → Tail_03
     └─ Paw_FL / Paw_FR / Paw_BL / Paw_BR   (si tiene patas)
  ```
  El diseño concreto lo decide el Claude de arte. Solo se exigen el hueso `Root` y nombres ASCII sin espacios, con sufijos `_L` y `_R`.
- **Límites:**
  - ≤ 40 huesos;
  - ≤ 4 influencias por vértice, con los pesos normalizados;
  - ≤ 4.000 triángulos (recomendado 2.500), porque puede haber 12 Lumi en pantalla.
- **Sin root motion:** las animaciones son en el sitio. El juego mueve el modelo; el hueso `Root` no se desplaza en X ni en Z. En `Jump` puede subir el `Body`.
- Velocidad de animación: 30 fps. En los bucles, el primer fotograma y el último coinciden.

## 5. Escala y orientación

- **Escala:** el código normaliza el alto, así que el tamaño exportado no tiene que ser exacto. Lo importante es que en Studio aparezca en un rango razonable (1–4 studs) y sin transformaciones raras. En Blender, aplica todas las transformaciones (Ctrl+A → All Transforms) antes de exportar.
- **Origen:** en el suelo, entre las patas o bajo el centro del cuerpo.
- **Frente:** en Roblox, el frente de un PET es −Z (la `LookVector` de su raíz). En Blender, Lumi debe mirar hacia −Y (hacia la cámara en la vista frontal, Numpad 1). Exporta el FBX con *Forward: −Z* y *Up: Y* y *Apply Transform* activado.
- **Comprobación en Studio:** la cara debe apuntar en la dirección en la que camina. Si queda girada, no hace falta reexportar: cambia `yaw` (90, 180 o −90) en `src/shared/PetAssets.luau`, dentro de `PetAssets.Species.lumi`.

## 6. Dónde va el modelo importado

1. Importa en Studio: **File → Import 3D** (importador 3D) y elige `art/lumi/export/Lumi_Rig.fbx`. Revisa en la vista previa que el rig y las texturas lleguen bien. Las opciones exactas del importador cambian con las versiones de Studio, así que verifícalas al importar.
2. Organiza el resultado así (el nombre del modelo es obligatorio):
   ```
   Lumi                    (Model, PrimaryPart = la parte raíz)
   ├─ LumiMesh             (MeshPart con los Bone dentro y su SurfaceAppearance)
   ├─ RootPart             (opcional: Part invisible en los pies si el rig usa Motor6D)
   ├─ AnimationController  (si el importador no lo crea, el juego lo crea solo)
   │  └─ Animator
   └─ Animations           (Folder)
      ├─ Idle              (Animation, AnimationId = rbxassetid://<id publicado>)
      ├─ Walk
      ├─ Run
      ├─ Jump
      └─ CaptureReaction
   ```
   - Con una sola malla deformada, `PrimaryPart` puede ser la propia `LumiMesh`.
   - El juego quita la colisión y la masa, suelda las piezas sueltas a la raíz, escala el modelo y calcula el pivote. No hace falta configurarlo a mano.
   - **No pongas scripts dentro del modelo.** El juego los elimina al clonar y avisa en Output.
   - Límite: 40 partes por plantilla; por encima, el juego usa el respaldo procedural.
3. Texturas: añade una `SurfaceAppearance` a `LumiMesh` con los mapas subidos (Color, Normal, Roughness y Metalness). Usa `AlphaMode = Overlay` salvo que haya recortes transparentes. Las texturas se asignan en Studio; un script no puede cambiarlas.
4. Arrastra `Lumi` a **ReplicatedStorage → PetAssets**. La carpeta está configurada para que Rojo no borre lo que pongas a mano durante `rojo serve`.
5. Guarda la plantilla en el repositorio: clic derecho en `Lumi` → **Save to File…** → `assets/pets/Lumi.rbxmx`. Al sincronizar, Rojo la coloca en `ReplicatedStorage.PetAssets.Lumi`; el nombre del archivo es el nombre de la instancia.

Las mallas, texturas y animaciones deben estar **subidas por la cuenta o el grupo dueño de la experiencia**. Si no, Roblox no las carga en el juego publicado.

## 7. Cómo conectar las animaciones

1. En Studio: **Avatar → Animation Editor** y selecciona el modelo `Lumi`.
2. Menú `…` → **Import → From FBX Animation** y elige `Lumi_Idle.fbx`. Repite con cada animación.
3. Marca el bucle en `Idle`, `Walk`, `Run`, `Work`, `Sleep_Loop` y `CaptureReaction`, y desmárcalo en `Happy` y `Sleep_Enter`. El juego también lo fuerza por código.
4. **Publish to Roblox** con la cuenta o el grupo dueño de la experiencia y copia el id que te da Studio.
5. En `Lumi/Animations`, crea un `Animation` por estado, con el nombre exacto, y pega `rbxassetid://<id>` en `AnimationId`.
6. Alternativa: escribe los ids en `PetAssets.Species.lumi.animations` (en `src/shared/PetAssets.luau`). **Hoy esa tabla está vacía a propósito: no se inventan ids.** Los ids de la plantilla tienen prioridad.

Comportamiento del código (`PetAnimator`):
- Solo existe en los modelos importados que tienen al menos una animación válida. El modelo procedural conserva su rebote de siempre.
- Tres capas (base < sueño < acción) y **una sola pista sonando a la vez**, con fundido cruzado (0,1–0,25 s según el estado, en `PetAssets.StateInfo`).
- Las pistas se cargan una vez por modelo y se reutilizan; los objetos `Animation` se comparten entre todos los PETs. Pedir el mismo estado cada fotograma no reinicia la pista.
- Velocidad de reproducción: `Walk` con referencia de 4 studs/s y `Run` con referencia de 12 studs/s.
- Una acción (`Happy`) no se corta por la locomoción: el cambio se anota y se aplica al terminar. Dormido no celebra. Si un PET dormido se desplaza, despierta (nunca se desliza dormido).
- Los finales de pistas sin bucle se detectan por duración (fundido antes del final) y por `Stopped`.
- Réplica: los trabajadores y el jefe se animan en el servidor (el `Animator` del servidor se replica a todos). Los PETs salvajes (privados) y los compañeros los construye y anima cada cliente, así que todos ven animados los compañeros de los demás. Una futura mecánica de sueño o celebración de compañeros tendrá que publicarse (por ejemplo, con un atributo replicado) para que la vean los demás.
- Conjuntos por rig (`PetAssets.AnimationSets`): Lumi usa `Lumi_v7`. Las rarezas con el mismo rig lo reutilizan sin configurar nada; una rareza con rig propio declara `variants[rareza].animationSet`. Si la plantilla tiene el atributo `Rig` y no coincide con el del conjunto, no se anima con él (aviso en Output).
- Orden de búsqueda de cada animación: carpeta `Animations` de la plantilla → `variants[rareza].animations` → `animations` de la especie → conjunto.
- Panel **Dev** (solo Studio): botones para ver `Happy`, `Sleep` y despertar en tus compañeros equipados. Es solo una vista previa local.

## 8. Cómo se conserva el respaldo procedural

El modelo procedural de `PetModels` **no se borra nunca**. El juego vuelve a él automáticamente si:
- no existe `ReplicatedStorage.PetAssets.Lumi`;
- la plantilla no es un `Model`, no tiene partes visibles o supera 40 partes (con aviso en Output);
- falla el clonado o el escalado (con aviso en Output).

Para comparar o desactivar a mano:
- En Studio, el atributo `UseProcedural = true` en `ReplicatedStorage.PetAssets` fuerza el respaldo sin tocar código.
- En código, `PetAssets.Enabled = false` (global) o `enabled = false` dentro de `PetAssets.Species.lumi`.

Pruebas automáticas (`lua5.4 tools/sim/petassets.lua`, con una plantilla **simulada**, no un asset real):
- sin plantilla, las 15 especies y 5 rarezas siguen siendo procedurales;
- con plantilla, Lumi usa el modelo importado escalado, sin colisión, con la raíz anclada, las piezas sueltas soldadas, los scripts eliminados y los efectos de rareza;
- variantes por rareza e interruptores de respaldo;
- plantillas inválidas y animaciones con sus respaldos;
- PETs salvajes y compañeros en el cliente, incluida `CaptureReaction` durante la succión.

Además, se comprobó que el modelo procedural es idéntico al de antes en 300 combinaciones (especie × rareza × opciones).

## 9. Pruebas en Roblox Studio (cuando exista el modelo)

Nada de esto está verificado todavía, porque el modelo aún no existe.

1. **Sin modelo:** el juego se ve y funciona como antes; Lumi es procedural y no hay avisos `[PetAssets]` en Output.
2. **Con `Lumi` en PetAssets:** los Lumi salvajes de la Zona 1 usan el modelo importado.
   - Tamaño parecido al procedural (común 2 studs, mítico 3).
   - Apoyados sobre el suelo, sin flotar ni hundirse.
   - La cara mira hacia donde caminan.
3. **Animaciones:**
   - `Idle` al estar quietos y `Walk` al deambular.
   - `CaptureReaction` mientras mantienes **F** para succionar; al soltar, vuelven a moverse.
   - Compañero equipado: `Walk` y `Run` al seguirte caminando o corriendo, y `Jump` al saltar.
   - Los bucles no tienen saltos y no hay deslizamiento visible de las patas.
4. **Rarezas:** destellos (raro+), luz extra (épico+), contorno (legendario+) y la etiqueta de nombre por encima del modelo.
5. **Otros usos:**
   - fusiones (PET principal + PET pequeño encima);
   - sombrero VIP;
   - Lumi trabajando en una estación de la parcela (animación `Work`; los demás jugadores también la ven);
   - jefe de incursión Lumi (escala 6).
6. **Multijugador** con 2 clientes: cada uno ve animados los compañeros del otro, y los PETs salvajes siguen siendo privados.
7. **Captura y datos:**
   - capturar un Lumi y comprobar que llega al tanque con su rareza;
   - reconectar y comprobar que el inventario, los niveles y las fusiones siguen iguales.
8. **Respaldo:** con `UseProcedural = true` en PetAssets, los Lumi nuevos vuelven a ser procedurales.
9. **Rendimiento:** 12 Lumi en pantalla más compañeros en un móvil, o con el emulador de dispositivos. Revisar los FPS y la memoria en el MicroProfiler o en Stats.
10. Hacer capturas desde los puntos fijos de la skill `roblox-visual-director` (zona 1 y parcela) para compararlas.

## 10. Lumi Común V1.0 (`Downloads/Lumi_Roblox_Export`)

### Análisis de los FBX (hecho por código, sin abrir Studio)

| Archivo | Toma | Duración | Fotogramas | Bucle cerrado |
|---|---|---|---|---|
| `Lumi_Comun_Model.fbx` | — (malla + rig) | — | — | — |
| `Lumi_Idle.fbx` | `Lumi_Idle` | 3,0 s | 91 | sí |
| `Lumi_Walk.fbx` | `Lumi_Walk` | 1,0 s | 31 | sí |
| `Lumi_Run.fbx` | `Lumi_Run` | 0,6 s | 19 | sí |
| `Lumi_Happy.fbx` | `Lumi_Happy` | 1,33 s | 41 | vuelve a su pose inicial |
| `Lumi_Sleep_Enter.fbx` | `Lumi_Sleep_Enter` | 1,2 s | 37 | no (transición) |
| `Lumi_Sleep_Loop.fbx` | `Lumi_Sleep_Loop` | 3,8 s | 115 | sí |
| `Lumi_Work.fbx` | `Lumi_Work` | 1,6 s | 49 | sí |

- FBX 7.4 binario, 30 fps en los 8 archivos.
- **Mismo esqueleto en los 8:** 34 huesos con nombres y jerarquía idénticos (`Lumi_Rig` → `Root` → `Hips` → …), 34 clusters de piel.
- **Sin root motion:** `Root` y `Lumi_Rig` no se desplazan en ninguna animación. Solo `Hips` sube o baja unos centímetros.
- **Transiciones:** la pose final de `Sleep_Enter` coincide con la inicial de `Sleep_Loop` (0°), y la inicial de `Sleep_Enter` coincide con `Idle` (0°). Entre los demás estados, la diferencia de pose la cubre el fundido cruzado.
- Malla `Lumi_Comun_Body`: 7.886 vértices y **15.631 triángulos**. Está dentro del límite de importación de Roblox, pero es casi 4 veces el presupuesto de este documento (≤ 4.000), así que hay que medir el rendimiento con 12 Lumi en pantalla en móvil.
- Textura `Lumi_Comun_Texture.png`: 2048×2048, idéntica a `Lumi_Comun_Model.fbm/texture_0.png`. Roblox la reduce a 1024×1024 al subirla.
- Los huesos usan sufijos `.L` y `.R` (no `_L` y `_R`). Es válido: lo único que importa es que el modelo y las animaciones usen los mismos nombres, y así es.

### Pasos en Roblox Studio

Pasos generales en las secciones 6 y 7. Resumen para Lumi Común:
1. **Import 3D** de `Lumi_Comun_Model.fbx` como rig propio (no R15). En la vista previa deben verse los 34 huesos y la textura.
2. Renombra el modelo a `Lumi`, comprueba `PrimaryPart`, añade el atributo `Rig = "Lumi_v7"` (texto) y muévelo a `ReplicatedStorage → PetAssets`.
3. Importa cada FBX de animación en el Animation Editor sobre `Lumi`. Activa el bucle en `Idle`, `Walk`, `Run`, `Work` y `Sleep_Loop`, y desactívalo en `Happy` y `Sleep_Enter`.
4. Publica cada animación con la cuenta o el grupo dueño de la experiencia.
5. Antes de guardar `assets/pets/Lumi.rbxmx`, borra la carpeta `AnimSaves` si el editor la creó.
6. Los 7 ids van en `PetAssets.AnimationSets.Lumi_v7.ids` (ya registrados).

### Ids publicados (Lumi_v7)

| Estado | AnimationId | Bucle | Prioridad |
|---|---|---|---|
| `Idle` | `rbxassetid://123787685829164` | sí | Idle |
| `Walk` | `rbxassetid://98626202379591` | sí | Movement |
| `Run` | `rbxassetid://139144120637137` | sí | Movement |
| `Happy` | `rbxassetid://98260166738628` | no | Action |
| `Sleep_Enter` | `rbxassetid://124146121312676` | no | Action |
| `Sleep_Loop` | `rbxassetid://87678883964103` | sí | Action |
| `Work` | `rbxassetid://138174795961249` | sí | Action |

- El código fuerza el bucle y la prioridad al cargar cada pista, así que no depende de cómo se publicó cada animación.
- Las animaciones pertenecen a la cuenta o grupo que las publicó, no al lugar. Funcionan en Portal Pets solo si la experiencia tiene el **mismo dueño**. Si Portal Pets es de un grupo y se publicaron desde una cuenta personal, hay que volver a publicarlas desde el grupo y cambiar los ids.
- **Rarezas:** común, raro, épico, legendario y mítico usan hoy la plantilla `Lumi` con estos 7 ids. Una futura `Lumi_<rareza>` con el mismo esqueleto de 34 huesos los reutiliza sin tocar código si lleva el atributo `Rig = "Lumi_v7"`. Si tiene otro esqueleto (por ejemplo, un mítico distinto), dale otro valor de `Rig` y su propio conjunto en `PetAssets.AnimationSets` + `variants.<rareza>.animationSet`.
- **Sin modelo:** si no existe la plantilla `Lumi`, los ids no se usan, porque el modelo procedural no tiene rig.

### Llevar el modelo del proyecto de prueba a Portal Pets

1. En el proyecto de prueba, revisa `Lumi`:
   - nombre exacto `Lumi`;
   - `PrimaryPart` asignado;
   - atributo `Rig = "Lumi_v7"`;
   - sin scripts;
   - sin la carpeta `AnimSaves`;
   - sin carpeta `Animations` (los ids ya están en el código; si la dejas, sus `Animation` tienen prioridad).
2. Clic derecho en `Lumi` → **Save to File…** → tipo **.rbxmx** → `assets/pets/Lumi.rbxmx` dentro del repositorio.
3. Abre Portal Pets en Studio y conecta Rojo (`rojo serve` + plugin). Rojo crea `ReplicatedStorage → PetAssets → Lumi` a partir del archivo.
   - Sin Rojo: arrastra el mismo archivo a `ReplicatedStorage → PetAssets`, o regenera el lugar con `python tools/build_rbxlx.py`, que incrusta los `.rbxmx`.
4. La malla y la textura viven en Roblox como assets. Si se subieron desde la cuenta dueña de la experiencia, el `.rbxmx` las referencia y cargan igual.

### Validar las 7 animaciones dentro del juego

Usa **Play** (o **Test → Clients and Servers** con 2 jugadores para la réplica) y revisa la ventana **Output**. No debe aparecer ningún aviso `[PetAssets]`, `[PetModels]` ni `[PetAnimator]`. Un `Failed to load animation` indica un problema de dueño o de id.

| Animación | Cómo verla |
|---|---|
| `Idle` / `Walk` | Lumi salvajes de la Zona 1: deambulan y se paran |
| `Run` | Equipa un Lumi como compañero y corre: a partir de 7 studs/s pasa a `Run` |
| `Work` | Asigna un Lumi a una estación de tu parcela. Con 2 jugadores, el otro también lo ve trabajar |
| `Happy` | Panel **Dev** → "Animacion: Happy", con un Lumi equipado y tú quieto. Al terminar vuelve a `Idle` |
| `Sleep_Enter` → `Sleep_Loop` | Panel **Dev** → "Animacion: Sleep": se acuesta y enlaza sin salto con el bucle |
| Despertar | Panel **Dev** → "Animacion: despertar", o muévete: vuelve a `Idle` / `Walk` |

Revisa también la orientación (que la cara mire hacia donde camina; si no, ajusta `yaw`), los pies sobre el suelo, la textura y que la captura con **F** siga funcionando. Mientras se le succiona, Lumi usa `Idle` porque no tiene `CaptureReaction`. La sección 9 tiene la lista completa (rarezas, fusiones, jefe, rendimiento).

## 11. `assets/pets/Lumi.rbxm`: cómo entra en el proyecto

### Estructura comprobada (`rojo build`, sin abrir Studio)

```
Lumi                          Model · atributos Rig = "Lumi_v7", RBX_ReimportId · PrimaryPart = Lumi_Comun_Body
├─ Lumi_Comun_Body            MeshPart 1,18 × 1,67 × 1,58 · MeshContent rbxassetid://85702700458518
│  ├─ SurfaceAppearance       ColorMap rbxassetid://116789412849410
│  └─ Bone Root → Hips → …    34 huesos, misma jerarquía que el FBX
├─ AnimationController
│  └─ Animator
└─ InitialPoses               Folder con 108 CFrameValue (los crea el importador para reimportar; no molestan)
```

- No tiene scripts ni carpeta `Animations`. Las 7 animaciones salen de `PetAssets.AnimationSets.Lumi_v7`.
- `PetModels` lo acepta (1 parte y 34 huesos, dentro de los límites), ancla `Lumi_Comun_Body` y lo escala de 1,67 a 2 studs en el Lumi común. `PetAnimator` reutiliza su `AnimationController`. La prueba `tools/sim/petassets.lua` (sección 5b) reproduce esta estructura.

### Construcción

| Vía | Resultado |
|---|---|
| `rojo build default.project.json -o PortalPets.rbxlx` | **Verificado.** `ReplicatedStorage.PetAssets.Lumi` sale completo, con malla, textura, 34 huesos, `AnimationController`, atributos y `PrimaryPart`. No hizo falta cambiar `default.project.json`: Rojo convierte cada `.rbxm` de `assets/pets` en una instancia con el nombre del archivo. |
| `python tools/build_rbxlx.py` | **Verificado.** Convierte el `.rbxm` con Rojo, en una carpeta temporal y sin tocar el original, y lo incrusta. Si Rojo no está instalado, avisa y genera el lugar sin el modelo (Lumi procedural). |
| `rojo serve` (sincronización en vivo) | **No verificado.** Un plugin de Studio quizá no pueda escribir la malla ni la textura (`MeshContent` / `ColorMapContent`) de un MeshPart; depende de la versión de Rojo y de Studio. Ver "Flujo recomendado". |

### Flujo recomendado en Studio

1. `rojo build default.project.json -o PortalPets.rbxlx` y abre `PortalPets.rbxlx` en Studio. Así Lumi entra desde el archivo con todas sus propiedades.
2. Para editar código en vivo, `rojo serve` y conecta el plugin a ese mismo lugar.
3. Comprueba en `ReplicatedStorage → PetAssets → Lumi` que la malla y la textura se ven.
4. **Si tras conectar Rojo, Lumi aparece sin malla o sin textura,** no lo arregles a mano en el árbol de Rojo: avisa. La solución es un `serve.project.json` sin `assets/pets`, para que el servidor en vivo no toque a Lumi, que seguiría viniendo de `rojo build`. Como `PetAssets` tiene `$ignoreUnknownInstances`, nada se borra.
5. Para incorporarlo a mano en un lugar abierto sin Rojo: **Model → Model → Insert from File…** (o arrastra el archivo) con `assets/pets/Lumi.rbxm` y colócalo en `ReplicatedStorage → PetAssets`. El archivo del repositorio sigue siendo la fuente; si cambias el modelo en Studio, vuelve a guardarlo en esa misma ruta.
