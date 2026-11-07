-- Pruebas de las variantes de Lumi por rareza (Lumi_rare, Lumi_epic, Lumi_legendary).
-- Ejecutar: lua5.4 tools/sim/variants.lua
-- Las plantillas son SIMULADAS con la estructura de los modelos reales (MeshPart con
-- 34 huesos, SurfaceAppearance, AnimationController, Rig = "Lumi_v7"); los mapas de
-- color son marcadores de prueba. Los 7 AnimationId son los publicados de Lumi Comun.
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

local PUBLISHED = {
	Idle = "rbxassetid://123787685829164", Walk = "rbxassetid://98626202379591", Run = "rbxassetid://139144120637137",
	Happy = "rbxassetid://98260166738628", Sleep_Enter = "rbxassetid://124146121312676",
	Sleep_Loop = "rbxassetid://87678883964103", Work = "rbxassetid://138174795961249",
}
local STATES = { "Idle", "Walk", "Run", "Happy", "Sleep_Enter", "Sleep_Loop", "Work" }
local VARIANTS = { rare = "Lumi_rare", epic = "Lumi_epic", legendary = "Lumi_legendary" }
local HIER = { { "Root", nil }, { "Hips", "Root" }, { "Spine", "Hips" }, { "Chest", "Spine" }, { "Neck", "Chest" }, { "Head", "Neck" },
	{ "Jaw", "Head" }, { "Ear_01.L", "Head" }, { "Ear_02.L", "Ear_01.L" }, { "Ear_03.L", "Ear_02.L" }, { "Ear_01.R", "Head" },
	{ "Ear_02.R", "Ear_01.R" }, { "Ear_03.R", "Ear_02.R" }, { "Shoulder.L", "Chest" }, { "UpperArm.L", "Shoulder.L" },
	{ "Forearm.L", "UpperArm.L" }, { "FrontPaw.L", "Forearm.L" }, { "Shoulder.R", "Chest" }, { "UpperArm.R", "Shoulder.R" },
	{ "Forearm.R", "UpperArm.R" }, { "FrontPaw.R", "Forearm.R" }, { "Tail_01", "Hips" }, { "Tail_02", "Tail_01" },
	{ "Tail_03", "Tail_02" }, { "Tail_04", "Tail_03" }, { "Tail_05", "Tail_04" }, { "Thigh.L", "Hips" }, { "Shin.L", "Thigh.L" },
	{ "BackFoot.L", "Shin.L" }, { "BackPaw.L", "BackFoot.L" }, { "Thigh.R", "Hips" }, { "Shin.R", "Thigh.R" },
	{ "BackFoot.R", "Shin.R" }, { "BackPaw.R", "BackFoot.R" } }

local folder = Instance.new("Folder")
folder.Name = "PetAssets"
folder.Parent = RS
-- Plantilla con la estructura de los .rbxm reales. size = tamaño de la malla en reposo.
local function makeTemplate(name, bodyName, size, colorMap)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Rig", "Lumi_v7")
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
	for _, h in ipairs(HIER) do
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
local VSIZE = Vector3.new(1.18, 1.6462, 1.58) -- alto de las variantes en reposo (FBX: 1.646)
makeTemplate("Lumi", "Lumi_Comun_Body", Vector3.new(1.1831539, 1.6666665, 1.5838034), "SIM_textura_comun")

local function colorMapOf(m)
	local body = m.PrimaryPart
	local sa = body and body:FindFirstChildOfClass("SurfaceAppearance")
	return sa and sa.ColorMap
end
local function animatorOf(m)
	local acs, an = 0, nil
	for _, c in ipairs(m:GetChildren()) do
		if c.ClassName == "AnimationController" then acs = acs + 1; an = c:FindFirstChildOfClass("Animator") end
	end
	return an, acs
end

-- 1) Sin plantillas de variante: respaldo a Lumi con aviso util ---------------------------
local rFallback = PetModels.Build("lumi", "rare")
check(rFallback:GetAttribute("AssetName") == "Lumi" and rFallback:GetAttribute("Rarity") == "rare", "sin Lumi_rare: el Lumi raro usa Lumi (respaldo actual)")
check(warned("Falta (o no es valida) la plantilla Lumi_rare") and warned("assets/pets/Lumi_rare.rbxm"), "aviso util en Output (nombre y ruta del archivo que falta)")
local nw = #warnings
PetModels.Build("lumi", "rare")
check(#warnings == nw, "el aviso sale una sola vez")
PetModels.Build("lumi", "mythic")
check(not warned("Lumi_mythic"), "mitico sin modelo propio previsto: usa Lumi sin aviso")
local missingWarnings = #warnings

-- 2) Con las tres plantillas: cada rareza usa su modelo y su textura ------------------------
for r, name in pairs(VARIANTS) do
	makeTemplate(name, name:gsub("Lumi_", "Lumi_Body_"), VSIZE, "SIM_textura_" .. r)
end
local expectedModel = { common = "Lumi", rare = "Lumi_rare", epic = "Lumi_epic", legendary = "Lumi_legendary", mythic = "Lumi" }
local maps = {}
for _, rar in ipairs(PetCatalog.Rarities) do
	local m = PetModels.Build("lumi", rar.id, { label = "Lumi" })
	check(m:GetAttribute("AssetName") == expectedModel[rar.id] and m:GetAttribute("Species") == "lumi" and m:GetAttribute("Rarity") == rar.id,
		rar.id .. ": modelo " .. m:GetAttribute("AssetName") .. ", especie y rareza intactas")
	check(m:GetAttribute("Rig") == "Lumi_v7" and m.PrimaryPart and m.PrimaryPart.ClassName == "MeshPart", rar.id .. ": Rig = Lumi_v7 y PrimaryPart MeshPart")
	maps[rar.id] = colorMapOf(m)
end
check(maps.rare == "SIM_textura_rare" and maps.epic == "SIM_textura_epic" and maps.legendary == "SIM_textura_legendary"
	and maps.common == "SIM_textura_comun", "cada rareza muestra su propia textura")
check(#warnings == missingWarnings, "con las plantillas presentes no hay avisos nuevos")
local tmplRare = folder:FindFirstChild("Lumi_rare")
check(colorMapOf(tmplRare) == "SIM_textura_rare" and tmplRare:GetAttribute("Rig") == "Lumi_v7", "las plantillas originales no se modifican")
check(PetModels.Build("lumi", "common"):GetAttribute("AssetName") == "Lumi", "Lumi Comun sigue usando su plantilla")

-- 3) Animaciones: los 7 ids publicados de Lumi Comun, sin duplicados ----------------------
local seen, allSame = {}, true
for r in pairs(VARIANTS) do
	local m = PetModels.Build("lumi", r)
	local a = PetAnimator.Attach(m)
	local an, acs = animatorOf(m)
	check(a ~= nil and acs == 1 and #an.__tracks == 7, r .. ": un solo AnimationController del modelo y 7 pistas")
	for _, s in ipairs(STATES) do
		if not (a:Has(s) and a.tracks[s].Animation.AnimationId == PUBLISHED[s]) then allSame = false end
		seen[a.tracks[s].Animation] = true
	end
	check(a:SetMoveSpeed(0) == "Idle" and a:SetMoveSpeed(18) == "Run" and a:Celebrate() == "Happy", r .. ": Idle, Run y Happy")
	a.tracks.Happy:__finish()
	check(a:Sleep() and a:GetState() == "Sleep_Enter", r .. ": Sleep_Enter")
	a.tracks.Sleep_Enter:__finish()
	check(a:GetState() == "Sleep_Loop", r .. ": Sleep_Loop")
	a:Wake()
	check(a:SetWorking(true) == "Work", r .. ": Work")
	a:Destroy()
end
check(allSame, "las tres variantes usan exactamente los 7 ids publicados de Lumi Comun")
local nAnim = 0
for _ in pairs(seen) do nAnim = nAnim + 1 end
check(nAnim == 7, "7 objetos Animation compartidos por todas las variantes (sin duplicar)")
folder:FindFirstChild("Lumi_epic"):SetAttribute("Rig", "Otro")
local nw2 = #warnings
check(PetAnimator.Attach(PetModels.Build("lumi", "epic")) == nil and #warnings > nw2, "una variante con otro rig no se anima con Lumi_v7 (aviso)")
folder:FindFirstChild("Lumi_epic"):SetAttribute("Rig", "Lumi_v7")
missingWarnings = #warnings

-- 4) Apoyo y efectos por rareza --------------------------------------------------------
for _, rar in ipairs(PetCatalog.Rarities) do
	local m = PetModels.Build("lumi", rar.id)
	local bb, size = m:GetBoundingBox()
	check(near(size.Y, 2 * rar.size, 1e-3) and near(m:GetAttribute("GroundOffset"), rar.size, 1e-3),
		rar.id .. ": alto " .. string.format("%.2f", size.Y) .. " y GroundOffset = base de la malla en reposo")
	m:PivotTo(PetGrounding.PivotCFrame(Vector3.new(0, 3, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, -1), m:GetAttribute("GroundOffset")))
	local _, s2 = m:GetBoundingBox()
	check(near(m:GetPivot().Y - m:GetAttribute("GroundOffset"), 3, 1e-6), rar.id .. ": suelas en el suelo")
end
local function fx(m)
	local lights, sparkles, emitters = {}, 0, {}
	for _, d in ipairs(m:GetDescendants()) do
		if d.ClassName == "PointLight" then table.insert(lights, d)
		elseif d.ClassName == "Sparkles" then sparkles = sparkles + 1
		elseif d.ClassName == "ParticleEmitter" then table.insert(emitters, d) end
	end
	return lights, sparkles, emitters, m:FindFirstChildOfClass("Highlight")
end
local FX = PetAssets.Effects
local maxB = 0
for r in pairs(VARIANTS) do
	local l, s, e = fx(PetModels.Build("lumi", r))
	for _, x in ipairs(l) do maxB = math.max(maxB, x.Brightness) end
	check(s == 0 and #e == 1 and e[1].LightEmission <= 0.3 and #l <= 2, r .. ": perfil moderado (sin Sparkles, 1 emisor, " .. #l .. " luz/luces)")
end
check(maxB <= math.max(FX.ownLight.brightness, FX.rarityLight.brightness), "ninguna luz de variante supera el perfil moderado (" .. maxB .. ")")
local _, _, eR = fx(PetModels.Build("lumi", "rare"))
local lE = fx(PetModels.Build("lumi", "epic"))
local lL, _, eL, hL = fx(PetModels.Build("lumi", "legendary"))
check(eR[1].Rate < eL[1].Rate and #lE == 2 and #lL == 2 and hL ~= nil and hL.FillTransparency == 1,
	"rarezas superiores mas vistosas (mas destellos, luz de color, contorno) sin tapar la textura")

-- 5) Juego completo: salvajes, captura, inventario, equipo, trabajo y reentrada -----------
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
local P = join(501, "Coleccionista")
RUN_SCRIPT(CLIENT_SCRIPT)
local RunService = game:GetService("RunService")
local function act(n, pl) local r = RS.Remotes.Action:InvokeServer(n, pl or {}); RUN_DELAYS(); return r end
local encounters = {}
RS.Remotes.Encounters.OnClientEvent:Connect(function(_, list) encounters = list end)
local realRoll = S.Capture.RollRarity
-- salvajes de cada rareza (se fuerza el sorteo solo en la prueba)
for r, name in pairs(VARIANTS) do
	S.Capture.RollRarity = function() return r end
	P:SetAttribute("Area", "home")
	S.Capture.OnAreaChanged(P, "home")
	P:SetAttribute("Area", "z1")
	S.Capture.OnAreaChanged(P, "z1")
	for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 30) end
	local ok, n = true, 0
	for _, w in ipairs(workspace:FindFirstChild("MisPETsSalvajes"):GetChildren()) do
		if w:GetAttribute("Rarity") == r then
			n = n + 1
			if w:GetAttribute("AssetName") ~= name then ok = false end
		end
	end
	check(ok and n >= 5, "salvajes " .. r .. ": " .. n .. " con el modelo " .. name)
end
-- captura de un Lumi legendario
S.Capture.RollRarity = function() return "legendary" end
P:SetAttribute("Area", "home"); S.Capture.OnAreaChanged(P, "home")
P:SetAttribute("Area", "z1"); S.Capture.OnAreaChanged(P, "z1")
local profile = S.DataService.Get(P)
local function owned(key) return (profile.stacks.tank[key] or 0) + (profile.stacks.storage[key] or 0) end
local before = owned("lumi:legendary")
local realClock = os.clock
local OFFSET = 0
os.clock = function() return realClock() + OFFSET end
local captured = false
for _ = 1, 40 do
	local e = encounters[1]
	if not e then P:SetAttribute("Area", "home"); S.Capture.OnAreaChanged(P, "home"); P:SetAttribute("Area", "z1"); S.Capture.OnAreaChanged(P, "z1"); e = encounters[1] end
	P.Character.HumanoidRootPart.__props.CFrame = CFrame.new(e.x, 3, e.z)
	act("captureBegin", { id = e.id })
	OFFSET = OFFSET + 100
	local r = act("captureFinish", { id = e.id })
	if r.captured then captured = r break end
end
S.Capture.RollRarity = realRoll -- os.clock sigue adelantado: el reloj debe ser monotono
check(captured and captured.r == "legendary" and (profile.stacks.tank["lumi:legendary"] or 0) >= 1 and owned("lumi:legendary") == before + 1,
	"captura de un Lumi legendario: llega al tanque como lumi:legendary")
-- equipar un raro y asignar un epico al extractor
act("dev", { cmd = "resources" })
act("dev", { cmd = "pets" })
act("craft", { line = "sanctuary" })
act("craft", { line = "station_stone" })
check(act("equip", { ref = { key = "lumi:rare" } }).ok, "equipar Lumi raro")
check(act("assign", { station = "stone", ref = { key = "lumi:epic" } }).ok, "asignar Lumi epico al extractor")
check(string.find(P:GetAttribute("Followers") or "", "lumi:rare", 1, true) ~= nil, "atributo Followers con lumi:rare")
for _ = 1, 10 do RunService.RenderStepped:Fire(1 / 30) end
local function follower()
	for _, c in ipairs(workspace:FindFirstChild("Compañeros"):GetChildren()) do
		if c:GetAttribute("Rarity") == "rare" then return c end
	end
end
local f = follower()
check(f and f:GetAttribute("AssetName") == "Lumi_rare" and colorMapOf(f) == "SIM_textura_rare", "el compañero raro usa Lumi_rare con su textura")
local fan = animatorOf(f)
local walking = false
for _, t in ipairs(fan.__tracks) do if t.IsPlaying then walking = true end end
check(walking and math.abs(f:GetPivot().Y - f:GetAttribute("GroundOffset")) < 1e-3, "el compañero raro esta animado y apoyado en el suelo")
local plot = workspace.Plots:FindFirstChild("Plot_" .. P:GetAttribute("Plot"))
local worker
for _, d in ipairs(plot:GetDescendants()) do
	if d.ClassName == "Model" and d:GetAttribute("Species") == "lumi" and d:GetAttribute("Rarity") == "epic" then worker = d end
end
check(worker and worker:GetAttribute("AssetName") == "Lumi_epic", "el trabajador epico usa Lumi_epic")
local wan = animatorOf(worker)
local working = false
for _, t in ipairs(wan.__tracks) do if t.IsPlaying and t.Animation.AnimationId == PUBLISHED.Work then working = true end end
check(working and math.abs(worker:GetPivot().Y - worker:GetAttribute("GroundOffset")) < 1e-3, "el trabajador epico reproduce Work y pisa el suelo")
-- salir y volver a entrar: rareza y datos intactos
local keysBefore = {}
for _, where in ipairs({ "tank", "storage" }) do
	for k, v in pairs(profile.stacks[where]) do if k:find("^lumi:") then keysBefore[where .. "/" .. k] = v end end
end
local unitsBefore = {}
for id, u in pairs(profile.units) do unitsBefore[id] = u.s .. ":" .. u.r .. ":" .. tostring(u.st) end
S.DataService.SaveNow(P)
Players.PlayerRemoving:Fire(P)
RUN_DELAYS()
check(DATABASE["u_501"] and DATABASE["u_501"].data and DATABASE["u_501"].lock == nil, "perfil guardado y bloqueo liberado al salir")
local P2 = join(501, "Coleccionista")
local p2 = S.DataService.Get(P2)
local same = true
for k, v in pairs(keysBefore) do
	local where, key = k:match("^(%w+)/(.+)$")
	if p2.stacks[where][key] ~= v then same = false end
end
for id, s in pairs(unitsBefore) do
	local u = p2.units[id]
	if not u or (u.s .. ":" .. u.r .. ":" .. tostring(u.st)) ~= s then same = false end
end
check(same, "al volver: mismas pilas lumi:<rareza> y mismas unidades (especie, rareza, estado)")
for _ = 1, 10 do RunService.RenderStepped:Fire(1 / 30) end
local f2
for _, c in ipairs(workspace:FindFirstChild("Compañeros"):GetChildren()) do
	if c:GetAttribute("Rarity") == "rare" and c:GetAttribute("AssetName") == "Lumi_rare" then f2 = c end
end
check(f2 ~= nil, "al volver, el compañero raro vuelve a usar Lumi_rare")
local Schema = require(RS.Shared.ProfileSchema)
check(p2.version == Schema.Default().version and p2.schemaVersion == profile.schemaVersion, "sin cambios de esquema ni de version")

-- 6) Una plantilla desaparece en pleno juego: respaldo sin errores ---------------------------
folder:FindFirstChild("Lumi_epic").Parent = nil
local me = PetModels.Build("lumi", "epic")
check(me:GetAttribute("AssetName") == "Lumi" and me:GetAttribute("Rarity") == "epic" and PetAnimator.Attach(me) ~= nil,
	"sin Lumi_epic: el epico usa Lumi, animado, con su rareza intacta")
check(warned("Falta (o no es valida) la plantilla Lumi_epic"), "aviso de plantilla Lumi_epic ausente")

local unexpected = {}
for _, w in ipairs(warnings) do
	if not (w:find("Falta (o no es valida) la plantilla", 1, true) or w:find("Rig=Otro", 1, true)) then table.insert(unexpected, w) end
end
check(#unexpected == 0, "sin avisos inesperados (" .. #unexpected .. ")")
print("ALL VARIANTS TESTS PASSED")
