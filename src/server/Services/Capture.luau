-- Capture (CaptureService): apariciones individuales por jugador, intentos de
-- captura con el Succionador de Resonancia, cebos y validaciones.
-- (GDD 06 y 23)
--  A) Aparicion/rareza: especie y variante (pocion Fortuna modifica la rareza).
--  A2) Shiny: tirada INDEPENDIENTE de la rareza (Config.Shiny.chance), decidida
--      aqui en el servidor al generar el encuentro. El cliente no puede pedirla.
--  B) Exito de captura: succionador, resistencia, cebo y habilidades.
-- El servidor es dueño de cada encuentro; el cliente solo lo dibuja.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)

local Capture = {}
local S

local enc = {} -- [player] = { zone, list = {[id]=e}, nextRefresh, counter, capturing = {id, t0} }
local rng = Random.new()
local forceShiny = {} -- [player] = true: solo herramientas de Studio (DevTools)

-- Tirada Shiny independiente de la especie y de la rareza
function Capture.RollShiny(chance, randomGen)
	local cfg = Config.Shiny
	if not cfg or not cfg.enabled then
		return false
	end
	return (randomGen or rng):NextNumber() < (chance or cfg.chance)
end

-- Solo para pruebas en Studio (DevTools lo protege)
function Capture.SetForceShiny(player, on)
	forceShiny[player] = on and true or nil
end

-- Sorteo de rareza. luck multiplica todas las rarezas superiores a comun.
function Capture.RollRarity(speciesId, luck, weightsOverride)
	local list = PetCatalog.RaritiesFor(speciesId)
	local weights = {}
	local total = 0
	local nonCommon = 0
	for _, r in ipairs(list) do
		if r.id ~= "common" then
			local w = (weightsOverride and weightsOverride[r.id] or r.weight) * (luck or 1)
			weights[r.id] = w
			nonCommon = nonCommon + w
		end
	end
	local commonW = weightsOverride and weightsOverride.common or 100 - nonCommon
	weights.common = math.max(0, commonW)
	for _, r in ipairs(list) do
		total = total + weights[r.id]
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for i = #list, 1, -1 do -- de mas rara a mas comun
		local r = list[i]
		acc = acc + weights[r.id]
		if roll < acc then
			return r.id
		end
	end
	return "common"
end

local function pickSpecies(zone, profile)
	local list = PetCatalog.SpeciesInZone(zone)
	local favBait = nil
	if profile.activeBait and (profile.items.baits[profile.activeBait] or 0) > 0 then
		favBait = profile.activeBait
	end
	local total = 0
	local ws = {}
	for i, sp in ipairs(list) do
		local w = sp.weight
		if favBait and sp.bait == favBait then
			w = w * 2 -- el cebo atrae a sus especies favoritas
		end
		ws[i] = w
		total = total + w
	end
	local roll = rng:NextNumber() * total
	for i, sp in ipairs(list) do
		roll = roll - ws[i]
		if roll <= 0 then
			return sp.id
		end
	end
	return list[#list].id
end

local function newEncounter(player, data, profile)
	local region = S.World.SpawnRegions[data.zone]
	data.counter = data.counter + 1
	local id = "e" .. data.counter
	local s = pickSpecies(data.zone, profile)
	local agg = Stats.Aggregate(profile, os.time())
	local r = Capture.RollRarity(s, agg.luck)
	local pos
	if region.clearings and #region.clearings > 0 then
		-- claros del bosque: puntos libres de arboles, rocas y obstaculos
		-- 60%: uno de los dos claros mas cercanos al jugador (se encuentran PETs al
		-- explorar sin aumentar la cantidad de entidades activas)
		local c = region.clearings[rng:NextInteger(1, #region.clearings)]
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and #region.clearings > 2 and rng:NextNumber() < 0.6 then
			local sorted = {}
			for _, cl in ipairs(region.clearings) do
				table.insert(sorted, cl)
			end
			local p = hrp.Position
			table.sort(sorted, function(a, b)
				return (a.center - p).Magnitude < (b.center - p).Magnitude
			end)
			c = sorted[rng:NextInteger(1, 2)]
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * c.r * 0.85
		pos = c.center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
	else
		pos = region.center + Vector3.new(rng:NextNumber(-region.sizeX / 2, region.sizeX / 2), 0, rng:NextNumber(-region.sizeZ / 2, region.sizeZ / 2))
	end
	local sh = forceShiny[player] == true or Capture.RollShiny()
	local e = { id = id, s = s, r = r, sh = sh or nil, pos = Vector3.new(pos.X, 0, pos.Z), born = os.time() }
	data.list[id] = e
	return e
end

local function serialize(data)
	local out = {}
	for _, e in pairs(data.list) do
		table.insert(out, { id = e.id, s = e.s, r = e.r, sh = e.sh, x = e.pos.X, z = e.pos.Z })
	end
	return out
end

local function sendAll(player, data)
	S.Net.Fire(player, "Encounters", data and data.zone or nil, data and serialize(data) or {})
end

local function fill(player, data, profile)
	local target = data.target
	local n = 0
	for _ in pairs(data.list) do
		n = n + 1
	end
	while n < target do
		newEncounter(player, data, profile)
		n = n + 1
	end
end

-- Llamado por Progress cuando cambia el area del jugador
function Capture.OnAreaChanged(player, area)
	local zone = S.World.ZoneOfArea(area)
	local profile = S.Data.Get(player)
	if not zone or not profile then
		if enc[player] then
			enc[player] = nil
			sendAll(player, nil)
		end
		return
	end
	if enc[player] and enc[player].zone == zone then
		return
	end
	local data = { zone = zone, list = {}, counter = 0, target = rng:NextInteger(Config.SpawnMin, Config.SpawnMax),
		nextRefresh = os.time() + Config.SpawnRefresh }
	enc[player] = data
	fill(player, data, profile)
	sendAll(player, data)
end

local function refresh(player, data)
	local profile = S.Data.Get(player)
	if not profile then
		return
	end
	local now = os.time()
	for id, e in pairs(data.list) do
		local busy = data.capturing and data.capturing.id == id
		if not busy and now - e.born >= Config.SpawnRefresh then
			data.list[id] = nil
		end
	end
	data.target = rng:NextInteger(Config.SpawnMin, Config.SpawnMax)
	fill(player, data, profile)
	data.nextRefresh = now + Config.SpawnRefresh
	sendAll(player, data)
end

local function result(ok, msg, extra)
	local r = extra or {}
	r.ok = ok
	r.msg = msg
	return r
end

local function distanceOk(player, e, range)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local p = hrp.Position
	return (Vector3.new(p.X, 0, p.Z) - e.pos).Magnitude <= Config.EncounterRadius + range
end

function Capture.Init(services)
	S = services
	local Net = S.Net

	Net.Register("captureBegin", function(player, profile, payload)
		local data = enc[player]
		local e = data and type(payload.id) == "string" and data.list[payload.id]
		if not e then
			return result(false, "Ese PET ya no esta aqui.")
		end
		if player:GetAttribute("Area") ~= "z" .. data.zone then
			return result(false, "Estas fuera de la zona.")
		end
		if not PetStore.CanAdd(profile, "tank", PetCatalog.Key(e.s, e.r, e.sh), 1) then
			return result(false, "¡Tanque de PETs lleno! Vuelve al Hogar y deposita en el Almacen.")
		end
		local agg = Stats.Aggregate(profile, os.time())
		local params = Stats.CaptureParams(agg, profile, e.s, e.r)
		if not distanceOk(player, e, params.range) then
			return result(false, "Acercate mas al PET.")
		end
		data.capturing = { id = e.id, t0 = os.clock(), time = params.time }
		return result(true, nil, { time = params.time, chance = params.chance })
	end)

	Net.Register("captureCancel", function(player)
		local data = enc[player]
		if data then
			data.capturing = nil
		end
		return result(true)
	end)

	Net.Register("captureFinish", function(player, profile, payload)
		local data = enc[player]
		local cap = data and data.capturing
		if not cap or cap.id ~= payload.id then
			return result(false, "No estabas capturando ese PET.")
		end
		data.capturing = nil
		local e = data.list[cap.id]
		if not e then
			return result(false, "El PET escapo.")
		end
		local elapsed = os.clock() - cap.t0
		if elapsed < cap.time * 0.8 - 0.25 then
			return result(false, "Captura interrumpida.")
		end
		local now = os.time()
		local agg = Stats.Aggregate(profile, now)
		local params = Stats.CaptureParams(agg, profile, e.s, e.r)
		if not distanceOk(player, e, params.range) then
			return result(false, "El PET quedo fuera de alcance.")
		end
		local key = PetCatalog.Key(e.s, e.r, e.sh) -- Shiny: solo lo que decidio el servidor
		if not PetStore.CanAdd(profile, "tank", key, 1) then
			return result(false, "¡Tanque de PETs lleno!")
		end
		-- consumir cebo activo
		local bait = profile.activeBait
		if bait and (profile.items.baits[bait] or 0) > 0 then
			profile.items.baits[bait] = profile.items.baits[bait] - 1
			if profile.items.baits[bait] <= 0 then
				profile.items.baits[bait] = nil
				profile.activeBait = nil
				S.Net.Notify(player, "Se acabo tu " .. Items.Baits[bait].name .. ".", "info")
			end
		end
		local sp = PetCatalog.Get(e.s)
		local rar = PetCatalog.Rarity(e.r)
		if rng:NextNumber() <= params.chance then
			data.list[e.id] = nil
			local first = (profile.captured[e.s] or 0) == 0
			local shiny = e.sh == true
			PetStore.Give(profile, e.s, e.r, false, shiny)
			PetStore.Register(profile, e.s, e.r, shiny)
			sendAll(player, data)
			if shiny then
				for _, other in ipairs(Players:GetPlayers()) do
					S.Net.Notify(other, "✨ " .. player.DisplayName .. " rescato un " .. sp.name .. " " .. rar.name .. " SHINY!", "rare")
				end
			elseif e.r == "mythic" or e.r == "legendary" then
				for _, other in ipairs(Players:GetPlayers()) do
					S.Net.Notify(other, "🌟 " .. player.DisplayName .. " rescato un " .. sp.name .. " " .. rar.name .. "!", "rare")
				end
			end
			if e.s == "eclipsar" and not profile.story.finished then
				profile.story.finished = true
				for _, other in ipairs(Players:GetPlayers()) do
					S.Net.Notify(other, "🌑 " .. player.DisplayName .. " alcanzo a Eclipsar y completo el Rescate Dimensional!", "rare")
				end
			end
			S.Progress.CheckUnlocks(player, profile)
			return result(true, "¡Capturaste un " .. sp.name .. " " .. rar.name .. (shiny and " ✨ Shiny" or "") .. "!",
				{ captured = true, s = e.s, r = e.r, shiny = shiny, first = first })
		end
		local escaped = rng:NextNumber() < Config.EscapeChanceOnFail
		if escaped then
			data.list[e.id] = nil
			sendAll(player, data)
		end
		return result(true, escaped and (sp.name .. " escapo. ¡Sigue intentando!") or (sp.name .. " resistio. ¡Intenta otra vez!"),
			{ captured = false, escaped = escaped })
	end)
end

function Capture.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for player, data in pairs(enc) do
				if player.Parent and now >= data.nextRefresh then
					refresh(player, data)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		enc[player] = nil
		forceShiny[player] = nil
	end)
end

function Capture.Resend(player)
	sendAll(player, enc[player])
end

return Capture
