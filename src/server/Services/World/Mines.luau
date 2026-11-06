-- World/Mines: MINAS DE ZUAR, mundo propio (decision oficial GDD 1.1).
--
--   Hub (area "mines"): campamento minero al aire libre con la Cantera de Zuar
--     (siempre libre: la piedra del primer pico nunca se bloquea, GDD 22),
--     portales al Hogar y al Reino.
--   Galerias I-V (areas "m1".."m5"): una boca en la cara de la montaña, un tunel
--     y una camara excavada en el terreno. La galeria k se abre al desbloquear la
--     zona k del Reino (cortina por jugador + validacion en el servidor) y tiene
--     WorldConfig.Regions[k].mine.slots vetas con mineral PRIVADO por jugador.
--   Cada camara tiene una salida a la boca de mina de su zona del Reino.
--
-- Coordenadas locales: x (este), z (norte) respecto a World.MINES. La montaña ocupa
-- z > -20; el hub queda al sur. Ver docs/ARQUITECTURA_TRES_MUNDOS.md.

local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Items)
local Progression = require(Shared.Progression)
local WorldConfig = require(Shared.WorldConfig)

local H = require(script.Parent.Helpers)
local Terrain = require(script.Parent.Terrain)
local Props = require(script.Parent.Props)

local folder, portal, makeNode, makeVein = H.Folder, H.Portal, H.MakeNode, H.MakeVein
local Part = Props.Part
local Mat = Enum.Material

local World, root
local Mines = {}

Mines.Half = 300 -- media anchura del mundo de minas (studs)
Mines.Face = -20 -- z de la cara de la montaña
Mines.TunnelHalf = 7 -- media anchura de los tuneles

-- Galerias: x de la boca y centro de la camara (z). El radio sale de mine.size.
local LAYOUT = {
	{ x = -200, cz = 95 },
	{ x = -100, cz = 115 },
	{ x = 100, cz = 115 },
	{ x = 200, cz = 100 },
	{ x = 0, cz = 200 },
}
local FLOOR = { Mat.Ground, Mat.Slate, Mat.Basalt, Mat.Limestone, Mat.Basalt }
local QUARRY = { x = -150, z = -150, r = 30 }

local function L(x, z, y)
	return World.MINES + Vector3.new(x, y or 0, z)
end

function Mines.Gallery(k)
	local g = LAYOUT[k]
	local size = WorldConfig.Regions[k].mine.size or 1
	local r = math.floor(30 * size + 0.5)
	return { x = g.x, cz = g.cz, r = r, h = math.max(24, math.floor(r * 0.8 + 0.5)) }
end

-- Area local dentro del mundo de minas ("mines" o "m1".."m5"), o nil si esta fuera
function Mines.AreaAt(lx, lz)
	if math.abs(lx) > Mines.Half or math.abs(lz) > Mines.Half then
		return nil
	end
	for k = 1, 5 do
		local g = Mines.Gallery(k)
		local dx, dz = lx - g.x, lz - g.cz
		if dx * dx + dz * dz <= (g.r + 3) * (g.r + 3) then
			return "m" .. k
		end
		if math.abs(dx) <= Mines.TunnelHalf + 2 and lz >= Mines.Face and lz <= g.cz then
			return "m" .. k
		end
	end
	return "mines"
end

-- Terreno: suelo, montaña con cara irregular, tuneles y camaras excavadas -------------------

local function buildTerrain(rng)
	local half = Mines.Half
	Terrain.Ground(L(0, 0), half * 2 + 40, half * 2 + 40, Mat.Ground, 24)
	-- montaña de roca sobre las galerias
	local mz0, mz1 = Mines.Face, half
	workspace.Terrain:FillBlock(CFrame.new(L(0, (mz0 + mz1) / 2, 60)), Vector3.new(half * 2, 120, mz1 - mz0), Mat.Rock)
	-- cumbres para una silueta natural (solo sobre la montaña)
	for i = 1, 14 do
		local x = -half + (i - 0.5) * (half * 2 / 14) + rng:NextNumber(-12, 12)
		workspace.Terrain:FillBall(L(x, rng:NextNumber(70, 250), 112), rng:NextNumber(24, 40), (i % 3 == 0) and Mat.Slate or Mat.Rock)
	end
	-- cara irregular (rocas sobresalientes), dejando libres las bocas
	for x = -half + 10, half - 10, 22 do
		local nearMouth = false
		for k = 1, 5 do
			if math.abs(x - LAYOUT[k].x) < 22 then
				nearMouth = true
			end
		end
		if not nearMouth then
			workspace.Terrain:FillBall(L(x + rng:NextNumber(-6, 6), Mines.Face - rng:NextNumber(0, 6), rng:NextNumber(14, 40)),
				rng:NextNumber(14, 22), rng:NextNumber() < 0.3 and Mat.Slate or Mat.Rock)
		end
	end
	-- excavar tuneles y camaras
	for k = 1, 5 do
		local g = Mines.Gallery(k)
		local z0, z1 = Mines.Face - 24, g.cz
		workspace.Terrain:FillBlock(CFrame.new(L(g.x, (z0 + z1) / 2, 9)), Vector3.new(Mines.TunnelHalf * 2, 18, z1 - z0), Mat.Air)
		workspace.Terrain:FillCylinder(CFrame.new(L(g.x, g.cz, g.h / 2)), g.h, g.r, Mat.Air)
		workspace.Terrain:FillBall(L(g.x, g.cz, g.h), g.r * 0.75, Mat.Air)
		-- suelo de la camara y del tunel
		Terrain.Disc(L(g.x, g.cz), g.r, FLOOR[k])
		Terrain.Patch(L(g.x, (z0 + z1) / 2), Mines.TunnelHalf * 2, z1 - z0, Mat.Ground)
	end
	-- plaza, caminos y cantera del hub
	Terrain.Disc(L(0, -170), 42, Mat.Pavement)
	for k = 1, 5 do
		local g = LAYOUT[k]
		Terrain.Path({ L(0, -170), L(g.x * 0.6, -90), L(g.x, Mines.Face - 26) }, 9, Mat.Ground)
	end
	Terrain.Path({ L(0, -170), L(QUARRY.x + 30, QUARRY.z) }, 8, Mat.Ground)
	Terrain.Disc(L(QUARRY.x, QUARRY.z), QUARRY.r + 4, Mat.Slate)
end

-- Bordes invisibles de respaldo
local function buildBounds(f)
	local half = Mines.Half
	for _, d in ipairs({ { 0, -half - 2, half * 2 + 8, 4 }, { 0, half + 2, half * 2 + 8, 4 }, { -half - 2, 0, 4, half * 2 + 8 },
		{ half + 2, 0, 4, half * 2 + 8 } }) do
		Part(f, CFrame.new(L(d[1], d[2], 60)), Vector3.new(d[3], 160, d[4]), Color3.new(1, 1, 1), Mat.SmoothPlastic,
			{ Transparency = 1, CanCollide = true, Name = "Limite" })
	end
end

-- Boca de galeria: arco de roca, marco de vigas, faroles, letrero y cortina por jugador
local function buildMouth(f, k, rng)
	local g = Mines.Gallery(k)
	local region = WorldConfig.Regions[k]
	local Z = Progression.Zones[k]
	local m = Instance.new("Model")
	m.Name = "BocaGaleria" .. k
	m.Parent = f
	local cf = CFrame.lookAt(L(g.x, Mines.Face - 2), L(g.x, Mines.Face - 40))
	local scale = k == 5 and 1.25 or 1
	local a, b = 9.5 * scale, 11 * scale
	for i = 0, 12 do
		local t = math.pi * i / 12
		local p = cf * CFrame.new(a * math.cos(t), b * math.sin(t), 0)
		Part(m, p * CFrame.Angles(0, 0, t + math.pi / 2) * CFrame.Angles(rng:NextNumber(-0.1, 0.1), 0, 0), Vector3.new(3.8, 3.4, 5) * scale,
			Props.Vary(Color3.fromRGB(112, 104, 100), rng, 0.08), Mat.Slate, { CanCollide = true })
	end
	for _, sx in ipairs({ -1, 1 }) do
		Part(m, cf * CFrame.new(sx * 6.4 * scale, 4.6 * scale, -1), Vector3.new(1.2, 9.2 * scale, 1.2), Color3.fromRGB(100, 72, 50), Mat.Wood)
		Props.Lantern(m, (cf * CFrame.new(sx * 10 * scale, 0, -5)).Position, rng, 5)
	end
	Part(m, cf * CFrame.new(0, 9.4 * scale, -1), Vector3.new(14 * scale, 1.2, 1.2), Color3.fromRGB(100, 72, 50), Mat.Wood)
	-- rieles hacia el interior
	for _, sx in ipairs({ -1.6, 1.6 }) do
		Part(m, cf * CFrame.new(sx, 0.15, 6), Vector3.new(0.3, 0.3, 30), Color3.fromRGB(90, 84, 80), Mat.Metal)
	end
	local minerals = {}
	for _, res in ipairs(WorldConfig.Mines.order) do
		local c = region.mine.chances[res]
		if c and c > 0 then
			table.insert(minerals, Items.Resources[res].icon .. " " .. math.floor(c * 100 + 0.5) .. "%")
		end
	end
	local lock = k == 1 and "Abierta" or ("Se abre con la Zona " .. k .. " · " .. Z.name)
	Props.Sign(m, cf * CFrame.new(-14 * scale, 0, -6), region.mine.name .. "\n" .. table.concat(minerals, "  ") .. "\n" .. lock, 11)
	if k >= 2 then
		local sheet = Part(m, CFrame.new(L(g.x, Mines.Face - 3, 9)), Vector3.new(Mines.TunnelHalf * 2 + 4, 18, 1.2), Z.color, Mat.ForceField,
			{ CanCollide = true, CastShadow = false, Transparency = 0.5, Name = "Cortina" })
		sheet:SetAttribute("Zone", k)
		CollectionService:AddTag(sheet, "ZoneBarrier")
	end
	World.MineMouths[k] = CFrame.lookAt(L(g.x, Mines.Face - 22, 4), L(g.x, Mines.Face - 60, 4))
end

-- Camara: vetas en anillo, vigas, faroles, cristales y salida al Reino
local function buildChamber(f, k, rng)
	local g = Mines.Gallery(k)
	local region = WorldConfig.Regions[k]
	local Z = Progression.Zones[k]
	local cf = folder("Galeria" .. k, f)
	cf:SetAttribute("Gallery", k)
	local center = L(g.x, g.cz)
	-- vetas: anillo junto a la pared, dejando libre la entrada del tunel (sur)
	local n = region.mine.slots
	local ids = {}
	local gap = 0.5
	local arc = math.pi * 2 - gap * 2
	local rr = g.r - 7
	for i = 1, n do
		local a = -math.pi / 2 + gap + arc * (i - 0.5) / n + rng:NextNumber(-1, 1) / rr -- +-1 stud
		local pos = L(g.x + math.cos(a) * rr, g.cz + math.sin(a) * rr)
		local _, id = makeVein(cf, pos, k, rng, center)
		table.insert(ids, id)
	end
	World.Veins[k] = ids
	-- vigas de sosten y faroles (pocas luces: rendimiento movil)
	for i, a in ipairs({ 0, 0.8, 2.35, math.pi }) do -- mitad norte: la entrada queda despejada
		local p = L(g.x + math.cos(a) * g.r * 0.45, g.cz + math.sin(a) * g.r * 0.45)
		Part(cf, CFrame.new(p + Vector3.new(0, 6, 0)), Vector3.new(1.4, 12, 1.4), Color3.fromRGB(96, 70, 50), Mat.Wood, { CanCollide = true })
		if i % 2 == 1 then
			Props.Lantern(cf, p + Vector3.new(2, 0, 0), rng, 5)
		end
	end
	-- cristales de ambiente con el color de la zona
	for i = 1, (k == 5 and 5 or 3) do
		local a = rng:NextNumber(0.3, math.pi - 0.3)
		local d = rng:NextNumber(4, g.r * 0.3)
		Props.Crystal(cf, L(g.x + math.cos(a) * d, g.cz + math.sin(a) * d), rng, Z.color, k == 5 and 1.3 or 0.9)
	end
	-- vagoneta junto a la entrada
	local cartPos = L(g.x + 8, g.cz - g.r * 0.45)
	Part(cf, CFrame.new(cartPos + Vector3.new(0, 1.6, 0)), Vector3.new(3.2, 2.2, 4.6), Color3.fromRGB(110, 80, 56), Mat.WoodPlanks, { CanCollide = true })
	Part(cf, CFrame.new(cartPos + Vector3.new(0, 2.9, 0)), Vector3.new(2.6, 0.6, 4), Color3.fromRGB(120, 116, 124), Mat.Slate)
	-- llegada dentro de la galeria y salida al Reino (boca de mina de la zona k)
	World.Spawns["mine_m" .. k] = CFrame.lookAt(L(g.x, g.cz - g.r + 6, 4), L(g.x, g.cz, 4))
	local exitPos = L(g.x - 8, g.cz - g.r * 0.35)
	portal(cf, exitPos, math.rad(90), "Salir a la Zona " .. k, Z.color, "mineexit_z" .. k)
	local sign = Props.Sign(cf, CFrame.lookAt(L(g.x + 9, g.cz - g.r * 0.62), L(g.x + 9, g.cz - g.r)), region.mine.name, 8)
	sign.Name = "LetreroGaleria"
	return cf
end

-- Hub: plaza, portales, cantera libre y decorado ----------------------------------------------

local function buildHub(f, rng)
	local hub = folder("CampamentoMinero", f)
	World.Spawns.mines = CFrame.lookAt(L(0, -235, 4), L(0, -150, 4))
	portal(hub, L(-46, -255), 0, "Volver al Santuario", Color3.fromRGB(120, 200, 255), "home")
	portal(hub, L(46, -255), 0, "Reino de los PETs", Color3.fromRGB(190, 140, 255), "world")
	Props.Sign(hub, CFrame.lookAt(L(14, -212), L(14, -260)),
		"Minas de Zuar\nCantera libre al oeste · Galerias I-V en la montaña\nCada galeria se abre con su zona del Reino", 13)
	Props.Campfire(hub, L(-18, -190), rng)
	for _, p in ipairs({ { -30, -150 }, { 30, -150 }, { -30, -200 }, { 30, -200 }, { 0, -120 } }) do
		Props.Lantern(hub, L(p[1], p[2]), rng, 6)
	end
	for i = 1, 6 do
		Props.Crate(hub, CFrame.new(L(24 + (i % 3) * 3.2, -184 + math.floor(i / 3) * 3.2, 1.5)) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), 1)
	end
	Props.Barrel(hub, L(36, -178), 1)
	Props.Barrel(hub, L(38, -182), 1)
	-- Cantera de Zuar (siempre libre)
	local q = folder("CanteraDeZuar", hub)
	local cfg = WorldConfig.Mines.quarry
	for i = 1, cfg.nodes do
		local a = (i / cfg.nodes) * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local d = (i % 2 == 0) and QUARRY.r * 0.75 or QUARRY.r * 0.4
		makeNode(q, cfg.type, L(QUARRY.x + math.cos(a) * d, QUARRY.z + math.sin(a) * d), "mines", rng)
	end
	for i = 1, 10 do
		local a = (i / 10) * math.pi * 2
		Props.Rock(q, L(QUARRY.x + math.cos(a) * (QUARRY.r + 6), QUARRY.z + math.sin(a) * (QUARRY.r + 6)), rng, rng:NextNumber(1.6, 2.6), false, true)
	end
	Props.Sign(q, CFrame.lookAt(L(QUARRY.x + 34, QUARRY.z - 6), L(QUARRY.x + 60, QUARRY.z - 6)),
		"Cantera de Zuar\nPiedra para tu primer pico\nSiempre abierta", 10)
end

function Mines.Build(world, rootFolder)
	World = world
	root = rootFolder
	World.MineMouths = {}
	World.Veins = {}
	local rng = Random.new(2024)
	local f = folder("MinasDeZuar", root)
	buildTerrain(rng)
	buildBounds(f)
	buildHub(f, rng)
	for k = 1, 5 do
		buildMouth(f, k, rng)
		buildChamber(f, k, rng)
	end
	World.MinesFolder = f
end

return Mines
