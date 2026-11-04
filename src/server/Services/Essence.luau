-- Essence (EssenceAndLeveling): Reactor de Esencias determinista y mejoras
-- de nivel 0..5 con costos por salto 50/200/500/1000/5000 = 6750. (GDD 12 y 13)
--  * Solo PETs ordinarios en pilas (no equipados, trabajando, fusionados,
--    evolucionados ni protegidos) pueden reciclarse.
--  * Descontar PETs y acreditar esencias ocurre en una sola operacion atomica,
--    con nonce de idempotencia contra reintentos.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)

local Essence = {}
local S

-- Calcula la conversion exacta (usado tambien para la vista previa)
function Essence.Preview(profile, items)
	local bySpecies = {}
	local total = 0
	if type(items) ~= "table" then
		return nil, "Seleccion invalida."
	end
	local count = 0
	for key, n in pairs(items) do
		count = count + 1
		if count > 80 then
			return nil, "Seleccion demasiado grande."
		end
		local s, r = PetCatalog.ParseKey(key)
		n = tonumber(n)
		if not s or not n or n < 0 or n % 1 ~= 0 then
			return nil, "Seleccion invalida."
		end
		if n > 0 then
			if PetStore.StackCount(profile, key) < n then
				return nil, "No tienes suficientes " .. PetCatalog.Get(s).name .. " de esa rareza."
			end
			local value = n * PetCatalog.Rarity(r).essence
			bySpecies[s] = (bySpecies[s] or 0) + value
			total = total + n
		end
	end
	if total == 0 then
		return nil, "No seleccionaste PETs."
	end
	return bySpecies, nil, total
end

function Essence.Init(services)
	S = services
	local Data = S.Data

	S.Net.Register("reactor", function(player, profile, payload)
		local fresh, cached = Data.CheckNonce(player, payload.nonce)
		if not fresh then
			return cached
		end
		local bySpecies, err, total = Essence.Preview(profile, payload.items)
		if not bySpecies then
			return { ok = false, msg = err }
		end
		-- operacion atomica (sin yields): descontar y acreditar
		for key, n in pairs(payload.items) do
			n = tonumber(n)
			if n > 0 then
				PetStore.Take(profile, key, n)
			end
		end
		local parts = {}
		for s, v in pairs(bySpecies) do
			profile.essence[s] = (profile.essence[s] or 0) + v
			table.insert(parts, "+" .. v .. " esencias de " .. PetCatalog.Get(s).name)
		end
		local res = { ok = true, msg = "⚛️ Reactor: " .. total .. " PETs convertidos. " .. table.concat(parts, ", ") }
		Data.StoreNonce(player, payload.nonce, res)
		return res
	end)

	S.Net.Register("levelUp", function(player, profile, payload)
		local fresh, cached = Data.CheckNonce(player, payload.nonce)
		if not fresh then
			return cached
		end
		local ref = payload.ref
		local s
		if type(ref) == "table" and type(ref.unit) == "string" then
			local u = profile.units[ref.unit]
			if not u then
				return { ok = false, msg = "PET no encontrado." }
			end
			s = u.s
			if u.lv >= PetCatalog.MaxLevel then
				return { ok = false, msg = "Ya esta en el nivel maximo." }
			end
			if u.st == "fused" then
				return { ok = false, msg = "No se puede mejorar durante una fusion." }
			end
		elseif type(ref) == "table" and type(ref.key) == "string" then
			s = PetCatalog.ParseKey(ref.key)
			if not s or PetStore.StackCount(profile, ref.key) < 1 then
				return { ok = false, msg = "PET no disponible." }
			end
		else
			return { ok = false, msg = "Seleccion invalida." }
		end
		local unit = (type(ref.unit) == "string") and profile.units[ref.unit] or nil
		local level = unit and unit.lv or 0
		local cost = PetCatalog.LevelCosts[level + 1]
		local have = profile.essence[s] or 0
		if have < cost then
			return { ok = false, msg = string.format("Necesitas %d esencias de %s (tienes %d).", cost, PetCatalog.Get(s).name, have) }
		end
		if not unit then
			unit = PetStore.Resolve(profile, ref)
			if not unit then
				return { ok = false, msg = "PET no disponible." }
			end
		end
		profile.essence[s] = have - cost
		unit.lv = unit.lv + 1
		S.Inventory.RefreshPlayer(player)
		local res = { ok = true, msg = string.format("⬆️ %s subio a nivel %d (-%d esencias).", PetCatalog.Get(s).name, unit.lv, cost),
			unit = unit.id }
		Data.StoreNonce(player, payload.nonce, res)
		return res
	end)
end

return Essence
