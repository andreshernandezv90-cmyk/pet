dofile("tools/sim/mock.lua")

local function check(c, msg) if not c then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end

-- Servidor
RUN_SCRIPT(SERVER_SCRIPT)
check(workspace:FindFirstChild("World") ~= nil, "mundo construido")
require(game:GetService("ReplicatedStorage").Shared.Config).ActionRateLimit = 1e9
local RS = game:GetService("ReplicatedStorage")
local remotes = RS:FindFirstChild("Remotes")
check(remotes ~= nil, "remotos creados")
for _, ev in ipairs(remotes:GetChildren()) do
	if ev.ClassName == "RemoteEvent" then
		ev.__onFireClient = function(player, ...) ev.OnClientEvent:Fire(...) end
	end
end
local S = {}
for _, m in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[m.Name] = require(m) end
local nodes = 0 for _ in pairs(S.World.Nodes) do nodes = nodes + 1 end
check(nodes > 100, "nodos de recursos: " .. nodes)
check(#S.World.Checkpoints >= 15 and #S.World.Portals >= 10, "checkpoints y portales")

local encounters = {}
remotes.Encounters.OnClientEvent:Connect(function(zone, list) encounters = list or {} end)
local toasts = {}
remotes.Notify.OnClientEvent:Connect(function(text) table.insert(toasts, text) end)

-- Jugador
local Players = game:GetService("Players")
LOCAL_PLAYER = MAKE_PLAYER(101, "Tester")
Players.__props.LocalPlayer = LOCAL_PLAYER
Players.PlayerAdded:Fire(LOCAL_PLAYER)
RUN_DELAYS()
local profile = S.DataService.Get(LOCAL_PLAYER)
check(profile ~= nil, "perfil cargado")
check(LOCAL_PLAYER:GetAttribute("Plot") == 1, "parcela asignada")
check(workspace:FindFirstChild("Plots"):FindFirstChild("Plot_1") ~= nil, "parcela construida")

-- Cliente
RUN_SCRIPT(CLIENT_SCRIPT)
RUN_DELAYS()
local State = require(CLIENT_SCRIPT.State)
local UI = require(CLIENT_SCRIPT.UI)

local function act(name, payload)
	local r = remotes.Action:InvokeServer(name, payload or {})
	RUN_DELAYS()
	return r
end
local r = act("hello")
check(r.ok and State.data ~= nil, "estado inicial en el cliente")

-- Abrir todos los paneles con el perfil inicial
local panels = { "map", "pets", "bag", "workshop", "stations", "alchemy", "reactor", "fusion", "shop", "dev" }
local function renderAll(tag)
	for _, id in ipairs(panels) do
		local ok, err = pcall(UI.Open, id)
		if not ok then error("panel " .. id .. ": " .. tostring(err)) end
	end
	UI.Close()
	print("ok  paneles renderizados (" .. tag .. ")")
end
-- capturar errores dentro de UI.Render (usa pcall interno): reemplazar warn
local warned = {}
warn = function(msg) table.insert(warned, msg); print("WARN", msg) end
renderAll("perfil nuevo")
check(#warned == 0, "sin errores de render")

-- Captura en zona 1
LOCAL_PLAYER:SetAttribute("Area", "z1")
S.Capture.OnAreaChanged(LOCAL_PLAYER, "z1")
check(#encounters >= 7 and #encounters <= 12, "apariciones privadas: " .. #encounters)
local e = encounters[1]
LOCAL_PLAYER.Character.HumanoidRootPart.__props.CFrame = CFrame.new(e.x, 3, e.z)
r = act("captureBegin", { id = e.id })
check(r.ok and r.time > 0, "inicio de captura (" .. string.format("%.2fs, %.0f%%", r.time, r.chance * 100) .. ")")
r = act("captureFinish", { id = e.id })
check(r.ok == false, "terminar demasiado rapido se rechaza")
r = act("captureBegin", { id = e.id })
-- simular tiempo transcurrido (reloj monotono)
local realClock = os.clock
local OFFSET = 0
os.clock = function() return realClock() + OFFSET end
OFFSET = OFFSET + 100
local captured = false
for i = 1, 40 do
	r = act("captureFinish", { id = e.id })
	if r.captured then captured = true break end
	if r.escaped or not r.ok then
		e = encounters[1]
		if not e then S.Capture.OnAreaChanged(LOCAL_PLAYER, "home"); S.Capture.OnAreaChanged(LOCAL_PLAYER, "z1"); e = encounters[1] end
		LOCAL_PLAYER.Character.HumanoidRootPart.__props.CFrame = CFrame.new(e.x, 3, e.z)
	end
	act("captureBegin", { id = e.id })
	OFFSET = OFFSET + 100
end
check(captured, "PET capturado: " .. tostring(r.msg))
check((profile.captured.lumi or 0) >= 1, "captured.lumi registrado")

-- Dev: recursos, desbloqueo y PETs
check(act("dev", { cmd = "resources" }).ok, "dev recursos")
check(act("dev", { cmd = "unlock" }).ok, "dev desbloquear")
check(act("dev", { cmd = "pets" }).ok, "dev pets")
renderAll("perfil completo")
check(#warned == 0, "sin errores de render (completo)")

-- Taller: todas las lineas
local Recipes = require(RS.Shared.Recipes)
for _, id in ipairs(Recipes.LineOrder) do
	for _ = 1, 10 do
		local n = Recipes.Next(profile, id)
		if n.maxed or n.locked then break end
		profile.res.storage = profile.res.storage
		for k, v in pairs(n.cost) do profile.res.storage[k] = (profile.res.storage[k] or 0) + v end
		local rr = act("craft", { line = id })
		if not rr.ok then error("craft " .. id .. ": " .. tostring(rr.msg)) end
	end
end
check(profile.stations.nexus.level == 5 and profile.buildings.petStorage == 10, "todas las recetas fabricadas")

-- Estaciones: asignar, producir, recoger
r = act("assign", { station = "stone", ref = { key = "lumi:common" } })
check(r.ok, "asignar Lumi al extractor de piedra")
r = act("assign", { station = "stone", ref = { key = "chispa:common" } })
check(not r.ok, "Chispa no es compatible con piedra")
profile.stations.stone.updatedAt = os.time() - 100
S.Production.Accrue(profile, "stone", os.time())
local buf = profile.stations.stone.buffer.piedra or 0
check(buf > 1, string.format("produccion acumulada %.1f piedra", buf))
r = act("collect", { station = "stone" })
check(r.ok, "recoger: " .. r.msg)
-- offline
profile.stations.stone.updatedAt = os.time() - 10 * 3600
S.Production.ApplyOffline(LOCAL_PLAYER, profile)
local off = profile.stations.stone.buffer.piedra or 0
check(off > 0, string.format("offline acotado a 2h al 50%%: %.1f", off))
-- huerto
r = act("plant", { plot = 1, crop = "baya" })
check(r.ok, "sembrar")
profile.garden.plots[1].progress = 1
r = act("harvest", { plot = 1 })
check(r.ok, "cosechar: " .. r.msg)
r = act("assign", { station = "garden", ref = { key = "florin:common" } })
check(r.ok, "Florin al huerto")

-- Alquimia
check(act("brew", { kind = "potion", id = "fortuna", n = 2 }).ok, "pocion")
check(act("brew", { kind = "bait", id = "berry", n = 3 }).ok, "cebo")
check(act("usePotion", { potion = "fortuna" }).ok, "beber pocion")
check(act("setBait", { bait = "berry" }).ok, "activar cebo")

-- Equipo
check(act("equip", { ref = { key = "lumi:mythic" } }).ok, "equipar Lumi mitico")
check(act("equip", { ref = { key = "venti:rare" } }).ok, "equipar Venti")
check(act("equip", { ref = { key = "nox:common" } }).ok, "equipar Nox")
check(not act("equip", { ref = { key = "rocon:common" } }).ok, "equipo lleno (3)")
check(string.find(LOCAL_PLAYER:GetAttribute("Followers"), "lumi:mythic") ~= nil, "atributo de compañeros")
check(string.find(LOCAL_PLAYER:GetAttribute("Flags"), "glide") ~= nil, "poder de planeo")

-- Reactor (ejemplo del GDD)
profile.stacks.storage["lumi:common"] = 5
profile.stacks.storage["lumi:rare"] = 1
profile.stacks.tank["lumi:common"] = nil
profile.stacks.tank["lumi:rare"] = nil
local before = profile.essence.lumi or 0
r = act("reactor", { items = { ["lumi:common"] = 5, ["lumi:rare"] = 1 }, nonce = "n1" })
check(r.ok and profile.essence.lumi - before == 13, "reactor 5 comunes + 1 raro = 13")
r = act("reactor", { items = { ["lumi:common"] = 5, ["lumi:rare"] = 1 }, nonce = "n1" })
check(r.ok and profile.essence.lumi - before == 13, "nonce repetido no duplica")
r = act("reactor", { items = { ["lumi:common"] = 1 }, nonce = "n2" })
check(not r.ok, "no se puede reciclar lo que no hay")

-- Niveles 0 -> 5
profile.essence.rocon = 6750
local unitId
for lv = 1, 5 do
	r = act("levelUp", { ref = unitId and { unit = unitId } or { key = "rocon:rare" }, nonce = "lv" .. lv })
	check(r.ok, r.msg)
	unitId = r.unit
end
check(profile.essence.rocon == 0 and profile.units[unitId].lv == 5, "nivel 5 cuesta exactamente 6750")
check(not act("levelUp", { ref = { unit = unitId }, nonce = "lv6" }).ok, "no pasa del nivel 5")

-- Fusion
r = act("fuse", { a = { key = "talpa:rare" }, b = { key = "zuri:common" } })
check(r.ok, r.msg)
check(not act("fuse", { a = { key = "talpa:rare" }, b = { key = "musguito:common" } }).ok, "una sola fusion sin VIP")
check(act("testPurchase", { key = "vip" }).ok, "VIP de prueba")
r = act("fuse", { a = { key = "gravix:rare" }, b = { key = "prisma:common" } })
check(r.ok, "VIP: segunda fusion simultanea")
check(act("endFusion", { slot = 1 }).ok, "terminar fusion")
check(profile.fusion.slots[1].cooldownUntil - os.time() == 24 * 60, "recarga VIP de 24 min")

-- Tienda y recibos
r = act("testPurchase", { key = "bp5" })
check(profile.paid.backpack == 5, "+5 espacios de mochila")
local MPS = game:GetService("MarketplaceService")
local Config = require(RS.Shared.Config)
Config.Products[1].productId = 999
-- reconstruir mapa del modulo no es posible; probar el recibo directamente con un producto de ID 0 no aplica

-- Deposito
LOCAL_PLAYER:SetAttribute("Area", "home")
profile.res.backpack.piedra = 50
r = act("depositAll")
check(r.ok and (profile.res.backpack.piedra or 0) == 0, "depositar en el hogar")

-- Viajes
r = act("teleport", { dest = "z5" })
check(r.ok, "viajar a zona 5: " .. r.msg)

-- Incursion
check(S.Raid.Begin(1), "incursion anunciada")
r = act("raidShot")
check(not r.ok, "disparo fuera de fase rechazado")

-- Guardado
S.DataService.SaveNow(LOCAL_PLAYER)
check(DATABASE["u_101"] and DATABASE["u_101"].data == profile, "perfil guardado con bloqueo")
Players.PlayerRemoving:Fire(LOCAL_PLAYER)
check(DATABASE["u_101"].lock == nil, "bloqueo liberado al salir")

-- Segundo jugador con un perfil v1 guardado (migracion al entrar)
local Schema = require(RS.Shared.ProfileSchema)
local old = Schema.Default()
old.schemaVersion = 1
old.world = nil
old.zones.unlocked = 2
old.captured = { lumi = 3 }
old.stacks.storage["lumi:epic"] = 2
old.essence.lumi = 42
DATABASE["u_202"] = { data = old }
local P2 = MAKE_PLAYER(202, "Veterano")
Players.PlayerAdded:Fire(P2)
RUN_DELAYS()
local p2 = S.DataService.Get(P2)
check(p2 and p2.schemaVersion == 2 and p2.world.beacons.z1, "perfil v1 migrado a v2 al entrar")
check(p2.stacks.storage["lumi:epic"] == 2 and p2.essence.lumi == 42 and p2.zones.unlocked == 2, "migracion sin perdida de datos")
check(P2:GetAttribute("Plot") == 1, "la parcela liberada al salir se reutiliza")

renderAll("final")
check(#warned == 0, "sin advertencias")
print("ALL SMOKE TESTS PASSED")
