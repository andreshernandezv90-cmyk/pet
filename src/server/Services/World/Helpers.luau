-- World/Helpers: utilidades de construccion compartidas por los modulos del mundo.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Items)
local Progression = require(Shared.Progression)

local Helpers = {}
local World -- registro del mundo (World/init), asignado en Helpers.Init
local nodeCounter = 0

function Helpers.Init(world)
	World = world
end

-- Helpers -------------------------------------------------------------------------------

local function part(props, parent)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "ClassName" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end
Helpers.Part = part

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Plataforma cuya cara superior queda a la altura topY
local function slab(parent, center, sx, sz, topY, color, material, name)
	return part({
		Name = name or "Ground",
		Size = Vector3.new(sx, 4, sz),
		Position = Vector3.new(center.X, topY - 2, center.Z),
		Color = color,
		Material = material or Enum.Material.Grass,
	}, parent)
end
Helpers.Slab = slab

local function billboard(adornee, text, color, size, offsetY, maxDist)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = UDim2.new(0, size or 220, 0, 60)
	bb.StudsOffset = Vector3.new(0, offsetY or 4, 0)
	bb.MaxDistance = maxDist or 120
	bb.LightInfluence = 0
	bb.Adornee = adornee
	bb.Parent = adornee
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	t.Text = text
	t.Parent = bb
	return bb, t
end
Helpers.Billboard = billboard

local function signPost(parent, pos, text, color)
	local post = part({ Name = "Sign", Size = Vector3.new(1, 6, 1), Position = pos + Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(110, 80, 50), Material = Enum.Material.Wood, CanCollide = false }, parent)
	local board = part({ Name = "Board", Size = Vector3.new(8, 3, 0.5), Position = pos + Vector3.new(0, 6.5, 0),
		Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood, CanCollide = false }, parent)
	billboard(board, text, color or Color3.fromRGB(255, 245, 200), 260, 3, 90)
	return post
end
Helpers.SignPost = signPost

local function addPrompt(parentPart, action, object, hold, dist)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object or ""
	pp.HoldDuration = hold or 0
	pp.MaxActivationDistance = dist or 10
	pp.RequiresLineOfSight = false
	pp.Parent = parentPart
	return pp
end
Helpers.AddPrompt = addPrompt

-- Portal: disco de neon + plataforma con ProximityPrompt
local function portal(parent, pos, facingYaw, text, color, dest)
	local m = Instance.new("Model")
	m.Name = "Portal_" .. dest
	m.Parent = parent
	local cf = CFrame.new(pos) * CFrame.Angles(0, facingYaw or 0, 0)
	part({ Name = "Base", Size = Vector3.new(14, 1, 6), CFrame = cf * CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(70, 70, 90), Material = Enum.Material.Slate }, m)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "Pillar", Size = Vector3.new(1.6, 14, 1.6), CFrame = cf * CFrame.new(sx * 6.5, 7, 0),
			Color = Color3.fromRGB(90, 90, 120), Material = Enum.Material.Marble }, m)
	end
	part({ Name = "Top", Size = Vector3.new(15, 1.6, 2), CFrame = cf * CFrame.new(0, 14.5, 0),
		Color = Color3.fromRGB(90, 90, 120), Material = Enum.Material.Marble }, m)
	local disc = part({ Name = "Gate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 12, 11),
		CFrame = cf * CFrame.new(0, 7.5, 0) * CFrame.Angles(0, math.rad(90), 0),
		Color = color, Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false }, m)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 2
	light.Parent = disc
	billboard(disc, text, color, 300, 9, 150)
	local pp = addPrompt(disc, "Viajar", text, 0, 12)
	pp:SetAttribute("Dest", dest)
	table.insert(World.Portals, { prompt = pp, dest = dest })
	return m
end
Helpers.Portal = portal

-- Nodos de recoleccion ------------------------------------------------------------------

local function makeNode(parent, nodeType, pos, area, rng)
	local def = Items.Nodes[nodeType]
	nodeCounter = nodeCounter + 1
	local id = "n" .. nodeCounter
	local m = Instance.new("Model")
	m.Name = def.name
	local main
	if nodeType == "tree" then
		local h = rng:NextNumber(9, 13)
		main = part({ Name = "Node", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 2.2, 2.2),
			CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(105, 75, 50), Material = Enum.Material.Wood }, m)
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 8, 9), Position = pos + Vector3.new(0, h + 2, 0),
			Color = def.color, Material = Enum.Material.Grass, CanCollide = false }, m)
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6), Position = pos + Vector3.new(2.5, h + 4, 1),
			Color = def.color:Lerp(Color3.new(1, 1, 1), 0.1), Material = Enum.Material.Grass, CanCollide = false }, m)
	elseif nodeType == "lunar" or nodeType == "zuarita" or nodeType == "estelar" then
		main = part({ Name = "Node", Size = Vector3.new(3, 4, 3), CFrame = CFrame.new(pos + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0.5, 0),
			Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Slate }, m)
		for i = 1, 3 do
			part({ Name = "Crystal", Size = Vector3.new(1.2, rng:NextNumber(3.5, 6), 1.2),
				CFrame = CFrame.new(pos + Vector3.new((i - 2) * 1.2, 4, 0)) * CFrame.Angles(0, i, (i - 2) * 0.35),
				Color = def.color, Material = Enum.Material.Neon, CanCollide = false }, m)
		end
		local l = Instance.new("PointLight")
		l.Color = def.color
		l.Range = 12
		l.Parent = main
	elseif nodeType == "petalo" or nodeType == "hongo" then
		main = part({ Name = "Node", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 0.8, 0.8),
			CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(80, 150, 70) }, m)
		part({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 1.6, 3), Position = pos + Vector3.new(0, 3.2, 0),
			Color = def.color, Material = Enum.Material.Neon, CanCollide = false }, m)
	elseif nodeType == "elemental" then
		main = part({ Name = "Node", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), Position = pos + Vector3.new(0, 2.5, 0),
			Color = def.color, Material = Enum.Material.Neon }, m)
		local f = Instance.new("Fire")
		f.Size = 4
		f.Parent = main
	elseif nodeType == "engranaje" then
		main = part({ Name = "Node", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 4, 4),
			CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)) * CFrame.Angles(0.3, 0.6, 0),
			Color = def.color, Material = Enum.Material.Metal }, m)
	else
		local s = rng:NextNumber(4, 6)
		main = part({ Name = "Node", Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(pos + Vector3.new(0, s * 0.35, 0)) *
			CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)),
			Color = Color3.fromRGB(110, 110, 115), Material = Enum.Material.Slate }, m)
		if nodeType ~= "stone" then
			for i = 1, 4 do
				part({ Name = "Ore", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4),
					Position = main.Position + Vector3.new(rng:NextNumber(-1.6, 1.6), rng:NextNumber(0, 1.6), rng:NextNumber(-1.6, 1.6)),
					Color = def.color, Material = Enum.Material.Metal, CanCollide = false }, m)
			end
		end
	end
	m.PrimaryPart = main
	m:SetAttribute("NodeId", id)
	m:SetAttribute("NodeType", nodeType)
	local pick = Items.Picks[def.pick]
	local obj = def.name
	if def.pick > 1 then
		obj = def.name .. " (" .. pick.name .. ")"
	end
	local pp = addPrompt(main, def.action, obj, 0.45, 12)
	pp.Name = "NodePrompt"
	pp.KeyboardKeyCode = Enum.KeyCode.E
	m.Parent = parent
	CollectionService:AddTag(m, "ResourceNode")
	World.Nodes[id] = { id = id, type = nodeType, model = m, part = main, pos = main.Position, area = area, prompt = pp }
	return m
end

Helpers.Folder = folder
Helpers.MakeNode = makeNode

return Helpers
