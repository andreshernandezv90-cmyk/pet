-- World/Helpers: utilidades de construccion compartidas por los modulos del mundo.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Items)
local Progression = require(Shared.Progression)

local Props = require(script.Parent.Props)

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
	local cf = CFrame.new(pos) * CFrame.Angles(0, facingYaw or 0, 0)
	local seed = math.floor(pos.X * 7 + pos.Z * 13) % 100000
	local m, gate = Props.Portal(parent, cf, color, Random.new(seed))
	m.Name = "Portal_" .. dest
	billboard(gate, text, color, 300, 9.5, 150)
	local pp = addPrompt(gate, "Viajar", text, 0, 12)
	pp:SetAttribute("Dest", dest)
	table.insert(World.Portals, { prompt = pp, dest = dest })
	return m, gate
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
		-- arboles talables con silueta natural (roble, abeto o abedul)
		local kind = rng:NextNumber()
		local sc = rng:NextNumber(0.85, 1.15)
		local _, trunk
		if kind < 0.55 then
			_, trunk = Props.Oak(m, pos, rng, sc)
		elseif kind < 0.85 then
			_, trunk = Props.Fir(m, pos, rng, sc)
		else
			_, trunk = Props.Birch(m, pos, rng, sc, Props.Palettes.magic)
		end
		main = trunk
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

-- Veta de galeria (Minas de Zuar): roca neutra con cristales de mineral. El mineral
-- de cada veta es PRIVADO por jugador y por ciclo (Mining + MineVeins); el cliente
-- pinta localmente su reparto. El servidor valida cada golpe contra ese reparto.
local function makeVein(parent, pos, gallery, rng, faceTo)
	nodeCounter = nodeCounter + 1
	local id = "n" .. nodeCounter
	local m = Instance.new("Model")
	m.Name = "Veta"
	local s = rng:NextNumber(4.2, 5.6)
	local look = faceTo and CFrame.lookAt(pos, Vector3.new(faceTo.X, pos.Y, faceTo.Z)) or CFrame.new(pos)
	local main = part({ Name = "Node", Size = Vector3.new(s, s * 0.85, s * 0.9),
		CFrame = look * CFrame.new(0, s * 0.36, 0) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-0.25, 0.25)),
		Color = Color3.fromRGB(92, 86, 90), Material = Enum.Material.Slate }, m)
	for i = 1, 4 do
		local ore = part({ Name = "Ore", Size = Vector3.new(1.1, rng:NextNumber(1.6, 2.6), 1.1),
			CFrame = look * CFrame.new(rng:NextNumber(-1.4, 1.4), s * 0.55 + rng:NextNumber(0, 1.2), -s * 0.3 + rng:NextNumber(-0.6, 0.6))
				* CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6), rng:NextNumber(-0.5, 0.5)),
			Color = Color3.fromRGB(110, 104, 108), Material = Enum.Material.Slate, CanCollide = false, CastShadow = false }, m)
		ore:SetAttribute("Ore", i)
	end
	m.PrimaryPart = main
	m:SetAttribute("NodeId", id)
	m:SetAttribute("NodeType", "vein")
	m:SetAttribute("Gallery", gallery)
	local pp = addPrompt(main, "Minar", "Veta", 0.45, 12)
	pp.Name = "NodePrompt"
	pp.KeyboardKeyCode = Enum.KeyCode.E
	m.Parent = parent
	CollectionService:AddTag(m, "ResourceNode")
	CollectionService:AddTag(m, "VeinSocket")
	World.Nodes[id] = { id = id, type = "vein", gallery = gallery, model = m, part = main, pos = main.Position, area = "m" .. gallery, prompt = pp }
	return m, id
end

Helpers.Folder = folder
Helpers.MakeNode = makeNode
Helpers.MakeVein = makeVein

return Helpers
