-- Pruebas de la integracion de Nox (Comun, Raro, Epico y Legendario; Mitico provisional).
-- Ejecutar: lua5.4 tools/sim/nox.lua
-- Las plantillas son SIMULADAS con la estructura de los .rbxm de assets/pets (MeshPart con los
-- 20 huesos del rig Nox_v1, SurfaceAppearance, AnimationController, Rig = "Nox_v1"; tamaños de la
-- malla en reposo leidos de assets/pets). Los mapas de color son marcadores.
-- Animaciones: los 7 ids publicados y comprobados en un Animator (PetAssets.AnimationSets.Nox_v1).
-- Mitico: Nox lo tiene en el catalogo, pero aun no tiene modelo propio. Usa la plantilla "Nox"
-- (provisional, sin aviso) para que los datos nox:mythic sigan funcionando.
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
-- Ids publicados por el dueño del proyecto (docs/ART_PIPELINE.md, seccion 18)
local PUBLISHED = {
	Idle = "rbxassetid://112605561747950", Walk = "rbxassetid://70485972409894", Run = "rbxassetid://129884516413247",
	Happy = "rbxassetid://130648680492072", Sleep_Enter = "rbxassetid://115262768771029",
	Sleep_Loop = "rbxassetid://83704950434754", Work = "rbxassetid://129838855420494",
}
local MODELS = { common = "Nox", rare = "Nox_rare", epic = "Nox_epic", legendary = "Nox_legendary", mythic = "Nox" }
local BODIES = { common = "Nox_Comun_Mesh", rare = "Nox_Raro_Mesh", epic = "Nox_Epico_Mesh", legendary = "Nox_Legendario_Mesh" }
BODIES.mythic = BODIES.common
-- Malla en reposo (X ancho, Y alto, Z fondo) de los .rbxm de assets/pets
local SIZES = {
	common = Vector3.new(1.5263, 2.0, 1.4950), rare = Vector3.new(1.5252, 2.0, 1.4922),
	epic = Vector3.new(1.5263, 2.0, 1.4950), legendary = Vector3.new(1.5263, 2.0, 1.4950),
}
local HIER = { { "Root", nil }, { "Hips", "Root" }, { "Spine", "Hips" }, { "Head", "Spine" }, { "Crown", "Head" },
	{ "Flame_Back", "Crown" }, { "Wisp", "Hips" }, { "Tail_1", "Hips" }, { "Tail_2", "Tail_1" }, { "Tail_3", "Tail_2" } }
for _, s in ipairs({ "L", "R" }) do
	for _, h in ipairs({ { "Tuft_" .. s, "Crown" }, { "Horn_" .. s .. "1", "Crown" }, { "Horn_" .. s .. "2", "Horn_" .. s .. "1" },
		{ "Arm_" .. s, "Spine" }, { "Hand_" .. s, "Arm_" .. s } }) do
		table.insert(HIER, h)
	end
end
check(#HIER == 20, "rig Nox_v1 simulado con 20 huesos")

-- 0) Reglas de especie: con mitico, zona 3, extractor lunar (sin cambios) ------------------
local rarities = {}
for _, r in ipairs(PetCatalog.RaritiesFor("nox")) do table.insert(rarities, r.id) end
check(table.concat(rarities, ",") == "common,rare,epic,legendary,mythic", "Nox tiene Comun, Raro, Epico, Legendario y Mitico (GDD)")
local FOUR = { "common", "rare", "epic", "legendary" }
check(PetCatalog.ParseKey("nox:mythic") == "nox" and PetCatalog.ParseKey("nox:mythic:shiny") == "nox", "nox:mythic sigue siendo una clave valida")
local sp = PetCatalog.Get("nox")
check(sp.zone == 3 and sp.mythic == true and sp.jobs.moon == 0.06 and sp.jobs.iron == nil and sp.bonus.captureEase == 0.03
	and sp.flags.nightVision == true, "zona 3, con mitico, extractor lunar, captureEase y vision nocturna (valores del catalogo)")

-- 1) Sin plantillas de Nox: procedural de siempre, sin avisos -------------------------------
local folder = Instance.new("Folder")
folder.Name = "PetAssets"
folder.Parent = RS
local function makeTemplate(name, bodyName, size, colorMap, rig, hier)
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
	for _, h in ipairs(hier or { { "Root", nil } }) do
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
-- Lumi, Rocon, Chispa y Talpa presentes (para comprobar que conviven sin cambios)
makeTemplate("Lumi", "Lumi_Comun_Body", Vector3.new(1.1831539, 1.6666665, 1.5838034), "SIM_textura_lumi", "Lumi_v7")
makeTemplate("Rocon", "Rocon_Comun_Body", Vector3.new(1.8982, 1.6966, 1.0762), "SIM_textura_rocon", "Rocon_v3")
makeTemplate("Chispa", "Chispa_Comun_Mesh", Vector3.new(1.2843, 2.0, 1.0261), "SIM_textura_chispa", "Chispa_v1")
makeTemplate("Talpa", "Talpa_Comun_Mesh", Vector3.new(1.5615, 1.7036, 2.0), "SIM_textura_talpa", "Talpa_v1")
for _, r in ipairs(rarities) do
	local m = PetModels.Build("nox", r)
	check(m:GetAttribute("Source") ~= "asset" and m:GetAttribute("Species") == "nox" and m:GetAttribute("Rarity") == r,
		r .. ": sin plantillas, Nox sigue siendo procedural")
end
check(not warned("Nox"), "sin plantillas de Nox no hay avisos en Output")

-- 2) Con las 4 plantillas: cada rareza usa su modelo, textura, alto y apoyo -----------------
for _, r in ipairs(FOUR) do
	makeTemplate(MODELS[r], BODIES[r], SIZES[r], "SIM_textura_nox_" .. r, "Nox_v1", HIER)
end
local function colorMapOf(m)
	local sa = m.PrimaryPart and m.PrimaryPart:FindFirstChildOfClass("SurfaceAppearance")
	return sa and sa.ColorMap
end
-- Root en la base de la malla en reposo (punta inferior) y fijo; la flotacion (Hips +0,08 a +0,16
-- studs) la pone la animacion. PENDIENTE de medir en Studio dentro del juego.
for _, r in ipairs(rarities) do
	local rar = PetCatalog.Rarity(r)
	local m = PetModels.Build("nox", r, { label = "Nox" })
	check(m:GetAttribute("AssetName") == MODELS[r] and m:GetAttribute("Rig") == "Nox_v1" and colorMapOf(m) == "SIM_textura_nox_" .. (r == "mythic" and "common" or r)
		and m.PrimaryPart.Name == BODIES[r], r .. ": modelo " .. MODELS[r] .. " con su textura y su MeshPart")
	local nb = 0
	for _, d in ipairs(m:GetDescendants()) do if d.ClassName == "Bone" then nb = nb + 1 end end
	check(nb == 20, r .. ": el clon conserva los 20 huesos")
	local _, size = m:GetBoundingBox()
	local h = 2 * rar.size
	check(near(size.Y, h, 1e-3), r .. ": alto " .. string.format("%.2f", size.Y) .. " studs (igual que el procedural)")
	check(near(m:GetAttribute("GroundOffset"), h / 2, 1e-3), r .. ": GroundOffset = alto/2 (footInset 0, sin correccion)")
	m:PivotTo(PetGrounding.PivotCFrame(Vector3.new(0, 5, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, -1), m:GetAttribute("GroundOffset")))
	local bb, s2 = m:GetBoundingBox()
	check(near(bb.Position.Y - s2.Y / 2, 5, 1e-3), r .. ": la base de reposo (Root) queda exactamente en el suelo")
	check(m:GetAttribute("Yaw") == nil or m:GetAttribute("Yaw") == 0, r .. ": sin giro de orientacion (frente -Z)")
end
check(not warned("Nox"), "con las 4 plantillas no hay avisos de Nox (Mitico usa Nox sin aviso)")
check(PetAssets.Species.nox.rarityModels.mythic == nil and folder:FindFirstChild("Nox_mythic") == nil,
	"Mitico no tiene modelo propio: es provisional (plantilla Nox), no un modelo mitico definitivo")
local mm, mc = PetModels.Build("nox", "mythic"), PetModels.Build("nox", "common")
check(mm:GetAttribute("Rarity") == "mythic" and mm:GetAttribute("Radius") > mc:GetAttribute("Radius"),
	"Nox Mitico conserva su rareza y su tamaño de rareza (mas grande que Comun)")
local ml = PetModels.Build("lumi", "common")
check(ml:GetAttribute("AssetName") == "Lumi" and near(ml:GetAttribute("GroundOffset"), 1.0, 1e-3), "Lumi conserva su plantilla y su apoyo")
local mr = PetModels.Build("rocon", "common")
local hr = mr:GetAttribute("Radius") * 2
check(mr:GetAttribute("AssetName") == "Rocon" and near(mr:GetAttribute("GroundOffset"), hr / 2 + 0.288 * hr, 1e-3),
	"Rocon conserva su plantilla y su correccion de apoyo medida")
local mch = PetModels.Build("chispa", "common")
check(mch:GetAttribute("AssetName") == "Chispa" and near(mch:GetAttribute("GroundOffset"), mch:GetAttribute("Radius"), 1e-3),
	"Chispa conserva su plantilla y su apoyo")
local mt = PetModels.Build("talpa", "common")
check(mt:GetAttribute("AssetName") == "Talpa" and near(mt:GetAttribute("GroundOffset"), mt:GetAttribute("Radius"), 1e-3),
	"Talpa conserva su plantilla y su apoyo")
-- Shiny: misma plantilla de su rareza + particulas; Shiny no es una rareza ni cambia el modelo
for _, r in ipairs(rarities) do
	local ms = PetModels.Build("nox", r, { shiny = true })
	check(ms:GetAttribute("AssetName") == MODELS[r] and ms:GetAttribute("Rarity") == r and ms:GetAttribute("Shiny") == true
		and ms.PrimaryPart:FindFirstChild("ShinySparkles") ~= nil and near(ms:GetAttribute("GroundOffset"), ms:GetAttribute("Radius"), 1e-3),
		r .. " Shiny: usa " .. MODELS[r] .. " con particulas Shiny y el mismo apoyo")
end
check(PetCatalog.ParseKey("nox:legendary:shiny") == "nox", "nox:legendary:shiny es una clave valida")

-- 3) Animaciones: los 7 ids publicados y comprobados en un Animator ------------------------
local set = PetAssets.AnimationSets.Nox_v1
local exact = set ~= nil and set.rig == "Nox_v1"
local nIds = 0
if set then
	for _, s in ipairs(STATES) do if set.ids[s] ~= PUBLISHED[s] then exact = false end end
	for _ in pairs(set.ids) do nIds = nIds + 1 end
end
check(exact and nIds == 7, "Nox_v1 tiene exactamente los 7 ids publicados (Idle 112605561747950 conservado)")
local OLD = { "rbxassetid://102879104312994", "rbxassetid://104458487195839", "rbxassetid://88530856883740",
	"rbxassetid://94564745666171", "rbxassetid://138793674065150", "rbxassetid://85715077517869" }
local noOld = true
for _, id in ipairs(OLD) do for _, v in pairs(set.ids) do if v == id then noOld = false end end end
check(noOld, "ninguno de los 6 ids anteriores que no cargan en Roblox esta en el conjunto")
check(PetAssets.Species.nox.animationSet == "Nox_v1" and next(PetAssets.Species.nox.variants) == nil
	and next(PetAssets.Species.nox.animations) == nil, "las rarezas usan el conjunto compartido, sin ids propios")
check(PetAssets.Species.nox.locomotion == nil, "Nox usa las referencias globales de velocidad (sin locomotion propia)")
local L, R, C, T = PetAssets.AnimationSets.Lumi_v7.ids, PetAssets.AnimationSets.Rocon_v3.ids, PetAssets.AnimationSets.Chispa_v1.ids, PetAssets.AnimationSets.Talpa_v1.ids
check(L.Idle == "rbxassetid://123787685829164" and L.Work == "rbxassetid://138174795961249"
	and R.Idle == "rbxassetid://99191665025042" and R.Work == "rbxassetid://100611091362223"
	and C.Idle == "rbxassetid://122236338807516" and C.Work == "rbxassetid://139469079471002"
	and T.Idle == "rbxassetid://136548107891720" and T.Work == "rbxassetid://79325542756265",
	"los ids de Lumi, Rocon, Chispa y Talpa no cambian")
local seen = {}
for _, r in ipairs(rarities) do
	local m = PetModels.Build("nox", r)
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
	check(a:SetMoveSpeed(9) == "Run" and near(a.speed, 9 / a.runRef, 1e-9) and a:SetMoveSpeed(30) == "Run" and near(a.speed, 1.8, 1e-9),
		r .. ": Run al correr (9 studs/s -> 0,75; limite de 1,8)")
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
check(nAnim == 7, "7 objetos Animation compartidos por las 5 rarezas (sin duplicar)")
check(not warned("PetAnimator"), "sin avisos de carga de animaciones")
-- Rig incompatible: no se anima con Nox_v1
folder:FindFirstChild("Nox_rare"):SetAttribute("Rig", "nox_v1")
check(PetAnimator.Attach(PetModels.Build("nox", "rare")) == nil and warned("Rig=nox_v1"),
	"una plantilla con otro rig (p. ej. 'nox_v1' en minuscula) no se anima (aviso)")
folder:FindFirstChild("Nox_rare"):SetAttribute("Rig", "Nox_v1")

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
local P = join(901, "Noctambula")
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
-- rareza forzada solo para Nox (las demas especies de la zona 3 no tienen mitico)
local function forceNox(r) S.Capture.RollRarity = function(sid, ...) if sid == "nox" then return r end return "common" end end
-- 4a) Salvajes de cada rareza (Mitico incluido) en la zona 3 con su modelo, apoyados en el suelo
for _, r in ipairs(rarities) do
	forceNox(r)
	enterZone3(P)
	for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 30) end
	local ok, n = true, 0
	for _, w in ipairs(workspace:FindFirstChild("MisPETsSalvajes"):GetChildren()) do
		if w:GetAttribute("Species") == "nox" then
			if w:GetAttribute("AssetName") ~= MODELS[w:GetAttribute("Rarity")] or not near(w:GetAttribute("GroundOffset"), w:GetAttribute("Radius"), 1e-3) then
				ok = false
			end
			if w:GetAttribute("Rarity") == r then n = n + 1 end
		end
	end
	check(ok and n >= 1, "zona 3, " .. r .. ": " .. n .. " Nox salvajes con el modelo " .. MODELS[r] .. " y apoyo sin correccion")
end
-- 4b) Captura de varios Nox por el servidor (un registro por captura, sin duplicar)
local profile = S.DataService.Get(P)
local function owned(pr, key) return (pr.stacks.tank[key] or 0) + (pr.stacks.storage[key] or 0) end
local realClock = os.clock
local OFFSET = 0
os.clock = function() return realClock() + OFFSET end
local function captureNox(pl, rarity, list)
	forceNox(rarity)
	for _ = 1, 60 do
		local e
		for _, x in ipairs(list()) do if x.s == "nox" and x.r == rarity then e = x break end end
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
local before = { common = owned(profile, "nox:common"), legendary = owned(profile, "nox:legendary"), mythic = owned(profile, "nox:mythic") }
local c1, e1 = captureNox(P, "common", function() return encounters end)
check(c1 and c1.r == "common" and owned(profile, "nox:common") == before.common + 1, "captura de un Nox comun: llega como nox:common")
local again = act("captureFinish", { id = e1.id })
check(not again.captured and owned(profile, "nox:common") == before.common + 1, "repetir la captura del mismo PET no lo duplica")
local c2 = captureNox(P, "legendary", function() return encounters end)
local c3 = captureNox(P, "mythic", function() return encounters end)
check(c2 and c3 and owned(profile, "nox:legendary") == before.legendary + 1 and owned(profile, "nox:mythic") == before.mythic + 1,
	"Nox legendario y Nox mitico capturados, uno por captura")
check(profile.dex["nox:common"] and profile.dex["nox:legendary"] and profile.dex["nox:mythic"] and (profile.captured.nox or 0) >= 3,
	"registro: dex (incluido nox:mythic) y contador de capturas")
S.Capture.RollRarity = realRoll
-- 4c) Inventario, equipo (Mitico incluido), cambio Lumi <-> Nox y trabajo en el extractor lunar
act("dev", { cmd = "resources" })
act("depositAll")
act("craft", { line = "sanctuary" })
profile.zones.unlocked = math.max(profile.zones.unlocked or 1, 3) -- el extractor lunar es de la zona 3
for _ = 1, 4 do
	if profile.tools.pick < 4 then act("craft", { line = "pick" }) end
end
local crafted = act("craft", { line = "station_moon" })
check(crafted.ok and profile.stations.moon.level >= 1, "extractor lunar construido (" .. tostring(crafted.msg) .. ")")
local PetStoreMod = require(RS.Shared.PetStore)
PetStoreMod.Give(profile, "lumi", "common", false)
local function unitOf(s, r, st)
	for _, u in pairs(profile.units) do if u.s == s and u.r == r and u.st == st then return u end end
end
local function follower(species)
	for _ = 1, 10 do RunService.RenderStepped:Fire(1 / 30) end
	for _, c in ipairs(workspace:FindFirstChild("Compañeros"):GetChildren()) do
		if c:GetAttribute("Species") == species then return c end
	end
end
local function playingId(m, id)
	for _, t in ipairs(m:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator").__tracks) do
		if t.IsPlaying and (id == nil or t.Animation.AnimationId == id) then return true end
	end
	return false
end
-- Mitico equipado: plantilla provisional Nox
check(act("equip", { ref = { key = "nox:mythic" } }).ok, "equipar Nox mitico")
local um = unitOf("nox", "mythic", "equipped")
local fm = follower("nox")
check(fm and fm:GetAttribute("AssetName") == "Nox" and fm:GetAttribute("Rarity") == "mythic" and playingId(fm)
	and math.abs(fm:GetPivot().Y - fm:GetAttribute("GroundOffset")) < 1e-3,
	"el compañero mitico usa la plantilla provisional Nox, esta animado y su base pisa el suelo")
check(act("unequip", { unit = um.id }).ok, "desequipar Nox mitico")
local eq = act("equip", { ref = { key = "nox:legendary" } })
check(eq.ok and string.find(P:GetAttribute("Followers") or "", "nox:legendary", 1, true), "equipar Nox legendario")
local ue = unitOf("nox", "legendary", "equipped")
check(ue and table.find(profile.team, ue.id), "el Nox legendario esta en el equipo (estado equipped)")
local f = follower("nox")
check(f and f:GetAttribute("AssetName") == "Nox_legendary" and math.abs(f:GetPivot().Y - f:GetAttribute("GroundOffset")) < 1e-3,
	"el compañero usa Nox_legendary y su base de reposo esta en el suelo")
check(playingId(f), "el compañero Nox esta animado")
check(not act("assign", { station = "moon", ref = { unit = ue.id } }).ok, "un Nox equipado no puede asignarse a la vez (estados excluyentes)")
check(act("unequip", { unit = ue.id }).ok and ue.st ~= "equipped" and not table.find(profile.team, ue.id), "desequipar Nox")
local function count(s, r)
	local n = owned(profile, s .. ":" .. r)
	for _, u in pairs(profile.units) do if u.s == s and u.r == r then n = n + 1 end end
	return n
end
local nLeg = count("nox", "legendary")
check(act("equip", { ref = { key = "lumi:common" } }).ok, "cambiar a Lumi")
local ul = unitOf("lumi", "common", "equipped")
check(act("unequip", { unit = ul.id }).ok and act("equip", { ref = { key = "nox:common" } }).ok, "y de Lumi otra vez a Nox")
local uc = unitOf("nox", "common", "equipped")
check(act("unequip", { unit = uc.id }).ok, "desequipar el Nox comun")
check(not act("assign", { station = "iron", ref = { key = "nox:common" } }).ok, "Nox no trabaja en el extractor de hierro (catalogo)")
local asg = act("assign", { station = "moon", ref = { key = "nox:legendary" } })
check(asg.ok, "asignar un Nox legendario al extractor lunar")
local uw = unitOf("nox", "legendary", "working")
check(uw and table.find(profile.stations.moon.workers, uw.id), "el Nox queda trabajando (estado working)")
check(not act("equip", { ref = { unit = uw.id } }).ok, "un Nox trabajando no puede equiparse a la vez")
check(count("nox", "legendary") == nLeg, "cambiar de estado no duplica ni pierde Nox legendarios (" .. nLeg .. ")")
local plot = workspace.Plots:FindFirstChild("Plot_" .. P:GetAttribute("Plot"))
local worker
for _, d in ipairs(plot:GetDescendants()) do
	if d.ClassName == "Model" and d:GetAttribute("Species") == "nox" then worker = d end
end
check(worker and worker:GetAttribute("AssetName") == "Nox_legendary" and playingId(worker, PUBLISHED.Work),
	"el trabajador usa Nox_legendary y reproduce Work")
check(near(worker:GetAttribute("GroundOffset"), worker:GetAttribute("Radius"), 1e-3) and math.abs(worker:GetPivot().Y - worker:GetAttribute("GroundOffset")) < 1e-3,
	"el trabajador se apoya en el suelo (pivote - GroundOffset = suelo)")
local Production = S.Production
local t0 = os.time()
local Stats = require(RS.Shared.Stats)
local rate = Production.Rates(profile, "moon", Stats.Aggregate(profile, t0)).lunar or 0
local b0 = profile.stations.moon.buffer.lunar or 0
profile.stations.moon.updatedAt = t0 - 100
Production.Accrue(profile, "moon", t0)
check(rate > 0 and near((profile.stations.moon.buffer.lunar or 0) - b0, rate * 100, 1e-6),
	"el extractor produce cristal lunar con el Nox trabajando (" .. string.format("%.3f", rate) .. "/s)")
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
local P2 = join(902, "Vecino")
local prof2 = S.DataService.Get(P2)
check(prof2 ~= profile1 and owned(prof2, "nox:common") == 0 and owned(prof2, "nox:mythic") == 0, "el segundo jugador empieza sin los Nox del primero")
local c4 = captureNox(P2, "common", function() return encBy[P2] or {} end)
check(c4 and owned(prof2, "nox:common") == 1, "el segundo jugador captura su propio Nox en sus apariciones")
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
-- 4e) Persistencia: salir y volver (con un Nox Shiny y el Nox mitico en el inventario)
PetStoreMod.Give(profile1, "nox", "epic", true, true)
local keysBefore = {}
for _, where in ipairs({ "tank", "storage" }) do
	for k, v in pairs(profile1.stacks[where]) do if k:find("^nox:") or k:find("^lumi:") then keysBefore[where .. "/" .. k] = v end end
end
local hasShiny, hasMythic = false, false
for k in pairs(keysBefore) do
	if k:find("nox:epic:shiny", 1, true) then hasShiny = true end
	if k:find("nox:mythic", 1, true) then hasMythic = true end
end
check(hasShiny and hasMythic, "inventario con nox:epic:shiny y nox:mythic")
S.DataService.SaveNow(P)
Players.PlayerRemoving:Fire(P)
RUN_DELAYS()
check(DATABASE["u_901"] and DATABASE["u_901"].data and DATABASE["u_901"].lock == nil, "perfil guardado y bloqueo liberado al salir")
local P3 = join(901, "Noctambula")
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
check(kept, "al volver: mismos Nox (incluidos el Shiny y el mitico) y Lumi (especie, rareza, estado e identificador)")
check(table.find(p3.stations.moon.workers, uw.id) ~= nil, "al volver, el Nox sigue trabajando en el extractor lunar")
local Schema = require(RS.Shared.ProfileSchema)
check(p3.version == Schema.Default().version, "sin cambios de esquema ni de version del perfil")

local unexpected = {}
for _, w in ipairs(warnings) do
	-- esperados: el aviso del rig incompatible (provocado en 3) y los de plantillas por rareza de
	-- Lumi/Rocon/Chispa/Talpa que esta prueba no crea (en el repositorio existen)
	if not (w:find("Rig=nox_v1", 1, true) or w:find("la plantilla Lumi_", 1, true) or w:find("la plantilla Rocon_", 1, true)
		or w:find("la plantilla Chispa_", 1, true) or w:find("la plantilla Talpa_", 1, true)) then
		table.insert(unexpected, w)
	end
end
check(#unexpected == 0, "sin avisos inesperados (" .. #unexpected .. ")")
print("ALL NOX TESTS PASSED")
