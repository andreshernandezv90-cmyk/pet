-- World: registro y orquestador de la construccion del mundo.
-- Modulos: Helpers (utilidades), Home (santuario), Mines (Minas de Zuar),
-- Realm (Reino/Mundo PET). Fase A: misma geografia que v1.0, reorganizada en
-- modulos para poder reemplazar cada parte en las fases siguientes.
-- No depende de modelos externos.

local Helpers = require(script.Helpers)
local Home = require(script.Home)
local Mines = require(script.Mines)
local Realm = require(script.Realm)

local World = {}

World.HOME = Vector3.new(0, 0, 0)
World.MINES = Vector3.new(2000, 0, 0)
World.REALM = Vector3.new(-2000, 0, 0)
World.ARENA = Vector3.new(-2000, 0, -700)

World.Nodes = {} -- [id] = { id, type, model, part, pos, area }
World.Checkpoints = {} -- lista { part, zone, index, meadow }
World.Chests = {} -- [zone] = { part, prompt }
World.Portals = {} -- lista de { prompt, dest }
World.Spawns = {} -- [nombre] = CFrame
World.SpawnRegions = {} -- [zone] = { center = Vector3, sizeX, sizeZ }
World.PlotCenters = {} -- [i] = CFrame (mira hacia la plaza)
World.ArenaPillars = {} -- lista de Vector3

local root

function World.ZoneOrigin(k)
	return Vector3.new(-2000 + (k - 3) * 500, 0, 700)
end
-- Areas (para saber donde esta cada jugador) ------------------------------------------------

function World.AreaAt(pos)
	local x, z = pos.X, pos.Z
	if math.abs(x) <= 460 and math.abs(z) <= 460 then
		return "home"
	end
	if math.abs(x - World.MINES.X) <= 270 and math.abs(z - World.MINES.Z) <= 270 then
		return "mines"
	end
	if math.abs(x - World.ARENA.X) <= 110 and math.abs(z - World.ARENA.Z) <= 110 then
		return "arena"
	end
	if math.abs(x - World.REALM.X) <= 100 and math.abs(z - World.REALM.Z) <= 100 then
		return "realm"
	end
	for k = 1, 5 do
		local O = World.ZoneOrigin(k)
		if math.abs(x - O.X) <= 200 and z >= O.Z - 260 and z <= O.Z + 210 then
			return "z" .. k
		end
	end
	return "void"
end

-- Utilidades expuestas para otros servicios
World.Part = Helpers.Part
World.Slab = Helpers.Slab
World.Billboard = Helpers.Billboard
World.SignPost = Helpers.SignPost
World.AddPrompt = Helpers.AddPrompt
World.Portal = Helpers.Portal

function World.ZoneOfArea(area)
	local k = area and string.match(area, "^z(%d)$")
	return k and tonumber(k) or nil
end

function World.Build()
	-- La plantilla "Baseplate" de Studio choca con el suelo del Hogar: se retira.
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local old = workspace:FindFirstChild(name)
		if old and old:IsA("BasePart") then
			old:Destroy()
		end
	end
	root = Instance.new("Folder")
	root.Name = "World"
	root.Parent = workspace
	Helpers.Init(World)
	Home.Build(World, root)
	Mines.Build(World, root)
	Realm.Build(World, root)
	World.Root = root
end

return World
