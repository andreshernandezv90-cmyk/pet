-- PetModels: construye modelos de PETs con primitivas (sin assets externos).
-- Cada especie tiene una silueta reconocible y cada rareza efectos distintos.
-- El modelo tiene una parte raiz "Body" anclada; el resto va soldado a ella,
-- por lo que basta con mover Body (o usar :PivotTo) para mover todo el PET.

local PetCatalog = require(script.Parent.PetCatalog)

local PetModels = {}

local function newPart(className, props)
	local p = Instance.new(className)
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function attach(model, body, className, props, offset)
	local p = newPart(className, props)
	p.CFrame = body.CFrame * offset
	p.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = body
	w.Part1 = p
	w.Parent = p
	return p
end

-- opts: { scale = 1, hat = bool, label = string|nil, anchored = true }
function PetModels.Build(speciesId, rarityId, opts)
	opts = opts or {}
	local sp = PetCatalog.Get(speciesId) or PetCatalog.Species[1]
	local rar = PetCatalog.Rarity(rarityId) or PetCatalog.Rarities[1]
	local u = 2 * (opts.scale or 1) * rar.size

	local model = Instance.new("Model")
	model.Name = sp.name

	local bodyShape = Enum.PartType.Ball
	local bodyMat = Enum.Material.SmoothPlastic
	if sp.shape == "rock" then
		bodyMat = Enum.Material.Slate
	elseif sp.shape == "moss" then
		bodyMat = Enum.Material.Grass
	elseif sp.shape == "mist" or sp.shape == "prism" then
		bodyMat = Enum.Material.Glass
	elseif sp.shape == "crystal" then
		bodyMat = Enum.Material.Ice
	end

	local body = newPart("Part", {
		Name = "Body",
		Shape = bodyShape,
		Size = Vector3.new(u, u, u),
		Color = sp.color,
		Material = bodyMat,
		Anchored = opts.anchored ~= false,
		CanQuery = true,
		Transparency = (sp.shape == "mist") and 0.25 or 0,
	})
	if sp.shape == "prism" then
		body.Shape = Enum.PartType.Block
		body.Size = Vector3.new(u * 0.8, u * 0.8, u * 0.8)
		body.CFrame = CFrame.Angles(0, math.rad(45), math.rad(45))
		body.Reflectance = 0.2
	end
	if sp.shape == "rock" then
		body.Shape = Enum.PartType.Block
		body.Size = Vector3.new(u * 0.95, u * 0.85, u * 0.9)
	end
	body.Parent = model
	model.PrimaryPart = body
	-- El pivote siempre es "derecho" aunque el cuerpo este rotado (prisma)
	body.PivotOffset = body.CFrame:Inverse()

	-- Para que los accesorios queden alineados aunque el cuerpo este rotado (prisma)
	local frame = newPart("Part", { Name = "Frame", Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1, CFrame = CFrame.new() })
	frame.Parent = model
	local fw = Instance.new("WeldConstraint")
	fw.Part0 = body
	fw.Part1 = frame
	fw.Parent = frame
	local F = frame

	local function add(className, props, offset)
		return attach(model, F, className, props, offset)
	end

	-- Ojos (frente = -Z)
	local eyeColor = Color3.fromRGB(20, 20, 30)
	local eyeMat = Enum.Material.SmoothPlastic
	if sp.shape == "night" or sp.shape == "eclipse" then
		eyeColor = sp.color2
		eyeMat = Enum.Material.Neon
	end
	for _, sx in ipairs({ -1, 1 }) do
		add("Part", { Name = "Eye", Shape = Enum.PartType.Ball, Size = Vector3.new(u * 0.22, u * 0.26, u * 0.22),
			Color = eyeColor, Material = eyeMat }, CFrame.new(sx * u * 0.2, u * 0.1, -u * 0.42))
		add("Part", { Name = "Shine", Shape = Enum.PartType.Ball, Size = Vector3.new(u * 0.08, u * 0.08, u * 0.08),
			Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon }, CFrame.new(sx * u * 0.2 + u * 0.04, u * 0.16, -u * 0.52))
	end

	local c2 = sp.color2
	local shape = sp.shape
	if shape == "round" then
		add("Part", { Name = "Halo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(u * 0.06, u * 0.7, u * 0.7),
			Color = c2, Material = Enum.Material.Neon, Transparency = 0.2 }, CFrame.new(0, u * 0.72, 0) * CFrame.Angles(0, 0, math.rad(90)))
	elseif shape == "rock" then
		add("Part", { Name = "Rock", Size = Vector3.new(u * 0.35, u * 0.3, u * 0.35), Color = c2, Material = Enum.Material.Slate },
			CFrame.new(u * 0.2, u * 0.5, 0.1) * CFrame.Angles(0.4, 0.3, 0.2))
		add("Part", { Name = "Rock", Size = Vector3.new(u * 0.28, u * 0.25, u * 0.3), Color = c2, Material = Enum.Material.Slate },
			CFrame.new(-u * 0.22, u * 0.48, u * 0.1) * CFrame.Angles(-0.3, 0.6, 0.1))
	elseif shape == "spark" then
		for _, sx in ipairs({ -1, 1 }) do
			add("WedgePart", { Name = "Ear", Size = Vector3.new(u * 0.1, u * 0.5, u * 0.3), Color = c2, Material = Enum.Material.Neon },
				CFrame.new(sx * u * 0.28, u * 0.6, 0) * CFrame.Angles(0, 0, sx * -0.3))
		end
		add("WedgePart", { Name = "Tail", Size = Vector3.new(u * 0.1, u * 0.4, u * 0.4), Color = c2, Material = Enum.Material.Neon },
			CFrame.new(0, u * 0.2, u * 0.55) * CFrame.Angles(0.5, math.rad(180), 0))
	elseif shape == "mole" then
		add("Part", { Name = "Snout", Shape = Enum.PartType.Ball, Size = Vector3.new(u * 0.35, u * 0.3, u * 0.35), Color = c2 },
			CFrame.new(0, -u * 0.08, -u * 0.48))
		for _, sx in ipairs({ -1, 1 }) do
			add("Part", { Name = "Claw", Size = Vector3.new(u * 0.25, u * 0.08, u * 0.2), Color = Color3.fromRGB(240, 230, 210) },
				CFrame.new(sx * u * 0.35, -u * 0.38, -u * 0.25))
		end
	elseif shape == "night" then
		for _, sx in ipairs({ -1, 1 }) do
			add("WedgePart", { Name = "Ear", Size = Vector3.new(u * 0.08, u * 0.55, u * 0.35), Color = sp.color },
				CFrame.new(sx * u * 0.3, u * 0.6, 0) * CFrame.Angles(0, 0, sx * -0.4))
		end
		add("Part", { Name = "Wing", Size = Vector3.new(u * 1.4, u * 0.05, u * 0.45), Color = sp.color, Transparency = 0.1 },
			CFrame.new(0, u * 0.05, u * 0.15))
	elseif shape == "crystal" then
		for i, a in ipairs({ -0.5, 0, 0.5 }) do
			add("Part", { Name = "Crystal", Size = Vector3.new(u * 0.15, u * (0.45 + (i == 2 and 0.15 or 0)), u * 0.15), Color = c2,
				Material = Enum.Material.Neon }, CFrame.new(a * u * 0.4, u * 0.55, 0) * CFrame.Angles(0, 0.7, a))
		end
	elseif shape == "moss" then
		add("Part", { Name = "Leaf", Size = Vector3.new(u * 0.55, u * 0.05, u * 0.3), Color = c2, Material = Enum.Material.Grass },
			CFrame.new(0, u * 0.55, 0) * CFrame.Angles(0, 0.4, 0.3))
		add("Part", { Name = "Stem", Size = Vector3.new(u * 0.05, u * 0.2, u * 0.05), Color = c2 }, CFrame.new(0, u * 0.48, 0))
	elseif shape == "flame" then
		local tuft = add("Part", { Name = "Flame", Shape = Enum.PartType.Ball, Size = Vector3.new(u * 0.45, u * 0.55, u * 0.45), Color = c2,
			Material = Enum.Material.Neon, Transparency = 0.15 }, CFrame.new(0, u * 0.55, u * 0.05))
		local fire = Instance.new("Fire")
		fire.Size = math.max(2, u * 0.8)
		fire.Heat = 3
		fire.Color = Color3.fromRGB(255, 140, 40)
		fire.SecondaryColor = Color3.fromRGB(255, 230, 120)
		fire.Parent = tuft
	elseif shape == "flower" then
		for i = 1, 5 do
			local a = (i / 5) * math.pi * 2
			add("Part", { Name = "Petal", Shape = Enum.PartType.Ball, Size = Vector3.new(u * 0.32, u * 0.12, u * 0.32), Color = sp.color },
				CFrame.new(math.cos(a) * u * 0.25, u * 0.55, math.sin(a) * u * 0.25))
		end
		add("Part", { Name = "Center", Shape = Enum.PartType.Ball, Size = Vector3.new(u * 0.22, u * 0.16, u * 0.22), Color = c2 },
			CFrame.new(0, u * 0.6, 0))
	elseif shape == "mist" then
		add("Part", { Name = "Core", Shape = Enum.PartType.Ball, Size = Vector3.new(u * 0.55, u * 0.55, u * 0.55), Color = c2,
			Material = Enum.Material.Neon, Transparency = 0.5 }, CFrame.new(0, 0, 0))
	elseif shape == "wind" then
		for _, sx in ipairs({ -1, 1 }) do
			add("Part", { Name = "Wing", Size = Vector3.new(u * 0.05, u * 0.45, u * 0.7), Color = c2, Material = Enum.Material.Glass,
				Transparency = 0.3 }, CFrame.new(sx * u * 0.55, u * 0.15, u * 0.1) * CFrame.Angles(0, 0, sx * 0.5))
		end
	elseif shape == "prism" then
		add("Part", { Name = "Glow", Shape = Enum.PartType.Ball, Size = Vector3.new(u * 0.3, u * 0.3, u * 0.3), Color = c2,
			Material = Enum.Material.Neon }, CFrame.new(0, u * 0.65, 0))
	elseif shape == "gravity" then
		add("Part", { Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(u * 0.05, u * 1.5, u * 1.5), Color = c2,
			Material = Enum.Material.Neon, Transparency = 0.3 }, CFrame.Angles(0.4, 0, math.rad(90)))
	elseif shape == "astral" then
		add("Part", { Name = "Star", Size = Vector3.new(u * 0.08, u * 0.4, u * 0.4), Color = c2, Material = Enum.Material.Neon },
			CFrame.new(0, u * 0.7, 0) * CFrame.Angles(math.rad(45), 0, 0))
		add("Part", { Name = "Star", Size = Vector3.new(u * 0.08, u * 0.3, u * 0.3), Color = c2, Material = Enum.Material.Neon },
			CFrame.new(0, u * 0.7, 0))
	elseif shape == "eclipse" then
		add("Part", { Name = "Corona", Shape = Enum.PartType.Cylinder, Size = Vector3.new(u * 0.05, u * 1.45, u * 1.45), Color = c2,
			Material = Enum.Material.Neon, Transparency = 0.1 }, CFrame.new(0, 0, u * 0.12) * CFrame.Angles(0, math.rad(90), 0))
	end

	-- Sombrero cosmetico
	if opts.hat then
		add("Part", { Name = "HatBrim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(u * 0.05, u * 0.6, u * 0.6),
			Color = Color3.fromRGB(60, 40, 120) }, CFrame.new(0, u * 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)))
		add("Part", { Name = "HatTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(u * 0.35, u * 0.35, u * 0.35),
			Color = Color3.fromRGB(80, 50, 160) }, CFrame.new(0, u * 0.68, 0) * CFrame.Angles(0, 0, math.rad(90)))
	end

	-- Efectos de rareza
	local order = rar.order
	if shape == "round" or sp.flags.light then
		local l = Instance.new("PointLight")
		l.Color = c2
		l.Range = 10 + order * 2
		l.Brightness = 1
		l.Parent = body
	end
	if order >= 2 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = rar.color
		sparkles.Parent = body
	end
	if order >= 3 then
		local l = Instance.new("PointLight")
		l.Color = rar.color
		l.Range = 8 + order * 2
		l.Brightness = 1.5
		l.Parent = body
	end
	if order >= 4 then
		local hl = Instance.new("Highlight")
		hl.FillTransparency = 1
		hl.OutlineColor = rar.color
		hl.OutlineTransparency = 0.1
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = model
	end

	if opts.label then
		local bb = Instance.new("BillboardGui")
		bb.Name = "Tag"
		bb.Size = UDim2.new(0, 160, 0, 40)
		bb.StudsOffset = Vector3.new(0, u * 0.6 + 1.2, 0)
		bb.AlwaysOnTop = false
		bb.MaxDistance = 60
		bb.Parent = body
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, 0, 1, 0)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = rar.color
		t.TextStrokeTransparency = 0.3
		t.Text = opts.label
		t.Parent = bb
	end

	model:SetAttribute("Radius", u * 0.5)
	return model
end

return PetModels
