-- World/PetWorld: el Mundo PET, un unico bosque largo y continuo (GDD 1.1b,
-- docs/MUNDO_PET_LAYOUT.md). De oeste a este:
--   Campamento (portal de regreso, Comerciante, Guia, Tienda premium, arena)
--   Zona 1 | barrera | Zona 2 | barrera | Zona 3 | barrera | Zona 4 | barrera | Zona 5
-- Norte: montaña con las bocas de mina; cada una lleva a su galeria de las Minas de Zuar.
-- Sur: bosque denso con senderos, retos opcionales y cofres.
-- Coordenadas locales: x = avance (0..2550), z = norte (+) / sur (-).

local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Progression = require(Shared.Progression)
local PetCatalog = require(Shared.PetCatalog)
local Items = require(Shared.Items)
local WorldConfig = require(Shared.WorldConfig)

local H = require(script.Parent.Helpers)
local Terrain = require(script.Parent.Terrain)
local Props = require(script.Parent.Props)

local folder, billboard, makeNode = H.Folder, H.Billboard, H.MakeNode
local Part, Blob, Disc, Column = Props.Part, Props.Blob, Props.Disc, Props.Column
local Mat = Enum.Material

local PetWorld = {}
local World

PetWorld.Origin = Vector3.new(3000, 0, 1500)
-- Fase C.1: mundo compacto (~1530 studs). Ajustable aqui: todo se recalcula.
PetWorld.CampLength = 140
PetWorld.Lengths = { 250, 260, 270, 280, 330 }
PetWorld.HalfWidth = 160
local O = PetWorld.Origin

-- Rangos de cada zona en x local
PetWorld.ZoneStart = {}
PetWorld.ZoneEnd = {}
do
	local x = PetWorld.CampLength
	for k, L in ipairs(PetWorld.Lengths) do
		PetWorld.ZoneStart[k] = x
		PetWorld.ZoneEnd[k] = x + L
		x = x + L
	end
	PetWorld.TotalLength = x
end
-- Arenas de incursion: una por zona, junto al camino principal
PetWorld.ArenaSpecs = {
	{ name = "Arena del Sakura", r = 30, at = 0.3 },
	{ name = "Coliseo Mecanico", r = 30, at = 0.3 },
	{ name = "Circulo de las Esporas", r = 31, at = 0.3 },
	{ name = "Arena del Cristal", r = 32, at = 0.3 },
	{ name = "Altar del Eclipse", r = 36, at = 0.3 },
}

function PetWorld.PathZ(x)
	return math.sin(x / 105) * 30
end
local PathZ = PetWorld.PathZ

local function W(x, z, y)
	return O + Vector3.new(x, y or 0, z)
end
PetWorld.W = W

-- Zona por coordenada local (0 = campamento, nil = fuera)
function PetWorld.LocalArea(lx, lz)
	if lx < -70 or lx > PetWorld.TotalLength + 70 or lz < -260 or lz > 520 then
		return nil
	end
	if lx < PetWorld.CampLength then
		return "camp"
	end
	for k = 1, 5 do
		if lx < PetWorld.ZoneEnd[k] or k == 5 then
			return "z" .. k
		end
	end
	return nil
end

-- Estilo visual por zona
local STYLE = {
	[1] = { meadow = Mat.LeafyGrass, palette = "forest", light = Color3.fromRGB(230, 255, 150) },
	[2] = { meadow = Mat.Sand, palette = "autumn", light = Color3.fromRGB(255, 220, 140) },
	[3] = { meadow = Mat.Slate, palette = "shadow", light = Color3.fromRGB(120, 255, 230) },
	[4] = { meadow = Mat.Limestone, palette = "garden", light = Color3.fromRGB(190, 255, 220) },
	[5] = { meadow = Mat.Salt, palette = "eclipse", light = Color3.fromRGB(220, 190, 255) },
}

local MATERIAL_COLORS = {
	{ Mat.Sand, Color3.fromRGB(214, 190, 126) },
	{ Mat.Slate, Color3.fromRGB(78, 104, 100) },
	{ Mat.Limestone, Color3.fromRGB(150, 208, 172) },
	{ Mat.Salt, Color3.fromRGB(176, 160, 214) },
}

-- Exclusiones para no poner arboles encima de caminos, retos, faros o barreras
local exclusions = {}
local function exclude(x0, z0, x1, z1)
	table.insert(exclusions, { x0, z0, x1, z1 })
end
local function excluded(x, z)
	for _, e in ipairs(exclusions) do
		if x >= e[1] and x <= e[3] and z >= e[2] and z <= e[4] then
			return true
		end
	end
	return false
end

-- Terreno -------------------------------------------------------------------------------------

local function buildTerrain(rng)
	for _, c in ipairs(MATERIAL_COLORS) do
		pcall(function()
			workspace.Terrain:SetMaterialColor(c[1], c[2])
		end)
	end
	local total = PetWorld.TotalLength
	Terrain.Ground(W(total / 2, 120), total + 180, 780, Mat.Grass, 30)
	-- Praderas centrales con material propio de cada zona
	workspace.Terrain:FillBlock(CFrame.new(W(PetWorld.CampLength / 2, 0, -2)), Vector3.new(PetWorld.CampLength + 40, 4, 200), Mat.LeafyGrass)
	for k = 1, 5 do
		local x0, x1 = PetWorld.ZoneStart[k], PetWorld.ZoneEnd[k]
		-- suelo tematico en todo el ancho de la zona (identidad visual); la zona 1
		-- conserva pasto animado corto en los bordes boscosos
		if k > 1 then
			workspace.Terrain:FillBlock(CFrame.new(W((x0 + x1) / 2, -2, -2)), Vector3.new(x1 - x0, 4, 372), STYLE[k].meadow)
		else
			workspace.Terrain:FillBlock(CFrame.new(W((x0 + x1) / 2, 2, -2)), Vector3.new(x1 - x0, 4, 190), STYLE[k].meadow)
		end
	end
	-- Camino principal serpenteante
	local pts = {}
	for x = 20, total + 10, 30 do
		table.insert(pts, W(x, PathZ(x)))
	end
	Terrain.Path(pts, 12, Mat.Ground)
	-- Montaña al norte (donde estaran las minas): faldas irregulares + cumbres
	for x = -40, total + 40, 26 do
		local mat = rng:NextNumber() < 0.55 and Mat.Rock or Mat.LeafyGrass
		workspace.Terrain:FillBall(W(x + rng:NextNumber(-8, 8), 216 + rng:NextNumber(0, 14), -12), rng:NextNumber(36, 48), mat)
	end
	for x = -40, total + 40, 55 do
		local mat = rng:NextNumber() < 0.6 and Mat.Rock or Mat.LeafyGrass
		workspace.Terrain:FillBall(W(x + rng:NextNumber(-15, 15), 300 + rng:NextNumber(-20, 30), -30), rng:NextNumber(100, 125), mat)
	end
	-- Loma rocosa al sur y muros de roca en los extremos
	for x = -40, total + 40, 26 do
		workspace.Terrain:FillBall(W(x + rng:NextNumber(-8, 8), -214 + rng:NextNumber(-6, 0), -14), rng:NextNumber(32, 40),
			rng:NextNumber() < 0.6 and Mat.Rock or Mat.Grass)
	end
	workspace.Terrain:FillBlock(CFrame.new(W(-58, 120, 20)), Vector3.new(40, 40, 760), Mat.Rock)
	workspace.Terrain:FillBlock(CFrame.new(W(total + 58, 120, 20)), Vector3.new(40, 40, 760), Mat.Rock)
	-- Algunos montículos suaves en el bosque sur, cerca del acantilado
	for x = 60, total, 140 do
		Terrain.Hill(W(x + rng:NextNumber(-30, 30), -176), 26, 7, Mat.Grass)
	end
end

-- Limites invisibles (la roca podria escalarse en pendientes)
local function buildBounds(f)
	local total = PetWorld.TotalLength
	local function wall(cx, cz, sx, sz)
		Part(f, CFrame.new(W(cx, cz, 60)), Vector3.new(sx, 140, sz), Color3.new(1, 1, 1), Mat.SmoothPlastic,
			{ Transparency = 1, CanCollide = true, CanQuery = false, CastShadow = false, Name = "Limite" })
	end
	wall(total / 2, 174, total + 160, 4)
	wall(total / 2, -180, total + 160, 4)
	wall(-44, 0, 4, 360)
	wall(total + 44, 0, 4, 360)
end

-- Vegetacion por zona --------------------------------------------------------------------------

local function zoneTree(parent, k, pos, rng)
	local pal = Props.Palettes[STYLE[k].palette]
	local r = rng:NextNumber()
	local s = rng:NextNumber(0.9, 1.3)
	if k == 1 then
		if r < 0.45 then
			Props.OakLite(parent, pos, rng, s, pal)
		elseif r < 0.65 then
			Props.Oak(parent, pos, rng, s, pal)
		elseif r < 0.88 then
			Props.Birch(parent, pos, rng, s, Props.Palettes.blossom)
		else
			Props.Fir(parent, pos, rng, s)
		end
	elseif k == 2 then
		if r < 0.5 then
			Props.OakLite(parent, pos, rng, s, pal)
		elseif r < 0.82 then
			Props.Fir(parent, pos, rng, s)
		else
			Props.Birch(parent, pos, rng, s, Props.Palettes.autumn)
		end
	elseif k == 3 then
		if r < 0.45 then
			Props.OakLite(parent, pos, rng, s * 1.1, pal)
		elseif r < 0.8 then
			Props.Fir(parent, pos, rng, s * 1.1)
		else
			Props.Mushroom(parent, pos, rng, rng:NextNumber(3.5, 5), true, Color3.fromRGB(110, 230, 210))
		end
	elseif k == 4 then
		if r < 0.45 then
			Props.OakLite(parent, pos, rng, s, pal)
		elseif r < 0.75 then
			Props.Birch(parent, pos, rng, s, Props.Palettes.magic)
		elseif r < 0.92 then
			Props.GiantFlower(parent, pos, rng)
		else
			Props.Fir(parent, pos, rng, s)
		end
	else
		if r < 0.5 then
			Props.OakLite(parent, pos, rng, s, pal)
		elseif r < 0.78 then
			Props.Birch(parent, pos, rng, s, pal)
		elseif r < 0.92 then
			Props.Fir(parent, pos, rng, s)
		else
			Props.Crystal(parent, pos, rng, Color3.fromRGB(200, 160, 255), 1.4)
		end
	end
end

-- Llena una banda de bosque entre x0..x1 y z0..z1. Devuelve posiciones libres (para regalos).
local function forestBand(parent, k, x0, x1, z0, z1, rng, count)
	local placed = {}
	local tries = 0
	while #placed < count and tries < count * 12 do
		tries = tries + 1
		local x = rng:NextNumber(x0, x1)
		local z = rng:NextNumber(z0, z1)
		local ok = not excluded(x, z)
		if ok then
			for _, p in ipairs(placed) do
				if (p[1] - x) ^ 2 + (p[2] - z) ^ 2 < 81 then
					ok = false
					break
				end
			end
		end
		if ok then
			table.insert(placed, { x, z })
			zoneTree(parent, k, W(x, z), rng)
		end
	end
	-- huecos libres para regalos
	local spots = {}
	for _ = 1, 160 do
		if #spots >= 18 then
			break
		end
		local x = rng:NextNumber(x0 + 6, x1 - 6)
		local z = rng:NextNumber(z0 + 4, z1 - 4)
		local ok = not excluded(x, z)
		if ok then
			for _, p in ipairs(placed) do
				if (p[1] - x) ^ 2 + (p[2] - z) ^ 2 < 36 then
					ok = false
					break
				end
			end
		end
		if ok then
			table.insert(spots, W(x, z))
		end
	end
	return spots
end

-- Barreras y puertas --------------------------------------------------------------------------

local function buildBarrier(f, k, rng)
	local bx = PetWorld.ZoneStart[k]
	local Z = Progression.Zones[k]
	local m = Instance.new("Model")
	m.Name = "Barrera" .. k
	m.Parent = f
	local sheet = Part(m, CFrame.new(W(bx, 1, 20)), Vector3.new(1.6, 40, 356), Z.color, Mat.ForceField,
		{ CanCollide = true, CastShadow = false, Transparency = 0.5, Name = "Cortina" })
	sheet:SetAttribute("Zone", k)
	CollectionService:AddTag(sheet, "ZoneBarrier")
	Part(m, CFrame.new(W(bx, 1, 0.1)), Vector3.new(1.4, 0.2, 356), Z.color:Lerp(Color3.new(1, 1, 1), 0.3), Mat.Neon,
		{ CastShadow = false, Name = "Linea" })
	local gz = PathZ(bx)
	for z = -172, 172, 24 do
		if math.abs(z - gz) > 12 then
			local p = W(bx, z)
			Part(m, CFrame.new(p + Vector3.new(0, 4, 0)) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Vector3.new(2.6, 8, 2.6),
				Props.Vary(Color3.fromRGB(120, 114, 134), rng, 0.06), Mat.Slate, { CanCollide = true })
			Part(m, CFrame.new(p + Vector3.new(0, 8.8, 0)) * CFrame.Angles(0.5, 0.6, 0.3), Vector3.new(1, 1.6, 1), Z.color, Mat.Neon,
				{ CastShadow = false })
		end
	end
	-- Puerta en arco sobre el camino
	for _, s in ipairs({ -1, 1 }) do
		local p = W(bx, gz + s * 9)
		for i = 0, 3 do
			Part(m, CFrame.new(p + Vector3.new(0, 1.8 + i * 3.6, 0)) * CFrame.Angles(0, i * 0.3, 0), Vector3.new(4 - i * 0.3, 3.6, 4 - i * 0.3),
				Props.Vary(Color3.fromRGB(140, 132, 156), rng, 0.05), Mat.Slate, { CanCollide = true })
		end
	end
	Part(m, CFrame.new(W(bx, gz, 15.6)), Vector3.new(4, 2.2, 22), Color3.fromRGB(150, 142, 166), Mat.Slate)
	Blob(m, CFrame.new(W(bx, gz, 18.2)), Vector3.new(2.4, 2.8, 2.4), Z.color, Mat.Neon, { CastShadow = false })
	local board = Part(m, CFrame.new(W(bx - 1.3, gz, 10.5)), Vector3.new(0.4, 5.6, 15), Color3.fromRGB(70, 60, 90), Mat.Slate,
		{ Name = "Tablero" })
	for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
		local gui = Instance.new("SurfaceGui")
		gui.Name = face == Enum.NormalId.Left and "GateSignFront" or "GateSignBack"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 36
		gui.LightInfluence = 0
		gui.Parent = board
		local t = Instance.new("TextLabel")
		t.Name = "Text"
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, -16, 1, -10)
		t.Position = UDim2.new(0, 8, 0, 5)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.RichText = true
		t.TextColor3 = Color3.fromRGB(240, 235, 255)
		t.Text = "Zona " .. k .. " · " .. Z.name
		t.Parent = gui
	end
	board:SetAttribute("Zone", k)
	CollectionService:AddTag(board, "GateSign")
	exclude(bx - 9, -180, bx + 9, 180)
	World.BarrierX[k] = W(bx, 0).X
	World.Gates[k] = CFrame.lookAt(W(bx - 16, gz, 4), W(bx + 10, gz, 4))
end

-- Faros ---------------------------------------------------------------------------------------

local function buildBeacon(f, id, zone, lx, lz, rng)
	local color = zone and Progression.Zones[zone].color or Color3.fromRGB(200, 180, 255)
	local cf = CFrame.new(W(lx, lz))
	local m, crystal = Props.Beacon(f, cf, color, rng)
	m.Name = "Faro_" .. id
	crystal:SetAttribute("Beacon", id)
	CollectionService:AddTag(crystal, "BeaconCrystal")
	local pp = H.AddPrompt(m:FindFirstChildWhichIsA("BasePart"), "Faro de viaje", zone and ("Zona " .. zone) or "Campamento", 0, 12)
	pp:SetAttribute("Beacon", id)
	CollectionService:AddTag(pp, "BeaconPrompt")
	billboard(crystal, zone and ("Faro · Zona " .. zone) or "Faro · Campamento", color:Lerp(Color3.new(1, 1, 1), 0.4), 200, 3, 90)
	exclude(lx - 8, lz - 8, lx + 8, lz + 8)
	World.Beacons[id] = { id = id, zone = zone, model = m, prompt = pp }
	World.Spawns["beacon_" .. id] = CFrame.lookAt(W(lx + 6, lz - 4, 4), W(lx + 30, PathZ(lx + 30), 4))
end

-- Bocas de mina: cada zona del Reino conecta con su galeria de las Minas de Zuar --------

local function buildMineEntrance(f, k, rng)
	local L = PetWorld.Lengths[k]
	local mx = PetWorld.ZoneStart[k] + L * 0.45
	local region = WorldConfig.Regions[k]
	local cf = CFrame.lookAt(W(mx, 166), W(mx, 100))
	local m = Instance.new("Model")
	m.Name = "EntradaMina" .. k
	m.Parent = f
	local scale = k == 5 and 1.5 or 1
	local a, b = 9 * scale, 10 * scale
	for i = 0, 12 do
		local t = math.pi * i / 12
		local p = cf * CFrame.new(a * math.cos(t), b * math.sin(t), 0)
		Part(m, p * CFrame.Angles(0, 0, t + math.pi / 2) * CFrame.Angles(rng:NextNumber(-0.1, 0.1), 0, 0), Vector3.new(3.6, 3.4, 4.5) * scale,
			Props.Vary(Color3.fromRGB(116, 108, 104), rng, 0.08), Mat.Slate, { CanCollide = true })
	end
	-- marco de madera y boca oscura que lleva a la galeria de esta zona
	for _, sx in ipairs({ -1, 1 }) do
		Part(m, cf * CFrame.new(sx * 6 * scale, 4.5 * scale, -0.6), Vector3.new(1.2, 9 * scale, 1.2), Color3.fromRGB(100, 72, 50), Mat.Wood)
	end
	Part(m, cf * CFrame.new(0, 9 * scale, -0.6), Vector3.new(13.5 * scale, 1.2, 1.2), Color3.fromRGB(100, 72, 50), Mat.Wood)
	local mouth = Part(m, cf * CFrame.new(0, 4.5 * scale, 0.6), Vector3.new(12 * scale, 9 * scale, 0.6), Color3.fromRGB(26, 22, 24),
		Mat.SmoothPlastic, { CanCollide = true, Name = "Boca" })
	for _, sx in ipairs({ -1.6, 1.6 }) do
		Part(m, cf * CFrame.new(sx, 0.15, -4), Vector3.new(0.3, 0.3, 8), Color3.fromRGB(90, 84, 80), Mat.Metal)
	end
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Entrar"
	pp.ObjectText = region.mine.name
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Dest", "m" .. k)
	pp.Parent = mouth
	table.insert(World.Portals, { prompt = pp, dest = "m" .. k })
	Props.Lantern(m, (cf * CFrame.new(8 * scale, 0, -3)).Position, rng, 5)
	local minerals = {}
	for _, res in ipairs({ "piedra", "cobre", "hierro", "lunar", "zuarita" }) do
		local c = region.mine.chances[res]
		if c and c > 0 then
			table.insert(minerals, Items.Resources[res].icon .. " " .. math.floor(c * 100 + 0.5) .. "%")
		end
	end
	Props.Sign(m, cf * CFrame.new(-11 * scale, 0, -4), region.mine.name .. "\n" .. table.concat(minerals, "  ") .. "\nEntrada a las Minas de Zuar", 10)
	exclude(mx - 16, 92, mx + 16, 180)
	World.MineEntrances[k] = cf
	World.Spawns["minegate_z" .. k] = CFrame.lookAt(W(mx, 150, 4), W(mx, 100, 4))
	-- sendero desde el camino principal
	Terrain.Path({ W(mx, PathZ(mx)), W(mx + 6, 120), W(mx, 158) }, 7, Mat.Ground)
end

-- Retos opcionales de parkour en el bosque sur -------------------------------------------
-- Cinco recorridos con mecanicas distintas. Cada paso se registra en
-- World.Challenges[k].steps (centro superior, media anchura, rebote) para poder
-- comprobar en las pruebas que todos los saltos son alcanzables.

local function checkpoint(parent, pos, zone, index, final)
	local cp = Part(parent, CFrame.new(pos + Vector3.new(0, 0.25, 0)), Vector3.new(5, 0.4, 5), Color3.fromRGB(90, 255, 140), Mat.Neon,
		{ Transparency = 0.3, CanCollide = false, CanTouch = true, Name = "Checkpoint" })
	cp:SetAttribute("Zone", zone)
	cp:SetAttribute("Index", index)
	table.insert(World.Checkpoints, { part = cp, zone = zone, index = index, meadow = final, pos = pos })
	return cp
end

local TITLES = {
	"Reto de los Troncos",
	"Reto de los Engranajes",
	"Reto de los Hongos Saltarines",
	"Reto del Cristal Helado",
	"Reto de las Plataformas Flotantes",
}
local MECHANIC = { "troncos", "engranajes", "rebote", "hielo", "temporales" }

local function courseFinish(cf, k, endPos, supported, ch)
	Part(cf, CFrame.new(endPos - Vector3.new(0, 1, 0)), Vector3.new(11, 2, 11), Color3.fromRGB(200, 190, 160), Mat.Cobblestone,
		{ CanCollide = true, Name = "Meta" })
	if supported then
		Column(cf, endPos - Vector3.new(0, endPos.Y, 0), math.max(0.5, endPos.Y - 2), 2.2, Color3.fromRGB(110, 90, 70), Mat.Wood, { CanCollide = true })
	end
	checkpoint(cf, endPos, k, 99, true)
	local chest = Part(cf, CFrame.new(endPos + Vector3.new(3, 1.5, 0)), Vector3.new(4, 3, 3), Color3.fromRGB(200, 150, 60), Mat.Wood,
		{ CanCollide = true, Name = "CofreSecreto" })
	Part(cf, CFrame.new(endPos + Vector3.new(3, 3.4, 0)), Vector3.new(4.2, 1, 3.2), Color3.fromRGB(230, 190, 70), Mat.Metal)
	CollectionService:AddTag(chest, "SecretChest")
	local pp = H.AddPrompt(chest, "Abrir", "Cofre del reto", 1, 10)
	World.Chests[k] = { part = chest, prompt = pp }
	table.insert(ch.steps, { pos = endPos, half = 5.5 })
	ch.finish = endPos
end

local function buildChallenge(f, k, rng)
	local L = PetWorld.Lengths[k]
	local x0 = PetWorld.ZoneStart[k] + L * 0.58
	local x1 = PetWorld.ZoneStart[k] + L * 0.92
	local zc = -128
	exclude(x0 - 14, -170, x1 + 16, -96)
	local cf = folder("Reto" .. k, f)
	cf:SetAttribute("Mechanic", MECHANIC[k])
	Terrain.Path({ W(x0 - 10, PathZ(x0 - 10)), W(x0 - 12, -80), W(x0 - 6, zc + 4) }, 6, Mat.Ground)
	Props.Sign(cf, CFrame.lookAt(W(x0 - 16, -92), W(x0 - 16, -60)), TITLES[k] .. "\n(opcional · cofre al final)", 9)
	checkpoint(cf, W(x0 - 6, zc), k, 0, false)
	local ch = { mechanic = MECHANIC[k], steps = { { pos = W(x0 - 6, zc), half = 3 } } }
	World.Challenges[k] = ch
	local function step(pos, half, bounce)
		table.insert(ch.steps, { pos = pos, half = half, bounce = bounce })
	end
	local span = x1 - x0
	local TweenService = game:GetService("TweenService")

	if k == 1 then
		-- Troncos y ramas: tocones cada vez mas altos unidos por troncos caidos
		local n = 7
		local sp = span / n
		local prev
		local bark = Color3.fromRGB(116, 82, 56)
		for i = 1, n do
			local x = x0 + (i - 1) * sp
			local z = zc + ((i % 2 == 0) and 5 or -5)
			local h = 1.5 + i * 1.5
			local top = W(x, z, h)
			Column(cf, W(x, z), h, 5.2, Props.Vary(bark, rng, 0.08), Mat.Wood, { CanCollide = true })
			Disc(cf, top + Vector3.new(0, 0.02, 0), 4.6, 0.1, Color3.fromRGB(214, 180, 130), Mat.Wood)
			if prev then
				-- tronco caido que une los tocones: se camina encima
				Props.Beam(cf, prev + Vector3.new(0, 0.5, 0), top + Vector3.new(0, 0.5, 0), 2.2, Props.Vary(bark, rng, 0.1), Mat.Wood, { CanCollide = true })
				step((prev + top) / 2 + Vector3.new(0, 0.6, 0), (top - prev).Magnitude / 2 - 0.5)
			end
			step(top, 2.6)
			if i % 3 == 0 then
				local tip = top + Vector3.new(rng:NextNumber(-2, 2), 4, i % 2 == 0 and 6 or -6)
				Props.Beam(cf, top + Vector3.new(0, 1, 0), tip, 0.9, bark, Mat.Wood)
				Blob(cf, CFrame.new(tip + Vector3.new(0, 1, 0)), Vector3.new(5, 3.5, 5), Color3.fromRGB(120, 190, 90), Mat.SmoothPlastic)
			end
			if i == 4 then
				checkpoint(cf, top, k, i, false)
			end
			prev = top
		end
		-- gran rama final con copa
		local endPos = prev + Vector3.new(sp, 1.5, 0)
		Props.Beam(cf, prev + Vector3.new(0, 0.5, 0), endPos + Vector3.new(-4, -0.5, 0), 2.4, bark, Mat.Wood, { CanCollide = true })
		courseFinish(cf, k, endPos, true, ch)
		Blob(cf, CFrame.new(endPos + Vector3.new(0, 12, 0)), Vector3.new(18, 9, 18), Color3.fromRGB(110, 180, 90), Mat.SmoothPlastic)
		Blob(cf, CFrame.new(endPos + Vector3.new(4, 15, 3)), Vector3.new(10, 7, 10), Color3.fromRGB(250, 175, 205), Mat.SmoothPlastic)
	elseif k == 2 then
		-- Engranajes: discos dentados que giran y suben
		local n = 8
		local sp = span / n
		local prev
		for i = 1, n do
			local x = x0 + (i - 1) * sp
			local z = zc + math.sin(i * 1.3) * 5
			local h = 2 + i * 1.4
			local disc = Part(cf, CFrame.new(W(x, z, h - 0.4)) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.8, 8, 8),
				Props.Vary(Color3.fromRGB(196, 160, 90), rng, 0.06), Mat.Metal, { Shape = Enum.PartType.Cylinder, CanCollide = true, Name = "Engranaje" })
			for t = 0, 9 do
				local a = t / 10 * math.pi * 2
				local tooth = Part(cf, CFrame.new(W(x + math.cos(a) * 4.3, z + math.sin(a) * 4.3, h - 0.4)) * CFrame.Angles(0, -a, 0),
					Vector3.new(1.2, 0.7, 1), Color3.fromRGB(176, 140, 76), Mat.Metal, { Anchored = false, Massless = true })
				local w = Instance.new("WeldConstraint")
				w.Part0 = disc
				w.Part1 = tooth
				w.Parent = tooth
			end
			Column(cf, W(x, z), math.max(0.5, h - 1.4), 1.2, Color3.fromRGB(90, 86, 96), Mat.Metal, { CanCollide = true })
			if i % 2 == 0 then
				disc:SetAttribute("Gira", true)
				TweenService:Create(disc, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ CFrame = disc.CFrame * CFrame.Angles(math.rad(120), 0, 0) }):Play()
			elseif i % 3 == 0 then
				TweenService:Create(disc, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ CFrame = disc.CFrame + Vector3.new(0, 2.5, 0) }):Play()
			end
			step(W(x, z, h), 4)
			if i == 4 then
				checkpoint(cf, W(x, z, h), k, i, false)
			end
			prev = W(x, z, h)
		end
		Props.Gear(cf, W(x1 + 10, zc - 14), rng, 1.4)
		courseFinish(cf, k, prev + Vector3.new(sp, 1, 0), true, ch)
	elseif k == 3 then
		-- Hongos con rebote: cada sombrero luminoso impulsa a la siguiente cornisa
		local ledges = { { f = 0.25, h = 10 }, { f = 0.5, h = 19 }, { f = 0.75, h = 28 } }
		local base = W(x0, zc, 0)
		local prevTop = base
		for i, l in ipairs(ledges) do
			local lx = x0 + span * l.f
			-- el primer hongo esta en el suelo; los siguientes, sobre la cornisa anterior
			local padX = i == 1 and (lx - 9) or (x0 + span * ledges[i - 1].f + 4.5)
			local padTop = prevTop.Y + 2.5
			-- hongo saltarin
			local padPos = W(padX, zc, padTop)
			Column(cf, W(padX, zc, prevTop.Y), 2.5, 1.6, Color3.fromRGB(240, 230, 210), Mat.SmoothPlastic, { CanCollide = true })
			local pad = Part(cf, CFrame.new(padPos) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.5, 6, 6), Color3.fromRGB(110, 240, 210),
				Mat.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = true, CanTouch = true, Name = "HongoSaltarin" })
			pad:SetAttribute("Power", 80)
			CollectionService:AddTag(pad, "JumpPad")
			Blob(cf, CFrame.new(padPos - Vector3.new(0, 0.6, 0)), Vector3.new(7, 2.4, 7), Color3.fromRGB(80, 200, 180), Mat.SmoothPlastic,
				{ CastShadow = false })
			step(padPos, 3, true)
			-- cornisa: sombrero gigante plano
			local top = W(lx, zc, l.h)
			Column(cf, W(lx, zc), l.h - 0.5, 3, Color3.fromRGB(235, 225, 205), Mat.SmoothPlastic, { CanCollide = true })
			Disc(cf, top - Vector3.new(0, 0.3, 0), 12, 0.6, Color3.fromRGB(150, 110, 230), Mat.SmoothPlastic, { CanCollide = true })
			Blob(cf, CFrame.new(top - Vector3.new(0, 1.6, 0)), Vector3.new(13, 3.4, 13), Color3.fromRGB(130, 90, 210), Mat.SmoothPlastic,
				{ CastShadow = false })
			local glow = Instance.new("PointLight")
			glow.Color = Color3.fromRGB(160, 120, 255)
			glow.Range = 12
			glow.Parent = pad
			if i < #ledges then
				step(top, 6)
				if i == 1 then
					checkpoint(cf, top, k, 1, false)
				end
			else
				courseFinish(cf, k, top + Vector3.new(0, 0.6, 0), false, ch)
			end
			prevTop = top
		end
	elseif k == 4 then
		-- Cristales y plataformas heladas (resbaladizas) con un muro de hielo opcional
		local n = 8
		local sp = span / n
		local prev
		local icy = PhysicalProperties.new(0.9, 0.04, 0.1, 100, 1)
		for i = 1, n do
			local x = x0 + (i - 1) * sp
			local z = zc + ((i % 2 == 0) and 4 or -4)
			local h = 2 + i * 1.3
			if i % 2 == 1 then
				-- pilar de cristal
				Part(cf, CFrame.new(W(x, z, h / 2)) * CFrame.Angles(0, math.rad(45), 0), Vector3.new(4.4, h, 4.4), Color3.fromRGB(170, 225, 255),
					Mat.Glass, { Transparency = 0.25, CanCollide = true, Name = "PilarCristal" })
				Part(cf, CFrame.new(W(x, z, h + 0.15)) * CFrame.Angles(0, math.rad(45), 0), Vector3.new(4.6, 0.3, 4.6), Color3.fromRGB(200, 245, 255),
					Mat.Neon, { CastShadow = false })
				step(W(x, z, h + 0.3), 2.3)
			else
				-- losa de hielo resbaladiza
				Part(cf, CFrame.new(W(x, z, h - 0.4)), Vector3.new(6.5, 0.8, 6), Color3.fromRGB(190, 235, 255), Mat.Ice,
					{ CanCollide = true, CustomPhysicalProperties = icy, Name = "LosaHelada" })
				Column(cf, W(x, z), math.max(0.5, h - 0.8), 0.8, Color3.fromRGB(150, 200, 230), Mat.Glass, { Transparency = 0.3 })
				step(W(x, z, h), 3.2)
			end
			if i == 5 then
				-- muro de hielo con desvio (Flamin lo derrite)
				local ice = Part(cf, CFrame.new(W(x + sp / 2, z, h + 5)), Vector3.new(1.4, 10, 7), Color3.fromRGB(170, 230, 255), Mat.Ice,
					{ Transparency = 0.2, CanCollide = true })
				CollectionService:AddTag(ice, "IceWall")
				Part(cf, CFrame.new(W(x + sp / 2, z + 7, h)), Vector3.new(sp + 3, 0.8, 4), Color3.fromRGB(190, 235, 255), Mat.Ice,
					{ CanCollide = true, CustomPhysicalProperties = icy })
				checkpoint(cf, W(x, z, h), k, i, false)
			end
			prev = W(x, z, h)
		end
		courseFinish(cf, k, prev + Vector3.new(sp, 1, 0), true, ch)
		Props.Crystal(cf, W(x1 + 12, zc + 8), rng, Color3.fromRGB(170, 230, 255), 1.6)
	else
		-- Plataformas flotantes (se mecen) y caminos temporales (aparecen y desaparecen)
		local n = 9
		local sp = span / n
		local prev
		for i = 1, n do
			local x = x0 + (i - 1) * sp
			local z = zc + math.sin(i * 0.9) * 6
			local h = 3 + i * 1.2
			local pos = W(x, z, h)
			if i % 2 == 1 then
				local p = Part(cf, CFrame.new(pos - Vector3.new(0, 0.6, 0)), Vector3.new(6, 1.2, 6), Color3.fromRGB(200, 186, 236), Mat.Marble,
					{ CanCollide = true, Name = "Flotante" })
				local under = Props.Crystal(cf, pos - Vector3.new(0, 3.2, 0), rng, Color3.fromRGB(200, 160, 255), 0.5)
				under.Name = "CristalBase"
				if i % 4 == 1 then
					TweenService:Create(p, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
						{ CFrame = p.CFrame + Vector3.new(0, 1.5, 0) }):Play()
				end
				step(pos, 3)
			else
				-- camino temporal: dos grupos que se alternan cada 2.5 s
				local ph = Part(cf, CFrame.new(pos - Vector3.new(0, 0.5, 0)), Vector3.new(6, 1, 6), Color3.fromRGB(190, 140, 255), Mat.Glass,
					{ CanCollide = true, Transparency = 0.15, Name = "CaminoTemporal" })
				ph:SetAttribute("Phase", (i / 2) % 2)
				CollectionService:AddTag(ph, "PhasePlatform")
				step(pos, 3)
			end
			if i == 5 then
				checkpoint(cf, pos, k, i, false)
			end
			prev = pos
		end
		-- atajo secreto (Prisma lo revela)
		for j = 1, 3 do
			local hp = Part(cf, CFrame.new(W(x0 + span * 0.3 + j * 7, zc + 14, 6 + j * 2)), Vector3.new(5, 1.2, 5), Color3.fromRGB(150, 255, 255),
				Mat.Glass, { Transparency = 0.92, CanCollide = false })
			CollectionService:AddTag(hp, "HiddenPlatform")
		end
		courseFinish(cf, k, prev + Vector3.new(sp, 1, 0), false, ch)
	end
end

-- Arenas de incursion tematicas (una por zona) ---------------------------------------------

function PetWorld.ArenaCenter(k)
	local spec = PetWorld.ArenaSpecs[k]
	local x = PetWorld.ZoneStart[k] + PetWorld.Lengths[k] * spec.at
	return x, PathZ(x) - (spec.r + 15), spec.r
end

local function buildArena(f, k, rng)
	local spec = PetWorld.ArenaSpecs[k]
	local ax, az, r = PetWorld.ArenaCenter(k)
	local af = folder("Arena" .. k, f)
	af:SetAttribute("ArenaName", spec.name)
	local floor = ({ Mat.Pavement, Mat.Cobblestone, Mat.Slate, Mat.Glacier, Mat.Salt })[k]
	Terrain.Disc(W(ax, az), r, floor)
	Terrain.Disc(W(ax, az), r * 0.35, ({ Mat.LeafyGrass, Mat.Pavement, Mat.Mud, Mat.Snow, Mat.Basalt })[k])
	Terrain.Path({ W(ax, PathZ(ax)), W(ax, az + r - 2) }, 8, Mat.Ground)
	-- arco de entrada con el nombre
	Props.ArchSign(af, CFrame.lookAt(W(ax, az + r + 3), W(ax, az + r + 30)), spec.name, 9, Progression.Zones[k].color)
	local function ring(count, dist, fn)
		for i = 0, count - 1 do
			local a = (i + 0.5) / count * math.pi * 2
			-- deja libre la entrada (lado norte, hacia el camino)
			if math.sin(a) < 0.82 then
				fn(W(ax + math.cos(a) * dist, az + math.sin(a) * dist), a)
			end
		end
	end
	local particleColor
	if k == 1 then
		ring(9, r + 6, function(p) Props.Birch(af, p, rng, 1.05, Props.Palettes.blossom) end)
		ring(12, r + 1, function(p, a)
			Part(af, CFrame.new(p + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, -a, 0), Vector3.new(3, 1.2, 2), Color3.fromRGB(176, 166, 156), Mat.Slate,
				{ CanCollide = true })
		end)
		particleColor = Color3.fromRGB(255, 180, 210)
	elseif k == 2 then
		ring(12, r + 3, function(p)
			Column(af, p, rng:NextNumber(6, 11), 2.2, Color3.fromRGB(214, 184, 110), Mat.Marble, { CanCollide = true })
		end)
		ring(4, r + 10, function(p) Props.Gear(af, p, rng, 1.2) end)
		particleColor = Color3.fromRGB(255, 220, 140)
	elseif k == 3 then
		ring(10, r + 5, function(p) Props.Mushroom(af, p, rng, rng:NextNumber(3, 4.5), true, Color3.fromRGB(110, 230, 210)) end)
		particleColor = Color3.fromRGB(140, 255, 230)
	elseif k == 4 then
		ring(10, r + 4, function(p) Props.Crystal(af, p, rng, Color3.fromRGB(170, 230, 255), 1.3) end)
		particleColor = Color3.fromRGB(210, 245, 255)
	else
		ring(8, r + 4, function(p) Props.RuneStone(af, p, rng, Color3.fromRGB(200, 160, 255)) end)
		Part(af, CFrame.new(W(ax, az, 0.12)) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.12, r * 1.2, r * 1.2), Color3.fromRGB(190, 140, 255),
			Mat.Neon, { Shape = Enum.PartType.Cylinder, Transparency = 0.6, CastShadow = false })
		particleColor = Color3.fromRGB(210, 170, 255)
	end
	-- particulas ambientales suaves (petalos, chispas, esporas, escarcha, runas)
	local e = Props.Fireflies(af, W(ax, az, 9), Vector3.new(r * 2, 12, r * 2), 4, particleColor)
	e.Name = "AmbienteArena"
	exclude(ax - r - 9, az - r - 9, ax + r + 9, az + r + 9)
	local pillars = {}
	for i = 1, 4 do
		local a = (i - 1) / 4 * math.pi * 2 + math.pi / 4
		table.insert(pillars, W(ax + math.cos(a) * r * 0.72, az + math.sin(a) * r * 0.72))
	end
	World.Arenas[k] = {
		zone = k,
		name = spec.name,
		center = W(ax, az),
		radius = r,
		pillars = pillars,
		spawn = CFrame.lookAt(W(ax, az + r - 6, 4), W(ax, az, 4)),
	}
end

-- Claros (donde aparecen los PETs) y arboledas dentro de la pradera -------------------------

local function clearingsFor(k)
	-- mas claros, mas pequeños y pegados al camino: se encuentran PETs al explorar
	local x0, x1 = PetWorld.ZoneStart[k], PetWorld.ZoneEnd[k]
	local n = math.max(4, math.floor((x1 - x0) / 50))
	local r = k == 5 and 24 or 22
	local ax, az, ar = PetWorld.ArenaCenter(k)
	local list = {}
	for i = 1, n do
		local x = x0 + 22 + (x1 - x0 - 44) * (i - 0.5) / n
		local pz = PathZ(x)
		local placed = false
		for _, side in ipairs({ (i % 2 == 0) and 1 or -1, (i % 2 == 0) and -1 or 1 }) do
			local cz = math.clamp(pz + side * 30, -52, 52)
			local clearArena = (x - ax) ^ 2 + (cz - az) ^ 2 > (ar + r + 6) ^ 2
			if not placed and clearArena then
				table.insert(list, { x = x, z = cz, r = r })
				placed = true
			end
		end
	end
	return list
end

local function groves(f, k, clearings, rng)
	local x0, x1 = PetWorld.ZoneStart[k], PetWorld.ZoneEnd[k]
	local placed = {}
	local function freeSpot(x, z)
		if excluded(x, z) or math.abs(z - PathZ(x)) < 15 then
			return false
		end
		for _, c in ipairs(clearings) do
			if (x - c.x) ^ 2 + (z - c.z) ^ 2 < (c.r + 6) ^ 2 then
				return false
			end
		end
		for _, p in ipairs(placed) do
			if (p[1] - x) ^ 2 + (p[2] - z) ^ 2 < 100 then
				return false
			end
		end
		return true
	end
	local target = math.floor((x1 - x0) / 6)
	local tries = 0
	while #placed < target and tries < target * 10 do
		tries = tries + 1
		-- arboledas: agrupar alrededor de nucleos para que se vean como bosquecillos
		local cx = rng:NextNumber(x0 + 15, x1 - 15)
		local cz = rng:NextNumber(-92, 92)
		for _ = 1, 4 do
			local x = cx + rng:NextNumber(-14, 14)
			local z = math.clamp(cz + rng:NextNumber(-14, 14), -94, 94)
			if #placed < target and freeSpot(x, z) then
				table.insert(placed, { x, z })
				zoneTree(f, k, W(x, z), rng)
			end
		end
	end
	-- lomas suaves entre las arboledas
	for _ = 1, 5 do
		local x = rng:NextNumber(x0 + 30, x1 - 30)
		local z = rng:NextNumber() < 0.5 and rng:NextNumber(58, 86) or rng:NextNumber(-86, -58)
		local ok = math.abs(z - PathZ(x)) > 30
		for _, c in ipairs(clearings) do
			if (x - c.x) ^ 2 + (z - c.z) ^ 2 < (c.r + 22) ^ 2 then
				ok = false
			end
		end
		if ok then
			Terrain.Hill(W(x, z), 20, 4, STYLE[k].meadow)
		end
	end
	-- flores alrededor de los claros
	for _, c in ipairs(clearings) do
		for i = 1, 3 do
			local a = rng:NextNumber(0, math.pi * 2)
			local x, z = c.x + math.cos(a) * (c.r + 3), c.z + math.sin(a) * (c.r + 3)
			if not excluded(x, z) and math.abs(z - PathZ(x)) > 10 then
				Props.Flowers(f, W(x, z), rng, 5, 2)
			end
			local _ = i
		end
	end
end

-- Paisaje caracteristico de cada zona -------------------------------------------------------

local function landmarks(f, k, rng)
	local x0, x1 = PetWorld.ZoneStart[k], PetWorld.ZoneEnd[k]
	local function edgeSpot()
		for _ = 1, 30 do
			local x = rng:NextNumber(x0 + 20, x1 - 20)
			local z = rng:NextNumber() < 0.5 and rng:NextNumber(84, 98) or rng:NextNumber(-98, -84)
			if not excluded(x, z) then
				exclude(x - 5, z - 5, x + 5, z + 5)
				return W(x, z), x, z
			end
		end
		return nil
	end
	-- borde de la pradera: arbustos y flores
	for _ = 1, math.floor((x1 - x0) / 22) do
		local p = edgeSpot()
		if p then
			if rng:NextNumber() < 0.5 then
				Props.Bush(f, p, rng, rng:NextNumber(0.9, 1.3))
			else
				Props.Flowers(f, p, rng, 5, 2)
			end
		end
	end
	if k == 1 then
		for _ = 1, 8 do
			local p = edgeSpot()
			if p then
				Props.Flowers(f, p, rng, 8, 3)
			end
		end
	elseif k == 2 then
		for _ = 1, 5 do
			local p = edgeSpot()
			if p then
				Props.Gear(f, p, rng, rng:NextNumber(0.8, 1.3))
			end
		end
		for _ = 1, 3 do
			local p, x, z = edgeSpot()
			if p then
				Props.Ruin(f, CFrame.lookAt(p, W(x, 0)), rng, Color3.fromRGB(200, 184, 150))
			end
		end
	elseif k == 3 then
		for _ = 1, 9 do
			local p = edgeSpot()
			if p then
				Props.Mushroom(f, p, rng, rng:NextNumber(3, 5.5), true, rng:NextNumber() < 0.5 and Color3.fromRGB(110, 230, 210)
					or Color3.fromRGB(170, 120, 255))
			end
		end
	elseif k == 4 then
		for _ = 1, 6 do
			local p = edgeSpot()
			if p then
				Props.GiantFlower(f, p, rng, Props.FlowerColors[rng:NextInteger(1, #Props.FlowerColors)])
			end
		end
		for _ = 1, 4 do
			local p = edgeSpot()
			if p then
				Props.Crystal(f, p, rng, Color3.fromRGB(170, 230, 255), 1.2)
			end
		end
		for _ = 1, 3 do
			local p = edgeSpot()
			if p then
				Props.Brazier(f, p, rng)
			end
		end
		for _ = 1, 2 do
			local x = rng:NextNumber(x0 + 40, x1 - 40)
			Terrain.Pond(W(x, 132), 7)
			exclude(x - 12, 120, x + 12, 144)
		end
	elseif k == 5 then
		for _ = 1, 6 do
			local p = edgeSpot()
			if p then
				Props.RuneStone(f, p, rng, Color3.fromRGB(200, 160, 255))
			end
		end
		-- ruinas flotantes
		for i = 1, 5 do
			local x = x0 + (x1 - x0) * i / 6
			local z = (i % 2 == 0) and 115 or -118
			local p = W(x, z, rng:NextNumber(22, 34))
			Part(f, CFrame.new(p) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 6), rng:NextNumber(-0.2, 0.2)),
				Vector3.new(10, 3, 8), Color3.fromRGB(150, 136, 180), Mat.Slate)
			Column(f, p + Vector3.new(2, 1.5, 0), 6, 1.6, Color3.fromRGB(190, 180, 220), Mat.Marble)
			Props.Crystal(f, p + Vector3.new(-2, 1.5, 0), rng, Color3.fromRGB(210, 170, 255), 0.7)
		end
		-- Templo del Eclipse al final del mundo
		local tx = x1 - 45
		local tz = PathZ(tx)
		local t = folder("TemploDelEclipse", f)
		for i = 0, 2 do
			Part(t, CFrame.new(W(tx + 10, tz, 0.8 + i * 1.6)), Vector3.new(50 - i * 10, 1.6, 60 - i * 12), Color3.fromRGB(170 - i * 10, 160 - i * 10, 200),
				Mat.Marble, { CanCollide = true })
		end
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			Column(t, W(tx + 10 + math.cos(a) * 16, tz + math.sin(a) * 16, 4.8), 12, 2.2, Color3.fromRGB(200, 190, 230), Mat.Marble, { CanCollide = true })
		end
		local disk = Part(t, CFrame.new(W(tx + 22, tz, 17)) * CFrame.Angles(0, 0, 0), Vector3.new(0.8, 20, 20), Color3.fromRGB(30, 20, 40),
			Mat.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		Part(t, CFrame.new(W(tx + 21.4, tz, 17)), Vector3.new(0.4, 24, 24), Color3.fromRGB(255, 180, 80), Mat.Neon,
			{ Shape = Enum.PartType.Cylinder, Transparency = 0.2, CastShadow = false })
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 180, 80)
		l.Range = 40
		l.Brightness = 2
		l.Parent = disk
		exclude(tx - 20, tz - 34, tx + 40, tz + 34)
	end
	-- luciernagas con el color de la zona
	for i = 1, 2 do
		local x = x0 + (x1 - x0) * (i / 3)
		Props.Fireflies(f, W(x, 0, 7), Vector3.new((x1 - x0) / 2, 10, 220), 4, STYLE[k].light)
	end
end

-- Campamento ----------------------------------------------------------------------------------

local function buildCamp(f, rng)
	local camp = folder("Campamento", f)
	-- plaza de llegada y portal de regreso al santuario
	Terrain.Disc(W(36, 0), 26, Mat.Pavement)
	local pcf = CFrame.new(W(12, 0)) * CFrame.Angles(0, -math.pi / 2, 0)
	local pm, gate = Props.Portal(camp, pcf, Color3.fromRGB(120, 200, 255), rng, 1.3)
	pm.Name = "PortalSantuario"
	billboard(gate, "Volver al santuario", Color3.fromRGB(200, 235, 255), 300, 11, 140)
	local pp = H.AddPrompt(gate, "Volver", "Santuario", 0, 14)
	pp:SetAttribute("Dest", "home")
	table.insert(World.Portals, { prompt = pp, dest = "home" })
	World.Spawns.world = CFrame.lookAt(W(30, 0, 4), W(70, PathZ(70), 4))
	exclude(-10, -26, 58, 26)

	-- Puestos de NPC (como en el esquema: norte, centro y sur)
	local stalls = {
		{ id = "merchant", x = 86, z = 66, face = -1, color = Color3.fromRGB(230, 150, 60), name = "Comerciante",
			npc = { body = Color3.fromRGB(150, 90, 60), hat = Color3.fromRGB(200, 80, 60) }, hat = "cap", panel = "merchant",
			action = "Intercambiar" },
		{ id = "guide", x = 60, z = -34, face = 1, color = Color3.fromRGB(90, 170, 230), name = "Guia del bosque",
			npc = { body = Color3.fromRGB(70, 130, 90), hat = Color3.fromRGB(80, 60, 160) }, hat = "wizard", panel = "guide",
			action = "Hablar" },
		{ id = "premium", x = 108, z = -58, face = 1, color = Color3.fromRGB(230, 110, 190), name = "Tienda premium",
			npc = { body = Color3.fromRGB(120, 70, 170), hat = Color3.fromRGB(255, 210, 80) }, hat = "crown", panel = "shop",
			action = "Ver tienda" },
	}
	World.Npcs = World.Npcs or {}
	for _, s in ipairs(stalls) do
		local cf = CFrame.new(W(s.x, s.z)) * (s.face < 0 and CFrame.new() or CFrame.Angles(0, math.pi, 0))
		local m = Props.Stall(camp, cf, s.color, rng)
		m.Name = "Puesto_" .. s.id
		local npc, body = Props.NPC(m, cf * CFrame.new(0, 0.4, 1.2), s.npc, s.hat)
		npc.Name = s.name
		local prompt = H.AddPrompt(body, s.action, s.name, 0, 12)
		prompt:SetAttribute("Panel", s.panel)
		prompt:SetAttribute("Npc", s.id)
		CollectionService:AddTag(prompt, "NpcPrompt")
		billboard(body, s.name, s.color:Lerp(Color3.new(1, 1, 1), 0.3), 220, 6, 90)
		exclude(s.x - 9, s.z - 8, s.x + 9, s.z + 8)
		World.Npcs[s.id] = W(s.x, s.z)
	end

	-- Fogata, tiendas de campaña, faroles y tablon
	Props.Campfire(camp, W(30, -44), rng)
	exclude(20, -54, 40, -34)
	for _, t in ipairs({ { 110, 104, 0.4 }, { 126, -104, -0.3 }, { 20, 84, 0.9 } }) do
		local tcf = CFrame.new(W(t[1], t[2])) * CFrame.Angles(0, t[3], 0)
		for _, s in ipairs({ -1, 1 }) do
			Part(camp, tcf * CFrame.new(s * 2.4, 2.4, 0) * CFrame.Angles(0, 0, s * -0.9), Vector3.new(0.3, 6.4, 8), Color3.fromRGB(220, 200, 160),
				Mat.Fabric)
		end
		exclude(t[1] - 7, t[2] - 7, t[1] + 7, t[2] + 7)
	end
	for _, l in ipairs({ { 48, 16 }, { 78, 40 }, { 116, 42 }, { 80, -8 }, { 118, 4 }, { 50, -70 }, { 96, -82 } }) do
		Props.Lantern(camp, W(l[1], l[2]), rng, 6.5)
	end
	Props.Sign(camp, CFrame.lookAt(W(46, -18), W(46, 10)), "Mundo PET\nSigue el camino hacia el este →\nCada zona tiene su arena de incursion", 9)
	-- arco de salida hacia la Zona 1, cercas y jardineras
	local ax = PetWorld.CampLength - 6
	Props.ArchSign(camp, CFrame.lookAt(W(ax, PathZ(ax)), W(ax - 20, PathZ(ax))), "Zona 1 · Bosque de Lumi →", 15, Color3.fromRGB(230, 255, 150))
	exclude(ax - 6, PathZ(ax) - 10, ax + 6, PathZ(ax) + 10)
	Props.Fence(camp, W(0, 98), W(PetWorld.CampLength - 20, 98), rng, false)
	Props.Fence(camp, W(0, -96), W(PetWorld.CampLength - 20, -96), rng, false)
	for _, fb in ipairs({ { 26, 28 }, { 44, -28 }, { 70, 72 }, { 118, 62 }, { 96, -34 }, { 104, 82 }, { 126, -30 } }) do
		Props.Flowers(camp, W(fb[1], fb[2]), rng, 7, 2.5)
		Props.Bush(camp, W(fb[1] + 3, fb[2] + 2), rng, 0.9)
	end
	buildBeacon(camp, "camp", nil, 52, 32, rng)
	return camp
end

-- Construccion -------------------------------------------------------------------------------

function PetWorld.Build(world, rootFolder)
	World = world
	World.PET = O
	World.BarrierX = {}
	World.Gates = {}
	World.Beacons = {}
	World.MineEntrances = {}
	World.GiftSpots = {}
	World.Npcs = {}
	World.Arenas = {}
	World.Challenges = {}
	local rng = Random.new(1105)
	local f = folder("MundoPET", rootFolder)
	buildTerrain(rng)
	buildBounds(f)
	-- caminos y reservas antes de plantar
	exclude(-20, -24, PetWorld.TotalLength + 20, 24) -- franja del camino principal (con holgura por la curva)
	local camp = buildCamp(f, rng)
	for k = 2, 5 do
		buildBarrier(f, k, rng)
	end
	for k = 1, 5 do
		local zf = folder("Zona" .. k, f)
		local x0, x1 = PetWorld.ZoneStart[k], PetWorld.ZoneEnd[k]
		local Z = Progression.Zones[k]
		buildBeacon(zf, "z" .. k, k, x0 + 22, PathZ(x0 + 22) + 20, rng)
		buildMineEntrance(zf, k, rng)
		buildChallenge(zf, k, rng)
		buildArena(zf, k, rng)
		-- letrero de bienvenida con PETs y minerales de la zona
		local names = {}
		for _, sp in ipairs(PetCatalog.SpeciesInZone(k)) do
			table.insert(names, sp.name)
		end
		local sx = x0 + 14
		Props.Sign(zf, CFrame.lookAt(W(sx, PathZ(sx) - 16), W(sx - 30, PathZ(sx) - 16)),
			"Zona " .. k .. " · " .. Z.name .. "\nPETs: " .. table.concat(names, ", "), 11)
		exclude(sx - 7, PathZ(sx) - 22, sx + 7, PathZ(sx) - 10)
		landmarks(zf, k, rng)
		local clearings = clearingsFor(k)
		groves(zf, k, clearings, rng)
		-- materiales de la zona (petalos, engranajes, hongos...)
		local placedNodes = 0
		for _ = 1, 60 do
			if placedNodes >= 10 then
				break
			end
			local x = rng:NextNumber(x0 + 25, x1 - 25)
			local z = rng:NextNumber() < 0.5 and rng:NextNumber(86, 100) or rng:NextNumber(-100, -86)
			if not excluded(x, z) then
				exclude(x - 4, z - 4, x + 4, z + 4)
				makeNode(zf, Z.material, W(x, z), "z" .. k, rng)
				placedNodes = placedNodes + 1
			end
		end
		-- bosques a ambos lados de la pradera
		local count = math.floor((x1 - x0) / 8)
		local north = forestBand(zf, k, x0 + 4, x1 - 4, 104, 168, rng, count)
		local south = forestBand(zf, k, x0 + 4, x1 - 4, -170, -102, rng, count)
		local spots = {}
		for _, s in ipairs(north) do
			table.insert(spots, s)
		end
		for _, s in ipairs(south) do
			table.insert(spots, s)
		end
		World.GiftSpots[k] = spots
		-- region de aparicion de PETs (pradera central, despejada)
		local cl = {}
		for _, c in ipairs(clearings) do
			table.insert(cl, { center = W(c.x, c.z), r = c.r })
		end
		World.SpawnRegions[k] = { center = W((x0 + x1) / 2, -2), sizeX = (x1 - x0) - 80, sizeZ = 148, y = 0, clearings = cl }
	end
	-- bosque del campamento
	forestBand(camp, 1, -30, PetWorld.CampLength, 104, 168, rng, 22)
	forestBand(camp, 1, -30, PetWorld.CampLength, -170, -102, rng, 14)
	-- legado: destinos antiguos del Reino apuntan al campamento; la arena "por defecto" es la de la zona 1
	World.Spawns.realm = World.Spawns.world
	World.ARENA = World.Arenas[1].center
	World.ArenaPillars = World.Arenas[1].pillars
	World.Spawns.arena = World.Arenas[1].spawn
	-- Caminos temporales de la zona 5: dos grupos que se alternan cada 2.5 s
	local phase = 0
	local function applyPhase()
		for _, p in ipairs(CollectionService:GetTagged("PhasePlatform")) do
			local active = p:GetAttribute("Phase") == phase
			p.CanCollide = active
			p.Transparency = active and 0.15 or 0.85
		end
	end
	applyPhase()
	task.spawn(function()
		while true do
			task.wait(2.5)
			phase = 1 - phase
			applyPhase()
		end
	end)
	for k = 1, 5 do
		World.Spawns["z" .. k] = World.Spawns["beacon_z" .. k]
		World.Spawns["z" .. k .. "m"] = World.Spawns["beacon_z" .. k]
	end
end

-- Centro de una zona (para pruebas y herramientas)
function PetWorld.ZoneCenter(k)
	return W((PetWorld.ZoneStart[k] + PetWorld.ZoneEnd[k]) / 2, 0)
end

return PetWorld
