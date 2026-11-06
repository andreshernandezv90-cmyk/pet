-- Mining (MiningAndCrafting, parte de nodos): arboles, minerales y materiales de zona.
-- La durabilidad de cada nodo es individual por jugador: lo que tu agotas no
-- desaparece para los demas. Todo se valida en el servidor. (GDD 02 y 07)
--
-- Minas de Zuar (Fase D): las vetas de cada galeria tienen mineral PRIVADO por
-- jugador y por ciclo (MineVeins + WorldConfig.Regions[k].mine). El servidor
-- decide el reparto, se lo envia solo a ese jugador ("Veins") y valida cada golpe
-- contra el. La galeria k exige la zona k del Reino (Mining.GalleryOpen) y, en el
-- futuro, vencer a su guardian (sello desactivado por configuracion).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local PetStore = require(Shared.PetStore)
local Stats = require(Shared.Stats)
local WorldConfig = require(Shared.WorldConfig)
local MineVeins = require(Shared.MineVeins)

local Mining = {}
local S

local state = {} -- [player] = { hp = {[nodeId]=hp}, respawn = {[nodeId]=t}, last = os.clock() }
local veins = {} -- [player] = { [galeria] = { untilT, types = {[nodeId] = nodeType}, present = {recursos} } }

local function getState(player)
	local st = state[player]
	if not st then
		st = { hp = {}, respawn = {}, last = 0 }
		state[player] = st
	end
	return st
end

-- ¿Puede el jugador usar la galeria k? Zona k del Reino desbloqueada y, cuando se
-- active la Fase G, guardian vencido. La Cantera de Zuar (hub) nunca se bloquea.
function Mining.GalleryOpen(profile, k)
	local region = WorldConfig.Regions[k]
	if not region then
		return false, "Galeria desconocida."
	end
	if profile.zones.unlocked < k then
		return false, region.mine.name .. " se abre al desbloquear la Zona " .. k .. " del Reino."
	end
	local guardian = region.mine.guardian
	if guardian and guardian.enabled then
		local beaten = type(profile.mines) == "table" and type(profile.mines.guardians) == "table" and profile.mines.guardians["m" .. k]
		if not beaten then
			return false, "Un guardian dimensional protege " .. region.mine.name .. "."
		end
	end
	return true, nil
end

-- Garantiza un reparto vigente de vetas para el jugador en la galeria k
function Mining.EnsureVeins(player, k)
	local profile = S.Data.Get(player)
	if not profile or not Mining.GalleryOpen(profile, k) then
		return nil
	end
	local pv = veins[player]
	if not pv then
		pv = {}
		veins[player] = pv
	end
	local now = os.time()
	local cur = pv[k]
	if cur and cur.untilT > now then
		return cur
	end
	local region = WorldConfig.Regions[k]
	local ids = S.World.Veins and S.World.Veins[k] or {}
	local types, present = MineVeins.Roll(region, ids, Random.new())
	cur = { untilT = now + region.mine.cycle, types = types, present = present }
	pv[k] = cur
	-- ciclo nuevo: las vetas de esta galeria vuelven a estar completas
	local st = getState(player)
	for _, id in ipairs(ids) do
		st.respawn[id] = nil
		st.hp[id] = nil
	end
	S.Net.Fire(player, "Veins", k, types, region.mine.cycle)
	return cur
end

function Mining.VeinsOf(player, k)
	local pv = veins[player]
	return pv and pv[k] or nil
end

-- Reenvia los repartos vigentes (cliente recien conectado)
function Mining.ResendVeins(player)
	local pv = veins[player]
	if not pv then
		return
	end
	local now = os.time()
	for k, cur in pairs(pv) do
		if cur.untilT > now then
			S.Net.Fire(player, "Veins", k, cur.types, cur.untilT - now)
		end
	end
end

local function hit(player, node)
	local profile = S.Data.Get(player)
	if not profile then
		return
	end
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
	-- vetas de galeria: el mineral sale del reparto privado del jugador
	local nodeType = node.type
	if node.gallery then
		local open, why = Mining.GalleryOpen(profile, node.gallery)
		if not open then
			S.Net.Notify(player, why, "error")
			return
		end
		local cur = Mining.VeinsOf(player, node.gallery)
		if not cur or cur.untilT <= t then
			Mining.EnsureVeins(player, node.gallery)
			S.Net.Notify(player, "Las vetas de la galeria se renovaron. ¡Elige otra vez!", "info")
			return
		end
		nodeType = cur.types[node.id]
		if not nodeType then
			return
		end
	end
	local def = Items.Nodes[nodeType]
	if not def then
		return
	end
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
	local inMines = node.area == "mines" or node.gallery ~= nil
	if inMines and not profile.story.visitedMines then
		profile.story.visitedMines = true
	end
	local agg = Stats.Aggregate(profile, t)
	local isTree = nodeType == "tree"
	local dmg = isTree and Stats.ChopDamage(agg, profile.tools.axe) or Stats.MineDamage(agg, profile.tools.pick)
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
	local amount = math.max(1, math.floor(base * Stats.YieldMult(agg, def.resource, profile.tools.axe) + rng:NextNumber()))
	local added = PetStore.AddToBackpack(profile, def.resource, amount)
	local extras = {}
	if nodeType == "tree" and rng:NextNumber() < 0.15 then
		local s = PetStore.AddToBackpack(profile, "semilla", 1)
		if s > 0 then
			table.insert(extras, "+1 " .. Items.ResName("semilla"))
		end
	end
	if inMines and agg.stats.rareFind > 0 and rng:NextNumber() < agg.stats.rareFind then
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
		veins[player] = nil
	end)
	-- renovar el reparto de quien esta dentro de una galeria al terminar su ciclo
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local k = S.World.GalleryOfArea(player:GetAttribute("Area"))
				if k then
					Mining.EnsureVeins(player, k)
				end
			end
		end
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
