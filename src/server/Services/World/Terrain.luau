-- World/Terrain: suelo natural con el Terrain de Roblox (colinas suaves, caminos
-- de tierra, estanques). Rojo no sincroniza Terrain, por eso se genera aqui.
-- La superficie "plana" queda a y = 0; los objetos se apoyan en esa altura.

local Terrain = {}
local T = workspace.Terrain

local M = Enum.Material

-- Paleta estilizada (colores mas vivos que los de fabrica)
local COLORS = {
	{ M.Grass, Color3.fromRGB(98, 170, 72) },
	{ M.LeafyGrass, Color3.fromRGB(112, 182, 84) }, -- cesped corto y limpio de las zonas transitables
	{ M.Ground, Color3.fromRGB(198, 160, 110) }, -- caminos de tierra clara, faciles de leer
	{ M.Mud, Color3.fromRGB(116, 86, 62) },
	{ M.Rock, Color3.fromRGB(126, 122, 132) },
	{ M.Slate, Color3.fromRGB(110, 108, 118) },
	{ M.Sand, Color3.fromRGB(226, 206, 160) },
	{ M.Cobblestone, Color3.fromRGB(168, 160, 150) },
	{ M.Pavement, Color3.fromRGB(196, 190, 178) },
	{ M.Basalt, Color3.fromRGB(70, 66, 80) },
	{ M.CrackedLava, Color3.fromRGB(255, 120, 50) },
	{ M.Salt, Color3.fromRGB(230, 225, 240) },
	{ M.Limestone, Color3.fromRGB(210, 200, 170) },
}

function Terrain.Init()
	for _, c in ipairs(COLORS) do
		pcall(function()
			T:SetMaterialColor(c[1], c[2])
		end)
	end
	-- Pasto animado solo sobre el material Grass (bosques y bordes) y corto, para
	-- no tapar la vista. Las zonas transitables usan LeafyGrass (cesped sin hojas
	-- altas), tierra o piedra.
	pcall(function()
		T.Decoration = true
	end)
	pcall(function()
		T.GrassLength = 0.3
	end)
	pcall(function()
		T.WaterColor = Color3.fromRGB(70, 170, 200)
		T.WaterTransparency = 0.55
		T.WaterWaveSize = 0.08
		T.WaterWaveSpeed = 6
		T.WaterReflectance = 0.3
	end)
end

-- Bloque de suelo cuya cara superior queda en topY (por defecto 0)
function Terrain.Ground(center, sizeX, sizeZ, material, depth, topY)
	depth = depth or 16
	topY = topY or 0
	T:FillBlock(CFrame.new(center.X, topY - depth / 2, center.Z), Vector3.new(sizeX, depth, sizeZ), material or M.Grass)
end

-- Cambia el material de la capa superior (rectangulo opcionalmente girado)
function Terrain.Patch(center, sizeX, sizeZ, material, yaw)
	T:FillBlock(CFrame.new(center.X, -2, center.Z) * CFrame.Angles(0, yaw or 0, 0), Vector3.new(sizeX, 4, sizeZ), material)
end

-- Mancha circular en la capa superior
function Terrain.Disc(center, radius, material)
	T:FillCylinder(CFrame.new(center.X, -2, center.Z), 4, radius, material)
end

-- Camino por una lista de puntos (Vector3, se ignora Y) con esquinas redondeadas
function Terrain.Path(points, width, material)
	material = material or M.Ground
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local a0 = Vector3.new(a.X, -2, a.Z)
		local b0 = Vector3.new(b.X, -2, b.Z)
		local len = (b0 - a0).Magnitude
		if len > 0.1 then
			local mid = (a0 + b0) / 2
			T:FillBlock(CFrame.lookAt(mid, b0), Vector3.new(width, 4, len), material)
		end
		T:FillCylinder(CFrame.new(a0), 4, width / 2, material)
	end
	local last = points[#points]
	T:FillCylinder(CFrame.new(last.X, -2, last.Z), 4, width / 2, material)
end

-- Colina en forma de domo: altura maxima "height" sobre el suelo
function Terrain.Hill(center, radius, height, material)
	local r = math.max(radius, height)
	local cy = height - r
	T:FillBall(Vector3.new(center.X, cy, center.Z), r, material or M.Grass)
end

-- Estanque redondo con orilla de arena
function Terrain.Pond(center, radius)
	T:FillCylinder(CFrame.new(center.X, -2, center.Z), 4, radius + 3, M.Sand)
	T:FillCylinder(CFrame.new(center.X, -3, center.Z), 6, radius, M.Water)
end

return Terrain
