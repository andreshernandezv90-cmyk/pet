-- Mapa: viaje rapido por faros del Mundo PET y regreso al santuario.
-- Un faro solo lleva a zonas desbloqueadas y visitadas; el servidor lo valida.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Progression)
local PetCatalog = require(Shared.PetCatalog)
local WorldConfig = require(Shared.WorldConfig)
local Items = require(Shared.Items)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local Map = { title = "🗺️ Mapa y faros de viaje" }

local function go(dest, UI)
	Net.Send("teleport", { dest = dest }, nil, function(r)
		if r.ok then
			UI.Close()
		end
	end)
end

function Map.render(root, UI)
	local d = State.data
	local sc = K.scroll({ Name = "MapScroll", Parent = root })
	K.vlist(8).Parent = sc

	local top = K.card({ LayoutOrder = 1, Parent = sc })
	K.vlist(6).Parent = top
	K.row({
		K.button("🏠 Volver al santuario", K.C.blue, function() go("home", UI) end, { Size = UDim2.new(0, 220, 0, 44) }),
		K.button("🌀 Campamento del Mundo PET", K.C.accent, function() go("world", UI) end, { Size = UDim2.new(0, 260, 0, 44) }),
		K.button("🌲 Bosque del santuario", K.C.good, function() go("forest", UI) end, { Size = UDim2.new(0, 210, 0, 44) }),
	}, 8).Parent = top
	K.text("Para entrar al Mundo PET por primera vez usa el gran portal de la plaza del santuario.", 13, K.C.muted, { Parent = top })

	for k = 1, 5 do
		local Z = Progression.Zones[k]
		local unlocked = d.zones.unlocked >= k
		local beacon = d.world and d.world.beacons["z" .. k]
		local card = K.card({ BackgroundColor3 = unlocked and K.C.cardHi or K.C.card, LayoutOrder = 10 + k, Parent = sc })
		K.vlist(4).Parent = card
		local status = not unlocked and "🔒 bloqueada" or (beacon and "🗼 faro activo" or "🗼 faro sin activar")
		K.text("<b>Zona " .. k .. " · " .. Z.name .. "</b>   " .. status, 17, K.C.text, { Parent = card, LayoutOrder = 1 })
		local species = {}
		for _, s in ipairs(PetCatalog.SpeciesInZone(k)) do
			table.insert(species, (d.captured[s.id] or 0) > 0 and s.name or K.color(s.name, K.C.muted))
		end
		local minerals = {}
		for _, res in ipairs({ "piedra", "cobre", "hierro", "lunar", "zuarita" }) do
			local c = WorldConfig.Regions[k].mine.chances[res]
			if c and c > 0 then
				table.insert(minerals, Items.Resources[res].icon .. math.floor(c * 100 + 0.5) .. "%")
			end
		end
		K.text("PETs: " .. table.concat(species, ", ") .. "\nMina: " .. table.concat(minerals, " "), 14, K.C.muted, { Parent = card, LayoutOrder = 2 })
		if unlocked and beacon then
			K.button("Viajar al faro", Z.color:Lerp(Color3.new(0, 0, 0), 0.35), function() go("z" .. k, UI) end,
				{ Size = UDim2.new(0, 200, 0, 38), LayoutOrder = 3, Parent = card })
		elseif unlocked then
			K.text("Camina hasta la Zona " .. k .. " para activar su faro.", 14, K.C.warn, { Parent = card, LayoutOrder = 3 })
		else
			local lines = {}
			for _, st in ipairs(Progression.Status(d, k)) do
				table.insert(lines, (st.ok and "✅ " or "❌ ") .. st.text)
			end
			K.text("Requisitos de la barrera:\n" .. table.concat(lines, "\n"), 14, K.C.warn, { Parent = card, LayoutOrder = 3 })
		end
	end

	local other = K.card({ LayoutOrder = 30, Parent = sc })
	K.vlist(6).Parent = other
	K.title("Otros lugares", 16, { Parent = other })
	K.row({
		K.button("⛏️ Minas de Zuar (temporal)", Color3.fromRGB(200, 120, 60), function() go("mines", UI) end, { Size = UDim2.new(0, 250, 0, 38) }),
		K.button("⚔️ Arena de Incursiones", Color3.fromRGB(220, 70, 110), function() go("arena", UI) end, { Size = UDim2.new(0, 230, 0, 38) }),
	}, 8).Parent = other
	K.text("Las minas separadas se mantienen hasta la Fase D, cuando cada zona tendra su propia Mina de Zuar. La arena abre durante las incursiones.",
		13, K.C.muted, { Parent = other })
end

return Map
