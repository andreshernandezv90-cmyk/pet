-- World/Realm: Reino de los PETs (hub, 5 zonas con parkour y arena).
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Items)
local Progression = require(Shared.Progression)

local H = require(script.Parent.Helpers)
local part, folder, slab, billboard, signPost, addPrompt, portal, makeNode =
	H.Part, H.Folder, H.Slab, H.Billboard, H.SignPost, H.AddPrompt, H.Portal, H.MakeNode

local World, root
local Realm = {}

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

function Realm.Build(world, rootFolder)
	World = world
	root = rootFolder
	buildRealm()
end

return Realm
