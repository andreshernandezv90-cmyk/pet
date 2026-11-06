-- PetAnimator: controlador de animaciones para PETs con modelo importado y rig.
-- Los modelos procedurales no tienen rig: Attach devuelve nil y quien llama sigue
-- usando el rebote procedural de siempre.
--
-- Tres capas, de menor a mayor prioridad; solo suena UNA pista a la vez (con fundido):
--   base   estado continuo: Idle / Walk / Run / Work / CaptureReaction / Jump
--   sueño  Sleep_Enter -> Sleep_Loop, hasta Wake() o hasta que el PET se mueva
--   accion reaccion de una vez (Happy); al terminar vuelve a la capa de debajo
--
-- Uso:
--   local anim = PetAnimator.Attach(model)      -- nil si no hay rig o animaciones
--   anim:SetMoveSpeed(velocidad)                -- elige Idle / Walk / Run
--   anim:Play("Work")                           -- fija el estado base (con respaldo)
--   anim:Celebrate()                            -- Happy (preparado; sin mecanica aun)
--   anim:Sleep() / anim:Wake()                  -- sueño (preparado; sin mecanica aun)
--   anim:Destroy()
--
-- Funciona igual en el servidor (PETs trabajadores, jefe de incursion: las pistas
-- de un Animator del servidor se replican a todos) y en el cliente (PETs salvajes
-- privados y compañeros, que cada cliente construye y anima en local).
-- Las pistas se cargan una vez por modelo y se reutilizan; los objetos Animation
-- se comparten entre modelos (PetAssets.AnimationsFor).

local PetAssets = require(script.Parent.PetAssets)

local PetAnimator = {}
PetAnimator.__index = PetAnimator

local SPEED_EPSILON = 0.05

local function animatorOf(model)
	local holder = model:FindFirstChildOfClass("AnimationController") or model:FindFirstChildOfClass("Humanoid")
	if not holder then
		holder = Instance.new("AnimationController")
		holder.Name = "AnimationController"
		holder.Parent = model
	end
	local animator = holder:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = holder
	end
	return animator
end

local function priorityEnum(name)
	local ok, v = pcall(function()
		return Enum.AnimationPriority[name]
	end)
	return ok and v or nil
end

local function infoOf(state)
	return PetAssets.StateInfo[state] or {}
end

-- Devuelve un controlador o nil (modelo procedural, sin animaciones validas)
function PetAnimator.Attach(model)
	if not model or model:GetAttribute("Source") ~= "asset" then
		return nil
	end
	local species = model:GetAttribute("Species")
	local sources = PetAssets.AnimationsFor(model, species)
	if next(sources) == nil then
		return nil
	end
	local animator = animatorOf(model)
	local self = setmetatable({
		model = model,
		tracks = {},
		conns = {},
		current = nil, -- estado cuya pista suena
		speed = nil, -- velocidad aplicada a la pista actual
		base = "Idle", -- capa base pedida
		baseSpeed = 1,
		sleeping = false,
		action = nil, -- reaccion en curso (Happy)
		token = 0, -- invalida finales programados que ya no aplican
		alive = true,
	}, PetAnimator)
	for state, anim in pairs(sources) do
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			local info = infoOf(state)
			pcall(function()
				track.Looped = info.looped == true
				local pr = priorityEnum(info.priority)
				if pr then
					track.Priority = pr
				end
			end)
			self.tracks[state] = track
			if info.looped ~= true then
				-- Fin natural de una pista sin bucle (Happy, Sleep_Enter)
				local okS, sig = pcall(function()
					return track.Stopped
				end)
				if okS and sig then
					table.insert(self.conns, sig:Connect(function()
						self:_onTrackEnded(state, self.token)
					end))
				end
			end
		else
			warn("[PetAnimator] no se pudo cargar la animacion " .. state .. " de " .. tostring(species))
		end
	end
	if next(self.tracks) == nil then
		return nil
	end
	local okD, destroying = pcall(function()
		return model.Destroying
	end)
	if okD and destroying then
		table.insert(self.conns, destroying:Connect(function()
			self:Destroy()
		end))
	end
	return self
end

-- Estado disponible siguiendo la cadena de respaldo (Run -> Walk -> Idle ...)
function PetAnimator:Resolve(state)
	local s = state
	local guard = 0
	while s and not self.tracks[s] and guard < 6 do
		s = infoOf(s).fallback
		guard = guard + 1
	end
	return s
end

function PetAnimator:Has(state)
	return self.tracks[state] ~= nil
end

-- Estado que suena ahora (nil si ninguno)
function PetAnimator:GetState()
	return self.current
end

function PetAnimator:IsSleeping()
	return self.sleeping
end

-- Cambia la pista que suena con fundido cruzado; nunca deja dos estados a la vez
function PetAnimator:_switch(state, speed)
	local s = self:Resolve(state)
	if not s then
		return nil
	end
	local track = self.tracks[s]
	if self.current ~= s then
		local fade = infoOf(s).fade or PetAssets.Locomotion.fade
		local old = self.current and self.tracks[self.current]
		self.current = s -- antes de Stop: el aviso Stopped de la pista vieja se ignora
		if old then
			old:Stop(fade)
		end
		track:Play(fade, 1, speed or 1)
		self.speed = speed or 1
	elseif speed and (self.speed == nil or math.abs(self.speed - speed) > SPEED_EPSILON) then
		track:AdjustSpeed(speed)
		self.speed = speed
	end
	return s
end

-- Programa el paso siguiente un poco antes del final, para fundir sin saltar a la
-- pose de reposo. Si la duracion aun no se conoce, basta el aviso Stopped.
function PetAnimator:_scheduleEnd(state)
	local track = self.tracks[state]
	local token = self.token
	local okL, length = pcall(function()
		return track.Length
	end)
	if okL and type(length) == "number" and length > 0 then
		local fade = PetAssets.Locomotion.fade
		local wait = math.max(0, length / math.max(self.speed or 1, 0.01) - fade)
		task.delay(wait, function()
			self:_onTrackEnded(state, token)
		end)
	end
end

function PetAnimator:_onTrackEnded(state, token)
	if not self.alive or token ~= self.token or self.current ~= state then
		return
	end
	if state == "Sleep_Enter" and self.sleeping then
		self:_switch("Sleep_Loop", 1)
	elseif self.action == state then
		self.action = nil
		self.token = self.token + 1
		self:_restore()
	end
end

-- Vuelve a la capa activa de debajo de la reaccion
function PetAnimator:_restore()
	if self.sleeping then
		return self:_switch(self:Has("Sleep_Loop") and "Sleep_Loop" or "Sleep_Enter", 1)
	end
	return self:_switch(self.base, self.baseSpeed)
end

-- Compatibilidad con las llamadas existentes: Play(estado[, velocidad]).
-- Estados base fijan la capa base; Happy y Sleep_* van a su capa.
function PetAnimator:Play(state, speed)
	if not self.alive then
		return nil
	end
	local kind = infoOf(state).kind
	if kind == "action" then
		return self:PlayOnce(state)
	elseif kind == "sleep" then
		return self:Sleep() and self.current or nil
	end
	self.base = state
	self.baseSpeed = speed or 1
	if self.action or self.sleeping then
		return self:Resolve(state) -- se aplicara al terminar la reaccion o al despertar
	end
	return self:_switch(state, speed or 1)
end

-- Elige Idle / Walk / Run segun la velocidad horizontal (studs/s).
-- Si el PET se desplaza mientras duerme, despierta: nunca se desliza dormido.
function PetAnimator:SetMoveSpeed(v)
	local L = PetAssets.Locomotion
	if self.sleeping and v >= L.walk then
		self:Wake()
	end
	if v >= L.run then
		return self:Play("Run", math.clamp(v / L.referenceRunSpeed, 0.6, 1.8))
	elseif v >= L.walk then
		return self:Play("Walk", math.clamp(v / L.referenceWalkSpeed, 0.5, 1.8))
	end
	return self:Play("Idle", 1)
end

-- Estado de trabajo (PET asignado a una estacion)
function PetAnimator:SetWorking(on)
	return self:Play(on and "Work" or "Idle", 1)
end

-- Reaccion de una vez. Devuelve el estado o nil si el PET no la tiene o duerme.
function PetAnimator:PlayOnce(state)
	if not self.alive or self.sleeping or not self.tracks[state] then
		return nil
	end
	self.token = self.token + 1
	self.action = state
	local tr = self.tracks[state]
	if self.current == state then
		self.current = nil -- antes de Stop, para que su aviso Stopped se ignore
		tr:Stop(0) -- reiniciar desde el principio
	end
	self:_switch(state, 1)
	self:_scheduleEnd(state)
	return state
end

-- Celebracion (Happy). Preparada para una futura mecanica: hoy nada la llama.
function PetAnimator:Celebrate()
	return self:PlayOnce("Happy")
end

-- Dormir: Sleep_Enter y luego Sleep_Loop en bucle. Preparado para una futura
-- mecanica: hoy nada lo llama. Devuelve false si el PET no tiene animacion de sueño.
function PetAnimator:Sleep()
	if not self.alive then
		return false
	end
	if self.sleeping then
		return true
	end
	if not (self:Has("Sleep_Enter") or self:Has("Sleep_Loop")) then
		return false
	end
	self.sleeping = true
	self.action = nil
	self.token = self.token + 1
	if self:Has("Sleep_Enter") then
		self:_switch("Sleep_Enter", 1)
		self:_scheduleEnd("Sleep_Enter")
	else
		self:_switch("Sleep_Loop", 1)
	end
	return true
end

function PetAnimator:Wake()
	if not self.alive or not self.sleeping then
		return
	end
	self.sleeping = false
	self.token = self.token + 1
	self:_switch(self.base, self.baseSpeed)
end

function PetAnimator:Stop()
	self.token = self.token + 1
	self.current = nil
	self.speed = nil
	self.action = nil
	self.sleeping = false
	for _, t in pairs(self.tracks) do
		t:Stop(PetAssets.Locomotion.fade)
	end
end

function PetAnimator:Destroy()
	if self.alive then
		self:Stop()
		self.alive = false
		for _, c in ipairs(self.conns) do
			c:Disconnect()
		end
		self.conns = {}
		self.tracks = {}
	end
end

return PetAnimator
