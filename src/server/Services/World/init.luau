-- World: registro y orquestador de la construccion del mundo.
-- Modulos: Helpers (utilidades), Terrain, Props, House, StationArt, PlotLayout,
-- Lighting y los TRES MUNDOS (decision oficial GDD 1.1):
--   Home     -> Hogar Dimensional (santuario y parcelas)
--   Mines    -> Minas de Zuar (hub, Cantera libre y galerias I-V con vetas privadas)
--   PetWorld -> Reino de los PETs (campamento, 5 zonas, barreras, faros, retos y
--               arenas; las bocas de mina de cada zona llevan a su galeria)
-- No depende de modelos externos.

local Helpers = require(script.Helpers)
local Home = require(script.Home)
local Mines = require(script.Mines)
local PetWorld = require(script.PetWorld)

local World = {}

World.HOME = Vector3.new(0, 0, 0)
World.MINES = Vector3.new(2000, 0, 0)
World.ARENA = Vector3.new(0, 0, 0) -- lo define PetWorld (claro del campamento)
World.PetWorld = PetWorld
World.Mines = Mines

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
	local mines = Mines.AreaAt(x - World.MINES.X, z - World.MINES.Z)
	if mines then
		return mines -- "mines" (hub y cantera) o "m1".."m5" (galerias)
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

-- Galeria de las Minas de Zuar de un area ("m3" -> 3)
function World.GalleryOfArea(area)
	local k = area and string.match(area, "^m(%d)$")
	return k and tonumber(k) or nil
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
