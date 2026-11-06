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
PetAssets.States = { "Idle", "Walk", "Run", "Jump", "CaptureReaction" }

-- Ajustes por estado: bucle, prioridad y a que estado recurrir si falta
PetAssets.StateInfo = {
	Idle = { looped = true, priority = "Idle", fallback = nil },
	Walk = { looped = true, priority = "Movement", fallback = "Idle" },
	Run = { looped = true, priority = "Movement", fallback = "Walk" },
	Jump = { looped = false, priority = "Action", fallback = "Idle" },
	CaptureReaction = { looped = true, priority = "Action", fallback = "Idle" },
}

-- Umbrales de velocidad (studs/s) para elegir Idle / Walk / Run
PetAssets.Locomotion = { walk = 0.6, run = 7, fade = 0.15, referenceWalkSpeed = 4, referenceRunSpeed = 12 }

-- Limites de seguridad para plantillas (avisos, no bloqueos, salvo maxParts)
PetAssets.Limits = { maxParts = 40, maxBones = 64 }

-- Especies con modelo importado. Solo las especies listadas aqui buscan plantilla.
--   model: nombre de la plantilla en ReplicatedStorage.PetAssets. Antes se busca
--          "<model>_<rareza>" (variante opcional por rareza) y despues "<model>".
--   heightFactor: alto final = alto del PET procedural (2 * escala * tamaño de
--          rareza) * heightFactor. La plantilla se escala sola con Model:ScaleTo.
--   yaw: grados para corregir la orientacion si la cara no mira hacia -Z.
--   animations: AnimationId por estado SOLO si no vienen dentro de la plantilla.
--          Deben ser ids reales publicados por la cuenta dueña de la experiencia.
PetAssets.Species = {
	lumi = {
		model = "Lumi",
		heightFactor = 1.0,
		yaw = 0,
		animations = {
			-- Idle = "rbxassetid://<id real>", -- dejar vacio hasta tener el id publicado
		},
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

-- Devuelve la plantilla valida para una especie y rareza, o nil (=> procedural)
function PetAssets.Find(speciesId, rarityId)
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
	if rarityId then
		table.insert(candidates, cfg.model .. "_" .. rarityId)
	end
	table.insert(candidates, cfg.model)
	for _, name in ipairs(candidates) do
		local t = f:FindFirstChild(name)
		if t and validate(name, t) then
			return t, cfg, name
		end
	end
	return nil
end

-- Fuentes de animacion: objetos Animation dentro de la plantilla (carpeta
-- "Animations") y, si faltan, los ids configurados. Devuelve { [estado] = Animation }.
function PetAssets.AnimationsFor(model, speciesId)
	local out = {}
	local folderA = model:FindFirstChild("Animations")
	local cfg = PetAssets.Species[speciesId]
	for _, state in ipairs(PetAssets.States) do
		local a = folderA and folderA:FindFirstChild(state)
		if a and a.ClassName == "Animation" and PetAssets.IsAnimationId(a.AnimationId) then
			out[state] = a
		elseif cfg and cfg.animations and PetAssets.IsAnimationId(cfg.animations[state]) then
			local anim = Instance.new("Animation")
			anim.Name = state
			anim.AnimationId = cfg.animations[state]
			out[state] = anim
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
