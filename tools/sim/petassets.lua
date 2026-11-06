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
