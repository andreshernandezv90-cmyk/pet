-- Plots: parcela y santuario de cada jugador. La casa, las estaciones, los PETs
-- trabajadores y las decoraciones se ven en el mundo (GDD 01: "las mejoras son
-- visibles en el mundo, no solo numeros de interfaz").
-- El bosque, los caminos y el portal de cada parcela son estaticos (World/Home);
-- aqui se construye lo que depende del progreso del dueño.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PetModels = require(Shared.PetModels)
local PetAnimator = require(Shared.PetAnimator)
local Items = require(Shared.Items)

local WorldFolder = script.Parent:WaitForChild("World")
local Props = require(WorldFolder.Props)
local House = require(WorldFolder.House)
local StationArt = require(WorldFolder.StationArt)
local PlotLayout = require(WorldFolder.PlotLayout)

local Plots = {}
local S

local owners = {} -- [index] = player
local folders = {} -- [index] = Model
local plotFolder

local Part, Blob, Disc, Column = Props.Part, Props.Blob, Props.Disc, Props.Column
local Mat = Enum.Material

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

-- Aparece frente al portal, mirando hacia su casa
function Plots.SpawnCFrame(player)
	local i = Plots.IndexOf(player)
	if not i then
		return S.World.Spawns.hub
	end
	local sp = PlotLayout.Spawn
	return S.World.PlotCenters[i] * CFrame.new(sp.x, 4, sp.z) * CFrame.Angles(0, math.pi, 0)
end

-- Estaciones -------------------------------------------------------------------------------

local STATIONS = {
	almacen = { name = "Almacen", panel = "bag" },
	taller = { name = "Taller y Herreria", panel = "workshop" },
	reactor = { name = "Reactor de Esencias", panel = "reactor" },
	fusionlab = { name = "Laboratorio de fusiones", panel = "fusion", building = "fusionLab" },
	alchemy = { name = "Laboratorio de alquimia", panel = "alchemy", building = "alchemy" },
	bait = { name = "Estacion de cebos", panel = "alchemy", building = "bait" },
	stone = { name = "Extractor de piedra", panel = "stations", station = "stone" },
	copper = { name = "Extractor de cobre", panel = "stations", station = "copper" },
	iron = { name = "Extractor de hierro", panel = "stations", station = "iron" },
	moon = { name = "Extractor lunar", panel = "stations", station = "moon" },
	zuarita = { name = "Refineria de Zuarita", panel = "stations", station = "zuarita" },
	nexus = { name = "Nexo dimensional", panel = "stations", station = "nexus" },
	garden = { name = "Huerto", panel = "stations", station = "garden" },
}
Plots.Stations = STATIONS

local function stationLevel(profile, info)
	if info.station then
		return profile.stations[info.station].level
	end
	if info.building then
		return profile.buildings[info.building] or 0
	end
	return 1
end

local function addOpenPrompt(part, spotId, info, index)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Abrir"
	pp.ObjectText = info.name
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 11
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Panel", info.panel)
	pp:SetAttribute("Plot", index)
	pp:SetAttribute("Spot", spotId)
	pp.Parent = part
	CollectionService:AddTag(pp, "PlotPrompt")
	return pp
end

local function label(part, text, height)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 230, 0, 50)
	bb.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	bb.MaxDistance = 85
	bb.LightInfluence = 0
	bb.Parent = part
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 1, 0)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 250, 230)
	t.TextStrokeTransparency = 0.25
	t.Text = text
	t.Parent = bb
	return bb
end

local function buildGarden(parent, cf, level, profile, index, rng)
	local g = PlotLayout.Spots.garden
	local built = level >= 1
	local n = built and Items.GardenPlots[math.clamp(level, 1, 5)] or 0
	local anchor
	for i = 1, 10 do
		local col = (i - 1) % 5
		local row = math.floor((i - 1) / 5)
		local bcf = cf * CFrame.new((col - 2) * 4.8, 0, (row - 0.5) * 5.4)
		local active = i <= n
		if built then
			local soil = StationArt.GardenBed(parent, bcf, active, active and profile.garden.plots[i] or nil)
			if i == 3 then
				anchor = soil
			end
		end
	end
	if built then
		-- espantapajaros y regadera
		local sc = cf * CFrame.new(g.w / 2 + 1.5, 0, 0)
		Part(parent, sc * CFrame.new(0, 2.6, 0), Vector3.new(0.35, 5.2, 0.35), Color3.fromRGB(110, 80, 56), Mat.Wood)
		Part(parent, sc * CFrame.new(0, 3.8, 0), Vector3.new(3.2, 0.3, 0.3), Color3.fromRGB(110, 80, 56), Mat.Wood)
		Part(parent, sc * CFrame.new(0, 3.5, 0), Vector3.new(1.6, 1.8, 0.9), Color3.fromRGB(80, 120, 170), Mat.Fabric)
		Blob(parent, sc * CFrame.new(0, 4.9, 0), Vector3.new(1.2, 1.3, 1.2), Color3.fromRGB(230, 200, 140), Mat.Fabric)
		Part(parent, sc * CFrame.new(0, 5.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.2, 2.2, 2.2), Color3.fromRGB(200, 170, 90), Mat.Fabric,
			{ Shape = Enum.PartType.Cylinder })
	else
		anchor = StationArt.Unbuilt(parent, cf, rng, STATIONS.garden)
	end
	addOpenPrompt(anchor, "garden", STATIONS.garden, index)
	label(anchor, built and ("Huerto Nv." .. level) or "Huerto\n(se desbloquea en la Zona 3)", built and 3 or 3.5)
end

local function buildStation(parent, base, spotId, level, profile, index, rng)
	local info = STATIONS[spotId]
	local spot = PlotLayout.Spots[spotId]
	-- las estaciones miran hacia el centro de la parcela
	local cf = base * CFrame.new(spot.x, 0, spot.z)
	if spotId == "garden" then
		return buildGarden(parent, cf, level, profile, index, rng)
	end
	local m = Instance.new("Model")
	m.Name = spotId
	m.Parent = parent
	local built = level >= 1
	local main, height
	if not built then
		main, height = StationArt.Unbuilt(m, cf, rng, info)
	elseif info.station then
		main, height = StationArt.Extractor(m, cf, level, rng, spotId)
	else
		main, height = StationArt[spotId](m, cf, level, rng)
	end
	local text = info.name
	if info.station then
		text = built and (info.name .. " Nv." .. level) or (info.name .. "\n(construir en el Taller)")
	elseif info.building and not built then
		text = info.name .. "\n(construir en el Taller)"
	elseif spotId == "taller" then
		text = "Taller · Herreria Nv." .. profile.buildings.forge
	end
	addOpenPrompt(main, spotId, info, index)
	label(main, text, height)
	return main
end

local function buildWorkers(parent, base, profile)
	for stationId, st in pairs(profile.stations) do
		local spot = PlotLayout.Spots[stationId]
		if spot and st.level >= 1 then
			for i, id in ipairs(st.workers) do
				if i > 3 then
					break
				end
				local u = profile.units[id]
				if u then
					local m = PetModels.Build(u.s, u.r, { scale = 0.7, shiny = u.shiny })
					local off
					if stationId == "garden" then
						off = CFrame.new((i - 2) * 6, 2, -spot.d / 2 - 2)
					else
						local a = (i / 3) * math.pi * 2 + 0.5
						off = CFrame.new(math.cos(a) * 4.6, 1.6, math.sin(a) * 4.6 - 1)
					end
					m:PivotTo(base * CFrame.new(spot.x, 0, spot.z) * off)
					m.Parent = parent
					CollectionService:AddTag(m, "WorkerPet")
					local anim = PetAnimator.Attach(m) -- solo modelos importados con animaciones
					if anim then
						anim:Play("Idle")
					end
				end
			end
		end
	end
end

-- Decoraciones compradas con materiales -------------------------------------------------

local DECOS = {
	fuente = function(parent, cf)
		Disc(parent, (cf * CFrame.new(0, 0.6, 0)).Position, 7, 1.2, Color3.fromRGB(200, 200, 210), Mat.Marble, { CanCollide = true })
		Disc(parent, (cf * CFrame.new(0, 1.15, 0)).Position, 6, 0.15, Color3.fromRGB(120, 220, 255), Mat.Glass, { Transparency = 0.25 })
		Column(parent, (cf * CFrame.new(0, 1, 0)).Position, 2.4, 0.8, Color3.fromRGB(210, 210, 220), Mat.Marble)
		local q = Part(parent, cf * CFrame.new(0, 3.9, 0) * CFrame.Angles(0.5, 0.5, 0), Vector3.new(0.9, 1.5, 0.9), Color3.fromRGB(200, 255, 240), Mat.Neon,
			{ CastShadow = false })
		local l = Instance.new("PointLight")
		l.Color = q.Color
		l.Range = 10
		l.Parent = q
	end,
	estatua = function(parent, cf)
		Part(parent, cf * CFrame.new(0, 1, 0), Vector3.new(3, 2, 3), Color3.fromRGB(200, 200, 210), Mat.Marble, { CanCollide = true })
		Part(parent, cf * CFrame.new(0, 4, 0) * CFrame.Angles(0, math.rad(45), math.rad(45)), Vector3.new(2.6, 2.6, 2.6), Color3.fromRGB(240, 200, 255),
			Mat.Glass, { Reflectance = 0.3 })
	end,
	faroles = function(parent, cf, rng)
		for _, sx in ipairs({ -2.5, 2.5 }) do
			local lamp = Props.Lantern(parent, (cf * CFrame.new(sx, 0, 0)).Position, rng, 6)
			for _, d in ipairs(lamp:GetDescendants()) do
				if d:IsA("PointLight") then
					d.Color = Color3.fromRGB(190, 210, 255)
				end
			end
		end
	end,
	arco = function(parent, cf)
		for _, sx in ipairs({ -3.6, 3.6 }) do
			Part(parent, cf * CFrame.new(sx, 4, 0), Vector3.new(1, 8, 1), Color3.fromRGB(40, 30, 50), Mat.Slate, { CanCollide = true })
		end
		Part(parent, cf * CFrame.new(0, 8.5, 0), Vector3.new(8.4, 1, 1), Color3.fromRGB(255, 180, 60), Mat.Neon)
	end,
}

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
	-- semilla fija por parcela: la casa no "cambia de forma" al recargar
	local rng = Random.new(9000 + i * 31 + profile.buildings.sanctuary)
	local hp = PlotLayout.House
	local _, ridgeY = House.Build(model, base * CFrame.new(hp.x, 0, hp.z), profile.buildings.sanctuary, rng)

	-- Letrero del dueño en la entrada
	local vip = S.Commerce and S.Commerce.IsVip(player, profile)
	local sg = PlotLayout.Sign
	local signModel, signText = Props.Sign(model, base * CFrame.new(sg.x, 0, sg.z), "", 8)
	signText.Text = (vip and "👑 " or "") .. "Santuario de " .. player.DisplayName .. "\nNivel " .. profile.buildings.sanctuary
	signModel.Name = "LetreroDueño"
	local bbPart = signModel:FindFirstChildWhichIsA("BasePart")
	label(bbPart, player.DisplayName, 6)

	local srng = Random.new(7000 + i)
	for spotId, info in pairs(STATIONS) do
		buildStation(model, base, spotId, stationLevel(profile, info), profile, i, srng)
	end
	buildWorkers(model, base, profile)

	for id, fn in pairs(DECOS) do
		if profile.decorations[id] then
			local d = PlotLayout.Decos[id]
			fn(model, base * CFrame.new(d.x, 0, d.z), srng)
		end
	end
	if vip then
		local d = PlotLayout.Decos.vip
		local vcf = base * CFrame.new(d.x, 0, d.z)
		Part(model, vcf * CFrame.new(0, 1, 0), Vector3.new(3, 2, 3), Color3.fromRGB(255, 210, 80), Mat.Metal, { CanCollide = true })
		Blob(model, vcf * CFrame.new(0, 4, 0), Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(255, 210, 80), Mat.Neon)
	end
	if profile.cosmetics.portal and not profile.cosmetics.hide_portal then
		local d = PlotLayout.Decos.portal
		local pm = Props.Portal(model, base * CFrame.new(d.x, 0, d.z) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(255, 120, 255), srng)
		pm.Name = "PortalDecorativo"
	end
	model:SetAttribute("RoofY", ridgeY)
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
