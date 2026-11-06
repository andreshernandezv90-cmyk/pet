-- DataService: carga/guardado en DataStore con version de esquema, migraciones,
-- bloqueo por sesion, reintentos, autosave y BindToClose. (GDD 17)
--
-- Formato guardado: { data = <perfil>, lock = { job = JobId, t = os.time() } | nil }
-- Si la carga falla en un servidor publicado, se expulsa al jugador en lugar de
-- arriesgar sobrescribir un perfil valido. Un registro ajeno (otra implementacion,
-- p. ej. Astra v0.6) o de una version futura NUNCA se migra ni se sobrescribe
-- (ProfileSchema.Classify, docs/COMPATIBILIDAD_ASTRA.md). En Studio sin acceso a API se juega
-- con un perfil temporal (no se guarda) y se avisa al jugador.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local ProfileSchema = require(Shared.ProfileSchema)

local DataService = {}
local S

local store = nil
local storeError = nil
local records = {} -- [player] = { data, persist, loaded, session }

local function keyFor(userId)
	return "u_" .. tostring(userId)
end

local function jobId()
	return game.JobId ~= "" and game.JobId or "studio"
end

function DataService.Init(services)
	S = services
	local ok, res = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = res
	else
		storeError = tostring(res)
		warn("[PortalPets] DataStore no disponible: " .. storeError)
	end
end

-- Devuelve: data, status ("ok" | "locked" | "foreign" | "error"), mensaje
local function tryLoad(userId)
	if not store then
		return nil, "error", storeError or "sin DataStore"
	end
	local data, status, why
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(userId), function(old)
			local now = os.time()
			local class, reason = ProfileSchema.Classify(old)
			if class == "foreign" then
				status = "foreign"
				why = reason
				return nil -- no se toca un perfil ajeno o futuro
			end
			if type(old) == "table" and type(old.lock) == "table" and old.lock.job ~= jobId()
				and now - (tonumber(old.lock.t) or 0) < Config.SessionLockStale then
				status = "locked"
				return nil -- cancela la escritura
			end
			local profile
			if type(old) == "table" and type(old.data) == "table" then
				profile = ProfileSchema.Migrate(old.data)
			else
				profile = ProfileSchema.Default()
				profile.createdAt = now
			end
			status = "ok"
			data = profile
			return { data = profile, lock = { job = jobId(), t = now } }
		end)
	end)
	if not ok then
		return nil, "error", tostring(err)
	end
	return data, status, why
end

local function studioNoApi(msg)
	if not RunService:IsStudio() then
		return false
	end
	msg = string.lower(msg or "")
	return string.find(msg, "studio") ~= nil or string.find(msg, "403") ~= nil or string.find(msg, "api") ~= nil
		or string.find(msg, "publish") ~= nil or store == nil
end

function DataService.Load(player)
	local data, status, msg
	for attempt = 1, Config.LoadRetries do
		data, status, msg = tryLoad(player.UserId)
		if status == "ok" or status == "foreign" then
			break
		end
		if status == "error" and studioNoApi(msg) then
			break
		end
		if not player.Parent then
			return nil
		end
		task.wait(status == "locked" and 4 or 2 * attempt)
	end
	if not player.Parent then
		return nil
	end
	local persist = true
	if status == "foreign" then
		warn("[PortalPets] El perfil de " .. player.Name .. " pertenece a otra version (" .. tostring(msg) .. "); no se modifica.")
		if RunService:IsStudio() then
			data = ProfileSchema.Default()
			data.createdAt = os.time()
			persist = false
		else
			player:Kick("Tus datos pertenecen a otra version de Portal Pets y no se modificaran. Entra a la experiencia correcta.")
			return nil
		end
	elseif status ~= "ok" then
		if status == "error" and studioNoApi(msg) then
			warn("[PortalPets] Studio sin acceso a DataStore; perfil temporal. Activa Game Settings > Security > Enable Studio Access to API Services.")
			data = ProfileSchema.Default()
			data.createdAt = os.time()
			persist = false
		else
			local reason = status == "locked" and "Tu partida sigue abierta en otro servidor. Intenta de nuevo en un minuto."
				or "No se pudieron cargar tus datos. Intenta de nuevo en unos minutos."
			player:Kick(reason)
			return nil
		end
	end
	local rec = {
		data = data,
		persist = persist,
		loaded = true,
		session = { nonces = {}, nonceOrder = {} },
		joinedAt = os.time(),
	}
	records[player] = rec
	return rec
end

local function save(player, rec, release)
	if not rec or not rec.persist or not store then
		return true
	end
	rec.data.lastSave = os.time()
	local payload = rec.data
	local ok, err = false, nil
	for attempt = 1, 3 do
		ok, err = pcall(function()
			store:UpdateAsync(keyFor(player.UserId), function(old)
				if ProfileSchema.Classify(old) == "foreign" then
					return nil -- jamas sobrescribir un registro ajeno o futuro
				end
				if type(old) == "table" and type(old.lock) == "table" and old.lock.job ~= jobId()
					and os.time() - (tonumber(old.lock.t) or 0) < Config.SessionLockStale then
					-- otro servidor tomo la sesion: no sobrescribir
					return nil
				end
				return { data = payload, lock = (not release) and { job = jobId(), t = os.time() } or nil }
			end)
		end)
		if ok then
			break
		end
		task.wait(attempt)
	end
	if not ok then
		warn("[PortalPets] Error al guardar " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function DataService.Get(player)
	local rec = records[player]
	return rec and rec.data or nil
end

function DataService.Record(player)
	return records[player]
end

function DataService.Session(player)
	local rec = records[player]
	return rec and rec.session or nil
end

function DataService.IsPersistent(player)
	local rec = records[player]
	return rec ~= nil and rec.persist
end

function DataService.SaveNow(player)
	return save(player, records[player], false)
end

-- Control de idempotencia de una operacion de cliente (nonce)
function DataService.CheckNonce(player, nonce)
	local rec = records[player]
	if not rec or type(nonce) ~= "string" or #nonce > 64 then
		return true, nil
	end
	local cached = rec.session.nonces[nonce]
	if cached then
		return false, cached
	end
	return true, nil
end

function DataService.StoreNonce(player, nonce, result)
	local rec = records[player]
	if not rec or type(nonce) ~= "string" or #nonce > 64 then
		return
	end
	rec.session.nonces[nonce] = result
	table.insert(rec.session.nonceOrder, nonce)
	if #rec.session.nonceOrder > 50 then
		local old = table.remove(rec.session.nonceOrder, 1)
		rec.session.nonces[old] = nil
	end
end

function DataService.Release(player)
	local rec = records[player]
	if not rec then
		return
	end
	if S.Production then
		S.Production.AccrueAll(player, rec.data)
	end
	save(player, rec, true)
	records[player] = nil
end

function DataService.Start()
	-- Autosave
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for player, rec in pairs(records) do
				if player.Parent then
					task.spawn(save, player, rec, false)
				end
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player, rec in pairs(records) do
			pending = pending + 1
			task.spawn(function()
				save(player, rec, true)
				pending = pending - 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.2)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		DataService.Release(player)
	end)
end

return DataService
