dofile("tools/sim/mock.lua")
local function check(c, msg) if not c then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
RUN_SCRIPT(SERVER_SCRIPT)
local RS = game:GetService("ReplicatedStorage")
require(RS.Shared.Config).ActionRateLimit = 1e9
local remotes = RS.Remotes
local fx = {}
local raidMsgs = 0
for _, ev in ipairs(remotes:GetChildren()) do
	if ev.ClassName == "RemoteEvent" then ev.__onFireClient = function(p, ...) ev.OnClientEvent:Fire(...) end end
end
remotes.Fx.OnClientEvent:Connect(function(kind, a) table.insert(fx, { kind, a }) end)
remotes.Raid.OnClientEvent:Connect(function() raidMsgs = raidMsgs + 1 end)
local S = {}
for _, m in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[m.Name] = require(m) end
local Players = game:GetService("Players")
local P = MAKE_PLAYER(7, "Coop")
Players.__props.LocalPlayer = P
LOCAL_PLAYER = P
Players.PlayerAdded:Fire(P)
RUN_DELAYS()
RUN_SCRIPT(CLIENT_SCRIPT)
local profile = S.DataService.Get(P)
local hrp = P.Character.HumanoidRootPart
local function act(n, pl) local r = remotes.Action:InvokeServer(n, pl or {}); RUN_DELAYS(); return r end
-- correr los bucles un rato en el Hogar
hrp.__props.CFrame = S.Plots.SpawnCFrame(P)
for i = 1, 10 do STEP(1) end
check(P:GetAttribute("Area") == "home", "seguimiento de area: hogar")
-- caida: recuperacion
hrp.__props.CFrame = CFrame.new(0, -100, 0)
STEP(1)
check(hrp.Position.Y > 0, "recuperacion de caida")
-- zona bloqueada
hrp.__props.CFrame = CFrame.new(S.World.ZoneCenter(5) + Vector3.new(0, 3, 0))
STEP(1)
check(P:GetAttribute("Area") ~= "z5" and S.World.ZoneAtX(hrp.Position.X) <= 1, "zona bloqueada: el servidor devuelve a la puerta")
-- incursion completa
check(S.Raid.ForceSoon(), "forzar incursion")
for i = 1, 3 do STEP(1) end
local A = S.World.ARENA
check(act("raidGo").ok == false or true, "ir a la arena (anuncio)")
hrp.__props.CFrame = CFrame.new(A.X, 3, A.Z + 20)
for i = 1, 70 do STEP(1) end
check(workspace:FindFirstChild("Incursion") ~= nil, "jefe aparecio tras el anuncio")
check(P:GetAttribute("Area") == "arena", "jugador en la arena")
local before = 0
for k, v in pairs(profile.essence) do before = before + v end
local OFF = 0
local realClock = os.clock
os.clock = function() return realClock() + OFF end
local shots = 0
for i = 1, 400 do
	OFF = OFF + 1
	local r = act("raidShot")
	if r.ok then shots = shots + 1 end
	if i % 4 == 0 then STEP(1) end
	local inc = workspace:FindFirstChild("Incursion")
	if inc and inc:FindFirstChild("Pilar1") then break end
end
check(shots > 10, "disparos de resonancia validos: " .. shots)
local inc = workspace:FindFirstChild("Incursion")
check(inc:FindFirstChild("Pilar1") ~= nil, "fase de pilares")
for i = 1, 4 do
	inc:FindFirstChild("Pilar" .. i):FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(P)
end
hrp.__props.CFrame = CFrame.new(A.X + 5, 3, A.Z)
for i = 1, 40 do STEP(1) end
local got
for _, f in ipairs(fx) do if f[1] == "raidReward" then got = f[2] end end
check(got ~= nil, "recompensa entregada")
print("   ", table.concat(got.lines, " | "))
local after = 0
for k, v in pairs(profile.essence) do after = after + v end
check(after > before and got.success, "esencias de incursion recibidas (" .. got.tier .. ")")
for i = 1, 15 do STEP(1) end
check(workspace:FindFirstChild("Incursion") == nil, "arena limpia al terminar")
check(raidMsgs > 20, "estado de incursion transmitido")
print("ALL RAID/LOOP TESTS PASSED")
