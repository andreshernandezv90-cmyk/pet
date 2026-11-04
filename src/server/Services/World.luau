-- World: construye los tres mundos con primitivas al iniciar el servidor.
--   1. Hogar Dimensional  (0, 0, 0)       parcelas, plaza, bosque
--   2. Minas de Zuar      (2000, 0, 0)    nodos minerales por nivel de pico
--   3. Reino de los PETs  (-2000, 0, 0)   hub + 5 zonas con parkour + arena
-- No depende de modelos externos: todo se genera con Parts.

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Items)
local Progression = require(Shared.Progression)

local World = {}

World.HOME = Vector3.new(0, 0, 0)
World.MINES = Vector3.new(2000, 0, 0)
World.REALM = Vector3.new(-2000, 0, 0)
World.ARENA = Vector3.new(-2000, 0, -700)

World.Nodes = {} -- [id] = { id, type, model, part, pos, area }
World.Checkpoints = {} -- lista { part, zone, index, meadow }
World.Chests = {} -- [zone] = { part, prompt }
World.Portals = {} -- lista de { prompt, dest }
World.Spawns = {} -- [nombre] = CFrame
World.SpawnRegions = {} -- [zone] = { center = Vector3, sizeX, sizeZ }
World.PlotCenters = {} -- [i] = CFrame (mira hacia la plaza)
World.ArenaPillars = {} -- lista de Vector3

local root
local nodeCounter = 0

function World.ZoneOrigin(k)
	return Vector3.new(-2000 + (k - 3) * 500, 0, 700)
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
World.Part = part

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
World.Slab = slab

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
World.Billboard = billboard

local function signPost(parent, pos, text, color)
	local post = part({ Name = "Sign", Size = Vector3.new(1, 6, 1), Position = pos + Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(110, 80, 50), Material = Enum.Material.Wood, CanCollide = false }, parent)
	local board = part({ Name = "Board", Size = Vector3.new(8, 3, 0.5), Position = pos + Vector3.new(0, 6.5, 0),
		Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood, CanCollide = false }, parent)
	billboard(board, text, color or Color3.fromRGB(255, 245, 200), 260, 3, 90)
	return post
end
World.SignPost = signPost

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
World.AddPrompt = addPrompt

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
World.Portal = portal

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

-- HOGAR ------------------------------------------------------------------------------------

local function buildHome()
	local f = folder("Hogar", root)
	local H = World.HOME
	slab(f, H, 820, 820, 0, Color3.fromRGB(110, 170, 80), Enum.Material.Grass, "Pasto")
	part({ Name = "Plaza", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 84, 84),
		CFrame = CFrame.new(H + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(190, 185, 170), Material = Enum.Material.Cobblestone }, f)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnHogar"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = H + Vector3.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(120, 200, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.4
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = f
	World.Spawns.hub = CFrame.new(H + Vector3.new(0, 4, 8))

	portal(f, H + Vector3.new(30, 0, 0), math.rad(90), "Minas de Zuar", Color3.fromRGB(255, 170, 70), "mines")
	portal(f, H + Vector3.new(-30, 0, 0), math.rad(-90), "Reino de los PETs", Color3.fromRGB(170, 120, 255), "realm")
	signPost(f, H + Vector3.new(0, 0, -30), "Hogar Dimensional\nTu parcela esta marcada con tu nombre", Color3.fromRGB(255, 240, 160))

	-- Parcelas (8 alrededor de la plaza)
	local plots = folder("Parcelas", f)
	for i = 1, 8 do
		local a = (i - 1) / 8 * math.pi * 2 + math.pi / 8
		local c = H + Vector3.new(math.cos(a) * 150, 0, math.sin(a) * 150)
		local cf = CFrame.lookAt(c, Vector3.new(H.X, 0, H.Z))
		World.PlotCenters[i] = cf
		part({ Name = "Parcela" .. i, Size = Vector3.new(72, 0.4, 72), CFrame = cf * CFrame.new(0, 0.2, 0),
			Color = Color3.fromRGB(150, 190, 110), Material = Enum.Material.Grass }, plots)
		-- camino hacia la plaza
		part({ Name = "Camino", Size = Vector3.new(8, 0.3, 72), CFrame = cf * CFrame.new(0, 0.15, -72),
			Color = Color3.fromRGB(200, 180, 140), Material = Enum.Material.Sand }, plots)
	end

	-- Bosque: anillo exterior
	local forest = folder("Bosque", f)
	local rng = Random.new(42)
	local placed = 0
	local tries = 0
	while placed < 60 and tries < 600 do
		tries = tries + 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(245, 385)
		local pos = H + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local ok = true
		for _, n in pairs(World.Nodes) do
			if n.area == "home" and (Vector3.new(n.pos.X, 0, n.pos.Z) - pos).Magnitude < 14 then
				ok = false
				break
			end
		end
		if ok then
			makeNode(forest, "tree", pos, "home", rng)
			placed = placed + 1
		end
	end
	signPost(f, H + Vector3.new(0, 0, 235), "Bosque: tala arboles para obtener madera 🪵", Color3.fromRGB(190, 255, 170))
	signPost(f, H + Vector3.new(0, 0, -235), "Bosque: tala arboles para obtener madera 🪵", Color3.fromRGB(190, 255, 170))
end

-- MINAS DE ZUAR ------------------------------------------------------------------------------

local function buildMines()
	local f = folder("MinasDeZuar", root)
	local M = World.MINES
	slab(f, M, 520, 520, 0, Color3.fromRGB(95, 85, 80), Enum.Material.Slate, "Suelo")
	-- paredes de roca
	for _, d in ipairs({ { 0, -262, 540, 6 }, { 0, 262, 540, 6 }, { -262, 0, 6, 540 }, { 262, 0, 6, 540 } }) do
		part({ Name = "Pared", Size = Vector3.new(d[3], 40, d[4]), Position = M + Vector3.new(d[1], 20, d[2]),
			Color = Color3.fromRGB(80, 70, 65), Material = Enum.Material.Rock }, f)
	end
	World.Spawns.mines = CFrame.new(M + Vector3.new(0, 4, -225)) * CFrame.Angles(0, math.rad(180), 0)
	portal(f, M + Vector3.new(0, 0, -245), 0, "Volver al Hogar", Color3.fromRGB(120, 200, 255), "home")
	signPost(f, M + Vector3.new(14, 0, -222), "Minas de Zuar\nMejora tu pico para llegar mas profundo", Color3.fromRGB(255, 210, 150))

	local rng = Random.new(7)
	local areas = {
		{ type = "stone", z0 = -200, z1 = -120, count = 14, label = "Piedra · Pico de madera" },
		{ type = "copper", z0 = -105, z1 = -30, count = 12, label = "Cobre · Pico de piedra" },
		{ type = "iron", z0 = -15, z1 = 60, count = 10, label = "Hierro · Pico de cobre" },
		{ type = "lunar", z0 = 75, z1 = 150, count = 8, label = "Cristal lunar · Pico de hierro" },
		{ type = "zuarita", z0 = 165, z1 = 235, count = 6, label = "Zuarita · Pico de cristal" },
	}
	for _, a in ipairs(areas) do
		local def = Items.Nodes[a.type]
		signPost(f, M + Vector3.new(-30, 0, a.z0 + 4), a.label, def.color:Lerp(Color3.new(1, 1, 1), 0.4))
		-- franja de color en el suelo
		part({ Name = "Franja", Size = Vector3.new(500, 0.2, a.z1 - a.z0), Position = M + Vector3.new(0, 0.1, (a.z0 + a.z1) / 2),
			Color = def.color:Lerp(Color3.fromRGB(95, 85, 80), 0.75), Material = Enum.Material.Slate }, f)
		for i = 1, a.count do
			local pos = M + Vector3.new(rng:NextNumber(-200, 200), 0, rng:NextNumber(a.z0 + 8, a.z1 - 4))
			makeNode(f, a.type, pos, "mines", rng)
		end
	end
	-- techo de caverna sobre los cristales
	part({ Name = "Techo", Size = Vector3.new(520, 4, 170), Position = M + Vector3.new(0, 30, 160),
		Color = Color3.fromRGB(60, 55, 60), Material = Enum.Material.Rock }, f)
end

-- REINO DE LOS PETs ----------------------------------------------------------------------------

local zoneStyles = {
	[1] = { ground = Color3.fromRGB(140, 210, 110), mat = Enum.Material.Grass, plat = Color3.fromRGB(250, 230, 150),
		n = 10, spacing = 14, size = 11, amp = 2 },
	[2] = { ground = Color3.fromRGB(190, 165, 115), mat = Enum.Material.Sand, plat = Color3.fromRGB(170, 150, 120),
		n = 11, spacing = 12.6, size = 9, amp = 3 },
	[3] = { ground = Color3.fromRGB(70, 65, 90), mat = Enum.Material.Slate, plat = Color3.fromRGB(110, 100, 140),
		n = 10, spacing = 14, size = 9, amp = 2 },
	[4] = { ground = Color3.fromRGB(110, 190, 150), mat = Enum.Material.Grass, plat = Color3.fromRGB(150, 220, 240),
		n = 10, spacing = 14, size = 9, amp = 2 },
	[5] = { ground = Color3.fromRGB(95, 80, 150), mat = Enum.Material.Marble, plat = Color3.fromRGB(200, 190, 255),
		n = 8, spacing = 18, size = 9, amp = 4 },
}

local function checkpoint(parent, pos, zone, index, meadow)
	local cp = part({ Name = "Checkpoint", Size = Vector3.new(8, 0.4, 8), Position = pos + Vector3.new(0, 0.2, 0),
		Color = Color3.fromRGB(90, 255, 140), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false }, parent)
	cp:SetAttribute("Zone", zone)
	cp:SetAttribute("Index", index)
	table.insert(World.Checkpoints, { part = cp, zone = zone, index = index, meadow = meadow, pos = pos })
	return cp
end

local function moving(p, offset, time)
	local tween = TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = p.CFrame + offset })
	tween:Play()
end

local function buildParkour(f, k, O)
	local st = zoneStyles[k]
	local z0, z1 = -198, -72
	local spacing = (z1 - z0) / (st.n - 1)
	local cps = { [4] = true, [7] = true }
	for i = 1, st.n do
		local z = z0 + (i - 1) * spacing
		local y = math.floor(math.sin(i * 1.3) * st.amp + 0.5) + (i - 1) * 0.6
		local x = math.sin(i * 0.9) * 6
		local center = O + Vector3.new(x, 0, z)
		local p = part({ Name = "Plataforma", Size = Vector3.new(st.size + 2, 2, st.size), Position = center + Vector3.new(0, y - 1, 0),
			Color = st.plat, Material = Enum.Material.SmoothPlastic }, f)
		if k == 2 and i > 1 and i < st.n then
			if i % 3 == 0 then
				p.Color = Color3.fromRGB(220, 160, 60)
				moving(p, Vector3.new(0, 5, 0), 2.5)
			elseif i % 4 == 0 then
				p.Color = Color3.fromRGB(200, 120, 60)
				moving(p, Vector3.new(7, 0, 0), 3.5)
			end
		elseif k == 3 then
			-- tunel oscuro
			part({ Name = "Pared", Size = Vector3.new(1, 14, spacing + 1), Position = center + Vector3.new(-(st.size / 2 + 4), y + 6, 0),
				Color = Color3.fromRGB(45, 40, 55), Material = Enum.Material.Rock }, f)
			part({ Name = "Pared", Size = Vector3.new(1, 14, spacing + 1), Position = center + Vector3.new(st.size / 2 + 4, y + 6, 0),
				Color = Color3.fromRGB(45, 40, 55), Material = Enum.Material.Rock }, f)
			part({ Name = "Techo", Size = Vector3.new(st.size + 10, 1, spacing + 1), Position = center + Vector3.new(0, y + 13, 0),
				Color = Color3.fromRGB(40, 35, 50), Material = Enum.Material.Rock }, f)
			local glow = part({ Name = "Hongo", Shape = Enum.PartType.Ball, Size = Vector3.new(1.5, 1, 1.5),
				Position = center + Vector3.new(st.size / 2 - 1, y + 0.4, 0), Color = Color3.fromRGB(150, 90, 255),
				Material = Enum.Material.Neon, CanCollide = false }, f)
			local l = Instance.new("PointLight")
			l.Color = glow.Color
			l.Range = 14
			l.Parent = glow
		elseif k == 4 then
			if i == 3 or i == 7 then
				local pad = part({ Name = "JumpPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 5, 5),
					CFrame = CFrame.new(center + Vector3.new(0, y + 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
					Color = Color3.fromRGB(255, 120, 60), Material = Enum.Material.Neon }, f)
				CollectionService:AddTag(pad, "JumpPad")
			end
			if i == 5 then
				local ice = part({ Name = "MuroDeHielo", Size = Vector3.new(st.size + 2, 14, 2), Position = center + Vector3.new(0, y + 7, 0),
					Color = Color3.fromRGB(170, 230, 255), Material = Enum.Material.Ice, Transparency = 0.2 }, f)
				CollectionService:AddTag(ice, "IceWall")
				billboard(ice, "Muro de hielo\n(Flamin lo derrite · o rodea por la derecha)", Color3.fromRGB(200, 240, 255), 260, 9, 60)
				-- desvio
				for j = 1, 2 do
					part({ Name = "Desvio", Size = Vector3.new(6, 2, 6), Position = center + Vector3.new(st.size / 2 + 6, y - 1, (j - 1.5) * 9),
						Color = st.plat, Material = Enum.Material.SmoothPlastic }, f)
				end
			end
		elseif k == 5 and i == 3 then
			-- ruta secreta con plataformas ocultas (Prisma las revela)
			for j = 1, 4 do
				local hp = part({ Name = "PlataformaOculta", Size = Vector3.new(7, 1.5, 7),
					Position = center + Vector3.new(-14 - j * 12, y + j * 2, 0), Color = Color3.fromRGB(150, 255, 255),
					Material = Enum.Material.Glass, Transparency = 0.92, CanCollide = false }, f)
				CollectionService:AddTag(hp, "HiddenPlatform")
			end
		end
		if cps[i] then
			checkpoint(f, center + Vector3.new(0, y, 0), k, i, false)
		end
	end
	local tip = {
		[1] = "Parkour tutorial: salta con ESPACIO (o el boton de salto). ¡Sin prisa!",
		[2] = "Valle de los Engranajes: plataformas moviles. Espera el momento justo.",
		[3] = "Cavernas Olvidadas: tunel oscuro. Nox te da vision nocturna.",
		[4] = "Jardines Elementales: trampolines y muros de hielo.",
		[5] = "Templo del Eclipse: gravedad baja. Prisma revela caminos ocultos.",
	}
	signPost(f, O + Vector3.new(14, 0, -222), tip[k], Color3.fromRGB(255, 255, 210))
end

local function buildZone(k)
	local Z = Progression.Zones[k]
	local st = zoneStyles[k]
	local f = folder("Zona" .. k, root)
	local O = World.ZoneOrigin(k)
	-- Entrada
	slab(f, O + Vector3.new(0, 0, -228), 40, 36, 0, st.plat, Enum.Material.SmoothPlastic, "Entrada")
	World.Spawns["z" .. k] = CFrame.new(O + Vector3.new(0, 4, -232)) * CFrame.Angles(0, math.pi, 0)
	portal(f, O + Vector3.new(-14, 0, -240), 0, "Volver al Reino", Color3.fromRGB(170, 120, 255), "realm")
	checkpoint(f, O + Vector3.new(0, 0, -225), k, 0, false)
	signPost(f, O + Vector3.new(-6, 0, -214), "Zona " .. k .. " · " .. Z.name, Z.color:Lerp(Color3.new(1, 1, 1), 0.5))

	buildParkour(f, k, O)

	-- Pradera central
	slab(f, O + Vector3.new(0, 0, 70), 360, 260, 0, st.ground, st.mat, "Pradera")
	checkpoint(f, O + Vector3.new(0, 0, -52), k, 99, true)
	World.Spawns["z" .. k .. "m"] = CFrame.new(O + Vector3.new(0, 4, -45)) * CFrame.Angles(0, math.pi, 0)
	World.SpawnRegions[k] = { center = O + Vector3.new(0, 0, 80), sizeX = 300, sizeZ = 200 }
	portal(f, O + Vector3.new(0, 0, 192), math.rad(180), "Volver al Reino", Color3.fromRGB(170, 120, 255), "realm")
	signPost(f, O + Vector3.new(10, 0, -45), Z.name .. "\nCaptura PETs salvajes con tu succionador", Color3.fromRGB(255, 255, 210))

	-- Decoracion tematica
	local rng = Random.new(100 + k)
	for i = 1, 28 do
		local pos = O + Vector3.new(rng:NextNumber(-170, 170), 0, rng:NextNumber(-50, 195))
		if math.abs(pos.X - O.X) > 30 or pos.Z - O.Z > 170 then
			if k == 1 or k == 4 then
				part({ Name = "Arbusto", Shape = Enum.PartType.Ball, Size = Vector3.new(6, 4, 6), Position = pos + Vector3.new(0, 1.5, 0),
					Color = st.ground:Lerp(Color3.new(0, 0.3, 0), 0.3), Material = Enum.Material.Grass }, f)
			elseif k == 2 then
				part({ Name = "Engranaje", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 8, 8),
					CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
					Color = Color3.fromRGB(160, 130, 80), Material = Enum.Material.Metal }, f)
			elseif k == 3 then
				part({ Name = "Estalagmita", Size = Vector3.new(3, rng:NextNumber(6, 14), 3), Position = pos + Vector3.new(0, 4, 0),
					Color = Color3.fromRGB(80, 70, 100), Material = Enum.Material.Rock }, f)
			else
				part({ Name = "Columna", Size = Vector3.new(3, 18, 3), Position = pos + Vector3.new(0, 9, 0),
					Color = Color3.fromRGB(190, 180, 240), Material = Enum.Material.Marble }, f)
			end
		end
	end
	if k == 3 then
		-- techo de caverna parcial
		part({ Name = "Boveda", Size = Vector3.new(360, 3, 260), Position = O + Vector3.new(0, 34, 70), Color = Color3.fromRGB(35, 30, 45),
			Material = Enum.Material.Rock, Transparency = 0 }, f)
	end

	-- Materiales de la zona
	for i = 1, 12 do
		local pos = O + Vector3.new(rng:NextNumber(-160, 160), 0, rng:NextNumber(-30, 185))
		makeNode(f, Z.material, pos, "z" .. k, rng)
	end

	-- Cofre secreto
	local chestPos
	if k == 5 then
		local cp = O + Vector3.new(math.sin(3 * 0.9) * 6, 0, -198 + 2 * 18)
		chestPos = cp + Vector3.new(-14 - 5 * 12, math.floor(math.sin(3 * 1.3) * 4 + 0.5) + 1.2 + 10, 0)
		part({ Name = "PlataformaCofre", Size = Vector3.new(10, 1.5, 10), Position = chestPos - Vector3.new(0, 1.5, 0),
			Color = Color3.fromRGB(200, 190, 255), Material = Enum.Material.Marble }, f)
	else
		chestPos = O + Vector3.new(rng:NextNumber(120, 165) * (rng:NextNumber() > 0.5 and 1 or -1), 0, rng:NextNumber(150, 190))
	end
	local chest = part({ Name = "CofreSecreto", Size = Vector3.new(4, 3, 3), Position = chestPos + Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(200, 150, 60), Material = Enum.Material.Wood }, f)
	part({ Name = "Tapa", Size = Vector3.new(4.2, 1, 3.2), Position = chestPos + Vector3.new(0, 3.4, 0),
		Color = Color3.fromRGB(230, 190, 70), Material = Enum.Material.Metal }, f)
	CollectionService:AddTag(chest, "SecretChest")
	local pp = addPrompt(chest, "Abrir", "Cofre secreto", 1, 10)
	World.Chests[k] = { part = chest, prompt = pp }
end

local function buildRealm()
	local f = folder("ReinoHub", root)
	local R = World.REALM
	slab(f, R, 180, 180, 0, Color3.fromRGB(150, 130, 210), Enum.Material.Grass, "Isla")
	part({ Name = "Base", Size = Vector3.new(150, 30, 150), Position = R + Vector3.new(0, -19, 0),
		Color = Color3.fromRGB(110, 90, 80), Material = Enum.Material.Rock }, f)
	World.Spawns.realm = CFrame.new(R + Vector3.new(0, 4, -40)) * CFrame.Angles(0, math.pi, 0)
	portal(f, R + Vector3.new(0, 0, -72), 0, "Volver al Hogar", Color3.fromRGB(120, 200, 255), "home")
	signPost(f, R + Vector3.new(14, 0, -48), "Reino de los PETs\nElige una zona. Las zonas bloqueadas muestran sus requisitos.",
		Color3.fromRGB(230, 210, 255))
	for k = 1, 5 do
		local Z = Progression.Zones[k]
		portal(f, R + Vector3.new((k - 3) * 30, 0, 60), math.rad(180), "Zona " .. k .. "\n" .. Z.name, Z.color, "z" .. k)
	end
	portal(f, R + Vector3.new(75, 0, -10), math.rad(-90), "Arena de Incursiones", Color3.fromRGB(255, 90, 90), "arena")

	for k = 1, 5 do
		buildZone(k)
	end

	-- Arena de incursiones
	local af = folder("Arena", root)
	local A = World.ARENA
	part({ Name = "Arena", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 190, 190),
		CFrame = CFrame.new(A + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(80, 70, 110), Material = Enum.Material.Marble }, af)
	part({ Name = "Circulo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 56, 56),
		CFrame = CFrame.new(A + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Neon, Transparency = 0.6 }, af)
	World.Spawns.arena = CFrame.new(A + Vector3.new(0, 4, 75))
	portal(f, A + Vector3.new(0, 0, 88), 0, "Volver al Reino", Color3.fromRGB(170, 120, 255), "realm")
	for i = 1, 4 do
		local a = (i - 1) / 4 * math.pi * 2 + math.pi / 4
		table.insert(World.ArenaPillars, A + Vector3.new(math.cos(a) * 55, 0, math.sin(a) * 55))
	end
end

-- Areas (para saber donde esta cada jugador) ------------------------------------------------

function World.AreaAt(pos)
	local x, z = pos.X, pos.Z
	if math.abs(x) <= 420 and math.abs(z) <= 420 then
		return "home"
	end
	if math.abs(x - World.MINES.X) <= 270 and math.abs(z - World.MINES.Z) <= 270 then
		return "mines"
	end
	if math.abs(x - World.ARENA.X) <= 110 and math.abs(z - World.ARENA.Z) <= 110 then
		return "arena"
	end
	if math.abs(x - World.REALM.X) <= 100 and math.abs(z - World.REALM.Z) <= 100 then
		return "realm"
	end
	for k = 1, 5 do
		local O = World.ZoneOrigin(k)
		if math.abs(x - O.X) <= 200 and z >= O.Z - 260 and z <= O.Z + 210 then
			return "z" .. k
		end
	end
	return "void"
end

function World.ZoneOfArea(area)
	local k = area and string.match(area, "^z(%d)$")
	return k and tonumber(k) or nil
end

function World.Build()
	-- La plantilla "Baseplate" de Studio choca con el suelo del Hogar: se retira.
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local old = workspace:FindFirstChild(name)
		if old and old:IsA("BasePart") then
			old:Destroy()
		end
	end
	root = folder("World", workspace)
	buildHome()
	buildMines()
	buildRealm()
	World.Root = root
end

return World
