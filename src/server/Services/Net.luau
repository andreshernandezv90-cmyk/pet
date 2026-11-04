-- Net: remotos, enrutador de acciones con limite de frecuencia y sincronizacion
-- del estado del perfil hacia el cliente. Ninguna cantidad enviada por el
-- cliente se considera confiable: cada handler valida y recalcula. (GDD 17)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ProfileSchema = require(Shared.ProfileSchema)

local Net = {}
local S

Net.Handlers = {}
local remotes = {}
local buckets = {} -- [player] = { tokens, last }
local dirty = {}

local EVENTS = { "State", "Notify", "Encounters", "NodeState", "Raid", "Fx", "OpenPanel" }

function Net.Init(services)
	S = services
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	local action = Instance.new("RemoteFunction")
	action.Name = "Action"
	action.Parent = folder
	remotes.Action = action
	for _, name in ipairs(EVENTS) do
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = folder
		remotes[name] = ev
	end
	folder.Parent = ReplicatedStorage
end

function Net.Register(name, fn)
	Net.Handlers[name] = fn
end

local function allow(player)
	local now = os.clock()
	local b = buckets[player]
	if not b then
		b = { tokens = Config.ActionRateLimit, last = now }
		buckets[player] = b
	end
	b.tokens = math.min(Config.ActionRateLimit, b.tokens + (now - b.last) * Config.ActionRateLimit)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens = b.tokens - 1
	return true
end

-- Envia un evento a un jugador
function Net.Fire(player, eventName, ...)
	local ev = remotes[eventName]
	if ev and player and player.Parent then
		ev:FireClient(player, ...)
	end
end

function Net.FireAll(eventName, ...)
	local ev = remotes[eventName]
	if ev then
		ev:FireAllClients(...)
	end
end

function Net.Notify(player, text, kind)
	Net.Fire(player, "Notify", text, kind or "info")
end

function Net.MarkDirty(player)
	dirty[player] = true
end

-- Vista del perfil para el cliente (copia sin datos internos)
local function buildView(player, profile)
	local view = ProfileSchema.DeepCopy(profile)
	view.receipts = nil
	view.receiptOrder = nil
	view.meta = {
		serverTime = os.time(),
		persist = S.Data.IsPersistent(player),
		vip = S.Commerce and S.Commerce.IsVip(player, profile) or false,
		plot = player:GetAttribute("Plot"),
		studio = RunService:IsStudio(),
		devTools = RunService:IsStudio() and Config.DevToolsInStudio,
	}
	return view
end

function Net.PushNow(player)
	local profile = S.Data.Get(player)
	if profile then
		dirty[player] = nil
		Net.Fire(player, "State", buildView(player, profile))
	end
end

function Net.Start()
	remotes.Action.OnServerInvoke = function(player, name, payload)
		if type(name) ~= "string" then
			return { ok = false, msg = "Accion invalida" }
		end
		if not allow(player) then
			return { ok = false, msg = "Demasiado rapido" }
		end
		local profile = S.Data.Get(player)
		if not profile then
			return { ok = false, msg = "Tu perfil aun se esta cargando" }
		end
		local handler = Net.Handlers[name]
		if not handler then
			return { ok = false, msg = "Accion desconocida" }
		end
		if type(payload) ~= "table" then
			payload = {}
		end
		local ok, res = pcall(handler, player, profile, payload)
		if not ok then
			warn("[PortalPets] Error en accion " .. name .. ": " .. tostring(res))
			return { ok = false, msg = "Error del servidor" }
		end
		Net.MarkDirty(player)
		if type(res) ~= "table" then
			res = { ok = true }
		end
		return res
	end

	task.spawn(function()
		while true do
			task.wait(0.25)
			for player in pairs(dirty) do
				dirty[player] = nil
				if player.Parent then
					Net.PushNow(player)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
		dirty[player] = nil
	end)
end

return Net
