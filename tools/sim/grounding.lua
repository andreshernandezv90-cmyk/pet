-- Pruebas de apoyo vertical de PETs importados (Lumi) sobre el terreno.
-- Ejecutar: lua5.4 tools/sim/grounding.lua
-- El terreno es simulado (SIM_GROUND) y la plantilla reproduce la estructura de
-- assets/pets/Lumi.rbxm. Nada de esto sustituye la comprobacion visual en Studio.
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
local PetGrounding = require(RS.Shared.PetGrounding)
local PetCatalog = require(RS.Shared.PetCatalog)
local UPV = Vector3.new(0, 1, 0)

-- Plantilla con la estructura real de Lumi.rbxm (malla 1.18 x 1.67 x 1.58, base = suelas)
local folder = Instance.new("Folder")
folder.Name = "PetAssets"
folder.Parent = RS
local function makeLumi(name, size)
	local real = Instance.new("Model")
	real.Name = name or "Lumi"
	real:SetAttribute("Rig", "Lumi_v7")
	local body = Instance.new("MeshPart")
	body.Name = "Lumi_Body"
	body.Size = size or Vector3.new(1.1831539, 1.6666665, 1.5838034)
	body.CFrame = CFrame.new(0, body.Size.Y / 2, 0)
	body.Anchored = true
	body.Parent = real
	local prev = body
	for _, n in ipairs({ "Root", "Hips", "Spine", "Chest" }) do
		local b = Instance.new("Bone"); b.Name = n; b.Parent = prev; prev = b
	end
	local ac = Instance.new("AnimationController")
	ac.Parent = real
	Instance.new("Animator").Parent = ac
	real.PrimaryPart = body
	real.Parent = folder
	return real
end
makeLumi()
-- Variantes por rareza (malla de 1.646 de alto en reposo, como los FBX de Raro/Epico/Legendario)
for _, r in ipairs({ "rare", "epic", "legendary" }) do makeLumi("Lumi_" .. r, Vector3.new(1.18, 1.6462, 1.58)) end

-- Pies = pivote - arriba_del_modelo * GroundOffset
local function feet(m)
	local pv = m:GetPivot()
	return pv.Position - pv:VectorToWorldSpace(UPV) * m:GetAttribute("GroundOffset")
end
local function tiltDeg(m)
	local up = m:GetPivot():VectorToWorldSpace(UPV)
	return math.deg(math.acos(math.clamp(up:Dot(UPV), -1, 1)))
end

-- 1) Referencia de reposo -----------------------------------------------------------
for _, rar in ipairs(PetCatalog.Rarities) do
	local m = PetModels.Build("lumi", rar.id)
	local h = 2 * rar.size
	local bb, size = m:GetBoundingBox()
	check(m:GetAttribute("Source") == "asset" and near(size.Y, h, 1e-3)
		and near(m:GetAttribute("GroundOffset"), m:GetPivot().Y - (bb.Y - size.Y / 2), 1e-6)
		and near(m:GetAttribute("GroundOffset"), h / 2, 1e-3),
		"GroundOffset de " .. rar.id .. " = pivote -> base de la malla en reposo (" .. string.format("%.3f", m:GetAttribute("GroundOffset")) .. ")")
end
PetAssets.Species.lumi.footInset = 0.05
check(near(PetModels.Build("lumi", "common"):GetAttribute("GroundOffset"), 1 - 0.1, 1e-3), "footInset ajusta el apoyo (especie)")
PetAssets.Species.lumi.footInset = 0
PetAssets.Species.lumi.variants.epic = { footInset = 0.1 }
check(near(PetModels.Build("lumi", "epic"):GetAttribute("GroundOffset"), 1.2 - 0.24, 1e-3)
	and near(PetModels.Build("lumi", "rare"):GetAttribute("GroundOffset"), 1.1, 1e-3), "footInset por rareza solo afecta a esa rareza")
PetAssets.Species.lumi.variants.epic = nil
local proc = PetModels.Build(PetCatalog.Species[2].id, "common")
check(PetGrounding.Offset(proc) == nil and proc:GetAttribute("GroundOffset") == nil, "los PETs procedurales no usan el apoyo nuevo")

-- 2) Colocacion: suelas en el punto de apoyo, inclinacion limitada ----------------------
local m = PetModels.Build("lumi", "common")
local cf = PetGrounding.PivotCFrame(Vector3.new(5, 3, -2), UPV, Vector3.new(1, 0, 0), 1)
m:PivotTo(cf)
check(near(feet(m).Y, 3, 1e-6) and near(feet(m).X, 5, 1e-6) and near(tiltDeg(m), 0, 1e-6), "llano: suelas exactamente en el suelo, sin inclinar")
check(near(m:GetPivot().LookVector.X, 1, 1e-6), "mira hacia donde se le indica")
local n15 = Vector3.new(math.sin(math.rad(15)), math.cos(math.rad(15)), 0)
m:PivotTo(PetGrounding.PivotCFrame(Vector3.new(0, 2, 0), n15, Vector3.new(0, 0, -1), 1))
check(near(tiltDeg(m), 15, 1e-3) and near((feet(m) - Vector3.new(0, 2, 0)).Magnitude, 0, 1e-6), "pendiente de 15°: se inclina 15° con las suelas en el punto de apoyo")
local n40 = Vector3.new(math.sin(math.rad(40)), math.cos(math.rad(40)), 0)
m:PivotTo(PetGrounding.PivotCFrame(Vector3.new(0, 2, 0), n40, Vector3.new(0, 0, -1), 1))
check(near(tiltDeg(m), 20, 1e-3), "pendiente de 40°: inclinacion limitada a 20°")

-- 3) Seguidor de suelo: sin teletransporte, sin vibracion, raycasts limitados ------------
SIM_GROUND = function() return 0 end
local tr = PetGrounding.Tracker()
local y = tr:Step(0, 0, 0, 0)
check(near(y, 0), "primera muestra: directamente en el suelo (sin caer desde arriba)")
SIM_GROUND = function() return 1 end
local saved = PetGrounding.Config.reprobeTime
PetGrounding.Config.reprobeTime = 0
local ys, maxStep, mono = {}, 0, true
local last = 0
for i = 1, 60 do
	local yy = tr:Step(0, 0, 0, 1 / 60)
	maxStep = math.max(maxStep, math.abs(yy - last))
	if yy < last - 1e-9 or yy > 1 + 1e-9 then mono = false end
	last = yy
	ys[i] = yy
end
check(ys[1] > 0 and ys[1] < 0.3 and maxStep < 0.25, "escalon de 1 stud: sube suave (max " .. string.format("%.3f", maxStep) .. " por fotograma a 60 fps)")
check(mono and near(ys[60], 1, 1e-3), "sin rebotes ni vibracion; en 1 s queda en el suelo nuevo")
PetGrounding.Config.reprobeTime = saved
local tr2 = PetGrounding.Tracker()
local r0 = SIM_RAYS
for _ = 1, 30 do tr2:Step(10, 10, 0, 1 / 60) end
check(SIM_RAYS - r0 <= 2, "quieto: no lanza un raycast por fotograma (" .. (SIM_RAYS - r0) .. ")")
SIM_GROUND = function() return nil end
local tr3 = PetGrounding.Tracker()
check(near(tr3:Step(0, 0, 4, 0), 4), "sin suelo (vacio): usa la altura de referencia")
check(PetGrounding.Snap(m, 0, 0, 0, Vector3.new(0, 0, -1)) == nil, "Snap sin suelo: no mueve al PET")
SIM_GROUND = function() return 0 end

-- 4) Cliente: PETs salvajes ---------------------------------------------------------------
for _, ev in ipairs(RS.Remotes:GetChildren()) do
	if ev.ClassName == "RemoteEvent" then ev.__onFireClient = function(p, ...) ev.OnClientEvent:Fire(...) end end
end
local S = {}
for _, mod in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[mod.Name] = require(mod) end
local Players = game:GetService("Players")
local P = MAKE_PLAYER(41, "Explorador")
Players.__props.LocalPlayer = P
LOCAL_PLAYER = P
Players.PlayerAdded:Fire(P)
RUN_DELAYS()
RUN_SCRIPT(CLIENT_SCRIPT)
local RunService = game:GetService("RunService")
PetGrounding.Config.reprobeTime = 0 -- el simulador corre mas rapido que el reloj real
P:SetAttribute("Area", "z1")
S.Capture.OnAreaChanged(P, "z1")
local wild = workspace:FindFirstChild("MisPETsSalvajes"):GetChildren()
local lumis, procs = {}, {}
for _, w in ipairs(wild) do
	if w:GetAttribute("Source") == "asset" then table.insert(lumis, w) else table.insert(procs, w) end
end
check(#lumis >= 3, "Lumi salvajes importados: " .. #lumis)
local okFeet, worst = true, 0
for _ = 1, 10 do RunService.RenderStepped:Fire(1 / 30) end
for _, w in ipairs(lumis) do
	worst = math.max(worst, math.abs(feet(w).Y))
	if math.abs(feet(w).Y) > 1e-3 then okFeet = false end
end
check(okFeet, "llano: los Lumi salvajes apoyan las suelas en y = 0 (antes flotaban 0.2); error max " .. string.format("%.4f", worst))
-- caminando: la altura no cambia en llano aunque cambie la animacion (Idle/Walk)
local anyWalk, steady = false, true
local t0 = os.clock()
local frames = 0
while (not anyWalk or frames < 90) and os.clock() - t0 < 8 do -- deambular depende del reloj real
	frames = frames + 1
	RunService.RenderStepped:Fire(1 / 30)
	for _, w in ipairs(lumis) do
		if math.abs(feet(w).Y) > 1e-3 then steady = false end
		local ac = w:FindFirstChildOfClass("AnimationController")
		for _, t in ipairs(ac and ac:FindFirstChildOfClass("Animator").__tracks or {}) do
			if t.IsPlaying and t.Animation.Name == "Walk" then anyWalk = true end
		end
	end
end
check(anyWalk and steady, "deambulando (Walk): siguen apoyados, sin saltos de altura")
-- colina: domo de 5 studs bajo el primer Lumi
local L1 = lumis[1]
local c = L1:GetPivot().Position
SIM_GROUND = function(x, z)
	local d = math.sqrt((x - c.X) ^ 2 + (z - c.Z) ^ 2)
	return d < 30 and 5 * (1 - (d / 30) ^ 2) or 0
end
for _ = 1, 60 do RunService.RenderStepped:Fire(1 / 30) end
local f1 = feet(L1)
check(math.abs(f1.Y - SIM_GROUND(f1.X, f1.Z)) < 0.05, string.format("colina: apoyado en el terreno (suelas %.3f, suelo %.3f; antes quedaba hundido)", f1.Y, SIM_GROUND(f1.X, f1.Z)))
-- ladera: el centro de la colina 12 studs al lado -> pendiente de ~7.6°
SIM_GROUND = function(x, z)
	local d = math.sqrt((x - (c.X + 12)) ^ 2 + (z - c.Z) ^ 2)
	return d < 30 and 5 * (1 - (d / 30) ^ 2) or 0
end
for _ = 1, 60 do RunService.RenderStepped:Fire(1 / 30) end
local f2 = feet(L1)
local d2 = math.sqrt((f2.X - (c.X + 12)) ^ 2 + (f2.Z - c.Z) ^ 2)
local slope = math.deg(math.atan(10 * d2 / 900))
check(math.abs(f2.Y - SIM_GROUND(f2.X, f2.Z)) < 0.05 and math.abs(tiltDeg(L1) - slope) < 0.5,
	string.format("ladera: suelas en el terreno y cuerpo inclinado %.1f° (pendiente %.1f°)", tiltDeg(L1), slope))
-- captura: el Lumi succionado sigue apoyado
SIM_GROUND = function() return 0 end
for _ = 1, 30 do RunService.RenderStepped:Fire(1 / 30) end
local hrp = P.Character.HumanoidRootPart
local tp = L1:GetPivot()
hrp.__props.CFrame = CFrame.new(tp.X + 3, 3, tp.Z)
local prompt = L1.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
prompt.PromptButtonHoldBegan:Fire()
RUN_DELAYS()
for _ = 1, 10 do RunService.RenderStepped:Fire(1 / 30) end
check(math.abs(feet(L1).Y) < 0.01, "durante la captura sigue apoyado (solo tiembla en horizontal)")
prompt.PromptButtonHoldEnded:Fire()
RUN_DELAYS()
-- PETs procedurales: exactamente su colocacion de siempre (radio + 0.2 + rebote), aunque haya colina
local other = PetCatalog.Species[2].id
SIM_GROUND = function() return 6 end
RS.Remotes.Encounters.OnClientEvent:Fire(1, { { id = 9001, s = other, r = "common", x = 5, z = 5 }, { id = 9002, s = other, r = "epic", x = -5, z = 5 } })
RUN_DELAYS()
for _ = 1, 30 do RunService.RenderStepped:Fire(1 / 30) end
local procOk, nProc = true, 0
for _, w in ipairs(workspace:FindFirstChild("MisPETsSalvajes"):GetChildren()) do
	if w:GetAttribute("Source") == "procedural" then
		nProc = nProc + 1
		local r = w:GetAttribute("Radius")
		local yy = w:GetPivot().Y
		if yy < r + 0.2 - 1e-6 or yy > r + 0.2 + 0.8 + 1e-6 then procOk = false end
	end
end
check(procOk and nProc == 2, "PETs procedurales sin cambios: y = radio + 0.2 + rebote, ignoran el terreno como antes (" .. nProc .. ")")
SIM_GROUND = function() return 0 end

-- 5) Compañeros ------------------------------------------------------------------------
hrp.__props.CFrame = CFrame.new(40, 3, 40) -- pies del jugador en y = 0 (HipHeight 2 + mitad de 2)
P:SetAttribute("Followers", "lumi:common")
for _ = 1, 40 do RunService.RenderStepped:Fire(1 / 30) end
local comp
for _, x in ipairs(workspace:FindFirstChild("Compañeros"):GetChildren()) do if x:GetAttribute("Source") == "asset" then comp = x end end
check(comp ~= nil and math.abs(feet(comp).Y) < 1e-3, string.format("compañero quieto: suelas en el suelo (%.4f; antes flotaba 0.65)", feet(comp).Y))
local hum = P.Character.Humanoid
-- corriendo: el jugador avanza 18 studs/s
local runOk, ranRun = true, false
for _ = 1, 30 do
	hrp.__props.CFrame = hrp.CFrame + Vector3.new(0.6, 0, 0)
	RunService.RenderStepped:Fire(1 / 30)
	if math.abs(feet(comp).Y) > 1e-3 then runOk = false end
	for _, t in ipairs(comp:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator").__tracks) do
		if t.IsPlaying and t.Animation.Name == "Run" then ranRun = true end
	end
end
check(ranRun and runOk, "compañero corriendo (Run): mantiene el apoyo; el rebote lo pone la animacion")
-- el jugador salta: el compañero no sube con el
hum.FloorMaterial = Enum.Material.Air
local jumpOk = true
for i = 1, 12 do
	hrp.__props.CFrame = hrp.CFrame + Vector3.new(0, i <= 6 and 0.8 or -0.8, 0)
	RunService.RenderStepped:Fire(1 / 30)
	if math.abs(feet(comp).Y) > 1e-3 then jumpOk = false end
end
hum.FloorMaterial = Enum.Material.Grass
check(jumpOk, "el jugador salta: el compañero sigue en el suelo")
-- Happy y Sleep no mueven el pivote (el cuerpo lo mueve el rig)
local Followers = require(CLIENT_SCRIPT.Followers)
for _ = 1, 20 do RunService.RenderStepped:Fire(1 / 30) end
local y0 = comp:GetPivot().Y
check(Followers.PreviewAnimation("happy") == 1, "Happy en el compañero")
for _ = 1, 5 do RunService.RenderStepped:Fire(1 / 30) end
local y1 = comp:GetPivot().Y
check(Followers.PreviewAnimation("sleep") == 1, "Sleep en el compañero")
for _ = 1, 5 do RunService.RenderStepped:Fire(1 / 30) end
local y2 = comp:GetPivot().Y
check(near(y0, y1, 1e-6) and near(y0, y2, 1e-6), "Happy y Sleep no cambian la altura del pivote: el rig conserva su salto y su postura tumbada")
Followers.PreviewAnimation("wake")
-- escalon bajo el compañero (el jugador sigue en y = 0): el compañero sube al escalon sin saltar
local cp = comp:GetPivot().Position
SIM_GROUND = function(x, z) return (math.abs(x - cp.X) < 6 and math.abs(z - cp.Z) < 6) and 1.5 or 0 end
local prevY, bigJump = feet(comp).Y, 0
for _ = 1, 30 do
	RunService.RenderStepped:Fire(1 / 30)
	local fy = feet(comp).Y
	bigJump = math.max(bigJump, math.abs(fy - prevY))
	prevY = fy
end
check(math.abs(feet(comp).Y - 1.5) < 0.02 and bigJump < 0.6, string.format("escalon de 1.5 bajo el compañero: sube suave (max %.2f por fotograma a 30 fps)", bigJump))
SIM_GROUND = function() return 0 end
P:SetAttribute("Followers", "")

-- 6) Trabajadores (servidor) -------------------------------------------------------------
local function act(n, pl) local r = RS.Remotes.Action:InvokeServer(n, pl or {}); RUN_DELAYS(); return r end
local profile = S.DataService.Get(P)
act("dev", { cmd = "resources" })
act("craft", { line = "sanctuary" })
act("craft", { line = "station_stone" })
profile.stacks.storage["lumi:common"] = 2
check(act("assign", { station = "stone", ref = { key = "lumi:common" } }).ok, "asignar Lumi al extractor")
local plotModel = workspace.Plots:FindFirstChild("Plot_" .. P:GetAttribute("Plot"))
local worker
for _, d in ipairs(plotModel:GetDescendants()) do
	if d.ClassName == "Model" and d:GetAttribute("Source") == "asset" and d:GetAttribute("Species") == "lumi" then worker = d end
end
check(worker ~= nil, "trabajador Lumi con modelo importado")
local wf = feet(worker)
check(math.abs(wf.Y - SIM_GROUND(wf.X, wf.Z)) < 1e-3, string.format("trabajador apoyado en el suelo de su estacion (suelas %.3f; antes flotaba ~0.9)", wf.Y))
local wa = worker:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator")
local working = false
for _, t in ipairs(wa.__tracks) do if t.IsPlaying and t.Animation.Name == "Work" then working = true end end
check(working, "el trabajador reproduce Work")

-- 7) Datos y avisos ----------------------------------------------------------------------
local Schema = require(RS.Shared.ProfileSchema)
check(profile.version == Schema.Default().version, "perfil sin cambios de version")
check(#warnings == 0, "sin avisos (" .. #warnings .. ")")
print("ALL GROUNDING TESTS PASSED")
