-- Plots: parcela y santuario de cada jugador. La casa, las estaciones, los PETs
-- trabajadores y las decoraciones se ven en el mundo (GDD 01: "las mejoras son
-- visibles en el mundo, no solo numeros de interfaz").

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local PetModels = require(Shared.PetModels)
local Items = require(Shared.Items)

local Plots = {}
local S

local owners = {} -- [index] = player
local folders = {} -- [index] = Model
local plotFolder

local WOOD = Color3.fromRGB(150, 105, 65)
local DARKWOOD = Color3.fromRGB(95, 70, 50)

local function P(parent, cf, size, color, material, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if props then
		for k, v in pairs(props) do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

function Plots.Init(services)
	S = services
	plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plots"
	plotFolder.Parent = workspace
end

function Plots.IndexOf(player)
	for i, p in pairs(owners) do
		if p == player then
			return i
		end
	end
	return nil
end

function Plots.OwnerOf(index)
	return owners[index]
end

function Plots.SpawnCFrame(player)
	local i = Plots.IndexOf(player)
	if not i then
		return S.World.Spawns.hub
	end
	return S.World.PlotCenters[i] * CFrame.new(0, 4, -24)
end

-- Casa segun nivel del santuario -----------------------------------------------------------

local function buildHouse(parent, base, level)
	local w, d, h = 16, 12, 9
	if level >= 3 then
		w, d = 22, 14
	end
	local wallColor = level == 1 and DARKWOOD or WOOD
	local mat = Enum.Material.WoodPlanks
	local floorY = 0.4
	-- piso
	P(parent, base * CFrame.new(0, floorY + 0.5, 0), Vector3.new(w + 2, 1, d + 2), Color3.fromRGB(120, 110, 100), Enum.Material.Cobblestone)
	local y0 = floorY + 1
	-- paredes (la puerta mira hacia -Z, hacia la plaza)
	P(parent, base * CFrame.new(0, y0 + h / 2, d / 2), Vector3.new(w, h, 1), wallColor, mat)
	P(parent, base * CFrame.new(-w / 2, y0 + h / 2, 0), Vector3.new(1, h, d), wallColor, mat)
	P(parent, base * CFrame.new(w / 2, y0 + h / 2, 0), Vector3.new(1, h, d), wallColor, mat)
	local side = (w - 5) / 2
	P(parent, base * CFrame.new(-(w / 2 - side / 2), y0 + h / 2, -d / 2), Vector3.new(side, h, 1), wallColor, mat)
	P(parent, base * CFrame.new(w / 2 - side / 2, y0 + h / 2, -d / 2), Vector3.new(side, h, 1), wallColor, mat)
	P(parent, base * CFrame.new(0, y0 + h - 1.5, -d / 2), Vector3.new(5, 3, 1), wallColor, mat)
	-- ventanas
	local winColor = level == 1 and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(255, 230, 150)
	local winMat = level == 1 and Enum.Material.Wood or Enum.Material.Neon
	for _, sx in ipairs({ -1, 1 }) do
		P(parent, base * CFrame.new(sx * (w / 2 - side / 2), y0 + h / 2 + 1, -d / 2 - 0.55), Vector3.new(3, 2.5, 0.2), winColor, winMat)
	end
	if level == 1 then
		-- tablas cruzadas en ventanas y puerta rota
		for _, sx in ipairs({ -1, 1 }) do
			P(parent, base * CFrame.new(sx * (w / 2 - side / 2), y0 + h / 2 + 1, -d / 2 - 0.7) * CFrame.Angles(0, 0, 0.6),
				Vector3.new(3.6, 0.4, 0.2), DARKWOOD, Enum.Material.Wood)
		end
		P(parent, base * CFrame.new(1.5, y0 + 2.5, -d / 2 - 1) * CFrame.Angles(0, 0.4, 0.15), Vector3.new(4.6, 5.5, 0.4), DARKWOOD, Enum.Material.Wood)
	else
		P(parent, base * CFrame.new(0, y0 + 3, -d / 2 + 0.1), Vector3.new(4.6, 6, 0.4), Color3.fromRGB(120, 70, 40), Enum.Material.Wood)
	end
	-- techo de dos aguas (con hueco y tablas caidas en nivel 1)
	local roofColor = level == 1 and Color3.fromRGB(90, 60, 50) or (level >= 5 and Color3.fromRGB(110, 70, 170) or Color3.fromRGB(170, 70, 60))
	local theta = math.rad(32)
	local half = d / 2 / math.cos(theta) + 0.8
	local ry = y0 + h + math.tan(theta) * d / 4
	P(parent, base * CFrame.new(0, ry, -d / 4) * CFrame.Angles(-theta, 0, 0), Vector3.new(w + 2, 0.8, half), roofColor, Enum.Material.Slate)
	if level == 1 then
		P(parent, base * CFrame.new(-w / 4, ry, d / 4) * CFrame.Angles(theta, 0, 0), Vector3.new(w / 2, 0.8, half), roofColor, Enum.Material.Slate)
		P(parent, base * CFrame.new(w / 2 + 3, 1.2, d / 2 + 3) * CFrame.Angles(0.2, 0.7, 1.2), Vector3.new(6, 0.5, 2), DARKWOOD, Enum.Material.Wood)
	else
		P(parent, base * CFrame.new(0, ry, d / 4) * CFrame.Angles(theta, 0, 0), Vector3.new(w + 2, 0.8, half), roofColor, Enum.Material.Slate)
	end
	if level >= 3 then
		P(parent, base * CFrame.new(w / 3, y0 + h + 5, d / 4), Vector3.new(2.5, 7, 2.5), Color3.fromRGB(150, 90, 70), Enum.Material.Brick)
		for i = -2, 2 do
			P(parent, base * CFrame.new(i * 3, 1, -d / 2 - 2.5), Vector3.new(1.4, 1.4, 1.4), Color3.fromRGB(255, 120 + i * 20, 160),
				Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
		end
	end
	if level >= 4 then
		-- segundo piso
		local y1 = y0 + h + 4
		P(parent, base * CFrame.new(0, y1 + 3, d / 4), Vector3.new(w * 0.6, 6, d * 0.5), WOOD, mat)
		P(parent, base * CFrame.new(0, y1 + 3.2, d / 4 - d * 0.25 - 0.1), Vector3.new(3, 2, 0.2), Color3.fromRGB(255, 230, 150), Enum.Material.Neon)
		P(parent, base * CFrame.new(0, y1 + 6.4, d / 4), Vector3.new(w * 0.6 + 1.5, 0.8, d * 0.5 + 1.5), roofColor, Enum.Material.Slate)
	end
	if level >= 5 then
		-- torre dimensional
		P(parent, base * CFrame.new(-w / 2 - 3, y0 + 10, d / 4), Vector3.new(5, 20, 5), Color3.fromRGB(200, 190, 230), Enum.Material.Marble)
		local orb = P(parent, base * CFrame.new(-w / 2 - 3, y0 + 23, d / 4), Vector3.new(4, 4, 4), Color3.fromRGB(190, 120, 255), Enum.Material.Neon,
			{ Shape = Enum.PartType.Ball })
		local l = Instance.new("PointLight")
		l.Color = orb.Color
		l.Range = 30
		l.Brightness = 3
		l.Parent = orb
	end
	return y0 + h
end

-- Estaciones ---------------------------------------------------------------------------------

local STATION_SPOTS = {
	almacen = { x = -27, z = 24, name = "Almacen", panel = "bag", color = Color3.fromRGB(170, 130, 80) },
	taller = { x = 27, z = 24, name = "Taller y Herreria", panel = "workshop", color = Color3.fromRGB(120, 120, 130) },
	reactor = { x = -28, z = 6, name = "Reactor de Esencias", panel = "reactor", color = Color3.fromRGB(120, 220, 255) },
	fusionlab = { x = -18, z = 6, name = "Laboratorio de fusiones", panel = "fusion", color = Color3.fromRGB(255, 120, 220), building = "fusionLab" },
	alchemy = { x = 18, z = 6, name = "Laboratorio de alquimia", panel = "alchemy", color = Color3.fromRGB(150, 255, 150), building = "alchemy" },
	bait = { x = 28, z = 6, name = "Estacion de cebos", panel = "alchemy", color = Color3.fromRGB(255, 200, 120), building = "bait" },
	stone = { x = -28, z = -12, name = "Extractor de piedra", panel = "stations", station = "stone", color = Color3.fromRGB(150, 150, 150) },
	copper = { x = -17, z = -12, name = "Extractor de cobre", panel = "stations", station = "copper", color = Color3.fromRGB(205, 120, 60) },
	iron = { x = -6, z = -12, name = "Extractor de hierro", panel = "stations", station = "iron", color = Color3.fromRGB(170, 170, 185) },
	moon = { x = 5, z = -12, name = "Extractor lunar", panel = "stations", station = "moon", color = Color3.fromRGB(170, 190, 255) },
	zuarita = { x = 16, z = -12, name = "Refineria de Zuarita", panel = "stations", station = "zuarita", color = Color3.fromRGB(70, 230, 210) },
	nexus = { x = 27, z = -12, name = "Nexo dimensional", panel = "stations", station = "nexus", color = Color3.fromRGB(190, 120, 255) },
	garden = { x = 0, z = 6, name = "Huerto", panel = "stations", station = "garden", color = Color3.fromRGB(110, 80, 50) },
}

local function stationLevel(profile, spot)
	if spot.station then
		return profile.stations[spot.station].level
	end
	if spot.building then
		return profile.buildings[spot.building] or 0
	end
	return 1
end

local function addOpenPrompt(part, spotId, spot, index)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Abrir"
	pp.ObjectText = spot.name
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 10
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Panel", spot.panel)
	pp:SetAttribute("Plot", index)
	pp:SetAttribute("Spot", spotId)
	pp.Parent = part
	CollectionService:AddTag(pp, "PlotPrompt")
	return pp
end

local function buildStation(parent, base, spotId, spot, level, profile, index)
	local cf = base * CFrame.new(spot.x, 0, spot.z)
	local built = level >= 1
	if spotId == "garden" then
		local n = built and Items.GardenPlots[math.clamp(level, 1, 5)] or 2
		local pad
		for i = 1, 10 do
			local col = (i - 1) % 5
			local row = math.floor((i - 1) / 5)
			local pcf = cf * CFrame.new((col - 2) * 4, 0.5, (row - 0.5) * 4.5)
			local active = built and i <= n
			local soil = P(parent, pcf, Vector3.new(3.4, 0.6, 3.6), active and Color3.fromRGB(100, 70, 45) or Color3.fromRGB(150, 140, 120),
				Enum.Material.Ground, { Transparency = active and 0 or 0.6 })
			if i == 3 then
				pad = soil
			end
			local plot = active and profile.garden.plots[i] or nil
			if plot and plot.crop then
				local ready = (plot.progress or 0) >= 1
				local cropColor = plot.crop == "baya" and Color3.fromRGB(90, 90, 230) or (plot.crop == "raiz" and Color3.fromRGB(255, 140, 50)
					or Color3.fromRGB(255, 230, 80))
				P(parent, pcf * CFrame.new(0, 0.8, 0), Vector3.new(0.4, 1.2, 0.4), Color3.fromRGB(70, 160, 60), Enum.Material.Grass)
				P(parent, pcf * CFrame.new(0, ready and 1.8 or 1.4, 0), ready and Vector3.new(1.4, 1.4, 1.4) or Vector3.new(0.8, 0.8, 0.8),
					ready and cropColor or Color3.fromRGB(110, 200, 90), ready and Enum.Material.Neon or Enum.Material.Grass,
					{ Shape = Enum.PartType.Ball, CanCollide = false })
			end
		end
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 200, 0, 40)
		bb.StudsOffset = Vector3.new(0, 4, 0)
		bb.MaxDistance = 70
		bb.Parent = pad
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, 0, 1, 0)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(200, 255, 170)
		t.TextStrokeTransparency = 0.3
		t.Text = built and ("Huerto Nv." .. level) or "Huerto (se desbloquea en la Zona 3)"
		t.Parent = bb
		addOpenPrompt(pad, spotId, spot, index)
		return pad
	end

	local size = built and (4 + math.min(level, 5) * 0.5) or 4
	local main = P(parent, cf * CFrame.new(0, size / 2 + 0.4, 0), Vector3.new(size, size, size),
		built and spot.color or Color3.fromRGB(200, 200, 200), built and Enum.Material.Metal or Enum.Material.Glass,
		{ Transparency = built and 0 or 0.6 })
	if built then
		if spotId == "reactor" or spotId == "fusionlab" or spotId == "alchemy" or spotId == "nexus" or spotId == "moon" or spotId == "zuarita" then
			local core = P(parent, cf * CFrame.new(0, size + 1.5, 0), Vector3.new(2, 2, 2), spot.color, Enum.Material.Neon,
				{ Shape = Enum.PartType.Ball, CanCollide = false })
			local l = Instance.new("PointLight")
			l.Color = spot.color
			l.Range = 12
			l.Parent = core
		elseif spotId == "almacen" then
			P(parent, cf * CFrame.new(0, size + 0.7, 0), Vector3.new(size + 0.4, 0.6, size + 0.4), Color3.fromRGB(200, 160, 60), Enum.Material.Metal)
		elseif spot.station then
			-- torre de extraccion
			P(parent, cf * CFrame.new(0, size + 2, 0), Vector3.new(1, 4, 1), Color3.fromRGB(80, 80, 90), Enum.Material.Metal)
		end
	end
	local label = spot.name
	if spot.station then
		label = built and (spot.name .. " Nv." .. level) or (spot.name .. "\n(construir en el Taller)")
	elseif spot.building and not built then
		label = spot.name .. "\n(construir en el Taller)"
	elseif spotId == "taller" then
		label = "Taller · Herreria Nv." .. profile.buildings.forge
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 180, 0, 44)
	bb.StudsOffset = Vector3.new(0, size / 2 + 2.5, 0)
	bb.MaxDistance = 60
	bb.Parent = main
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Text = label
	t.Parent = bb
	addOpenPrompt(main, spotId, spot, index)
	return main
end

local function buildWorkers(parent, base, profile)
	for stationId, st in pairs(profile.stations) do
		local spot = STATION_SPOTS[stationId]
		if spot and st.level >= 1 then
			for i, id in ipairs(st.workers) do
				if i > 3 then
					break
				end
				local u = profile.units[id]
				if u then
					local m = PetModels.Build(u.s, u.r, { scale = 0.7 })
					local a = (i / 3) * math.pi * 2
					local off = stationId == "garden" and CFrame.new((i - 2) * 4, 2, -5) or CFrame.new(math.cos(a) * 4.5, 1.6, math.sin(a) * 4.5)
					m:PivotTo(base * CFrame.new(spot.x, 0, spot.z) * off)
					m.Parent = parent
					CollectionService:AddTag(m, "WorkerPet")
				end
			end
		end
	end
end

local DECOS = {
	fuente = function(parent, cf)
		P(parent, cf * CFrame.new(0, 1, 0), Vector3.new(2, 7, 7), Color3.fromRGB(200, 200, 210), Enum.Material.Marble,
			{ Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)) })
		P(parent, cf * CFrame.new(0, 2.1, 0), Vector3.new(0.3, 6, 6), Color3.fromRGB(120, 220, 255), Enum.Material.Neon,
			{ Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.3 })
	end,
	estatua = function(parent, cf)
		P(parent, cf * CFrame.new(0, 1, 0), Vector3.new(3, 2, 3), Color3.fromRGB(200, 200, 210), Enum.Material.Marble)
		P(parent, cf * CFrame.new(0, 4, 0) * CFrame.Angles(0, math.rad(45), math.rad(45)), Vector3.new(2.6, 2.6, 2.6),
			Color3.fromRGB(240, 200, 255), Enum.Material.Glass, { Reflectance = 0.3 })
	end,
	faroles = function(parent, cf)
		for _, sx in ipairs({ -2, 2 }) do
			P(parent, cf * CFrame.new(sx, 3, 0), Vector3.new(0.5, 6, 0.5), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
			local lamp = P(parent, cf * CFrame.new(sx, 6.4, 0), Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(255, 250, 180), Enum.Material.Neon,
				{ Shape = Enum.PartType.Ball })
			local l = Instance.new("PointLight")
			l.Range = 14
			l.Color = lamp.Color
			l.Parent = lamp
		end
	end,
	arco = function(parent, cf)
		for _, sx in ipairs({ -3, 3 }) do
			P(parent, cf * CFrame.new(sx, 4, 0), Vector3.new(1, 8, 1), Color3.fromRGB(40, 30, 50), Enum.Material.Slate)
		end
		P(parent, cf * CFrame.new(0, 8.5, 0), Vector3.new(7.5, 1, 1), Color3.fromRGB(255, 180, 60), Enum.Material.Neon)
	end,
}
local DECO_SPOTS = { fuente = -20, estatua = -8, faroles = 8, arco = 20 }

function Plots.Refresh(player)
	local i = Plots.IndexOf(player)
	local profile = S.Data.Get(player)
	if not i or not profile then
		return
	end
	local model = folders[i]
	if model then
		model:Destroy()
	end
	model = Instance.new("Model")
	model.Name = "Plot_" .. i
	local base = S.World.PlotCenters[i]
	local houseBase = base * CFrame.new(0, 0, 24)
	local roofY = buildHouse(model, houseBase, profile.buildings.sanctuary)

	-- letrero del dueño
	local signPart = P(model, base * CFrame.new(0, 3, -34), Vector3.new(10, 3, 0.6), Color3.fromRGB(150, 110, 70), Enum.Material.Wood)
	P(model, base * CFrame.new(0, 1, -34), Vector3.new(0.6, 2, 0.6), Color3.fromRGB(110, 80, 50), Enum.Material.Wood)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 260, 0, 60)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.MaxDistance = 150
	bb.Parent = signPart
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 240, 170)
	t.TextStrokeTransparency = 0.2
	local vip = S.Commerce and S.Commerce.IsVip(player, profile)
	t.Text = (vip and "👑 " or "") .. "Santuario de " .. player.DisplayName .. "\nNivel " .. profile.buildings.sanctuary
	t.Parent = bb
	local houseLabel = P(model, houseBase * CFrame.new(0, roofY + 6, 0), Vector3.new(1, 1, 1), Color3.new(1, 1, 1), nil,
		{ Transparency = 1, CanCollide = false })
	houseLabel.Name = "HouseAnchor"

	for spotId, spot in pairs(STATION_SPOTS) do
		local level = stationLevel(profile, spot)
		buildStation(model, base, spotId, spot, level, profile, i)
	end
	buildWorkers(model, base, profile)

	for id, x in pairs(DECO_SPOTS) do
		if profile.decorations[id] then
			DECOS[id](model, base * CFrame.new(x, 0, -28))
		end
	end
	if vip then
		P(model, base * CFrame.new(-31, 1, -30), Vector3.new(3, 2, 3), Color3.fromRGB(255, 210, 80), Enum.Material.Metal)
		P(model, base * CFrame.new(-31, 4, -30), Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(255, 210, 80), Enum.Material.Neon,
			{ Shape = Enum.PartType.Ball })
	end
	if profile.cosmetics.portal then
		local pcf = base * CFrame.new(31, 0, -30)
		P(model, pcf * CFrame.new(0, 5, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.4, 8, 8), Color3.fromRGB(255, 120, 255),
			Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, Transparency = 0.3, CanCollide = false })
	end
	model.Parent = plotFolder
	folders[i] = model
end

local function onPrompt(prompt, player)
	local idx = prompt:GetAttribute("Plot")
	local owner = owners[idx]
	if owner ~= player then
		S.Net.Notify(player, owner and ("Esta es la parcela de " .. owner.DisplayName .. ". ¡Puedes admirarla!") or "Parcela libre.", "info")
		return
	end
	local spot = prompt:GetAttribute("Spot")
	if spot == "almacen" then
		S.Inventory.DepositAll(player, S.Data.Get(player), true)
	end
	S.Net.Fire(player, "OpenPanel", prompt:GetAttribute("Panel"), spot)
end

function Plots.Assign(player)
	for i = 1, #S.World.PlotCenters do
		if not owners[i] then
			owners[i] = player
			player:SetAttribute("Plot", i)
			Plots.Refresh(player)
			return i
		end
	end
	return nil
end

function Plots.Start()
	local ProximityPromptService = game:GetService("ProximityPromptService")
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if CollectionService:HasTag(prompt, "PlotPrompt") then
			onPrompt(prompt, player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local i = Plots.IndexOf(player)
		if i then
			owners[i] = nil
			if folders[i] then
				folders[i]:Destroy()
				folders[i] = nil
			end
		end
	end)
end

return Plots
