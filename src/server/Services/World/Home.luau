-- World/Home: el Santuario (Hogar Dimensional).
--   * Terreno natural con colinas suaves y caminos de tierra.
--   * Plaza central empedrada con fuente magica, faroles y bancos.
--   * 8 parcelas: cada una es un claro dentro de un pequeño bosque, con
--     arboles talables, flores, hongos, rocas, estanque, cerca rustica y el
--     portal al Mundo PET frente a la casa. (La casa y las estaciones son
--     dinamicas y las construye Plots segun el progreso de cada jugador.)
--   * Bosque exterior con arboles talables, colinas y luciernagas.

local H = require(script.Parent.Helpers)
local Terrain = require(script.Parent.Terrain)
local Props = require(script.Parent.Props)
local PlotLayout = require(script.Parent.PlotLayout)
local Lighting = require(script.Parent.Lighting)

local folder, billboard, portal, makeNode = H.Folder, H.Billboard, H.Portal, H.MakeNode
local Part, Blob, Disc, Column = Props.Part, Props.Blob, Props.Disc, Props.Column
local Mat = Enum.Material

local World
local Home = {}

local PORTAL_COLOR = Color3.fromRGB(150, 110, 255)
local hills = {} -- { pos, r, h } para calcular la altura del suelo

local function groundY(x, z)
	local y = 0
	for _, hl in ipairs(hills) do
		local r = math.max(hl.r, hl.h)
		local cy = hl.h - r
		local d2 = (x - hl.pos.X) ^ 2 + (z - hl.pos.Z) ^ 2
		if d2 < r * r then
			y = math.max(y, cy + math.sqrt(r * r - d2))
		end
	end
	return y
end

local function hill(pos, r, h, mat)
	table.insert(hills, { pos = pos, r = r, h = h })
	Terrain.Hill(pos, r, h, mat or Mat.Grass)
end

local function onGround(p)
	return Vector3.new(p.X, groundY(p.X, p.Z), p.Z)
end

-- Plaza central ------------------------------------------------------------------------------

local function buildPlaza(f, C, rng)
	Terrain.Disc(C, 46, Mat.Cobblestone)
	Terrain.Disc(C, 18, Mat.Pavement)
	-- Fuente magica de tres niveles
	local fm = Instance.new("Model")
	fm.Name = "FuenteMagica"
	fm.Parent = f
	Disc(fm, C + Vector3.new(0, 0.6, 0), 15, 1.2, Color3.fromRGB(170, 164, 156), Mat.Cobblestone, { CanCollide = true })
	Disc(fm, C + Vector3.new(0, 1.15, 0), 13, 0.2, Color3.fromRGB(110, 200, 230), Mat.Glass, { Transparency = 0.25, CastShadow = false })
	Column(fm, C + Vector3.new(0, 1, 0), 4, 2.2, Color3.fromRGB(190, 184, 176), Mat.Marble, { CanCollide = true })
	Disc(fm, C + Vector3.new(0, 4.9, 0), 6, 0.6, Color3.fromRGB(190, 184, 176), Mat.Marble)
	Disc(fm, C + Vector3.new(0, 5.25, 0), 5, 0.15, Color3.fromRGB(120, 210, 240), Mat.Glass, { Transparency = 0.2, CastShadow = false })
	Column(fm, C + Vector3.new(0, 5, 0), 2.6, 1.2, Color3.fromRGB(200, 194, 186), Mat.Marble)
	local crystal = Part(fm, CFrame.new(C + Vector3.new(0, 9.2, 0)) * CFrame.Angles(0.4, 0.6, 0.3), Vector3.new(1.6, 2.6, 1.6),
		Color3.fromRGB(150, 220, 255), Mat.Neon, { CastShadow = false })
	local l = Instance.new("PointLight")
	l.Color = crystal.Color
	l.Range = 24
	l.Brightness = 1.6
	l.Parent = crystal
	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(190, 235, 255))
	spray.LightEmission = 0.6
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.1) })
	spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	spray.Lifetime = NumberRange.new(1, 1.4)
	spray.Rate = 14
	spray.Speed = NumberRange.new(6, 8)
	spray.SpreadAngle = Vector2.new(18, 18)
	spray.Acceleration = Vector3.new(0, -14, 0)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Parent = crystal
	-- Bancos y faroles alrededor (entre los caminos hacia las parcelas)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		Props.Lantern(f, C + dir * 40, rng, 7)
		if k % 2 == 1 then
			local bc = CFrame.lookAt(C + dir * 24, C) * CFrame.new(0, 0, 0)
			local bench = Instance.new("Model")
			bench.Name = "Banco"
			bench.Parent = f
			Part(bench, bc * CFrame.new(0, 1.4, 0), Vector3.new(5, 0.35, 1.6), Color3.fromRGB(160, 116, 74), Mat.WoodPlanks, { CanCollide = true })
			Part(bench, bc * CFrame.new(0, 2.3, 0.75) * CFrame.Angles(-0.2, 0, 0), Vector3.new(5, 1.2, 0.25), Color3.fromRGB(150, 108, 70),
				Mat.WoodPlanks)
			for _, sx in ipairs({ -2, 2 }) do
				Part(bench, bc * CFrame.new(sx, 0.6, 0), Vector3.new(0.5, 1.2, 1.4), Color3.fromRGB(120, 116, 112), Mat.Slate)
			end
		end
		-- macetas con flores en el borde de la plaza
		local pot = C + Vector3.new(math.cos(a + 0.2), 0, math.sin(a + 0.2)) * 44
		Column(f, pot, 1.2, 2.6, Color3.fromRGB(180, 110, 80), Mat.Slate)
		Props.Flowers(f, pot + Vector3.new(0, 1.2, 0), rng, 5, 0.9)
	end
	-- Punto de aparicion (se redirige a la parcela en cuanto carga el perfil)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnHogar"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.Position = C + Vector3.new(0, 0.2, -26)
	spawn.Color = Color3.fromRGB(170, 160, 210)
	spawn.Material = Mat.Slate
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Transparency = 0.2
	spawn.Parent = f
	World.Spawns.hub = CFrame.new(C + Vector3.new(0, 4, -26))
	local sign = Props.Sign(f, CFrame.lookAt(C + Vector3.new(0, 0, -34), C + Vector3.new(0, 0, -60)), "Santuario\nTu parcela tiene tu nombre", 8)
	sign.Name = "LetreroPlaza"
end

-- Parcela -----------------------------------------------------------------------------------

local function plotWorld(cf, x, z)
	return (cf * CFrame.new(x, 0, z)).Position
end

local function buildPlot(f, i, cf, rng)
	local pf = folder("Parcela" .. i, f)
	local half, usable = PlotLayout.Half, PlotLayout.Usable
	local function W(x, z)
		return plotWorld(cf, x, z)
	end
	-- Suelo: borde de pasto frondoso donde crece el bosque
	for _, e in ipairs({ { 0, half - 4.5, half * 2 + 6, 13 }, { 0, -half + 4.5, half * 2 + 6, 13 }, { half - 4.5, 0, 13, half * 2 + 6 },
		{ -half + 4.5, 0, 13, half * 2 + 6 } }) do
		local c = cf * CFrame.new(e[1], -2, e[2])
		workspace.Terrain:FillBlock(c, Vector3.new(e[3], 4, e[4]), Mat.LeafyGrass)
	end
	-- Caminos de tierra
	for _, path in ipairs(PlotLayout.Paths) do
		local pts = {}
		for _, p in ipairs(path.points) do
			table.insert(pts, W(p[1], p[2]))
		end
		Terrain.Path(pts, path.width, Mat.Ground)
	end
	-- Tierra del huerto
	local g = PlotLayout.Spots.garden
	workspace.Terrain:FillBlock(cf * CFrame.new(g.x, -2, g.z), Vector3.new(g.w + 2, 4, g.d + 2), Mat.Mud)
	-- Estanque
	local pond = PlotLayout.Pond
	Terrain.Pond(W(pond.x, pond.z), pond.r)
	for k = 1, 3 do
		local a = k * 2.2
		Props.Rock(pf, W(pond.x + math.cos(a) * (pond.r + 2.6), pond.z + math.sin(a) * (pond.r + 2.6)), rng, 0.55, true)
	end

	-- Bosque del borde: arboles grandes afuera, arbustos hacia dentro
	local placed = {}
	local function free(x, z, minDist)
		for _, p in ipairs(placed) do
			if (p[1] - x) ^ 2 + (p[2] - z) ^ 2 < minDist * minDist then
				return false
			end
		end
		return true
	end
	local choppable = 0
	local tries = 0
	while #placed < 26 and tries < 400 do
		tries = tries + 1
		local side = rng:NextInteger(1, 4)
		local along = rng:NextNumber(-half + 2, half - 2)
		local depth = rng:NextNumber(usable + 4.5, half - 0.5)
		local x, z
		if side == 1 then
			x, z = along, depth
		elseif side == 2 then
			x, z = along, -depth
		elseif side == 3 then
			x, z = depth, along
		else
			x, z = -depth, along
		end
		local entrance = z < 0 and math.abs(x) < 11
		if not entrance and not PlotLayout.IsReserved(x, z, 3) and free(x, z, 8.5) then
			table.insert(placed, { x, z })
			local pos = W(x, z)
			if choppable < 6 and z < 0 and z > -usable then
				-- arboles talables cerca del frente: madera a mano desde el inicio
				makeNode(pf, "tree", pos, "home", rng)
				choppable = choppable + 1
			else
				local kind = rng:NextNumber()
				local s = rng:NextNumber(0.8, 1.1)
				if kind < 0.22 then
					Props.Oak(pf, pos, rng, s)
				elseif kind < 0.45 then
					Props.OakLite(pf, pos, rng, s)
				elseif kind < 0.78 then
					Props.Fir(pf, pos, rng, s)
				elseif kind < 0.9 then
					Props.Birch(pf, pos, rng, s * 0.95, Props.Palettes.blossom)
				else
					Props.Birch(pf, pos, rng, s * 0.95, Props.Palettes.magic)
				end
			end
		end
	end
	-- Arbustos en el limite interior del bosque
	local bushes = 0
	for _ = 1, 40 do
		if bushes >= 14 then
			break
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local r = usable + rng:NextNumber(0, 3)
		local x = math.clamp(math.cos(a) * r * 1.4, -r, r)
		local z = math.clamp(math.sin(a) * r * 1.4, -r, r)
		if not (z < 0 and math.abs(x) < 11) and not PlotLayout.IsReserved(x, z, 2) and free(x, z, 4) then
			table.insert(placed, { x, z })
			bushes = bushes + 1
			Props.Bush(pf, W(x, z), rng, rng:NextNumber(0.8, 1.2), nil, rng:NextNumber() < 0.3 and Color3.fromRGB(220, 60, 90) or nil)
		end
	end
	-- Flores, hongos y rocas en huecos libres del interior
	local decor = 0
	for _ = 1, 140 do
		if decor >= 16 then
			break
		end
		local x = rng:NextNumber(-usable + 2, usable - 2)
		local z = rng:NextNumber(-usable + 2, usable - 2)
		if not PlotLayout.IsReserved(x, z, 2.5) and free(x, z, 5) then
			table.insert(placed, { x, z })
			decor = decor + 1
			local k = rng:NextNumber()
			if k < 0.55 then
				Props.Flowers(pf, W(x, z), rng, 4, 1.4)
			elseif k < 0.75 then
				Props.Mushroom(pf, W(x, z), rng, rng:NextNumber(0.7, 1.1), false)
				Props.Mushroom(pf, W(x + 1.2, z + 0.6), rng, 0.6, false)
			elseif k < 0.9 then
				Props.Rock(pf, W(x, z), rng, rng:NextNumber(0.6, 1), true)
			else
				Props.Mushroom(pf, W(x, z), rng, 0.9, true)
			end
		end
	end
	-- Tronco caido junto al bosque del fondo
	Props.Log(pf, W(-34, 47), W(-24, 49), 1.6, rng)
	-- Cerca rustica a ambos lados de la entrada
	Props.Fence(pf, W(-44, -51), W(-12, -51), rng, true)
	Props.Fence(pf, W(12, -51), W(44, -51), rng, true)
	-- Pilares de entrada con faroles
	for _, sx in ipairs({ -1, 1 }) do
		local base = W(sx * 7, -54)
		for k = 0, 2 do
			Part(pf, CFrame.new(base + Vector3.new(0, 0.7 + k * 1.15, 0)) * CFrame.Angles(0, rng:NextNumber(0, 1), 0),
				Vector3.new(2 - k * 0.2, 1.2, 2 - k * 0.2), Props.Vary(Color3.fromRGB(150, 146, 140), rng, 0.1), Mat.Cobblestone, { CanCollide = true })
		end
		Props.Lantern(pf, base + Vector3.new(0, 3.8, 0), rng, 2.6)
	end
	-- Faroles a lo largo del camino principal
	for _, p in ipairs({ { -5, -34 }, { 5, -24 }, { 5, 10 }, { -5, 20 }, { 5.5, 24 } }) do
		if not PlotLayout.IsReserved(p[1], p[2], 0.3) then
			Props.Lantern(pf, W(p[1], p[2]), rng, 5.5)
		end
	end
	-- Piedras planas en el tramo final hacia el portal
	Props.SteppingStones(pf, { W(-1, -1), W(-10, 7) }, rng, 3)
	-- Luciernagas sobre la parcela
	Props.Fireflies(pf, W(0, 0) + Vector3.new(0, 7, 0), Vector3.new(90, 10, 90), 4)

	-- Portal al Mundo PET, frente a la casa
	local P = PlotLayout.Portal
	local pcf = cf * CFrame.new(P.x, 0, P.z) * CFrame.Angles(0, P.yaw or 0, 0)
	local seed = rng:NextInteger(1, 100000)
	local pm, gate = Props.Portal(pf, pcf, PORTAL_COLOR, Random.new(seed))
	pm.Name = "PortalMundoPET"
	billboard(gate, "Portal al Mundo PET", Color3.fromRGB(220, 200, 255), 300, 9.5, 120)
	local pp = H.AddPrompt(gate, "Viajar", "Mundo PET", 0, 12)
	-- Fase B: lleva al Reino actual; en la Fase C apuntara a la entrada del Mundo PET continuo
	pp:SetAttribute("Dest", "realm")
	table.insert(World.Portals, { prompt = pp, dest = "realm", plot = i })
	World.PlotPortals[i] = pm
end

-- Bosque exterior --------------------------------------------------------------------------

local function buildOuterForest(f, C, rng)
	-- Colinas entre parcelas y en el anillo exterior
	for i = 1, 8 do
		local a = (i - 1) / 8 * math.pi * 2 + math.pi / 8 + math.pi / 8
		hill(C + Vector3.new(math.cos(a) * 250, 0, math.sin(a) * 250), 26, 8, Mat.Grass)
		hill(C + Vector3.new(math.cos(a + 0.18) * 360, 0, math.sin(a + 0.18) * 360), 44, 14, Mat.LeafyGrass)
		hill(C + Vector3.new(math.cos(a - 0.25) * 330, 0, math.sin(a - 0.25) * 330), 30, 9, Mat.Grass)
	end
	-- Rocas grandes sobre algunas colinas
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2 + 0.6
		Props.Rock(f, onGround(C + Vector3.new(math.cos(a) * 395, 0, math.sin(a) * 395)), rng, rng:NextNumber(1.6, 2.4), true, true)
	end
	-- Arboles talables y decorativos
	local forest = folder("Bosque", f)
	local trees = {}
	local function farEnough(pos, d)
		for _, t in ipairs(trees) do
			if (t - pos).Magnitude < d then
				return false
			end
		end
		return true
	end
	local chop = 0
	local tries = 0
	while #trees < 210 and tries < 4000 do
		tries = tries + 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(268, 440)
		local pos = C + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		-- dejar despejados los caminos hacia las parcelas (no hay parcelas tan lejos)
		if math.abs(pos.X) < 452 and math.abs(pos.Z) < 452 and farEnough(pos, 9.5) then
			table.insert(trees, pos)
			local g = onGround(pos)
			if chop < 48 and r < 380 then
				makeNode(forest, "tree", g, "home", rng)
				chop = chop + 1
			else
				local k = rng:NextNumber()
				if k < 0.5 then
					Props.Fir(forest, g, rng, rng:NextNumber(1, 1.45))
				elseif k < 0.88 then
					Props.OakLite(forest, g, rng, rng:NextNumber(1, 1.35))
				elseif k < 0.95 then
					Props.Birch(forest, g, rng, 1.1, Props.Palettes.autumn)
				else
					Props.Birch(forest, g, rng, 1.1, Props.Palettes.blossom)
				end
			end
		end
	end
	for _ = 1, 36 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(262, 430)
		local pos = C + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if farEnough(pos, 5) then
			local g = onGround(pos)
			local k = rng:NextNumber()
			if k < 0.6 then
				Props.Bush(forest, g, rng, rng:NextNumber(0.9, 1.4))
			elseif k < 0.8 then
				Props.Flowers(forest, g, rng, 6, 2)
			else
				Props.Mushroom(forest, g, rng, 1.1, rng:NextNumber() < 0.3)
			end
		end
	end
	-- Arboledas entre caminos (cerca de la plaza) y entre parcelas
	for w = 0, 7 do
		local mid = w / 8 * math.pi * 2
		local grove = 0
		for _ = 1, 60 do
			if grove >= 9 then
				break
			end
			local a = mid + rng:NextNumber(-0.22, 0.22)
			local r = rng:NextNumber(64, 265)
			-- despejar la linea de la plaza a los portales de Minas y Reino
			local nearPortals = (w == 0 or w == 4) and r < 75
			local pos = C + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			if not nearPortals and farEnough(pos, 10) then
				local inPlot = false
				for _, pc in ipairs(World.PlotCenters) do
					local lp = pc:PointToObjectSpace(pos)
					if math.abs(lp.X) < PlotLayout.Half + 4 and math.abs(lp.Z) < PlotLayout.Half + 8 then
						inPlot = true
					end
				end
				if not inPlot then
					table.insert(trees, pos)
					grove = grove + 1
					local g = onGround(pos)
					local k = rng:NextNumber()
					if k < 0.4 then
						Props.OakLite(forest, g, rng, rng:NextNumber(0.9, 1.2))
					elseif k < 0.75 then
						Props.Fir(forest, g, rng, rng:NextNumber(0.9, 1.3))
					else
						Props.Birch(forest, g, rng, 1, k < 0.88 and Props.Palettes.blossom or Props.Palettes.magic)
					end
					if rng:NextNumber() < 0.5 then
						Props.Bush(forest, g + Vector3.new(rng:NextNumber(-5, 5), 0, rng:NextNumber(-5, 5)), rng, rng:NextNumber(0.8, 1.2))
					end
				end
			end
		end
		local meadow = C + Vector3.new(math.cos(mid) * 105, 0, math.sin(mid) * 105)
		if w ~= 0 and w ~= 4 then
			Props.Flowers(forest, meadow, rng, 7, 6)
		end
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		Props.Fireflies(f, C + Vector3.new(math.cos(a) * 300, 8, math.sin(a) * 300), Vector3.new(90, 12, 90), 5)
	end
	Props.Fireflies(f, C + Vector3.new(0, 8, 0), Vector3.new(70, 10, 70), 3, Color3.fromRGB(200, 230, 255))
end

-- Caminos de la plaza a cada parcela
local function buildRoads(C, rng, f)
	for i = 1, 8 do
		local cf = World.PlotCenters[i]
		local entrance = plotWorld(cf, 0, -PlotLayout.Half - 4)
		local dir = (Vector3.new(entrance.X, 0, entrance.Z) - C).Unit
		local start = C + dir * 40
		-- pequeña curva natural
		local mid = (start + entrance) / 2 + Vector3.new(-dir.Z, 0, dir.X) * rng:NextNumber(-8, 8)
		Terrain.Path({ start, mid, entrance }, 8, Mat.Ground)
		local side = Vector3.new(-dir.Z, 0, dir.X)
		Props.Flowers(f, mid + side * 7, rng, 5, 1.4)
		Props.Bush(f, mid - side * 8, rng, 0.9)
		Props.Sign(f, CFrame.lookAt(start + dir * 12 + side * 6, start + side * 6), "Parcela " .. i, 5)
	end
end

function Home.Build(world, rootFolder)
	World = world
	World.PlotPortals = World.PlotPortals or {}
	local f = folder("Hogar", rootFolder)
	local C = World.HOME
	local rng = Random.new(2026)
	Lighting.Setup()
	Terrain.Init()
	Terrain.Ground(C, 920, 920, Mat.Grass, 24)

	buildPlaza(f, C, rng)
	portal(f, C + Vector3.new(29, 0, 0), math.rad(90), "Minas de Zuar", Color3.fromRGB(255, 170, 70), "mines")
	portal(f, C + Vector3.new(-29, 0, 0), math.rad(-90), "Reino de los PETs", Color3.fromRGB(170, 120, 255), "realm")

	local plots = folder("Parcelas", f)
	for i = 1, 8 do
		local a = (i - 1) / 8 * math.pi * 2 + math.pi / 8
		local c = C + Vector3.new(math.cos(a) * PlotLayout.Radius, 0, math.sin(a) * PlotLayout.Radius)
		local cf = CFrame.lookAt(c, Vector3.new(C.X, 0, C.Z))
		World.PlotCenters[i] = cf
		buildPlot(plots, i, cf, Random.new(500 + i))
	end
	buildRoads(C, rng, f)
	buildOuterForest(f, C, rng)
	World.Spawns.forest = CFrame.new(C + Vector3.new(0, 4, 262))
end

return Home
