-- Mapa: viajes rapidos a los tres mundos y a las zonas desbloqueadas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Progression)
local PetCatalog = require(Shared.PetCatalog)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local Map = { title = "🗺️ Mapa de mundos" }

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

	local worlds = K.card({ LayoutOrder = 1, Parent = sc })
	K.vlist(6).Parent = worlds
	K.title("Mundo 1 y 2", 18, { Parent = worlds })
	K.row({
		K.button("🏠 Mi santuario", K.C.blue, function() go("home", UI) end, { Size = UDim2.new(0, 170, 0, 44) }),
		K.button("🌲 Bosque", K.C.good, function() go("forest", UI) end, { Size = UDim2.new(0, 140, 0, 44) }),
		K.button("⛏️ Minas de Zuar", Color3.fromRGB(200, 120, 60), function() go("mines", UI) end, { Size = UDim2.new(0, 170, 0, 44) }),
		K.button("🌀 Reino de los PETs", K.C.accent, function() go("realm", UI) end, { Size = UDim2.new(0, 200, 0, 44) }),
	}, 8).Parent = worlds

	local zones = K.card({ LayoutOrder = 2, Parent = sc })
	K.vlist(6).Parent = zones
	K.title("Mundo 3 · Reino de los PETs", 18, { Parent = zones })
	for k = 1, 5 do
		local Z = Progression.Zones[k]
		local unlocked = d.zones.unlocked >= k
		local species = {}
		for _, s in ipairs(PetCatalog.SpeciesInZone(k)) do
			local got = (d.captured[s.id] or 0) > 0
			table.insert(species, got and s.name or K.color(s.name, K.C.muted))
		end
		local card = K.card({ BackgroundColor3 = unlocked and K.C.cardHi or K.C.card, LayoutOrder = k, Parent = zones })
		K.vlist(4).Parent = card
		K.text("<b>Zona " .. k .. " · " .. Z.name .. "</b>  " .. (unlocked and "🔓" or "🔒"), 17, K.C.text, { Parent = card, LayoutOrder = 1 })
		K.text("Especies: " .. table.concat(species, ", ") .. "\n" .. Z.activity, 14, K.C.muted, { Parent = card, LayoutOrder = 2 })
		if unlocked then
			local buttons = {
				K.button("Viajar (inicio del parkour)", Z.color:Lerp(Color3.new(0, 0, 0), 0.35), function() go("z" .. k, UI) end,
					{ Size = UDim2.new(0, 230, 0, 38) }),
			}
			if d.zones.parkour["z" .. k] then
				table.insert(buttons, K.button("Ir a la pradera", K.C.good, function() go("z" .. k .. "m", UI) end,
					{ Size = UDim2.new(0, 160, 0, 38) }))
			end
			local r = K.row(buttons, 8)
			r.LayoutOrder = 3
			r.Parent = card
		else
			local missing = Progression.Missing(d, k)
			K.text("Requisitos: " .. table.concat(missing, " · "), 14, K.C.warn, { Parent = card, LayoutOrder = 3 })
		end
	end

	local arena = K.card({ LayoutOrder = 3, Parent = sc })
	K.vlist(6).Parent = arena
	K.title("Arena de Incursiones Dimensionales", 18, { Parent = arena })
	K.text("Se abre aproximadamente una vez por hora. Todos cooperan y cada participante recibe su propia recompensa.", 14,
		K.C.muted, { Parent = arena })
	K.button("⚔️ Ir a la Arena", Color3.fromRGB(220, 70, 110), function() go("arena", UI) end,
		{ Size = UDim2.new(0, 180, 0, 40), Parent = arena })
end

return Map
