-- Progress (WorldProgression): areas, portales, viajes, desbloqueo de zonas,
-- checkpoints, recuperacion de caidas y cofres secretos. (GDD 03)

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)

local Progress = {}
local S

local lastTeleport = {}
local checkpoints = {} -- [player] = CFrame

local DEST_NAMES = {
	home = "tu Hogar", forest = "el Bosque", mines = "las Minas de Zuar", realm = "el Reino de los PETs", arena = "la Arena",
}

local function result(ok, msg)
	return { ok = ok, msg = msg }
end

function Progress.CheckUnlocks(player, profile)
	local changed = false
	while profile.zones.unlocked < 5 and Progression.CanUnlock(profile, profile.zones.unlocked + 1) do
		profile.zones.unlocked = profile.zones.unlocked + 1
		changed = true
		local z = profile.zones.unlocked
		S.Net.Notify(player, "🔓 ¡Zona " .. z .. " desbloqueada: " .. Progression.Zones[z].name .. "! Tu mochila y tanque crecieron.", "unlock")
	end
	if changed then
		S.Net.MarkDirty(player)
	end
	return changed
end

local function destCFrame(player, profile, dest)
	if dest == "home" then
		return S.Plots.SpawnCFrame(player)
	elseif dest == "forest" then
		return S.World.Spawns.forest or CFrame.new(0, 4, 262)
	elseif dest == "mines" then
		return S.World.Spawns.mines
	elseif dest == "realm" then
		return S.World.Spawns.realm
	elseif dest == "arena" then
		if not (S.Raid and S.Raid.IsOpen()) then
			return nil, "La arena solo abre durante una Incursion Dimensional."
		end
		return S.World.Spawns.arena
	end
	local k, meadow = string.match(dest, "^z(%d)(m?)$")
	k = tonumber(k)
	if k and k >= 1 and k <= 5 then
		if profile.zones.unlocked < k then
			local missing = Progression.Missing(profile, k)
			return nil, "Zona " .. k .. " bloqueada. Falta: " .. table.concat(missing, ", ")
		end
		if meadow == "m" then
			if not profile.zones.parkour["z" .. k] then
				return nil, "Primero completa el parkour de esta zona."
			end
			return S.World.Spawns["z" .. k .. "m"]
		end
		return S.World.Spawns["z" .. k]
	end
	return nil, "Destino desconocido."
end

function Progress.Teleport(player, dest, force)
	local profile = S.Data.Get(player)
	local char = player.Character
	if not profile or not char or not char.PrimaryPart then
		return result(false, "Tu personaje no esta listo.")
	end
	local now = os.clock()
	if not force and lastTeleport[player] and now - lastTeleport[player] < Config.TeleportCooldown then
		return result(false, "Espera un momento antes de viajar otra vez.")
	end
	local cf, err = destCFrame(player, profile, dest)
	if not cf then
		return result(false, err)
	end
	lastTeleport[player] = now
	checkpoints[player] = cf
	-- con StreamingEnabled, precargar el destino antes de mover al personaje
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 3)
	end)
	char:PivotTo(cf)
	local k = string.match(dest, "^z(%d)")
	local name = DEST_NAMES[dest] or (k and ("la Zona " .. k .. " · " .. Progression.Zones[tonumber(k)].name)) or dest
	return result(true, "Viajaste a " .. name .. ".")
end

local function onCheckpoint(cp, hit)
	local char = hit and hit.Parent
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then
		return
	end
	local cf = CFrame.new(cp.pos + Vector3.new(0, 4, 0))
	if checkpoints[player] == cf then
		return
	end
	checkpoints[player] = cf
	if cp.meadow then
		local profile = S.Data.Get(player)
		if profile and not profile.zones.parkour["z" .. cp.zone] then
			profile.zones.parkour["z" .. cp.zone] = true
			S.Net.Notify(player, "🏁 ¡Parkour completado! Ahora puedes viajar directo a esta pradera desde el Mapa.", "success")
			S.Net.MarkDirty(player)
		end
	elseif cp.index > 0 then
		S.Net.Fire(player, "Fx", "checkpoint", cp.pos)
	end
end

local function openChest(player, zone)
	local profile = S.Data.Get(player)
	if not profile then
		return
	end
	local key = "chest_z" .. zone
	local now = os.time()
	local cd = profile.cooldowns[key]
	if cd and cd > now then
		S.Net.Notify(player, string.format("El cofre esta vacio. Vuelve en %d min.", math.ceil((cd - now) / 60)), "info")
		return
	end
	profile.cooldowns[key] = now + Config.ChestCooldown
	local rng = Random.new()
	local mat = Progression.Zones[zone].material
	local n = rng:NextInteger(5, 10)
	local added = PetStore.AddToBackpack(profile, mat, n)
	if added < n then
		PetStore.AddToStorage(profile, mat, n - added)
	end
	local agg = Stats.Aggregate(profile, now)
	local species = PetCatalog.SpeciesInZone(zone)
	local sp = species[rng:NextInteger(1, #species)]
	local ess = math.floor(rng:NextInteger(5, 15) * zone * (1 + agg.stats.essenceFind) + 0.5)
	profile.essence[sp.id] = (profile.essence[sp.id] or 0) + ess
	S.Net.Notify(player, string.format("🎁 Cofre secreto: +%d %s y +%d esencias de %s", n, Items.ResName(mat), ess, sp.name), "success")
	S.Net.MarkDirty(player)
end

function Progress.Init(services)
	S = services
	S.Net.Register("teleport", function(player, profile, payload)
		if type(payload.dest) ~= "string" then
			return result(false, "Destino invalido.")
		end
		return Progress.Teleport(player, payload.dest)
	end)
end

function Progress.Start()
	for _, cp in ipairs(S.World.Checkpoints) do
		cp.part.Touched:Connect(function(hit)
			onCheckpoint(cp, hit)
		end)
	end
	for _, p in ipairs(S.World.Portals) do
		p.prompt.Triggered:Connect(function(player)
			local r = Progress.Teleport(player, p.dest)
			if not r.ok then
				S.Net.Notify(player, r.msg, "error")
			end
		end)
	end
	for zone, chest in pairs(S.World.Chests) do
		chest.prompt.Triggered:Connect(function(player)
			if player:GetAttribute("Area") == "z" .. zone then
				openChest(player, zone)
			end
		end)
	end

	-- Bucle de areas y caidas
	task.spawn(function()
		while true do
			task.wait(0.4)
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local profile = S.Data.Get(player)
				if hrp and profile then
					local pos = hrp.Position
					local area = S.World.AreaAt(pos)
					if pos.Y < -45 then
						local cf = checkpoints[player] or S.Plots.SpawnCFrame(player)
						hrp.AssemblyLinearVelocity = Vector3.zero
						char:PivotTo(cf)
						S.Net.Fire(player, "Fx", "respawn")
					elseif area ~= "void" and area ~= player:GetAttribute("Area") then
						local zone = S.World.ZoneOfArea(area)
						if zone and zone > profile.zones.unlocked then
							char:PivotTo(S.World.Spawns.realm)
							S.Net.Notify(player, "Esa zona aun esta bloqueada.", "error")
						else
							player:SetAttribute("Area", area)
							if area == "mines" and not profile.story.visitedMines then
								profile.story.visitedMines = true
								S.Net.MarkDirty(player)
							end
							S.Capture.OnAreaChanged(player, area)
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastTeleport[player] = nil
		checkpoints[player] = nil
	end)
end

return Progress
