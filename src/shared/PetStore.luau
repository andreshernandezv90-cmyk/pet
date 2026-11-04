-- PetStore: logica pura de inventario (pilas, individuos, tanque, almacen, mochila).
-- El servidor es el unico que la usa para modificar perfiles; el cliente solo la
-- usa para mostrar conteos. (GDD 05, 12, 14 y 17)

local Config = require(script.Parent.Config)
local PetCatalog = require(script.Parent.PetCatalog)
local Progression = require(script.Parent.Progression)
local Items = require(script.Parent.Items)

local PetStore = {}

local STACK = Config.PetStackSize
local RSTACK = Config.ResourceStackSize

local function ceilDiv(n, d)
	if n <= 0 then
		return 0
	end
	return math.floor((n + d - 1) / d)
end
PetStore.CeilDiv = ceilDiv

-- PETs -------------------------------------------------------------------------------

function PetStore.Capacity(profile, loc)
	if loc == "tank" then
		return Progression.TankSlots(profile)
	end
	return Progression.PetStorageSlots(profile)
end

function PetStore.Used(profile, loc)
	local used = 0
	for _, n in pairs(profile.stacks[loc]) do
		used = used + ceilDiv(n, STACK)
	end
	for _, u in pairs(profile.units) do
		if u.st == "free" and u.loc == loc then
			used = used + 1
		end
	end
	return used
end

-- Espacios que se necesitarian tras agregar n PETs ordinarios de una clave
function PetStore.SlotsAfterAdd(profile, loc, key, n)
	local old = profile.stacks[loc][key] or 0
	return PetStore.Used(profile, loc) - ceilDiv(old, STACK) + ceilDiv(old + n, STACK)
end

function PetStore.CanAdd(profile, loc, key, n)
	return PetStore.SlotsAfterAdd(profile, loc, key, n or 1) <= PetStore.Capacity(profile, loc)
end

function PetStore.Add(profile, loc, key, n)
	profile.stacks[loc][key] = (profile.stacks[loc][key] or 0) + n
end

-- Registra descubrimiento/captura
function PetStore.Register(profile, speciesId, rarityId)
	profile.dex[PetCatalog.Key(speciesId, rarityId)] = true
	profile.captured[speciesId] = (profile.captured[speciesId] or 0) + 1
end

-- Agrega un PET nuevo: tanque -> almacen -> (force) almacen excedido.
-- Devuelve la ubicacion o nil si no cupo y no se forzo.
function PetStore.Give(profile, speciesId, rarityId, force)
	local key = PetCatalog.Key(speciesId, rarityId)
	if PetStore.CanAdd(profile, "tank", key, 1) then
		PetStore.Add(profile, "tank", key, 1)
		return "tank"
	end
	if PetStore.CanAdd(profile, "storage", key, 1) or force then
		PetStore.Add(profile, "storage", key, 1)
		return "storage"
	end
	return nil
end

function PetStore.StackCount(profile, key)
	return (profile.stacks.tank[key] or 0) + (profile.stacks.storage[key] or 0)
end

-- Retira n PETs ordinarios (primero del tanque, luego del almacen)
function PetStore.Take(profile, key, n)
	if PetStore.StackCount(profile, key) < n then
		return false
	end
	local fromTank = math.min(profile.stacks.tank[key] or 0, n)
	if fromTank > 0 then
		profile.stacks.tank[key] = profile.stacks.tank[key] - fromTank
		if profile.stacks.tank[key] <= 0 then
			profile.stacks.tank[key] = nil
		end
	end
	local rest = n - fromTank
	if rest > 0 then
		profile.stacks.storage[key] = profile.stacks.storage[key] - rest
		if profile.stacks.storage[key] <= 0 then
			profile.stacks.storage[key] = nil
		end
	end
	return true
end

-- Saca un ejemplar de una pila y le da identidad propia
function PetStore.Individualize(profile, key)
	local s, r = PetCatalog.ParseKey(key)
	if not s then
		return nil
	end
	local loc
	if (profile.stacks.storage[key] or 0) > 0 then
		loc = "storage"
	elseif (profile.stacks.tank[key] or 0) > 0 then
		loc = "tank"
	else
		return nil
	end
	profile.stacks[loc][key] = profile.stacks[loc][key] - 1
	if profile.stacks[loc][key] <= 0 then
		profile.stacks[loc][key] = nil
	end
	local id = "u" .. tostring(profile.nextUnitId)
	profile.nextUnitId = profile.nextUnitId + 1
	local unit = { id = id, s = s, r = r, lv = 0, st = "free", lock = false, loc = loc }
	profile.units[id] = unit
	return unit
end

-- Resuelve una referencia del cliente: { unit = "u12" } o { key = "lumi:rare" }
-- Solo devuelve unidades libres (o la unidad indicada si allowBusy).
function PetStore.Resolve(profile, ref, allowBusy)
	if type(ref) ~= "table" then
		return nil
	end
	if type(ref.unit) == "string" then
		local u = profile.units[ref.unit]
		if u and (allowBusy or u.st == "free") then
			return u
		end
		return nil
	end
	if type(ref.key) == "string" and PetCatalog.ParseKey(ref.key) then
		return PetStore.Individualize(profile, ref.key)
	end
	return nil
end

-- Si un individuo vuelve a ser ordinario (nivel 0, libre, sin proteccion), regresa a su pila
function PetStore.TryMerge(profile, unit)
	if unit.st == "free" and unit.lv == 0 and not unit.lock then
		local key = PetCatalog.Key(unit.s, unit.r)
		local loc = unit.loc == "tank" and "tank" or "storage"
		profile.stacks[loc][key] = (profile.stacks[loc][key] or 0) + 1
		profile.units[unit.id] = nil
		return true
	end
	return false
end

-- Libera una unidad de cualquier uso y la devuelve al inventario
function PetStore.Release(profile, unit)
	local idx = table.find(profile.team, unit.id)
	if idx then
		table.remove(profile.team, idx)
	end
	for _, st in pairs(profile.stations) do
		local wi = table.find(st.workers, unit.id)
		if wi then
			table.remove(st.workers, wi)
		end
	end
	unit.st = "free"
	if unit.loc ~= "tank" then
		unit.loc = "storage"
	end
	PetStore.TryMerge(profile, unit)
end

-- Envia todo el tanque al almacen del santuario (lo que quepa)
function PetStore.DepositPets(profile)
	local moved = 0
	local keys = {}
	for key in pairs(profile.stacks.tank) do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		local n = profile.stacks.tank[key]
		-- mover la mayor cantidad posible que quepa
		local lo, hi = 0, n
		while lo < hi do
			local mid = math.floor((lo + hi + 1) / 2)
			if PetStore.CanAdd(profile, "storage", key, mid) then
				lo = mid
			else
				hi = mid - 1
			end
		end
		if lo > 0 then
			profile.stacks.tank[key] = n - lo
			if profile.stacks.tank[key] <= 0 then
				profile.stacks.tank[key] = nil
			end
			PetStore.Add(profile, "storage", key, lo)
			moved = moved + lo
		end
	end
	for _, u in pairs(profile.units) do
		if u.st == "free" and u.loc == "tank" then
			if PetStore.Used(profile, "storage") < PetStore.Capacity(profile, "storage") then
				u.loc = "storage"
				moved = moved + 1
			end
		end
	end
	return moved
end

-- Lista ordenada de entradas del inventario (para la interfaz)
function PetStore.Entries(profile)
	local list = {}
	local merged = {}
	for _, loc in ipairs({ "tank", "storage" }) do
		for key, n in pairs(profile.stacks[loc]) do
			merged[key] = merged[key] or { tank = 0, storage = 0 }
			merged[key][loc] = merged[key][loc] + n
		end
	end
	for key, c in pairs(merged) do
		local s, r = PetCatalog.ParseKey(key)
		if s then
			table.insert(list, { kind = "stack", key = key, s = s, r = r, lv = 0, tank = c.tank, storage = c.storage,
				count = c.tank + c.storage })
		end
	end
	for id, u in pairs(profile.units) do
		table.insert(list, { kind = "unit", unit = id, key = PetCatalog.Key(u.s, u.r), s = u.s, r = u.r, lv = u.lv,
			st = u.st, lock = u.lock, loc = u.loc, count = 1 })
	end
	table.sort(list, function(a, b)
		local sa, sb = PetCatalog.Get(a.s), PetCatalog.Get(b.s)
		if sa.num ~= sb.num then
			return sa.num < sb.num
		end
		local ra, rb = PetCatalog.Rarity(a.r).order, PetCatalog.Rarity(b.r).order
		if ra ~= rb then
			return ra > rb
		end
		if a.kind ~= b.kind then
			return a.kind == "unit"
		end
		return (a.lv or 0) > (b.lv or 0)
	end)
	return list
end

-- Recursos ---------------------------------------------------------------------------

function PetStore.BackpackUsed(profile)
	local used = 0
	for _, n in pairs(profile.res.backpack) do
		used = used + ceilDiv(n, RSTACK)
	end
	return used
end

-- Cuanto de un recurso cabe todavia en la mochila
function PetStore.BackpackRoom(profile, resId)
	local cap = Progression.BackpackSlots(profile)
	local used = PetStore.BackpackUsed(profile)
	local have = profile.res.backpack[resId] or 0
	local partial = ceilDiv(have, RSTACK) * RSTACK - have
	return math.max(0, (cap - used) * RSTACK + partial)
end

-- Agrega a la mochila lo que quepa; devuelve la cantidad agregada
function PetStore.AddToBackpack(profile, resId, n)
	if not Items.Resources[resId] then
		return 0
	end
	local add = math.min(n, PetStore.BackpackRoom(profile, resId))
	if add > 0 then
		profile.res.backpack[resId] = (profile.res.backpack[resId] or 0) + add
	end
	return add
end

function PetStore.AddToStorage(profile, resId, n)
	if not Items.Resources[resId] or n <= 0 then
		return 0
	end
	profile.res.storage[resId] = (profile.res.storage[resId] or 0) + n
	return n
end

function PetStore.ResTotal(profile, resId)
	return (profile.res.backpack[resId] or 0) + (profile.res.storage[resId] or 0)
end

function PetStore.HasCost(profile, cost)
	for id, n in pairs(cost) do
		if PetStore.ResTotal(profile, id) < n then
			return false
		end
	end
	return true
end

-- Gasta primero del almacen y luego de la mochila
function PetStore.SpendCost(profile, cost)
	if not PetStore.HasCost(profile, cost) then
		return false
	end
	for id, n in pairs(cost) do
		local fromStorage = math.min(profile.res.storage[id] or 0, n)
		profile.res.storage[id] = (profile.res.storage[id] or 0) - fromStorage
		if profile.res.storage[id] <= 0 then
			profile.res.storage[id] = nil
		end
		local rest = n - fromStorage
		if rest > 0 then
			profile.res.backpack[id] = profile.res.backpack[id] - rest
			if profile.res.backpack[id] <= 0 then
				profile.res.backpack[id] = nil
			end
		end
	end
	return true
end

function PetStore.DepositResources(profile)
	local moved = 0
	for id, n in pairs(profile.res.backpack) do
		profile.res.storage[id] = (profile.res.storage[id] or 0) + n
		moved = moved + n
	end
	profile.res.backpack = {}
	return moved
end

return PetStore
