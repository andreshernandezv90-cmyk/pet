-- Progression: zonas del Reino, requisitos, capacidades y objetivos del HUD.
-- (GDD 03, 05, 14 y 18)

local PetCatalog = require(script.Parent.PetCatalog)

local Progression = {}

Progression.Zones = {
	{ id = 1, name = "Praderas Luminosas", activity = "Parkour tutorial con checkpoints y capturas basicas.",
		color = Color3.fromRGB(150, 220, 110), material = "petalo" },
	{ id = 2, name = "Valle de los Engranajes", activity = "Bloques moviles, circuitos y disparo de resonancia.",
		color = Color3.fromRGB(200, 170, 110), material = "engranaje" },
	{ id = 3, name = "Cavernas Olvidadas", activity = "Cuevas oscuras y captura avanzada. Desbloquea huerto, alquimia y cebos.",
		color = Color3.fromRGB(90, 80, 120), material = "hongo" },
	{ id = 4, name = "Jardines Elementales", activity = "Mecanicas elementales, muros de hielo y plataformas moviles.",
		color = Color3.fromRGB(120, 200, 160), material = "elemental" },
	{ id = 5, name = "Templo del Eclipse", activity = "Gravedad, puzles combinados y mision final.",
		color = Color3.fromRGB(110, 90, 170), material = "estelar" },
}

local function anyStation(p)
	for id, st in pairs(p.stations) do
		if id ~= "garden" and st.level >= 1 then
			return true
		end
	end
	return false
end

local function earlySpeciesDone(p)
	local missing = 0
	for _, s in ipairs(PetCatalog.Species) do
		if s.zone <= 4 and (p.captured[s.id] or 0) <= 0 then
			missing = missing + 1
		end
	end
	return missing == 0, missing
end

-- Requisitos de cada zona (puerta de acceso)
Progression.Requirements = {
	[2] = {
		{ text = "Pico de piedra", check = function(p) return p.tools.pick >= 2 end },
		{ text = "Santuario nivel 2", check = function(p) return p.buildings.sanctuary >= 2 end },
	},
	[3] = {
		{ text = "Pico de cobre", check = function(p) return p.tools.pick >= 3 end },
		{ text = "Primer extractor construido", check = anyStation },
	},
	[4] = {
		{ text = "Pico de hierro", check = function(p) return p.tools.pick >= 4 end },
		{ text = "Huerto nivel 2", check = function(p) return p.buildings.garden >= 2 end },
		{ text = "Succionador mejorado (reforzado o superior)", check = function(p) return p.tools.vacuum >= 2 end },
	},
	[5] = {
		{ text = "Succionador magnetico o superior", check = function(p) return p.tools.vacuum >= 3 end },
		{ text = "Santuario nivel 4", check = function(p) return p.buildings.sanctuary >= 4 end },
		{ text = "Mision: capturar las 10 especies de las zonas 1-4", check = function(p)
			return (earlySpeciesDone(p))
		end },
	},
}

function Progression.Missing(profile, zone)
	local out = {}
	local reqs = Progression.Requirements[zone]
	if not reqs then
		return out
	end
	for _, r in ipairs(reqs) do
		if not r.check(profile) then
			table.insert(out, r.text)
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
		return "Viaja al Reino de los PETs (boton Mapa) y captura tu primer Lumi en las Praderas Luminosas."
	end
	if p.tools.pick < 2 or p.buildings.sanctuary < 2 then
		if not p.story.visitedMines and totalRes(p, "piedra") < 10 then
			return "Visita las Minas de Zuar y consigue piedra con tu pico de madera."
		end
		if totalRes(p, "madera") < 10 and p.buildings.sanctuary < 2 then
			return "Recoge madera en el bosque que rodea el Hogar."
		end
		if p.buildings.sanctuary < 2 then
			return "Mejora el Santuario a nivel 2 en el Taller (50 madera + 50 piedra)."
		end
		return "Fabrica el Pico de piedra en el Taller para abrir la Zona 2."
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
