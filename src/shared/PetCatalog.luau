-- PetCatalog: definiciones inmutables de especies, rarezas, habilidades y trabajos.
-- (GDD secciones 04, 05 y 08)

local PetCatalog = {}

-- Rarezas oficiales ---------------------------------------------------------------
-- weight: peso base de aparicion (%). essence: esencias al reciclar en el Reactor.
PetCatalog.Rarities = {
	{ id = "common", name = "Comun", order = 1, weight = 70, essence = 2, color = Color3.fromRGB(200, 200, 200), size = 1.0,
		power = 1.0, work = 1.0, catchChance = 0.90, catchTime = 0.0 },
	{ id = "rare", name = "Raro", order = 2, weight = 22, essence = 3, color = Color3.fromRGB(80, 170, 255), size = 1.1,
		power = 1.6, work = 1.5, catchChance = 0.75, catchTime = 0.5 },
	{ id = "epic", name = "Epico", order = 3, weight = 6.5, essence = 5, color = Color3.fromRGB(180, 90, 255), size = 1.2,
		power = 2.5, work = 2.2, catchChance = 0.55, catchTime = 1.0 },
	{ id = "legendary", name = "Legendario", order = 4, weight = 1.45, essence = 10, color = Color3.fromRGB(255, 190, 40), size = 1.35,
		power = 4.0, work = 3.5, catchChance = 0.35, catchTime = 1.5 },
	{ id = "mythic", name = "Mitico", order = 5, weight = 0.05, essence = 15, color = Color3.fromRGB(255, 70, 160), size = 1.5,
		power = 10.0, work = 6.0, catchChance = 0.20, catchTime = 2.0 },
}

PetCatalog.RarityById = {}
for _, r in ipairs(PetCatalog.Rarities) do
	PetCatalog.RarityById[r.id] = r
end

-- Multiplicadores por nivel de mejora (indice = nivel + 1)
PetCatalog.LevelPower = { 1.0, 1.4, 1.8, 2.2, 2.6, 3.0 }
PetCatalog.LevelWork = { 1.0, 1.25, 1.5, 1.8, 2.2, 2.6 }
-- Costos de cada salto (GDD 13): 50 / 200 / 500 / 1000 / 5000 = 6750
PetCatalog.LevelCosts = { 50, 200, 500, 1000, 5000 }
PetCatalog.MaxLevel = 5

-- Descripcion de estadisticas de compañero ---------------------------------------
PetCatalog.StatInfo = {
	mineSpeed = { name = "Velocidad de mineria", cap = 2.0, pct = true },
	mineDamage = { name = "Fuerza en minerales duros", cap = 1.5, pct = true },
	oreYield = { name = "Rendimiento al minar", cap = 1.0, pct = true },
	copperFind = { name = "Cobre extra", cap = 1.0, pct = true },
	rareFind = { name = "Prob. de polvo de Zuarita", cap = 0.5, pct = true },
	captureEase = { name = "Facilidad de captura", cap = 0.35, pct = true },
	captureSpeed = { name = "Velocidad de captura", cap = 0.6, pct = true },
	growth = { name = "Crecimiento de cultivos", cap = 2.0, pct = true },
	baitPower = { name = "Potencia de cebos", cap = 0.6, pct = true },
	essenceFind = { name = "Esencias extra", cap = 0.5, pct = true },
	woodYield = { name = "Madera extra", cap = 1.0, pct = true },
	jump = { name = "Planeo / salto", cap = 0.6, pct = true },
}

PetCatalog.FlagInfo = {
	light = "Aporta luz",
	nightVision = "Vision nocturna en cuevas",
	meltIce = "Derrite muros de hielo",
	glide = "Planea distancias cortas",
	reveal = "Revela plataformas ocultas",
	gravity = "Manipula la gravedad",
	anomaly = "Localiza cofres secretos",
	roots = "Activa raices",
}

-- Estaciones de trabajo ------------------------------------------------------------
PetCatalog.Stations = {
	stone = { id = "stone", name = "Extractor de piedra", product = "piedra", zone = 1 },
	copper = { id = "copper", name = "Extractor de cobre", product = "cobre", zone = 2 },
	iron = { id = "iron", name = "Extractor de hierro", product = "hierro", zone = 3 },
	moon = { id = "moon", name = "Extractor lunar", product = "lunar", zone = 3 },
	zuarita = { id = "zuarita", name = "Refineria de Zuarita", product = "polvo", zone = 3 },
	nexus = { id = "nexus", name = "Nexo dimensional", product = nil, zone = 5 },
	garden = { id = "garden", name = "Huerto", product = nil, zone = 3 },
}
PetCatalog.StationOrder = { "stone", "copper", "iron", "moon", "zuarita", "nexus", "garden" }
PetCatalog.StationSlots = { 2, 3, 5, 7, 10 }
PetCatalog.StationCapacity = { 1000, 3000, 10000, 30000, 100000 }

-- Las quince especies --------------------------------------------------------------
-- bonus: estadisticas numericas como compañero (valor base para comun nivel 0).
-- flags: poderes de navegacion. jobs: estaciones compatibles y tasa base (unidades/seg).
PetCatalog.Species = {
	{ id = "lumi", num = 1, name = "Lumi", zone = 1, shape = "round", mythic = true, bait = "berry", weight = 1,
		color = Color3.fromRGB(255, 240, 150), color2 = Color3.fromRGB(255, 255, 220),
		companion = "Acelera la mineria y aporta luz.", work = "Extractor de piedra.",
		bonus = { mineSpeed = 0.10 }, flags = { light = true },
		jobs = { stone = 0.20 } },
	{ id = "rocon", num = 2, name = "Rocon", zone = 2, shape = "rock", mythic = false, bait = "root", weight = 1,
		color = Color3.fromRGB(140, 125, 110), color2 = Color3.fromRGB(95, 85, 75),
		companion = "Mayor fuerza en minerales duros.", work = "Extractor de piedra.",
		bonus = { mineDamage = 0.12 }, flags = {},
		jobs = { stone = 0.25 } },
	{ id = "chispa", num = 3, name = "Chispa", zone = 2, shape = "spark", mythic = false, bait = "berry", weight = 1,
		color = Color3.fromRGB(255, 220, 60), color2 = Color3.fromRGB(80, 160, 255),
		companion = "Detecta cobre y mecanismos electricos.", work = "Extractor de cobre; apoyo en alquimia.",
		bonus = { copperFind = 0.15 }, flags = {},
		jobs = { copper = 0.18 } },
	{ id = "talpa", num = 4, name = "Talpa", zone = 3, shape = "mole", mythic = false, bait = "root", weight = 1,
		color = Color3.fromRGB(150, 105, 75), color2 = Color3.fromRGB(240, 180, 170),
		companion = "Mejora el rendimiento al minar.", work = "Extractor de hierro.",
		bonus = { oreYield = 0.08 }, flags = {},
		jobs = { iron = 0.12 } },
	{ id = "zuri", num = 5, name = "Zuri", zone = 3, shape = "crystal", mythic = false, bait = "root", weight = 0.8,
		color = Color3.fromRGB(60, 210, 200), color2 = Color3.fromRGB(170, 255, 250),
		companion = "Detecta vetas raras de Zuarita.", work = "Produce polvo de Zuarita.",
		bonus = { rareFind = 0.05 }, flags = {},
		jobs = { zuarita = 0.05 } },
	{ id = "musguito", num = 6, name = "Musguito", zone = 4, shape = "moss", mythic = false, bait = "flower", weight = 1,
		color = Color3.fromRGB(100, 180, 80), color2 = Color3.fromRGB(60, 120, 50),
		companion = "Activa raices y facilita desafios naturales.", work = "Riega cultivos y acelera el crecimiento.",
		bonus = { growth = 0.15 }, flags = { roots = true },
		jobs = { garden = 0.25 } },
	{ id = "flamin", num = 7, name = "Flamin", zone = 4, shape = "flame", mythic = false, bait = "flower", weight = 1,
		color = Color3.fromRGB(255, 120, 50), color2 = Color3.fromRGB(255, 220, 90),
		companion = "Derrite obstaculos y supera el calor.", work = "Ayuda en herreria: cobre e hierro.",
		bonus = { mineDamage = 0.08 }, flags = { meltIce = true },
		jobs = { copper = 0.12, iron = 0.08 } },
	{ id = "nox", num = 8, name = "Nox", zone = 3, shape = "night", mythic = true, bait = "root", weight = 1,
		color = Color3.fromRGB(70, 50, 120), color2 = Color3.fromRGB(150, 120, 255),
		companion = "Vision nocturna y secretos en cuevas.", work = "Produce cristal lunar.",
		bonus = { captureEase = 0.03 }, flags = { nightVision = true },
		jobs = { moon = 0.06 } },
	{ id = "florin", num = 9, name = "Florin", zone = 4, shape = "flower", mythic = false, bait = "flower", weight = 1,
		color = Color3.fromRGB(255, 150, 200), color2 = Color3.fromRGB(255, 240, 120),
		companion = "Mejora el rendimiento de cebos vegetales.", work = "Cosecha cultivos y guarda alimentos.",
		bonus = { baitPower = 0.10 }, flags = {},
		jobs = { garden = 0.25 } },
	{ id = "brumi", num = 10, name = "Brumi", zone = 4, shape = "mist", mythic = false, bait = "berry", weight = 1,
		color = Color3.fromRGB(190, 220, 255), color2 = Color3.fromRGB(255, 255, 255),
		companion = "Reduce la dificultad de capturas salvajes.", work = "Transporta materiales: resiembra el huerto.",
		bonus = { captureEase = 0.04 }, flags = {},
		jobs = { garden = 0.25 } },
	{ id = "venti", num = 11, name = "Venti", zone = 5, shape = "wind", mythic = false, bait = "star", weight = 1,
		color = Color3.fromRGB(200, 255, 230), color2 = Color3.fromRGB(120, 220, 200),
		companion = "Permite planear distancias cortas.", work = "Produce cuarzo aereo.",
		bonus = { jump = 0.15 }, flags = { glide = true },
		jobs = { nexus = 0.04 }, product = "cuarzo" },
	{ id = "prisma", num = 12, name = "Prisma", zone = 5, shape = "prism", mythic = false, bait = "star", weight = 1,
		color = Color3.fromRGB(240, 200, 255), color2 = Color3.fromRGB(120, 255, 255),
		companion = "Revela simbolos y luz oculta.", work = "Produce fragmentos prismaticos.",
		bonus = { essenceFind = 0.05 }, flags = { reveal = true },
		jobs = { nexus = 0.03 }, product = "prisma" },
	{ id = "gravix", num = 13, name = "Gravix", zone = 5, shape = "gravity", mythic = false, bait = "star", weight = 1,
		color = Color3.fromRGB(90, 70, 160), color2 = Color3.fromRGB(255, 200, 80),
		companion = "Manipula mecanismos gravitacionales.", work = "Produce fragmentos gravitacionales.",
		bonus = { mineDamage = 0.10 }, flags = { gravity = true },
		jobs = { nexus = 0.03 }, product = "gravedad" },
	{ id = "astrael", num = 14, name = "Astrael", zone = 5, shape = "astral", mythic = false, bait = "star", weight = 0.7,
		color = Color3.fromRGB(40, 60, 140), color2 = Color3.fromRGB(255, 250, 180),
		companion = "Localiza anomalias y rescates secretos.", work = "Produce energia astral.",
		bonus = { essenceFind = 0.08 }, flags = { anomaly = true },
		jobs = { nexus = 0.02 }, product = "astral" },
	{ id = "eclipsar", num = 15, name = "Eclipsar", zone = 5, shape = "eclipse", mythic = true, bait = "star", weight = 0.35,
		color = Color3.fromRGB(25, 20, 35), color2 = Color3.fromRGB(255, 180, 60),
		companion = "Resonancia temporal de varios beneficios.", work = "Produce fragmentos del eclipse.",
		bonus = { mineSpeed = 0.06, captureEase = 0.02, oreYield = 0.04, growth = 0.06 }, flags = { light = true },
		jobs = { nexus = 0.01 }, product = "eclipse" },
}

PetCatalog.ById = {}
for _, s in ipairs(PetCatalog.Species) do
	PetCatalog.ById[s.id] = s
end

function PetCatalog.Get(speciesId)
	return PetCatalog.ById[speciesId]
end

function PetCatalog.Rarity(rarityId)
	return PetCatalog.RarityById[rarityId]
end

-- Clave de pila: "especie:rareza" (normal) o "especie:rareza:shiny" (Shiny).
-- Shiny es una dimension aparte de la rareza: "lumi:common:shiny" y "lumi:common"
-- son pilas distintas. Las claves antiguas (sin sufijo) siguen siendo normales.
PetCatalog.ShinySuffix = "shiny"

function PetCatalog.Key(speciesId, rarityId, shiny)
	if shiny then
		return speciesId .. ":" .. rarityId .. ":" .. PetCatalog.ShinySuffix
	end
	return speciesId .. ":" .. rarityId
end

-- Devuelve especie, rareza, shiny (o nil si la clave no es valida)
function PetCatalog.ParseKey(key)
	if type(key) ~= "string" then
		return nil, nil, nil
	end
	local s, r, rest = string.match(key, "^(%a+):(%a+)(.*)$")
	local shiny
	if rest == "" then
		shiny = false
	elseif rest == ":" .. PetCatalog.ShinySuffix then
		shiny = true
	else
		return nil, nil, nil
	end
	if s and PetCatalog.ById[s] and PetCatalog.RarityById[r] then
		if r == "mythic" and not PetCatalog.ById[s].mythic then
			return nil, nil, nil
		end
		return s, r, shiny
	end
	return nil, nil, nil
end

-- Clave base (sin Shiny) para la coleccion de 63 variantes
function PetCatalog.BaseKey(key)
	local s, r = PetCatalog.ParseKey(key)
	return s and PetCatalog.Key(s, r) or nil
end

-- Rarezas disponibles para una especie (4 o 5 si tiene mitico)
function PetCatalog.RaritiesFor(speciesId)
	local sp = PetCatalog.ById[speciesId]
	local list = {}
	for _, r in ipairs(PetCatalog.Rarities) do
		if r.id ~= "mythic" or (sp and sp.mythic) then
			table.insert(list, r)
		end
	end
	return list
end

function PetCatalog.SpeciesInZone(zone)
	local list = {}
	for _, s in ipairs(PetCatalog.Species) do
		if s.zone == zone then
			table.insert(list, s)
		end
	end
	return list
end

-- 15 x 4 + 3 miticos = 63 variantes
function PetCatalog.AllVariants()
	local list = {}
	for _, s in ipairs(PetCatalog.Species) do
		for _, r in ipairs(PetCatalog.RaritiesFor(s.id)) do
			table.insert(list, PetCatalog.Key(s.id, r.id))
		end
	end
	return list
end

-- Producto que genera una especie en una estacion
function PetCatalog.ProductFor(speciesId, stationId)
	local sp = PetCatalog.ById[speciesId]
	if not sp then
		return nil
	end
	if stationId == "nexus" then
		return sp.product
	end
	local st = PetCatalog.Stations[stationId]
	return st and st.product
end

-- Nombre de fusion: Lumi + Talpa = "Lumital"
function PetCatalog.FusionName(a, b)
	local sa, sb = PetCatalog.ById[a], PetCatalog.ById[b]
	if not sa or not sb then
		return "Fusion"
	end
	return sa.name .. string.lower(string.sub(sb.name, 1, 3))
end

return PetCatalog
