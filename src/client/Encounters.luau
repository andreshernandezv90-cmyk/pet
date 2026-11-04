-- Encounters: dibuja localmente los PETs salvajes del jugador y gestiona la
-- captura con el Succionador (ProximityPrompt con tiempo de succion).
-- El servidor decide la especie, rareza y resultado; aqui solo se representa.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local PetModels = require(Shared.PetModels)
local Stats = require(Shared.Stats)

local State = require(script.Parent.State)
local Net = require(script.Parent.Net)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer

local Encounters = {}
local folder
local pets = {} -- [id] = { model, data, home, target, nextMove, prompt, phase }
local capturing = nil
local beam, a0, a1

local function params(s, r)
	local agg = State.Agg()
	if not agg then
		return { time = 2, chance = 0.5, range = 14 }
	end
	return Stats.CaptureParams(agg, State.data, s, r)
end

local function updatePrompt(p)
	local pr = params(p.data.s, p.data.r)
	p.prompt.HoldDuration = pr.time
	p.prompt.MaxActivationDistance = pr.range
	p.prompt.ActionText = string.format("Succionar (%d%%)", math.floor(pr.chance * 100 + 0.5))
end

local function stopBeam()
	if beam then
		beam.Enabled = false
	end
end

local function startBeam(model)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not model.PrimaryPart then
		return
	end
	if not beam then
		a0 = Instance.new("Attachment")
		a0.Name = "VacuumA0"
		beam = Instance.new("Beam")
		beam.Width0 = 1.2
		beam.Width1 = 0.4
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255), Color3.fromRGB(200, 120, 255))
		beam.Transparency = NumberSequence.new(0.2)
		beam.TextureSpeed = 3
		beam.Segments = 12
		beam.CurveSize0 = 2
		beam.CurveSize1 = -2
	end
	a0.Parent = hrp
	a0.Position = Vector3.new(1, 0.5, -1)
	a1 = model.PrimaryPart:FindFirstChild("VacuumA1") or Instance.new("Attachment")
	a1.Name = "VacuumA1"
	a1.Parent = model.PrimaryPart
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Parent = hrp
	beam.Enabled = true
end

local function remove(id)
	local p = pets[id]
	if not p then
		return
	end
	pets[id] = nil
	if capturing == id then
		capturing = nil
		stopBeam()
	end
	local m = p.model
	local body = m.PrimaryPart
	if body then
		local t = TweenService:Create(body, TweenInfo.new(0.35), { Transparency = 1 })
		t:Play()
	end
	task.delay(0.4, function()
		m:Destroy()
	end)
end

local function spawnPet(e)
	local sp = PetCatalog.Get(e.s)
	local rar = PetCatalog.Rarity(e.r)
	if not sp or not rar then
		return
	end
	local model = PetModels.Build(e.s, e.r, { label = sp.name .. " · " .. rar.name })
	local radius = model:GetAttribute("Radius") or 1
	local home = Vector3.new(e.x, radius + 0.2, e.z)
	model:PivotTo(CFrame.new(home))
	model.Parent = folder
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = sp.name .. " " .. rar.name
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.Parent = model.PrimaryPart
	local p = { model = model, data = e, home = home, pos = home, target = home, nextMove = os.clock() + math.random() * 3, prompt = prompt,
		phase = math.random() * 6, radius = radius }
	pets[e.id] = p
	updatePrompt(p)

	prompt.PromptButtonHoldBegan:Connect(function()
		capturing = e.id
		startBeam(model)
		Net.Send("captureBegin", { id = e.id }, { silent = true }, function(r)
			if not r.ok then
				UI.Toast(r.msg, "error")
				if capturing == e.id then
					capturing = nil
					stopBeam()
				end
				-- cancelar la retencion
				prompt.Enabled = false
				task.wait(0.2)
				if prompt.Parent then
					prompt.Enabled = true
				end
			end
		end)
	end)
	prompt.PromptButtonHoldEnded:Connect(function()
		task.delay(0.2, function()
			if capturing == e.id then
				capturing = nil
				stopBeam()
				Net.Send("captureCancel", {}, { silent = true })
			end
		end)
	end)
	prompt.Triggered:Connect(function()
		capturing = nil
		stopBeam()
		Net.Send("captureFinish", { id = e.id }, { silent = true }, function(r)
			if r.ok and r.captured then
				UI.Popup("¡Rescatado!", { (r.first and "¡Nueva especie! " or "") .. PetCatalog.Get(r.s).name .. " " .. PetCatalog.Rarity(r.r).name,
					"Se guardo en tu tanque de PETs." }, PetCatalog.Rarity(r.r).color)
				remove(e.id)
			elseif r.msg then
				UI.Toast(r.msg, r.ok and "info" or "error")
				if r.escaped then
					remove(e.id)
				end
			end
		end)
	end)
end

local function setInstinct(on)
	for _, p in pairs(pets) do
		local hl = p.model:FindFirstChild("Instinct")
		if on and not hl then
			hl = Instance.new("Highlight")
			hl.Name = "Instinct"
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.FillTransparency = 0.6
			hl.FillColor = Color3.fromRGB(255, 220, 120)
			hl.OutlineColor = Color3.fromRGB(255, 255, 255)
			hl.Parent = p.model
		elseif not on and hl then
			hl:Destroy()
		end
	end
end

function Encounters.Init()
	folder = Instance.new("Folder")
	folder.Name = "MisPETsSalvajes"
	folder.Parent = workspace

	Net.On("Encounters", function(zone, list)
		local keep = {}
		for _, e in ipairs(list or {}) do
			keep[e.id] = true
			if not pets[e.id] then
				spawnPet(e)
			end
		end
		for id in pairs(pets) do
			if not keep[id] then
				remove(id)
			end
		end
		local agg = State.Agg()
		setInstinct(agg and agg.flags.instinct)
	end)

	State.Changed:Connect(function()
		for _, p in pairs(pets) do
			updatePrompt(p)
		end
		local agg = State.Agg()
		setInstinct(agg and agg.flags.instinct)
	end)

	-- Deambular y animacion
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		for id, p in pairs(pets) do
			if p.model.Parent then
				if id ~= capturing then
					if now >= p.nextMove then
						local a = math.random() * math.pi * 2
						local r = math.random() * 8
						p.target = p.home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
						p.nextMove = now + 2 + math.random() * 4
					end
					local delta = p.target - p.pos
					local step = math.min(delta.Magnitude, dt * 4)
					if step > 0.01 then
						p.pos = p.pos + delta.Unit * step
					end
				end
				p.phase = p.phase + dt * (id == capturing and 20 or 5)
				local hop = math.abs(math.sin(p.phase)) * (id == capturing and 0.4 or 0.8)
				local look = (p.target - p.pos)
				local cf
				if look.Magnitude > 0.1 then
					cf = CFrame.lookAt(p.pos, p.pos + Vector3.new(look.X, 0, look.Z))
				else
					cf = CFrame.new(p.pos) * (p.model:GetPivot() - p.model:GetPivot().Position)
				end
				if id == capturing then
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp then
						cf = CFrame.lookAt(p.pos, Vector3.new(hrp.Position.X, p.pos.Y, hrp.Position.Z)) *
							CFrame.new(math.sin(now * 40) * 0.15, 0, 0)
					end
				end
				p.model:PivotTo(cf + Vector3.new(0, hop, 0))
			end
		end
	end)
end

return Encounters
