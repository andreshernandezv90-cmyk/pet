-- World/House: casa rustica del santuario, construida pieza a pieza.
--   Nivel 1: humilde y deteriorada (tablas faltantes, techo con agujeros y
--            lona, ventana tapiada, puerta entreabierta, chimenea torcida).
--   Nivel 2: reparada (techo completo, ventanas con luz, humo).
--   Nivel 3: mas grande, anexo lateral, jardineras y porche con farol.
--   Nivel 4: segundo piso con balcon.
--   Nivel 5: cristales y runas dimensionales, orbe flotante.
-- La puerta mira hacia -Z (hacia el portal y la entrada de la parcela).

local Props = require(script.Parent.Props)

local House = {}
local M = Enum.Material
local Part, Blob, Beam, Column, vary = Props.Part, Props.Blob, Props.Beam, Props.Column, Props.Vary

local WOOD = Color3.fromRGB(150, 108, 70)
local WOOD_OLD = Color3.fromRGB(118, 92, 72)
local POST = Color3.fromRGB(88, 64, 46)
local STONE = Color3.fromRGB(140, 136, 132)

-- Pared de tablas verticales. "openings" = lista de {x0, x1, y0, y1} sin tablas.
local function plankWall(m, cf, width, height, rng, color, missing, openings, neat)
	local x = -width / 2
	while x < width / 2 - 0.05 do
		local w = math.min(rng:NextNumber(0.9, 1.25), width / 2 - x)
		local cx = x + w / 2
		local skip = missing > 0 and rng:NextNumber() < missing
		local jag = neat and 0.1 or 0.35
		local segments = { { 0, height + rng:NextNumber(-jag, jag * 0.7) } }
		for _, o in ipairs(openings or {}) do
			if cx > o[1] and cx < o[2] then
				local new = {}
				for _, s in ipairs(segments) do
					if o[3] > s[1] then
						table.insert(new, { s[1], math.min(s[2], o[3]) })
					end
					if o[4] < s[2] then
						table.insert(new, { math.max(s[1], o[4]), s[2] })
					end
				end
				segments = new
			end
		end
		if not skip then
			local c = vary(color, rng, 0.1)
			for _, s in ipairs(segments) do
				local h = s[2] - s[1]
				if h > 0.2 then
					local tilt = neat and 0.008 or 0.025
					Part(m, cf * CFrame.new(cx, s[1] + h / 2, 0) * CFrame.Angles(0, 0, rng:NextNumber(-tilt, tilt)),
						Vector3.new(w - 0.06, h, 0.32), c, M.WoodPlanks, { CanCollide = true })
				end
			end
		end
		x = x + w
	end
end

-- Hastial escalonado (triangulo de tablas horizontales)
local function gable(m, cf, width, height, rng, color)
	local rows = 6
	for i = 0, rows - 1 do
		local t = (i + 0.5) / rows
		local w = width * (1 - t)
		if w > 0.6 then
			Part(m, cf * CFrame.new(rng:NextNumber(-0.1, 0.1), height * i / rows + height / rows / 2, 0),
				Vector3.new(w, height / rows + 0.05, 0.3), vary(color, rng, 0.1), M.WoodPlanks)
		end
	end
end

-- Una vertiente del tejado hecha de hileras de tejas. holeChance deja huecos.
local function roofSlope(m, cf, length, slopeLen, rng, color, holeChance, tarp)
	local rows = 5
	local rowW = slopeLen / rows
	for r = 0, rows - 1 do
		local z = -slopeLen / 2 + rowW * (r + 0.5)
		local segs = rng:NextInteger(2, 3)
		local segL = length / segs
		for sgi = 0, segs - 1 do
			if not (holeChance > 0 and rng:NextNumber() < holeChance) then
				local c = vary(color, rng, 0.1)
				if r % 2 == 1 then
					c = c:Lerp(Color3.new(0, 0, 0), 0.08)
				end
				Part(m, cf * CFrame.new(-length / 2 + segL * (sgi + 0.5) + rng:NextNumber(-0.15, 0.15), r * 0.06, z)
					* CFrame.Angles(rng:NextNumber(-0.03, 0.03), 0, rng:NextNumber(-0.02, 0.02)),
					Vector3.new(segL + 0.05, 0.32, rowW + 0.35), c, M.Slate)
			end
		end
	end
	if tarp then
		Part(m, cf * CFrame.new(length * 0.18, 0.28, slopeLen * 0.05) * CFrame.Angles(0, 0.12, 0.03),
			Vector3.new(length * 0.32, 0.12, slopeLen * 0.45), Color3.fromRGB(70, 120, 150), M.Fabric)
	end
end

local function window(m, cf, w, h, lit, boarded, rng)
	local frame = POST
	Part(m, cf * CFrame.new(0, h / 2 + 0.15, 0), Vector3.new(w + 0.6, 0.3, 0.45), frame, M.Wood)
	Part(m, cf * CFrame.new(0, -h / 2 - 0.15, -0.1), Vector3.new(w + 0.9, 0.3, 0.7), frame, M.Wood)
	Part(m, cf * CFrame.new(-w / 2 - 0.15, 0, 0), Vector3.new(0.3, h, 0.45), frame, M.Wood)
	Part(m, cf * CFrame.new(w / 2 + 0.15, 0, 0), Vector3.new(0.3, h, 0.45), frame, M.Wood)
	local glass = Part(m, cf * CFrame.new(0, 0, 0.05), Vector3.new(w, h, 0.1), lit and Color3.fromRGB(255, 214, 140) or Color3.fromRGB(40, 36, 40),
		lit and M.Neon or M.SmoothPlastic, { Transparency = lit and 0.15 or 0, CastShadow = false })
	Part(m, cf * CFrame.new(0, 0, -0.05), Vector3.new(0.15, h, 0.12), frame, M.Wood)
	if boarded then
		Part(m, cf * CFrame.new(0, 0.3, -0.25) * CFrame.Angles(0, 0, 0.5), Vector3.new(w + 0.8, 0.45, 0.12), WOOD_OLD, M.Wood)
		Part(m, cf * CFrame.new(0, -0.4, -0.25) * CFrame.Angles(0, 0, -0.35), Vector3.new(w + 0.6, 0.45, 0.12), vary(WOOD_OLD, rng, 0.1), M.Wood)
	else
		-- contraventanas
		Part(m, cf * CFrame.new(-w / 2 - 0.9, 0, -0.3) * CFrame.Angles(0, 0.35, 0), Vector3.new(1.2, h, 0.15), vary(WOOD, rng, 0.1), M.WoodPlanks)
		Part(m, cf * CFrame.new(w / 2 + 0.9, -0.15, -0.3) * CFrame.Angles(0, -0.5, 0.08), Vector3.new(1.2, h, 0.15), vary(WOOD, rng, 0.1),
			M.WoodPlanks)
	end
	if lit then
		local l = Instance.new("PointLight")
		l.Range = 10
		l.Brightness = 0.9
		l.Color = Color3.fromRGB(255, 200, 130)
		l.Parent = glass
	end
end

local function chimney(m, cf, height, lean, rng, smoke)
	local y = 0
	local cur = cf
	local i = 0
	while y < height do
		i = i + 1
		local h = rng:NextNumber(0.9, 1.3)
		local w = 2.6 - i * 0.06
		Part(m, cur * CFrame.new(rng:NextNumber(-0.08, 0.08), y + h / 2, 0) * CFrame.Angles(0, rng:NextNumber(-0.06, 0.06), 0),
			Vector3.new(w, h + 0.04, w * 0.9), vary(STONE, rng, 0.1), M.Cobblestone)
		y = y + h
		cur = cur * CFrame.Angles(0, 0, lean / 8)
	end
	local top = Part(m, cur * CFrame.new(0, y + 0.2, 0), Vector3.new(2.9, 0.4, 2.7), vary(STONE, rng, 0.1):Lerp(Color3.new(0, 0, 0), 0.15),
		M.Cobblestone)
	if smoke then
		local s = Instance.new("Smoke")
		s.Color = Color3.fromRGB(220, 220, 225)
		s.Opacity = 0.12
		s.RiseVelocity = 3
		s.Size = 1.5
		s.Parent = top
	end
end

-- Construye la casa. base: CFrame en el suelo, centro de la casa, puerta hacia -Z.
function House.Build(parent, base, level, rng)
	level = math.clamp(level or 1, 1, 5)
	local m = Instance.new("Model")
	m.Name = "Casa"
	m.Parent = parent

	local W = level >= 3 and 18 or 14
	local D = level >= 3 and 13 or 11
	local H = level >= 4 and 13 or 8
	local broken = level == 1
	local wallColor = broken and WOOD_OLD or WOOD
	local floorY = 1.1

	-- Cimientos de piedras irregulares
	for side = 1, 4 do
		local len = (side % 2 == 1) and W or D
		local x = -len / 2 - 0.6
		while x < len / 2 + 0.6 do
			local sl = rng:NextNumber(1.8, 3)
			local sx = x + sl / 2
			local local_cf
			if side == 1 then
				local_cf = CFrame.new(sx, 0, -D / 2)
			elseif side == 3 then
				local_cf = CFrame.new(sx, 0, D / 2)
			elseif side == 2 then
				local_cf = CFrame.new(W / 2, 0, sx) * CFrame.Angles(0, math.rad(90), 0)
			else
				local_cf = CFrame.new(-W / 2, 0, sx) * CFrame.Angles(0, math.rad(90), 0)
			end
			local h = rng:NextNumber(1.2, 1.7)
			Part(m, base * local_cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(rng:NextNumber(-0.06, 0.06), rng:NextNumber(-0.1, 0.1), 0),
				Vector3.new(sl, h, rng:NextNumber(1.3, 1.7)), vary(STONE, rng, 0.12), M.Cobblestone, { CanCollide = true })
			x = x + sl
		end
	end
	Part(m, base * CFrame.new(0, floorY, 0), Vector3.new(W, 0.4, D), Color3.fromRGB(130, 96, 64), M.WoodPlanks, { CanCollide = true })
	-- Interior oscuro: lo que se ve por las rendijas
	Part(m, base * CFrame.new(0, floorY + H / 2, 0), Vector3.new(W - 1.2, H - 0.4, D - 1.2), Color3.fromRGB(34, 28, 26), M.SmoothPlastic,
		{ CastShadow = false })

	local y0 = floorY + 0.2
	local missing = broken and 0.12 or 0
	local doorW, doorH = 3.6, 6.4
	local winY0, winY1 = 3.2, 5.6
	-- Frente (-Z): puerta al centro y dos ventanas
	local frontOpen = { { -doorW / 2, doorW / 2, -1, doorH }, { -W / 2 + 1.6, -W / 2 + 4.4, winY0, winY1 }, { W / 2 - 4.4, W / 2 - 1.6, winY0, winY1 } }
	if level >= 4 then
		table.insert(frontOpen, { -W / 2 + 1.6, -W / 2 + 4.4, 9, 11.2 })
		table.insert(frontOpen, { W / 2 - 4.4, W / 2 - 1.6, 9, 11.2 })
	end
	local neat = level >= 3
	plankWall(m, base * CFrame.new(0, y0, -D / 2), W, H, rng, wallColor, missing, frontOpen, neat)
	plankWall(m, base * CFrame.new(0, y0, D / 2) * CFrame.Angles(0, math.pi, 0), W, H, rng, wallColor, missing,
		{ { -2, 2, winY0, winY1 } }, neat)
	plankWall(m, base * CFrame.new(W / 2, y0, 0) * CFrame.Angles(0, -math.rad(90), 0), D, H, rng, wallColor, missing,
		{ { -1.4, 1.4, winY0, winY1 } }, neat)
	plankWall(m, base * CFrame.new(-W / 2, y0, 0) * CFrame.Angles(0, math.rad(90), 0), D, H, rng, wallColor, missing, {}, neat)

	-- Postes de esquina y vigas (algo torcidos en nivel 1)
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		local tilt = broken and rng:NextNumber(-0.05, 0.05) or 0
		Part(m, base * CFrame.new(c[1] * W / 2, y0 + H / 2, c[2] * D / 2) * CFrame.Angles(tilt, 0, tilt), Vector3.new(0.9, H + 0.6, 0.9),
			POST, M.Wood, { CanCollide = true })
	end
	for _, zz in ipairs({ -1, 1 }) do
		Part(m, base * CFrame.new(0, y0 + H + 0.1, zz * D / 2), Vector3.new(W + 1.2, 0.6, 0.7), POST, M.Wood)
	end
	if level >= 4 then
		-- franja que separa los dos pisos y balcon
		Part(m, base * CFrame.new(0, y0 + 7.6, -D / 2 - 0.1), Vector3.new(W + 0.6, 0.5, 0.5), POST, M.Wood)
		Part(m, base * CFrame.new(0, y0 + 7.4, -D / 2 - 1.6), Vector3.new(W * 0.55, 0.35, 3), Color3.fromRGB(130, 96, 64), M.WoodPlanks,
			{ CanCollide = true })
		for i = -3, 3 do
			Part(m, base * CFrame.new(i * W * 0.08, y0 + 8.2, -D / 2 - 3), Vector3.new(0.25, 1.4, 0.25), POST, M.Wood)
		end
		Part(m, base * CFrame.new(0, y0 + 8.9, -D / 2 - 3), Vector3.new(W * 0.55, 0.25, 0.3), POST, M.Wood)
	end

	-- Hastiales y tejado (cumbrera paralela al frente: vertientes hacia -Z y +Z)
	local theta = math.rad(level == 1 and 34 or 32)
	local rise = math.tan(theta) * (D / 2 + 1)
	local wallTop = y0 + H + 0.4
	for _, side in ipairs({ -1, 1 }) do
		gable(m, base * CFrame.new(side * W / 2, wallTop, 0) * CFrame.Angles(0, math.rad(90), 0), D + 0.4, rise - 0.3, rng, wallColor)
	end
	local slopeLen = (D / 2 + 1.6) / math.cos(theta)
	local roofColor = level >= 5 and Color3.fromRGB(110, 76, 160) or (broken and Color3.fromRGB(104, 80, 70) or Color3.fromRGB(170, 82, 62))
	local ridgeY = wallTop + rise
	local frontCf = base * CFrame.new(0, ridgeY - math.sin(theta) * slopeLen / 2 + 0.2, -math.cos(theta) * slopeLen / 2) * CFrame.Angles(-theta, 0, 0)
	local backCf = base * CFrame.new(0, ridgeY - math.sin(theta) * slopeLen / 2 + 0.2, math.cos(theta) * slopeLen / 2) * CFrame.Angles(theta, 0, 0)
	if broken then
		-- la cumbrera se ha hundido un poco hacia un lado
		frontCf = frontCf * CFrame.Angles(0, 0, 0.025)
		backCf = backCf * CFrame.Angles(0, 0, -0.02)
	end
	roofSlope(m, frontCf, W + 2.8, slopeLen, rng, roofColor, broken and 0.14 or 0, level <= 2)
	roofSlope(m, backCf, W + 2.8, slopeLen, rng, roofColor, broken and 0.2 or 0, false)
	Beam(m, base * CFrame.new(-W / 2 - 1.6, ridgeY + 0.25, 0).Position, base * CFrame.new(W / 2 + 1.6, ridgeY + 0.25 - (broken and 0.4 or 0), 0).Position,
		0.75, POST, M.Wood)

	-- Chimenea
	chimney(m, base * CFrame.new(W / 2 - 3, wallTop - 2, D / 4), rise + 4.2, broken and 0.09 or 0.02, rng, level >= 2)

	-- Puerta
	local hinge = base * CFrame.new(-doorW / 2, y0, -D / 2 - 0.05)
	local door = hinge * CFrame.Angles(0, broken and math.rad(28) or 0, 0)
	for i = 0, 2 do
		Part(m, door * CFrame.new(0.6 + i * 1.2, doorH / 2, 0), Vector3.new(1.15, doorH - 0.1, 0.3), vary(Color3.fromRGB(120, 76, 46), rng, 0.08),
			M.WoodPlanks)
	end
	Part(m, door * CFrame.new(doorW / 2, doorH * 0.3, -0.2), Vector3.new(doorW - 0.2, 0.35, 0.15), POST, M.Wood)
	Part(m, door * CFrame.new(doorW / 2, doorH * 0.75, -0.2), Vector3.new(doorW - 0.2, 0.35, 0.15), POST, M.Wood)
	Part(m, door * CFrame.new(doorW / 2, doorH * 0.52, -0.2) * CFrame.Angles(0, 0, 0.9), Vector3.new(doorH * 0.55, 0.3, 0.12), POST, M.Wood)
	Part(m, door * CFrame.new(doorW - 0.5, doorH * 0.5, -0.3), Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(60, 60, 66), M.Metal)
	Part(m, base * CFrame.new(0, y0 + doorH + 0.25, -D / 2 - 0.15), Vector3.new(doorW + 0.8, 0.5, 0.5), POST, M.Wood)

	-- Ventanas
	local lit = level >= 2
	window(m, base * CFrame.new(-W / 2 + 3, y0 + (winY0 + winY1) / 2, -D / 2 - 0.15), 2.6, winY1 - winY0, lit, broken, rng)
	window(m, base * CFrame.new(W / 2 - 3, y0 + (winY0 + winY1) / 2, -D / 2 - 0.15), 2.6, winY1 - winY0, lit, false, rng)
	if level >= 4 then
		window(m, base * CFrame.new(-W / 2 + 3, y0 + 10.1, -D / 2 - 0.15), 2.6, 2.2, true, false, rng)
		window(m, base * CFrame.new(W / 2 - 3, y0 + 10.1, -D / 2 - 0.15), 2.6, 2.2, true, false, rng)
	end

	-- Escalones de entrada
	Part(m, base * CFrame.new(0, 0.45, -D / 2 - 1.4) * CFrame.Angles(0, rng:NextNumber(-0.05, 0.05), 0), Vector3.new(4.6, 0.9, 1.8),
		vary(STONE, rng, 0.1), M.Slate, { CanCollide = true })

	-- Detalles exteriores
	local wp = Props.Woodpile(m, base * CFrame.new(-W / 2 - 2.6, 0, D / 4) * CFrame.Angles(0, math.rad(90), 0), rng)
	wp.Name = "Leña"
	Props.Barrel(m, (base * CFrame.new(W / 2 + 1.8, 0, -D / 2 + 1.4)).Position, 0.9)
	Props.Crate(m, base * CFrame.new(W / 2 + 2, 0, -D / 2 + 4) * CFrame.Angles(0, 0.4, 0), 0.9)
	if broken then
		-- tablas sueltas apoyadas y una rueda de carreta rota
		Part(m, base * CFrame.new(-W / 2 + 1, 2, -D / 2 - 1) * CFrame.Angles(0.3, 0.2, 0.15), Vector3.new(1, 4.6, 0.25), WOOD_OLD, M.WoodPlanks)
		Part(m, base * CFrame.new(-W / 2 + 2, 1.8, -D / 2 - 0.9) * CFrame.Angles(0.35, -0.1, -0.1), Vector3.new(1, 4, 0.25),
			vary(WOOD_OLD, rng, 0.1), M.WoodPlanks)
		local wheel = Part(m, base * CFrame.new(W / 2 + 2.5, 0.25, D / 2 + 1) * CFrame.Angles(0, 0.4, 0), Vector3.new(0.35, 3.2, 3.2), POST, M.Wood,
			{ Shape = Enum.PartType.Cylinder })
		wheel.CFrame = wheel.CFrame * CFrame.Angles(0, 0, math.rad(90))
		Props.Stump(m, (base * CFrame.new(-W / 2 - 3, 0, -D / 2 - 2)).Position, rng, true)
	else
		local lantern = Props.Lantern(m, (base * CFrame.new(-doorW / 2 - 1.5, 0, -D / 2 - 1.8)).Position, rng, 4.8)
		lantern.Name = "FarolEntrada"
	end
	if level >= 3 then
		-- jardineras bajo las ventanas
		for _, sx in ipairs({ -1, 1 }) do
			local bx = base * CFrame.new(sx * (W / 2 - 3), y0 + winY0 - 0.7, -D / 2 - 0.7)
			Part(m, bx, Vector3.new(3.2, 0.8, 0.9), Color3.fromRGB(120, 80, 50), M.WoodPlanks)
			Props.Flowers(m, (bx * CFrame.new(0, 0.3, 0)).Position, rng, 4, 1.2)
		end
		-- anexo lateral con tejado de una sola caida
		local ax = base * CFrame.new(W / 2 + 3.2, 0, D / 4)
		plankWall(m, ax * CFrame.new(0, y0, -2.5), 5, 5, rng, wallColor, 0, {})
		plankWall(m, ax * CFrame.new(2.5, y0, 0) * CFrame.Angles(0, -math.rad(90), 0), 5, 5, rng, wallColor, 0, {})
		plankWall(m, ax * CFrame.new(0, y0, 2.5) * CFrame.Angles(0, math.pi, 0), 5, 5, rng, wallColor, 0, {})
		Part(m, ax * CFrame.new(0.2, y0 + 5.9, 0) * CFrame.Angles(0, 0, -0.25), Vector3.new(6.4, 0.35, 6.2), roofColor, M.Slate)
	end
	if level >= 5 then
		for i = -2, 2 do
			local c = Part(m, base * CFrame.new(i * W * 0.18, ridgeY + 1.4, 0) * CFrame.Angles(0.3 * i, 0.5, 0.2 * i),
				Vector3.new(0.8, 2.6 + (2 - math.abs(i)) * 0.7, 0.8), Color3.fromRGB(190, 130, 255), M.Neon, { CastShadow = false })
			c.Name = "Cristal"
		end
		local orb = Blob(m, base * CFrame.new(W / 2 - 3, ridgeY + 9, D / 4), Vector3.new(2.6, 2.6, 2.6), Color3.fromRGB(200, 150, 255), M.Neon,
			{ CastShadow = false })
		local l = Instance.new("PointLight")
		l.Color = orb.Color
		l.Range = 26
		l.Brightness = 2
		l.Parent = orb
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			Part(m, base * CFrame.new(math.cos(a) * (W / 2 + 3), 0.15, math.sin(a) * (D / 2 + 3)), Vector3.new(0.9, 0.2, 0.9),
				Color3.fromRGB(170, 120, 255), M.Neon, { CastShadow = false })
		end
	end
	return m, ridgeY
end

return House
