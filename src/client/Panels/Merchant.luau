-- Comerciante del campamento: intercambio de materiales por semillas, cebos e
-- ingredientes. Las tasas vienen de WorldConfig.Trades y el servidor valida todo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldConfig = require(Shared.WorldConfig)
local Items = require(Shared.Items)
local PetStore = require(Shared.PetStore)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)
local Common = require(script.Parent.Common)

local Merchant = { title = "🤝 Comerciante · Intercambios" }

local function scaled(cost, n)
	local out = {}
	for k, v in pairs(cost) do
		out[k] = v * n
	end
	return out
end

local function getText(get, n)
	local amount = get.n * (n or 1)
	if get.kind == "resource" then
		return amount .. " " .. Items.ResName(get.id)
	elseif get.kind == "bait" then
		return amount .. " " .. Items.Baits[get.id].icon .. " " .. Items.Baits[get.id].name
	elseif get.kind == "potion" then
		return amount .. " " .. Items.Potions[get.id].icon .. " " .. Items.Potions[get.id].name
	end
	return tostring(amount)
end

function Merchant.render(root)
	local d = State.data
	local sc = K.scroll({ Name = "MerchantScroll", Parent = root })
	K.vlist(8).Parent = sc
	K.text("Sin monedas: entregas materiales y recibes semillas, cebos o ingredientes. Producirlos tu mismo siempre sale mejor; " ..
		"aqui pagas por la comodidad. Debes estar junto al Comerciante.", 13, K.C.muted, { Parent = sc, LayoutOrder = 0 })
	for i, t in ipairs(WorldConfig.Trades.list) do
		local card = K.card({ LayoutOrder = i, Parent = sc })
		K.vlist(4).Parent = card
		local locked = d.zones.unlocked < t.zone
		K.text("<b>" .. t.name .. "</b>  →  recibes " .. getText(t.get) .. (locked and K.color("   🔒 Zona " .. t.zone, K.C.warn) or ""),
			15, K.C.text, { Parent = card })
		K.text("Entregas: " .. Common.CostText(d, t.give), 14, K.C.text, { Parent = card })
		local buttons = {}
		for _, n in ipairs({ 1, 5 }) do
			table.insert(buttons, K.button("Intercambiar x" .. n, K.C.good, function()
				Net.Send("trade", { id = t.id, n = n, nonce = Net.Nonce() })
			end, { Enabled = not locked and PetStore.HasCost(d, scaled(t.give, n)), Size = UDim2.new(0, 170, 0, 34) }))
		end
		K.row(buttons).Parent = card
	end
end

return Merchant
