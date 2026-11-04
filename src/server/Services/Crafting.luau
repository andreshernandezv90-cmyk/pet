-- Crafting (MiningAndCrafting, parte de recetas): picos, succionador,
-- santuario, herreria, almacen de PETs, huerto, laboratorios, extractores y
-- decoraciones. Los costos se recalculan siempre en el servidor. (GDD 07)

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Recipes = require(Shared.Recipes)
local PetStore = require(Shared.PetStore)
local Items = require(Shared.Items)

local Crafting = {}
local S

local function apply(profile, line, level)
	local id = line.id
	if id == "pick" then
		profile.tools.pick = level
	elseif id == "vacuum" then
		profile.tools.vacuum = level
	elseif id == "sanctuary" then
		profile.buildings.sanctuary = level
	elseif id == "forge" then
		profile.buildings.forge = level
	elseif id == "petstorage" then
		profile.buildings.petStorage = level
	elseif id == "garden" then
		profile.buildings.garden = level
		profile.stations.garden.level = level
		local n = Items.GardenPlots[level]
		for i = 1, n do
			profile.garden.plots[i] = profile.garden.plots[i] or {}
		end
		if level == 1 then
			profile.res.storage.semilla = (profile.res.storage.semilla or 0) + 10
		end
	elseif id == "alchemy" then
		profile.buildings.alchemy = level
	elseif id == "bait" then
		profile.buildings.bait = level
	elseif id == "fusionlab" then
		profile.buildings.fusionLab = level
	elseif line.station then
		local st = profile.stations[line.station]
		if st.level == 0 then
			st.updatedAt = os.time()
		elseif S.Production then
			S.Production.Accrue(profile, line.station, os.time())
		end
		st.level = level
	elseif line.deco then
		profile.decorations[line.deco] = true
	end
end

function Crafting.Init(services)
	S = services
	S.Net.Register("craft", function(player, profile, payload)
		if type(payload.line) ~= "string" then
			return { ok = false, msg = "Receta invalida." }
		end
		local nxt = Recipes.Next(profile, payload.line)
		if not nxt then
			return { ok = false, msg = "Receta invalida." }
		end
		if nxt.maxed then
			return { ok = false, msg = "Ya esta al maximo." }
		end
		if nxt.locked then
			return { ok = false, msg = nxt.reason or "Bloqueado." }
		end
		if not PetStore.SpendCost(profile, nxt.cost) then
			return { ok = false, msg = "Te faltan materiales." }
		end
		apply(profile, nxt.line, nxt.level)
		S.Plots.Refresh(player)
		S.Inventory.RefreshPlayer(player)
		S.Progress.CheckUnlocks(player, profile)
		return { ok = true, msg = "✅ " .. nxt.name .. " listo." }
	end)
end

return Crafting
