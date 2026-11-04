-- Raid (RaidService): Incursiones Dimensionales cooperativas, aprox. una por hora.
-- Fases: anuncio -> barrera (disparo de resonancia) -> pilares + ondas ->
-- resonancia final (estabilizar en el circulo) -> recompensa privada.
-- La contribucion mezcla disparos, objetivos y apoyo, no solo daño bruto.
-- (GDD 11)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PetCatalog = require(Shared.PetCatalog)
local PetModels = require(Shared.PetModels)
local PetStore = require(Shared.PetStore)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)
local Progression = require(Shared.Progression)

local Raid = {}
local S

local TIERS = {
	{ id = "bronze", name = "Bronce", essence = 50,
		weights = { common = 60, rare = 30, epic = 8, legendary = 1.8, mythic = 0.2 } },
	{ id = "silver", name = "Plata", essence = 150,
		weights = { common = 50, rare = 33, epic = 13, legendary = 3.6, mythic = 0.4 } },
	{ id = "gold", name = "Oro", essence = 400,
		weights = { common = 40, rare = 35, epic = 18, legendary = 6.3, mythic = 0.7 } },
	{ id = "diamond", name = "Diamante", essence = 1000,
		weights = { common = 30, rare = 35, epic = 22, legendary = 12, mythic = 1.0 } },
}
local ZONE_SCALE = { 0.1, 0.2, 0.35, 0.6, 1.0 }

local state = {
	phase = "idle",
	nextAt = 0,
	zone = nil,
	species = nil,
	phaseEnds = 0,
	startedAt = 0,
	shield = 0,
	shieldMax = 0,
	pillars = {},
	stability = 0,
	scores = {}, -- [userId] = score
	lastShot = {},
	boss = nil,
	folder = nil,
}

function Raid.IsOpen()
	return state.phase ~= "idle" and state.phase ~= "reward"
end

local function interval()
	return RunService:IsStudio() and Config.RaidIntervalStudio or Config.RaidInterval
end

local function inArena(player)
	return player:GetAttribute("Area") == "arena"
end

local function arenaPlayers()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if inArena(p) then
			table.insert(list, p)
		end
	end
	return list
end

local function addScore(player, n)
	local k = tostring(player.UserId)
	state.scores[k] = (state.scores[k] or 0) + n
end

local function broadcast()
	local now = os.time()
	local payload = {
		phase = state.phase,
		zone = state.zone,
		zoneName = state.zone and Progression.Zones[state.zone].name or nil,
		species = state.species,
		timeLeft = math.max(0, state.phaseEnds - now),
		nextIn = math.max(0, state.nextAt - now),
		shield = state.shield,
		shieldMax = state.shieldMax,
		pillars = 0,
		pillarsTotal = #state.pillars,
		stability = state.stability,
		participants = #arenaPlayers(),
		scores = state.scores,
	}
	for _, p in ipairs(state.pillars) do
		if p.active then
			payload.pillars = payload.pillars + 1
		end
	end
	S.Net.FireAll("Raid", payload)
end

local function cleanup()
	if state.folder then
		state.folder:Destroy()
	end
	state.folder = nil
	state.boss = nil
	state.pillars = {}
end

local function setPhase(phase, duration)
	state.phase = phase
	state.phaseEnds = os.time() + (duration or 0)
	broadcast()
end

local function pickZone()
	local maxZone = 1
	for _, p in ipairs(Players:GetPlayers()) do
		local prof = S.Data.Get(p)
		if prof then
			maxZone = math.max(maxZone, prof.zones.unlocked)
		end
	end
	return Random.new():NextInteger(1, maxZone)
end

local function spawnBoss()
	cleanup()
	local f = Instance.new("Folder")
	f.Name = "Incursion"
	f.Parent = workspace
	state.folder = f
	local A = S.World.ARENA
	local boss = PetModels.Build(state.species, "legendary", { scale = 6, label = "JEFE · " .. PetCatalog.Get(state.species).name })
	boss:PivotTo(CFrame.new(A + Vector3.new(0, 22, 0)) * CFrame.Angles(0, math.rad(180), 0))
	boss.Parent = f
	state.boss = boss
	local shield = Instance.new("Part")
	shield.Name = "Shield"
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(34, 34, 34)
	shield.Anchored = true
	shield.CanCollide = false
	shield.Material = Enum.Material.ForceField
	shield.Color = Color3.fromRGB(120, 200, 255)
	shield.Position = A + Vector3.new(0, 22, 0)
	shield.Parent = f
	local body = boss.PrimaryPart
	TweenService:Create(body, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = body.CFrame + Vector3.new(0, 4, 0) }):Play()
	CollectionService:AddTag(boss, "RaidBoss")
end

local function spawnPillars()
	state.pillars = {}
	for i, pos in ipairs(S.World.ArenaPillars) do
		local p = Instance.new("Part")
		p.Name = "Pilar" .. i
		p.Anchored = true
		p.Size = Vector3.new(4, 14, 4)
		p.Position = pos + Vector3.new(0, 7, 0)
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 80, 80)
		p.Parent = state.folder
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Activar pilar"
		pp.ObjectText = "Pilar de resonancia"
		pp.HoldDuration = 1.5
		pp.MaxActivationDistance = 12
		pp.RequiresLineOfSight = false
		pp.Parent = p
		local entry = { part = p, active = false }
		pp.Triggered:Connect(function(player)
			if state.phase ~= "pillars" or entry.active or not inArena(player) then
				return
			end
			entry.active = true
			p.Color = Color3.fromRGB(90, 255, 140)
			pp.Enabled = false
			addScore(player, 15)
			S.Net.Notify(player, "Pilar activado (+15 contribucion)", "success")
		end)
		table.insert(state.pillars, entry)
	end
end

local function shockwave()
	if not state.folder then
		return
	end
	local A = S.World.ARENA
	local ring = Instance.new("Part")
	ring.Name = "Onda"
	ring.Anchored = true
	ring.CanCollide = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(1.5, 10, 10)
	ring.CFrame = CFrame.new(A + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 120, 200)
	ring.Transparency = 0.55
	ring:SetAttribute("Start", workspace:GetServerTimeNow())
	ring:SetAttribute("Duration", 3)
	ring:SetAttribute("MaxRadius", 90)
	ring.Parent = state.folder
	CollectionService:AddTag(ring, "RaidWave")
	TweenService:Create(ring, TweenInfo.new(3, Enum.EasingStyle.Linear), { Size = Vector3.new(1.5, 180, 180) }):Play()
	task.delay(3.1, function()
		ring:Destroy()
	end)
end

local function giveRewards(success)
	local scores = state.scores
	local top = 0
	for _, v in pairs(scores) do
		top = math.max(top, v)
	end
	local now = os.time()
	local sp = PetCatalog.Get(state.species)
	for _, player in ipairs(Players:GetPlayers()) do
		local score = scores[tostring(player.UserId)] or 0
		local profile = S.Data.Get(player)
		if score > 0 and profile then
			local tierIdx = 1
			if score >= 80 or (score >= 40 and score >= top * 0.9) then
				tierIdx = 4
			elseif score >= 45 or score >= top * 0.6 then
				tierIdx = 3
			elseif score >= 20 or score >= top * 0.3 then
				tierIdx = 2
			end
			local tier = TIERS[tierIdx]
			local agg = Stats.Aggregate(profile, now)
			local mult = success and 1 or 0.5
			local ess = math.max(1, math.floor(tier.essence * ZONE_SCALE[state.zone] * (1 + agg.stats.essenceFind) * mult + 0.5))
			profile.essence[sp.id] = (profile.essence[sp.id] or 0) + ess
			profile.raidsJoined = (profile.raidsJoined or 0) + 1
			local lines = { string.format("Contribucion %s (%d pts): +%d esencias de %s", tier.name, score, ess, sp.name) }
			local captured = nil
			if success then
				local r = S.Capture.RollRarity(sp.id, 1, tier.weights)
				local chance = math.min(0.95, 0.6 + 0.07 * profile.tools.vacuum)
				if Random.new():NextNumber() <= chance then
					PetStore.Give(profile, sp.id, r, true)
					PetStore.Register(profile, sp.id, r)
					captured = r
					table.insert(lines, "¡Capturaste un " .. sp.name .. " " .. PetCatalog.Rarity(r).name .. " de tamaño normal!")
				else
					table.insert(lines, "Tu tirada de captura (" .. PetCatalog.Rarity(r).name .. ") fallo esta vez.")
				end
			end
			S.Net.Fire(player, "Fx", "raidReward", { tier = tier.name, essence = ess, species = sp.id, rarity = captured,
				lines = lines, success = success })
			S.Net.MarkDirty(player)
			S.Progress.CheckUnlocks(player, profile)
		end
	end
end

function Raid.Begin(zone)
	if state.phase ~= "idle" then
		return false
	end
	state.zone = zone or pickZone()
	local list = PetCatalog.SpeciesInZone(state.zone)
	state.species = list[Random.new():NextInteger(1, #list)].id
	state.scores = {}
	state.stability = 0
	state.lastShot = {}
	for _, p in ipairs(Players:GetPlayers()) do
		S.Net.Notify(p, "⚠️ ¡Incursion Dimensional en 60 s! Un " .. PetCatalog.Get(state.species).name ..
			" gigante aparecera en la Arena. Abre el Mapa o el aviso para ir.", "raid")
	end
	setPhase("announce", Config.RaidAnnounce)
	return true
end

local function runPhases()
	-- anuncio
	while os.time() < state.phaseEnds do
		task.wait(1)
		broadcast()
	end
	spawnBoss()
	state.startedAt = os.time()
	local deadline = state.startedAt + Config.RaidMaxDuration
	local n = math.max(1, #arenaPlayers())
	state.shieldMax = 60 + 50 * n
	state.shield = state.shieldMax
	setPhase("barrier", Config.RaidMaxDuration)
	while state.shield > 0 and os.time() < deadline do
		task.wait(0.5)
		broadcast()
	end
	local success = false
	if state.shield <= 0 then
		local shield = state.folder and state.folder:FindFirstChild("Shield")
		if shield then
			shield:Destroy()
		end
		spawnPillars()
		setPhase("pillars", deadline - os.time())
		local t = 0
		while os.time() < deadline do
			local done = true
			for _, p in ipairs(state.pillars) do
				if not p.active then
					done = false
				end
			end
			if done then
				break
			end
			task.wait(0.5)
			t = t + 0.5
			if t % 5 == 0 then
				shockwave()
			end
			broadcast()
		end
		local allDone = true
		for _, p in ipairs(state.pillars) do
			if not p.active then
				allDone = false
			end
		end
		if allDone then
			setPhase("final", deadline - os.time())
			local A = S.World.ARENA
			while state.stability < 100 and os.time() < deadline do
				task.wait(1)
				local count = 0
				for _, p in ipairs(arenaPlayers()) do
					local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local d = Vector3.new(hrp.Position.X - A.X, 0, hrp.Position.Z - A.Z).Magnitude
						if d <= 28 then
							count = count + 1
							addScore(p, 2)
						end
					end
				end
				if count > 0 then
					state.stability = math.min(100, state.stability + 4 + 3 * count)
				end
				broadcast()
			end
			success = state.stability >= 100
		end
	end
	setPhase("reward", 8)
	giveRewards(success)
	for _, p in ipairs(Players:GetPlayers()) do
		S.Net.Notify(p, success and ("🏆 ¡Incursion superada! El " .. PetCatalog.Get(state.species).name .. " fue estabilizado.")
			or "La incursion termino sin estabilizar al jefe. Los participantes reciben una recompensa parcial.", success and "success" or "info")
	end
	task.wait(8)
	cleanup()
	state.phase = "idle"
	state.zone = nil
	state.species = nil
	state.nextAt = os.time() + interval()
	broadcast()
end

function Raid.Init(services)
	S = services
	S.Net.Register("raidShot", function(player, profile)
		if state.phase ~= "barrier" then
			return { ok = false }
		end
		if not inArena(player) then
			return { ok = false, msg = "Debes estar en la Arena." }
		end
		local now = os.clock()
		local k = tostring(player.UserId)
		if state.lastShot[k] and now - state.lastShot[k] < Config.RaidShotCooldown then
			return { ok = false }
		end
		state.lastShot[k] = now
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp or (hrp.Position - (S.World.ARENA + Vector3.new(0, 22, 0))).Magnitude > 120 then
			return { ok = false, msg = "Acercate al jefe." }
		end
		-- disparo de resonancia: el daño crece poco con el equipo para no excluir a nuevos
		local vac = Items.Vacuums[profile.tools.vacuum] or Items.Vacuums[1]
		state.shield = math.max(0, state.shield - vac.raid)
		addScore(player, 1)
		return { ok = true, shield = state.shield }
	end)

	S.Net.Register("raidGo", function(player)
		return S.Progress.Teleport(player, "arena")
	end)
end

function Raid.Start()
	state.nextAt = os.time() + interval()
	task.spawn(function()
		while true do
			task.wait(1)
			if state.phase == "idle" and os.time() >= state.nextAt and #Players:GetPlayers() > 0 then
				if Raid.Begin() then
					local ok, err = pcall(runPhases)
					if not ok then
						warn("[PortalPets] Error en incursion: " .. tostring(err))
						cleanup()
						state.phase = "idle"
						state.nextAt = os.time() + interval()
					end
				end
			elseif state.phase == "idle" then
				if os.time() % 5 == 0 then
					broadcast()
				end
			end
		end
	end)
end

-- Para herramientas de desarrollo en Studio
function Raid.ForceSoon()
	if state.phase == "idle" then
		state.nextAt = os.time()
		return true
	end
	return false
end

return Raid
