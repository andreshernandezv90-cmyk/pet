-- Pruebas de la Fase B: santuario, parcelas, casa, estaciones y portal.
dofile("tools/sim/mock.lua")
local function check(c, msg) if not c then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

RUN_SCRIPT(SERVER_SCRIPT)
local RS = game:GetService("ReplicatedStorage")
require(RS.Shared.Config).ActionRateLimit = 1e9
for _, ev in ipairs(RS.Remotes:GetChildren()) do
	if ev.ClassName == "RemoteEvent" then ev.__onFireClient = function(p, ...) ev.OnClientEvent:Fire(...) end end
end
local S = {}
for _, m in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[m.Name] = require(m) end
local World = S.World
local Layout = require(SERVER_SCRIPT.Services.World.PlotLayout)
local House = require(SERVER_SCRIPT.Services.World.House)

local function count(inst)
	local n = 0
	for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then n = n + 1 end end
	return n
end

-- 1. Distribucion: ninguna reserva se superpone con otra
local items = {}
local function circle(name, x, z, r) table.insert(items, { name = name, x = x, z = z, r = r }) end
circle("fogata", Layout.Campfire.x, Layout.Campfire.z, Layout.Campfire.r)
circle("spawn", Layout.Spawn.x, Layout.Spawn.z, Layout.Spawn.r)
circle("letrero", Layout.Sign.x, Layout.Sign.z, Layout.Sign.r)
circle("estanque", Layout.Pond.x, Layout.Pond.z, Layout.Pond.r + 3)
for id, s in pairs(Layout.Spots) do
	if s.w then circle(id, s.x, s.z, math.sqrt((s.w / 2) ^ 2 + (s.d / 2) ^ 2) * 0.75) else circle(id, s.x, s.z, s.r) end
end
for id, d in pairs(Layout.Decos) do circle("deco_" .. id, d.x, d.z, d.r) end
local overlaps = {}
for i = 1, #items do
	for j = i + 1, #items do
		local a, b = items[i], items[j]
		local dist = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
		if dist < (a.r + b.r) * 0.92 then table.insert(overlaps, a.name .. "/" .. b.name) end
	end
	local a = items[i]
	local H = Layout.House
	if math.abs(a.x - H.x) < H.w / 2 + a.r * 0.9 and math.abs(a.z - H.z) < H.d / 2 + a.r * 0.9 then
		table.insert(overlaps, a.name .. "/casa")
	end
	local entrance = math.abs(a.x) < 12 and a.z < 0
	if not entrance and math.max(math.abs(a.x), math.abs(a.z)) + a.r > Layout.Usable + 3 then
		table.insert(overlaps, a.name .. "/bosque")
	end
end
check(#overlaps == 0, "reservas de la parcela sin superposiciones " .. table.concat(overlaps, ","))
-- las estaciones no quedan sobre caminos
local blocked = {}
for id, s in pairs(Layout.Spots) do
	for _, path in ipairs(Layout.Paths) do
		local last = path.points[#path.points]
		local leadsHere = math.sqrt((last[1] - s.x) ^ 2 + (last[2] - s.z) ^ 2) < (s.r or 0) + 2.5
		for k = 1, leadsHere and 0 or #path.points - 1 do
			local a, b = path.points[k], path.points[k + 1]
			local d = Layout.DistToSeg(s.x, s.z, a[1], a[2], b[1], b[2])
			local r = s.r or 0
			if not s.w and d < r + path.width / 2 - 1.5 then table.insert(blocked, id) end
		end
	end
end
check(#blocked == 0, "ninguna estacion tapa un camino " .. table.concat(blocked, ","))

-- 2. Las 8 parcelas tienen bosque, arboles talables, areas de trabajo y NINGUN portal propio
check(#World.PlotCenters == 8, "8 parcelas")
local plotsFolder = workspace.World.Hogar.Parcelas
for i = 1, 8 do
	local pf = plotsFolder:FindFirstChild("Parcela" .. i)
	check(pf ~= nil and count(pf) > 200, "parcela " .. i .. " con bosque y decoracion (" .. count(pf) .. " partes)")
	check(pf:FindFirstChild("Portal", true) == nil, "parcela " .. i .. " sin portal propio")
	local signs, arches = 0, 0
	for _, d in ipairs(pf:GetDescendants()) do
		if d.Name == "Letrero" then signs = signs + 1 end
		if d.Name == "ArcoLetrero" then arches = arches + 1 end
	end
	check(signs >= 4 and arches == 2, "parcela " .. i .. ": letreros de areas (" .. signs .. " + " .. arches .. " arcos)")
	check(pf:FindFirstChild("Fogata") ~= nil, "parcela " .. i .. ": fogata frente a la casa")
	local chop = 0
	for _, n in pairs(World.Nodes) do
		if n.type == "tree" and n.model:IsDescendantOf(pf) then chop = chop + 1 end
	end
	check(chop >= 4, "parcela " .. i .. ": " .. chop .. " arboles talables")
end
local central = 0
for _, p in ipairs(World.Portals) do
	check(not p.plot, "ningun portal por parcela registrado")
	if p.central then central = central + 1 end
end
check(central == 1 and World.CentralPortal ~= nil, "un unico portal central en la plaza")
-- terreno: el interior de las parcelas usa cesped corto (LeafyGrass), los caminos tierra
local leafy, ground = 0, 0
for _, o in ipairs(TERRAIN_OPS) do
	if tostring(o.mat):find("LeafyGrass") then leafy = leafy + 1 end
	if tostring(o.mat):find("Ground") then ground = ground + 1 end
end
check(leafy >= 8 and ground > 50, "cesped corto en parcelas y caminos de tierra clara")

-- 3. La casa se construye en los 5 niveles con presupuesto razonable de partes
local prev = 0
for lv = 1, 5 do
	local f = Instance.new("Folder")
	f.Parent = workspace
	House.Build(f, CFrame.new(0, 0, 0), lv, Random.new(1))
	local n = count(f)
	check(n > 80 and n < 420, "casa nivel " .. lv .. ": " .. n .. " partes")
	f:Destroy()
end

-- 4. Jugadores: parcela, casa y estaciones cambian con el progreso; el portal de la casa funciona
local Players = game:GetService("Players")
local P = MAKE_PLAYER(77, "Constructor")
Players.__props.LocalPlayer = P
LOCAL_PLAYER = P
Players.PlayerAdded:Fire(P)
RUN_DELAYS()
local profile = S.DataService.Get(P)
local idx = P:GetAttribute("Plot")
local plotModel = workspace.Plots:FindFirstChild("Plot_" .. idx)
check(plotModel and plotModel:FindFirstChild("Casa"), "casa construida en la parcela del jugador")
local before = count(plotModel)
local function act(n, pl) local r = RS.Remotes.Action:InvokeServer(n, pl or {}); RUN_DELAYS(); return r end
act("dev", { cmd = "resources" })
check(act("craft", { line = "sanctuary" }).ok, "mejorar santuario a nivel 2")
check(act("craft", { line = "station_stone" }).ok, "construir extractor de piedra")
plotModel = workspace.Plots:FindFirstChild("Plot_" .. idx)
check(plotModel:GetAttribute("RoofY") ~= nil and count(plotModel) ~= before, "la parcela se reconstruye al mejorar")
local prompts = 0
for _, d in ipairs(plotModel:GetDescendants()) do
	if d.ClassName == "ProximityPrompt" then prompts = prompts + 1 end
end
check(prompts == 13, "13 estaciones con interaccion (" .. prompts .. ")")
-- abrir una estacion desde su prompt
local opened
RS.Remotes.OpenPanel.OnClientEvent:Connect(function(panel) opened = panel end)
for _, d in ipairs(plotModel:GetDescendants()) do
	if d.ClassName == "ProximityPrompt" and d:GetAttribute("Spot") == "stone" then
		game:GetService("ProximityPromptService").PromptTriggered:Fire(d, P)
	end
end
check(opened == "stations", "el extractor abre el panel de estaciones")
-- trabajador visible
check(act("assign", { station = "stone", ref = { key = "lumi:common" } }).ok == false, "sin Lumi no hay trabajador (esperado)")
profile.stacks.storage["lumi:common"] = 2
check(act("assign", { station = "stone", ref = { key = "lumi:common" } }).ok, "asignar Lumi")
plotModel = workspace.Plots:FindFirstChild("Plot_" .. idx)
local workers = 0
for _, d in ipairs(plotModel:GetDescendants()) do if d.ClassName == "Model" and d.Name == "Lumi" then workers = workers + 1 end end
check(workers == 1, "el trabajador aparece junto al extractor")
-- portal central -> Mundo PET (en esta etapa: el Reino actual)
local portalPrompt
for _, p in ipairs(World.Portals) do if p.central then portalPrompt = p.prompt end end
P.Character.HumanoidRootPart.__props.CFrame = World.Spawns.hub
portalPrompt.Triggered:Fire(P)
local pos = P.Character:GetPivot().Position
check(World.AreaAt(pos) == "camp", "el portal central lleva al campamento del Mundo PET")
-- hacha por niveles: mejora el talado
local Items = require(RS.Shared.Items)
check(profile.tools.axe == 1, "hacha inicial: " .. Items.Axes[1].name)
check(act("craft", { line = "axe" }).ok and profile.tools.axe == 2, "fabricar Hacha de piedra")
local tree
for _, n in pairs(World.Nodes) do
	if n.type == "tree" and n.area == "home" then tree = n break end
end
P.Character.HumanoidRootPart.__props.CFrame = CFrame.new(tree.pos)
local OFF = 0
local realClock = os.clock
os.clock = function() return realClock() + OFF end
local hits = 0
local before = profile.res.backpack.madera or 0
for _ = 1, 10 do
	OFF = OFF + 1
	game:GetService("ProximityPromptService").PromptTriggered:Fire(tree.prompt, P)
	hits = hits + 1
	if (profile.res.backpack.madera or 0) > before then break end
end
os.clock = realClock
check(hits == 2, "con Hacha de piedra un arbol cae en 2 golpes (" .. hits .. ")")
P.Character.HumanoidRootPart.__props.CFrame = S.Plots.SpawnCFrame(P)
-- spawn dentro de la parcela, frente a la casa
local sp = S.Plots.SpawnCFrame(P)
local lp = World.PlotCenters[idx]:PointToObjectSpace(sp.Position)
check(math.abs(lp.X) < 2 and lp.Z < 0 and World.AreaAt(sp.Position) == "home", "aparicion frente a la casa")
check(sp.LookVector:Dot((World.PlotCenters[idx] * CFrame.new(0, 4, 36)).Position - sp.Position) > 0, "al aparecer se mira hacia la casa")

-- 5. Regalos aleatorios: privados, validados y configurables por zona
local giftsSeen = {}
RS.Remotes.Gifts.OnClientEvent:Connect(function(list) giftsSeen = list end)
P:SetAttribute("Area", "z1")
S.Gifts.ForceSpawn(P, 1)
check(#giftsSeen == 1, "aparece un regalo en la zona 1")
local g = giftsSeen[1]
P.Character.HumanoidRootPart.__props.CFrame = CFrame.new(g.x + 100, 3, g.z)
check(not act("claimGift", { id = g.id }).ok, "no se abre desde lejos")
P.Character.HumanoidRootPart.__props.CFrame = CFrame.new(g.x, 3, g.z)
local opened0 = profile.giftsOpened
local r = act("claimGift", { id = g.id })
check(r.ok and profile.giftsOpened == opened0 + 1, "regalo abierto: " .. tostring(r.reward))
check(not act("claimGift", { id = g.id }).ok and #giftsSeen == 0, "no se puede abrir dos veces")
local WC = require(RS.Shared.WorldConfig)
for z = 1, 5 do check(WC.Gifts.byZone[z] and WC.Gifts.byZone[z].chance <= 0.2, "zona " .. z .. ": regalos poco frecuentes") end

-- 6. Presupuesto de partes del santuario
local static = count(workspace.World.Hogar)
check(static < 9000, "santuario estatico: " .. static .. " partes")
print("ALL SANCTUARY TESTS PASSED")
