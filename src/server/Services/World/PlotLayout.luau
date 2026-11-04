-- World/PlotLayout: distribucion de una parcela (coordenadas locales).
-- La parcela mira hacia la plaza por -Z. La casa queda al fondo (+Z), el
-- portal justo delante de la casa, los talleres a los lados y los extractores
-- en la zona delantera derecha. Todo lo decorativo respeta estas reservas para
-- no tapar estaciones, interacciones ni caminos.

local PlotLayout = {}

PlotLayout.Radius = 210 -- distancia de cada parcela a la plaza
PlotLayout.Half = 56 -- media anchura de la parcela
PlotLayout.Usable = 45 -- interior despejado; entre Usable y Half crece el bosque

PlotLayout.House = { x = 0, z = 36, w = 24, d = 20 } -- reserva para el nivel maximo
PlotLayout.Portal = { x = -13, z = 16, r = 8.5, yaw = -0.3 } -- frente a la casa, orientado hacia la entrada
PlotLayout.Spawn = { x = 0, z = -22, r = 5 }
PlotLayout.Sign = { x = 9, z = -47, r = 4 }
PlotLayout.Pond = { x = -38, z = 27, r = 4.5 }

-- Estaciones (mismos ids que Plots/Production). r = radio reservado.
PlotLayout.Spots = {
	almacen = { x = -26, z = 37, r = 6 },
	taller = { x = 26, z = 37, r = 7 },
	reactor = { x = -39, z = 9, r = 5 },
	fusionlab = { x = -27, z = 8, r = 5 },
	alchemy = { x = 24, z = 10, r = 5 },
	bait = { x = 37, z = 10, r = 5 },
	stone = { x = 16, z = -9, r = 5 },
	copper = { x = 28, z = -9, r = 5 },
	iron = { x = 40, z = -9, r = 5 },
	moon = { x = 16, z = -25, r = 5 },
	zuarita = { x = 28, z = -25, r = 5 },
	nexus = { x = 40, z = -25, r = 5 },
	garden = { x = -27, z = -17, w = 25, d = 13 },
}

PlotLayout.Decos = {
	fuente = { x = -14, z = -38, r = 5 },
	estatua = { x = 16, z = -40, r = 4 },
	faroles = { x = -30, z = -40, r = 4 },
	arco = { x = 0, z = -50, r = 5 },
	vip = { x = -40, z = -38, r = 4 },
	portal = { x = 40, z = -40, r = 5 },
}

-- Caminos de tierra (listas de puntos locales {x, z}) y su ancho
PlotLayout.Paths = {
	{ width = 6, points = { { 0, -60 }, { 0, -30 }, { 0, 27 } } }, -- entrada -> puerta de la casa
	{ width = 5, points = { { 0, -2 }, { -8, 5 }, { -11, 8 } } }, -- al portal
	{ width = 5, points = { { 0, 24 }, { -18, 31 }, { -26, 31 } } }, -- al almacen
	{ width = 5, points = { { 0, 24 }, { 18, 31 }, { 26, 31 } } }, -- al taller
	{ width = 5, points = { { 0, -8 }, { -14, -5 }, { -27, -9 } } }, -- al huerto
	{ width = 4, points = { { -8, 5 }, { -18, 0 }, { -34, 1 } } }, -- reactor y fusiones
	{ width = 5, points = { { 0, -4 }, { 12, 0 }, { 30, 3 } } }, -- alquimia y cebos
	{ width = 5, points = { { 0, -17 }, { 46, -17 } } }, -- entre filas de extractores
}

local function distToSeg(px, pz, ax, az, bx, bz)
	local dx, dz = bx - ax, bz - az
	local l2 = dx * dx + dz * dz
	local t = 0
	if l2 > 0 then
		t = math.clamp(((px - ax) * dx + (pz - az) * dz) / l2, 0, 1)
	end
	local cx, cz = ax + dx * t, az + dz * t
	return math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end
PlotLayout.DistToSeg = distToSeg

-- ¿Un punto local (x, z) choca con alguna reserva? margin = holgura extra.
function PlotLayout.IsReserved(x, z, margin)
	margin = margin or 0
	local H = PlotLayout.House
	if math.abs(x - H.x) < H.w / 2 + margin and math.abs(z - H.z) < H.d / 2 + margin then
		return true
	end
	for _, c in ipairs({ PlotLayout.Portal, PlotLayout.Spawn, PlotLayout.Sign, PlotLayout.Pond }) do
		if math.sqrt((x - c.x) ^ 2 + (z - c.z) ^ 2) < c.r + margin then
			return true
		end
	end
	for _, s in pairs(PlotLayout.Spots) do
		if s.w then
			if math.abs(x - s.x) < s.w / 2 + margin and math.abs(z - s.z) < s.d / 2 + margin then
				return true
			end
		elseif math.sqrt((x - s.x) ^ 2 + (z - s.z) ^ 2) < s.r + margin then
			return true
		end
	end
	for _, d in pairs(PlotLayout.Decos) do
		if math.sqrt((x - d.x) ^ 2 + (z - d.z) ^ 2) < d.r + margin then
			return true
		end
	end
	for _, path in ipairs(PlotLayout.Paths) do
		local pts = path.points
		for i = 1, #pts - 1 do
			if distToSeg(x, z, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2]) < path.width / 2 + margin then
				return true
			end
		end
	end
	return false
end

return PlotLayout
