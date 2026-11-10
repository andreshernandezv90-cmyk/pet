-- Pruebas de la integracion de Talpa (Comun, Raro, Epico y Legendario; sin mitico).
-- Ejecutar: lua5.4 tools/sim/talpa.lua
-- Las plantillas son SIMULADAS con la estructura de los .rbxm de assets/pets (MeshPart con los
-- 25 huesos del rig Talpa_v1, SurfaceAppearance, AnimationController, Rig = "Talpa_v1";
-- tamaños de la malla en reposo leidos de assets/pets). Los mapas de color son marcadores.
-- Los 7 ids de animacion son los publicados (PetAssets.AnimationSets.Talpa_v1).
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
local MODELS = { common = "Talpa", rare = "Talpa_rare", epic = "Talpa_epic", legendary = "Talpa_legendary" }
local BODIES = { common = "Talpa_Comun_Mesh", rare = "Talpa_Raro_Mesh", epic = "Talpa_Epico_Mesh", legendary = "Talpa_Legendario_Mesh" }
-- Malla en reposo (X ancho, Y alto, Z fondo) de los .rbxm de assets/pets
local REST = Vector3.new(1.5615, 1.7036, 2.0) -- igual en las 4 rarezas (validador)
local SIZES = { common = REST, rare = REST, epic = REST, legendary = REST }
local HIER = { { "Root", nil }, { "Hips", "Root" }, { "Spine", "Hips" }, { "Chest", "Spine" }, { "Neck", "Chest" },
	{ "Head", "Neck" }, { "Snout", "Head" }, { "Tail1", "Hips" }, { "Tail2", "Tail1" }, { "Tail3", "Tail2" }, { "Tail4", "Tail3" } }
for _, s in ipairs({ "Left", "Right" }) do
	for _, h in ipairs({ { "UpperArm", "Chest" }, { "LowerArm", s .. "UpperArm" }, { "Hand", s .. "LowerArm" }, { "Claws", s .. "Hand" },
		{ "UpperLeg", "Hips" }, { "LowerLeg", s .. "UpperLeg" }, { "Foot", s .. "LowerLeg" } }) do
		table.insert(HIER, { s .. h[1], h[2] })
	end
end
check(#HIER == 25, "rig Talpa_v1 simulado con 25 huesos")

-- 0) Reglas de especie: sin mitico, zona 3, extractor de hierro (sin cambios) --------------
local rarities = {}
for _, r in ipairs(PetCatalog.RaritiesFor("talpa")) do table.insert(rarities, r.id) end
check(table.concat(rarities, ",") == "common,rare,epic,legendary", "Talpa tiene exactamente Comun, Raro, Epico y Legendario")
check(PetCatalog.ParseKey("talpa:mythic") == nil and PetCatalog.ParseKey("talpa:mythic:shiny") == nil, "talpa:mythic no es una clave valida")
local sp = PetCatalog.Get("talpa")
check(sp.zone == 3 and sp.mythic == false and sp.jobs.iron == 0.12 and sp.jobs.stone == nil and sp.jobs.copper == nil
	and sp.bonus.oreYield == 0.08, "zona 3, sin mitico, extractor de hierro y bonus al minar (valores del catalogo)")

-- 1) Sin plantillas de Talpa: procedural de siempre, sin avisos ----------------------------
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
	for _, h in ipairs(rig == "Talpa_v1" and HIER or { { "Root", nil } }) do
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
-- Lumi, Rocon y Chispa presentes (para comprobar que conviven sin cambios)
makeTemplate("Lumi", "Lumi_Comun_Body", Vector3.new(1.1831539, 1.6666665, 1.5838034), "SIM_textura_lumi", "Lumi_v7")
makeTemplate("Rocon", "Rocon_Comun_Body", Vector3.new(1.8982, 1.6966, 1.0762), "SIM_textura_rocon", "Rocon_v3")
makeTemplate("Chispa", "Chispa_Comun_Mesh", Vector3.new(1.2843, 2.0, 1.0261), "SIM_textura_chispa", "Chispa_v1")
for _, r in ipairs(rarities) do
	local m = PetModels.Build("talpa", r)
	check(m:GetAttribute("Source") ~= "asset" and m:GetAttribute("Species") == "talpa" and m:GetAttribute("Rarity") == r,
		r .. ": sin plantillas, Talpa sigue siendo procedural")
end
check(not warned("Talpa"), "sin plantillas de Talpa no hay avisos en Output")

-- 2) Con las 4 plantillas: cada rareza usa su modelo, textura, alto y apoyo ----------------
for _, r in ipairs(rarities) do
	makeTemplate(MODELS[r], BODIES[r], SIZES[r], "SIM_textura_talpa_" .. r, "Talpa_v1")
end
local function colorMapOf(m)
	local sa = m.PrimaryPart and m.PrimaryPart:FindFirstChildOfClass("SurfaceAppearance")
	return sa and sa.ColorMap
end
-- Exportado (Blender, 2026-11-09) con la malla apoyada en Y = 0 en cada fotograma de las 7
-- animaciones y Root fijo en la base de reposo. PENDIENTE de medir en Studio dentro del juego.
for _, r in ipairs(rarities) do
	local rar = PetCatalog.Rarity(r)
	local m = PetModels.Build("talpa", r, { label = "Talpa" })
	check(m:GetAttribute("AssetName") == MODELS[r] and m:GetAttribute("Rig") == "Talpa_v1" and colorMapOf(m) == "SIM_textura_talpa_" .. r
		and m.PrimaryPart.Name == BODIES[r], r .. ": modelo " .. MODELS[r] .. " con su textura y su MeshPart")
	local nb = 0
	for _, d in ipairs(m:GetDescendants()) do if d.ClassName == "Bone" then nb = nb + 1 end end
	check(nb == 25, r .. ": el clon conserva los 25 huesos")
	local _, size = m:GetBoundingBox()
	local h = 2 * rar.size
	check(near(size.Y, h, 1e-3), r .. ": alto " .. string.format("%.2f", size.Y) .. " studs (igual que el procedural)")
	check(near(m:GetAttribute("GroundOffset"), h / 2, 1e-3), r .. ": GroundOffset = alto/2 (footInset 0, sin correccion)")
	m:PivotTo(PetGrounding.PivotCFrame(Vector3.new(0, 5, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, -1), m:GetAttribute("GroundOffset")))
	local bb, s2 = m:GetBoundingBox()
	local restBase = bb.Position.Y - s2.Y / 2
	check(near(restBase, 5, 1e-3), r .. ": la base de reposo (Root) queda exactamente en el suelo")
	check(m:GetAttribute("Yaw") == nil or m:GetAttribute("Yaw") == 0, r .. ": sin giro de orientacion (frente -Z)")
end
check(not warned("Talpa"), "con las 4 plantillas no hay avisos de Talpa")
local ml = PetModels.Build("lumi", "common")
check(ml:GetAttribute("AssetName") == "Lumi" and near(ml:GetAttribute("GroundOffset"), 1.0, 1e-3), "Lumi conserva su plantilla y su apoyo")
local mr = PetModels.Build("rocon", "common")
local hr = mr:GetAttribute("Radius") * 2
check(mr:GetAttribute("AssetName") == "Rocon" and near(mr:GetAttribute("GroundOffset"), hr / 2 + 0.288 * hr, 1e-3),
	"Rocon conserva su plantilla y su correccion de apoyo medida")
local mc = PetModels.Build("chispa", "common")
check(mc:GetAttribute("AssetName") == "Chispa" and near(mc:GetAttribute("GroundOffset"), mc:GetAttribute("Radius"), 1e-3),
	"Chispa conserva su plantilla y su apoyo")
-- Shiny: misma plantilla de su rareza + particulas; Shiny no es una rareza ni cambia el modelo
for _, r in ipairs(rarities) do
	local ms = PetModels.Build("talpa", r, { shiny = true })
	check(ms:GetAttribute("AssetName") == MODELS[r] and ms:GetAttribute("Rarity") == r and ms:GetAttribute("Shiny") == true
		and ms.PrimaryPart:FindFirstChild("ShinySparkles") ~= nil and near(ms:GetAttribute("GroundOffset"), ms:GetAttribute("Radius"), 1e-3),
		r .. " Shiny: usa " .. MODELS[r] .. " con particulas Shiny y el mismo apoyo")
end
check(PetCatalog.ParseKey("talpa:legendary:shiny") == "talpa", "talpa:legendary:shiny es una clave valida")

-- 3) Animaciones -------------------------------------------------------------------------
-- Ids publicados por el dueño del proyecto (docs/ART_PIPELINE.md, seccion 17)
local PUBLISHED = {
	Idle = "rbxassetid://136548107891720", Walk = "rbxassetid://81290030630381", Run = "rbxassetid://102908093464049",
	Happy = "rbxassetid://140408446222794", Sleep_Enter = "rbxassetid://81127893070487",
	Sleep_Loop = "rbxassetid://101325040811253", Work = "rbxassetid://79325542756265",
}
local set = PetAssets.AnimationSets.Talpa_v1
local exact = set ~= nil and set.rig == "Talpa_v1"
local nIds = 0
if set then
	for _, s in ipairs(STATES) do if set.ids[s] ~= PUBLISHED[s] then exact = false end end
	for _ in pairs(set.ids) do nIds = nIds + 1 end
end
check(exact and nIds == 7, "Talpa_v1 tiene exactamente los 7 ids publicados")
check(PetAssets.Species.talpa.animationSet == "Talpa_v1" and next(PetAssets.Species.talpa.variants) == nil
	and next(PetAssets.Species.talpa.animations) == nil, "las 4 rarezas usan el conjunto compartido, sin ids propios")
check(PetAssets.Species.talpa.locomotion == nil, "Talpa usa las referencias globales de velocidad (sin locomotion propia)")
local lumiIds, roconIds, chispaIds = PetAssets.AnimationSets.Lumi_v7.ids, PetAssets.AnimationSets.Rocon_v3.ids, PetAssets.AnimationSets.Chispa_v1.ids
check(lumiIds.Idle == "rbxassetid://123787685829164" and lumiIds.Work == "rbxassetid://138174795961249"
	and roconIds.Idle == "rbxassetid://99191665025042" and roconIds.Work == "rbxassetid://100611091362223"
	and chispaIds.Idle == "rbxassetid://122236338807516" and chispaIds.Work == "rbxassetid://139469079471002",
	"los ids de Lumi, Rocon y Chispa no cambian")
local seen = {}
for _, r in ipairs(rarities) do
	local m = PetModels.Build("talpa", r)
	local a = PetAnimator.Attach(m)
	check(a ~= nil and a.tracks.Idle and #m:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator").__tracks == 7,
		r .. ": 7 pistas cargadas una sola vez")
	for _, s in ipairs(STATES) do
		check(a.tracks[s].Animation.AnimationId == PUBLISHED[s], r .. ": " .. s .. " usa el id del conjunto compartido")
		seen[a.tracks[s].Animation] = true
	end
	check(a.tracks.Idle.Looped and a.tracks.Walk.Looped and a.tracks.Run.Looped and a.tracks.Work.Looped and a.tracks.Sleep_Loop.Looped
		and not a.tracks.Happy.Looped and not a.tracks.Sleep_Enter.Looped, r .. ": bucles correctos (Happy y Sleep_Enter sin bucle)")
	check(a.walkRef == PetAssets.Locomotion.referenceWalkSpeed and a.runRef == PetAssets.Locomotion.referenceRunSpeed,
		r .. ": referencias globales de Walk/Run")
	check(a:SetMoveSpeed(0) == "Idle", r .. ": quieto -> Idle")
	check(a:SetMoveSpeed(2) == "Walk" and near(a.speed, 2 / a.walkRef, 1e-9), r .. ": Walk a 2 studs/s (velocidad 0,5)")
	local tr = a.tracks.Walk
	local plays = tr.__plays or 0
	a:SetMoveSpeed(2)
	check(a:GetState() == "Walk" and (tr.__plays or 0) == plays, r .. ": pedir el mismo estado no reinicia la pista")
	check(a:SetMoveSpeed(9) == "Run" and near(a.speed, 9 / a.runRef, 1e-9) and a:SetMoveSpeed(30) == "Run" and near(a.speed, 1.8, 1e-9), r .. ": Run al correr (9 studs/s -> 0,75; limite de 1,8)")
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
-- Rig incompatible: no se anima con Talpa_v1
folder:FindFirstChild("Talpa_rare"):SetAttribute("Rig", "talpa_v1")
check(PetAnimator.Attach(PetModels.Build("talpa", "rare")) == nil and warned("Rig=talpa_v1"),
	"una plantilla con otro rig (p. ej. 'talpa_v1' en minuscula) no se anima (aviso)")
folder:FindFirstChild("Talpa_rare"):SetAttribute("Rig", "Talpa_v1")

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
local P = join(801, "Excavadora")
RUN_SCRIPT(CLIENT_SCRIPT)
local RunService = game:GetService("RunService")
local function act(n, pl) local r = RS.Remotes.Action:InvokeServer(n, pl or {}); RUN_DELAYS(); return r end
local encounters = {}
RS.Remotes.Encounters.OnClientEvent:Connect(function(_, list) encounters = list end)
local function enterZone3(pl)
	pl:SetAttribute("Area", "home"); S.Capture.OnAreaChanged(pl, "home")
	pl:SetAttribute("Area", "z3"); S.Capture.OnAreaChanged(pl, "z3")
end
local realRoll = S.Capture.RollRarity
-- 4a) Salvajes de cada rareza en la zona 3 con su modelo, apoyados en el suelo
for _, r in ipairs(rarities) do
	S.Capture.RollRarity = function() return r end
	enterZone3(P)
	for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 30) end
	local ok, n = true, 0
	for _, w in ipairs(workspace:FindFirstChild("MisPETsSalvajes"):GetChildren()) do
		if w:GetAttribute("Species") == "talpa" then
			if w:GetAttribute("AssetName") ~= MODELS[w:GetAttribute("Rarity")] or not near(w:GetAttribute("GroundOffset"), w:GetAttribute("Radius"), 1e-3) then
				ok = false
			end
			if w:GetAttribute("Rarity") == r then n = n + 1 end
		end
	end
	check(ok and n >= 1, "zona 3, " .. r .. ": " .. n .. " Talpa salvajes con el modelo " .. MODELS[r] .. " y apoyo sin correccion")
end
-- 4b) Captura de varias Talpa por el servidor (un registro por captura, sin duplicar)
local profile = S.DataService.Get(P)
local function owned(pr, key) return (pr.stacks.tank[key] or 0) + (pr.stacks.storage[key] or 0) end
local realClock = os.clock
local OFFSET = 0
os.clock = function() return realClock() + OFFSET end
local function captureTalpa(pl, rarity, list)
	S.Capture.RollRarity = function() return rarity end
	for _ = 1, 60 do
		local e
		for _, x in ipairs(list()) do if x.s == "talpa" and x.r == rarity then e = x break end end
		if not e then enterZone3(pl) else
			pl.Character.HumanoidRootPart.__props.CFrame = CFrame.new(e.x, 3, e.z)
			act("captureBegin", { id = e.id })
			OFFSET = OFFSET + 100
			local r = act("captureFinish", { id = e.id })
			if r.captured then return r, e end
			enterZone3(pl)
		end
	end
end
local before = { common = owned(profile, "talpa:common"), legendary = owned(profile, "talpa:legendary") }
local c1, e1 = captureTalpa(P, "common", function() return encounters end)
check(c1 and c1.r == "common" and owned(profile, "talpa:common") == before.common + 1, "captura de una Talpa comun: llega como talpa:common")
local again = act("captureFinish", { id = e1.id })
check(not again.captured and owned(profile, "talpa:common") == before.common + 1, "repetir la captura del mismo PET no lo duplica")
local c2 = captureTalpa(P, "common", function() return encounters end)
local c3 = captureTalpa(P, "legendary", function() return encounters end)
check(c2 and c3 and owned(profile, "talpa:common") == before.common + 2 and owned(profile, "talpa:legendary") == before.legendary + 1,
	"varias Talpa de distintas rarezas: 2 comunes y 1 legendaria, una por captura")
check(profile.dex["talpa:common"] and profile.dex["talpa:legendary"] and (profile.captured.talpa or 0) >= 3, "registro: dex y contador de capturas")
S.Capture.RollRarity = realRoll
-- 4c) Inventario, equipo, cambio Lumi <-> Talpa y trabajo en el extractor de hierro
act("dev", { cmd = "resources" })
act("depositAll")
act("craft", { line = "sanctuary" })
profile.zones.unlocked = math.max(profile.zones.unlocked or 1, 3) -- el extractor de hierro es de la zona 3
for _ = 1, 4 do -- pico mejorado por el camino normal (el extractor de hierro pide el pico de cobre)
	if profile.tools.pick < 3 then act("craft", { line = "pick" }) end
end
local crafted = act("craft", { line = "station_iron" })
check(crafted.ok and profile.stations.iron.level >= 1, "extractor de hierro construido (" .. tostring(crafted.msg) .. ")")
local PetStoreMod = require(RS.Shared.PetStore)
PetStoreMod.Give(profile, "lumi", "common", false)
local eq = act("equip", { ref = { key = "talpa:legendary" } })
check(eq.ok and string.find(P:GetAttribute("Followers") or "", "talpa:legendary", 1, true), "equipar Talpa legendaria")
local function unitOf(s, r, st)
	for _, u in pairs(profile.units) do if u.s == s and u.r == r and u.st == st then return u end end
end
local ue = unitOf("talpa", "legendary", "equipped")
check(ue and table.find(profile.team, ue.id), "la Talpa legendaria esta en el equipo (estado equipped)")
for _ = 1, 10 do RunService.RenderStepped:Fire(1 / 30) end
local f
for _, c in ipairs(workspace:FindFirstChild("Compañeros"):GetChildren()) do
	if c:GetAttribute("Species") == "talpa" then f = c end
end
check(f and f:GetAttribute("AssetName") == "Talpa_legendary" and math.abs(f:GetPivot().Y - f:GetAttribute("GroundOffset")) < 1e-3,
	"la compañera usa Talpa_legendary y pisa el suelo")
local playing = false
for _, t in ipairs(f:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator").__tracks) do
	if t.IsPlaying then playing = true end
end
check(playing, "la compañera Talpa esta animada")
check(not act("assign", { station = "iron", ref = { unit = ue.id } }).ok, "una Talpa equipada no puede asignarse a la vez (estados excluyentes)")
check(act("unequip", { unit = ue.id }).ok and ue.st ~= "equipped" and not table.find(profile.team, ue.id), "desequipar Talpa")
local function count(s, r)
	local n = owned(profile, s .. ":" .. r)
	for _, u in pairs(profile.units) do if u.s == s and u.r == r then n = n + 1 end end
	return n
end
local nLeg = count("talpa", "legendary")
check(act("equip", { ref = { key = "lumi:common" } }).ok, "cambiar a Lumi")
local ul = unitOf("lumi", "common", "equipped")
check(act("unequip", { unit = ul.id }).ok and act("equip", { ref = { key = "talpa:common" } }).ok, "y de Lumi otra vez a Talpa")
local uc = unitOf("talpa", "common", "equipped")
check(act("unequip", { unit = uc.id }).ok, "desequipar la Talpa comun")
check(not act("assign", { station = "stone", ref = { key = "talpa:common" } }).ok, "Talpa no trabaja en el extractor de piedra (catalogo)")
local asg = act("assign", { station = "iron", ref = { key = "talpa:legendary" } })
check(asg.ok, "asignar una Talpa legendaria al extractor de hierro")
local uw = unitOf("talpa", "legendary", "working")
check(uw and table.find(profile.stations.iron.workers, uw.id), "la Talpa queda trabajando (estado working)")
check(not act("equip", { ref = { unit = uw.id } }).ok, "una Talpa trabajando no puede equiparse a la vez")
check(count("talpa", "legendary") == nLeg, "cambiar de estado no duplica ni pierde Talpa legendarias (" .. nLeg .. ")")
local plot = workspace.Plots:FindFirstChild("Plot_" .. P:GetAttribute("Plot"))
local worker
for _, d in ipairs(plot:GetDescendants()) do
	if d.ClassName == "Model" and d:GetAttribute("Species") == "talpa" then worker = d end
end
local working = false
if worker then
	for _, t in ipairs(worker:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator").__tracks) do
		if t.IsPlaying and t.Animation.AnimationId == PUBLISHED.Work then working = true end
	end
end
check(worker and worker:GetAttribute("AssetName") == "Talpa_legendary" and working, "la trabajadora usa Talpa_legendary y reproduce Work")
check(near(worker:GetAttribute("GroundOffset"), worker:GetAttribute("Radius"), 1e-3) and math.abs(worker:GetPivot().Y - worker:GetAttribute("GroundOffset")) < 1e-3,
	"la trabajadora se apoya en el suelo (pivote - GroundOffset = suelo)")
-- produccion: la Talpa produce hierro con la tasa del catalogo
local Production = S.Production
local t0 = os.time()
local Stats = require(RS.Shared.Stats)
local rate = Production.Rates(profile, "iron", Stats.Aggregate(profile, t0)).hierro or 0
local b0 = profile.stations.iron.buffer.hierro or 0
profile.stations.iron.updatedAt = t0 - 100
Production.Accrue(profile, "iron", t0)
check(rate > 0 and near((profile.stations.iron.buffer.hierro or 0) - b0, rate * 100, 1e-6),
	"el extractor produce hierro con la Talpa trabajando (" .. string.format("%.3f", rate) .. "/s)")
-- 4d) Segundo jugador: apariciones privadas y PETs independientes
local encBy = {}
RS.Remotes.Encounters.__onFireClient = function(pl, zone, list)
	encBy[pl] = list
	if pl == P then RS.Remotes.Encounters.OnClientEvent:Fire(zone, list) end
end
enterZone3(P)
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
local P2 = join(802, "Vecino")
local prof2 = S.DataService.Get(P2)
check(prof2 ~= profile1 and owned(prof2, "talpa:common") == 0 and owned(prof2, "talpa:legendary") == 0,
	"el segundo jugador empieza sin las Talpa del primero")
local c4 = captureTalpa(P2, "common", function() return encBy[P2] or {} end)
check(c4 and owned(prof2, "talpa:common") == 1, "el segundo jugador captura su propia Talpa en sus apariciones")
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
-- 4e) Persistencia: salir y volver (con una Talpa Shiny en el inventario)
PetStoreMod.Give(profile1, "talpa", "epic", true, true)
local keysBefore = {}
for _, where in ipairs({ "tank", "storage" }) do
	for k, v in pairs(profile1.stacks[where]) do if k:find("^talpa:") or k:find("^lumi:") then keysBefore[where .. "/" .. k] = v end end
end
local hasShiny = false
for k in pairs(keysBefore) do if k:find("talpa:epic:shiny", 1, true) then hasShiny = true end end
check(hasShiny, "una Talpa epica Shiny entra en el inventario como talpa:epic:shiny")
S.DataService.SaveNow(P)
Players.PlayerRemoving:Fire(P)
RUN_DELAYS()
check(DATABASE["u_801"] and DATABASE["u_801"].data and DATABASE["u_801"].lock == nil, "perfil guardado y bloqueo liberado al salir")
local P3 = join(801, "Excavadora")
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
check(kept, "al volver: mismas Talpa (incluida la Shiny) y Lumi (especie, rareza, estado e identificador)")
check(table.find(p3.stations.iron.workers, uw.id) ~= nil, "al volver, la Talpa sigue trabajando en el extractor de hierro")
local Schema = require(RS.Shared.ProfileSchema)
check(p3.version == Schema.Default().version, "sin cambios de esquema ni de version del perfil")

local unexpected = {}
for _, w in ipairs(warnings) do
	-- esperados: el aviso del rig incompatible (provocado en 3) y los de plantillas de Lumi/Rocon/Chispa
	-- por rareza que esta prueba no crea (en el repositorio existen)
	if not (w:find("Rig=talpa_v1", 1, true) or w:find("la plantilla Lumi_", 1, true) or w:find("la plantilla Rocon_", 1, true)
		or w:find("la plantilla Chispa_", 1, true)) then
		table.insert(unexpected, w)
	end
end
check(#unexpected == 0, "sin avisos inesperados (" .. #unexpected .. ")")
print("ALL TALPA TESTS PASSED")
