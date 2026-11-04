-- State (cliente): copia de solo lectura del perfil enviada por el servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Stats = require(Shared.Stats)

local State = {}
State.data = nil
State.offset = 0 -- serverTime - os.time() local

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

function State.Set(view)
	State.data = view
	if view and view.meta and view.meta.serverTime then
		State.offset = view.meta.serverTime - os.time()
	end
	changed:Fire(view)
end

-- Hora del servidor (segundos) estimada en el cliente
function State.Now()
	return os.time() + State.offset
end

function State.Agg()
	if not State.data then
		return nil
	end
	return Stats.Aggregate(State.data, State.Now())
end

function State.IsVip()
	return State.data and State.data.meta and State.data.meta.vip or false
end

return State
