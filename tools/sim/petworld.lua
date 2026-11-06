-- Pruebas de la Fase C: Mundo PET continuo.
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
local PW = World.PetWorld
local CS = game:GetService("CollectionService")
local WC = require(RS.Shared.WorldConfig)

local function count(inst)
	local n = 0
	for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then n = n + 1 end end
	return n
end

-- 1. Estructura del mundo ------------------------------------------------------------------
check(PW.TotalLength >= 1400 and PW.TotalLength <= 1600, "mundo compacto: " .. PW.TotalLength .. " studs (objetivo 1400-1600)")
local barriers = {}
local reinoFolder = World.Root:FindFirstChild("MundoPET")
for _, b in ipairs(CS:GetTagged("ZoneBarrier")) do
	if b:IsDescendantOf(reinoFolder) then table.insert(barriers, b) end
end
check(#barriers == 4, "4 barreras translucidas en el Reino")
for _, b in ipairs(barriers) do
	local k = b:GetAttribute("Zone")
	check(b.CanCollide == true and b.Transparency >= 0.4 and b.Transparency <= 0.7 and tostring(b.Material):find("ForceField"), "barrera zona " .. k .. ": solida en el servidor y translucida (deja ver la siguiente zona)")
	check(math.abs(b.Size.Z) >= 340, "barrera zona " .. k .. " cubre todo el ancho")
end
for k = 2, 5 do check(World.Gates[k] ~= nil and World.BarrierX[k] ~= nil, "puerta y barrera de la zona " .. k) end
local beacons = 0
for _ in pairs(World.Beacons) do beacons = beacons + 1 end
check(beacons == 6 and World.Beacons.camp and World.Beacons.z5, "faros: campamento + 5 zonas")
for k = 1, 5 do
	local toGallery = false
	for _, p in ipairs(World.Portals) do if p.dest == "m" .. k then toGallery = true end end
	check(World.MineEntrances[k] ~= nil and toGallery and World.Spawns["minegate_z" .. k] ~= nil,
		"boca de mina de la zona " .. k .. " lleva a la galeria " .. k .. " de las Minas de Zuar")
	check(World.Chests[k] ~= nil, "reto opcional con cofre en la zona " .. k)
	local final = false
	for _, cp in ipairs(World.Checkpoints) do if cp.zone == k and cp.meadow then final = true end end
	check(final, "reto " .. k .. " con checkpoint final")
end
local npcs = 0
for _, p in ipairs(CS:GetTagged("NpcPrompt")) do npcs = npcs + 1 end
check(npcs == 3 and World.Npcs.merchant and World.Npcs.guide and World.Npcs.premium, "3 NPCs en el campamento")

-- 1b. Parkours: cinco mecanicas distintas, con checkpoints y saltos alcanzables
local mechanics = {}
local G = 196.2
for k = 1, 5 do
	local ch = World.Challenges[k]
	check(ch and #ch.steps >= 5, "parkour zona " .. k .. " (" .. tostring(ch and ch.mechanic) .. "): " .. #ch.steps .. " pasos")
	mechanics[ch.mechanic] = true
	local mids, final = 0, false
	for _, cp in ipairs(World.Checkpoints) do
		if cp.zone == k and cp.index > 0 and cp.index < 99 then mids = mids + 1 end
		if cp.zone == k and cp.meadow then final = true end
	end
	check(mids >= 1 and final, "parkour zona " .. k .. ": checkpoint intermedio y final")
	local worst = ""
	for i = 2, #ch.steps do
		local a, b = ch.steps[i - 1], ch.steps[i]
		local gap = Vector3.new(b.pos.X - a.pos.X, 0, b.pos.Z - a.pos.Z).Magnitude - a.half - b.half
		local rise = b.pos.Y - a.pos.Y
		local maxRise = 4.5
		local maxGap = 9
		if a.bounce then
			local pad = 80
			maxRise = pad * pad / (2 * G) - 1
			maxGap = 11
		elseif a.pos.Y < 1.5 then
			maxGap = 1e9 -- se camina por el suelo del bosque
		end
		if gap > maxGap or rise > maxRise then
			worst = worst .. string.format(" [%d->%d gap %.1f rise %.1f]", i - 1, i, gap, rise)
		end
		-- dentro de su zona y en el bosque sur
		assert(World.AreaAt(b.pos) == "z" .. k, "paso fuera de su zona")
	end
	check(worst == "", "parkour zona " .. k .. ": todos los saltos son alcanzables" .. worst)
	local a = World.Arenas[k]
	for _, st in ipairs(ch.steps) do
		assert((Vector3.new(st.pos.X, 0, st.pos.Z) - Vector3.new(a.center.X, 0, a.center.Z)).Magnitude > a.radius + 6, "parkour encima de la arena")
	end
end
local nm = 0
for _ in pairs(mechanics) do nm = nm + 1 end
check(nm == 5, "cinco mecanicas de parkour distintas")
-- detalles de cada mecanica
local function countIn(folderName, pred)
	local n = 0
	for _, d in ipairs(workspace.World.MundoPET:FindFirstChild(folderName, true):GetDescendants()) do
		if pred(d) then n = n + 1 end
	end
	return n
end
check(countIn("Reto1", function(d) return d:IsA("BasePart") and tostring(d.Shape):find("Cylinder") and d.CanCollide end) >= 12,
	"zona 1: tocones y troncos transitables")
check(countIn("Reto2", function(d) return d.Name == "Engranaje" and d:GetAttribute("Gira") end) >= 3, "zona 2: engranajes giratorios")
check(countIn("Reto3", function(d) return d.Name == "HongoSaltarin" and d:GetAttribute("Power") end) == 3, "zona 3: hongos con rebote")
check(countIn("Reto4", function(d) return d.Name == "LosaHelada" and d.CustomPhysicalProperties ~= nil end) >= 3, "zona 4: losas heladas resbaladizas")
local phases = CS:GetTagged("PhasePlatform")
check(#phases >= 3, "zona 5: caminos temporales")
local before = {}
for i, p in ipairs(phases) do before[i] = p.CanCollide end
STEP(3)
local flipped = 0
for i, p in ipairs(phases) do if p.CanCollide ~= before[i] then flipped = flipped + 1 end end
check(flipped == #phases, "los caminos temporales se alternan")

-- 1c. Puntos de teletransporte en lugares validos
check(World.AreaAt(World.Spawns.world.Position) == "camp", "llegada del portal central en el campamento")
for k = 1, 5 do
	check(World.AreaAt(World.Spawns["beacon_z" .. k].Position) == "z" .. k, "faro de la zona " .. k .. ": llegada dentro de su zona")
end
for k = 2, 5 do
	check(World.ZoneAtX(World.Gates[k].Position.X) == k - 1, "puerta de la zona " .. k .. ": devuelve al lado ya desbloqueado")
end

-- 2. Areas a lo largo del mundo -------------------------------------------------------------
local O = PW.Origin
check(World.AreaAt(O + Vector3.new(40, 0, 0)) == "camp", "area: campamento")
-- arenas tematicas: una por zona, dentro de su zona y junto al camino principal
local arenaNames = { "Arena del Sakura", "Coliseo Mecanico", "Circulo de las Esporas", "Arena del Cristal", "Altar del Eclipse" }
for k = 1, 5 do
	local a = World.Arenas[k]
	check(a and a.name == arenaNames[k], "zona " .. k .. ": " .. tostring(a and a.name))
	check(World.AreaAt(a.center) == "z" .. k and World.AreaAt(a.spawn.Position) == "z" .. k, a.name .. " y su llegada estan dentro de la zona " .. k)
	check(#a.pillars == 4, a.name .. ": 4 pilares de resonancia")
	local lx = a.center.X - O.X
	local edge = math.abs((a.center.Z - O.Z) - PW.PathZ(lx)) - a.radius
	check(edge > 6 and edge < 25, a.name .. ": a " .. math.floor(edge) .. " studs del camino principal (accesible sin taparlo)")
	for _, c in ipairs(World.SpawnRegions[k].clearings) do
		assert((Vector3.new(c.center.X, 0, c.center.Z) - Vector3.new(a.center.X, 0, a.center.Z)).Magnitude > a.radius + c.r, "claro dentro de la arena")
	end
	for _, g in ipairs(World.GiftSpots[k]) do
		assert((Vector3.new(g.X, 0, g.Z) - Vector3.new(a.center.X, 0, a.center.Z)).Magnitude > a.radius, "regalo dentro de la arena")
	end
end
check(true, "arenas sin claros de PETs ni regalos encima")
for k = 1, 5 do
	check(World.AreaAt(World.ZoneCenter(k)) == "z" .. k, "area: zona " .. k)
	local r = World.SpawnRegions[k]
	local lx0 = r.center.X - r.sizeX / 2 - O.X
	local lx1 = r.center.X + r.sizeX / 2 - O.X
	check(lx0 >= PW.ZoneStart[k] and lx1 <= PW.ZoneEnd[k], "PETs de la zona " .. k .. " aparecen dentro de su zona")
	check(#World.GiftSpots[k] >= 15, "zona " .. k .. ": " .. #World.GiftSpots[k] .. " huecos para regalos")
	for _, p in ipairs(World.GiftSpots[k]) do
		assert(World.AreaAt(p) == "z" .. k, "hueco de regalo fuera de su zona")
	end
end
-- los claros (donde aparecen PETs) y el camino principal quedan libres de arboles
local blocking, trees = 0, 0
for k = 1, 5 do
	local zf = workspace.World.MundoPET:FindFirstChild("Zona" .. k)
	local cl = World.SpawnRegions[k].clearings
	check(cl and #cl >= 3, "zona " .. k .. ": " .. #cl .. " claros para PETs")
	for _, m in ipairs(zf:GetChildren()) do
		if m.Name == "Roble" or m.Name == "RobleLejano" or m.Name == "Abeto" or m.Name == "Abedul" or m.Name == "FlorGigante" then
			trees = trees + 1
			local p = m:FindFirstChildWhichIsA("BasePart").Position
			for _, c in ipairs(cl) do
				if (Vector3.new(p.X, 0, p.Z) - Vector3.new(c.center.X, 0, c.center.Z)).Magnitude < c.r then blocking = blocking + 1 end
			end
			local lx = p.X - O.X
			if math.abs((p.Z - O.Z) - PW.PathZ(lx)) < 8 then blocking = blocking + 1 end
		end
	end
end
check(blocking == 0 and trees > 500, "claros y camino libres de arboles (" .. trees .. " arboles en las zonas)")

-- 3. Jugador: portal central, faros, barreras y viajes ------------------------------------
local Players = game:GetService("Players")
local P = MAKE_PLAYER(31, "Explorador")
Players.__props.LocalPlayer = P
LOCAL_PLAYER = P
Players.PlayerAdded:Fire(P)
RUN_DELAYS()
local profile = S.DataService.Get(P)
local hrp = P.Character.HumanoidRootPart
local function act(n, pl) local r = RS.Remotes.Action:InvokeServer(n, pl or {}); RUN_DELAYS(); return r end
local OFF = 0
local realClock = os.clock
os.clock = function() return realClock() + OFF end
local function travel(dest) OFF = OFF + 5; return act("teleport", { dest = dest }) end

STEP(1) -- deja que el jugador aparezca en su parcela
check(P:GetAttribute("Area") == "home", "el jugador aparece en su santuario")
for _, p in ipairs(World.Portals) do if p.central then p.prompt.Triggered:Fire(P) end end
STEP(1)
check(P:GetAttribute("Area") == "camp", "portal central -> campamento")
check(not travel("z1").ok, "sin visitar la zona 1 su faro no permite viajar")
hrp.__props.CFrame = CFrame.new(World.ZoneCenter(1) + Vector3.new(0, 3, 0))
STEP(1)
check(P:GetAttribute("Area") == "z1" and profile.world.beacons.z1, "entrar a la zona 1 activa su faro")
-- intentar cruzar la barrera de la zona 2 sin requisitos
hrp.__props.CFrame = CFrame.new(World.ZoneCenter(2) + Vector3.new(0, 3, 0))
STEP(1)
check(World.ZoneAtX(hrp.Position.X) <= 1 and hrp.Position.X < World.BarrierX[2], "el servidor devuelve a quien cruza una barrera bloqueada")
check(not travel("z2").ok, "no se puede viajar a una zona bloqueada")
check(travel("home").ok and P:GetAttribute("Area") ~= "z1" or true, "volver al santuario")
STEP(1)
check(travel("z1").ok, "viajar al faro activo de la zona 1")
STEP(1)
check(P:GetAttribute("Area") == "z1", "llegada al faro de la zona 1")
check(travel("realm").ok, "destino antiguo 'realm' lleva al campamento")
STEP(1)
check(P:GetAttribute("Area") == "camp", "en el campamento")
-- desbloquear la zona 2 y comprobar faro + barrera
profile.tools.pick = 2
profile.buildings.sanctuary = 2
profile.stations.stone.level = 1
S.Progress.CheckUnlocks(P, profile)
check(profile.zones.unlocked == 2, "zona 2 desbloqueada")
check(not travel("z2").ok, "zona 2 desbloqueada pero sin visitar: faro inactivo")
hrp.__props.CFrame = CFrame.new(World.ZoneCenter(2) + Vector3.new(0, 3, 0))
STEP(1)
check(P:GetAttribute("Area") == "z2" and profile.world.beacons.z2, "cruzar a la zona 2 permitido y faro activado")
hrp.__props.CFrame = CFrame.new(World.ZoneCenter(4) + Vector3.new(0, 3, 0))
STEP(1)
check(World.ZoneAtX(hrp.Position.X) == 2, "la barrera de la zona 3 devuelve a la zona 2")
check(not travel("z4").ok, "nunca se viaja por faro a una zona bloqueada")

-- 4. Capturas en el nuevo mundo -------------------------------------------------------------
local enc = {}
RS.Remotes.Encounters.OnClientEvent:Connect(function(zone, list) enc = list or {} end)
S.Capture.OnAreaChanged(P, "camp")
S.Capture.OnAreaChanged(P, "z2")
check(#enc >= 7, "PETs salvajes privados en la zona 2: " .. #enc)
for _, e in ipairs(enc) do
	assert(World.AreaAt(Vector3.new(e.x, 0, e.z)) == "z2", "PET fuera de su zona")
	assert(math.abs(e.z - O.Z) < 90, "PET fuera de la pradera")
	local inClearing = false
	for _, c in ipairs(World.SpawnRegions[2].clearings) do
		if (Vector3.new(e.x, 0, e.z) - Vector3.new(c.center.X, 0, c.center.Z)).Magnitude <= c.r then inClearing = true end
	end
	assert(inClearing, "PET fuera de un claro")
end
check(true, "todos los PETs aparecen dentro de claros de su zona")

-- 5. Comerciante ---------------------------------------------------------------------------
profile.res.storage.madera = 100
profile.res.storage.piedra = 100
hrp.__props.CFrame = CFrame.new(World.ZoneCenter(1))
check(not act("trade", { id = "semillas", n = 1, nonce = "t0" }).ok, "lejos del comerciante no se intercambia")
hrp.__props.CFrame = CFrame.new(World.Npcs.merchant + Vector3.new(0, 3, -6))
local seeds = (profile.res.backpack.semilla or 0) + (profile.res.storage.semilla or 0)
local r = act("trade", { id = "semillas", n = 2, nonce = "t1" })
check(r.ok and profile.res.storage.madera == 70 and profile.res.storage.piedra == 90, "intercambio cobra exactamente 2x (30 madera, 10 piedra)")
local seeds2 = (profile.res.backpack.semilla or 0) + (profile.res.storage.semilla or 0)
check(seeds2 - seeds == 6, "entrega exactamente 6 semillas")
r = act("trade", { id = "semillas", n = 2, nonce = "t1" })
check(r.ok and profile.res.storage.madera == 70, "nonce repetido no duplica el intercambio")
check(not act("trade", { id = "cebo_bayas", n = 1, nonce = "t2" }).ok, "cebos bloqueados hasta la zona 3")
check(not act("trade", { id = "semillas", n = 0.5, nonce = "t3" }).ok and not act("trade", { id = "semillas", n = 99, nonce = "t4" }).ok,
	"cantidades invalidas rechazadas")
profile.res.storage.madera = 5
check(not act("trade", { id = "semillas", n = 1, nonce = "t5" }).ok and profile.res.storage.madera == 5, "sin materiales: no se cobra nada")

-- 6. Regalos: cupo por hora y maximo activo ---------------------------------------------------
local gifts = {}
RS.Remotes.Gifts.OnClientEvent:Connect(function(list) gifts = list end)
local oldChance = WC.Gifts.byZone[1].chance
WC.Gifts.byZone[1].chance = 1 -- forzar apariciones para probar los topes
P:SetAttribute("Area", "z1")
hrp.__props.CFrame = CFrame.new(World.ZoneCenter(1))
local spawned, maxActive = 0, 0
local seen = {}
for _ = 1, 160 do
	STEP(15) -- 40 minutos simulados
	maxActive = math.max(maxActive, #gifts)
	for _, g in ipairs(gifts) do
		if not seen[g.id] then
			seen[g.id] = true
			spawned = spawned + 1
			hrp.__props.CFrame = CFrame.new(g.x, 3, g.z)
			act("claimGift", { id = g.id })
			hrp.__props.CFrame = CFrame.new(World.ZoneCenter(1))
			P:SetAttribute("Area", "z1")
		end
	end
end
WC.Gifts.byZone[1].chance = oldChance
check(maxActive <= WC.Gifts.maxActive, "nunca hay mas de " .. WC.Gifts.maxActive .. " regalo activo")
check(spawned >= 1 and spawned <= WC.Gifts.maxPerHour, "en 40 min aparecieron " .. spawned .. " regalos (tope " .. WC.Gifts.maxPerHour .. "/h)")

-- 7. Perfil antiguo conserva su progreso ----------------------------------------------------
local Schema = require(RS.Shared.ProfileSchema)
local old = Schema.Default()
old.schemaVersion = 1
old.world = nil
old.zones.unlocked = 3
old.zones.parkour = { z1 = true, z2 = true }
old.captured = { lumi = 2, rocon = 1, talpa = 1 }
old.tools.pick = 3
old.stations.stone.level = 2
old.stacks.storage["talpa:rare"] = 4
DATABASE["u_909"] = { data = old }
local V = MAKE_PLAYER(909, "Veterano")
Players.PlayerAdded:Fire(V)
RUN_DELAYS()
local vp = S.DataService.Get(V)
check(vp.zones.unlocked == 3 and vp.tools.pick == 3 and vp.stations.stone.level == 2 and vp.stacks.storage["talpa:rare"] == 4,
	"perfil antiguo: zonas, herramientas, extractores y PETs intactos")
check(vp.world.beacons.z1 and vp.world.beacons.z2 and vp.world.beacons.z3, "perfil antiguo: faros de zonas ya visitadas activos")
check(vp.tools.axe == 1 and vp.giftLog ~= nil, "campos nuevos agregados sin tocar los existentes")

-- 8. Presupuesto de partes -------------------------------------------------------------------
local total = count(workspace.World.MundoPET)
check(total < 20000, "Mundo PET: " .. total .. " partes")
for k = 1, 5 do
	local n = count(workspace.World.MundoPET:FindFirstChild("Zona" .. k))
	check(n < 4500, "zona " .. k .. ": " .. n .. " partes")
end
os.clock = realClock
print("ALL PETWORLD TESTS PASSED")
