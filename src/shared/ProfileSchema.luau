-- ProfileSchema: forma del perfil persistente, valores por defecto y migraciones.
-- (GDD 17, "Modelo conceptual minimo de datos")

local Config = require(script.Parent.Config)
local PetCatalog = require(script.Parent.PetCatalog)

local ProfileSchema = {}

local STATIONS = { "stone", "copper", "iron", "moon", "zuarita", "nexus", "garden" }

function ProfileSchema.Default()
	local stations = {}
	for _, id in ipairs(STATIONS) do
		stations[id] = { level = 0, workers = {}, buffer = {}, updatedAt = 0 }
	end
	return {
		schemaVersion = Config.SchemaVersion,
		createdAt = 0,
		lastSave = 0,
		playTime = 0,

		res = { backpack = {}, storage = {} },
		tools = { pick = 1, vacuum = 1 },
		buildings = { sanctuary = 1, forge = 1, petStorage = 0, garden = 0, alchemy = 0, bait = 0, fusionLab = 0 },
		decorations = {},
		stations = stations,

		zones = { unlocked = 1, parkour = {} },
		dex = {}, -- ["lumi:common"] = true
		captured = {}, -- [speciesId] = total capturados
		story = { visitedMines = false, finished = false },

		-- PETs: pilas agregadas (ordinarios) + individuos con identidad propia
		stacks = { tank = {}, storage = {} },
		units = {}, -- [id] = { id, s, r, lv, st = "free"|"equipped"|"working"|"fused", lock, loc = "tank"|"storage" }
		nextUnitId = 1,
		team = {}, -- lista ordenada de ids (1 = principal)

		essence = {}, -- [speciesId] = entero >= 0

		garden = { plots = {} }, -- [i] = { crop = "baya", plantedAt = t, progress = 0 }
		items = { baits = {}, potions = {} },
		activeBait = nil,
		effects = {}, -- [potionId] = expiraEn (os.time)

		fusion = { slots = {}, discovered = {}, nextId = 1 },
		cooldowns = {},

		paid = { backpack = 0, tank = 0 },
		vip = false,
		cosmetics = {},
		receipts = {}, -- [receiptId] = true
		receiptOrder = {},

		raidsJoined = 0,

		-- v2: Mundo PET continuo
		world = {
			beacons = {}, -- ["z1"] = true: faro de viaje rapido activado
			visited = {}, -- ["z1"] = true: zona visitada al menos una vez
			npc = {}, -- ["guide"] = true: dialogos vistos
		},
	}
end

-- Rellena claves faltantes de forma recursiva (sin pisar datos existentes).
local function reconcile(target, template)
	for k, v in pairs(template) do
		if target[k] == nil then
			if type(v) == "table" then
				local copy = {}
				reconcile(copy, v)
				target[k] = copy
			else
				target[k] = v
			end
		elseif type(v) == "table" and type(target[k]) == "table" then
			-- solo reconciliamos tablas "estructurales" (no listas de datos)
			if next(v) ~= nil then
				reconcile(target[k], v)
			end
		end
	end
end

function ProfileSchema.Migrate(profile)
	if type(profile) ~= "table" then
		return ProfileSchema.Default()
	end
	local v = tonumber(profile.schemaVersion) or 0
	if v < 1 then
		profile.schemaVersion = 1
	end
	-- Rellena campos nuevos sin tocar los existentes
	reconcile(profile, ProfileSchema.Default())
	if v < 2 then
		-- v1 -> v2: solo AGREGA datos. Las zonas que el jugador ya visito
		-- (parkour completado o especies de esa zona capturadas) quedan con
		-- su faro activo para no hacerle repetir el camino.
		local unlocked = tonumber(profile.zones.unlocked) or 1
		for _, sp in ipairs(PetCatalog.Species) do
			if (profile.captured[sp.id] or 0) > 0 and sp.zone <= unlocked then
				profile.world.visited["z" .. sp.zone] = true
				profile.world.beacons["z" .. sp.zone] = true
			end
		end
		for k = 1, 5 do
			if profile.zones.parkour["z" .. k] and k <= unlocked then
				profile.world.visited["z" .. k] = true
				profile.world.beacons["z" .. k] = true
			end
		end
	end
	profile.schemaVersion = Config.SchemaVersion
	return profile
end

function ProfileSchema.DeepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = ProfileSchema.DeepCopy(v)
	end
	return out
end

return ProfileSchema
