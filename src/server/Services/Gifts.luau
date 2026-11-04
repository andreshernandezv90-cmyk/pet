-- Gifts: regalos aleatorios de exploracion en el Mundo PET.
-- Privados por jugador (no se los roban otros), poco frecuentes y configurables
-- por zona en WorldConfig.Gifts. El servidor decide donde aparecen y que dan;
-- el cliente solo los dibuja y pide abrirlos.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local WorldConfig = require(Shared.WorldConfig)
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Items = require(Shared.Items)
local Stats = require(Shared.Stats)

local Gifts = {}
local S

local active = {} -- [player] = { list = {[id] = gift}, counter, nextCheck }
local rng = Random.new()

local function data(player)
	local d = active[player]
	if not d then
		d = { list = {}, counter = 0, nextCheck = os.time() + WorldConfig.Gifts.checkInterval }
		active[player] = d
	end
	return d
end

local function serialize(d)
	local out = {}
	for _, g in pairs(d.list) do
		table.insert(out, { id = g.id, x = g.pos.X, y = g.pos.Y, z = g.pos.Z, zone = g.zone })
	end
	return out
end

function Gifts.Resend(player)
	local d = active[player]
	S.Net.Fire(player, "Gifts", d and serialize(d) or {})
end

-- Zona donde puede aparecer un regalo. En la Fase C el Mundo PET continuo
-- publicara World.GiftAreas[zona]; mientras tanto se usan las praderas actuales.
local function areaFor(zone)
	local areas = S.World.GiftAreas and S.World.GiftAreas[zone]
	if areas and #areas > 0 then
		return areas[rng:NextInteger(1, #areas)]
	end
	return S.World.SpawnRegions[zone]
end

local function pickReward(zone)
	local cfg = WorldConfig.Gifts.byZone[zone]
	local total = 0
	for _, r in ipairs(cfg.rewards) do
		total = total + r.weight
	end
	local roll = rng:NextNumber() * total
	for _, r in ipairs(cfg.rewards) do
		roll = roll - r.weight
		if roll <= 0 then
			return r
		end
	end
	return cfg.rewards[1]
end

local function spawnGift(player, d, zone)
	local area = areaFor(zone)
	if not area then
		return
	end
	local pos = area.center + Vector3.new(rng:NextNumber(-area.sizeX / 2, area.sizeX / 2), 0, rng:NextNumber(-area.sizeZ / 2, area.sizeZ / 2))
	pos = Vector3.new(pos.X, area.y or 0, pos.Z)
	d.counter = d.counter + 1
	local id = "g" .. d.counter
	d.list[id] = { id = id, zone = zone, pos = pos, born = os.time() }
	S.Net.Fire(player, "Gifts", serialize(d))
	S.Net.Notify(player, "🎁 ¡Algo brilla entre los arboles! Hay un regalo escondido cerca.", "rare")
end

local function grant(player, profile, zone, reward)
	local text
	if reward.kind == "resource" then
		local n = rng:NextInteger(reward.min, reward.max)
		local added = PetStore.AddToBackpack(profile, reward.id, n)
		if added < n then
			PetStore.AddToStorage(profile, reward.id, n - added)
		end
		text = "+" .. n .. " " .. Items.ResName(reward.id)
	elseif reward.kind == "essence" then
		local list = PetCatalog.SpeciesInZone(zone)
		local sp = list[rng:NextInteger(1, #list)]
		local agg = Stats.Aggregate(profile, os.time())
		local n = math.floor(rng:NextInteger(reward.min, reward.max) * (1 + agg.stats.essenceFind) + 0.5)
		profile.essence[sp.id] = (profile.essence[sp.id] or 0) + n
		text = "+" .. n .. " esencias de " .. sp.name
	elseif reward.kind == "potion" then
		profile.items.potions[reward.id] = (profile.items.potions[reward.id] or 0) + (reward.n or 1)
		text = "+" .. (reward.n or 1) .. " " .. Items.Potions[reward.id].name
	elseif reward.kind == "bait" then
		profile.items.baits[reward.id] = (profile.items.baits[reward.id] or 0) + (reward.n or 1)
		text = "+" .. (reward.n or 1) .. " " .. Items.Baits[reward.id].name
	end
	profile.giftsOpened = (profile.giftsOpened or 0) + 1
	return text or "¡Sorpresa!"
end

function Gifts.Init(services)
	S = services
	S.Net.Register("claimGift", function(player, profile, payload)
		local d = active[player]
		local g = d and type(payload.id) == "string" and d.list[payload.id]
		if not g then
			return { ok = false, msg = "Ese regalo ya no esta." }
		end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp or (hrp.Position - g.pos).Magnitude > WorldConfig.Gifts.claimDistance + 6 then
			return { ok = false, msg = "Acercate al regalo." }
		end
		if player:GetAttribute("Area") ~= "z" .. g.zone then
			return { ok = false, msg = "Ese regalo esta en otra zona." }
		end
		d.list[g.id] = nil
		local text = grant(player, profile, g.zone, pickReward(g.zone))
		S.Net.Fire(player, "Gifts", serialize(d))
		return { ok = true, msg = "🎁 Regalo abierto: " .. text, reward = text }
	end)
end

function Gifts.Start()
	task.spawn(function()
		while true do
			task.wait(3)
			if WorldConfig.Gifts.enabled then
				local now = os.time()
				for _, player in ipairs(Players:GetPlayers()) do
					local profile = S.Data.Get(player)
					if profile then
						local d = data(player)
						local changed = false
						for id, g in pairs(d.list) do
							if now - g.born >= WorldConfig.Gifts.lifetime then
								d.list[id] = nil
								changed = true
							end
						end
						if changed then
							S.Net.Fire(player, "Gifts", serialize(d))
						end
						if now >= d.nextCheck then
							d.nextCheck = now + WorldConfig.Gifts.checkInterval
							local zone = S.World.ZoneOfArea(player:GetAttribute("Area"))
							local cfg = zone and WorldConfig.Gifts.byZone[zone]
							local count = 0
							for _ in pairs(d.list) do
								count = count + 1
							end
							if cfg and count < WorldConfig.Gifts.maxActive and rng:NextNumber() < cfg.chance then
								spawnGift(player, d, zone)
							end
						end
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		active[player] = nil
	end)
end

-- Para pruebas y herramientas de desarrollo
function Gifts.ForceSpawn(player, zone)
	spawnGift(player, data(player), zone)
end

function Gifts.Active(player)
	return active[player] and active[player].list or {}
end

return Gifts
