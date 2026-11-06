-- PetModels: construye el modelo visual de un PET.
-- 1) Si la especie tiene una plantilla importada valida en ReplicatedStorage.PetAssets
--    (ver PetAssets y docs/ART_PIPELINE.md), clona esa plantilla, la escala y le
--    añade los efectos de rareza.
-- 2) Si no, construye el modelo procedural con primitivas (respaldo permanente).
-- En ambos casos el modelo tiene una parte raiz (PrimaryPart) anclada; el resto va
-- unido a ella, por lo que basta con :PivotTo para mover todo el PET. El pivote
-- queda en el centro del PET y el frente mira hacia -Z.
-- Atributos comunes: Radius, Species, Rarity, Shiny, Source ("procedural" | "asset").
-- El aspecto nunca altera la especie, la rareza, el inventario ni los datos.
-- Shiny (opts.shiny): paleta alternativa (ShinyStyle) + particulas ligeras. Es
-- solo visual; un modelo importado puede tener su variante "<Modelo>_shiny".

local PetCatalog = require(script.Parent.PetCatalog)
local PetAssets = require(script.Parent.PetAssets)
local ShinyStyle = require(script.Parent.ShinyStyle)

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

-- Efectos de rareza y etiqueta (comunes a ambos tipos de modelo)
local function rarityEffects(model, body, sp, rar, u, opts, labelHeight)
	local order = rar.order
	local c2 = sp.color2
	if sp.shape == "round" or sp.flags.light then
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
		bb.StudsOffset = Vector3.new(0, labelHeight, 0)
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
end

local function buildProcedural(sp, rar, u, opts)
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

	rarityEffects(model, body, sp, rar, u, opts, u * 0.6 + 1.2)

	model:SetAttribute("Radius", u * 0.5)
	model:SetAttribute("Source", "procedural")
	return model
end

local SCRIPT_CLASSES = { Script = true, LocalScript = true, ModuleScript = true }

-- Modelo importado: clon de la plantilla, sin fisica, escalado al tamaño del PET
local function buildFromAsset(template, cfg, assetName, sp, rar, u, opts)
	local model = template:Clone()
	model.Name = sp.name
	for _, d in ipairs(model:GetDescendants()) do
		if SCRIPT_CLASSES[d.ClassName] then
			d:Destroy()
		end
	end
	local root = PetAssets.RootOf(model)
	if not root then
		model:Destroy()
		return nil
	end
	model.PrimaryPart = root

	-- Fisica: nada choca ni pesa; lo que no este unido a la raiz se suelda
	local joined = {}
	local okJ, list = pcall(function()
		return root:GetConnectedParts(true)
	end)
	if okJ and list then
		for _, p in ipairs(list) do
			joined[p] = true
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = d == root
			d.Massless = true
			d.CastShadow = false
			if d ~= root and not joined[d] then
				local w = Instance.new("WeldConstraint")
				w.Part0 = root
				w.Part1 = d
				w.Parent = d
			end
		end
	end
	root.Anchored = opts.anchored ~= false

	-- Escala: el alto final coincide con el PET procedural de la misma rareza
	local target = u * (cfg.heightFactor or 1)
	local baseHeight = template:GetAttribute("BaseHeight")
	if type(baseHeight) ~= "number" or baseHeight <= 0 then
		baseHeight = model:GetExtentsSize().Y
	end
	if baseHeight > 0.01 then
		local okS = pcall(function()
			model:ScaleTo(model:GetScale() * target / baseHeight)
		end)
		if not okS then
			warn("[PetModels] no se pudo escalar " .. assetName)
		end
	end

	-- Pivote en el centro vertical del PET, con la orientacion de la raiz (+ yaw)
	local bb, size = model:GetBoundingBox()
	local rot = root.CFrame - root.CFrame.Position
	local pivot = CFrame.new(root.Position.X, bb.Position.Y, root.Position.Z) * rot * CFrame.Angles(0, math.rad(cfg.yaw or 0), 0)
	root.PivotOffset = root.CFrame:Inverse() * pivot
	local height = size.Y

	if opts.hat then
		local function hatPart(name, size3, color, offset)
			local p = Instance.new("Part")
			p.Name = name
			p.Shape = Enum.PartType.Cylinder
			p.Size = size3
			p.Color = color
			p.Anchored = false
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.Massless = true
			p.CastShadow = false
			p.CFrame = pivot * offset
			p.Parent = model
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p
		end
		hatPart("HatBrim", Vector3.new(u * 0.05, u * 0.6, u * 0.6), Color3.fromRGB(60, 40, 120),
			CFrame.new(0, height * 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)))
		hatPart("HatTop", Vector3.new(u * 0.35, u * 0.35, u * 0.35), Color3.fromRGB(80, 50, 160),
			CFrame.new(0, height * 0.5 + u * 0.18, 0) * CFrame.Angles(0, 0, math.rad(90)))
	end

	rarityEffects(model, root, sp, rar, u, opts, height * 0.6 + 1.2)
	model:SetAttribute("Radius", height * 0.5)
	model:SetAttribute("Source", "asset")
	model:SetAttribute("AssetName", assetName)
	return model
end

-- Particulas Shiny ligeras (pocas, cortas, sin luz extra: aptas para moviles)
local function shinyParticles(body, u, color)
	local P = ShinyStyle.Particles
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "ShinySparkles"
	pe.Rate = P.rate
	pe.Lifetime = NumberRange.new(P.lifetime[1], P.lifetime[2])
	pe.Speed = NumberRange.new(P.speed[1], P.speed[2])
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, u * P.size),
		NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new(0.15, 1)
	pe.LightEmission = P.lightEmission
	pe.LightInfluence = 0
	pe.Color = ColorSequence.new(color)
	pe.Parent = body
	return pe
end

-- opts: { scale = 1, hat = bool, label = string|nil, anchored = true, procedural = bool, shiny = bool }
function PetModels.Build(speciesId, rarityId, opts)
	opts = opts or {}
	local sp = PetCatalog.Get(speciesId) or PetCatalog.Species[1]
	local rar = PetCatalog.Rarity(rarityId) or PetCatalog.Rarities[1]
	local u = 2 * (opts.scale or 1) * rar.size
	local shiny = opts.shiny == true
	local palette = shiny and ShinyStyle.Palette(sp) or nil
	local model = nil
	local tinted = false
	if not opts.procedural then
		local template, cfg, assetName, shinyVariant = PetAssets.Find(sp.id, rar.id, shiny)
		if template then
			local ok, res = pcall(buildFromAsset, template, cfg, assetName, sp, rar, u, opts)
			if ok and res then
				model = res
				tinted = shinyVariant == true
			else
				warn("[PetModels] fallo el modelo importado de " .. sp.name .. "; se usa el procedural. " .. tostring(res))
			end
		end
	end
	if not model then
		-- el procedural Shiny usa la paleta alternativa con la misma silueta
		local look = sp
		if palette then
			look = setmetatable({ color = palette.color, color2 = palette.color2 }, { __index = sp })
			tinted = true
		end
		model = buildProcedural(look, rar, u, opts)
	end
	model:SetAttribute("Species", sp.id)
	model:SetAttribute("Rarity", rar.id)
	if shiny then
		model:SetAttribute("Shiny", true)
		model:SetAttribute("ShinyTinted", tinted)
		if model.PrimaryPart then
			shinyParticles(model.PrimaryPart, u, palette.particle)
		end
	end
	return model
end

return PetModels
