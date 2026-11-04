-- Alchemy (AlchemyAndBait): recetas de pociones y cebos. Se obtienen
-- jugando y fabricando, nunca con Robux. (GDD 09 y 15)

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Items)
local PetStore = require(Shared.PetStore)

local Alchemy = {}
local S

local function scaled(cost, n)
	local out = {}
	for k, v in pairs(cost) do
		out[k] = v * n
	end
	return out
end

function Alchemy.Init(services)
	S = services
	S.Net.Register("brew", function(player, profile, payload)
		local kind, id = payload.kind, payload.id
		local n = math.floor(tonumber(payload.n) or 1)
		if n < 1 or n > 10 then
			return { ok = false, msg = "Cantidad invalida." }
		end
		local def, bag
		if kind == "potion" then
			if profile.buildings.alchemy < 1 then
				return { ok = false, msg = "Construye el Laboratorio de alquimia (Zona 3)." }
			end
			def = type(id) == "string" and Items.Potions[id]
			bag = profile.items.potions
		elseif kind == "bait" then
			if profile.buildings.bait < 1 then
				return { ok = false, msg = "Construye la Estacion de cebos (Zona 3)." }
			end
			def = type(id) == "string" and Items.Baits[id]
			bag = profile.items.baits
		end
		if not def then
			return { ok = false, msg = "Receta invalida." }
		end
		if not PetStore.SpendCost(profile, scaled(def.cost, n)) then
			return { ok = false, msg = "Te faltan ingredientes." }
		end
		bag[id] = (bag[id] or 0) + n
		-- Chispa trabajando en el extractor de cobre apoya la alquimia: 20% de pocion extra
		if kind == "potion" then
			for _, uid in ipairs(profile.stations.copper.workers) do
				local u = profile.units[uid]
				if u and u.s == "chispa" and Random.new():NextNumber() < 0.2 then
					bag[id] = bag[id] + 1
					S.Net.Notify(player, "⚡ Chispa ayudo en la alquimia: +1 " .. def.name, "success")
					break
				end
			end
		end
		return { ok = true, msg = "Preparaste " .. n .. "x " .. def.name .. "." }
	end)
end

return Alchemy
