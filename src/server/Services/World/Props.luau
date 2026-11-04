-- World/Props: biblioteca de elementos decorativos estilizados hechos con
-- primitivas y mallas parametricas de Roblox (SpecialMesh Sphere), sin assets
-- externos. Siluetas organicas: troncos inclinados en segmentos, copas de
-- varias esferas achatadas, raices, musgo y variacion de color.
-- Pensado para moviles: pocas partes por elemento y efectos moderados.

local CollectionService = game:GetService("CollectionService")

local Props = {}
local M = Enum.Material
local RAD90 = math.rad(90)

-- Basicos ----------------------------------------------------------------------------

local function newPart(className)
	local p = Instance.new(className or "Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

function Props.Part(parent, cf, size, color, material, opts)
	local p = newPart(opts and opts.ClassName)
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or M.SmoothPlastic
	if opts then
		for k, v in pairs(opts) do
			if k ~= "ClassName" then
				p[k] = v
			end
		end
	end
	p.Parent = parent
	return p
end
local Part = Props.Part

-- Elipsoide (esfera deformable): la pieza clave de las siluetas organicas
function Props.Blob(parent, cf, size, color, material, opts)
	local p = Part(parent, cf, size, color, material, opts)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end
local Blob = Props.Blob

-- Cilindro entre dos puntos
function Props.Beam(parent, a, b, diameter, color, material, opts)
	local d = b - a
	local len = d.Magnitude
	local mid = (a + b) / 2
	local cf
	if math.abs(d.Unit.Y) > 0.999 then
		cf = CFrame.new(mid) * CFrame.Angles(0, 0, RAD90)
	else
		cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, RAD90, 0)
	end
	local p = Part(parent, cf, Vector3.new(len, diameter, diameter), color, material, opts)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local Beam = Props.Beam

-- Columna vertical desde una base
function Props.Column(parent, basePos, height, diameter, color, material, opts)
	local p = Part(parent, CFrame.new(basePos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, RAD90),
		Vector3.new(height, diameter, diameter), color, material, opts)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local Column = Props.Column

-- Disco plano (cilindro con eje vertical)
function Props.Disc(parent, center, diameter, thickness, color, material, opts)
	local p = Part(parent, CFrame.new(center) * CFrame.Angles(0, 0, RAD90), Vector3.new(thickness, diameter, diameter), color, material, opts)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local Disc = Props.Disc

function Props.Vary(c, rng, amount)
	local f = 1 + rng:NextNumber(-amount, amount)
	return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end
local vary = Props.Vary

local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Paletas -------------------------------------------------------------------------------

Props.Palettes = {
	forest = { leaf = Color3.fromRGB(86, 160, 70), leaf2 = Color3.fromRGB(120, 190, 80), dark = Color3.fromRGB(56, 112, 58),
		bark = Color3.fromRGB(110, 78, 54) },
	magic = { leaf = Color3.fromRGB(110, 190, 140), leaf2 = Color3.fromRGB(170, 230, 160), dark = Color3.fromRGB(60, 120, 100),
		bark = Color3.fromRGB(96, 74, 70) },
	blossom = { leaf = Color3.fromRGB(250, 170, 200), leaf2 = Color3.fromRGB(255, 210, 225), dark = Color3.fromRGB(215, 120, 160),
		bark = Color3.fromRGB(120, 86, 76) },
	autumn = { leaf = Color3.fromRGB(240, 160, 60), leaf2 = Color3.fromRGB(250, 200, 90), dark = Color3.fromRGB(200, 100, 50),
		bark = Color3.fromRGB(104, 76, 56) },
}
Props.FlowerColors = {
	Color3.fromRGB(255, 120, 160), Color3.fromRGB(255, 220, 90), Color3.fromRGB(170, 130, 255), Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(110, 190, 255), Color3.fromRGB(255, 150, 80),
}

-- Arboles --------------------------------------------------------------------------------

-- Roble ligero para el bosque lejano (6 partes)
function Props.OakLite(parent, pos, rng, s, pal)
	s = s or 1
	pal = pal or Props.Palettes.forest
	local m = model(parent, "RobleLejano")
	local bark = vary(pal.bark, rng, 0.08)
	local p1 = pos + Vector3.new(rng:NextNumber(-0.8, 0.8) * s, 6 * s, rng:NextNumber(-0.8, 0.8) * s)
	local p2 = p1 + Vector3.new(rng:NextNumber(-0.8, 0.8) * s, 3.4 * s, rng:NextNumber(-0.8, 0.8) * s)
	local trunk = Beam(m, pos - Vector3.new(0, 0.8, 0), p1, 2.3 * s, bark, M.Wood, { CanCollide = true })
	Beam(m, p1, p2, 1.5 * s, bark, M.Wood)
	local top = p2 + Vector3.new(0, 2.6 * s, 0)
	local leaf = vary(pal.leaf, rng, 0.08)
	Blob(m, CFrame.new(top - Vector3.new(0, 1.2 * s, 0)), Vector3.new(11, 4.5, 11) * s, vary(pal.dark, rng, 0.06), M.SmoothPlastic)
	Blob(m, CFrame.new(top), Vector3.new(11.5, 8, 11.5) * s, leaf, M.SmoothPlastic)
	local a = rng:NextNumber(0, 6)
	Blob(m, CFrame.new(top + Vector3.new(math.cos(a) * 4 * s, 1.5 * s, math.sin(a) * 4 * s)), Vector3.new(7, 5.5, 7) * s,
		vary(pal.leaf2, rng, 0.08), M.SmoothPlastic)
	return m, trunk
end

-- Roble: tronco en 3 segmentos inclinados, raices, ramas y copa de varias esferas.
-- Devuelve el modelo y la parte del tronco (para interacciones).
function Props.Oak(parent, pos, rng, s, pal)
	s = s or 1
	pal = pal or Props.Palettes.forest
	local m = model(parent, "Roble")
	local bark = vary(pal.bark, rng, 0.08)
	local function lean(h)
		return Vector3.new(rng:NextNumber(-0.7, 0.7) * s, h * s, rng:NextNumber(-0.7, 0.7) * s)
	end
	local p0 = pos - Vector3.new(0, 0.8, 0)
	local p1 = p0 + lean(4.8)
	local p2 = p1 + lean(3.8)
	local p3 = p2 + lean(2.4)
	local trunk = Beam(m, p0, p1, 2.5 * s, bark, M.Wood, { CanCollide = true, CanQuery = true })
	Beam(m, p1, p2, 1.95 * s, bark, M.Wood)
	Beam(m, p2, p3, 1.4 * s, bark, M.Wood)
	local yaw = rng:NextNumber(0, math.pi * 2)
	for k = 1, 3 do
		local a = yaw + k * math.pi * 2 / 3
		local out = Vector3.new(math.cos(a), 0, math.sin(a))
		Beam(m, pos + out * 2.3 * s - Vector3.new(0, 0.4, 0), pos + out * 0.3 * s + Vector3.new(0, 1.7 * s, 0), 1.0 * s, bark, M.Wood)
	end
	local leaf, leaf2, dark = vary(pal.leaf, rng, 0.07), vary(pal.leaf2, rng, 0.07), vary(pal.dark, rng, 0.07)
	local top = p3 + Vector3.new(0, 2.8 * s, 0)
	-- ramas con mini copas
	for k = 1, 2 do
		local a = yaw + k * math.pi + 0.6
		local tip = p2 + Vector3.new(math.cos(a) * 4.2 * s, 2.2 * s, math.sin(a) * 4.2 * s)
		Beam(m, p2, tip, 0.75 * s, bark, M.Wood)
		Blob(m, CFrame.new(tip + Vector3.new(0, 1 * s, 0)), Vector3.new(5.5, 4, 5.5) * s, k == 1 and leaf or leaf2, M.SmoothPlastic)
	end
	Blob(m, CFrame.new(top - Vector3.new(0, 1.4 * s, 0)), Vector3.new(10.5, 4.2, 10.5) * s, dark, M.SmoothPlastic)
	Blob(m, CFrame.new(top), Vector3.new(11, 7.5, 11) * s, leaf, M.SmoothPlastic)
	for k = 1, 3 do
		local a = yaw + k * 2.1
		Blob(m, CFrame.new(top + Vector3.new(math.cos(a) * 4 * s, rng:NextNumber(0.2, 2.4) * s, math.sin(a) * 4 * s)),
			Vector3.new(6.5, 5, 6.5) * s * rng:NextNumber(0.85, 1.15), k == 2 and leaf2 or leaf, M.SmoothPlastic)
	end
	Blob(m, CFrame.new(top + Vector3.new(0.6 * s, 3.4 * s, -0.4 * s)), Vector3.new(6, 3.6, 6) * s, leaf2, M.SmoothPlastic)
	return m, trunk
end

-- Abeto estilizado: capas de esferas achatadas decrecientes
function Props.Fir(parent, pos, rng, s)
	s = s or 1
	local m = model(parent, "Abeto")
	local trunk = Column(m, pos - Vector3.new(0, 0.6, 0), 4 * s, 1.5 * s, vary(Color3.fromRGB(100, 72, 52), rng, 0.08), M.Wood,
		{ CanCollide = true, CanQuery = true })
	local base = vary(Color3.fromRGB(46, 122, 82), rng, 0.08)
	for i = 1, 4 do
		local w = (10.5 - i * 2.1) * s
		local c = base:Lerp(Color3.fromRGB(110, 180, 110), (i - 1) * 0.12)
		Blob(m, CFrame.new(pos + Vector3.new(0, (2.8 + (i - 1) * 2.6) * s, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
			Vector3.new(w, 3.6 * s, w * 0.92), c, M.SmoothPlastic)
	end
	Blob(m, CFrame.new(pos + Vector3.new(0, 13.4 * s, 0)), Vector3.new(1.8, 3, 1.8) * s, base:Lerp(Color3.fromRGB(150, 210, 130), 0.5),
		M.SmoothPlastic)
	return m, trunk
end

-- Arbol claro (abedul magico / cerezo): tronco palido curvado y copa luminosa
function Props.Birch(parent, pos, rng, s, pal)
	s = s or 1
	pal = pal or Props.Palettes.blossom
	local m = model(parent, "Abedul")
	local bark = vary(Color3.fromRGB(232, 226, 214), rng, 0.04)
	local p1 = pos + Vector3.new(rng:NextNumber(-1, 1) * s, 5 * s, rng:NextNumber(-1, 1) * s)
	local p2 = p1 + Vector3.new(rng:NextNumber(-1.2, 1.2) * s, 4.2 * s, rng:NextNumber(-1.2, 1.2) * s)
	local trunk = Beam(m, pos - Vector3.new(0, 0.6, 0), p1, 1.5 * s, bark, M.SmoothPlastic, { CanCollide = true, CanQuery = true })
	Beam(m, p1, p2, 1.1 * s, bark, M.SmoothPlastic)
	for k = 1, 3 do
		local y = rng:NextNumber(1.5, 6) * s
		local a = rng:NextNumber(0, math.pi * 2)
		Part(m, CFrame.new(pos + Vector3.new(math.cos(a) * 0.72 * s, y, math.sin(a) * 0.72 * s)) * CFrame.Angles(0, -a, 0),
			Vector3.new(0.12, 0.25 * s, 0.6 * s), Color3.fromRGB(50, 45, 45), M.SmoothPlastic, { CastShadow = false })
	end
	local top = p2 + Vector3.new(0, 1.8 * s, 0)
	Blob(m, CFrame.new(top), Vector3.new(8, 6, 8) * s, vary(pal.leaf, rng, 0.06), M.SmoothPlastic)
	Blob(m, CFrame.new(top + Vector3.new(2.6 * s, -1 * s, 1 * s)), Vector3.new(5, 4, 5) * s, vary(pal.leaf2, rng, 0.06), M.SmoothPlastic)
	Blob(m, CFrame.new(top + Vector3.new(-2.2 * s, 0.6 * s, -1.6 * s)), Vector3.new(5, 4, 5) * s, vary(pal.dark, rng, 0.06), M.SmoothPlastic)
	return m, trunk
end

-- Arbusto de 3 esferas, opcionalmente con bayas
function Props.Bush(parent, pos, rng, s, color, berries)
	s = s or 1
	local m = model(parent, "Arbusto")
	color = vary(color or Color3.fromRGB(80, 156, 72), rng, 0.08)
	Blob(m, CFrame.new(pos + Vector3.new(0, 1.1 * s, 0)), Vector3.new(4.2, 2.8, 4) * s, color, M.SmoothPlastic)
	Blob(m, CFrame.new(pos + Vector3.new(1.6 * s, 0.8 * s, 0.6 * s)), Vector3.new(3, 2.2, 3) * s, color:Lerp(Color3.new(1, 1, 0.6), 0.12),
		M.SmoothPlastic)
	Blob(m, CFrame.new(pos + Vector3.new(-1.4 * s, 0.7 * s, -0.5 * s)), Vector3.new(2.8, 2, 2.8) * s, color:Lerp(Color3.new(0, 0.2, 0), 0.15),
		M.SmoothPlastic)
	if berries then
		for k = 1, 4 do
			local a = k * 1.7
			Part(m, CFrame.new(pos + Vector3.new(math.cos(a) * 1.6 * s, (1.3 + (k % 2) * 0.6) * s, math.sin(a) * 1.4 * s)),
				Vector3.new(0.5, 0.5, 0.5) * s, berries, M.SmoothPlastic, { Shape = Enum.PartType.Ball, CastShadow = false })
		end
	end
	return m
end

-- Grupo de flores (tallo + corola)
function Props.Flowers(parent, center, rng, count, spread, colors)
	local m = model(parent, "Flores")
	colors = colors or Props.FlowerColors
	local stem = Color3.fromRGB(90, 150, 70)
	for _ = 1, count do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0, spread)
		local p = center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local h = rng:NextNumber(0.9, 1.6)
		local tilt = CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2))
		Part(m, CFrame.new(p) * tilt * CFrame.new(0, h / 2, 0), Vector3.new(0.14, h, 0.14), stem, M.SmoothPlastic, { CastShadow = false })
		local c = colors[rng:NextInteger(1, #colors)]
		Blob(m, CFrame.new(p) * tilt * CFrame.new(0, h, 0), Vector3.new(0.8, 0.45, 0.8), c, M.SmoothPlastic, { CastShadow = false })
	end
	return m
end

-- Hongo (opcionalmente luminoso)
function Props.Mushroom(parent, pos, rng, s, glow, capColor)
	s = s or 1
	local m = model(parent, "Hongo")
	local tilt = CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, rng:NextNumber(-0.15, 0.15))
	Part(m, CFrame.new(pos) * tilt * CFrame.new(0, 0.65 * s, 0) * CFrame.Angles(0, 0, RAD90), Vector3.new(1.3 * s, 0.6 * s, 0.6 * s),
		Color3.fromRGB(245, 235, 215), M.SmoothPlastic, { Shape = Enum.PartType.Cylinder, CastShadow = false })
	capColor = capColor or (glow and Color3.fromRGB(150, 110, 255) or Color3.fromRGB(220, 60, 60))
	local cap = Blob(m, CFrame.new(pos) * tilt * CFrame.new(0, 1.35 * s, 0), Vector3.new(2, 1.05, 2) * s, capColor,
		glow and M.Neon or M.SmoothPlastic, { CastShadow = false })
	if glow then
		local l = Instance.new("PointLight")
		l.Color = capColor
		l.Range = 9
		l.Brightness = 0.9
		l.Parent = cap
	else
		for k = 1, 3 do
			local a = k * 2.1
			Blob(m, CFrame.new(pos) * tilt * CFrame.new(math.cos(a) * 0.5 * s, 1.72 * s, math.sin(a) * 0.5 * s), Vector3.new(0.35, 0.18, 0.35) * s,
				Color3.new(1, 1, 1), M.SmoothPlastic, { CastShadow = false })
		end
	end
	return m
end

-- Roca con musgo
function Props.Rock(parent, pos, rng, s, mossy, collide)
	s = s or 1
	local m = model(parent, "Roca")
	local c = vary(Color3.fromRGB(128, 126, 136), rng, 0.08)
	local yaw = rng:NextNumber(0, math.pi * 2)
	Part(m, CFrame.new(pos + Vector3.new(0, 0.7 * s, 0)) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), yaw, rng:NextNumber(-0.25, 0.25)),
		Vector3.new(3.2, 2.2, 2.6) * s, c, M.Slate, { CanCollide = collide == true })
	Part(m, CFrame.new(pos + Vector3.new(1.4 * s, 0.4 * s, 0.6 * s)) * CFrame.Angles(0.3, yaw + 0.8, 0.2), Vector3.new(1.8, 1.4, 1.6) * s,
		c:Lerp(Color3.new(0, 0, 0), 0.1), M.Slate)
	if mossy ~= false then
		Blob(m, CFrame.new(pos + Vector3.new(-0.2 * s, 1.75 * s, 0)), Vector3.new(2.4, 0.7, 2) * s, Color3.fromRGB(96, 160, 80), M.SmoothPlastic,
			{ CastShadow = false })
	end
	return m
end

-- Tronco caido
function Props.Log(parent, a, b, d, rng)
	local m = model(parent, "TroncoCaido")
	local bark = vary(Color3.fromRGB(106, 76, 54), rng, 0.08)
	Beam(m, a, b, d, bark, M.Wood, { CanCollide = true })
	local dir = (b - a).Unit
	Beam(m, a - dir * 0.05, a + dir * 0.08, d * 0.86, Color3.fromRGB(214, 180, 130), M.Wood)
	Beam(m, b - dir * 0.08, b + dir * 0.05, d * 0.86, Color3.fromRGB(214, 180, 130), M.Wood)
	Blob(m, CFrame.new((a + b) / 2 + Vector3.new(0, d * 0.45, 0)), Vector3.new(d * 1.4, d * 0.4, d * 1.1), Color3.fromRGB(96, 160, 80),
		M.SmoothPlastic, { CastShadow = false })
	return m
end

-- Farol de madera con luz calida
function Props.Lantern(parent, pos, rng, height)
	height = height or 6
	local m = model(parent, "Farol")
	local wood = vary(Color3.fromRGB(86, 62, 46), rng, 0.06)
	local tilt = CFrame.Angles(rng:NextNumber(-0.04, 0.04), rng:NextNumber(0, 6), rng:NextNumber(-0.04, 0.04))
	local base = CFrame.new(pos) * tilt
	Part(m, base * CFrame.new(0, height / 2, 0), Vector3.new(0.5, height, 0.5), wood, M.Wood, { CanCollide = true })
	Part(m, base * CFrame.new(0.8, height - 0.2, 0), Vector3.new(2, 0.3, 0.3), wood, M.Wood)
	Part(m, base * CFrame.new(1.6, height - 0.7, 0), Vector3.new(0.08, 0.7, 0.08), Color3.fromRGB(50, 50, 55), M.Metal)
	Part(m, base * CFrame.new(1.6, height - 1.5, 0), Vector3.new(0.9, 0.18, 0.9), Color3.fromRGB(50, 50, 55), M.Metal)
	Part(m, base * CFrame.new(1.6, height - 2.4, 0), Vector3.new(0.9, 0.18, 0.9), Color3.fromRGB(50, 50, 55), M.Metal)
	local glass = Part(m, base * CFrame.new(1.6, height - 1.95, 0), Vector3.new(0.75, 0.75, 0.75), Color3.fromRGB(255, 205, 120), M.Neon,
		{ CastShadow = false })
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 190, 110)
	l.Range = 16
	l.Brightness = 1.3
	l.Shadows = false
	l.Parent = glass
	return m
end

-- Cerca rustica entre dos puntos (algunas tablas rotas si broken)
function Props.Fence(parent, a, b, rng, broken)
	local m = model(parent, "Cerca")
	local wood = Color3.fromRGB(122, 90, 62)
	local d = b - a
	local n = math.max(1, math.floor(d.Magnitude / 3.6 + 0.5))
	local prev
	for i = 0, n do
		local p = a + d * (i / n)
		local post = p + Vector3.new(0, 1.3, 0)
		Part(m, CFrame.new(post) * CFrame.Angles(rng:NextNumber(-0.08, 0.08), rng:NextNumber(0, 1), rng:NextNumber(-0.08, 0.08)),
			Vector3.new(0.45, 2.6, 0.45), vary(wood, rng, 0.1), M.Wood, { CanCollide = true })
		if prev then
			for _, y in ipairs({ 0.9, 1.9 }) do
				if not (broken and rng:NextNumber() < 0.25) then
					Beam(m, prev + Vector3.new(0, y, 0), p + Vector3.new(0, y + rng:NextNumber(-0.15, 0.15), 0), 0.28, vary(wood, rng, 0.12), M.Wood)
				end
			end
		end
		prev = p
	end
	return m
end

function Props.Crate(parent, cf, s)
	s = s or 1
	local m = model(parent, "Caja")
	Part(m, cf * CFrame.new(0, 1 * s, 0), Vector3.new(2, 2, 2) * s, Color3.fromRGB(176, 130, 82), M.WoodPlanks, { CanCollide = true })
	for _, x in ipairs({ -1, 1 }) do
		Part(m, cf * CFrame.new(x * 0.95 * s, 1 * s, -1.02 * s), Vector3.new(0.22, 2.05, 0.1) * s, Color3.fromRGB(110, 80, 52), M.Wood)
	end
	Part(m, cf * CFrame.new(0, 1 * s, -1.02 * s) * CFrame.Angles(0, 0, math.rad(45)), Vector3.new(0.22, 2.6, 0.08) * s,
		Color3.fromRGB(110, 80, 52), M.Wood)
	return m
end

function Props.Barrel(parent, pos, s)
	s = s or 1
	local m = model(parent, "Barril")
	Column(m, pos, 2.6 * s, 1.9 * s, Color3.fromRGB(150, 100, 60), M.Wood, { CanCollide = true })
	Column(m, pos + Vector3.new(0, 0.5 * s, 0), 0.22 * s, 2.0 * s, Color3.fromRGB(60, 60, 66), M.Metal)
	Column(m, pos + Vector3.new(0, 1.9 * s, 0), 0.22 * s, 2.0 * s, Color3.fromRGB(60, 60, 66), M.Metal)
	return m
end

function Props.Woodpile(parent, cf, rng)
	local m = model(parent, "Leña")
	local rows = { 3, 2, 1 }
	for r, n in ipairs(rows) do
		for i = 1, n do
			local x = (i - (n + 1) / 2) * 1.05
			local p = cf * CFrame.new(x, 0.5 + (r - 1) * 0.9, 0)
			local log = Part(m, p * CFrame.Angles(0, RAD90 + rng:NextNumber(-0.1, 0.1), 0), Vector3.new(3.2, 1, 1),
				vary(Color3.fromRGB(120, 84, 56), rng, 0.1), M.Wood)
			log.Shape = Enum.PartType.Cylinder
		end
	end
	return m
end

-- Tocon con hacha clavada
function Props.Stump(parent, pos, rng, axe)
	local m = model(parent, "Tocon")
	Column(m, pos, 1.4, 2.4, Color3.fromRGB(116, 82, 56), M.Wood, { CanCollide = true })
	Disc(m, pos + Vector3.new(0, 1.42, 0), 2.1, 0.06, Color3.fromRGB(214, 180, 130), M.Wood)
	if axe then
		local base = CFrame.new(pos + Vector3.new(0.3, 1.4, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), math.rad(25))
		Part(m, base * CFrame.new(0, 1.2, 0), Vector3.new(0.22, 2.4, 0.22), Color3.fromRGB(150, 110, 70), M.Wood)
		Part(m, base * CFrame.new(0.35, 0.15, 0), Vector3.new(0.8, 0.6, 0.12), Color3.fromRGB(160, 165, 175), M.Metal)
	end
	return m
end

-- Piedras planas para caminos
function Props.SteppingStones(parent, points, rng, spacing)
	local m = model(parent, "PiedrasCamino")
	spacing = spacing or 3
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local d = b - a
		local n = math.max(1, math.floor(d.Magnitude / spacing))
		local side = Vector3.new(-d.Z, 0, d.X).Unit
		for k = 0, n - 1 do
			local p = a + d * ((k + rng:NextNumber(0.2, 0.8)) / n) + side * rng:NextNumber(-1.2, 1.2)
			local sz = rng:NextNumber(1.4, 2.2)
			local stone = Part(m, CFrame.new(p.X, 0.06, p.Z) * CFrame.Angles(0, rng:NextNumber(0, 6), RAD90), Vector3.new(0.25, sz, sz * 0.85),
				vary(Color3.fromRGB(160, 154, 146), rng, 0.08), M.Slate, { CastShadow = false })
			stone.Shape = Enum.PartType.Cylinder
		end
	end
	return m
end

-- Luciernagas: un emisor con forma de caja (efecto moderado)
function Props.Fireflies(parent, center, size, rate, color)
	local p = Part(parent, CFrame.new(center), size, Color3.new(1, 1, 1), M.SmoothPlastic,
		{ Transparency = 1, CanQuery = false, CastShadow = false, Name = "Luciernagas" })
	local e = Instance.new("ParticleEmitter")
	e.Name = "Fireflies"
	e.Color = ColorSequence.new(color or Color3.fromRGB(230, 255, 150))
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Size = NumberSequence.new(0.22)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(3, 6)
	e.Rate = rate or 3
	e.Speed = NumberRange.new(0.3, 0.9)
	e.SpreadAngle = Vector2.new(180, 180)
	e.RotSpeed = NumberRange.new(-20, 20)
	pcall(function()
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	end)
	e.Parent = p
	return p
end

-- Letrero de madera con texto en la cara frontal (-Z)
function Props.Sign(parent, cf, text, width, textColor)
	width = width or 7
	local m = model(parent, "Letrero")
	local wood = Color3.fromRGB(120, 88, 60)
	for _, x in ipairs({ -width / 2 + 0.5, width / 2 - 0.5 }) do
		Part(m, cf * CFrame.new(x, 1.6, 0), Vector3.new(0.4, 3.2, 0.4), wood, M.Wood, { CanCollide = true })
	end
	local board = Part(m, cf * CFrame.new(0, 3.1, -0.15) * CFrame.Angles(0, 0, math.rad(1.5)), Vector3.new(width, 2.2, 0.35),
		Color3.fromRGB(170, 126, 84), M.WoodPlanks)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.6
	gui.Parent = board
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -16, 1, -8)
	t.Position = UDim2.new(0, 8, 0, 4)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = textColor or Color3.fromRGB(255, 244, 210)
	t.TextStrokeTransparency = 0.5
	t.Text = text
	t.Parent = gui
	return m, t
end

-- Portal magico: anillo ovalado de piedras con runas y superficie luminosa.
-- cf: centro de la base, mirando hacia -Z. Devuelve el modelo y la superficie.
function Props.Portal(parent, cf, color, rng)
	local m = model(parent, "Portal")
	local stone = Color3.fromRGB(128, 120, 146)
	-- Estrado de dos escalones
	Part(m, cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, RAD90), Vector3.new(0.6, 15, 15), Color3.fromRGB(116, 110, 126), M.Slate,
		{ Shape = Enum.PartType.Cylinder, CanCollide = true })
	Part(m, cf * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, RAD90), Vector3.new(0.5, 11, 11), Color3.fromRGB(140, 134, 150), M.Slate,
		{ Shape = Enum.PartType.Cylinder, CanCollide = true })
	local a, b, cy = 5.2, 6.6, 7.6
	local n = 16
	for i = 0, n - 1 do
		local t = (i / n) * math.pi * 2
		local px, py = a * math.cos(t), cy + b * math.sin(t)
		-- tangente de la elipse para orientar la piedra
		local ang = math.atan2(b * math.cos(t), -a * math.sin(t))
		local scl = rng:NextNumber(0.9, 1.15)
		local sc = cf * CFrame.new(px, py, 0) * CFrame.Angles(0, 0, ang) * CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, 0)
		Part(m, sc, Vector3.new(2.3 * scl, 1.6 * scl, 1.8 * scl), vary(stone, rng, 0.08), M.Slate, { CanCollide = true })
		if i % 2 == 0 then
			Part(m, sc * CFrame.new(0, 0, -0.95 * scl), Vector3.new(0.7, 0.5, 0.1), color, M.Neon, { CastShadow = false })
		end
	end
	-- piedra clave con gema
	Part(m, cf * CFrame.new(0, cy + b + 0.6, 0), Vector3.new(2.6, 2.4, 2.2), stone:Lerp(Color3.new(1, 1, 1), 0.1), M.Slate)
	Blob(m, cf * CFrame.new(0, cy + b + 0.7, -1.1), Vector3.new(1.1, 1.3, 0.6), color, M.Neon, { CastShadow = false })
	-- superficie del portal
	local gate = Blob(m, cf * CFrame.new(0, cy, 0), Vector3.new(2 * a - 1.2, 2 * b - 1.2, 0.35), color, M.Neon,
		{ Transparency = 0.3, CastShadow = false, Name = "Gate" })
	local swirl = Blob(m, cf * CFrame.new(0, cy, -0.12), Vector3.new(2 * a - 4, 2 * b - 4.5, 0.2), color:Lerp(Color3.new(1, 1, 1), 0.45),
		M.Neon, { Transparency = 0.45, CastShadow = false, Name = "Swirl" })
	CollectionService:AddTag(swirl, "PortalSwirl")
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 22
	light.Brightness = 2
	light.Parent = gate
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5))
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(1.2, 2)
	e.Rate = 7
	e.Speed = NumberRange.new(1, 2.5)
	e.SpreadAngle = Vector2.new(30, 30)
	e.EmissionDirection = Enum.NormalId.Front
	e.Parent = gate
	return m, gate
end

return Props
