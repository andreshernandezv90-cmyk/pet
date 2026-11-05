-- World/Home: el Santuario (Hogar Dimensional).
--   * Terreno natural con colinas suaves y caminos de tierra.
--   * Plaza central: punto de reunion con el GRAN PORTAL DIMENSIONAL, el unico
--     acceso al Mundo PET.
--   * 8 parcelas: cada una es un claro dentro de un pequeño bosque, con cesped
--     corto y limpio, caminos claros, areas de trabajo con suelo, borde y
--     letrero propios, arboles talables, fogata y estanque. (La casa y las
--     estaciones son dinamicas y las construye Plots segun el progreso.)
--   * Bosque exterior con arboles talables, colinas y luciernagas.

local H = require(script.Parent.Helpers)
local Terrain = require(script.Parent.Terrain)
local Props = require(script.Parent.Props)
local PlotLayout = require(script.Parent.PlotLayout)
local Lighting = require(script.Parent.Lighting)

local folder, billboard, makeNode = H.Folder, H.Billboard, H.MakeNode
local Part, Blob, Disc, Column = Props.Part, Props.Blob, Props.Disc, Props.Column
local Mat = Enum.Material

local World
local Home = {}

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

-- Plaza central: gran portal dimensional y punto social --------------------------------------

local CENTRAL_COLOR = Color3.fromRGB(160, 110, 255)
Home.PlazaRadius = 62

local function buildPlaza(f, C, rng)
	Terrain.Disc(C, Home.PlazaRadius, Mat.Cobblestone)
	Terrain.Disc(C, 30, Mat.Pavement)
	local pm = Instance.new("Model")
	pm.Name = "PortalCentral"
	pm.Parent = f
	Disc(pm, C + Vector3.new(0, 0.25, 0), 40, 0.5, Color3.fromRGB(150, 144, 160), Mat.Slate, { CanCollide = true })
	Disc(pm, C + Vector3.new(0, 0.55, 0), 41, 0.12, Color3.fromRGB(170, 130, 255), Mat.Neon, { CastShadow = false, Transparency = 0.35 })
	local _, gate = Props.Portal(pm, CFrame.new(C + Vector3.new(0, 0.5, 0)), CENTRAL_COLOR, rng, 2.1)
	-- Obeliscos con cristales alrededor del portal
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + math.pi / 6
		local base = C + Vector3.new(math.cos(a) * 17, 0.5, math.sin(a) * 17)
		for k = 0, 2 do
			Part(pm, CFrame.new(base + Vector3.new(0, 0.9 + k * 1.7, 0)) * CFrame.Angles(0, a + k * 0.3, 0), Vector3.new(2.6 - k * 0.5, 1.8, 2.6 - k * 0.5),
				Props.Vary(Color3.fromRGB(132, 124, 150), rng, 0.06), Mat.Slate, { CanCollide = true })
		end
		local cr = Part(pm, CFrame.new(base + Vector3.new(0, 6.6, 0)) * CFrame.Angles(0.3, a, 0.2), Vector3.new(1.1, 2.6, 1.1), CENTRAL_COLOR:Lerp(
			Color3.new(1, 1, 1), 0.3), Mat.Neon, { CastShadow = false })
		if i % 2 == 0 then
			local l = Instance.new("PointLight")
			l.Color = CENTRAL_COLOR
			l.Range = 12
			l.Brightness = 0.8
			l.Parent = cr
		end
	end
	-- Cristales que orbitan el portal (giran en el cliente)
	local orbit = Instance.new("Model")
	orbit.Name = "Orbita"
	orbit.Parent = pm
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local p = Part(orbit, CFrame.new(C + Vector3.new(math.cos(a) * 12, 20 + math.sin(a * 2) * 2, math.sin(a) * 12)) * CFrame.Angles(a, a, 0),
			Vector3.new(0.8, 1.6, 0.8), Color3.fromRGB(220, 200, 255), Mat.Neon, { CastShadow = false })
		if i == 0 then
			orbit.PrimaryPart = p
		end
	end
	orbit.WorldPivot = CFrame.new(C)
	game:GetService("CollectionService"):AddTag(orbit, "SpinY")
	-- Particulas que suben desde el estrado
	local motes = Part(pm, CFrame.new(C + Vector3.new(0, 1, 0)), Vector3.new(30, 0.2, 30), Color3.new(1, 1, 1), Mat.SmoothPlastic,
		{ Transparency = 1, CanQuery = false, CastShadow = false })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(210, 180, 255))
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(2.5, 4)
	e.Rate = 6
	e.Speed = NumberRange.new(2, 4)
	e.SpreadAngle = Vector2.new(10, 10)
	e.EmissionDirection = Enum.NormalId.Top
	pcall(function()
		e.Shape = Enum.ParticleEmitterShape.Box
	end)
	e.Parent = motes
	-- Activador a nivel del suelo (la superficie del portal esta muy alta para el ProximityPrompt)
	local trigger = Part(pm, CFrame.new(C + Vector3.new(0, 3, -4)), Vector3.new(14, 5, 6), Color3.new(1, 1, 1), Mat.SmoothPlastic,
		{ Transparency = 1, CanQuery = false, CastShadow = false, Name = "PortalTrigger" })
	billboard(gate, "Portal Dimensional\nMundo PET", Color3.fromRGB(230, 210, 255), 380, 18, 260)
	local pp = H.AddPrompt(trigger, "Viajar al Mundo PET", "Portal Dimensional", 0, 16)
	pp.Name = "PortalCentralPrompt"
	-- Unico acceso al Mundo PET: lleva al campamento de bienvenida
	pp:SetAttribute("Dest", "world")
	table.insert(World.Portals, { prompt = pp, dest = "world", central = true })
	World.CentralPortal = pm

	-- Anillo social: bancos, faroles, maceteros y tablon de avisos
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		-- k = 6 es el eje sur: queda libre la vista del punto de aparicion al portal
		if k ~= 6 then
			Props.Lantern(f, C + dir * 56, rng, 7)
		end
		local bc = CFrame.lookAt(C + dir * 34, C)
		local bench = Instance.new("Model")
		bench.Name = "Banco"
		bench.Parent = k ~= 6 and f or nil
		Part(bench, bc * CFrame.new(0, 1.4, 0), Vector3.new(5, 0.35, 1.6), Color3.fromRGB(160, 116, 74), Mat.WoodPlanks, { CanCollide = true })
		Part(bench, bc * CFrame.new(0, 2.3, 0.75) * CFrame.Angles(-0.2, 0, 0), Vector3.new(5, 1.2, 0.25), Color3.fromRGB(150, 108, 70), Mat.WoodPlanks)
		for _, sx in ipairs({ -2, 2 }) do
			Part(bench, bc * CFrame.new(sx, 0.6, 0), Vector3.new(0.5, 1.2, 1.4), Color3.fromRGB(120, 116, 112), Mat.Slate)
		end
		local pot = C + Vector3.new(math.cos(a + 0.2), 0, math.sin(a + 0.2)) * 46
		Column(f, pot, 1.2, 3, Color3.fromRGB(180, 110, 80), Mat.Slate)
		Props.Flowers(f, pot + Vector3.new(0, 1.2, 0), rng, 5, 1)
	end
	-- Punto de aparicion inicial (se redirige a la parcela al cargar el perfil)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnHogar"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.Position = C + Vector3.new(0, 0.2, -44)
	spawn.Color = Color3.fromRGB(170, 160, 210)
	spawn.Material = Mat.Slate
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Transparency = 0.2
	spawn.Parent = f
	World.Spawns.hub = CFrame.lookAt(C + Vector3.new(0, 4, -44), C + Vector3.new(0, 4, 0))
	local board = Props.Sign(f, CFrame.lookAt(C + Vector3.new(14, 0, -48), C + Vector3.new(14, 0, -70)),
		"Santuario\nPortal al Mundo PET ↑ · Parcelas por los caminos", 9)
	board.Name = "TablonPlaza"
end

-- Parcela -----------------------------------------------------------------------------------

local function plotWorld(cf, x, z)
	return (cf * CFrame.new(x, 0, z)).Position
end

local AREA_FLOOR = { Pavement = Mat.Pavement, Mud = Mat.Mud }
local AREA_RING = {
	extractores = Color3.fromRGB(150, 150, 165),
	resonancia = Color3.fromRGB(150, 110, 210),
	alquimia = Color3.fromRGB(90, 190, 140),
}

local function buildAreas(pf, cf, rng, W)
	for _, area in ipairs(PlotLayout.Areas) do
		if area.rect then
			local r = area.rect
			workspace.Terrain:FillBlock(cf * CFrame.new((r[1] + r[3]) / 2, -2, (r[2] + r[4]) / 2), Vector3.new(r[3] - r[1], 4, r[4] - r[2]),
				AREA_FLOOR[area.floor] or Mat.Pavement)
			if area.curb or area.fence then
				local edges = {
					x0 = { { r[1], r[2] }, { r[1], r[4] } },
					x1 = { { r[3], r[2] }, { r[3], r[4] } },
					z0 = { { r[1], r[2] }, { r[3], r[2] } },
					z1 = { { r[1], r[4] }, { r[3], r[4] } },
				}
				for side, e in pairs(edges) do
					local segs = { e }
					local gap = area.gap
					if gap and gap.side == side then
						local alongX = side == "z0" or side == "z1"
						if alongX then
							segs = { { e[1], { gap.from, e[1][2] } }, { { gap.to, e[1][2] }, e[2] } }
						else
							segs = { { e[1], { e[1][1], gap.from } }, { { e[1][1], gap.to }, e[2] } }
						end
					end
					for _, sg in ipairs(segs) do
						local a, b = W(sg[1][1], sg[1][2]), W(sg[2][1], sg[2][2])
						if (b - a).Magnitude > 0.8 then
							if area.fence then
								Props.Picket(pf, a, b, rng)
							else
								Props.Curb(pf, a, b, rng)
							end
						end
					end
				end
			end
		elseif area.deck then
			local d = area.deck
			local dcf = cf * CFrame.new(d[1], 0, d[2])
			Part(pf, dcf * CFrame.new(0, 0.25, 0), Vector3.new(d[3], 0.5, d[4]), Color3.fromRGB(156, 114, 74), Mat.WoodPlanks, { CanCollide = true })
			for _, e in ipairs({ { -1, -1, 1, -1 }, { 1, -1, 1, 1 }, { 1, 1, -1, 1 }, { -1, 1, -1, -1 } }) do
				Props.Beam(pf, (dcf * CFrame.new(e[1] * d[3] / 2, 0.45, e[2] * d[4] / 2)).Position,
					(dcf * CFrame.new(e[3] * d[3] / 2, 0.45, e[4] * d[4] / 2)).Position, 0.6, Color3.fromRGB(100, 72, 50), Mat.Wood)
			end
		end
		local sg = area.sign
		local pos = W(sg[1], sg[2])
		local look = (cf * CFrame.new(sg[3], 0, sg[4])).Position - (cf * CFrame.new(0, 0, 0)).Position
		local scf = CFrame.lookAt(pos, pos + look)
		if area.arch then
			Props.ArchSign(pf, scf, area.label, 7.5)
		else
			Props.Sign(pf, scf, area.label, 6.5)
		end
	end
	-- Plataformas claras bajo cada estacion (con anillo de color por area)
	for id, s in pairs(PlotLayout.Spots) do
		if s.r and id ~= "almacen" and id ~= "taller" then
			local ring = AREA_RING.extractores
			if id == "reactor" or id == "fusionlab" then
				ring = AREA_RING.resonancia
			elseif id == "alchemy" or id == "bait" then
				ring = AREA_RING.alquimia
			end
			Disc(pf, W(s.x, s.z) + Vector3.new(0, 0.1, 0), s.r * 2 + 1.6, 0.2, ring, Mat.Slate, { CanCollide = true, CastShadow = false })
			Disc(pf, W(s.x, s.z) + Vector3.new(0, 0.16, 0), s.r * 2, 0.2, Color3.fromRGB(208, 202, 190), Mat.Pavement, { CastShadow = false })
		end
	end
end

local function buildPlot(f, i, cf, rng)
	local pf = folder("Parcela" .. i, f)
	local half, usable = PlotLayout.Half, PlotLayout.Usable
	local function W(x, z)
		return plotWorld(cf, x, z)
	end
	-- Suelo: cesped corto y limpio en todo el interior transitable; el pasto alto
	-- (material Grass) queda solo en el borde boscoso
	workspace.Terrain:FillBlock(cf * CFrame.new(0, -2, 0), Vector3.new(usable * 2 + 4, 4, usable * 2 + 4), Mat.LeafyGrass)
	-- Caminos de tierra
	for _, path in ipairs(PlotLayout.Paths) do
		local pts = {}
		for _, p in ipairs(path.points) do
			table.insert(pts, W(p[1], p[2]))
		end
		Terrain.Path(pts, path.width, Mat.Ground)
	end
	-- Areas de trabajo: suelo, borde, plataformas y letreros
	buildAreas(pf, cf, rng, W)
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
		if decor >= 10 then
			break
		end
		local x = rng:NextNumber(-usable + 2, usable - 2)
		local z = rng:NextNumber(-usable + 2, usable - 2)
		if not PlotLayout.IsReserved(x, z, 4.5) and free(x, z, 6) then
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
	-- Fogata frente a la casa (punto acogedor del santuario)
	local cfp = PlotLayout.Campfire
	Props.Campfire(pf, W(cfp.x, cfp.z), rng)
	-- Luciernagas sobre la parcela
	Props.Fireflies(pf, W(0, 0) + Vector3.new(0, 7, 0), Vector3.new(90, 10, 90), 2)
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
			local r = rng:NextNumber(Home.PlazaRadius + 10, 265)
			local nearPortals = r < Home.PlazaRadius + 12
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
		local start = C + dir * (Home.PlazaRadius - 4)
		-- pequeña curva natural
		local mid = (start + entrance) / 2 + Vector3.new(-dir.Z, 0, dir.X) * rng:NextNumber(-8, 8)
		Terrain.Path({ start, mid, entrance }, 8, Mat.Ground)
		local side = Vector3.new(-dir.Z, 0, dir.X)
		Props.Flowers(f, mid + side * 7, rng, 5, 1.4)
		Props.Bush(f, mid - side * 8, rng, 0.9)
		Props.Sign(f, CFrame.lookAt(start + dir * 14 + side * 6.5, start + side * 6.5), "Parcela " .. i, 5)
	end
end

function Home.Build(world, rootFolder)
	World = world
	local f = folder("Hogar", rootFolder)
	local C = World.HOME
	local rng = Random.new(2026)
	Lighting.Setup()
	Terrain.Init()
	Terrain.Ground(C, 920, 920, Mat.Grass, 24)

	buildPlaza(f, C, rng)

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
