-- Pruebas de la integracion de Rocon (Comun, Raro, Epico y Legendario; sin mitico).
-- Ejecutar: lua5.4 tools/sim/rocon.lua
-- Las plantillas son SIMULADAS con la estructura de los FBX aprobados (MeshPart con los
-- 29 huesos del rig Rocon_v3, SurfaceAppearance, AnimationController, Rig = "Rocon_v3";
-- tamaños de la malla en reposo medidos en Blender). Los mapas de color son marcadores.
-- Los 7 ids de animacion son los publicados (PetAssets.AnimationSets.Rocon_v3).
dofile("tools/sim/mock.lua")
local function check(c, msg) if not c then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-6) end
local warnings = {}
warn = function(...) local t = {} for i, v in ipairs({ ... }) do t[i] = tostring(v) end table.insert(warnings, table.concat(t, " ")) print("WARN", ...) end
local function warned(pattern)
	for _, w in ipairs(warnings) do if w:find(pattern, 1, true) then return true end end
	return false
end

RUN_SCRIPT(SERVER_SCRIPT)
local RS = game:GetService("ReplicatedStorage")
require(RS.Shared.Config).ActionRateLimit = 1e9
local PetModels = require(RS.Shared.PetModels)
local PetAssets = require(RS.Shared.PetAssets)
local PetAnimator = require(RS.Shared.PetAnimator)
local PetGrounding = require(RS.Shared.PetGrounding)
local PetCatalog = require(RS.Shared.PetCatalog)

local STATES = { "Idle", "Walk", "Run", "Happy", "Sleep_Enter", "Sleep_Loop", "Work" }
local MODELS = { common = "Rocon", rare = "Rocon_rare", epic = "Rocon_epic", legendary = "Rocon_legendary" }
local BODIES = { common = "Rocon_Comun_Body", rare = "Rocon_Raro_Body", epic = "Rocon_Epico_Body", legendary = "Rocon_Legendario_Body" }
-- Malla en reposo (X ancho con brazos, Y alto, Z fondo), de Etapa4_Roblox_Export/Validacion_Compatibilidad
local SIZES = { common = Vector3.new(1.8982, 1.6966, 1.0762), rare = Vector3.new(1.8977, 1.6610, 1.0753),
	epic = Vector3.new(2.0000, 1.7876, 1.1339), legendary = Vector3.new(2.0000, 1.7876, 1.1339) }
local HIER = { { "Root", nil }, { "Pelvis", "Root" }, { "Spine", "Pelvis" }, { "Chest", "Spine" }, { "Head", "Chest" } }
for _, s in ipairs({ "L", "R" }) do
	for _, h in ipairs({ { "Shoulder_", "Chest" }, { "UpperArm_", "Shoulder_" .. s }, { "Forearm_", "UpperArm_" .. s },
		{ "Hand_", "Forearm_" .. s }, { "Fingers_01_", "Hand_" .. s }, { "Fingers_02_", "Fingers_01_" .. s },
		{ "Thumb_01_", "Hand_" .. s }, { "Thumb_02_", "Thumb_01_" .. s }, { "Thigh_", "Pelvis" }, { "Shin_", "Thigh_" .. s },
		{ "Foot_", "Shin_" .. s }, { "Toe_", "Foot_" .. s } }) do
		table.insert(HIER, { h[1] .. s, h[2] })
	end
end
check(#HIER == 29, "rig Rocon_v3 simulado con 29 huesos")

-- 0) Reglas de especie: sin mitico, zona 2, extractor de piedra (sin cambios) -------------
local rarities = {}
for _, r in ipairs(PetCatalog.RaritiesFor("rocon")) do table.insert(rarities, r.id) end
check(table.concat(rarities, ",") == "common,rare,epic,legendary", "Rocon tiene exactamente Comun, Raro, Epico y Legendario")
check(PetCatalog.ParseKey("rocon:mythic") == nil and PetCatalog.ParseKey("rocon:mythic:shiny") == nil, "rocon:mythic no es una clave valida")
local sp = PetCatalog.Get("rocon")
check(sp.zone == 2 and sp.mythic == false and sp.jobs.stone == 0.25, "zona 2, sin mitico y extractor de piedra (tasa del catalogo)")
local lumiMythic = false
for _, r in ipairs(PetCatalog.RaritiesFor("lumi")) do if r.id == "mythic" then lumiMythic = true end end
check(lumiMythic and PetCatalog.ParseKey("lumi:mythic") == "lumi", "las reglas miticas de Lumi no cambian")

-- 1) Sin plantillas de Rocon: procedural de siempre, sin avisos -----------------------------
local folder = Instance.new("Folder")
folder.Name = "PetAssets"
folder.Parent = RS
local function makeTemplate(name, bodyName, size, colorMap, rig)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Rig", rig)
	local body = Instance.new("MeshPart")
	body.Name = bodyName
	body.Size = size
	body.CFrame = CFrame.new(0, size.Y / 2, 0)
	body.Anchored = true
	body.Parent = m
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMap = colorMap
	sa.Parent = body
	local bones = {}
	for _, h in ipairs(rig == "Rocon_v3" and HIER or { { "Root", nil } }) do
		local b = Instance.new("Bone")
		b.Name = h[1]
		b.Parent = h[2] and bones[h[2]] or body
		bones[h[1]] = b
	end
	local ac = Instance.new("AnimationController")
	ac.Parent = m
	Instance.new("Animator").Parent = ac
	m.PrimaryPart = body
	m.Parent = folder
	return m
end
-- Lumi presente como en el repositorio (para comprobar que convive sin cambios)
makeTemplate("Lumi", "Lumi_Comun_Body", Vector3.new(1.1831539, 1.6666665, 1.5838034), "SIM_textura_lumi", "Lumi_v7")
for _, r in ipairs(rarities) do
	local m = PetModels.Build("rocon", r)
	check(m:GetAttribute("Source") ~= "asset" and m:GetAttribute("Species") == "rocon" and m:GetAttribute("Rarity") == r,
		r .. ": sin plantillas, Rocon sigue siendo procedural")
end
check(not warned("Rocon"), "sin plantillas de Rocon no hay avisos en Output")
check(PetModels.Build("lumi", "common"):GetAttribute("AssetName") == "Lumi", "Lumi sigue usando su plantilla")

-- 2) Con las 4 plantillas: cada rareza usa su modelo, textura, alto y apoyo ----------------
-- Medidas reales en Studio (2026-11-07, modo Cliente, zona 2): Root animado respecto a la base
-- de reposo, en studs, y alto del modelo en ese momento. Legendario no se midio (= Epico).
local MEASURED = { common = -0.576, rare = -0.599, epic = -0.692 }
local MEASURED_H = { common = 2.0, rare = 2.2, epic = 2.4 }
local FOOT_INSET = { common = -0.288, rare = -0.2723, epic = -0.2883, legendary = -0.2883 }
for _, r in ipairs(rarities) do
	makeTemplate(MODELS[r], BODIES[r], SIZES[r], "SIM_textura_rocon_" .. r, "Rocon_v3")
end
local function colorMapOf(m)
	local sa = m.PrimaryPart and m.PrimaryPart:FindFirstChildOfClass("SurfaceAppearance")
	return sa and sa.ColorMap
end
for _, r in ipairs(rarities) do
	local rar = PetCatalog.Rarity(r)
	local m = PetModels.Build("rocon", r, { label = "Rocon" })
	check(m:GetAttribute("AssetName") == MODELS[r] and m:GetAttribute("Rig") == "Rocon_v3" and colorMapOf(m) == "SIM_textura_rocon_" .. r
		and m.PrimaryPart.Name == BODIES[r], r .. ": modelo " .. MODELS[r] .. " con su textura y su MeshPart")
	local _, size = m:GetBoundingBox()
	local h = 2 * rar.size
	check(near(size.Y, h, 1e-3), r .. ": alto " .. string.format("%.2f", size.Y) .. " studs (igual que el procedural)")
	-- Regresion del apoyo (medidas en Studio): con la animacion, Root queda MEASURED[r] studs
	-- por debajo de la base de reposo; GroundOffset debe compensarlo exactamente.
	local inset = PetAssets.Species.rocon.variants[r].footInset
	check(near(inset, FOOT_INSET[r], 1e-9) and near(m:GetAttribute("GroundOffset"), h / 2 - inset * h, 1e-3),
		r .. ": GroundOffset = alto/2 - footInset*alto (footInset " .. inset .. ")")
	m:PivotTo(PetGrounding.PivotCFrame(Vector3.new(0, 5, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, -1), m:GetAttribute("GroundOffset")))
	local bb, s2 = m:GetBoundingBox()
	local restBase = bb.Position.Y - s2.Y / 2
	if MEASURED[r] then
		check(math.abs(restBase + MEASURED[r] * h / MEASURED_H[r] - 5) < 0.002,
			r .. ": el Root animado medido en Studio queda en el suelo (error " .. string.format("%.4f", restBase + MEASURED[r] * h / MEASURED_H[r] - 5) .. " studs)")
	end
	check(restBase > 5 and near(restBase - 5, -inset * h, 1e-3), r .. ": la base de REPOSO queda elevada lo que baja el rig animado")
end
check(not warned("Rocon"), "con las 4 plantillas no hay avisos de Rocon")
local ml = PetModels.Build("lumi", "common")
check(near(ml:GetAttribute("GroundOffset"), 1.0, 1e-3) and (PetAssets.Species.lumi.footInset or 0) == 0 and next(PetAssets.Species.lumi.variants) == nil,
	"Lumi conserva su apoyo (GroundOffset = alto/2, sin footInset)")
check(PetModels.Build("lumi", "rare"):GetAttribute("AssetName") == "Lumi", "Lumi raro sin cambios (sigue con su respaldo actual)")
-- Shiny: misma plantilla de su rareza + particulas; Shiny no es una rareza ni cambia el modelo
local ms = PetModels.Build("rocon", "epic", { shiny = true })
check(ms:GetAttribute("AssetName") == "Rocon_epic" and ms:GetAttribute("Rarity") == "epic" and ms:GetAttribute("Shiny") == true
	and ms.PrimaryPart:FindFirstChild("ShinySparkles") ~= nil, "Rocon epico Shiny: usa Rocon_epic con particulas Shiny")

-- 3) Animaciones -------------------------------------------------------------------------
-- Ids publicados por el dueño del proyecto (docs/ART_PIPELINE.md, seccion 15)
local PUBLISHED = {
	Idle = "rbxassetid://99191665025042", Walk = "rbxassetid://79078597091924", Run = "rbxassetid://119802077605294",
	Happy = "rbxassetid://139430381617586", Sleep_Enter = "rbxassetid://80979103631192",
	Sleep_Loop = "rbxassetid://124646034769643", Work = "rbxassetid://100611091362223",
}
local ids = PetAssets.AnimationSets.Rocon_v3.ids
local exact = PetAssets.AnimationSets.Rocon_v3.rig == "Rocon_v3"
for _, s in ipairs(STATES) do if ids[s] ~= PUBLISHED[s] then exact = false end end
local nIds = 0
for _ in pairs(ids) do nIds = nIds + 1 end
check(exact and nIds == 7, "Rocon_v3 tiene exactamente los 7 ids publicados")
local lumiIds = PetAssets.AnimationSets.Lumi_v7.ids
check(lumiIds.Idle == "rbxassetid://123787685829164" and lumiIds.Work == "rbxassetid://138174795961249", "los ids de Lumi no cambian")
local seen = {}
for _, r in ipairs(rarities) do
	local m = PetModels.Build("rocon", r)
	local a = PetAnimator.Attach(m)
	check(a ~= nil and a.tracks.Idle and #m:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator").__tracks == 7,
		r .. ": 7 pistas cargadas una sola vez")
	for _, s in ipairs(STATES) do
		check(a.tracks[s].Animation.AnimationId == PUBLISHED[s], r .. ": " .. s .. " usa el id del conjunto compartido")
		seen[a.tracks[s].Animation] = true
	end
	check(a.tracks.Idle.Looped and a.tracks.Walk.Looped and a.tracks.Run.Looped and a.tracks.Work.Looped and a.tracks.Sleep_Loop.Looped
		and not a.tracks.Happy.Looped and not a.tracks.Sleep_Enter.Looped, r .. ": bucles correctos (Happy y Sleep_Enter sin bucle)")
	-- Velocidad nativa: Walk a 0,269 alturas/s y Run a 0,774 alturas/s del alto real
	local h = m:GetAttribute("Radius") * 2
	check(near(a.walkRef, 0.269 * h, 1e-9) and near(a.runRef, 0.774 * h, 1e-9), r .. ": referencias de Walk/Run segun su alto (" .. string.format("%.2f", h) .. " studs)")
	check(a:SetMoveSpeed(0) == "Idle", r .. ": quieto -> Idle")
	local v = 0.9 * a.walkRef * 1.5 -- dentro del rango de ajuste: sin deslizamiento
	if v >= PetAssets.Locomotion.walk then
		check(a:SetMoveSpeed(v) == "Walk" and near(a.speed, v / a.walkRef, 1e-9), r .. ": Walk al ritmo de la velocidad real")
	end
	local tr = a.tracks.Walk
	local plays = tr.__plays or 0
	a:SetMoveSpeed(v)
	a:SetMoveSpeed(v)
	check(a:GetState() == "Walk" and (tr.__plays or 0) == plays, r .. ": pedir el mismo estado no reinicia la pista")
	check(a:SetMoveSpeed(20) == "Run" and near(a.speed, 1.8, 1e-9), r .. ": Run al correr (con el limite de 1,8)")
	check(a:Celebrate() == "Happy", r .. ": Happy")
	a.tracks.Happy:__finish()
	check(a:GetState() == "Run", r .. ": al terminar Happy vuelve a la locomocion")
	a:SetMoveSpeed(0)
	check(a:Sleep() and a:GetState() == "Sleep_Enter", r .. ": Sleep_Enter")
	a.tracks.Sleep_Enter:__finish()
	check(a:GetState() == "Sleep_Loop", r .. ": enlaza con Sleep_Loop")
	a:SetMoveSpeed(3)
	check(not a:IsSleeping() and a:GetState() == "Walk", r .. ": si se desplaza, despierta (nunca se desliza dormido)")
	check(a:SetWorking(true) == "Work" and a:SetWorking(false) == "Idle", r .. ": Work y vuelta a Idle")
	a:Destroy()
end
local nAnim = 0
for _ in pairs(seen) do nAnim = nAnim + 1 end
check(nAnim == 7, "7 objetos Animation compartidos por las 4 rarezas (sin duplicar)")
-- Lumi conserva sus ids y sus referencias globales de velocidad
local la = PetAnimator.Attach(PetModels.Build("lumi", "common"))
check(la.tracks.Idle.Animation.AnimationId == "rbxassetid://123787685829164" and la.walkRef == PetAssets.Locomotion.referenceWalkSpeed
	and la.runRef == PetAssets.Locomotion.referenceRunSpeed, "Lumi: mismos ids y mismas referencias de velocidad que antes")
la:SetMoveSpeed(2)
check(near(la.speed, 2 / 4, 1e-9), "Lumi: Walk a 2 studs/s sigue a velocidad 0,5 (formula anterior)")
la:Destroy()
-- Rig incompatible: no se anima con Rocon_v3
folder:FindFirstChild("Rocon_rare"):SetAttribute("Rig", "Otro")
check(PetAnimator.Attach(PetModels.Build("rocon", "rare")) == nil and warned("Rig=Otro"), "una plantilla con otro rig no se anima (aviso)")
folder:FindFirstChild("Rocon_rare"):SetAttribute("Rig", "Rocon_v3")

-- 4) Juego completo con dos jugadores ------------------------------------------------------
for _, ev in ipairs(RS.Remotes:GetChildren()) do
	if ev.ClassName == "RemoteEvent" then ev.__onFireClient = function(p, ...) ev.OnClientEvent:Fire(...) end end
end
local S = {}
for _, mod in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[mod.Name] = require(mod) end
local Players = game:GetService("Players")
local function join(id, name)
	local p = MAKE_PLAYER(id, name)
	Players.__props.LocalPlayer = p
	LOCAL_PLAYER = p
	Players.PlayerAdded:Fire(p)
	RUN_DELAYS()
	return p
end
local P = join(701, "Minero")
RUN_SCRIPT(CLIENT_SCRIPT)
local RunService = game:GetService("RunService")
local function act(n, pl) local r = RS.Remotes.Action:InvokeServer(n, pl or {}); RUN_DELAYS(); return r end
local encounters = {}
RS.Remotes.Encounters.OnClientEvent:Connect(function(_, list) encounters = list end)
local function enterZone2(pl)
	pl:SetAttribute("Area", "home"); S.Capture.OnAreaChanged(pl, "home")
	pl:SetAttribute("Area", "z2"); S.Capture.OnAreaChanged(pl, "z2")
end
local realRoll = S.Capture.RollRarity
-- 4a) Salvajes de cada rareza en la zona 2 con su modelo
for _, r in ipairs(rarities) do
	S.Capture.RollRarity = function() return r end
	enterZone2(P)
	for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 30) end
	local ok, n = true, 0
	for _, w in ipairs(workspace:FindFirstChild("MisPETsSalvajes"):GetChildren()) do
		-- (los salvajes de la vuelta anterior pueden seguir en la escena: se miran los de esta rareza)
		if w:GetAttribute("Species") == "rocon" and w:GetAttribute("Rarity") == r then
			n = n + 1
			if w:GetAttribute("AssetName") ~= MODELS[r] then ok = false end
		elseif w:GetAttribute("Species") == "rocon" and w:GetAttribute("AssetName") ~= MODELS[w:GetAttribute("Rarity")] then
			ok = false
		end
	end
	check(ok and n >= 1, "zona 2, " .. r .. ": " .. n .. " Rocon salvajes con el modelo " .. MODELS[r])
end
-- 4b) Captura de varios Rocon por el servidor (un registro por captura, sin duplicar)
local profile = S.DataService.Get(P)
local function owned(pr, key) return (pr.stacks.tank[key] or 0) + (pr.stacks.storage[key] or 0) end
local realClock = os.clock
local OFFSET = 0
os.clock = function() return realClock() + OFFSET end
local function captureRocon(pl, rarity, list)
	S.Capture.RollRarity = function() return rarity end
	for _ = 1, 60 do
		local e
		for _, x in ipairs(list()) do if x.s == "rocon" and x.r == rarity then e = x break end end
		if not e then enterZone2(pl) else
			pl.Character.HumanoidRootPart.__props.CFrame = CFrame.new(e.x, 3, e.z)
			act("captureBegin", { id = e.id })
			OFFSET = OFFSET + 100
			local r = act("captureFinish", { id = e.id })
			if r.captured then return r, e end
			enterZone2(pl)
		end
	end
end
local before = { common = owned(profile, "rocon:common"), epic = owned(profile, "rocon:epic") }
local c1, e1 = captureRocon(P, "common", function() return encounters end)
check(c1 and c1.r == "common" and owned(profile, "rocon:common") == before.common + 1, "captura de un Rocon comun: llega como rocon:common")
local again = act("captureFinish", { id = e1.id })
check(not again.captured and owned(profile, "rocon:common") == before.common + 1, "repetir la captura del mismo PET no lo duplica")
local c2 = captureRocon(P, "common", function() return encounters end)
local c3 = captureRocon(P, "epic", function() return encounters end)
check(c2 and c3 and owned(profile, "rocon:common") == before.common + 2 and owned(profile, "rocon:epic") == before.epic + 1,
	"varios Rocon de distintas rarezas: 2 comunes y 1 epico, uno por captura")
check(profile.dex["rocon:common"] and profile.dex["rocon:epic"] and (profile.captured.rocon or 0) >= 3, "registro: Rocodex y contador de capturas")
S.Capture.RollRarity = realRoll
-- 4c) Inventario, equipo, cambio Lumi <-> Rocon y trabajo
act("dev", { cmd = "resources" })
act("depositAll")
act("craft", { line = "sanctuary" })
act("craft", { line = "station_stone" })
local PetStoreMod = require(RS.Shared.PetStore)
PetStoreMod.Give(profile, "lumi", "common", false)
local eq = act("equip", { ref = { key = "rocon:epic" } })
check(eq.ok and string.find(P:GetAttribute("Followers") or "", "rocon:epic", 1, true), "equipar Rocon epico")
local function unitOf(s, r, st)
	for _, u in pairs(profile.units) do if u.s == s and u.r == r and u.st == st then return u end end
end
local ue = unitOf("rocon", "epic", "equipped")
check(ue and table.find(profile.team, ue.id), "el Rocon epico esta en el equipo (estado equipped)")
for _ = 1, 10 do RunService.RenderStepped:Fire(1 / 30) end
local f
for _, c in ipairs(workspace:FindFirstChild("Compañeros"):GetChildren()) do
	if c:GetAttribute("Species") == "rocon" then f = c end
end
check(f and f:GetAttribute("AssetName") == "Rocon_epic" and math.abs(f:GetPivot().Y - f:GetAttribute("GroundOffset")) < 1e-3,
	"el compañero usa Rocon_epic y pisa el suelo")
local playing = false
for _, t in ipairs(f:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator").__tracks) do
	if t.IsPlaying then playing = true end
end
check(playing, "el compañero Rocon esta animado")
check(not act("assign", { station = "stone", ref = { unit = ue.id } }).ok, "un Rocon equipado no puede asignarse a la vez (estados excluyentes)")
check(act("unequip", { unit = ue.id }).ok and ue.st ~= "equipped" and not table.find(profile.team, ue.id), "desequipar Rocon")
local nEpic = owned(profile, "rocon:epic") + (function() local n = 0 for _, u in pairs(profile.units) do if u.s == "rocon" and u.r == "epic" then n = n + 1 end end return n end)()
check(act("equip", { ref = { key = "lumi:common" } }).ok, "cambiar a Lumi")
local ul = unitOf("lumi", "common", "equipped")
check(act("unequip", { unit = ul.id }).ok and act("equip", { ref = { key = "rocon:common" } }).ok, "y de Lumi otra vez a Rocon")
local uc = unitOf("rocon", "common", "equipped")
check(act("unequip", { unit = uc.id }).ok, "desequipar el Rocon comun")
local asg = act("assign", { station = "stone", ref = { key = "rocon:epic" } })
check(asg.ok, "asignar un Rocon epico al extractor de piedra")
local uw = unitOf("rocon", "epic", "working")
check(uw and table.find(profile.stations.stone.workers, uw.id), "el Rocon queda trabajando (estado working)")
check(not act("equip", { ref = { unit = uw.id } }).ok, "un Rocon trabajando no puede equiparse a la vez")
local nEpic2 = owned(profile, "rocon:epic") + (function() local n = 0 for _, u in pairs(profile.units) do if u.s == "rocon" and u.r == "epic" then n = n + 1 end end return n end)()
check(nEpic2 == nEpic, "cambiar de estado no duplica ni pierde Rocon epicos (" .. nEpic2 .. ")")
local plot = workspace.Plots:FindFirstChild("Plot_" .. P:GetAttribute("Plot"))
local worker
for _, d in ipairs(plot:GetDescendants()) do
	if d.ClassName == "Model" and d:GetAttribute("Species") == "rocon" then worker = d end
end
local working = false
if worker then
	for _, t in ipairs(worker:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator").__tracks) do
		if t.IsPlaying and t.Animation.AnimationId == PUBLISHED.Work then working = true end
	end
end
check(worker and worker:GetAttribute("AssetName") == "Rocon_epic" and working, "el trabajador Rocon usa Rocon_epic y reproduce Work")
local hW = worker:GetAttribute("Radius") * 2
check(near(worker:GetAttribute("GroundOffset"), hW / 2 + 0.2883 * hW, 1e-3) and math.abs(worker:GetPivot().Y - worker:GetAttribute("GroundOffset")) < 1e-3,
	"el trabajador epico se apoya con la correccion medida (pivote - GroundOffset = suelo)")
-- produccion: el Rocon produce piedra con la tasa del catalogo
local Production = S.Production
local t0 = os.time()
local Stats = require(RS.Shared.Stats)
local rate = Production.Rates(profile, "stone", Stats.Aggregate(profile, t0)).piedra or 0
local b0 = profile.stations.stone.buffer.piedra or 0
profile.stations.stone.updatedAt = t0 - 100
Production.Accrue(profile, "stone", t0)
check(rate > 0 and near((profile.stations.stone.buffer.piedra or 0) - b0, rate * 100, 1e-6),
	"el extractor produce piedra con el Rocon trabajando (" .. string.format("%.3f", rate) .. "/s)")
-- 4d) Segundo jugador: apariciones privadas y PETs independientes
-- El simulador entrega cada evento a todos los oyentes; aqui se separan las listas por jugador.
local encBy = {}
RS.Remotes.Encounters.__onFireClient = function(pl, zone, list)
	encBy[pl] = list
	if pl == P then RS.Remotes.Encounters.OnClientEvent:Fire(zone, list) end
end
enterZone2(P)
local function sig(list)
	local t = {}
	for _, e in ipairs(list or {}) do table.insert(t, e.id .. "@" .. string.format("%.2f,%.2f", e.x, e.z) .. ":" .. e.s .. ":" .. e.r) end
	table.sort(t)
	return table.concat(t, "|")
end
local profile1 = profile
local snapshot = {}
for id, u in pairs(profile1.units) do snapshot[id] = u.s .. ":" .. u.r .. ":" .. tostring(u.st) end
local stacks1 = {}
for _, where in ipairs({ "tank", "storage" }) do
	for k, v in pairs(profile1.stacks[where]) do stacks1[where .. "/" .. k] = v end
end
local sig1 = sig(encBy[P])
local P2 = join(702, "Vecina") -- desde aqui, las acciones las envia P2
local prof2 = S.DataService.Get(P2)
check(prof2 ~= profile1 and owned(prof2, "rocon:common") == 0 and owned(prof2, "rocon:epic") == 0,
	"el segundo jugador empieza sin los Rocon del primero")
local c4 = captureRocon(P2, "common", function() return encBy[P2] or {} end)
check(c4 and owned(prof2, "rocon:common") == 1, "el segundo jugador captura su propio Rocon en sus apariciones")
S.Capture.RollRarity = realRoll
S.Capture.Resend(P)
check(encBy[P] ~= nil and sig(encBy[P]) == sig1, "las apariciones privadas del primer jugador no cambian")
local same = true
for id, st in pairs(snapshot) do
	local u = profile1.units[id]
	if not u or (u.s .. ":" .. u.r .. ":" .. tostring(u.st)) ~= st then same = false end
end
for k, v in pairs(stacks1) do
	local where, key = k:match("^(%w+)/(.+)$")
	if profile1.stacks[where][key] ~= v then same = false end
end
check(same, "las capturas del segundo jugador no tocan los PETs del primero")
-- 4e) Persistencia: salir y volver
local keysBefore = {}
for _, where in ipairs({ "tank", "storage" }) do
	for k, v in pairs(profile1.stacks[where]) do if k:find("^rocon:") or k:find("^lumi:") then keysBefore[where .. "/" .. k] = v end end
end
S.DataService.SaveNow(P)
Players.PlayerRemoving:Fire(P)
RUN_DELAYS()
check(DATABASE["u_701"] and DATABASE["u_701"].data and DATABASE["u_701"].lock == nil, "perfil guardado y bloqueo liberado al salir")
local P3 = join(701, "Minero")
local p3 = S.DataService.Get(P3)
local kept = true
for k, v in pairs(keysBefore) do
	local where, key = k:match("^(%w+)/(.+)$")
	if p3.stacks[where][key] ~= v then kept = false end
end
for id, s in pairs(snapshot) do
	local u = p3.units[id]
	if not u or (u.s .. ":" .. u.r .. ":" .. tostring(u.st)) ~= s then kept = false end
end
check(kept, "al volver: mismos Rocon y Lumi (especie, rareza, estado e identificador)")
check(table.find(p3.stations.stone.workers, uw.id) ~= nil, "al volver, el Rocon sigue trabajando en el extractor")
local Schema = require(RS.Shared.ProfileSchema)
check(p3.version == Schema.Default().version, "sin cambios de esquema ni de version del perfil")

local unexpected = {}
for _, w in ipairs(warnings) do
	-- esperados: el aviso del rig incompatible (provocado en 3b) y el de Lumi_rare, que en esta
	-- prueba no se crea (en el repositorio existe assets/pets/Lumi_rare.rbxm)
	if not (w:find("Rig=Otro", 1, true) or w:find("la plantilla Lumi_rare", 1, true)) then table.insert(unexpected, w) end
end
check(#unexpected == 0, "sin avisos inesperados (" .. #unexpected .. ")")
print("ALL ROCON TESTS PASSED")
