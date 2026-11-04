-- Inventory (PetInventoryService): equipo, proteccion, deposito al hogar,
-- cebos y pociones. Cada PET individual ocupa un solo estado a la vez.
-- (GDD 05, 06, 09 y 14)

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Progression = require(Shared.Progression)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)

local Inventory = {}
local S

-- Atributos replicados que los clientes usan para dibujar compañeros y poderes
function Inventory.RefreshPlayer(player)
	local profile = S.Data.Get(player)
	if not profile then
		return
	end
	local now = os.time()
	local agg = Stats.Aggregate(profile, now)
	local parts = {}
	for _, id in ipairs(profile.team) do
		local u = profile.units[id]
		if u then
			table.insert(parts, u.s .. ":" .. u.r .. ":" .. u.lv)
		end
	end
	for _, f in ipairs(Stats.ActiveFusions(profile, now)) do
		table.insert(parts, "F:" .. f.a.s .. ":" .. f.a.r .. ":" .. f.b.s .. ":" .. f.b.r)
	end
	if profile.cosmetics.visualpet and not profile.cosmetics.hide_visualpet then
		table.insert(parts, "V:lumi:legendary")
	end
	player:SetAttribute("Followers", table.concat(parts, ","))
	local flags = {}
	for f in pairs(agg.flags) do
		table.insert(flags, f)
	end
	table.sort(flags)
	player:SetAttribute("Flags", table.concat(flags, ","))
	player:SetAttribute("Jump", agg.stats.jump)
	local c = profile.cosmetics
	player:SetAttribute("PetHat", c.hat == true and not c.hide_hat)
	player:SetAttribute("Trail", c.trail == true and not c.hide_trail)
	player:SetAttribute("Wings", c.wings == true and not c.hide_wings)
	player:SetAttribute("VIP", S.Commerce.IsVip(player, profile))
end

function Inventory.Aggregate(player)
	local profile = S.Data.Get(player)
	return Stats.Aggregate(profile, os.time())
end

local function result(ok, msg, extra)
	local r = extra or {}
	r.ok = ok
	r.msg = msg
	return r
end

local function isHome(player)
	return player:GetAttribute("Area") == "home"
end

function Inventory.DepositAll(player, profile, silent)
	if not isHome(player) then
		return result(false, "Debes estar en el Hogar para depositar.")
	end
	local r = PetStore.DepositResources(profile)
	local p = PetStore.DepositPets(profile)
	S.Net.MarkDirty(player)
	local msg
	if r == 0 and p == 0 then
		msg = "No hay nada que depositar."
	else
		msg = string.format("Depositado: %d recursos y %d PETs en el santuario.", r, p)
	end
	if PetStore.Used(profile, "tank") > 0 and p == 0 and next(profile.stacks.tank) ~= nil then
		msg = msg .. " (El almacen de PETs esta lleno: amplialo en el Taller)"
	end
	if not silent or r > 0 or p > 0 then
		S.Net.Notify(player, msg, "success")
	end
	return result(true, msg)
end

function Inventory.Init(services)
	S = services
	local Net = S.Net

	Net.Register("depositAll", function(player, profile)
		return Inventory.DepositAll(player, profile)
	end)

	Net.Register("equip", function(player, profile, payload)
		local slots = Progression.TeamSlots(profile)
		if #profile.team >= slots then
			return result(false, "Tu equipo esta completo (" .. slots .. " espacios). Quita un PET primero.")
		end
		local unit = PetStore.Resolve(profile, payload.ref)
		if not unit then
			return result(false, "Ese PET no esta disponible.")
		end
		unit.st = "equipped"
		table.insert(profile.team, unit.id)
		Inventory.RefreshPlayer(player)
		return result(true, PetCatalog.Get(unit.s).name .. " se unio a tu equipo.")
	end)

	Net.Register("unequip", function(player, profile, payload)
		local u = type(payload.unit) == "string" and profile.units[payload.unit]
		if not u or u.st ~= "equipped" then
			return result(false, "Ese PET no esta equipado.")
		end
		PetStore.Release(profile, u)
		Inventory.RefreshPlayer(player)
		return result(true, "PET devuelto al inventario.")
	end)

	Net.Register("setPrincipal", function(player, profile, payload)
		local idx = type(payload.unit) == "string" and table.find(profile.team, payload.unit)
		if not idx then
			return result(false, "Ese PET no esta en tu equipo.")
		end
		table.remove(profile.team, idx)
		table.insert(profile.team, 1, payload.unit)
		Inventory.RefreshPlayer(player)
		return result(true, "Nuevo compañero principal.")
	end)

	Net.Register("lock", function(player, profile, payload)
		local ref = payload.ref
		if type(ref) == "table" and type(ref.unit) == "string" then
			local u = profile.units[ref.unit]
			if not u then
				return result(false, "PET no encontrado.")
			end
			u.lock = not u.lock
			if not u.lock then
				PetStore.TryMerge(profile, u)
			end
			return result(true, u.lock and "PET protegido." or "Proteccion quitada.")
		end
		local u = PetStore.Resolve(profile, ref)
		if not u then
			return result(false, "PET no disponible.")
		end
		u.lock = true
		return result(true, "PET protegido: no se usara en el Reactor.")
	end)

	Net.Register("setBait", function(player, profile, payload)
		local id = payload.bait
		if id == nil or id == false then
			profile.activeBait = nil
			return result(true, "Sin cebo activo.")
		end
		if type(id) ~= "string" or not Items.Baits[id] then
			return result(false, "Cebo invalido.")
		end
		if (profile.items.baits[id] or 0) <= 0 then
			return result(false, "No tienes ese cebo.")
		end
		profile.activeBait = id
		return result(true, Items.Baits[id].name .. " activo. Se gasta 1 por intento de captura.")
	end)

	Net.Register("usePotion", function(player, profile, payload)
		local id = payload.potion
		local def = type(id) == "string" and Items.Potions[id]
		if not def then
			return result(false, "Pocion invalida.")
		end
		if (profile.items.potions[id] or 0) <= 0 then
			return result(false, "No tienes esa pocion.")
		end
		local now = os.time()
		profile.items.potions[id] = profile.items.potions[id] - 1
		if profile.items.potions[id] <= 0 then
			profile.items.potions[id] = nil
		end
		local cur = profile.effects[id]
		local start = (cur and cur > now) and cur or now
		profile.effects[id] = math.min(start + def.duration, now + Items.PotionMaxStack)
		Inventory.RefreshPlayer(player)
		return result(true, def.name .. " activa.")
	end)
end

function Inventory.Start()
	-- Limpia efectos vencidos y refresca atributos cuando expiran fusiones/pociones
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.time()
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				local profile = S.Data.Get(player)
				if profile then
					local changed = false
					for id, t in pairs(profile.effects) do
						if t <= now then
							profile.effects[id] = nil
							changed = true
						end
					end
					if changed then
						Inventory.RefreshPlayer(player)
						S.Net.Notify(player, "Un efecto de pocion termino.", "info")
						S.Net.MarkDirty(player)
					end
				end
			end
		end
	end)
end

return Inventory
