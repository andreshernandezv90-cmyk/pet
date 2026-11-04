-- Gifts (cliente): dibuja los regalos privados del jugador y permite abrirlos.
-- El servidor valida la distancia, la zona y decide la recompensa.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Net = require(script.Parent.Net)
local UI = require(script.Parent.UI)

local Gifts = {}
local folder
local models = {} -- [id] = { model, base, phase }

local COLORS = {
	Color3.fromRGB(255, 90, 120), Color3.fromRGB(90, 180, 255), Color3.fromRGB(255, 200, 70), Color3.fromRGB(150, 110, 255),
}

local function part(parent, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for k, v in pairs(props) do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function build(g)
	local m = Instance.new("Model")
	m.Name = "Regalo"
	local color = COLORS[(tonumber(string.match(g.id, "%d+")) or 1) % #COLORS + 1]
	local base = CFrame.new(g.x, g.y, g.z)
	local box = part(m, Vector3.new(2.4, 2, 2.4), base * CFrame.new(0, 1.2, 0), color, Enum.Material.SmoothPlastic)
	m.PrimaryPart = box
	local ribbon = Color3.fromRGB(255, 245, 210)
	part(m, Vector3.new(2.5, 2.05, 0.45), base * CFrame.new(0, 1.2, 0), ribbon, Enum.Material.SmoothPlastic)
	part(m, Vector3.new(0.45, 2.05, 2.5), base * CFrame.new(0, 1.2, 0), ribbon, Enum.Material.SmoothPlastic)
	part(m, Vector3.new(2.7, 0.45, 2.7), base * CFrame.new(0, 2.35, 0), color:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.SmoothPlastic)
	for _, sx in ipairs({ -1, 1 }) do
		part(m, Vector3.new(0.9, 0.7, 0.4), base * CFrame.new(sx * 0.45, 2.85, 0) * CFrame.Angles(0, 0, sx * 0.5), ribbon, Enum.Material.SmoothPlastic)
	end
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Range = 12
	glow.Brightness = 1.5
	glow.Parent = box
	local sp = Instance.new("Sparkles")
	sp.SparkleColor = Color3.fromRGB(255, 240, 180)
	sp.Parent = box
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 1
	hl.OutlineColor = Color3.fromRGB(255, 240, 160)
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = m
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Abrir regalo"
	prompt.ObjectText = "Regalo misterioso"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = box
	prompt.Triggered:Connect(function()
		Net.Send("claimGift", { id = g.id }, { silent = true }, function(r)
			if r.ok then
				UI.Popup("🎁 ¡Regalo!", { r.reward or "" }, Color3.fromRGB(255, 210, 120))
			elseif r.msg then
				UI.Toast(r.msg, "error")
			end
		end)
	end)
	m.Parent = folder
	return m
end

local function remove(id)
	local d = models[id]
	if not d then
		return
	end
	models[id] = nil
	local box = d.model.PrimaryPart
	if box then
		TweenService:Create(box, TweenInfo.new(0.3), { Transparency = 1 }):Play()
	end
	task.delay(0.35, function()
		d.model:Destroy()
	end)
end

function Gifts.Init()
	folder = Instance.new("Folder")
	folder.Name = "MisRegalos"
	folder.Parent = workspace
	Net.On("Gifts", function(list)
		local keep = {}
		for _, g in ipairs(list or {}) do
			keep[g.id] = true
			if not models[g.id] then
				local m = build(g)
				models[g.id] = { model = m, base = m:GetPivot(), phase = math.random() * 6 }
			end
		end
		for id in pairs(models) do
			if not keep[id] then
				remove(id)
			end
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		for _, d in pairs(models) do
			d.phase = d.phase + dt * 2
			d.model:PivotTo(d.base * CFrame.new(0, math.abs(math.sin(d.phase)) * 0.6, 0) * CFrame.Angles(0, d.phase * 0.4, 0))
		end
	end)
end

return Gifts
