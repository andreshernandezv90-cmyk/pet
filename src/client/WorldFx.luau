-- WorldFx: iluminacion por zona, gravedad, poderes de navegacion de los PETs
-- (planeo, vision nocturna, derretir hielo, revelar plataformas, anomalias),
-- trampolines, nodos agotados por jugador, ondas de incursion y efectos.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local State = require(script.Parent.State)
local Net = require(script.Parent.Net)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local WorldFx = {}
local cc -- ColorCorrection
local atmosphere

local LOOKS = {
	home = { clock = 15.6, ambient = Color3.fromRGB(112, 106, 122), outdoor = Color3.fromRGB(142, 136, 150), bright = 2.4,
		tint = Color3.fromRGB(255, 250, 240), fog = 1400, fogColor = Color3.fromRGB(205, 220, 240) },
	mines = { clock = 17.5, ambient = Color3.fromRGB(90, 80, 75), outdoor = Color3.fromRGB(110, 95, 85), bright = 1.4,
		tint = Color3.fromRGB(255, 235, 215), fog = 500, fogColor = Color3.fromRGB(110, 90, 80) },
	realm = { clock = 16, ambient = Color3.fromRGB(120, 100, 150), outdoor = Color3.fromRGB(150, 120, 190), bright = 2,
		tint = Color3.fromRGB(240, 225, 255), fog = 800, fogColor = Color3.fromRGB(190, 160, 255) },
	z1 = { clock = 13, ambient = Color3.fromRGB(140, 140, 120), outdoor = Color3.fromRGB(160, 160, 140), bright = 2.4,
		tint = Color3.fromRGB(255, 250, 230), fog = 900, fogColor = Color3.fromRGB(230, 250, 210) },
	z2 = { clock = 15.5, ambient = Color3.fromRGB(130, 115, 95), outdoor = Color3.fromRGB(150, 130, 105), bright = 2,
		tint = Color3.fromRGB(255, 240, 210), fog = 700, fogColor = Color3.fromRGB(220, 200, 160) },
	z3 = { clock = 0.5, ambient = Color3.fromRGB(25, 22, 35), outdoor = Color3.fromRGB(30, 25, 45), bright = 0.4,
		tint = Color3.fromRGB(200, 190, 255), fog = 160, fogColor = Color3.fromRGB(20, 15, 30) },
	z4 = { clock = 11, ambient = Color3.fromRGB(120, 150, 135), outdoor = Color3.fromRGB(140, 170, 150), bright = 2.2,
		tint = Color3.fromRGB(235, 255, 245), fog = 800, fogColor = Color3.fromRGB(200, 255, 230) },
	z5 = { clock = 19, ambient = Color3.fromRGB(100, 80, 140), outdoor = Color3.fromRGB(120, 95, 170), bright = 1.5,
		tint = Color3.fromRGB(230, 210, 255), fog = 700, fogColor = Color3.fromRGB(120, 90, 180) },
	arena = { clock = 18, ambient = Color3.fromRGB(130, 80, 100), outdoor = Color3.fromRGB(160, 90, 120), bright = 1.8,
		tint = Color3.fromRGB(255, 220, 230), fog = 700, fogColor = Color3.fromRGB(200, 100, 140) },
}

local flags = {}

local function readFlags()
	flags = {}
	for f in string.gmatch(player:GetAttribute("Flags") or "", "[^,]+") do
		flags[f] = true
	end
end

local function applyLook()
	local area = player:GetAttribute("Area") or "home"
	local look = LOOKS[area] or LOOKS.home
	local ambient, outdoor, bright = look.ambient, look.outdoor, look.bright
	local tint = look.tint
	local fog = look.fog
	if area == "z3" and flags.nightVision then
		ambient = Color3.fromRGB(110, 140, 120)
		outdoor = Color3.fromRGB(120, 150, 130)
		tint = Color3.fromRGB(200, 255, 210)
		fog = 500
	end
	local info = TweenInfo.new(1.2)
	TweenService:Create(Lighting, info, { ClockTime = look.clock, Ambient = ambient, OutdoorAmbient = outdoor, Brightness = bright,
		FogEnd = fog, FogColor = look.fogColor }):Play()
	TweenService:Create(cc, info, { TintColor = tint }):Play()
	-- Gravedad (solo afecta la simulacion local del personaje)
	if area == "z5" then
		workspace.Gravity = flags.gravity and 80 or 110
	else
		workspace.Gravity = 196.2
	end
end

local function applyJump()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = 50 * (1 + (player:GetAttribute("Jump") or 0))
	end
end

local function applyPowers()
	for _, wall in ipairs(CollectionService:GetTagged("IceWall")) do
		wall.CanCollide = not flags.meltIce
		wall.Transparency = flags.meltIce and 0.85 or 0.2
	end
	for _, p in ipairs(CollectionService:GetTagged("HiddenPlatform")) do
		p.CanCollide = flags.reveal == true
		p.Transparency = flags.reveal and 0.25 or 0.92
	end
	for _, chest in ipairs(CollectionService:GetTagged("SecretChest")) do
		local hl = chest:FindFirstChild("Anomaly")
		if flags.anomaly and not hl then
			hl = Instance.new("Highlight")
			hl.Name = "Anomaly"
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.FillColor = Color3.fromRGB(255, 230, 120)
			hl.Parent = chest
		elseif not flags.anomaly and hl then
			hl:Destroy()
		end
	end
end

-- Nodos agotados (por jugador) ---------------------------------------------------------------

local nodes = {}
local function indexNodes()
	for _, m in ipairs(CollectionService:GetTagged("ResourceNode")) do
		local id = m:GetAttribute("NodeId")
		if id then
			nodes[id] = m
		end
	end
end

local function setNodeVisible(m, visible)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			if d:GetAttribute("OrigT") == nil then
				d:SetAttribute("OrigT", d.Transparency)
			end
			d.Transparency = visible and d:GetAttribute("OrigT") or 0.85
		elseif d:IsA("ProximityPrompt") then
			d.Enabled = visible
		end
	end
end

local function floatText(pos, text, color)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = pos
	p.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 260, 0, 40)
	bb.AlwaysOnTop = true
	bb.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color or Color3.fromRGB(255, 255, 200)
	t.TextStrokeTransparency = 0.2
	t.Text = text
	t.Parent = bb
	TweenService:Create(p, TweenInfo.new(1.4), { Position = pos + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(1.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(p, 1.5)
end

function WorldFx.Init()
	cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "PP_ZoneTint"
	cc.Parent = Lighting
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		local sky = Instance.new("Sky")
		sky.Parent = Lighting
	end

	readFlags()
	applyLook()
	applyPowers()
	player:GetAttributeChangedSignal("Area"):Connect(applyLook)
	player:GetAttributeChangedSignal("Flags"):Connect(function()
		readFlags()
		applyLook()
		applyPowers()
	end)
	player:GetAttributeChangedSignal("Jump"):Connect(applyJump)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid", 10)
		applyJump()
	end)
	if player.Character then
		applyJump()
	end

	indexNodes()
	CollectionService:GetInstanceAddedSignal("ResourceNode"):Connect(indexNodes)

	Net.On("NodeState", function(id, secs)
		local m = nodes[id]
		if not m then
			indexNodes()
			m = nodes[id]
		end
		if m then
			setNodeVisible(m, false)
			task.delay(secs or 20, function()
				setNodeVisible(m, true)
			end)
		end
	end)

	Net.On("Fx", function(kind, a, b)
		if kind == "loot" then
			local m = nodes[a]
			local pos = m and m.PrimaryPart and m.PrimaryPart.Position or (player.Character and player.Character:GetPivot().Position)
			if pos then
				floatText(pos + Vector3.new(0, 4, 0), b, Color3.fromRGB(180, 255, 160))
			end
		elseif kind == "nodeHit" then
			local m = nodes[a]
			if m and m.PrimaryPart then
				floatText(m.PrimaryPart.Position + Vector3.new(0, 3, 0), string.rep("▮", math.max(1, math.ceil((b or 0) * 5))),
					Color3.fromRGB(255, 220, 120))
			end
		elseif kind == "checkpoint" then
			UI.Toast("✅ Checkpoint guardado", "success")
		elseif kind == "respawn" then
			UI.Toast("¡Ups! Volviste al ultimo checkpoint. Sin penalizacion.", "info")
		elseif kind == "raidReward" then
			local data = a
			UI.Popup(data.success and ("🏆 Contribucion " .. data.tier) or "Incursion terminada", data.lines, Color3.fromRGB(255, 160, 220))
		end
	end)

	-- Trampolines (Zona 4)
	local lastPad = 0
	local function hookPad(pad)
		pad.Touched:Connect(function(hit)
			local char = player.Character
			if not char or not hit:IsDescendantOf(char) then
				return
			end
			local now = os.clock()
			if now - lastPad < 0.6 then
				return
			end
			lastPad = now
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local v = hrp.AssemblyLinearVelocity
				hrp.AssemblyLinearVelocity = Vector3.new(v.X, 95, v.Z)
			end
		end)
	end
	for _, pad in ipairs(CollectionService:GetTagged("JumpPad")) do
		hookPad(pad)
	end
	CollectionService:GetInstanceAddedSignal("JumpPad"):Connect(hookPad)
	-- con StreamingEnabled las partes pueden llegar despues: reaplicar poderes
	for _, tag in ipairs({ "IceWall", "HiddenPlatform", "SecretChest" }) do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function()
			task.defer(applyPowers)
		end)
	end

	-- Planeo de Venti + ondas de incursion
	local lastWave = {}
	RunService.Heartbeat:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then
			return
		end
		if flags.glide and hum:GetState() == Enum.HumanoidStateType.Freefall then
			local holding = UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump
			local v = hrp.AssemblyLinearVelocity
			if holding and v.Y < -12 then
				hrp.AssemblyLinearVelocity = Vector3.new(v.X, -12, v.Z)
			end
		end
		if player:GetAttribute("Area") == "arena" then
			local now = workspace:GetServerTimeNow()
			for _, ring in ipairs(CollectionService:GetTagged("RaidWave")) do
				local start = ring:GetAttribute("Start") or now
				local dur = ring:GetAttribute("Duration") or 3
				local maxR = ring:GetAttribute("MaxRadius") or 90
				local r = math.clamp((now - start) / dur, 0, 1) * maxR
				local c = ring.Position
				local d = Vector3.new(hrp.Position.X - c.X, 0, hrp.Position.Z - c.Z)
				local grounded = hum.FloorMaterial ~= Enum.Material.Air
				if grounded and math.abs(d.Magnitude - r) < 3 and not lastWave[ring] then
					lastWave[ring] = true
					local dir = d.Magnitude > 0.1 and d.Unit or Vector3.new(1, 0, 0)
					hrp.AssemblyLinearVelocity = dir * 70 + Vector3.new(0, 45, 0)
					UI.Toast("¡Te alcanzo una onda! Salta para esquivarlas.", "info")
				end
			end
		end
	end)
	CollectionService:GetInstanceRemovedSignal("RaidWave"):Connect(function(ring)
		lastWave[ring] = nil
	end)

	-- Trabajadores del santuario: animacion de saltitos
	local workers = {}
	local function addWorker(m)
		workers[m] = { base = m:GetPivot(), phase = math.random() * 6 }
	end
	for _, m in ipairs(CollectionService:GetTagged("WorkerPet")) do
		addWorker(m)
	end
	CollectionService:GetInstanceAddedSignal("WorkerPet"):Connect(function(m)
		task.defer(function()
			if m.Parent then
				addWorker(m)
			end
		end)
	end)
	CollectionService:GetInstanceRemovedSignal("WorkerPet"):Connect(function(m)
		workers[m] = nil
	end)
	RunService.RenderStepped:Connect(function(dt)
		for m, w in pairs(workers) do
			if m.Parent then
				w.phase = w.phase + dt * 5
				m:PivotTo(w.base * CFrame.new(0, math.abs(math.sin(w.phase)) * 0.8, 0) * CFrame.Angles(0, math.sin(w.phase * 0.5) * 0.4, 0))
			else
				workers[m] = nil
			end
		end
	end)

	-- Portales: el remolino interior gira lentamente (solo visual, local)
	local swirls = {}
	local function addSwirl(p)
		if p:IsA("BasePart") then
			swirls[p] = p.CFrame
		end
	end
	for _, p in ipairs(CollectionService:GetTagged("PortalSwirl")) do
		addSwirl(p)
	end
	CollectionService:GetInstanceAddedSignal("PortalSwirl"):Connect(addSwirl)
	CollectionService:GetInstanceRemovedSignal("PortalSwirl"):Connect(function(p)
		swirls[p] = nil
	end)
	local spinners = {}
	local function addSpinner(m)
		if m:IsA("Model") then
			spinners[m] = m:GetPivot()
		end
	end
	for _, m in ipairs(CollectionService:GetTagged("SpinY")) do
		addSpinner(m)
	end
	CollectionService:GetInstanceAddedSignal("SpinY"):Connect(addSpinner)
	CollectionService:GetInstanceRemovedSignal("SpinY"):Connect(function(m)
		spinners[m] = nil
	end)
	local spin = 0
	RunService.RenderStepped:Connect(function(dt)
		spin = spin + dt * 0.8
		for m, base in pairs(spinners) do
			if m.Parent then
				m:PivotTo(base * CFrame.Angles(0, spin * 0.35, 0))
			else
				spinners[m] = nil
			end
		end
		for p, base in pairs(swirls) do
			if p.Parent then
				p.CFrame = base * CFrame.Angles(0, 0, spin)
			else
				swirls[p] = nil
			end
		end
	end)

	State.Changed:Connect(function()
		applyPowers()
	end)
end

return WorldFx
