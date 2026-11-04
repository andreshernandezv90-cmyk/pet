-- World/StationArt: aspecto de cada estacion del santuario.
-- Cada funcion recibe (model, cf, level, rng, info) y devuelve la parte donde
-- va la interaccion (ProximityPrompt) y la altura para su etiqueta.
-- Si la estacion no esta construida se dibuja una obra marcada con estacas.

local Props = require(script.Parent.Props)

local StationArt = {}
local M = Enum.Material
local Part, Blob, Beam, Column, Disc, vary = Props.Part, Props.Blob, Props.Beam, Props.Column, Props.Disc, Props.Vary

local WOOD = Color3.fromRGB(140, 100, 66)
local DARK = Color3.fromRGB(86, 62, 44)
local METAL = Color3.fromRGB(70, 70, 78)
local STONE = Color3.fromRGB(150, 146, 140)

local function pad(m, cf, d)
	return Disc(m, cf * CFrame.new(0, 0.2, 0).Position, d, 0.4, Color3.fromRGB(160, 150, 136), M.Cobblestone, { CanCollide = true })
end

-- Techo de una sola caida sobre 4 postes
local function shelter(m, cf, w, d, h, rng, roofColor)
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		local hh = h + (c[2] > 0 and 0.8 or 0)
		Part(m, cf * CFrame.new(c[1] * w / 2, hh / 2, c[2] * d / 2) * CFrame.Angles(rng:NextNumber(-0.03, 0.03), 0, rng:NextNumber(-0.03, 0.03)),
			Vector3.new(0.6, hh, 0.6), DARK, M.Wood, { CanCollide = true })
	end
	local rows = 4
	for r = 0, rows - 1 do
		local z = -d / 2 - 0.6 + (d + 1.2) * (r + 0.5) / rows
		Part(m, cf * CFrame.new(rng:NextNumber(-0.1, 0.1), h + 0.4 + 0.8 * (z + d / 2) / d, z) * CFrame.Angles(-0.17, 0, rng:NextNumber(-0.02, 0.02)),
			Vector3.new(w + 1.4, 0.3, (d + 1.2) / rows + 0.3), vary(roofColor or Color3.fromRGB(150, 84, 60), rng, 0.1), M.Slate)
	end
end

function StationArt.Unbuilt(m, cf, rng, info)
	local s = 3.2
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
		Part(m, cf * CFrame.new(c[1] * s, 0.9, c[2] * s) * CFrame.Angles(rng:NextNumber(-0.1, 0.1), 0, rng:NextNumber(-0.1, 0.1)),
			Vector3.new(0.3, 1.8, 0.3), WOOD, M.Wood)
	end
	local pts = { cf * CFrame.new(-s, 1.4, -s), cf * CFrame.new(s, 1.4, -s), cf * CFrame.new(s, 1.4, s), cf * CFrame.new(-s, 1.4, s) }
	for i = 1, 4 do
		Beam(m, pts[i].Position, pts[i % 4 + 1].Position, 0.1, Color3.fromRGB(230, 200, 120), M.Fabric, { CastShadow = false })
	end
	local board = Part(m, cf * CFrame.new(0, 1.1, 0) * CFrame.Angles(-0.25, 0, 0), Vector3.new(2.6, 1.6, 0.25), Color3.fromRGB(176, 132, 86),
		M.WoodPlanks, { CanCollide = true })
	Part(m, cf * CFrame.new(0, 0.5, 0.2), Vector3.new(0.25, 1, 0.25), DARK, M.Wood)
	return board, 2.4
end

function StationArt.almacen(m, cf, level, rng)
	shelter(m, cf, 8, 6, 5.2, rng, Color3.fromRGB(120, 90, 70))
	Part(m, cf * CFrame.new(0, 0.2, 0), Vector3.new(8.4, 0.4, 6.4), Color3.fromRGB(126, 94, 64), M.WoodPlanks, { CanCollide = true })
	local main = Props.Crate(m, cf * CFrame.new(-2, 0.4, 0.8) * CFrame.Angles(0, 0.2, 0), 1.1):FindFirstChildWhichIsA("BasePart")
	Props.Crate(m, cf * CFrame.new(-2.2, 2.6, 0.9) * CFrame.Angles(0, -0.3, 0), 0.9)
	Props.Crate(m, cf * CFrame.new(0.4, 0.4, 1.4), 1)
	Props.Barrel(m, (cf * CFrame.new(2.6, 0.4, 1)).Position, 0.9)
	Props.Barrel(m, (cf * CFrame.new(2.9, 0.4, -1.3)).Position, 0.8)
	for k = 1, 3 do
		Blob(m, cf * CFrame.new(-0.5 + k * 0.9, 1.1, -1.8) * CFrame.Angles(0, k, 0.2), Vector3.new(1.6, 2, 1.4), Color3.fromRGB(214, 190, 140),
			M.Fabric)
	end
	return main, 6.5
end

function StationArt.taller(m, cf, level, rng)
	shelter(m, cf, 10, 7, 6, rng, Color3.fromRGB(110, 110, 120))
	-- banco de trabajo
	local top = Part(m, cf * CFrame.new(-2, 2.6, 1.6), Vector3.new(5, 0.4, 2.2), Color3.fromRGB(170, 126, 82), M.WoodPlanks, { CanCollide = true })
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		Part(m, cf * CFrame.new(-2 + c[1] * 2.2, 1.2, 1.6 + c[2] * 0.85), Vector3.new(0.35, 2.4, 0.35), DARK, M.Wood)
	end
	Part(m, cf * CFrame.new(-3, 3, 1.4) * CFrame.Angles(0, 0.4, 0), Vector3.new(1.4, 0.25, 0.25), Color3.fromRGB(150, 110, 70), M.Wood)
	Part(m, cf * CFrame.new(-0.8, 2.95, 1.5), Vector3.new(0.6, 0.3, 0.9), Color3.fromRGB(160, 165, 175), M.Metal)
	-- yunque
	Part(m, cf * CFrame.new(2.3, 0.7, 1.4), Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(110, 80, 56), M.Wood)
	Part(m, cf * CFrame.new(2.3, 1.7, 1.4), Vector3.new(0.9, 0.6, 0.9), METAL, M.Metal)
	Part(m, cf * CFrame.new(2.3, 2.15, 1.4), Vector3.new(2.2, 0.5, 1), METAL, M.Metal)
	-- forja de piedra con brasas
	for i = 0, 2 do
		Part(m, cf * CFrame.new(3, 0.6 + i * 0.9, -2) * CFrame.Angles(0, rng:NextNumber(-0.1, 0.1), 0), Vector3.new(3 - i * 0.3, 0.95, 2.6 - i * 0.3),
			vary(STONE, rng, 0.1), M.Cobblestone, { CanCollide = true })
	end
	local coal = Part(m, cf * CFrame.new(3, 2.75, -2), Vector3.new(1.8, 0.25, 1.5), Color3.fromRGB(255, 120, 40), M.Neon, { CastShadow = false })
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 140, 60)
	l.Range = 12
	l.Brightness = 1.6
	l.Parent = coal
	if level >= 2 then
		local smoke = Instance.new("Smoke")
		smoke.Opacity = 0.08
		smoke.Size = 1
		smoke.RiseVelocity = 2
		smoke.Parent = coal
		-- herramientas colgadas
		for k = 0, 2 do
			Part(m, cf * CFrame.new(-4 + k * 1.1, 4.6, -3.3), Vector3.new(0.2, 1.6, 0.2), DARK, M.Wood)
			Part(m, cf * CFrame.new(-4 + k * 1.1, 3.8, -3.3), Vector3.new(0.7, 0.35, 0.2), Color3.fromRGB(160, 165, 175), M.Metal)
		end
	end
	return top, 7.5
end

function StationArt.reactor(m, cf, level, rng)
	local base = Part(m, cf * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(1, 6.5, 6.5), Color3.fromRGB(120, 130, 150),
		M.Slate, { Shape = Enum.PartType.Cylinder, CanCollide = true })
	Disc(m, (cf * CFrame.new(0, 1.05, 0)).Position, 4.2, 0.1, Color3.fromRGB(90, 220, 255), M.Neon, { CastShadow = false })
	for k = 0, 2 do
		local a = k * math.pi * 2 / 3
		local foot = (cf * CFrame.new(math.cos(a) * 2.8, 1, math.sin(a) * 2.8)).Position
		local tip = (cf * CFrame.new(math.cos(a) * 1.2, 5.2, math.sin(a) * 1.2)).Position
		Beam(m, foot, tip, 0.55, Color3.fromRGB(150, 150, 170), M.Metal)
	end
	local crystal = Part(m, cf * CFrame.new(0, 4.4, 0) * CFrame.Angles(0.6, 0.8, 0.4), Vector3.new(1.5, 2.4, 1.5), Color3.fromRGB(110, 230, 255),
		M.Neon, { CastShadow = false })
	local ring = Part(m, cf * CFrame.new(0, 4.4, 0) * CFrame.Angles(0.3, 0, math.rad(90)), Vector3.new(0.15, 4.2, 4.2), Color3.fromRGB(160, 240, 255),
		M.Neon, { Shape = Enum.PartType.Cylinder, Transparency = 0.55, CastShadow = false })
	ring.Name = "Anillo"
	local l = Instance.new("PointLight")
	l.Color = crystal.Color
	l.Range = 14
	l.Brightness = 1.6
	l.Parent = crystal
	return base, 7
end

function StationArt.fusionlab(m, cf, level, rng)
	local base = Disc(m, (cf * CFrame.new(0, 0.3, 0)).Position, 6.5, 0.6, Color3.fromRGB(140, 120, 160), M.Slate, { CanCollide = true })
	for _, sx in ipairs({ -1, 1 }) do
		local pc = cf * CFrame.new(sx * 2, 0.6, 0)
		Column(m, pc.Position, 2.4, 1.1, Color3.fromRGB(190, 180, 210), M.Marble)
		local orb = Blob(m, pc * CFrame.new(0, 3.2, 0), Vector3.new(1.4, 1.4, 1.4), sx < 0 and Color3.fromRGB(255, 120, 220) or Color3.fromRGB(140, 160, 255),
			M.Neon, { CastShadow = false })
		if sx < 0 then
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(230, 140, 255)
			l.Range = 12
			l.Parent = orb
		end
	end
	Beam(m, (cf * CFrame.new(-2, 3.8, 0)).Position, (cf * CFrame.new(0, 5.2, 0)).Position, 0.18, Color3.fromRGB(255, 180, 255), M.Neon,
		{ CastShadow = false, Transparency = 0.2 })
	Beam(m, (cf * CFrame.new(0, 5.2, 0)).Position, (cf * CFrame.new(2, 3.8, 0)).Position, 0.18, Color3.fromRGB(180, 190, 255), M.Neon,
		{ CastShadow = false, Transparency = 0.2 })
	return base, 7
end

function StationArt.alchemy(m, cf, level, rng)
	-- caldero sobre piedras
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		Part(m, cf * CFrame.new(math.cos(a) * 1.8, 0.35, math.sin(a) * 1.8) * CFrame.Angles(0, a, 0.2), Vector3.new(1, 0.7, 0.9), vary(STONE, rng, 0.1),
			M.Slate)
	end
	local pot = Blob(m, cf * CFrame.new(0, 1.7, 0), Vector3.new(3.6, 2.8, 3.6), Color3.fromRGB(46, 44, 52), M.Metal, { CanCollide = true })
	Part(m, cf * CFrame.new(0, 2.95, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.35, 3.1, 3.1), Color3.fromRGB(60, 58, 66), M.Metal,
		{ Shape = Enum.PartType.Cylinder })
	local liquid = Disc(m, (cf * CFrame.new(0, 3.05, 0)).Position, 2.6, 0.15, Color3.fromRGB(120, 255, 140), M.Neon, { CastShadow = false })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(150, 255, 170))
	e.LightEmission = 0.8
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Rate = 5
	e.Speed = NumberRange.new(1, 2)
	e.SpreadAngle = Vector2.new(15, 15)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = liquid
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(120, 255, 150)
	l.Range = 10
	l.Parent = liquid
	-- estante con frascos
	local sh = cf * CFrame.new(0, 0, 3)
	for _, sx in ipairs({ -1, 1 }) do
		Part(m, sh * CFrame.new(sx * 2, 2, 0), Vector3.new(0.3, 4, 0.8), DARK, M.Wood)
	end
	for k = 0, 1 do
		Part(m, sh * CFrame.new(0, 1.4 + k * 1.6, 0), Vector3.new(4.4, 0.2, 0.9), WOOD, M.WoodPlanks)
		for b = 0, 3 do
			local colors = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 220, 80), Color3.fromRGB(170, 110, 255) }
			Part(m, sh * CFrame.new(-1.5 + b, 1.85 + k * 1.6, 0), Vector3.new(0.6, 0.6, 0.6), colors[(b + k) % 4 + 1], M.Glass,
				{ Shape = Enum.PartType.Ball, Transparency = 0.15, CastShadow = false })
		end
	end
	return pot, 6
end

function StationArt.bait(m, cf, level, rng)
	local top = Part(m, cf * CFrame.new(0, 2.4, 0), Vector3.new(5, 0.35, 2.6), Color3.fromRGB(170, 126, 82), M.WoodPlanks, { CanCollide = true })
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		Part(m, cf * CFrame.new(c[1] * 2.2, 1.1, c[2] * 1), Vector3.new(0.35, 2.2, 0.35), DARK, M.Wood)
	end
	local fills = { Color3.fromRGB(80, 90, 220), Color3.fromRGB(255, 140, 50), Color3.fromRGB(255, 220, 80) }
	for k = 0, 2 do
		local bc = cf * CFrame.new(-1.6 + k * 1.6, 2.6, 0)
		Part(m, bc * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.7, 1.4, 1.4), Color3.fromRGB(196, 160, 100), M.Fabric,
			{ Shape = Enum.PartType.Cylinder })
		for b = 0, 3 do
			Part(m, bc * CFrame.new(rng:NextNumber(-0.35, 0.35), 0.85, rng:NextNumber(-0.35, 0.35)), Vector3.new(0.45, 0.45, 0.45), fills[k + 1],
				M.SmoothPlastic, { Shape = Enum.PartType.Ball, CastShadow = false })
		end
	end
	-- hierbas colgando
	Part(m, cf * CFrame.new(0, 4.6, -1.1), Vector3.new(5.4, 0.2, 0.2), DARK, M.Wood)
	for _, sx in ipairs({ -1, 1 }) do
		Part(m, cf * CFrame.new(sx * 2.6, 2.4, -1.1), Vector3.new(0.3, 4.8, 0.3), DARK, M.Wood)
	end
	for k = 0, 4 do
		Blob(m, cf * CFrame.new(-2 + k, 3.9, -1.1), Vector3.new(0.6, 1.2, 0.6), Color3.fromRGB(90 + k * 10, 150, 70), M.SmoothPlastic, { CastShadow = false })
	end
	return top, 6
end

local PRODUCT_COLORS = {
	stone = Color3.fromRGB(150, 150, 155),
	copper = Color3.fromRGB(205, 120, 60),
	iron = Color3.fromRGB(175, 175, 190),
	moon = Color3.fromRGB(170, 190, 255),
	zuarita = Color3.fromRGB(70, 230, 210),
	nexus = Color3.fromRGB(190, 120, 255),
}

-- Torre de extraccion (madera para minerales comunes, metal y cristal para los magicos)
function StationArt.Extractor(m, cf, level, rng, id)
	local magic = id == "moon" or id == "zuarita" or id == "nexus"
	local color = PRODUCT_COLORS[id] or Color3.new(1, 1, 1)
	local base = pad(m, cf, 7.5)
	local h = 6 + level * 0.8
	local frameColor = magic and Color3.fromRGB(120, 116, 140) or DARK
	local frameMat = magic and M.Metal or M.Wood
	local top = cf * CFrame.new(0, h, 0)
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		Beam(m, (cf * CFrame.new(c[1] * 2.6, 0.3, c[2] * 2.6)).Position, (top * CFrame.new(c[1] * 0.6, 0, c[2] * 0.6)).Position, 0.45, frameColor, frameMat)
	end
	for _, y in ipairs({ 0.35, 0.7 }) do
		local yy = h * y
		local s = 2.6 - 2 * y
		local pts = {}
		for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
			table.insert(pts, (cf * CFrame.new(c[1] * s, yy, c[2] * s)).Position)
		end
		for i = 1, 4 do
			Beam(m, pts[i], pts[i % 4 + 1], 0.3, frameColor, frameMat)
		end
	end
	-- polea y taladro
	Part(m, top * CFrame.new(0, 0.3, 0), Vector3.new(1.8, 0.4, 1.8), frameColor, frameMat)
	local wheel = Part(m, top * CFrame.new(0, 1, 0), Vector3.new(0.4, 1.6, 1.6), METAL, M.Metal, { Shape = Enum.PartType.Cylinder })
	wheel.Name = "Polea"
	Column(m, (cf * CFrame.new(0, 0.3, 0)).Position, h - 0.2, 0.45, Color3.fromRGB(170, 170, 180), M.Metal)
	Disc(m, (cf * CFrame.new(0, 0.42, 0)).Position, 1.8, 0.05, Color3.fromRGB(30, 26, 26), M.SmoothPlastic, { CastShadow = false })
	-- monton de mineral
	local pile = cf * CFrame.new(3.6, 0, 1.4)
	for k = 1, 4 + math.min(level, 5) do
		local a = k * 2.3
		local r = (k % 3) * 0.45
		Part(m, pile * CFrame.new(math.cos(a) * r, 0.35 + (k > 4 and 0.5 or 0), math.sin(a) * r) * CFrame.Angles(k, k * 2, 0),
			Vector3.new(0.8, 0.7, 0.8), vary(color, rng, 0.1), magic and M.Neon or M.Slate, { CastShadow = false })
	end
	if magic then
		local cr = Part(m, top * CFrame.new(0, 2.6, 0) * CFrame.Angles(0.3, 0.7, 0), Vector3.new(1, 1.8, 1), color, M.Neon, { CastShadow = false })
		local l = Instance.new("PointLight")
		l.Color = color
		l.Range = 12
		l.Parent = cr
	elseif level >= 3 then
		Props.Lantern(m, (cf * CFrame.new(-3.4, 0, -2.4)).Position, rng, 4.2)
	end
	return base, h + 3
end

-- Bancal del huerto con cultivo
function StationArt.GardenBed(m, cf, active, plot)
	local frame = active and Color3.fromRGB(140, 100, 66) or Color3.fromRGB(150, 140, 120)
	for _, s in ipairs({ { 0, -1.85, 3.8, 0.3 }, { 0, 1.85, 3.8, 0.3 }, { -1.75, 0, 0.3, 4 }, { 1.75, 0, 0.3, 4 } }) do
		Part(m, cf * CFrame.new(s[1], 0.45, s[2]), Vector3.new(s[3], 0.9, s[4]), frame, M.WoodPlanks, { CanCollide = true })
	end
	local soil = Part(m, cf * CFrame.new(0, 0.7, 0), Vector3.new(3.3, 0.35, 3.4), active and Color3.fromRGB(96, 66, 44) or Color3.fromRGB(130, 116, 96),
		M.Ground)
	if plot and plot.crop then
		local ready = (plot.progress or 0) >= 1
		local cc = plot.crop == "baya" and Color3.fromRGB(90, 90, 230) or (plot.crop == "raiz" and Color3.fromRGB(255, 140, 50)
			or Color3.fromRGB(255, 220, 90))
		for k = 0, 3 do
			local p = cf * CFrame.new((k % 2 - 0.5) * 1.6, 0.9, (math.floor(k / 2) - 0.5) * 1.6)
			if ready then
				Blob(m, p * CFrame.new(0, 0.7, 0), Vector3.new(1.4, 1.2, 1.4), Color3.fromRGB(80, 160, 70), M.SmoothPlastic, { CastShadow = false })
				Part(m, p * CFrame.new(0.3, 1.1, -0.3), Vector3.new(0.6, 0.6, 0.6), cc, plot.crop == "flor" and M.Neon or M.SmoothPlastic,
					{ Shape = Enum.PartType.Ball, CastShadow = false })
			else
				local g = math.max(0.25, plot.progress or 0)
				Blob(m, p * CFrame.new(0, 0.3 * g, 0), Vector3.new(0.6, 0.9, 0.6) * (0.6 + g), Color3.fromRGB(120, 200, 90), M.SmoothPlastic,
					{ CastShadow = false })
			end
		end
	elseif not active then
		Blob(m, cf * CFrame.new(0.6, 1, -0.4), Vector3.new(0.8, 0.6, 0.8), Color3.fromRGB(120, 140, 70), M.SmoothPlastic, { CastShadow = false })
	end
	return soil
end

return StationArt
