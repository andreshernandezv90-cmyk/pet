-- DevTools: atajos para probar todos los sistemas. SOLO funcionan en Roblox Studio.

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Items = require(Shared.Items)
local PetCatalog = require(Shared.PetCatalog)
local ProfileSchema = require(Shared.ProfileSchema)

local DevTools = {}
local S

function DevTools.Init(services)
	S = services
	S.Net.Register("dev", function(player, profile, payload)
		if not (RunService:IsStudio() and Config.DevToolsInStudio) then
			return { ok = false, msg = "Herramientas de desarrollo desactivadas." }
		end
		local cmd = payload.cmd
		if cmd == "resources" then
			for _, id in ipairs(Items.ResourceOrder) do
				profile.res.storage[id] = (profile.res.storage[id] or 0) + 500
			end
			return { ok = true, msg = "+500 de cada recurso en el almacen." }
		elseif cmd == "unlock" then
			profile.tools.pick = 5
			profile.tools.vacuum = 5
			profile.tools.axe = 5
			profile.buildings.sanctuary = 5
			profile.buildings.forge = 2
			profile.buildings.garden = 5
			profile.stations.garden.level = 5
			profile.buildings.alchemy = 1
			profile.buildings.bait = 1
			profile.buildings.fusionLab = 1
			for i = 1, Items.GardenPlots[5] do
				profile.garden.plots[i] = profile.garden.plots[i] or {}
			end
			for _, id in ipairs({ "stone", "copper", "iron", "moon", "zuarita", "nexus" }) do
				if profile.stations[id].level < 1 then
					profile.stations[id].updatedAt = os.time()
				end
				profile.stations[id].level = math.max(profile.stations[id].level, 3)
			end
			profile.zones.unlocked = 5
			for k = 1, 5 do
				profile.zones.parkour["z" .. k] = true
			end
			S.Plots.Refresh(player)
			S.Inventory.RefreshPlayer(player)
			return { ok = true, msg = "Todo desbloqueado (herramientas, edificios y zonas)." }
		elseif cmd == "pets" then
			for _, key in ipairs(PetCatalog.AllVariants()) do
				local s, r = PetCatalog.ParseKey(key)
				profile.stacks.storage[key] = (profile.stacks.storage[key] or 0) + 3
				profile.dex[key] = true
				profile.captured[s] = (profile.captured[s] or 0) + 3
				profile.essence[s] = (profile.essence[s] or 0) + 2000
			end
			profile.buildings.petStorage = math.max(profile.buildings.petStorage, 10)
			S.Progress.CheckUnlocks(player, profile)
			return { ok = true, msg = "+3 de cada variante (63) y +2000 esencias por especie." }
		elseif cmd == "raid" then
			if S.Raid.ForceSoon() then
				return { ok = true, msg = "La incursion se anunciara en un segundo." }
			end
			return { ok = false, msg = "Ya hay una incursion en curso." }
		elseif cmd == "gift" then
			local zone = S.World.ZoneOfArea(player:GetAttribute("Area"))
			if not zone then
				return { ok = false, msg = "Entra a una zona del Mundo PET para probar los regalos." }
			end
			S.Gifts.ForceSpawn(player, zone)
			return { ok = true, msg = "Regalo de prueba creado en tu zona." }
		elseif cmd == "reset" then
			local fresh = ProfileSchema.Default()
			fresh.createdAt = os.time()
			for k in pairs(profile) do
				profile[k] = nil
			end
			for k, v in pairs(fresh) do
				profile[k] = v
			end
			S.Plots.Refresh(player)
			S.Inventory.RefreshPlayer(player)
			return { ok = true, msg = "Perfil reiniciado." }
		end
		return { ok = false, msg = "Comando desconocido." }
	end)
end

return DevTools
