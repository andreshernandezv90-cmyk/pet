-- Fusion (FusionService): Resonancia Dimensional. Dos PETs de especies
-- distintas se combinan 20 minutos; sus ejemplares quedan reservados y luego
-- regresan al inventario. Recarga 30 min (VIP 24 min), 1 simultanea (VIP 2).
-- (GDD 10)

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Progression = require(Shared.Progression)

local Fusion = {}
local S

local function ensureSlots(player, profile)
	local n = Progression.FusionSlots(profile, S.Commerce.IsVip(player, profile))
	while #profile.fusion.slots < n do
		table.insert(profile.fusion.slots, { cooldownUntil = 0 })
	end
	return n
end

local function finish(player, profile, slot, now)
	local f = slot.fusion
	if not f then
		return
	end
	for _, part in ipairs({ f.a, f.b }) do
		local u = profile.units[part.id]
		if u then
			PetStore.Release(profile, u)
		end
	end
	slot.fusion = nil
	local factor = S.Commerce.IsVip(player, profile) and Config.VipCooldownFactor or 1
	slot.cooldownUntil = now + math.floor(Config.FusionCooldown * factor)
end

-- Termina fusiones vencidas
function Fusion.Update(player, profile)
	local now = os.time()
	local changed = false
	for _, slot in ipairs(profile.fusion.slots) do
		if slot.fusion and slot.fusion.endsAt <= now then
			local name = slot.fusion.name
			finish(player, profile, slot, now)
			changed = true
			S.Net.Notify(player, "La fusion " .. name .. " termino. Tus PETs volvieron al inventario.", "info")
		end
	end
	if changed then
		S.Inventory.RefreshPlayer(player)
		S.Net.MarkDirty(player)
	end
end

function Fusion.Init(services)
	S = services
	S.Net.Register("fuse", function(player, profile, payload)
		local n = ensureSlots(player, profile)
		if n < 1 then
			return { ok = false, msg = "Construye el Laboratorio de fusiones (Santuario 3 + Zona 4)." }
		end
		local now = os.time()
		local free
		for i = 1, n do
			local slot = profile.fusion.slots[i]
			if not slot.fusion and (slot.cooldownUntil or 0) <= now then
				free = slot
				break
			end
		end
		if not free then
			return { ok = false, msg = "No hay espacio de fusion disponible (en uso o en recarga)." }
		end
		local refA, refB = payload.a, payload.b
		if type(refA) ~= "table" or type(refB) ~= "table" then
			return { ok = false, msg = "Elige dos PETs." }
		end
		-- validar especies antes de individualizar
		local function speciesOf(ref)
			if type(ref.unit) == "string" then
				local u = profile.units[ref.unit]
				return u and u.st == "free" and u.s or nil
			end
			local s = PetCatalog.ParseKey(ref.key)
			return s and PetStore.StackCount(profile, ref.key) > 0 and s or nil
		end
		local sa, sb = speciesOf(refA), speciesOf(refB)
		if not sa or not sb then
			return { ok = false, msg = "Uno de los PETs no esta disponible." }
		end
		if sa == sb then
			return { ok = false, msg = "La resonancia requiere dos especies distintas." }
		end
		local ua = PetStore.Resolve(profile, refA)
		local ub = ua and PetStore.Resolve(profile, refB)
		if not ua or not ub then
			if ua then
				PetStore.TryMerge(profile, ua)
			end
			return { ok = false, msg = "Uno de los PETs no esta disponible." }
		end
		ua.st = "fused"
		ub.st = "fused"
		local name = PetCatalog.FusionName(ua.s, ub.s)
		profile.fusion.nextId = (profile.fusion.nextId or 1) + 1
		free.fusion = {
			id = "f" .. profile.fusion.nextId,
			name = name,
			a = { id = ua.id, s = ua.s, r = ua.r, lv = ua.lv },
			b = { id = ub.id, s = ub.s, r = ub.r, lv = ub.lv },
			startedAt = now,
			endsAt = now + Config.FusionDuration,
		}
		local combo = ua.s < ub.s and (ua.s .. "+" .. ub.s) or (ub.s .. "+" .. ua.s)
		local isNew = not profile.fusion.discovered[combo]
		profile.fusion.discovered[combo] = name
		S.Inventory.RefreshPlayer(player)
		return { ok = true, msg = "✨ ¡Resonancia! Nace " .. name .. (isNew and " (nueva en tu coleccion)" or "") .. " durante 20 minutos." }
	end)

	S.Net.Register("endFusion", function(player, profile, payload)
		local i = tonumber(payload.slot)
		local slot = i and profile.fusion.slots[i]
		if not slot or not slot.fusion then
			return { ok = false, msg = "No hay fusion activa ahi." }
		end
		finish(player, profile, slot, os.time())
		S.Inventory.RefreshPlayer(player)
		return { ok = true, msg = "Fusion terminada. Inicia la recarga." }
	end)
end

function Fusion.Start()
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = S.Data.Get(player)
				if profile then
					ensureSlots(player, profile)
					Fusion.Update(player, profile)
				end
			end
		end
	end)
end

function Fusion.OnJoin(player, profile)
	ensureSlots(player, profile)
	Fusion.Update(player, profile)
end

return Fusion
