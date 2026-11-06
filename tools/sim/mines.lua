-- Fase D: Minas de Zuar como mundo propio (hub + Cantera libre + 5 galerias con
-- vetas privadas por jugador), vinculadas a la progresion del Reino.
-- Ejecutar: lua5.4 tools/sim/mines.lua
dofile("tools/sim/mock.lua")
local function check(c, msg) if not c then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local realClock = os.clock
local OFFSET = 0
os.clock = function() return realClock() + OFFSET end

RUN_SCRIPT(SERVER_SCRIPT)
local RS = game:GetService("ReplicatedStorage")
require(RS.Shared.Config).ActionRateLimit = 1e9
local WC = require(RS.Shared.WorldConfig)
local MineVeins = require(RS.Shared.MineVeins)
local Items = require(RS.Shared.Items)
local CS = game:GetService("CollectionService")
local PPS = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")

local events = {} -- [nombre] = lista de { player, args }
for _, ev in ipairs(RS.Remotes:GetChildren()) do
	if ev.ClassName == "RemoteEvent" then
		local name = ev.Name
		events[name] = {}
		ev.__onFireClient = function(p, ...)
			table.insert(events[name], { p = p, args = { ... } })
			if p == nil or p == LOCAL_PLAYER then ev.OnClientEvent:Fire(...) end
		end
	end
end
local S = {}
for _, m in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[m.Name] = require(m) end
local World = S.World
local P = MAKE_PLAYER(41, "Minera")
Players.__props.LocalPlayer = P
LOCAL_PLAYER = P
Players.PlayerAdded:Fire(P)
RUN_DELAYS()
RUN_SCRIPT(CLIENT_SCRIPT)
local profile = S.DataService.Get(P)
local hrp = P.Character.HumanoidRootPart
for _ = 1, 3 do STEP(1) end -- deja terminar la llegada a la parcela

local function act(n, pl, who)
	OFFSET = OFFSET + 3
	local r = RS.Remotes.Action:InvokeServer(n, pl or {})
	RUN_DELAYS()
	return r
end
local function teleport(dest, who)
	OFFSET = OFFSET + 3
	local r = S.Progress.Teleport(who or P, dest)
	RUN_DELAYS()
	return r
end
local function steps(n) for _ = 1, n do STEP(1) end end
local function at(pos, who) (who or P).Character.HumanoidRootPart.__props.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
local function hitNode(node, who)
	OFFSET = OFFSET + 1
	PPS.PromptTriggered:Fire(node.prompt, who or P)
	RUN_DELAYS()
end
local function total(res) return (profile.res.backpack[res] or 0) + (profile.res.storage[res] or 0) end
local function mineUntil(node, res, who, maxHits)
	local before = total(res)
	for _ = 1, maxHits or 12 do
		hitNode(node, who)
		if total(res) > before then return true end
	end
	return false
end
local function lastVeins(who, k)
	local list = events.Veins
	for i = #list, 1, -1 do
		if list[i].p == who and list[i].args[1] == k then return list[i].args[2], i end
	end
	return nil, 0
end

-- 1. Tres mundos y estructura ---------------------------------------------------------------
local minesFolder = World.Root:FindFirstChild("MinasDeZuar")
check(minesFolder ~= nil and World.Mines ~= nil, "mundo Minas de Zuar construido")
check(World.AreaAt(World.Spawns.mines.Position) == "mines", "llegada al hub de las minas")
check(World.AreaAt(S.Plots.SpawnCFrame(P).Position) == "home" and World.AreaAt(World.Spawns.world.Position) == "camp",
	"Hogar y Reino siguen en su sitio (tres mundos separados)")
local M = World.MINES
local corners = { Vector3.new(-300, 0, -300), Vector3.new(300, 0, -300), Vector3.new(-300, 0, 300), Vector3.new(300, 0, 300) }
local isolated = true
for _, c in ipairs(corners) do
	local a = World.AreaAt(M + c)
	if not (a == "mines" or string.match(a, "^m%d$")) then isolated = false end
end
check(isolated, "las esquinas del mundo de minas no pisan el Hogar ni el Reino")

local quarry = 0
for _, n in pairs(World.Nodes) do
	if n.area == "mines" and n.type == "stone" and World.AreaAt(n.pos) == "mines" then quarry = quarry + 1 end
end
check(quarry == WC.Mines.quarry.nodes, "Cantera de Zuar: " .. quarry .. " rocas de piedra en el hub (siempre libre)")

local Mn = World.Mines
for k = 1, 5 do
	local region = WC.Regions[k]
	local ids = World.Veins[k]
	check(ids and #ids == region.mine.slots, "galeria " .. k .. ": " .. #ids .. " vetas (= mine.slots)")
	local okArea, minGap = true, math.huge
	for i, id in ipairs(ids) do
		local n = World.Nodes[id]
		if n.area ~= "m" .. k or n.gallery ~= k or World.AreaAt(n.pos) ~= "m" .. k then okArea = false end
		for j = i + 1, #ids do
			local o = World.Nodes[ids[j]]
			local d = Vector3.new(n.pos.X - o.pos.X, 0, n.pos.Z - o.pos.Z).Magnitude
			if d < minGap then minGap = d end
		end
	end
	check(okArea, "galeria " .. k .. ": todas las vetas dentro de su camara")
	check(minGap >= 7, string.format("galeria %d: vetas separadas (min %.1f studs)", k, minGap))
	check(World.AreaAt(World.Spawns["mine_m" .. k].Position) == "m" .. k, "galeria " .. k .. ": llegada dentro de la galeria")
	check(World.AreaAt(World.MineMouths[k].Position) == "mines", "galeria " .. k .. ": punto de rechazo fuera (en el hub)")
	local exit = false
	for _, p in ipairs(World.Portals) do if p.dest == "mineexit_z" .. k then exit = true end end
	check(exit, "galeria " .. k .. ": salida a la Zona " .. k .. " del Reino")
	check(region.mine.guardian and region.mine.guardian.enabled == false, "galeria " .. k .. ": sello de guardian preparado y desactivado")
end
-- camaras separadas por roca y tuneles libres
local sep = true
for a = 1, 5 do
	local ga = Mn.Gallery(a)
	for b = a + 1, 5 do
		local gb = Mn.Gallery(b)
		local d = math.sqrt((ga.x - gb.x) ^ 2 + (ga.cz - gb.cz) ^ 2)
		if d < ga.r + gb.r + 8 then sep = false end
	end
	for b = 1, 5 do
		if b ~= a then
			local gb = Mn.Gallery(b)
			if math.abs(ga.x - gb.x) < gb.r + Mn.TunnelHalf + 2 and gb.cz - gb.r < ga.cz then sep = false end
		end
	end
end
check(sep, "camaras separadas por roca y tuneles sin cruzar otras camaras")
local gates = {}
for _, b in ipairs(CS:GetTagged("ZoneBarrier")) do
	if b:IsDescendantOf(minesFolder) then gates[b:GetAttribute("Zone")] = true end
end
check(not gates[1] and gates[2] and gates[3] and gates[4] and gates[5], "cortinas por jugador en las bocas II-V (la I esta abierta)")
local air = 0
for _, op in ipairs(TERRAIN_OPS) do if op.mat == Enum.Material.Air then air = air + 1 end end
check(air >= 15, "terreno excavado: " .. air .. " operaciones de aire (5 tuneles + 5 camaras + 5 cupulas)")
local parts = 0
for _, d in ipairs(minesFolder:GetDescendants()) do if d:IsA("BasePart") then parts = parts + 1 end end
check(parts <= 2500, "Minas de Zuar: " .. parts .. " partes (presupuesto 2500)")

-- 2. Reparto de vetas (logica pura) ------------------------------------------------------------
local rng = Random.new(7)
local fake = {}
for i = 1, 14 do fake[i] = "v" .. i end
local copperCycles, okTypes, okCount, okGuarantee = 0, true, true, true
for _ = 1, 3000 do
	local types, present = MineVeins.Roll(WC.Regions[1], fake, rng)
	local n, hasCopper = 0, false
	for _, t in pairs(types) do
		n = n + 1
		if t ~= "stone" and t ~= "copper" then okTypes = false end
		if t == "copper" then hasCopper = true end
	end
	if n ~= 14 then okCount = false end
	local presentCopper = false
	for _, r in ipairs(present) do if r == "cobre" then presentCopper = true end end
	if presentCopper then copperCycles = copperCycles + 1 end
	if presentCopper ~= hasCopper then okGuarantee = false end
end
check(okCount and okTypes, "galeria I: 14 vetas, solo piedra y cobre")
check(okGuarantee, "cada mineral presente recibe al menos una veta")
check(math.abs(copperCycles / 3000 - 0.15) < 0.03, string.format("cobre presente en %.1f%% de los ciclos (tabla: 15%%)", copperCycles / 30))
local fake5 = {}
for i = 1, 28 do fake5[i] = "w" .. i end
local seen, zu = {}, 0
for _ = 1, 3000 do
	local types, present = MineVeins.Roll(WC.Regions[5], fake5, rng)
	for _, t in pairs(types) do seen[t] = true end
	for _, r in ipairs(present) do if r == "zuarita" then zu = zu + 1 end end
end
check(seen.stone and seen.copper and seen.iron and seen.lunar and seen.zuarita, "Gran Mina: pueden aparecer los cinco minerales")
check(math.abs(zu / 3000 - 0.25) < 0.03, string.format("zuarita presente en %.1f%% de los ciclos (tabla: 25%%)", zu / 30))

-- 3. Flujo de juego ------------------------------------------------------------------------
check(profile.zones.unlocked == 1 and profile.tools.pick == 1, "perfil nuevo: zona 1, pico de madera")
check(teleport("mines").ok, "viaje al hub de las Minas de Zuar")
steps(2)
check(P:GetAttribute("Area") == "mines" and profile.story.visitedMines, "area 'mines' y visita registrada")
-- Cantera libre
local qnode
for _, n in pairs(World.Nodes) do if n.area == "mines" and n.type == "stone" then qnode = n break end end
at(qnode.pos)
check(mineUntil(qnode, "piedra"), "Cantera: piedra con el pico de madera")
-- galeria bloqueada
local r = teleport("m2")
check(not r.ok and r.msg:find("Zona 2"), "galeria II bloqueada sin la Zona 2: " .. tostring(r.msg))
-- galeria I
check(teleport("m1").ok, "viaje a la galeria I")
steps(2)
check(P:GetAttribute("Area") == "m1" and profile.mines.visited.m1, "area 'm1' y galeria registrada en el perfil")
local types = lastVeins(P, 1)
local nT = 0
for _ in pairs(types or {}) do nT = nT + 1 end
check(nT == WC.Regions[1].mine.slots, "reparto privado recibido: " .. nT .. " vetas")
-- el cliente pinta su reparto
local painted, promptsOk = 0, true
for _, m in ipairs(CS:GetTagged("VeinSocket")) do
	if m:GetAttribute("Gallery") == 1 then
		local t = types[m:GetAttribute("NodeId")]
		for _, d in ipairs(m:GetDescendants()) do
			if d:GetAttribute("Ore") and t and d.Color == Items.Nodes[t].color then painted = painted + 1 end
			if d.ClassName == "ProximityPrompt" and d.Enabled ~= (t ~= nil) then promptsOk = false end
		end
	end
end
check(painted >= nT * 4 and promptsOk, "el cliente pinta sus vetas (" .. painted .. " cristales) y activa sus indicadores")
-- minar una veta de piedra
local cur = S.Mining.VeinsOf(P, 1)
local stoneId, copperId
for _, id in ipairs(World.Veins[1]) do
	if cur.types[id] == "stone" and not stoneId then stoneId = id elseif cur.types[id] == "stone" and not copperId then copperId = id end
end
cur.types[copperId] = "copper" -- forzar una veta de cobre (estado del servidor) para la prueba
local sNode, cNode = World.Nodes[stoneId], World.Nodes[copperId]
at(sNode.pos)
check(mineUntil(sNode, "piedra"), "galeria I: veta de piedra minada")
check(S.Mining.RespawnTimes(P)[stoneId] ~= nil, "la veta queda agotada para este jugador")
at(cNode.pos)
check(not mineUntil(cNode, "cobre", P, 4), "cobre sin pico de piedra: rechazado")
profile.tools.pick = 2
check(mineUntil(cNode, "cobre"), "con pico de piedra se extrae cobre")
-- validaciones del servidor
local other
for _, id in ipairs(World.Veins[1]) do if id ~= stoneId and id ~= copperId then other = World.Nodes[id] break end end
at(other.pos + Vector3.new(60, 0, 0))
check(not mineUntil(other, "piedra", P, 3), "demasiado lejos: rechazado")
at(other.pos)
cur.types[other.id] = nil
check(not mineUntil(other, "piedra", P, 3) and not mineUntil(other, "cobre", P, 1), "veta sin mineral en tu reparto: nada")
local g2 = World.Nodes[World.Veins[2][1]]
at(g2.pos)
check(not mineUntil(g2, "piedra", P, 3), "veta de una galeria bloqueada: rechazada")
steps(2)
check(World.AreaAt(hrp.Position) == "mines", "dentro de una galeria bloqueada: el servidor te devuelve al hub")
-- privacidad
local P2 = MAKE_PLAYER(42, "Vecina")
Players.PlayerAdded:Fire(P2)
RUN_DELAYS()
for _ = 1, 3 do STEP(1) end
check(teleport("m1", P2).ok, "segunda jugadora entra a la galeria I")
steps(2)
check(S.Mining.VeinsOf(P2, 1) ~= nil and S.Mining.VeinsOf(P2, 1) ~= S.Mining.VeinsOf(P, 1), "cada jugador tiene su propio reparto")
check(S.Mining.RespawnTimes(P2)[stoneId] == nil, "lo que tu agotas no se agota para ella")
-- nuevo ciclo
teleport("m1")
steps(2)
local _, before = lastVeins(P, 1)
TIME_OFFSET = TIME_OFFSET + WC.Regions[1].mine.cycle + 1
steps(2)
local _, after = lastVeins(P, 1)
check(after > before and S.Mining.VeinsOf(P, 1).untilT > os.time(), "al terminar el ciclo llega un reparto nuevo")
check(S.Mining.RespawnTimes(P)[stoneId] == nil, "ciclo nuevo: vetas completas otra vez")

-- 4. Vinculo con el Reino ------------------------------------------------------------------------
profile.zones.unlocked = 3
check(teleport("m3").ok, "con la Zona 3 se abre la galeria III")
steps(2)
check(P:GetAttribute("Area") == "m3", "dentro de la galeria III")
check(teleport("mineexit_z3").ok, "salida de la galeria III al Reino")
steps(2)
check(P:GetAttribute("Area") == "z3", "apareces junto a la boca de mina de la Zona 3")
check(not teleport("mineexit_z4").ok and not teleport("m4").ok, "zona 4 bloqueada: ni galeria ni salida")
local entrance
for _, p in ipairs(World.Portals) do if p.dest == "m2" then entrance = p end end
OFFSET = OFFSET + 3
entrance.prompt.Triggered:Fire(P)
RUN_DELAYS()
steps(2)
check(P:GetAttribute("Area") == "m2", "la boca de mina del Reino (zona 2) lleva a la galeria II")

-- 5. Sello de guardian (Fase G, desactivado por defecto) -----------------------------------
WC.Regions[2].mine.guardian.enabled = true
teleport("mines")
steps(2)
local rg = teleport("m2")
check(not rg.ok and rg.msg:find("guardian"), "sello activado: la galeria II pide vencer al guardian")
at(qnode.pos)
check(mineUntil(qnode, "piedra"), "la Cantera sigue libre con sellos activos")
profile.mines.guardians = { m2 = true }
check(teleport("m2").ok, "guardian vencido: galeria abierta")
profile.mines.guardians = nil
WC.Regions[2].mine.guardian.enabled = false

-- 6. Datos -------------------------------------------------------------------------------
check(profile.schemaVersion == 3 and profile.lineage == "main", "perfil v3 con linaje")
check(profile.mines.visited.m1 and profile.mines.visited.m3 and profile.mines.visited.m2, "galerias visitadas guardadas")
print("ALL MINES TESTS PASSED")
