-- Pruebas de la integracion de modelos importados (Lumi) con respaldo procedural.
-- Ejecutar: lua5.4 tools/sim/petassets.lua
-- La plantilla "Lumi" de esta prueba es FALSA (partes del simulador) y sus
-- AnimationId son marcadores de prueba: no son assets reales de Roblox.
dofile("tools/sim/mock.lua")
local function check(c, msg) if not c then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-6) end

local warnings = {}
warn = function(...) local t = {} for i, v in ipairs({ ... }) do t[i] = tostring(v) end table.insert(warnings, table.concat(t, " ")) print("WARN", ...) end

RUN_SCRIPT(SERVER_SCRIPT)
local RS = game:GetService("ReplicatedStorage")
require(RS.Shared.Config).ActionRateLimit = 1e9
local PetModels = require(RS.Shared.PetModels)
local PetAssets = require(RS.Shared.PetAssets)
local PetAnimator = require(RS.Shared.PetAnimator)
local PetCatalog = require(RS.Shared.PetCatalog)

-- 0) Ids publicados de Lumi Comun: exactamente los que dio el dueño del proyecto ----------
local SET = PetAssets.AnimationSets.Lumi_v7
local LUMI7 = { "Idle", "Walk", "Run", "Happy", "Sleep_Enter", "Sleep_Loop", "Work" }
local EXPECTED = {
	Idle = "rbxassetid://123787685829164", Walk = "rbxassetid://98626202379591", Run = "rbxassetid://139144120637137",
	Happy = "rbxassetid://98260166738628", Sleep_Enter = "rbxassetid://124146121312676",
	Sleep_Loop = "rbxassetid://87678883964103", Work = "rbxassetid://138174795961249",
}
local nIds = 0
for k, v in pairs(SET.ids) do
	nIds = nIds + 1
	check(EXPECTED[k] == v and PetAssets.IsAnimationId(v), "id publicado " .. k .. " = " .. v)
end
check(nIds == 7, "Lumi_v7 trae exactamente 7 ids")
check(PetAssets.Species.lumi.animationSet == "Lumi_v7" and SET.rig == "Lumi_v7", "Lumi usa el conjunto Lumi_v7")
-- Las secciones 1-3 prueban plantillas con y sin animaciones propias: conjunto vacio temporal
local PUBLISHED = SET.ids
SET.ids = {}

-- 1) Sin carpeta de assets: todo es procedural, igual que antes ------------------------
check(RS:FindFirstChild("PetAssets") == nil, "sin carpeta PetAssets en el simulador")
check(PetAssets.Find("lumi", "common") == nil, "sin plantilla: Find devuelve nil")
for _, sp in ipairs(PetCatalog.Species) do
	for _, rar in ipairs(PetCatalog.Rarities) do
		local m = PetModels.Build(sp.id, rar.id, { scale = 0.85, hat = true, label = "x" })
		local u = 2 * 0.85 * rar.size
		assert(m:GetAttribute("Source") == "procedural", sp.id)
		assert(m.PrimaryPart and m.PrimaryPart.Name == "Body", sp.id)
		assert(near(m:GetAttribute("Radius"), u * 0.5), sp.id)
		assert(m:GetAttribute("Species") == sp.id and m:GetAttribute("Rarity") == rar.id, sp.id)
		assert(PetAnimator.Attach(m) == nil, sp.id)
	end
end
check(true, "15 especies x 5 rarezas: modelo procedural, raiz Body, radio, especie y rareza")
local proc = PetModels.Build("lumi", "mythic", { label = "Lumi" })
check(proc:FindFirstChildOfClass("Highlight") ~= nil and proc.Body:FindFirstChild("Tag") ~= nil, "efectos de rareza y etiqueta en el procedural")

-- 2) Plantilla importada falsa --------------------------------------------------
local folder = Instance.new("Folder")
folder.Name = "PetAssets"
folder.Parent = RS
local function part(cls, name, parent, size, pos, transparency)
	local p = Instance.new(cls)
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(pos)
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent
	return p
end
local function makeTemplate(name, withAnims)
	local t = Instance.new("Model")
	t.Name = name
	local root = part("Part", "RootPart", t, Vector3.new(1, 1, 1), Vector3.new(0, 0.5, 0), 1)
	local body = part("MeshPart", "LumiMesh", t, Vector3.new(2, 3, 2), Vector3.new(0, 1.5, 0))
	local m6 = Instance.new("Motor6D")
	m6.Part0 = root
	m6.Part1 = body
	m6.Parent = root
	part("MeshPart", "Tail", t, Vector3.new(0.5, 0.5, 1), Vector3.new(0, 1, 1.2))
	local evil = Instance.new("Script")
	evil.Name = "NoDeberiaEstar"
	evil.Parent = t
	t.PrimaryPart = root
	local ac = Instance.new("AnimationController")
	ac.Parent = t
	Instance.new("Animator").Parent = ac
	if withAnims then
		local af = Instance.new("Folder")
		af.Name = "Animations"
		af.Parent = t
		for state, id in pairs({ Idle = "rbxassetid://101", Walk = "rbxassetid://102", CaptureReaction = "rbxassetid://105" }) do
			local a = Instance.new("Animation")
			a.Name = state
			a.AnimationId = id -- marcador de prueba, no es un asset real
			a.Parent = af
		end
	end
	t.Parent = folder
	return t
end
local template = makeTemplate("Lumi", true)

local found, cfg, name = PetAssets.Find("lumi", "common")
check(found == template and name == "Lumi", "Find encuentra la plantilla Lumi")
check(PetAssets.Find("roccon", "common") == nil and PetAssets.Find(PetCatalog.Species[2].id, "common") == nil, "otras especies siguen sin plantilla")

local m = PetModels.Build("lumi", "common", { label = "Lumi · Comun" })
check(m:GetAttribute("Source") == "asset" and m:GetAttribute("AssetName") == "Lumi", "Lumi usa el modelo importado")
check(m:GetAttribute("Species") == "lumi" and m:GetAttribute("Rarity") == "common", "especie y rareza intactas en el modelo")
check(m.PrimaryPart and m.PrimaryPart.Name == "RootPart", "PrimaryPart = RootPart")
local scripts = 0
for _, d in ipairs(m:GetDescendants()) do if d.ClassName == "Script" then scripts = scripts + 1 end end
check(scripts == 0, "scripts eliminados del clon")
local tmplScript = template:FindFirstChild("NoDeberiaEstar")
check(tmplScript ~= nil and near(template:GetExtentsSize().Y, 3), "la plantilla original no se modifica")
local allSafe, rootAnch, othersFree = true, false, true
for _, d in ipairs(m:GetDescendants()) do
	if d:IsA("BasePart") then
		if d.CanCollide or d.CanTouch or not d.Massless then allSafe = false end
		if d == m.PrimaryPart then rootAnch = d.Anchored else othersFree = othersFree and not d.Anchored end
	end
end
check(allSafe, "sin colision, sin toque y sin masa")
check(rootAnch and othersFree, "raiz anclada y el resto unido a ella")
check(m.Tail:FindFirstChildOfClass("WeldConstraint") ~= nil, "parte suelta (Tail) soldada a la raiz")
check(m.LumiMesh:FindFirstChildOfClass("WeldConstraint") == nil, "parte con Motor6D no recibe soldadura extra (el rig sigue animable)")
check(near(m:GetExtentsSize().Y, 2, 1e-4), "escalado al alto del PET comun (2 studs): " .. string.format("%.3f", m:GetExtentsSize().Y))
check(near(m:GetAttribute("Radius"), 1, 1e-4), "Radius = mitad del alto")
local bb = m:GetBoundingBox()
check(near(m:GetPivot().Y, bb.Y, 1e-4), "pivote en el centro vertical del PET")
m:PivotTo(CFrame.new(10, 5, -3))
check(near(m:GetPivot().X, 10) and near(m:GetPivot().Y, 5), "PivotTo mueve el PET a su pivote")
check(m.PrimaryPart:FindFirstChildOfClass("PointLight") ~= nil, "Lumi aporta luz tambien con modelo importado")
check(m.PrimaryPart:FindFirstChild("Tag") ~= nil, "etiqueta sobre el modelo importado")

local mm = PetModels.Build("lumi", "mythic", { hat = true })
check(near(mm:GetAttribute("Radius"), 1.5, 1e-4), "mitico mas grande (alto 3 = 2 x tamaño 1.5)")
check(mm:FindFirstChildOfClass("Highlight") ~= nil and mm:FindFirstChild("HatBrim") ~= nil, "efectos de rareza y sombrero en el importado")
check(PetModels.Build("lumi", "common", { procedural = true }):GetAttribute("Source") == "procedural", "opts.procedural fuerza el respaldo")

-- variante por rareza
local variant = makeTemplate("Lumi_mythic", false)
check(PetModels.Build("lumi", "mythic"):GetAttribute("AssetName") == "Lumi_mythic", "variante Lumi_mythic para la rareza mitica")
check(PetModels.Build("lumi", "rare"):GetAttribute("AssetName") == "Lumi", "otras rarezas usan Lumi")
variant.Parent = nil

-- interruptor en Studio
folder:SetAttribute("UseProcedural", true)
check(PetModels.Build("lumi", "common"):GetAttribute("Source") == "procedural", "atributo UseProcedural vuelve al respaldo")
folder:SetAttribute("UseProcedural", nil)
PetAssets.Enabled = false
check(PetModels.Build("lumi", "common"):GetAttribute("Source") == "procedural", "PetAssets.Enabled = false vuelve al respaldo")
PetAssets.Enabled = true

-- 3) Animaciones -------------------------------------------------------------
local anim = PetAnimator.Attach(m)
check(anim ~= nil, "animador conectado al modelo importado")
check(anim:Has("Idle") and anim:Has("Walk") and anim:Has("CaptureReaction") and not anim:Has("Run") and not anim:Has("Jump"),
	"carga solo las animaciones presentes (Idle, Walk, CaptureReaction)")
check(anim:SetMoveSpeed(0) == "Idle", "quieto -> Idle")
check(anim:SetMoveSpeed(3) == "Walk", "caminando -> Walk")
check(anim:SetMoveSpeed(20) == "Walk", "sin Run: respaldo a Walk")
check(anim:Play("Jump") == "Idle", "sin Jump: respaldo a Idle")
check(anim:Play("CaptureReaction") == "CaptureReaction", "reaccion de captura")
local tr = anim.tracks
check(tr.Idle.Looped == true and tr.Walk.Looped == true and tr.CaptureReaction.Looped == true, "bucles configurados")
check(tr.CaptureReaction.IsPlaying and not tr.Idle.IsPlaying, "solo una pista de estado activa")
anim:Destroy()
check(not tr.CaptureReaction.IsPlaying and anim:Play("Idle") == nil, "Destroy detiene y desactiva")

check(not PetAssets.IsAnimationId("") and not PetAssets.IsAnimationId("123") and not PetAssets.IsAnimationId("rbxassetid://abc")
	and PetAssets.IsAnimationId("rbxassetid://123"), "validacion de AnimationId")
local noAnim = makeTemplate("Lumi_rare", false)
local mr = PetModels.Build("lumi", "rare")
check(mr:GetAttribute("AssetName") == "Lumi_rare" and PetAnimator.Attach(mr) == nil, "modelo importado sin animaciones: sin animador (sigue el rebote procedural)")
PetAssets.Species.lumi.animations.Idle = "rbxassetid://201" -- marcador de prueba
local cfgAnim = PetAnimator.Attach(PetModels.Build("lumi", "rare"))
check(cfgAnim ~= nil and cfgAnim:Has("Idle") and cfgAnim:SetMoveSpeed(5) == "Idle", "ids configurados como respaldo de la plantilla")
PetAssets.Species.lumi.animations.Idle = nil
check(next(PetAssets.Species.lumi.animations) == nil, "la configuracion publicada no trae ids inventados")

-- 3b) Conjunto completo de Lumi Comun (7 animaciones) y controlador por capas ------
-- Con los ids publicados reales (el Animator es simulado: no se descargan).
SET.ids = PUBLISHED
local m7 = PetModels.Build("lumi", "rare") -- Lumi_rare: sin carpeta Animations, usa el conjunto
local a7 = PetAnimator.Attach(m7)
check(a7 ~= nil, "conjunto Lumi_v7: animador conectado")
local allSeven = true
for _, s in ipairs(LUMI7) do allSeven = allSeven and a7:Has(s) end
check(allSeven and not a7:Has("Jump") and not a7:Has("CaptureReaction"), "carga las 7 animaciones de Lumi y nada mas")
local idsOk = true
for _, s in ipairs(LUMI7) do idsOk = idsOk and a7.tracks[s].Animation.AnimationId == EXPECTED[s] and a7.tracks[s].Animation.Name == s end
check(idsOk, "cada pista usa su id publicado")
for _, r in ipairs({ "rare", "epic", "legendary" }) do
	local ar = PetAnimator.Attach(PetModels.Build("lumi", r))
	local all = ar ~= nil
	for _, s in ipairs(LUMI7) do all = all and ar:Has(s) end
	check(all, "rareza " .. r .. ": mismo rig de 34 huesos, reutiliza las 7 animaciones")
end
local t7 = a7.tracks
check(t7.Idle.Looped and t7.Walk.Looped and t7.Run.Looped and t7.Work.Looped and t7.Sleep_Loop.Looped
	and not t7.Happy.Looped and not t7.Sleep_Enter.Looped, "bucles: Idle/Walk/Run/Work/Sleep_Loop si; Happy/Sleep_Enter no")
check(t7.Idle.Priority == Enum.AnimationPriority.Idle and t7.Walk.Priority == Enum.AnimationPriority.Movement
	and t7.Run.Priority == Enum.AnimationPriority.Movement and t7.Work.Priority == Enum.AnimationPriority.Action
	and t7.Happy.Priority == Enum.AnimationPriority.Action, "prioridades configuradas")
local function playing()
	local list = {}
	for s, t in pairs(t7) do if t.IsPlaying then table.insert(list, s) end end
	return list
end
local function only(state)
	local p = playing()
	return #p == 1 and p[1] == state
end
check(a7:SetMoveSpeed(0) == "Idle" and only("Idle"), "quieto -> Idle (una sola pista)")
check(a7:SetMoveSpeed(4) == "Walk" and only("Walk") and near(t7.Walk.Speed, 1), "Walk a 4 studs/s, velocidad 1")
check(a7:SetMoveSpeed(18) == "Run" and only("Run") and near(t7.Run.Speed, 1.5), "Run a 18 studs/s, velocidad 1.5")
local runPlays = t7.Run.plays
for _ = 1, 20 do a7:SetMoveSpeed(18) end
check(t7.Run.plays == runPlays, "mismo estado: la pista no se reinicia cada fotograma")
check(a7:SetWorking(true) == "Work" and only("Work"), "trabajo -> Work")
-- Happy: reaccion de una vez que respeta la capa base y vuelve a ella
check(a7:Celebrate() == "Happy" and only("Happy"), "Happy interrumpe con fundido y queda sola")
a7:SetMoveSpeed(4)
check(only("Happy") and a7.base == "Walk", "durante Happy, la locomocion se anota sin cortar la reaccion")
t7.Happy:__finish()
check(only("Walk"), "al terminar Happy vuelve al estado base actual (Walk)")
a7:Celebrate()
a7:Celebrate()
check(only("Happy") and t7.Happy.plays >= 3, "Happy repetido reinicia la reaccion")
t7.Happy:__finish()
-- Sueño: Sleep_Enter -> Sleep_Loop -> despertar
a7:SetMoveSpeed(0)
check(a7:Sleep() == true and only("Sleep_Enter") and a7:IsSleeping(), "Sleep empieza con Sleep_Enter")
a7:SetMoveSpeed(0)
check(only("Sleep_Enter"), "quieto mientras se acuesta: sigue la transicion")
t7.Sleep_Enter:__finish()
check(only("Sleep_Loop"), "al terminar Sleep_Enter pasa a Sleep_Loop")
check(a7:Celebrate() == nil and only("Sleep_Loop"), "dormido no celebra")
a7:Wake()
check(not a7:IsSleeping() and only("Idle"), "Wake vuelve al estado base")
a7:Sleep()
a7:SetMoveSpeed(5)
check(not a7:IsSleeping() and only("Walk"), "si el PET se desplaza dormido, despierta (nunca se desliza dormido)")
t7.Sleep_Enter:__finish()
check(only("Walk"), "un final atrasado de Sleep_Enter no reactiva el sueño")
-- Reutilizacion: pistas cargadas una vez; Animation compartidas entre modelos
local an7 = m7:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator")
check(#an7.__tracks == 7, "7 pistas cargadas una sola vez tras todas las transiciones")
local m7b = PetModels.Build("lumi", "rare")
local a7b = PetAnimator.Attach(m7b)
check(a7b.tracks.Idle.Animation == t7.Idle.Animation, "los objetos Animation se comparten entre PETs")
a7b:Destroy()
check(a7b:Play("Idle") == nil and a7b:Celebrate() == nil and a7b:Sleep() == false, "Destroy deja el controlador inerte")
-- Rarezas: mismo rig reutiliza el conjunto; rig distinto no se anima con el
local mr7 = PetModels.Build("lumi", "epic")
check(PetAnimator.Attach(mr7):Has("Sleep_Loop"), "otra rareza con el mismo rig reutiliza el conjunto")
noAnim:SetAttribute("Rig", "Otro_rig")
local nw0 = #warnings
check(PetAnimator.Attach(PetModels.Build("lumi", "rare")) == nil and #warnings > nw0, "rig incompatible: no se usa el conjunto (aviso)")
table.remove(warnings) -- aviso esperado
noAnim:SetAttribute("Rig", "Lumi_v7")
check(PetAnimator.Attach(PetModels.Build("lumi", "rare")) ~= nil, "Rig = Lumi_v7 coincide con el conjunto")
noAnim:SetAttribute("Rig", nil)
PetAssets.Species.lumi.variants.rare = { animations = { Happy = "rbxassetid://999" } }
local av = PetAnimator.Attach(PetModels.Build("lumi", "rare"))
check(av.tracks.Happy.Animation.AnimationId == "rbxassetid://999" and av.tracks.Idle.Animation.AnimationId == SET.ids.Idle,
	"una variante puede sustituir animaciones sueltas y reutilizar el resto")
PetAssets.Species.lumi.variants.rare = nil
-- Modelo sin Sleep/Happy (plantilla con carpeta parcial): las funciones preparadas no rompen nada
local partial = PetAnimator.Attach(PetModels.Build("lumi", "common"))
SET.ids = {}
local partialOnly = PetAnimator.Attach(PetModels.Build("lumi", "common"))
check(partialOnly:Sleep() == false and partialOnly:Celebrate() == nil and partialOnly:SetMoveSpeed(0) == "Idle",
	"sin Sleep/Happy: Sleep() = false, Celebrate() = nil y sigue en Idle")
check(partial ~= nil, "plantilla con carpeta Animations y conjunto a la vez")
SET.ids = PUBLISHED
noAnim.Parent = nil

-- 4) Plantillas invalidas -> respaldo con aviso ------------------------------------
template.Parent = nil
local bad = Instance.new("Model")
bad.Name = "Lumi"
bad.Parent = folder
local nw = #warnings
check(PetModels.Build("lumi", "common"):GetAttribute("Source") == "procedural" and #warnings > nw, "plantilla sin partes visibles: respaldo + aviso")
bad.Parent = nil
local big = makeTemplate("Lumi", false)
for i = 1, 45 do part("Part", "Extra" .. i, big, Vector3.new(1, 1, 1), Vector3.new(0, 1, 0)) end
check(PetModels.Build("lumi", "common"):GetAttribute("Source") == "procedural", "plantilla por encima del presupuesto de partes: respaldo")
big.Parent = nil
template.Parent = folder

-- 5) Cliente: PETs salvajes y compañeros con el modelo importado -------------------------
local remotes = RS.Remotes
for _, ev in ipairs(remotes:GetChildren()) do
	if ev.ClassName == "RemoteEvent" then ev.__onFireClient = function(p, ...) ev.OnClientEvent:Fire(...) end end
end
local S = {}
for _, mod in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[mod.Name] = require(mod) end
local Players = game:GetService("Players")
local P = MAKE_PLAYER(31, "Artista")
Players.__props.LocalPlayer = P
LOCAL_PLAYER = P
Players.PlayerAdded:Fire(P)
RUN_DELAYS()
RUN_SCRIPT(CLIENT_SCRIPT)
local RunService = game:GetService("RunService")
P:SetAttribute("Area", "z1")
S.Capture.OnAreaChanged(P, "z1")
local wild = workspace:FindFirstChild("MisPETsSalvajes")
local wildModels = wild and wild:GetChildren() or {}
check(#wildModels >= 7, "PETs salvajes dibujados: " .. #wildModels)
local allAsset = true
for _, w in ipairs(wildModels) do if w:GetAttribute("Source") ~= "asset" then allAsset = false end end
check(allAsset, "los Lumi salvajes usan el modelo importado")
for _ = 1, 30 do RunService.RenderStepped:Fire(1 / 30) end
check(true, "animacion de PETs salvajes por fotograma sin errores")
P:SetAttribute("Followers", "lumi:legendary,V:lumi:common")
for _ = 1, 10 do RunService.RenderStepped:Fire(1 / 30) end
local Followers = require(CLIENT_SCRIPT.Followers)
for _ = 1, 30 do RunService.RenderStepped:Fire(1 / 30) end -- el compañero llega a su sitio
check(Followers.PreviewAnimation("happy") == 2, "panel Dev: Happy en los 2 compañeros")
check(Followers.PreviewAnimation("sleep") == 2 and Followers.PreviewAnimation("wake") == 2, "panel Dev: Sleep y Wake")
P.Character.Humanoid.FloorMaterial = Enum.Material.Air
local hrp0 = P.Character.HumanoidRootPart
local moving = 0
for i = 1, 6 do
	hrp0.__props.CFrame = hrp0.CFrame + Vector3.new(0.6, 0, 0) -- el jugador avanza en el aire (18 studs/s)
	RunService.RenderStepped:Fire(1 / 30)
end
for _, c in ipairs(workspace:FindFirstChild("Compañeros"):GetChildren()) do
	local ac = c:FindFirstChildOfClass("AnimationController")
	for _, t in ipairs(ac and ac:FindFirstChildOfClass("Animator").__tracks or {}) do
		if t.IsPlaying and (t.Animation.Name == "Walk" or t.Animation.Name == "Run") then moving = moving + 1 end
	end
end
P.Character.Humanoid.FloorMaterial = Enum.Material.Grass
check(moving == 2, "compañero en el aire sin animacion Jump: sigue caminando/corriendo (" .. moving .. ")")
local comp = workspace:FindFirstChild("Compañeros")
local ca = 0
for _, c in ipairs(comp and comp:GetChildren() or {}) do if c:GetAttribute("Source") == "asset" then ca = ca + 1 end end
check(ca == 2, "compañeros con modelo importado: " .. ca)
-- captura: el PET reacciona mientras se succiona
local target = wildModels[1]
local hrp = P.Character.HumanoidRootPart
local tp = target:GetPivot()
hrp.__props.CFrame = CFrame.new(tp.X, 3, tp.Z)
local prompt = target.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
prompt.PromptButtonHoldBegan:Fire()
RUN_DELAYS()
for _ = 1, 3 do RunService.RenderStepped:Fire(1 / 30) end
local playingCapture = false
local ctrl = target:FindFirstChildOfClass("AnimationController")
local animator = ctrl and ctrl:FindFirstChildOfClass("Animator")
for _, t in ipairs(animator and animator.__tracks or {}) do
	if t.Animation.Name == "CaptureReaction" and t.IsPlaying then playingCapture = true end
end
check(playingCapture, "CaptureReaction suena durante la succion")
prompt.PromptButtonHoldEnded:Fire()
RUN_DELAYS()

-- 5b) Estructura real de assets/pets/Lumi.rbxm (comprobada con `rojo build`) ------------
-- Model "Lumi" (Rig = "Lumi_v7", PrimaryPart = Lumi_Comun_Body)
--   MeshPart Lumi_Comun_Body (1.18 x 1.67 x 1.58) > SurfaceAppearance, Bone Root > ... (34)
--   AnimationController > Animator;  Folder InitialPoses (108 CFrameValue del importador)
local fakeTemplate = folder:FindFirstChild("Lumi")
fakeTemplate.Parent = nil
local real = Instance.new("Model")
real.Name = "Lumi"
real:SetAttribute("Rig", "Lumi_v7")
real:SetAttribute("RBX_ReimportId", "importador")
local body = part("MeshPart", "Lumi_Comun_Body", real, Vector3.new(1.1831539, 1.6666665, 1.5838034), Vector3.new(0, 0.83, 0))
Instance.new("SurfaceAppearance").Parent = body
local HIER = { { "Root", nil }, { "Hips", "Root" }, { "Spine", "Hips" }, { "Chest", "Spine" }, { "Neck", "Chest" }, { "Head", "Neck" },
	{ "Jaw", "Head" }, { "Ear_01.L", "Head" }, { "Ear_02.L", "Ear_01.L" }, { "Ear_03.L", "Ear_02.L" }, { "Ear_01.R", "Head" },
	{ "Ear_02.R", "Ear_01.R" }, { "Ear_03.R", "Ear_02.R" }, { "Shoulder.L", "Chest" }, { "UpperArm.L", "Shoulder.L" },
	{ "Forearm.L", "UpperArm.L" }, { "FrontPaw.L", "Forearm.L" }, { "Shoulder.R", "Chest" }, { "UpperArm.R", "Shoulder.R" },
	{ "Forearm.R", "UpperArm.R" }, { "FrontPaw.R", "Forearm.R" }, { "Tail_01", "Hips" }, { "Tail_02", "Tail_01" },
	{ "Tail_03", "Tail_02" }, { "Tail_04", "Tail_03" }, { "Tail_05", "Tail_04" }, { "Thigh.L", "Hips" }, { "Shin.L", "Thigh.L" },
	{ "BackFoot.L", "Shin.L" }, { "BackPaw.L", "BackFoot.L" }, { "Thigh.R", "Hips" }, { "Shin.R", "Thigh.R" },
	{ "BackFoot.R", "Shin.R" }, { "BackPaw.R", "BackFoot.R" } }
local bonesByName = {}
for _, h in ipairs(HIER) do
	local b = Instance.new("Bone")
	b.Name = h[1]
	b.Parent = h[2] and bonesByName[h[2]] or body
	bonesByName[h[1]] = b
end
local poses = Instance.new("Folder")
poses.Name = "InitialPoses"
poses.Parent = real
for i = 1, 108 do local v = Instance.new("CFrameValue"); v.Name = "Pose" .. i; v.Parent = poses end
local realAC = Instance.new("AnimationController")
realAC.Parent = real
Instance.new("Animator").Parent = realAC
real.PrimaryPart = body
real.Parent = folder
local nwReal = #warnings
check(#HIER == 34 and PetAssets.Find("lumi", "common") == real, "estructura real de Lumi.rbxm: plantilla valida (1 parte, 34 huesos)")
local rm = PetModels.Build("lumi", "common", { label = "Lumi · Comun" })
check(rm:GetAttribute("Source") == "asset" and rm.PrimaryPart.Name == "Lumi_Comun_Body" and rm.PrimaryPart.Anchored,
	"PrimaryPart = Lumi_Comun_Body (MeshPart con huesos), anclada")
check(rm:GetAttribute("Rig") == "Lumi_v7" and near(rm:GetExtentsSize().Y, 2, 1e-3), "conserva Rig = Lumi_v7 y se escala a 2 studs")
local nBones = 0
for _, d in ipairs(rm:GetDescendants()) do if d.ClassName == "Bone" then nBones = nBones + 1 end end
check(nBones == 34 and rm.Lumi_Comun_Body:FindFirstChildOfClass("SurfaceAppearance") ~= nil, "clon con 34 huesos y SurfaceAppearance")
local ra = PetAnimator.Attach(rm)
local acs = 0
for _, c in ipairs(rm:GetChildren()) do if c.ClassName == "AnimationController" then acs = acs + 1 end end
check(ra ~= nil and acs == 1, "reutiliza el AnimationController del importador (no crea otro)")
local all7 = true
for _, s in ipairs(LUMI7) do all7 = all7 and ra:Has(s) and ra.tracks[s].Animation.AnimationId == EXPECTED[s] end
check(all7, "las 7 animaciones publicadas se cargan sobre el modelo real")
check(ra:SetMoveSpeed(0) == "Idle" and ra:Sleep() and ra:GetState() == "Sleep_Enter", "Idle y Sleep_Enter sobre el modelo real")
ra.tracks.Sleep_Enter:__finish()
check(ra:GetState() == "Sleep_Loop", "Sleep_Enter -> Sleep_Loop")
ra:Wake()
check(ra:GetState() == "Idle", "despertar -> Idle")
check(#warnings == nwReal, "sin avisos con la estructura real")
real.Parent = nil
fakeTemplate.Parent = folder

-- 6) Datos intactos ----------------------------------------------------------
local profile = S.DataService.Get(P)
local Schema = require(RS.Shared.ProfileSchema)
check(profile.version == Schema.Default().version, "perfil sin cambios de version")
local unexpected = {}
for _, w in ipairs(warnings) do
	if not (w:find("PetAssets") and (w:find("no tiene partes") or w:find("partes %(maximo") or w:find("trae scripts"))) then
		table.insert(unexpected, w)
	end
end
check(#unexpected == 0, "sin avisos inesperados (" .. #unexpected .. ")")
print("ALL PETASSETS TESTS PASSED")
