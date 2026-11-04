-- Net (cliente): invocacion de acciones del servidor y escucha de eventos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Net = {}
local remotes
local notifyHandler = nil

function Net.Init()
	remotes = ReplicatedStorage:WaitForChild("Remotes")
end

function Net.SetNotifier(fn)
	notifyHandler = fn
end

function Net.Nonce()
	return HttpService:GenerateGUID(false)
end

-- Llama una accion. Muestra el mensaje del servidor salvo opts.silent.
function Net.Call(name, payload, opts)
	local ok, res = pcall(function()
		return remotes:WaitForChild("Action"):InvokeServer(name, payload or {})
	end)
	if not ok or type(res) ~= "table" then
		res = { ok = false, msg = "Sin conexion con el servidor." }
	end
	if notifyHandler and res.msg and not (opts and opts.silent) then
		notifyHandler(res.msg, res.ok and "success" or "error")
	end
	return res
end

-- Igual que Call pero sin bloquear al llamador
function Net.Send(name, payload, opts, callback)
	task.spawn(function()
		local r = Net.Call(name, payload, opts)
		if callback then
			callback(r)
		end
	end)
end

function Net.On(eventName, fn)
	return remotes:WaitForChild(eventName).OnClientEvent:Connect(fn)
end

return Net
