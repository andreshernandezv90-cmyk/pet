-- World: registro y orquestador de la construccion del mundo.
-- Modulos: Helpers (utilidades), Terrain, Props, House, StationArt, PlotLayout,
-- Lighting, Home (santuario), Mines (Minas de Zuar separadas: temporales hasta
-- la Fase D) y PetWorld (Mundo PET continuo con campamento, 5 zonas, barreras,
-- faros, retos opcionales y arena). No depende de modelos externos.

local Helpers = require(script.Helpers)
local Home = require(script.Home)
local Mines = require(script.Mines)
local PetWorld = require(script.PetWorld)

local World = {}

World.HOME = Vector3.new(0, 0, 0)
World.MINES = Vector3.new(2000, 0, 0)
World.ARENA = Vector3.new(0, 0, 0) -- lo define PetWorld (claro del campamento)
World.PetWorld = PetWorld

World.Nodes = {} -- [id] = { id, type, model, part, pos, area }
World.Checkpoints = {} -- lista { part, zone, index, meadow }
World.Chests = {} -- [zone] = { part, prompt }
World.Portals = {} -- lista de { prompt, dest }
World.Spawns = {} -- [nombre] = CFrame
World.SpawnRegions = {} -- [zone] = { center = Vector3, sizeX, sizeZ }
World.PlotCenters = {} -- [i] = CFrame (mira hacia la plaza)
World.ArenaPillars = {} -- lista de Vector3
World.BarrierX = {} -- [zona] = X mundial de la barrera que protege esa zona
World.Gates = {} -- [zona] = CFrame frente a la puerta (lado ya desbloqueado)
World.Beacons = {} -- [id] = { id, zone, model, prompt }
World.GiftSpots = {} -- [zona] = lista de Vector3

local root

-- Areas (para saber donde esta cada jugador) ------------------------------------------------

function World.AreaAt(pos)
	local x, z = pos.X, pos.Z
	if math.abs(x) <= 460 and math.abs(z) <= 460 then
		return "home"
	end
	if math.abs(x - World.MINES.X) <= 270 and math.abs(z - World.MINES.Z) <= 270 then
		return "mines"
	end
	local O = PetWorld.Origin
	local area = PetWorld.LocalArea(x - O.X, z - O.Z)
	return area or "void"
end

-- Zona del Mundo PET a la que pertenece una posicion (por x), aunque sea la arena o el campamento
function World.ZoneAtX(x)
	local lx = x - PetWorld.Origin.X
	if lx < PetWorld.CampLength then
		return 0
	end
	for k = 1, 5 do
		if lx < PetWorld.ZoneEnd[k] then
			return k
		end
	end
	return 5
end

function World.ZoneCenter(k)
	return PetWorld.ZoneCenter(k)
end

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
	PetWorld.Build(World, root)
	World.Root = root
end

return World
