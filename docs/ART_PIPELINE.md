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

**Shiny:** para un Lumi Shiny se busca primero `Lumi_<rareza>_shiny` y luego `Lumi_shiny`. Si ninguna existe, se usa el modelo normal con las partículas Shiny. Una variante Shiny solo cambia la apariencia (paleta o texturas); la estructura del rig y los nombres de animación son los mismos.

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

## 12. Apoyo en el suelo (PETs importados)

### Diagnóstico (Lumi Común)

**Las animaciones no causan el problema.** La cinemática directa sobre los FBX da:

| Animación | Pata más baja respecto a la base de reposo | Comentario |
|---|---|---|
| Idle / Walk | 0,0 % del alto | Las patas quedan justo en la base |
| Run | de +1 % a +5 % | Despega en la zancada (intencional) |
| Happy | hasta +12 % | Salta (intencional) |
| Sleep_Enter / Sleep_Loop | de 0 % a +3 %; `Hips` −11 % | Se tumba |
| Work | de +1 % a +2 % | — |

La base de la malla en reposo (`MeshPart.Size`) son las suelas, así que es una referencia estable.

**El error estaba en la colocación, heredada de los PETs procedurales (bolas), que suponía el suelo en `y = 0`:**
- Salvajes: el pivote iba a `y = radio + 0.2` fijo. Lumi levitaba 0,2 studs en llano y se hundía en las colinas (de 4 a 7 studs); al deambular por una pendiente no cambiaba de altura.
- Compañeros: el centro iba a `hrp.Y − 1.5` para cualquier tamaño. Un Lumi común levitaba 0,65 studs, la altura cambiaba con la rareza y el compañero subía con cada salto del jugador.
- Trabajadores: el centro iba a 1,6 studs sobre la parcela (2,0 en el huerto). Un Lumi de 1,4 studs levitaba entre 0,9 y 1,3.

### Solución (`src/shared/PetGrounding.luau`)

- `PetModels` guarda en cada modelo importado el atributo `GroundOffset`, la distancia del pivote a la base de la malla en reposo. La animación no lo modifica.
- El suelo se busca con un raycast hacia abajo. Respeta `CanCollide` (la decoración sin colisión no cuenta), ignora el agua, los personajes y los PETs, que no tienen colisión.
- Pivote = punto de apoyo + arriba × `GroundOffset`. **Nunca se fuerza la malla animada contra el suelo:** los saltos de Run y Happy y la postura de Sleep salen del rig tal cual.
- **Pendientes:** el cuerpo se inclina hacia la normal del suelo, con un máximo de 20°.
- **Suavizado:** la altura y la inclinación se suavizan, así que un escalón de 1,5 studs se sube en unos 0,2 s, sin teletransportes ni vibraciones. Los raycasts se lanzan solo al moverse 0,3 studs o cada 0,25 s.
- **Rayos:** empiezan 3 studs sobre el último suelo, para que los techos no cuenten. Si el rayo nace dentro del terreno (desnivel brusco), se repite desde más arriba.

**Por sistema:**
- Salvajes: suelo real bajo cada PET.
- Compañeros: suelo bajo el compañero, no la altura del jugador. Al saltar el jugador, el compañero se queda en el suelo.
- Trabajadores: se apoyan una vez cuando la parcela está en `workspace`, sobre el terreno o la base de la estación.
- El jefe de incursión flota a propósito y no cambia.
- Los PETs procedurales conservan exactamente su colocación anterior.

**Rarezas:** cada rareza calcula su propio `GroundOffset` con su tamaño. Si una variante futura tiene la parte más baja de la malla en otro sitio (una cola que cuelga, por ejemplo), se ajusta con `footInset` (fracción del alto) en `PetAssets.Species.<especie>` o en `variants.<rareza>`. Lumi usa 0.

Los ajustes están en `PetGrounding.Config`: `maxTilt`, `heightRate`, `tiltRate`, `probeAbove`, `probeBelow`, `firstProbeAbove`, `reprobeDistance` y `reprobeTime`.

### Comprobación visual en Studio (pendiente)

1. **Zona 1, Lumi quieto:** con cámara a ras de suelo, las patas tocan el césped, sin hueco ni hundimiento.
2. **Lumi deambulando:** sube y baja las colinas apoyado e inclinado con la ladera.
3. **Compañero:** al caminar, correr y saltar, se queda en el suelo. Al correr, el rebote propio de Run se ve.
4. **Panel Dev, Happy:** salta y aterriza en el mismo sitio.
5. **Panel Dev, Sleep:** se tumba con el cuerpo apoyado.
6. **Trabajador en el extractor:** patas en el suelo (o sobre la base de piedra si queda encima).
7. **Superficies inclinadas:** rampas o laderas de las zonas; inclinación hasta 20°.
8. **Rarezas:** compañero raro, épico y legendario apoyados igual.

Para medir el apoyo, en la barra de comandos con un PET seleccionado:

```lua
local m = game.Selection:Get()[1]
print(m:GetPivot().Y - m:GetAttribute("GroundOffset"))
```

Compara el resultado con la altura del suelo.

## 13. Brillo y efectos de los PETs importados

### Diagnóstico: por qué el Lumi equipado se veía blanco

Los Lumi salvajes y los equipados se construyen igual (`PetModels.Build`) y tienen los mismos efectos de rareza. La diferencia viene de fuera del modelo:
- Al equipar a Lumi, su poder **"Aporta luz"** (`flags.light`) activa el atributo `Flags = light`. Entonces `Followers` crea la luz `PP_Light` en el `HumanoidRootPart`: una `PointLight` de brillo 1,6 y alcance 22, casi blanca. El compañero camina a 3–4 studs de esa fuente y su pelaje claro con textura real (`SurfaceAppearance`) se quema a blanco. **Era la causa principal.**
- La luz propia de Lumi (brillo 1, alcance de 12 a 20, color casi blanco) se diseñó para las bolas procedurales. Con modelos texturizados, cada Lumi blanquea a los Lumi que tiene cerca, y se nota en grupos.
- Raro y superior usaban `Sparkles`, un objeto antiguo de tamaño, ritmo y emisión fijos, muy intenso. Épico y superior sumaban otra luz de brillo 1,5.
- **Bloom global** (`PP_Bloom`: Intensity 0,15, Threshold 2,2): solo actúa sobre superficies sobreexpuestas, así que amplificaba el halo pero no lo causaba. **No se modifica**, ni tampoco la iluminación global.

### Cambios

| Elemento | Antes | Ahora |
|---|---|---|
| Luz del poder "Aporta luz" (jugador) | En el `HumanoidRootPart`, brillo 1,6, alcance 22 | En `PP_LightAnchor`, 4,5 studs sobre el centro (encima de la cabeza), brillo 1,1, mismo alcance 22, color cálido menos blanco. Sigue iluminando el entorno |
| Luz propia de Lumi importado | Brillo 1, alcance 12–20 | Brillo 0,35, alcance 6–10 |
| Luz de rareza (épico+) importado | Brillo 1,5, alcance 14–18 | Brillo 0,4, alcance 7–9 |
| Destellos (raro+) importado | `Sparkles` | `ParticleEmitter` `PP_Sparkles`: tamaño 9 % del alto, `LightEmission` 0,25, `LightInfluence` 0,5, de 3 (raro) a 7,5 (mítico) partículas/s, en una esfera alrededor del cuerpo |
| Contorno (legendario+) importado | `OutlineTransparency` 0,1 | 0,4, sin relleno |

- Los valores de los modelos importados están en `PetAssets.Effects`, y los de la luz del jugador en `Followers.LightConfig`.
- **Los PETs procedurales conservan sus efectos de siempre.** El orden de rareza se mantiene: las rarezas altas tienen más destellos, luz de color y contorno.
- **Móvil:** como mucho unas 10 partículas vivas por PET (7,5/s × 1,4 s) y luces de menos alcance, así que el coste baja respecto a antes.

### Comprobación en Studio (pendiente)

No hay ciclo de día y noche; cada zona tiene su hora y su tono (`WorldFx.LOOKS`).
- Zonas de día: Zona 1 y parcela.
- Zonas oscuras: Zona 3 (18:36), Zona 5 y las Minas, donde importa el poder de luz.

1. Lumi común salvaje junto a un Lumi común equipado: deben verse iguales, con los ojos, los patrones azules y el pelaje blanco sin quemar.
2. Lumi raro equipado: destellos azules pequeños y discretos que no tapan la cara.
3. Varios Lumi juntos (Zona 1): sin halo blanco entre ellos.
4. Épico, legendario y mítico (comando Dev "pets"): más llamativos, pero la textura siempre visible.
5. Zona 3 o Minas con Lumi equipado: el entorno del jugador sigue iluminado.

## 14. Lumi Raro, Épico y Legendario (plantillas por rareza)

### Estado

| Rareza | Plantilla | Archivo | Estado |
|---|---|---|---|
| Común | `Lumi` | `assets/pets/Lumi.rbxm` | Importado; **validado visualmente por el usuario en Roblox Studio** (2026-11-06) |
| Raro | `Lumi_rare` | `assets/pets/Lumi_rare.rbxm` | Importado; **validado visualmente por el usuario en Roblox Studio** (2026-11-06) |
| Épico | `Lumi_epic` | `assets/pets/Lumi_epic.rbxm` | Importado; **validado visualmente por el usuario en Roblox Studio** (2026-11-06) |
| Legendario | `Lumi_legendary` | `assets/pets/Lumi_legendary.rbxm` | Importado; **validado visualmente por el usuario en Roblox Studio** (2026-11-06) |
| Mítico | — (usa `Lumi`) | — | Sin modelo propio todavía |

Las cuatro variantes de Lumi fueron probadas visualmente por el usuario en Roblox Studio y funcionan correctamente. Además pasan `tools/check_pet_assets.py --require Lumi,Lumi_rare,Lumi_epic,Lumi_legendary` y las 10 suites de `tools/sim`.

Datos de los archivos guardados (leídos por el validador):

| Plantilla | PrimaryPart | Malla | Textura (ColorMap) |
|---|---|---|---|
| `Lumi` | `Lumi_Comun_Body` | `rbxassetid://85702700458518` | `rbxassetid://116789412849410` |
| `Lumi_rare` | `Lumi_Raro_Body` | `rbxassetid://99859815912404` | `rbxassetid://116220629047041` |
| `Lumi_epic` | `Lumi_Epico_Body` | `rbxassetid://106946233331711` | `rbxassetid://75192529583080` |
| `Lumi_legendary` | `Lumi_Legendario_Body` | `rbxassetid://130109281460178` | `rbxassetid://99272336846687` |

Todas tienen `Rig = Lumi_v7`, 34 huesos y comparten los 7 ids de animación de `PetAssets.AnimationSets.Lumi_v7`.

`PetAssets.Find` busca `Lumi_<rareza>` y, si no existe, usa `Lumi`. Las rarezas con plantilla prevista (`PetAssets.Species.lumi.rarityModels`) avisan una vez en Output si falta la suya: `Falta (o no es valida) la plantilla Lumi_rare...`. La rareza, el inventario y los datos guardados no dependen del modelo.

### Análisis de los archivos (`Downloads/Lumi_Variantes` y `Lumi_Variantes_Optimizado_1024`)

- **Rig:** 34 huesos con los mismos nombres y jerarquía que Lumi Común, 30 fps, sin root motion. La base de la malla en reposo son las suelas (alto 1,646). En Idle y Walk las patas quedan a ±0,7 % del alto de esa base.
- **Malla:** propia de las variantes, idéntica en las tres (7.901 vértices, 15.801 triángulos).
- **Reposo de los huesos:** difiere del rig Común hasta 13,6° (`Spine`, `Chest`, `Shoulder.R`) y 2,5 cm.
- **Animaciones: no hace falta publicar nada nuevo.** Roblox aplica cada pose relativa al reposo del hueso. Al simular los 7 ids de Lumi Común sobre el reposo de cada variante, el resultado coincide con la animación validada de esa variante con un error máximo de **0,37° y 1 mm** en todos los fotogramas. Cálculo hecho con los FBX y confirmado después en la prueba visual del usuario en Studio.
- **Texturas originales:** `Lumi_*_Texture.png` son **JPEG de 4096 px con extensión .png**. No conviene usarlas.
- **Versión optimizada:** `*_Model_1024.fbx` (72 % más ligero) tiene el mismo rig, pesos y UV, verificado; su textura es un PNG real de 1024 px. Es la resolución que Roblox mostraría de todos modos.
- **Mapas extra:** metal ≈ 0 en toda la textura, normales prácticamente planas (desviación de unos 2/255) y alfa opaco. Basta el **mapa de color**, igual que en la Común.

### Importar cada variante en Studio

Repite estos pasos para Raro → `Lumi_rare`, Épico → `Lumi_epic` y Legendario → `Lumi_legendary`.

1. **Import 3D** de `Lumi_Variantes_Optimizado_1024/Lumi_<Var>_Roblox_Export_1024/Lumi_<Var>_Model_1024.fbx`:
   - rig propio, igual que con la Común;
   - **no importes animaciones.**
   En la vista previa deben verse los 34 huesos y la textura.
2. Si la textura no aparece, sube `Lumi_<Var>_Texture_1024.png` y asígnala como `ColorMap` de la `SurfaceAppearance` de `Lumi_<Var>_Body`.
3. Prepara el modelo:
   - renómbralo exactamente como su plantilla (`Lumi_rare`, `Lumi_epic` o `Lumi_legendary`);
   - asigna `PrimaryPart` = la MeshPart `Lumi_<Var>_Body`;
   - añade el atributo de texto `Rig = Lumi_v7`;
   - comprueba que haya un `AnimationController` con un `Animator` dentro (si falta, créalo);
   - borra `AnimSaves` o `Animations` si aparecen.
4. Botón derecho → **Save to File…** → `assets/pets/Lumi_<rareza>.rbxm`. No sobrescribas `Lumi.rbxm`.
5. Valida los archivos:
   ```
   python tools/check_pet_assets.py --require Lumi,Lumi_rare,Lumi_epic,Lumi_legendary
   ```
   Comprueba la PrimaryPart, `Rig`, los 34 huesos y su jerarquía, la textura propia (distinta en cada rareza), el `AnimationController`/`Animator`, que no haya scripts y que no haya carpeta `Animations`.
6. La malla y la textura se suben al importar. Deben pertenecer al mismo dueño que la experiencia (cuenta o grupo); si no, no cargarán en el juego publicado.

### Comprobación en Studio (validada por el usuario; repetir si cambian los modelos)

1. `rojo build default.project.json -o PortalPets.rbxlx`, abrir y **Play**. Output no debe mostrar `Falta (o no es valida) la plantilla` ni `Failed to load animation`.
2. Panel Dev → "pets" (+3 de cada variante). Equipa un Lumi raro, uno épico y uno legendario: cada uno con su textura, animado (Idle, Walk, Run), apoyado y sin blanquearse.
3. Panel Dev → Happy / Sleep / despertar con los tres equipados.
4. Asigna un Lumi épico al extractor: animación Work, patas en el suelo.
5. Salir y volver a entrar: el equipo y los trabajadores conservan su rareza y su modelo.
6. Varios Lumi visibles (Zona 1 y compañeros): fluidez en el emulador de móvil (MicroProfiler o Stats).

## 15. Rocón Común, Raro, Épico y Legendario

### Estado

| Pieza | Estado |
|---|---|
| Especie `rocon` en el juego | **Ya existía** en `PetCatalog`, sin cambios: n.º 2, zona 2 (Valle de los Engranajes, con Chispa), sin mítico, cebo `root`, extractor de piedra (0,25/s), compañero "Mayor fuerza en minerales duros". |
| Animaciones | `Referenciado en código con respaldo`: los 7 ids publicados están en `PetAssets.AnimationSets.Rocon_v3`, compartidos por las 4 rarezas. |
| Modelos | `Guardado en assets/pets`: `Rocon.rbxm`, `Rocon_rare.rbxm`, `Rocon_epic.rbxm` y `Rocon_legendary.rbxm`, todos con `Rig = Rocon_v3`. Entran en `rojo build` y en `tools/build_rbxlx.py`. |
| Validación estructural | **Aprobada** (2026-11-07). `tools/check_pet_assets.py` pasa con los 4 Rocón y los 4 Lumi, y pasan las 12 suites de `tools/sim`. |
| Dentro de Portal Pets | **Falta la prueba visual en Roblox Studio** (abajo, "Comprobación en Studio"). Hasta que el usuario la confirme, no se da por verificado. |

### Ids publicados (Rocon_v3)

| Estado | AnimationId | Bucle | Prioridad |
|---|---|---|---|
| `Idle` | `rbxassetid://99191665025042` | sí | Idle |
| `Walk` | `rbxassetid://79078597091924` | sí | Movement |
| `Run` | `rbxassetid://119802077605294` | sí | Movement |
| `Happy` | `rbxassetid://139430381617586` | no | Action |
| `Sleep_Enter` | `rbxassetid://80979103631192` | no | Action |
| `Sleep_Loop` | `rbxassetid://124646034769643` | sí | Action |
| `Work` | `rbxassetid://100611091362223` | sí | Action |

El código fuerza el bucle y la prioridad al cargar cada pista. Las animaciones solo cargan en el juego si las publicó el mismo dueño (cuenta o grupo) que la experiencia.

### Modelos guardados (leídos por `tools/check_pet_assets.py`)

| Plantilla | PrimaryPart | Huesos | `Rig` | Malla | Textura (`MeshPart.TextureContent`) | Tamaño en reposo |
|---|---|---|---|---|---|---|
| `Rocon` | `Rocon_Comun_Body` | 29 | `Rocon_v3` | `rbxassetid://116612514049739` | `rbxassetid://74730886442037` | 1,898 × 1,697 × 1,076 |
| `Rocon_rare` | `Rocon_Raro_Body` | 29 | `Rocon_v3` | `rbxassetid://102027818243174` | `rbxassetid://92664743474619` | 1,898 × 1,661 × 1,075 |
| `Rocon_epic` | `Rocon_Epico_Body` | 29 | `Rocon_v3` | `rbxassetid://102121702855412` | `rbxassetid://97813604923897` | 2,000 × 1,788 × 1,134 |
| `Rocon_legendary` | `Rocon_Legendario_Body` | 29 | `Rocon_v3` | `rbxassetid://86832758145413` | `rbxassetid://111379690298983` | 2,000 × 1,788 × 1,134 |

- Los cuatro tienen:
  - la jerarquía de 29 huesos idéntica a la del FBX;
  - un `AnimationController` con `Animator`;
  - malla y textura propias, distintas en cada rareza;
  - ni scripts ni carpeta `Animations`;
  - la carpeta `InitialPoses` del importador, que no molesta.
- **Textura:** a diferencia de Lumi, va en la propia MeshPart (`TextureContent`), no en una `SurfaceAppearance`. El juego no lee ni cambia texturas, así que funciona igual. Por eso el validador acepta ahora las dos formas.
- **Atributo `Rig`:** los cuatro tienen `Rig = Rocon_v3`. Raro, Épico y Legendario lo recibieron en Studio después de la primera validación y se guardaron de nuevo.

### Datos de los FBX

- **Rig `Rocon_v3`:** 29 huesos, iguales en las 4 rarezas:
  ```
  Root → Pelvis → Spine → Chest → Head
  Chest → Shoulder_L/R → UpperArm → Forearm → Hand → Fingers_01 → Fingers_02
                                                    Hand → Thumb_01 → Thumb_02
  Pelvis → Thigh_L/R → Shin → Foot → Toe
  ```
  - `Root` no deforma; 30 fps; sin root motion.
  - Mismos ajustes de exportación que Lumi (Y arriba, frente +Z del FBX = −Z de Roblox), así que `yaw = 0`.
- **Reposo:** la misma orientación en las 4 rarezas (≤ 0,0001°). Solo cambia la posición de los huesos (Raro ×0,979; Épico y Legendario ×1,054). Por eso **los 7 ids se publican una sola vez** y sirven para las cuatro, como con Lumi.
- **Mallas:**

  | Rareza | Triángulos | Reposo en Blender (ancho con brazos × alto × fondo, m) |
  |---|---|---|
  | Común | 5.191 | 1,898 × 1,697 × 1,076 |
  | Raro | 5.221 | 1,898 × 1,661 × 1,075 |
  | Épico / Legendario | 5.191 | 2,000 × 1,788 × 1,134 |

  - Máximo 4 influencias por vértice.
  - La base de la malla en reposo son las suelas (`footInset = 0`).
- **Texturas:**
  - El color base de 1024 va incrustado en cada FBX.
  - Hay una alternativa de 2048 en cada carpeta, sin alfa.
  - Sin mapas de normales ni de rugosidad, igual que Lumi.
- **Animaciones:**

  | Animación | Duración | Bucle |
  |---|---|---|
  | Idle | 3,0 s | sí |
  | Walk | 1,2 s | sí |
  | Run | 0,8 s | sí |
  | Happy | 1,5 s | no; vuelve al reposo |
  | Sleep_Enter | 1,5 s | no; acaba en la pose de `Sleep_Loop` |
  | Sleep_Loop | 4,0 s | sí |
  | Work | 1,5 s | sí |

  En los bucles, el primer fotograma y el último son iguales.

### Qué hace el código

- `PetAssets.Find("rocon", rareza)` busca `Rocon_<rareza>` y, si no existe, `Rocon`.
  - Si falta una plantilla prevista (`rarityModels`), avisa una vez en Output y usa `Rocon` con los efectos de su rareza.
  - Sin ninguna plantilla, Rocón sigue siendo procedural, sin avisos.
  - Rocón no tiene mítico: `PetCatalog.RaritiesFor("rocon")` nunca lo devuelve.
- **Shiny:**
  - se buscan primero `Rocon_<rareza>_shiny` y `Rocon_shiny`, que hoy no existen;
  - si no hay, se usa el modelo de su rareza con las partículas Shiny;
  - Shiny no es una rareza y no sustituye a los cuatro modelos.
- **Tamaño:** igual que el procedural de su rareza (alto 2 × tamaño de rareza: 2; 2,2; 2,4 y 2,7 studs) y apoyado en el suelo con `PetGrounding`.
- **Animaciones:**
  - las mismas capas y respaldos que Lumi (`PetAnimator`);
  - pistas cargadas una vez por modelo y 7 objetos `Animation` compartidos por las 4 rarezas;
  - pedir el mismo estado no reinicia la pista.
- **Dónde se ve cada animación:**

  | Estado | Cuándo |
  |---|---|
  | Idle | quieto |
  | Walk / Run | según la velocidad |
  | Work | trabajando en el extractor de piedra (el servidor lo replica) |
  | Happy, Sleep_Enter → Sleep_Loop | panel **Dev** (preparadas; todavía sin mecánica de juego, igual que en Lumi) |

### Velocidad de Walk y Run (deslizamiento de pies)

- **Ajuste nuevo y opcional por especie:** `PetAssets.Species.rocon.locomotion = { walk = 0.269, run = 0.774 }`. Es la velocidad nativa de la cinta en **alturas del PET por segundo**, medida en los FBX.
- `PetAnimator` la convierte a studs/s con el alto real del modelo y reproduce Walk/Run a `velocidad real / velocidad nativa`, con los límites de siempre (Walk 0,5–1,8, Run 0,6–1,8).
- **Lumi no tiene `locomotion`, así que conserva exactamente sus referencias globales** (4 y 12 studs/s).

| Caso (Rocón Común, 2 studs) | Desplazamiento | Nativa | Velocidad pedida | Aplicada | Pies |
|---|---|---|---|---|---|
| Hasta 0,97 studs/s | ≤ 0,97 | 0,54 (Walk) | ≤ 1,8 | igual | **sin deslizamiento** |
| Salvaje deambulando (`Encounters`, 4 studs/s) | 4,0 | 0,54 (Walk) | 7,4 | 1,8 | los pies cubren 0,97 studs/s y **el resto se desliza** |
| Compañero de un jugador que camina (16 studs/s) | ~16 | 1,55 (Run) | 10,3 | 1,8 | igual |

Rocón es un gólem pesado: su paso nativo es lento (0,27 alturas/s), mientras que el juego mueve todos los PETs salvajes a 4 studs/s (2 alturas/s) y los compañeros a la velocidad del jugador. **No se cambió ninguna velocidad de movimiento**, porque es diseño de juego. Hay tres opciones, y la decisión es tuya:
- (a) aceptar el deslizamiento a velocidades altas, como hoy;
- (b) subir el límite de velocidad solo para Rocón (`maxRate`), aunque a ×4–×7 el gólem se vería frenético;
- (c) que los Rocón salvajes deambulen más despacio (p. ej. 1 studs/s, `Encounters`).

**Decisión actual:** se mantiene esta configuración; el ajuste queda pendiente de la prueba visual en Studio.

### Pruebas automáticas

`lua5.4 tools/sim/rocon.lua`: 144 comprobaciones con plantillas **simuladas** y los 7 ids **reales** de `Rocon_v3`. Comprueba que los ids son exactamente los publicados y que los de Lumi no cambian. Las 11 suites anteriores siguen pasando con las mismas comprobaciones.

### Comprobación en Studio (pendiente de la prueba visual del usuario)

1. `rojo build default.project.json -o PortalPets.rbxlx`, abre el lugar y pulsa **Play**.
   - Output no debe mostrar `Falta (o no es valida) la plantilla Rocon_…`, `[PetAnimator]` ni `Failed to load animation`.
   - En **ReplicatedStorage → PetAssets** deben verse `Rocon`, `Rocon_rare`, `Rocon_epic` y `Rocon_legendary` con su malla y su textura. Si alguno sale sin malla o textura tras conectar Rojo, ver la sección 11 ("Flujo recomendado").
2. **Zona 2** (Valle de los Engranajes): los Rocón salvajes usan su modelo según la rareza.
   - Común: piedra marrón. Raro: gris con cristales turquesa. Épico: amatista. Legendario: magma.
   - Están apoyados, miran hacia donde caminan (si no, cambia `yaw` en `PetAssets.Species.rocon`) y usan Idle y Walk.
3. Captura un Rocón con **F**. Llega al tanque con su rareza y aparece en el inventario. Captura varios: cada captura suma uno.
4. **Equipo:**
   - equipa y desequipa un Rocón;
   - cambia a Lumi y de vuelta a Rocón;
   - al seguirte camina o corre, y salta contigo sin despegarse del suelo.
5. Panel **Dev** → "pets" (+3 de cada variante): equipa un Rocón raro, uno épico y uno legendario, y prueba Happy, Sleep y despertar.
6. **Trabajo:**
   - asigna un Rocón al **Extractor de piedra**: reproduce Work con los pies en el suelo;
   - con 2 clientes, el otro jugador también lo ve;
   - recoge la piedra producida.
7. Sal y vuelve a entrar: el equipo, los trabajadores y las rarezas de Rocón y de Lumi siguen igual.
8. **Test → Clients and Servers** con 2 jugadores:
   - cada uno ve sus propios salvajes;
   - los compañeros del otro se ven animados;
   - las capturas de uno no afectan al otro.
9. **Shiny:** panel Dev con forzado Shiny en la zona 2. Un Rocón Shiny mantiene el modelo de su rareza y añade partículas.
10. **Lumi:** repite una captura, un equipo y un trabajo con Lumi para confirmar que nada cambió.
11. **Rendimiento:** zona 2 con varios Rocón y compañeros en el emulador de móvil (MicroProfiler o Stats).
