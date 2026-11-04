-- World/Home: Santuario (plaza, parcelas y bosque).
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Items)
local Progression = require(Shared.Progression)

local H = require(script.Parent.Helpers)
local part, folder, slab, billboard, signPost, addPrompt, portal, makeNode =
	H.Part, H.Folder, H.Slab, H.Billboard, H.SignPost, H.AddPrompt, H.Portal, H.MakeNode

local World, root
local Home = {}

-- HOGAR ------------------------------------------------------------------------------------

local function buildHome()
	local f = folder("Hogar", root)
	local H = World.HOME
	slab(f, H, 820, 820, 0, Color3.fromRGB(110, 170, 80), Enum.Material.Grass, "Pasto")
	part({ Name = "Plaza", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 84, 84),
		CFrame = CFrame.new(H + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(190, 185, 170), Material = Enum.Material.Cobblestone }, f)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnHogar"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = H + Vector3.new(0, 0.5, 0)
	spawn.Color = Color3.fromRGB(120, 200, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.4
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = f
	World.Spawns.hub = CFrame.new(H + Vector3.new(0, 4, 8))

	portal(f, H + Vector3.new(30, 0, 0), math.rad(90), "Minas de Zuar", Color3.fromRGB(255, 170, 70), "mines")
	portal(f, H + Vector3.new(-30, 0, 0), math.rad(-90), "Reino de los PETs", Color3.fromRGB(170, 120, 255), "realm")
	signPost(f, H + Vector3.new(0, 0, -30), "Hogar Dimensional\nTu parcela esta marcada con tu nombre", Color3.fromRGB(255, 240, 160))

	-- Parcelas (8 alrededor de la plaza)
	local plots = folder("Parcelas", f)
	for i = 1, 8 do
		local a = (i - 1) / 8 * math.pi * 2 + math.pi / 8
		local c = H + Vector3.new(math.cos(a) * 150, 0, math.sin(a) * 150)
		local cf = CFrame.lookAt(c, Vector3.new(H.X, 0, H.Z))
		World.PlotCenters[i] = cf
		part({ Name = "Parcela" .. i, Size = Vector3.new(72, 0.4, 72), CFrame = cf * CFrame.new(0, 0.2, 0),
			Color = Color3.fromRGB(150, 190, 110), Material = Enum.Material.Grass }, plots)
		-- camino hacia la plaza
		part({ Name = "Camino", Size = Vector3.new(8, 0.3, 72), CFrame = cf * CFrame.new(0, 0.15, -72),
			Color = Color3.fromRGB(200, 180, 140), Material = Enum.Material.Sand }, plots)
	end

	-- Bosque: anillo exterior
	local forest = folder("Bosque", f)
	local rng = Random.new(42)
	local placed = 0
	local tries = 0
	while placed < 60 and tries < 600 do
		tries = tries + 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(245, 385)
		local pos = H + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local ok = true
		for _, n in pairs(World.Nodes) do
			if n.area == "home" and (Vector3.new(n.pos.X, 0, n.pos.Z) - pos).Magnitude < 14 then
				ok = false
				break
			end
		end
		if ok then
			makeNode(forest, "tree", pos, "home", rng)
			placed = placed + 1
		end
	end
	signPost(f, H + Vector3.new(0, 0, 235), "Bosque: tala arboles para obtener madera 🪵", Color3.fromRGB(190, 255, 170))
	signPost(f, H + Vector3.new(0, 0, -235), "Bosque: tala arboles para obtener madera 🪵", Color3.fromRGB(190, 255, 170))
end

function Home.Build(world, rootFolder)
	World = world
	root = rootFolder
	buildHome()
end

return Home
