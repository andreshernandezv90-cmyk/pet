-- Mining (MiningAndCrafting, parte de nodos): arboles, minerales y materiales de zona.
-- La durabilidad de cada nodo es individual por jugador: lo que tu agotas no
-- desaparece para los demas. Todo se valida en el servidor. (GDD 02 y 07)

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local PetStore = require(Shared.PetStore)
local Stats = require(Shared.Stats)

local Mining = {}
local S

local state = {} -- [player] = { hp = {[nodeId]=hp}, respawn = {[nodeId]=t}, last = os.clock() }

local function getState(player)
	local st = state[player]
	if not st then
		st = { hp = {}, respawn = {}, last = 0 }
		state[player] = st
	end
	return st
end

local function hit(player, node)
	local profile = S.Data.Get(player)
	if not profile then
		return
	end
	local def = Items.Nodes[node.type]
	local st = getState(player)
	local now = os.clock()
	if now - st.last < Config.MineCooldown then
		return
	end
	st.last = now
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or (hrp.Position - node.pos).Magnitude > 18 then
		return
	end
	local t = os.time()
	if st.respawn[node.id] and st.respawn[node.id] > t then
		S.Net.Notify(player, "Este recurso esta reapareciendo...", "info")
		return
	end
	if profile.tools.pick < def.pick then
		S.Net.Notify(player, "Necesitas el " .. Items.Picks[def.pick].name .. " para esto.", "error")
		return
	end
	if PetStore.BackpackRoom(profile, def.resource) <= 0 then
		S.Net.Notify(player, "¡Mochila llena! Deposita en el Almacen de tu Hogar o fabrica mas espacio.", "error")
		return
	end
	if node.area == "mines" and not profile.story.visitedMines then
		profile.story.visitedMines = true
	end
	local agg = Stats.Aggregate(profile, t)
	local dmg = Stats.MineDamage(agg, profile.tools.pick)
	local hp = (st.hp[node.id] or def.hp) - dmg
	if hp > 0 then
		st.hp[node.id] = hp
		S.Net.Fire(player, "Fx", "nodeHit", node.id, hp / def.hp)
		return
	end
	-- Agotado: botin
	st.hp[node.id] = nil
	st.respawn[node.id] = t + def.respawn
	local rng = Random.new()
	local base = rng:NextInteger(def.yield[1], def.yield[2])
	local amount = math.max(1, math.floor(base * Stats.YieldMult(agg, def.resource) + rng:NextNumber()))
	local added = PetStore.AddToBackpack(profile, def.resource, amount)
	local extras = {}
	if node.type == "tree" and rng:NextNumber() < 0.15 then
		local s = PetStore.AddToBackpack(profile, "semilla", 1)
		if s > 0 then
			table.insert(extras, "+1 " .. Items.ResName("semilla"))
		end
	end
	if node.area == "mines" and agg.stats.rareFind > 0 and rng:NextNumber() < agg.stats.rareFind then
		local s = PetStore.AddToBackpack(profile, "polvo", 1)
		if s > 0 then
			table.insert(extras, "+1 " .. Items.ResName("polvo") .. " (Zuri)")
		end
	end
	S.Net.Fire(player, "NodeState", node.id, st.respawn[node.id] - t)
	local text = "+" .. added .. " " .. Items.ResName(def.resource)
	if #extras > 0 then
		text = text .. "  " .. table.concat(extras, "  ")
	end
	if added < amount then
		text = text .. "  (mochila llena)"
	end
	S.Net.Fire(player, "Fx", "loot", node.id, text)
	S.Net.MarkDirty(player)
	if S.Progress then
		S.Progress.CheckUnlocks(player, profile)
	end
end

function Mining.Init(services)
	S = services
end

function Mining.Start()
	local byPrompt = {}
	for _, node in pairs(S.World.Nodes) do
		byPrompt[node.prompt] = node
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local node = byPrompt[prompt]
		if node then
			hit(player, node)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		state[player] = nil
	end)
end

-- Para que un cliente recien llegado sepa que nodos tiene agotados
function Mining.RespawnTimes(player)
	local st = getState(player)
	local out = {}
	local t = os.time()
	for id, r in pairs(st.respawn) do
		if r > t then
			out[id] = r - t
		end
	end
	return out
end

return Mining
