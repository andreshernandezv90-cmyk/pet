-- Progression: zonas del Reino, requisitos, capacidades y objetivos del HUD.
-- (GDD 03, 05, 14 y 18)

local PetCatalog = require(script.Parent.PetCatalog)
local Items = require(script.Parent.Items)
local WorldConfig = require(script.Parent.WorldConfig)

local Progression = {}

-- Zonas del Mundo PET (datos en WorldConfig.Regions)
Progression.Zones = WorldConfig.Regions

local BUILDING_NAMES = {
	garden = "Huerto",
	alchemy = "Laboratorio de alquimia",
	bait = "Estacion de cebos",
	fusionLab = "Laboratorio de fusiones",
	forge = "Herreria",
}

local function speciesMissing(p, maxZone)
	local missing, total = 0, 0
	for _, s in ipairs(PetCatalog.Species) do
		if s.zone <= maxZone then
			total = total + 1
			if (p.captured[s.id] or 0) <= 0 then
				missing = missing + 1
			end
		end
	end
	return missing, total
end

-- Evalua un requisito configurable. Devuelve ok, texto.
function Progression.Evaluate(p, req)
	local t = req.type
	if t == "pick" then
		local pick = Items.Picks[req.level]
		return p.tools.pick >= req.level, pick and pick.name or ("Pico nivel " .. req.level)
	elseif t == "vacuum" then
		local v = Items.Vacuums[req.level]
		return p.tools.vacuum >= req.level, (v and v.name or ("Succionador nivel " .. req.level)) .. " o superior"
	elseif t == "sanctuary" then
		return p.buildings.sanctuary >= req.level, "Santuario nivel " .. req.level
	elseif t == "building" then
		local name = BUILDING_NAMES[req.id] or req.id
		local lv = req.level or 1
		return (p.buildings[req.id] or 0) >= lv, name .. (lv > 1 and (" nivel " .. lv) or " construido")
	elseif t == "station" then
		local st = PetCatalog.Stations[req.id]
		local lv = req.level or 1
		local cur = p.stations[req.id] and p.stations[req.id].level or 0
		return cur >= lv, (st and st.name or req.id) .. (lv > 1 and (" nivel " .. lv) or " construido")
	elseif t == "anyStation" then
		for id, st in pairs(p.stations) do
			if id ~= "garden" and st.level >= 1 then
				return true, "Primer extractor construido"
			end
		end
		return false, "Primer extractor construido"
	elseif t == "speciesCaptured" then
		local missing, total = speciesMissing(p, req.maxZone)
		local text = string.format("Mision: capturar las %d especies de las zonas 1-%d", total, req.maxZone)
		if missing > 0 then
			text = text .. string.format(" (faltan %d)", missing)
		end
		return missing == 0, text
	elseif t == "zone" then
		return (p.zones.unlocked or 1) >= req.id, "Desbloquear la Zona " .. req.id
	end
	return false, "Requisito desconocido: " .. tostring(t)
end

-- Requisitos de cada zona como { text, check } (compatibilidad con la API anterior)
Progression.Requirements = {}
for _, region in ipairs(WorldConfig.Regions) do
	local list = {}
	for _, req in ipairs(region.requirements) do
		local _, text = Progression.Evaluate(
			{ tools = { pick = 0, vacuum = 0 }, buildings = { sanctuary = 0 }, stations = {}, captured = {}, zones = { unlocked = 0 } }, req)
		table.insert(list, { text = text, req = req, check = function(p)
			return (Progression.Evaluate(p, req))
		end })
	end
	Progression.Requirements[region.id] = list
end

-- Estado de cada requisito de una zona: { { text, ok } }
function Progression.Status(profile, zone)
	local out = {}
	local region = WorldConfig.Regions[zone]
	if not region then
		return out
	end
	for _, req in ipairs(region.requirements) do
		local ok, text = Progression.Evaluate(profile, req)
		table.insert(out, { text = text, ok = ok })
	end
	return out
end

function Progression.Missing(profile, zone)
	local out = {}
	for _, st in ipairs(Progression.Status(profile, zone)) do
		if not st.ok then
			table.insert(out, st.text)
		end
	end
	return out
end

function Progression.CanUnlock(profile, zone)
	return #Progression.Missing(profile, zone) == 0
end

-- Capacidades portatiles gratuitas por zona desbloqueada (GDD 14)
Progression.BackpackByZone = { 5, 10, 15, 20, 25 }
Progression.TankByZone = { 3, 6, 9, 12, 15 }
Progression.PetStorageBySanctuary = { 10, 15, 25, 40, 60 }

function Progression.BackpackSlots(p)
	return Progression.BackpackByZone[math.clamp(p.zones.unlocked, 1, 5)] + (p.paid.backpack or 0)
end

function Progression.TankSlots(p)
	return Progression.TankByZone[math.clamp(p.zones.unlocked, 1, 5)] + (p.paid.tank or 0)
end

function Progression.PetStorageSlots(p)
	return Progression.PetStorageBySanctuary[math.clamp(p.buildings.sanctuary, 1, 5)] + 10 * (p.buildings.petStorage or 0)
end

-- Espacios de equipo (GDD 05): inicio 1, herreria 2 => 2, santuario 3 => 3
function Progression.TeamSlots(p)
	local n = 1
	if p.buildings.forge >= 2 then
		n = n + 1
	end
	if p.buildings.sanctuary >= 3 then
		n = n + 1
	end
	return n
end

function Progression.FusionSlots(p, isVip)
	if (p.buildings.fusionLab or 0) < 1 then
		return 0
	end
	return isVip and 2 or 1
end

local function totalRes(p, id)
	return (p.res.backpack[id] or 0) + (p.res.storage[id] or 0)
end

-- Objetivo actual para el HUD: "que te falta para avanzar"
function Progression.Objective(p)
	if (p.captured.lumi or 0) <= 0 then
		return "Viaja al Mundo PET (boton Mapa) y captura tu primer Lumi en el " .. Progression.Zones[1].name .. "."
	end
	if p.zones.unlocked < 2 then
		if not p.story.visitedMines and totalRes(p, "piedra") < 10 then
			return "Entra a una Mina de Zuar y consigue piedra con tu pico de madera."
		end
		if totalRes(p, "madera") < 10 and (p.buildings.sanctuary < 2 or p.stations.stone.level < 1) then
			return "Tala arboles alrededor de tu santuario para conseguir madera."
		end
		if p.buildings.sanctuary < 2 then
			return "Mejora el Santuario a nivel 2 en el Taller (50 madera + 50 piedra)."
		end
		if p.stations.stone.level < 1 then
			return "Construye el Extractor de piedra en el Taller y pon a trabajar a un Lumi."
		end
		if p.tools.pick < 2 then
			return "Fabrica el Pico de piedra en el Taller para abrir la Zona 2."
		end
	end
	local unlocked = p.zones.unlocked
	if unlocked < 5 then
		local nextZone = unlocked + 1
		local missing = Progression.Missing(p, nextZone)
		if #missing > 0 then
			return "Zona " .. nextZone .. " (" .. Progression.Zones[nextZone].name .. "): " .. table.concat(missing, " · ")
		end
		return "¡La Zona " .. nextZone .. " esta lista! Abre el Mapa para viajar."
	end
	if (p.captured.eclipsar or 0) <= 0 then
		return "Mision final: encuentra y captura a Eclipsar en el Templo del Eclipse."
	end
	local n, total = 0, 0
	for _, key in ipairs(PetCatalog.AllVariants()) do
		total = total + 1
		if p.dex[key] then
			n = n + 1
		end
	end
	if n < total then
		return string.format("¡Completa tu PETdex! %d/%d variantes descubiertas.", n, total)
	end
	return "¡Has completado Portal Pets! Lleva tus PETs al nivel 5 y domina las incursiones."
end

-- Bonificacion de coleccion: especies con sus 4 rarezas base (+1% c/u, una sola vez)
function Progression.CollectionBonus(p)
	local complete = 0
	for _, s in ipairs(PetCatalog.Species) do
		local all = true
		for _, r in ipairs({ "common", "rare", "epic", "legendary" }) do
			if not p.dex[PetCatalog.Key(s.id, r)] then
				all = false
			end
		end
		if all then
			complete = complete + 1
		end
	end
	return complete * 0.01, complete
end

return Progression
