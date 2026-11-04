-- Recipes: fabricacion de herramientas y construcciones del Hogar.
-- Cada "linea" tiene niveles; solo se puede fabricar el siguiente nivel.
-- (GDD 02, 07, 08, 09 y 14)

local Items = require(script.Parent.Items)
local PetCatalog = require(script.Parent.PetCatalog)
local WorldConfig = require(script.Parent.WorldConfig)

local Recipes = {}

local function scale(cost, mult)
	local out = {}
	for k, v in pairs(cost) do
		out[k] = math.floor(v * mult + 0.5)
	end
	return out
end

-- Definicion de lineas -------------------------------------------------------------
-- get(profile) -> nivel actual; levels[n] = { cost, zone (zona requerida), req(profile) -> ok, texto }
Recipes.Lines = {}
Recipes.LineOrder = {}

local function addLine(def)
	Recipes.Lines[def.id] = def
	table.insert(Recipes.LineOrder, def.id)
end

addLine({
	id = "pick", category = "tools", name = "Pico",
	get = function(p) return p.tools.pick end,
	maxLevel = 5,
	names = { "Pico de madera", "Pico de piedra", "Pico de cobre", "Pico de hierro", "Pico de cristal" },
	levels = {
		[2] = { cost = { madera = 30, piedra = 40 } },
		[3] = { cost = { madera = 60, piedra = 120, cobre = 60 } },
		[4] = { cost = { piedra = 150, cobre = 150, hierro = 100 } },
		[5] = { cost = { hierro = 200, lunar = 80, hongo = 30 } },
	},
	desc = function(lv) return "Permite minar " .. Items.Picks[lv].unlocks .. "." end,
})

addLine({
	id = "vacuum", category = "tools", name = "Succionador",
	get = function(p) return p.tools.vacuum end,
	maxLevel = 5,
	names = { "Succionador basico", "Succionador reforzado", "Succionador magnetico", "Succionador dimensional", "Succionador maestro" },
	levels = {
		[2] = { cost = { madera = 40, piedra = 50, petalo = 15 } },
		[3] = { cost = { cobre = 80, hierro = 40, engranaje = 20 } },
		[4] = { cost = { hierro = 120, lunar = 40, hongo = 25 } },
		[5] = { cost = { zuarita = 40, elemental = 30, polvo = 20 } },
	},
	desc = function(lv)
		local v = Items.Vacuums[lv]
		return string.format("+%d%% captura, +%d%% velocidad, alcance %d.", v.chance * 100, v.speed * 100, v.range)
	end,
})

addLine({
	id = "sanctuary", category = "build", name = "Santuario",
	get = function(p) return p.buildings.sanctuary end,
	maxLevel = 5,
	names = { "Santuario (casa deteriorada)", "Santuario reparado", "Santuario acogedor", "Santuario de dos pisos", "Santuario dimensional" },
	levels = {
		[2] = { cost = { madera = 50, piedra = 50 } },
		[3] = { cost = { madera = 150, piedra = 150, cobre = 50 } },
		[4] = { cost = { madera = 300, cobre = 200, hierro = 120 } },
		[5] = { cost = { madera = 500, hierro = 250, lunar = 80, zuarita = 30 } },
	},
	desc = function(lv)
		if lv == 3 then
			return "Mejora visible de la casa. Desbloquea el 3er espacio de equipo y el laboratorio de fusiones."
		end
		return "Mejora visible de la casa y mas almacen de PETs."
	end,
})

addLine({
	id = "forge", category = "build", name = "Herreria",
	get = function(p) return p.buildings.forge end,
	maxLevel = 2,
	names = { "Herreria", "Herreria mejorada" },
	levels = {
		[2] = { cost = { piedra = 80, cobre = 40 } },
	},
	desc = function() return "Desbloquea el 2do espacio de equipo (apoyo)." end,
})

addLine({
	id = "petstorage", category = "build", name = "Almacen de PETs",
	get = function(p) return p.buildings.petStorage end,
	maxLevel = 10,
	baseLevel = 0,
	names = {},
	levels = (function()
		local t = {}
		for k = 1, 10 do
			local c = { madera = 100 * k, piedra = 80 * k }
			if k >= 4 then
				c.hierro = 30 * k
			end
			t[k] = { cost = c }
		end
		return t
	end)(),
	desc = function() return "+10 espacios en el almacen de PETs del santuario." end,
})

addLine({
	id = "garden", category = "build", name = "Huerto",
	get = function(p) return p.buildings.garden end,
	maxLevel = 5,
	baseLevel = 0,
	names = { "Huerto", "Huerto nivel 2", "Huerto nivel 3", "Huerto nivel 4", "Huerto nivel 5" },
	levels = {
		[1] = { cost = { madera = 80, piedra = 60, hongo = 5 }, zone = 3 },
		[2] = { cost = { madera = 150, cobre = 60, hongo = 15 }, zone = 3 },
		[3] = { cost = { madera = 250, hierro = 80, elemental = 10 }, zone = 4 },
		[4] = { cost = { madera = 400, lunar = 40, elemental = 25 }, zone = 4 },
		[5] = { cost = { madera = 600, zuarita = 30, estelar = 20 }, zone = 5 },
	},
	desc = function(lv) return string.format("%d parcelas de cultivo y %d puestos de trabajo.", Items.GardenPlots[lv], PetCatalog.StationSlots[lv]) end,
})

addLine({
	id = "alchemy", category = "build", name = "Laboratorio de alquimia",
	get = function(p) return p.buildings.alchemy end,
	maxLevel = 1, baseLevel = 0,
	names = { "Laboratorio de alquimia" },
	levels = { [1] = { cost = { madera = 100, piedra = 100, cobre = 50, hongo = 10 }, zone = 3 } },
	desc = function() return "Prepara pociones temporales." end,
})

addLine({
	id = "bait", category = "build", name = "Estacion de cebos",
	get = function(p) return p.buildings.bait end,
	maxLevel = 1, baseLevel = 0,
	names = { "Estacion de cebos" },
	levels = { [1] = { cost = { madera = 80, piedra = 40, hongo = 5 }, zone = 3 } },
	desc = function() return "Prepara cebos para facilitar capturas." end,
})

addLine({
	id = "fusionlab", category = "build", name = "Laboratorio de fusiones",
	get = function(p) return p.buildings.fusionLab end,
	maxLevel = 1, baseLevel = 0,
	names = { "Laboratorio de fusiones" },
	levels = { [1] = { cost = { hierro = 150, lunar = 50, elemental = 20 }, zone = 4,
		req = function(p) return p.buildings.sanctuary >= 3, "Requiere santuario nivel 3" end } },
	desc = function() return "Resonancia Dimensional: fusiones temporales de dos PETs." end,
})

-- Extractores ------------------------------------------------------------------------
local stationBase = {
	stone = { cost = { madera = 40, piedra = 60 }, zone = 1 },
	copper = { cost = { piedra = 80, cobre = 40 }, zone = 2 },
	iron = { cost = { piedra = 120, cobre = 80, hierro = 30 }, zone = 3 },
	moon = { cost = { cobre = 120, hierro = 80, lunar = 20 }, zone = 3 },
	zuarita = { cost = { hierro = 120, lunar = 40, zuarita = 10 }, zone = 3 },
	nexus = { cost = { lunar = 80, zuarita = 30, estelar = 10 }, zone = 5 },
}
local stationMult = { 1, 3, 8, 20, 50 }
for _, sid in ipairs({ "stone", "copper", "iron", "moon", "zuarita", "nexus" }) do
	local base = stationBase[sid]
	local st = PetCatalog.Stations[sid]
	local levels = {}
	for lv = 1, 5 do
		levels[lv] = { cost = scale(base.cost, stationMult[lv]), zone = base.zone }
	end
	addLine({
		id = "station_" .. sid, category = "stations", name = st.name, station = sid,
		get = function(p) return p.stations[sid].level end,
		maxLevel = 5, baseLevel = 0,
		names = { st.name, st.name .. " Nv.2", st.name .. " Nv.3", st.name .. " Nv.4", st.name .. " Nv.5" },
		levels = levels,
		desc = function(lv)
			return string.format("%d puestos, deposito de %d.", PetCatalog.StationSlots[lv], PetCatalog.StationCapacity[lv])
		end,
	})
end

-- Decoraciones -------------------------------------------------------------------------
local decos = {
	{ id = "fuente", name = "Fuente de cuarzo", cost = { piedra = 100, cuarzo = 10 } },
	{ id = "estatua", name = "Estatua prismatica", cost = { hierro = 50, prisma = 10 } },
	{ id = "faroles", name = "Faroles astrales", cost = { cobre = 50, astral = 5 } },
	{ id = "arco", name = "Arco del eclipse", cost = { zuarita = 20, gravedad = 10, eclipse = 3 } },
}
Recipes.Decorations = decos
for _, d in ipairs(decos) do
	addLine({
		id = "deco_" .. d.id, category = "deco", name = d.name, deco = d.id,
		get = function(p) return p.decorations[d.id] and 1 or 0 end,
		maxLevel = 1, baseLevel = 0,
		names = { d.name },
		levels = { [1] = { cost = d.cost } },
		desc = function() return "Decoracion visible en tu santuario." end,
	})
end

Recipes.Categories = {
	{ id = "tools", name = "Herramientas" },
	{ id = "build", name = "Construccion" },
	{ id = "stations", name = "Extractores" },
	{ id = "deco", name = "Decoraciones" },
}

-- Requisitos derivados de los materiales: ninguna receta debe pedir algo que
-- el jugador todavia no pueda recolectar. Devuelve una lista de requisitos
-- { kind, value, text, why } sin evaluar.
function Recipes.MaterialRequirements(cost)
	local reqs = {}
	local seen = {}
	local function add(kind, value, text, why)
		local key = kind .. ":" .. tostring(value)
		if not seen[key] then
			seen[key] = true
			table.insert(reqs, { kind = kind, value = value, text = text, why = why })
		end
	end
	local ids = {}
	for id in pairs(cost) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local resName = Items.Resources[id] and Items.Resources[id].name or id
		local node = WorldConfig.MineralNode[id]
		if node then
			local zone = WorldConfig.FirstMineZone(id) or 1
			local pick = Items.Nodes[node].pick
			if zone > 1 then
				add("zone", zone, "Desbloquear la Zona " .. zone, "para encontrar " .. resName)
			end
			if pick > 1 then
				add("pick", pick, Items.Picks[pick].name, "para minar " .. resName)
			end
		else
			local src = WorldConfig.ResourceSources[id]
			if src then
				if (src.zone or 1) > 1 then
					add("zone", src.zone, "Desbloquear la Zona " .. src.zone, "para conseguir " .. resName)
				end
				if src.building then
					add("building", src.building, "Huerto construido", "para cultivar " .. resName)
				end
				if src.station then
					add("station", src.station, PetCatalog.Stations[src.station].name .. " construido", "para producir " .. resName)
				end
				if src.species then
					add("species", src.species, "Tener un " .. PetCatalog.Get(src.species).name, "para producir " .. resName)
				end
			end
		end
	end
	return reqs
end

local function evalMaterialReq(profile, r)
	if r.kind == "zone" then
		return (profile.zones.unlocked or 1) >= r.value
	elseif r.kind == "pick" then
		return profile.tools.pick >= r.value
	elseif r.kind == "building" then
		return (profile.buildings[r.value] or 0) >= 1
	elseif r.kind == "station" then
		return profile.stations[r.value] ~= nil and profile.stations[r.value].level >= 1
	elseif r.kind == "species" then
		return (profile.captured[r.value] or 0) > 0
	end
	return true
end

-- Lista completa de requisitos de un paso: { text, ok, why? }
function Recipes.Requirements(profile, lineId, level)
	local line = Recipes.Lines[lineId]
	local def = line and line.levels[level]
	local out = {}
	if not def then
		return out
	end
	local base = line.baseLevel or 1
	if level - 1 >= base and level - 1 >= 1 then
		local prevName = line.names[level - 1] or (line.name .. " " .. (level - 1))
		table.insert(out, { text = "Tener " .. prevName, ok = line.get(profile) >= level - 1 })
	end
	local zoneShown = 0
	if def.zone and def.zone > 1 then
		zoneShown = def.zone
		table.insert(out, { text = "Desbloquear la Zona " .. def.zone, ok = (profile.zones.unlocked or 1) >= def.zone })
	end
	if def.req then
		local ok, why = def.req(profile)
		table.insert(out, { text = why or "Requisito especial", ok = ok })
	end
	for _, r in ipairs(Recipes.MaterialRequirements(def.cost)) do
		local redundant = (r.kind == "zone" and r.value <= zoneShown)
			or (r.kind == "pick" and lineId == "pick" and r.value <= level - 1)
		if not redundant then
			if r.kind == "zone" then
				zoneShown = math.max(zoneShown, r.value)
			end
			table.insert(out, { text = r.text, ok = evalMaterialReq(profile, r), why = r.why })
		end
	end
	return out
end

-- Siguiente paso de una linea para un perfil.
-- Devuelve: { line, level, name, cost, desc, locked, reason, requirements } o
-- { maxed = true } si esta al maximo.
function Recipes.Next(profile, lineId)
	local line = Recipes.Lines[lineId]
	if not line then
		return nil
	end
	local cur = line.get(profile)
	if cur >= line.maxLevel then
		return { line = line, level = cur, maxed = true, name = line.names[cur] or line.name }
	end
	local lv = cur + 1
	local def = line.levels[lv]
	local reqs = Recipes.Requirements(profile, lineId, lv)
	local locked, reason = false, nil
	for _, r in ipairs(reqs) do
		if not r.ok then
			locked = true
			reason = "Requiere: " .. r.text .. (r.why and (" (" .. r.why .. ")") or "")
			break
		end
	end
	return {
		line = line,
		level = lv,
		name = line.names[lv] or (line.name .. " " .. lv),
		cost = def.cost,
		desc = line.desc and line.desc(lv) or "",
		locked = locked,
		reason = reason,
		requirements = reqs,
	}
end

return Recipes
