-- WorldConfig: configuracion de datos del mundo, independiente por region.
-- (GDD 1.1: Santuario + Mundo PET con las cinco Minas de Zuar integradas)
--
-- Cada region del Mundo PET es un bloque de datos. Para ampliar una zona o
-- cambiar su balance, edita este archivo; no hace falta tocar la logica.
--
--   requirements: lista de condiciones (ver WorldConfig.RequirementTypes).
--   mine.chances: probabilidad (0..1) de que cada recurso aparezca en un ciclo
--     de generacion. NO son excluyentes ni deben sumar 1: en la Zona 5 pueden
--     aparecer piedra, cobre, hierro, cristal y zuarita a la vez.

local WorldConfig = {}

WorldConfig.Version = 2

-- Tipos de requisito soportados (evaluados en Shared/Progression):
--   { type = "pick", level = n }                Pico de nivel >= n
--   { type = "vacuum", level = n }              Succionador de nivel >= n
--   { type = "sanctuary", level = n }           Santuario de nivel >= n
--   { type = "building", id = "garden", level = n }  Construccion de nivel >= n
--   { type = "station", id = "stone", level = n }    Extractor concreto de nivel >= n
--   { type = "anyStation" }                     Cualquier extractor construido
--   { type = "speciesCaptured", maxZone = n }   Haber capturado todas las especies de las zonas 1..n
--   { type = "zone", id = n }                   Tener desbloqueada la zona n (para futuras condiciones)
--   (Para agregar un tipo nuevo: añadelo aqui y en Progression.Evaluate.)

WorldConfig.Regions = {
	{
		id = 1,
		name = "Bosque de Lumi",
		legacyName = "Praderas Luminosas",
		activity = "Bosque tutorial: captura tus primeros Lumi y explora la primera Mina de Zuar.",
		color = Color3.fromRGB(150, 220, 110),
		material = "petalo",
		requirements = {},
		mine = {
			name = "Mina de Zuar I · Galeria del Musgo",
			size = 1,
			slots = 14, -- vetas por ciclo (por jugador)
			cycle = 120, -- segundos entre ciclos de generacion
			chances = { piedra = 1.00, cobre = 0.15 },
		},
		challenge = "Parkour tutorial con checkpoints (opcional, con cofre).",
	},
	{
		id = 2,
		name = "Valle de los Engranajes",
		activity = "Bosque avanzado entre ruinas mecanicas: Rocon y Chispa.",
		color = Color3.fromRGB(200, 170, 110),
		material = "engranaje",
		-- GDD: pico de piedra + santuario 2. Agregado en v1.1: extractor de piedra.
		requirements = {
			{ type = "pick", level = 2 },
			{ type = "sanctuary", level = 2 },
			{ type = "station", id = "stone", level = 1 },
		},
		mine = {
			name = "Mina de Zuar II · Tuneles de Cobre",
			size = 1.2,
			slots = 16,
			cycle = 120,
			chances = { piedra = 1.00, cobre = 0.40, hierro = 0.15 },
		},
		challenge = "Plataformas moviles (opcional, con cofre).",
	},
	{
		id = 3,
		name = "Cavernas Olvidadas",
		activity = "Region intermedia de cuevas y hongos: Talpa, Nox y Zuri. Desbloquea huerto, alquimia y cebos.",
		color = Color3.fromRGB(90, 80, 120),
		material = "hongo",
		-- GDD: pico de cobre + primer extractor (queda cubierto por la Zona 2; se mantiene como respaldo).
		requirements = {
			{ type = "pick", level = 3 },
			{ type = "anyStation" },
		},
		mine = {
			name = "Mina de Zuar III · Grieta de Cristal",
			size = 1.4,
			slots = 18,
			cycle = 120,
			chances = { piedra = 1.00, cobre = 0.65, hierro = 0.40, lunar = 0.10 },
		},
		challenge = "Tunel oscuro (opcional, con cofre). Nox da vision nocturna.",
	},
	{
		id = 4,
		name = "Jardines Elementales",
		activity = "Region avanzada de jardines y elementos: Musguito, Flamin, Florin y Brumi.",
		color = Color3.fromRGB(120, 200, 160),
		material = "elemental",
		-- GDD: pico de hierro + huerto nivel 2 + succionador mejorado.
		requirements = {
			{ type = "pick", level = 4 },
			{ type = "building", id = "garden", level = 2 },
			{ type = "vacuum", level = 2 },
		},
		mine = {
			name = "Mina de Zuar IV · Caverna Elemental",
			size = 1.6,
			slots = 20,
			cycle = 120,
			chances = { piedra = 1.00, cobre = 0.85, hierro = 0.75, lunar = 0.40, zuarita = 0.10 },
		},
		challenge = "Trampolines y muros de hielo (opcional, con cofre). Flamin derrite el hielo.",
	},
	{
		id = 5,
		name = "Templo del Eclipse",
		activity = "Region final: Venti, Prisma, Gravix, Astrael y Eclipsar. La Gran Mina de Zuar.",
		color = Color3.fromRGB(110, 90, 170),
		material = "estelar",
		-- GDD: equipo avanzado + santuario desarrollado + misiones previas.
		requirements = {
			{ type = "vacuum", level = 3 },
			{ type = "sanctuary", level = 4 },
			{ type = "speciesCaptured", maxZone = 4 },
		},
		mine = {
			name = "Gran Mina de Zuar",
			size = 2.2,
			slots = 28,
			cycle = 120,
			chances = { piedra = 1.00, cobre = 1.00, hierro = 1.00, lunar = 0.75, zuarita = 0.25 },
		},
		challenge = "Gravedad baja y plataformas ocultas (opcional, con cofre). Prisma las revela.",
	},
}

-- Fuentes de recursos fuera de las minas (para validar que la progresion no
-- tenga dependencias circulares y para explicar al jugador de donde sale cada cosa).
--   zone: primera zona donde se puede obtener. pick: pico minimo.
--   building / station: construccion necesaria. species: especie trabajadora.
WorldConfig.ResourceSources = {
	madera = { zone = 1, where = "Arboles del santuario" },
	petalo = { zone = 1, where = "Flores luminosas de la Zona 1" },
	engranaje = { zone = 2, where = "Chatarra del Valle de los Engranajes" },
	hongo = { zone = 3, where = "Hongos de las Cavernas Olvidadas" },
	elemental = { zone = 4, where = "Nucleos de los Jardines Elementales" },
	estelar = { zone = 5, where = "Polvo estelar del Templo del Eclipse" },
	baya = { zone = 3, building = "garden", where = "Huerto" },
	raiz = { zone = 3, building = "garden", where = "Huerto" },
	flor = { zone = 3, building = "garden", where = "Huerto" },
	semilla = { zone = 1, where = "Arboles del santuario y cosechas" },
	polvo = { zone = 3, species = "zuri", where = "Zuri (compañero en minas o trabajador en la refineria)" },
	cuarzo = { zone = 5, station = "nexus", species = "venti", where = "Venti en el Nexo dimensional" },
	prisma = { zone = 5, station = "nexus", species = "prisma", where = "Prisma en el Nexo dimensional" },
	gravedad = { zone = 5, station = "nexus", species = "gravix", where = "Gravix en el Nexo dimensional" },
	astral = { zone = 5, station = "nexus", species = "astrael", where = "Astrael en el Nexo dimensional" },
	eclipse = { zone = 5, station = "nexus", species = "eclipsar", where = "Eclipsar en el Nexo dimensional" },
}

-- Mineral -> tipo de nodo (Items.Nodes) para las minas
WorldConfig.MineralNode = {
	piedra = "stone",
	cobre = "copper",
	hierro = "iron",
	lunar = "lunar",
	zuarita = "zuarita",
}

-- Faros de viaje rapido (uno por zona; se activan al visitarla por primera vez)
WorldConfig.Beacons = {
	enabled = true,
	cooldown = 5, -- segundos entre viajes
}

-- Regalos aleatorios por el Mundo PET ---------------------------------------------------
-- Son privados por jugador (como los PETs salvajes) y poco frecuentes. Cada
-- `checkInterval` segundos, si el jugador esta en una zona, se tira el dado con
-- la probabilidad de esa zona. Las recompensas salen de una tabla ponderada que
-- se puede cambiar sin tocar el codigo.
WorldConfig.Gifts = {
	enabled = true,
	checkInterval = 45, -- segundos entre tiradas por jugador
	maxActive = 1, -- regalos sin abrir a la vez por jugador (una zona puede bajarlo con maxActive)
	maxPerHour = 4, -- tope de regalos que pueden aparecer por jugador en una hora (evita abuso)
	lifetime = 240, -- segundos antes de desaparecer
	claimDistance = 14,
	byZone = {
		-- chance: probabilidad por tirada. rewards: lista ponderada.
		--   kind = "resource" (id, min, max) | "essence" (de una especie de la zona, min, max)
		--   kind = "potion" / "bait" (id, n)
		[1] = { chance = 0.15, rewards = {
			{ weight = 45, kind = "resource", id = "petalo", min = 3, max = 6 },
			{ weight = 30, kind = "resource", id = "madera", min = 10, max = 20 },
			{ weight = 20, kind = "essence", min = 5, max = 12 },
			{ weight = 5, kind = "potion", id = "fortuna", n = 1 },
		} },
		[2] = { chance = 0.14, rewards = {
			{ weight = 40, kind = "resource", id = "engranaje", min = 3, max = 6 },
			{ weight = 30, kind = "resource", id = "cobre", min = 6, max = 12 },
			{ weight = 25, kind = "essence", min = 8, max = 16 },
			{ weight = 5, kind = "potion", id = "impulso", n = 1 },
		} },
		[3] = { chance = 0.13, rewards = {
			{ weight = 40, kind = "resource", id = "hongo", min = 3, max = 6 },
			{ weight = 30, kind = "resource", id = "hierro", min = 5, max = 10 },
			{ weight = 25, kind = "essence", min = 10, max = 20 },
			{ weight = 5, kind = "potion", id = "instinto", n = 1 },
		} },
		[4] = { chance = 0.12, rewards = {
			{ weight = 40, kind = "resource", id = "elemental", min = 2, max = 5 },
			{ weight = 30, kind = "resource", id = "lunar", min = 3, max = 6 },
			{ weight = 25, kind = "essence", min = 12, max = 24 },
			{ weight = 5, kind = "potion", id = "succion", n = 1 },
		} },
		[5] = { chance = 0.12, rewards = {
			{ weight = 40, kind = "resource", id = "estelar", min = 2, max = 5 },
			{ weight = 30, kind = "resource", id = "zuarita", min = 1, max = 3 },
			{ weight = 25, kind = "essence", min = 15, max = 30 },
			{ weight = 5, kind = "potion", id = "fortuna", n = 2 },
		} },
	},
}

-- Comerciante del campamento: intercambio de materiales (sin moneda) ----------------------
-- give: lo que entrega el jugador. get: lo que recibe (kind = resource | bait | potion).
-- zone: zona minima desbloqueada para que el intercambio este disponible (respeta el
-- GDD: los cultivos, cebos e ingredientes avanzados llegan con la Zona 3).
-- Las tasas son deliberadamente menos convenientes que producir uno mismo.
WorldConfig.Trades = {
	maxPerTrade = 10, -- multiplicador maximo por operacion
	merchantRange = 26, -- distancia maxima al comerciante
	list = {
		{ id = "semillas", name = "Semillas", zone = 1, give = { madera = 15, piedra = 5 }, get = { kind = "resource", id = "semilla", n = 3 } },
		{ id = "petalos", name = "Petalos luminosos", zone = 1, give = { piedra = 20 }, get = { kind = "resource", id = "petalo", n = 2 } },
		{ id = "engranajes", name = "Engranajes antiguos", zone = 2, give = { cobre = 15 }, get = { kind = "resource", id = "engranaje", n = 2 } },
		{ id = "hongos", name = "Hongos sombrios", zone = 3, give = { hierro = 12 }, get = { kind = "resource", id = "hongo", n = 2 } },
		{ id = "bayas", name = "Bayas", zone = 3, give = { semilla = 2, madera = 10 }, get = { kind = "resource", id = "baya", n = 2 } },
		{ id = "raices", name = "Raices", zone = 3, give = { semilla = 2, piedra = 10 }, get = { kind = "resource", id = "raiz", n = 2 } },
		{ id = "flores", name = "Flores", zone = 3, give = { semilla = 2, petalo = 4 }, get = { kind = "resource", id = "flor", n = 2 } },
		{ id = "cebo_bayas", name = "Cebo de bayas", zone = 3, give = { baya = 4, petalo = 2 }, get = { kind = "bait", id = "berry", n = 1 } },
		{ id = "cebo_raices", name = "Cebo de raices", zone = 3, give = { raiz = 4, hongo = 2 }, get = { kind = "bait", id = "root", n = 1 } },
		{ id = "cebo_floral", name = "Cebo floral", zone = 4, give = { flor = 4, elemental = 2 }, get = { kind = "bait", id = "flower", n = 1 } },
		{ id = "chispas", name = "Chispas elementales", zone = 4, give = { lunar = 6 }, get = { kind = "resource", id = "elemental", n = 2 } },
	},
}
WorldConfig.TradeById = {}
for _, t in ipairs(WorldConfig.Trades.list) do
	WorldConfig.TradeById[t.id] = t
end

function WorldConfig.Region(id)
	return WorldConfig.Regions[id]
end

-- Primera zona cuya mina puede generar un mineral
function WorldConfig.FirstMineZone(resource)
	for _, r in ipairs(WorldConfig.Regions) do
		if (r.mine.chances[resource] or 0) > 0 then
			return r.id
		end
	end
	return nil
end

return WorldConfig
