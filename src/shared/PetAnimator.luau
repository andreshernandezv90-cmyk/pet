-- PetAnimator: animaciones configurables (Idle, Walk, Run, Jump, CaptureReaction)
-- para PETs con modelo importado. Los modelos procedurales no tienen rig: Attach
-- devuelve nil y quien llama sigue usando el rebote procedural de siempre.
--
-- Uso:
--   local anim = PetAnimator.Attach(model)      -- nil si no hay rig o animaciones
--   if anim then anim:SetMoveSpeed(velocidad) end -- elige Idle / Walk / Run
--   anim:Play("CaptureReaction")                 -- con respaldo si falta el estado
--   anim:Destroy()
--
-- Funciona igual en el servidor (PETs trabajadores, jefe de incursion) y en el
-- cliente (PETs salvajes privados y compañeros, que son modelos locales).

local PetAssets = require(script.Parent.PetAssets)

local PetAnimator = {}
PetAnimator.__index = PetAnimator

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
	local self = setmetatable({ model = model, tracks = {}, current = nil, alive = true }, PetAnimator)
	for state, anim in pairs(sources) do
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			local info = PetAssets.StateInfo[state]
			pcall(function()
				track.Looped = info.looped
				local pr = priorityEnum(info.priority)
				if pr then
					track.Priority = pr
				end
			end)
			self.tracks[state] = track
		else
			warn("[PetAnimator] no se pudo cargar la animacion " .. state .. " de " .. tostring(species))
		end
	end
	if next(self.tracks) == nil then
		return nil
	end
	return self
end

-- Estado disponible siguiendo la cadena de respaldo (Run -> Walk -> Idle ...)
function PetAnimator:Resolve(state)
	local s = state
	local guard = 0
	while s and not self.tracks[s] and guard < 6 do
		local info = PetAssets.StateInfo[s]
		s = info and info.fallback or nil
		guard = guard + 1
	end
	return s
end

function PetAnimator:Has(state)
	return self.tracks[state] ~= nil
end

function PetAnimator:Play(state, speed)
	if not self.alive then
		return nil
	end
	local s = self:Resolve(state)
	if not s then
		return nil
	end
	local fade = PetAssets.Locomotion.fade
	local track = self.tracks[s]
	if self.current ~= s then
		local old = self.current and self.tracks[self.current]
		if old then
			old:Stop(fade)
		end
		track:Play(fade)
		self.current = s
	end
	if speed then
		track:AdjustSpeed(speed)
	end
	return s
end

-- Elige Idle / Walk / Run segun la velocidad horizontal (studs/s)
function PetAnimator:SetMoveSpeed(v)
	local L = PetAssets.Locomotion
	if v >= L.run then
		return self:Play("Run", math.clamp(v / L.referenceRunSpeed, 0.6, 1.8))
	elseif v >= L.walk then
		return self:Play("Walk", math.clamp(v / L.referenceWalkSpeed, 0.5, 1.8))
	end
	return self:Play("Idle", 1)
end

function PetAnimator:Stop()
	for _, t in pairs(self.tracks) do
		t:Stop(PetAssets.Locomotion.fade)
	end
	self.current = nil
end

function PetAnimator:Destroy()
	if self.alive then
		self:Stop()
		self.alive = false
		self.tracks = {}
	end
end

return PetAnimator
