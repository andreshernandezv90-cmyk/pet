-- PetAssets: registro de modelos importados (Blender -> Roblox Studio) por especie.
--
-- Los modelos viven como plantillas en ReplicatedStorage.PetAssets (carpeta
-- sincronizada desde assets/pets/ por Rojo, ver docs/ART_PIPELINE.md). Si la
-- plantilla de una especie no existe o no es valida, PetModels usa el modelo
-- procedural de siempre: la especie, la rareza, el inventario, las estadisticas
-- y la persistencia no dependen nunca del aspecto.
--
-- No se inventan identificadores: las animaciones se leen de objetos Animation
-- que vienen dentro de la plantilla (carpeta "Animations", con el AnimationId que
-- se publica en Studio) o de esta tabla, que hoy esta vacia a proposito.

local PetAssets = {}

-- Interruptor global (ademas, en Studio se puede poner el atributo
-- UseProcedural = true en ReplicatedStorage.PetAssets para comparar).
PetAssets.Enabled = true

-- Estados de animacion admitidos (nombres exactos de los objetos Animation)
PetAssets.States = { "Idle", "Walk", "Run", "Work", "Happy", "Sleep_Enter", "Sleep_Loop", "Jump", "CaptureReaction" }

-- Ajustes por estado:
--   kind: "base"   estado continuo (locomocion, trabajo, succion): solo uno a la vez
--         "action" reaccion de una sola vez (Happy): al terminar vuelve al estado base
--         "sleep"  secuencia de sueño (Sleep_Enter -> Sleep_Loop) hasta despertar
--   looped / priority: se fuerzan por codigo al cargar la pista
--   fallback: estado al que recurrir si falta la animacion (nil = no se reproduce)
--   fade: segundos de fundido al entrar en el estado
PetAssets.StateInfo = {
	Idle = { kind = "base", looped = true, priority = "Idle", fallback = nil, fade = 0.2 },
	Walk = { kind = "base", looped = true, priority = "Movement", fallback = "Idle", fade = 0.15 },
	Run = { kind = "base", looped = true, priority = "Movement", fallback = "Walk", fade = 0.15 },
	Work = { kind = "base", looped = true, priority = "Action", fallback = "Idle", fade = 0.2 },
	CaptureReaction = { kind = "base", looped = true, priority = "Action", fallback = "Idle", fade = 0.1 },
	Jump = { kind = "base", looped = false, priority = "Action", fallback = "Idle", fade = 0.1 },
	Happy = { kind = "action", looped = false, priority = "Action", fallback = nil, fade = 0.12 },
	Sleep_Enter = { kind = "sleep", looped = false, priority = "Action", fallback = nil, fade = 0.25 },
	Sleep_Loop = { kind = "sleep", looped = true, priority = "Action", fallback = nil, fade = 0.1 },
}

-- Umbrales de velocidad (studs/s) para elegir Idle / Walk / Run
PetAssets.Locomotion = { walk = 0.6, run = 7, fade = 0.15, referenceWalkSpeed = 4, referenceRunSpeed = 12 }

-- Conjuntos de animaciones por esqueleto. Todas las variantes que compartan el
-- mismo rig (mismos nombres y jerarquia de huesos) reutilizan el mismo conjunto.
--   rig: identificador del esqueleto. Si la plantilla tiene el atributo "Rig" y no
--        coincide, el conjunto no se usa (evita animar un rig incompatible).
--   ids: AnimationId por estado. Deben ser ids reales publicados por la cuenta o el
--        grupo dueño de la experiencia. Vacio hasta tenerlos: no se inventan.
PetAssets.AnimationSets = {
	-- Lumi Comun: Lumi_Comun_rig_v7.blend, 34 huesos (Root, Hips, Spine, Chest, Neck,
	-- Head, Jaw, Ear_01-03.L/R, Shoulder/UpperArm/Forearm/FrontPaw.L/R, Tail_01-05,
	-- Thigh/Shin/BackFoot/BackPaw.L/R), 30 fps, sin root motion.
	-- Ids publicados en Roblox por el dueño del proyecto (no modificar sin republicar).
	Lumi_v7 = {
		rig = "Lumi_v7",
		ids = {
			Idle = "rbxassetid://123787685829164",
			Walk = "rbxassetid://98626202379591",
			Run = "rbxassetid://139144120637137",
			Happy = "rbxassetid://98260166738628",
			Sleep_Enter = "rbxassetid://124146121312676",
			Sleep_Loop = "rbxassetid://87678883964103",
			Work = "rbxassetid://138174795961249",
		},
	},
	-- Rocon (Comun, Raro, Epico y Legendario): Rocon_<Rareza>_Anim_v3.blend, 29 huesos
	-- (Root, Pelvis, Spine, Chest, Head, Shoulder/UpperArm/Forearm/Hand/Fingers_01-02/
	-- Thumb_01-02_L/R, Thigh/Shin/Foot/Toe_L/R), 30 fps, sin root motion. Las 4 rarezas
	-- tienen la misma orientacion de reposo (<= 0,0001 grados), asi que comparten los 7 ids.
	-- FBX en Downloads/Rocon_Rig/Etapa4_Roblox_Export/Animaciones (docs/ART_PIPELINE.md, seccion 15).
	-- Ids publicados en Roblox por el dueño del proyecto (no modificar sin republicar).
	Rocon_v3 = {
		rig = "Rocon_v3",
		ids = {
			Idle = "rbxassetid://99191665025042",
			Walk = "rbxassetid://79078597091924",
			Run = "rbxassetid://119802077605294",
			Happy = "rbxassetid://139430381617586",
			Sleep_Enter = "rbxassetid://80979103631192",
			Sleep_Loop = "rbxassetid://124646034769643",
			Work = "rbxassetid://100611091362223",
		},
	},
	-- Chispa (Comun, Raro, Epico y Legendario): Chispa_Master.blend, rig compartido de 22 huesos
	-- (Root, Hips, Spine, Chest, Neck, Head, Antenna, Left/RightUpperArm/LowerArm/Hand, Tail1-3,
	-- Left/RightUpperLeg/LowerLeg/Foot), 30 fps, sin root motion. Exportado con el reposo de los
	-- huesos alineado (rotacion local nula) para que Studio no aplique dos veces esa rotacion.
	-- FBX en Downloads/Chispa/Export/Animations (docs/ART_PIPELINE.md, seccion 16).
	-- Ids publicados en Roblox por el dueño del proyecto (no modificar sin republicar).
	Chispa_v1 = {
		rig = "Chispa_v1",
		ids = {
			Idle = "rbxassetid://122236338807516",
			Walk = "rbxassetid://100453215475992",
			Run = "rbxassetid://107019646221510",
			Happy = "rbxassetid://120703378701836",
			Sleep_Enter = "rbxassetid://103551660461300",
			Sleep_Loop = "rbxassetid://72480467022919",
			Work = "rbxassetid://139469079471002",
		},
	},
	-- Talpa (Comun, Raro, Epico y Legendario): Talpa_Master.blend (v3), rig compartido de 25 huesos
	-- (Root, Hips, Spine, Chest, Neck, Head, Snout, Tail1-4, Left/RightUpperArm/LowerArm/Hand/Claws,
	-- Left/RightUpperLeg/LowerLeg/Foot), 30 fps, sin root motion, reposo alineado (rotacion local
	-- nula, como Chispa). FBX en Downloads/Talpa/Export/Animations (docs/ART_PIPELINE.md, seccion 17).
	-- Ids publicados en Roblox por el dueño del proyecto (no modificar sin republicar).
	Talpa_v1 = {
		rig = "Talpa_v1",
		ids = {
			Idle = "rbxassetid://136548107891720",
			Walk = "rbxassetid://81290030630381",
			Run = "rbxassetid://102908093464049",
			Happy = "rbxassetid://140408446222794",
			Sleep_Enter = "rbxassetid://81127893070487",
			Sleep_Loop = "rbxassetid://101325040811253",
			Work = "rbxassetid://79325542756265",
		},
	},
}

-- Limites de seguridad para plantillas (avisos, no bloqueos, salvo maxParts)
PetAssets.Limits = { maxParts = 40, maxBones = 64 }

-- Efectos de rareza para modelos importados (texturas reales: el pelaje claro se
-- sobreexpone con las luces pensadas para las bolas procedurales). Los procedurales
-- conservan sus efectos de siempre. Rangos en studs; "order" = 1 comun ... 5 mitico.
PetAssets.Effects = {
	-- luz propia de especies luminosas (Lumi): resplandor corto que no blanquea vecinos
	ownLight = { brightness = 0.35, range = 5, rangePerOrder = 1 },
	-- luz extra de epico+ (color de la rareza)
	rarityLight = { brightness = 0.4, range = 4, rangePerOrder = 1 },
	-- destellos de raro+: ParticleEmitter ajustable en lugar de Sparkles (fijo e intenso)
	sparkles = {
		texture = "rbxasset://textures/particles/sparkles_main.dds",
		ratePerOrder = 1.5, -- raro 3/s ... mitico 7.5/s
		size = 0.09, -- fraccion del alto del PET
		lightEmission = 0.25,
		lightInfluence = 0.5,
		transparency = 0.35,
		lifetime = { 0.8, 1.4 },
		speed = { 0.2, 0.6 },
	},
	-- contorno de legendario+
	outlineTransparency = 0.4,
}

-- Especies con modelo importado. Solo las especies listadas aqui buscan plantilla.
--   model: nombre de la plantilla en ReplicatedStorage.PetAssets. Antes se busca
--          "<model>_<rareza>" (variante opcional por rareza) y despues "<model>".
--   heightFactor: alto final = alto del PET procedural (2 * escala * tamaño de
--          rareza) * heightFactor. La plantilla se escala sola con Model:ScaleTo.
--   yaw: grados para corregir la orientacion si la cara no mira hacia -Z.
--   animationSet: conjunto de PetAssets.AnimationSets que usa la especie.
--   animations: AnimationId por estado que sustituyen a los del conjunto (opcional).
--   variants[rareza]: { animationSet = ..., animations = {...}, footInset = ... } para
--          una rareza con rig propio. Sin entrada, la rareza reutiliza lo de la especie.
--   footInset: fraccion del alto que se hunde el apoyo cuando la parte mas baja de la
--          malla en reposo no son las patas (0 si la base de la malla son las suelas,
--          como en Lumi: comprobado con el FBX). Negativo sube el apoyo cuando el rig
--          animado queda por debajo de la base de reposo (Rocon, medido en Studio). Ver PetGrounding.
--   locomotion: { walk = ..., run = ... } velocidad nativa de Walk y Run en alturas del
--          PET por segundo (opcional). Si existe, PetAnimator ajusta la velocidad de
--          reproduccion a velocidad real / (nativa * alto del modelo); si no, usa las
--          referencias globales de PetAssets.Locomotion (caso de Lumi).
-- Orden de busqueda por estado: carpeta "Animations" de la plantilla ->
-- variants[rareza].animations -> animations -> conjunto (de la variante o especie).
PetAssets.Species = {
	lumi = {
		model = "Lumi",
		heightFactor = 1.0,
		yaw = 0,
		footInset = 0,
		animationSet = "Lumi_v7",
		animations = {},
		-- Plantillas propias por rareza (assets/pets/Lumi_<rareza>.rbxm). Comparten el rig
		-- de 34 huesos (Rig = "Lumi_v7"), asi que reutilizan Lumi_v7 sin configurar nada.
		-- Si falta alguna, ese Lumi usa la plantilla "Lumi" con sus efectos de rareza y se
		-- avisa una vez en Output. Mitico aun no tiene modelo propio (usa "Lumi", sin aviso).
		rarityModels = { rare = true, epic = true, legendary = true },
		variants = {
			-- <rareza> = { animationSet = ..., animations = {...}, footInset = ... } solo si difiere
		},
	},
	-- Rocon: golem de piedra (zona 2). Las reglas de juego (rarezas sin mitico, zona,
	-- trabajo en el extractor de piedra) estan en PetCatalog; aqui solo el aspecto.
	rocon = {
		model = "Rocon",
		heightFactor = 1.0,
		yaw = 0, -- exportado con la misma convencion que Lumi (frente -Y en Blender)
		-- Apoyo corregido con medidas en Studio (2026-11-07, PETs salvajes en la zona 2, modo
		-- Cliente): con la animacion sonando, el hueso Root (padre de todo el esqueleto, y por
		-- tanto de la malla deformada) queda por debajo de la base de reposo de la MeshPart,
		-- que es la referencia de GroundOffset. Root no se mueve en los FBX, asi que es un
		-- desplazamiento constante del rig animado en Roblox, proporcional al alto:
		--   Comun   Root -0,576 studs con alto 2,0 -> -0,288 del alto
		--   Raro    Root -0,599 studs con alto 2,2 -> -0,272 del alto
		--   Epico   Root -0,692 studs con alto 2,4 -> -0,288 del alto
		-- footInset negativo sube el apoyo esa fraccion (GroundOffset = alto/2 - footInset*alto).
		-- Legendario usa la misma malla, huesos y tamaño de reposo que Epico (validador):
		-- mismo valor, PENDIENTE de medir en Studio. Docs: ART_PIPELINE.md, seccion 15.
		footInset = 0,
		animationSet = "Rocon_v3",
		animations = {},
		-- Rocon_rare / Rocon_epic / Rocon_legendary (assets/pets). Rocon no tiene mitico.
		rarityModels = { rare = true, epic = true, legendary = true },
		variants = {
			common = { footInset = -0.288 },
			rare = { footInset = -0.2723 },
			epic = { footInset = -0.2883 },
			legendary = { footInset = -0.2883 },
		},
		-- Velocidad nativa de la cinta de Walk y Run en ALTURAS DEL PET por segundo, medida
		-- en los FBX (Comun: 0,457 m/s y 1,313 m/s con 1,697 m de alto; Raro y Epico/
		-- Legendario difieren < 1 %). PetAnimator la convierte a studs/s con el alto real
		-- del modelo para que el ritmo de los pasos siga a la velocidad de desplazamiento.
		locomotion = { walk = 0.269, run = 0.774 },
	},
	-- Chispa: espiritu electrico (zona 2). Las reglas de juego (rarezas sin mitico, zona,
	-- extractor de cobre y apoyo en alquimia) estan en PetCatalog; aqui solo el aspecto.
	chispa = {
		model = "Chispa",
		heightFactor = 1.0,
		-- Frente hacia -Z (LookVector) comprobado en Studio con Idle y Walk: cola en +Z y
		-- Root sin rotacion añadida por la animacion.
		yaw = 0,
		-- Apoyo medido en Studio (2026-11-08, las 4 mallas con los 7 ids publicados): Root esta en
		-- la base de la malla en reposo y no se mueve; las suelas quedan entre 0,03 y 0,06 studs
		-- sobre esa base en Idle, Walk, Run y Work (Happy salta; en Sleep_Loop esta tumbado sobre
		-- la base). La base de reposo es el suelo: sin correccion, como Lumi. Seccion 16 de la doc.
		footInset = 0,
		animationSet = "Chispa_v1",
		animations = {},
		-- Chispa_rare / Chispa_epic / Chispa_legendary (assets/pets). Chispa no tiene mitico.
		rarityModels = { rare = true, epic = true, legendary = true },
		variants = {},
		-- Sin locomotion propia: en Walk el pie de apoyo no barre hacia atras a ritmo constante y
		-- Run casi no tiene fase de contacto (medido en Blender), asi que no hay una velocidad
		-- nativa fiable; usa las referencias globales de PetAssets.Locomotion, como Lumi.
	},
	-- Talpa: topo excavador (zona 3). Las reglas de juego (rarezas sin mitico, zona, extractor
	-- de hierro y bonus al minar) estan en PetCatalog; aqui solo el aspecto.
	talpa = {
		model = "Talpa",
		heightFactor = 1.0,
		-- Frente hacia -Z (LookVector) en los 4 FBX y en los .rbxm (hocico en -Z, cola en +Z),
		-- sin rotacion en ningun nodo: sin correccion.
		yaw = 0,
		-- Root esta en la base de la malla en reposo y no se mueve; las 7 animaciones se
		-- exportaron con la malla apoyada en Y = 0 en cada fotograma (Hips resuelto contra el
		-- suelo). La base de reposo es el suelo: sin correccion, como Lumi y Chispa.
		-- PENDIENTE de comprobar en Studio dentro de Portal Pets. Seccion 17 de la doc.
		footInset = 0,
		animationSet = "Talpa_v1",
		animations = {},
		-- Talpa_rare / Talpa_epic / Talpa_legendary (assets/pets). Talpa no tiene mitico.
		rarityModels = { rare = true, epic = true, legendary = true },
		variants = {},
		-- Sin locomotion propia: usa las referencias globales de PetAssets.Locomotion, como
		-- Lumi y Chispa.
	},
}

local folderCache = nil
local checked = {} -- [template] = true | false (valida o no)
local warned = {}

local function warnOnce(key, msg)
	if not warned[key] then
		warned[key] = true
		warn("[PetAssets] " .. msg)
	end
end

local function folder()
	if folderCache and folderCache.Parent then
		return folderCache
	end
	local rs = game:GetService("ReplicatedStorage")
	folderCache = rs:FindFirstChild("PetAssets")
	return folderCache
end

function PetAssets.Folder()
	return folder()
end

-- Parte raiz de una plantilla: PrimaryPart, o una parte llamada RootPart /
-- HumanoidRootPart, o la primera BasePart.
function PetAssets.RootOf(model)
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	local r = model:FindFirstChild("RootPart") or model:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			return d
		end
	end
	return nil
end

local function validate(name, template)
	if checked[template] ~= nil then
		return checked[template]
	end
	local ok = true
	if not template:IsA("Model") then
		warnOnce(name .. ":model", name .. " no es un Model; se usa el modelo procedural.")
		ok = false
	end
	local parts, bones, visible = 0, 0, 0
	if ok then
		for _, d in ipairs(template:GetDescendants()) do
			if d:IsA("BasePart") then
				parts = parts + 1
				if d.Transparency < 1 then
					visible = visible + 1
				end
			elseif d.ClassName == "Bone" then
				bones = bones + 1
			elseif d:IsA("LuaSourceContainer") or d.ClassName == "Script" or d.ClassName == "LocalScript" or d.ClassName == "ModuleScript" then
				warnOnce(name .. ":script", name .. " trae scripts; se eliminan al clonar (los modelos de arte no deben llevar codigo).")
			end
		end
		if visible == 0 or not PetAssets.RootOf(template) then
			warnOnce(name .. ":parts", name .. " no tiene partes visibles; se usa el modelo procedural.")
			ok = false
		elseif parts > PetAssets.Limits.maxParts then
			warnOnce(name .. ":budget", name .. " tiene " .. parts .. " partes (maximo " .. PetAssets.Limits.maxParts .. "); se usa el modelo procedural.")
			ok = false
		end
		if bones > PetAssets.Limits.maxBones then
			warnOnce(name .. ":bones", name .. " tiene " .. bones .. " huesos; revisa el presupuesto del rig.")
		end
	end
	checked[template] = ok
	return ok
end

-- Devuelve la plantilla valida para una especie y rareza, o nil (=> procedural).
-- Con shiny = true busca primero las variantes Shiny personalizadas:
--   "<model>_<rareza>_shiny", "<model>_shiny"; despues las normales.
-- Cuarto valor: true si la plantilla encontrada es una variante Shiny.
function PetAssets.Find(speciesId, rarityId, shiny)
	if not PetAssets.Enabled then
		return nil
	end
	local cfg = PetAssets.Species[speciesId]
	if not cfg or cfg.enabled == false then
		return nil
	end
	local f = folder()
	if not f or f:GetAttribute("UseProcedural") == true then
		return nil
	end
	local candidates = {}
	if shiny then
		if rarityId then
			table.insert(candidates, { cfg.model .. "_" .. rarityId .. "_shiny", true })
		end
		table.insert(candidates, { cfg.model .. "_shiny", true })
	end
	if rarityId then
		table.insert(candidates, { cfg.model .. "_" .. rarityId, false })
	end
	table.insert(candidates, { cfg.model, false })
	for _, c in ipairs(candidates) do
		local name = c[1]
		local t = f:FindFirstChild(name)
		if t and validate(name, t) then
			-- Se cayo al modelo base aunque esta rareza tiene plantilla propia prevista
			if name == cfg.model and rarityId and cfg.rarityModels and cfg.rarityModels[rarityId] then
				local want = cfg.model .. "_" .. rarityId
				warnOnce(want .. ":missing", "Falta (o no es valida) la plantilla " .. want .. " en ReplicatedStorage.PetAssets (assets/pets/" .. want
					.. ".rbxm); este PET usa " .. name .. " con los efectos de su rareza. Ver docs/ART_PIPELINE.md, seccion 14.")
			end
			return t, cfg, name, c[2]
		end
	end
	return nil
end

-- Un unico objeto Animation por (estado, id): todos los PETs lo comparten
local animCache = {}
local function animationObject(state, id)
	local key = state .. "|" .. id
	local a = animCache[key]
	if not a then
		a = Instance.new("Animation")
		a.Name = state
		a.AnimationId = id
		animCache[key] = a
	end
	return a
end

-- Conjunto de animaciones aplicable a un modelo, o nil si no hay o si el rig no coincide
function PetAssets.AnimationSetFor(model, speciesId)
	local cfg = PetAssets.Species[speciesId]
	if not cfg then
		return nil
	end
	local rarity = model:GetAttribute("Rarity")
	local variant = cfg.variants and rarity and cfg.variants[rarity] or nil
	local setName = (variant and variant.animationSet) or cfg.animationSet
	local set = setName and PetAssets.AnimationSets[setName] or nil
	if not set then
		return nil, variant
	end
	local rig = model:GetAttribute("Rig")
	if rig ~= nil and set.rig ~= nil and rig ~= set.rig then
		warnOnce(tostring(model:GetAttribute("AssetName")) .. ":rig:" .. setName,
			tostring(model:GetAttribute("AssetName")) .. " tiene Rig=" .. tostring(rig) .. " y el conjunto " .. setName .. " es para " .. set.rig .. "; no se usa.")
		return nil, variant
	end
	return set, variant
end

-- Fuentes de animacion por estado: carpeta "Animations" de la plantilla y, si
-- faltan, los ids configurados (variante, especie, conjunto). Devuelve { [estado] = Animation }.
function PetAssets.AnimationsFor(model, speciesId)
	local out = {}
	local folderA = model:FindFirstChild("Animations")
	local cfg = PetAssets.Species[speciesId]
	local set, variant = PetAssets.AnimationSetFor(model, speciesId)
	for _, state in ipairs(PetAssets.States) do
		local a = folderA and folderA:FindFirstChild(state)
		if a and a.ClassName == "Animation" and PetAssets.IsAnimationId(a.AnimationId) then
			out[state] = a
		else
			local id = (variant and variant.animations and variant.animations[state])
			if not PetAssets.IsAnimationId(id) then
				id = cfg and cfg.animations and cfg.animations[state]
			end
			if not PetAssets.IsAnimationId(id) then
				id = set and set.ids and set.ids[state]
			end
			if PetAssets.IsAnimationId(id) then
				out[state] = animationObject(state, id)
			end
		end
	end
	return out
end

function PetAssets.IsAnimationId(id)
	if type(id) ~= "string" then
		return false
	end
	return string.match(id, "^rbxassetid://%d+$") ~= nil or string.match(id, "^https?://") ~= nil
end

return PetAssets
