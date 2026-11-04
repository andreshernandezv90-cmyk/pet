-- Alquimia y cebos: recetas con ingredientes del huerto, minas y zonas. (GDD 09)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Items)
local PetStore = require(Shared.PetStore)
local PetCatalog = require(Shared.PetCatalog)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)
local Common = require(script.Parent.Common)

local Alchemy = { title = "⚗️ Alquimia y cebos" }
local tab = "potion"

function Alchemy.onOpen(arg)
	if arg == "bait" then
		tab = "bait"
	end
end

local function scaled(cost, n)
	local out = {}
	for k, v in pairs(cost) do
		out[k] = v * n
	end
	return out
end

function Alchemy.render(root, UI)
	local d = State.data
	K.tabs({ { id = "potion", name = "Pociones" }, { id = "bait", name = "Cebos" } }, tab, function(id)
		tab = id
		UI.Render()
	end).Parent = root
	local sc = K.scroll({ Name = "Alch" .. tab, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 1, -46), Parent = root })
	K.vlist(8).Parent = sc
	local built = tab == "potion" and d.buildings.alchemy >= 1 or (tab == "bait" and d.buildings.bait >= 1)
	if not built then
		K.text((tab == "potion" and "Construye el Laboratorio de alquimia" or "Construye la Estacion de cebos") ..
			" en el Taller (se desbloquea al llegar a la Zona 3).", 15, K.C.warn, { Parent = sc, LayoutOrder = 0 })
	end
	local order = tab == "potion" and Items.PotionOrder or Items.BaitOrder
	local defs = tab == "potion" and Items.Potions or Items.Baits
	local bag = tab == "potion" and d.items.potions or d.items.baits
	for i, id in ipairs(order) do
		local def = defs[id]
		local card = K.card({ LayoutOrder = i, Parent = sc })
		K.vlist(4).Parent = card
		local desc
		if tab == "potion" then
			desc = def.desc .. " Duracion: " .. K.fmtTime(def.duration)
		else
			local favs = {}
			for _, sp in ipairs(PetCatalog.Species) do
				if sp.bait == id then
					table.insert(favs, sp.name)
				end
			end
			desc = string.format("+%d%% captura (+%d%% en favoritos) y atrae a: %s", def.bonus * 100, def.favBonus * 100, table.concat(favs, ", "))
		end
		K.text(string.format("%s <b>%s</b>  (tienes %d)", def.icon, def.name, bag[id] or 0), 16, K.C.text, { Parent = card })
		K.text(desc, 13, K.C.muted, { Parent = card })
		K.text(Common.CostText(d, def.cost), 14, K.C.text, { Parent = card })
		local b1 = K.button("Preparar x1", K.C.good, function()
			Net.Send("brew", { kind = tab, id = id, n = 1 })
		end, { Enabled = built and PetStore.HasCost(d, def.cost), Size = UDim2.new(0, 140, 0, 34) })
		local b5 = K.button("Preparar x5", K.C.good, function()
			Net.Send("brew", { kind = tab, id = id, n = 5 })
		end, { Enabled = built and PetStore.HasCost(d, scaled(def.cost, 5)), Size = UDim2.new(0, 140, 0, 34) })
		local use
		if tab == "potion" then
			use = K.button("Beber", K.C.accent, function()
				Net.Send("usePotion", { potion = id })
			end, { Enabled = (bag[id] or 0) > 0, Size = UDim2.new(0, 110, 0, 34) })
		else
			local active = d.activeBait == id
			use = K.button(active and "Activo ✓" or "Activar", K.C.accent, function()
				Net.Send("setBait", { bait = active and false or id })
			end, { Enabled = (bag[id] or 0) > 0, Size = UDim2.new(0, 110, 0, 34) })
		end
		K.row({ b1, b5, use }).Parent = card
	end
end

return Alchemy
