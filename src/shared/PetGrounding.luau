-- PetGrounding: apoyo vertical de PETs con modelo importado (rig esqueletico).
--
-- Referencia estable: el atributo GroundOffset que PetModels calcula al construir
-- el modelo = distancia del pivote a la base de la malla EN REPOSO (las suelas).
-- Nunca se mide la malla animada: la altura del pivote no depende de la animacion,
-- asi que los saltos de Run/Happy y el cuerpo tumbado de Sleep se conservan tal
-- cual vienen del rig (las animaciones de Lumi no tienen root motion y en Idle y
-- Walk las patas quedan exactamente en la base de reposo).
--
-- El suelo se busca con un raycast hacia abajo (respeta CanCollide, ignora agua,
-- PETs y personajes). La altura y la normal se suavizan para que no haya saltos
-- ni vibraciones; en pendientes el PET se inclina hacia la normal (con limite).
--
-- Los PETs procedurales no usan este modulo (conservan su colocacion de siempre).

local Players = game:GetService("Players")

local PetGrounding = {}

PetGrounding.Config = {
	maxTilt = math.rad(20), -- inclinacion maxima en pendientes
	heightRate = 14, -- suavizado de altura (1/s): ~70 ms para seguir un escalon
	tiltRate = 8, -- suavizado de la inclinacion (1/s)
	probeAbove = 3, -- el rayo empieza este alto sobre el ultimo suelo conocido
	probeBelow = 14, -- y baja hasta aqui por debajo
	firstProbeAbove = 9, -- primera busqueda por defecto (colinas de hasta 7 studs)
	reprobeDistance = 0.3, -- studs horizontales entre raycasts
	reprobeTime = 0.25, -- o cada tantos segundos aunque no se mueva
}

local UP = Vector3.new(0, 1, 0)

-- Distancia pivote -> suelas en reposo; nil si el modelo no es importado
function PetGrounding.Offset(model)
	if not model or model:GetAttribute("Source") ~= "asset" then
		return nil
	end
	local off = model:GetAttribute("GroundOffset")
	if type(off) == "number" then
		return off
	end
	return model:GetAttribute("Radius")
end

local params = nil
local paramsAt = -math.huge
local function rayParams()
	local now = os.clock()
	if params == nil or now - paramsAt > 1 then
		paramsAt = now
		params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true
		pcall(function()
			params.RespectCanCollide = true -- decoracion sin colision (hierba, hojas) y PETs no cuentan
		end)
		local exclude = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(exclude, p.Character)
			end
		end
		params.FilterDescendantsInstances = exclude
	end
	return params
end

-- Suelo bajo (x, z) buscando desde topY hacia abajo. Devuelve y, normal o nil.
function PetGrounding.Probe(x, z, topY, depth)
	local origin = Vector3.new(x, topY, z)
	local hit = workspace:Raycast(origin, Vector3.new(0, -depth, 0), rayParams())
	if hit then
		return hit.Position.Y, hit.Normal
	end
	return nil
end

-- CFrame del pivote para apoyar las suelas en groundPos, mirando hacia look
-- (horizontal) e inclinado hacia normal (limitado a Config.maxTilt).
function PetGrounding.PivotCFrame(groundPos, normal, look, offset)
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		flat = Vector3.new(0, 0, -1)
	end
	local yaw = CFrame.lookAt(Vector3.new(), flat.Unit)
	local up = UP
	if normal and normal.Y > 0.05 then
		local n = normal.Unit
		local angle = math.acos(math.clamp(n:Dot(UP), -1, 1))
		if angle > 1e-3 then
			local axis = UP:Cross(n)
			if axis.Magnitude > 1e-6 then
				local tilt = CFrame.fromAxisAngle(axis.Unit, math.min(angle, PetGrounding.Config.maxTilt))
				yaw = tilt * yaw
				up = tilt:VectorToWorldSpace(UP)
			end
		end
	end
	return CFrame.new(groundPos + up * offset) * yaw
end

-- Seguidor de suelo por PET (estado de suavizado y de raycasts)
local Tracker = {}
Tracker.__index = Tracker

-- firstAbove: altura de la primera busqueda sobre refY (por defecto Config.firstProbeAbove).
-- Para compañeros conviene poca (un techo encima no debe contar como suelo).
function PetGrounding.Tracker(firstAbove)
	return setmetatable({ y = nil, normal = UP, lastX = nil, lastZ = nil, lastAt = -math.huge, targetY = nil, targetN = UP,
		firstAbove = firstAbove }, Tracker)
end

-- Altura de suelo suavizada bajo (x, z). refY: suelo esperado si nunca se encontro
-- (aparicion) o si el rayo no encuentra nada (respaldo). Devuelve y, normal.
function Tracker:Step(x, z, refY, dt)
	local C = PetGrounding.Config
	local now = os.clock()
	local moved = self.lastX == nil or math.abs(x - self.lastX) + math.abs(z - self.lastZ) > C.reprobeDistance
	if moved or now - self.lastAt >= C.reprobeTime then
		local firstTop = refY + (self.firstAbove or C.firstProbeAbove)
		local top = self.targetY and (self.targetY + C.probeAbove) or firstTop
		local gy, n = PetGrounding.Probe(x, z, top, (top - refY) + C.probeBelow)
		if not gy and top < firstTop then
			-- el rayo corto nacio dentro del terreno (desnivel brusco): buscar desde mas arriba
			gy, n = PetGrounding.Probe(x, z, firstTop, (firstTop - refY) + C.probeBelow)
		end
		self.targetY = gy or refY
		self.targetN = n or UP
		self.lastX, self.lastZ, self.lastAt = x, z, now
	end
	if self.y == nil then
		self.y = self.targetY -- primera vez: sin animacion de caida desde 0
		self.normal = self.targetN
	else
		local a = 1 - math.exp(-C.heightRate * (dt or 0))
		self.y = self.y + (self.targetY - self.y) * a
		local b = 1 - math.exp(-C.tiltRate * (dt or 0))
		local n = self.normal:Lerp(self.targetN, b)
		self.normal = n.Magnitude > 1e-3 and n.Unit or UP
	end
	return self.y, self.normal
end

-- Colocacion puntual (sin suavizado), p. ej. trabajadores en su estacion.
-- Devuelve el CFrame del pivote o nil si no hay suelo entre refY+above y refY-below.
function PetGrounding.Snap(model, x, z, refY, look, above, below)
	local offset = PetGrounding.Offset(model)
	if not offset then
		return nil
	end
	local top = refY + (above or 6)
	local gy, n = PetGrounding.Probe(x, z, top, (above or 6) + (below or 6))
	if not gy then
		return nil
	end
	return PetGrounding.PivotCFrame(Vector3.new(x, gy, z), n, look, offset)
end

return PetGrounding
