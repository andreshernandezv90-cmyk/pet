-- Tienda: cosmeticos, comodidad y VIP. Sin azar por Robux (GDD 15).

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local Shop = { title = "🛍️ Tienda" }

local function buy(product, studio)
	if product.productId and product.productId ~= 0 then
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.productId)
	elseif studio and Config.StudioTestPurchases then
		Net.Send("testPurchase", { key = product.key })
	end
end

function Shop.render(root)
	local d = State.data
	local studio = d.meta and d.meta.studio
	local sc = K.scroll({ Name = "ShopScroll", Parent = root })
	K.vlist(8).Parent = sc
	K.text("Todo el contenido del juego (mundos, PETs, herramientas, huerto y nivel 5) se obtiene gratis jugando. " ..
		"La tienda solo ofrece cosmeticos y comodidad. Nunca vendemos PETs aleatorios ni probabilidades.", 13, K.C.muted,
		{ Parent = sc, LayoutOrder = 0 })
	if studio then
		K.text("🧪 Modo Studio: los productos con ID 0 se otorgan gratis para probar. Configura los IDs reales en Shared/Config.", 13,
			K.C.warn, { Parent = sc, LayoutOrder = 1 })
	end

	-- VIP
	local vip = State.IsVip()
	local vipCard = K.card({ LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(90, 70, 30), Parent = sc })
	K.vlist(4).Parent = vipCard
	K.text("👑 <b>VIP</b> · 249 Robux · Pase permanente" .. (vip and K.color("  (activo)", K.C.good) or ""), 16, K.C.gold, { Parent = vipCard })
	K.text("Etiqueta y decoracion exclusiva, 2 fusiones simultaneas y 20% menos recarga de fusion. Es comodidad, no un requisito.", 13,
		K.C.text, { Parent = vipCard })
	K.button(vip and "Ya eres VIP" or "Obtener VIP", K.C.gold, function()
		if Config.VipGamePassId ~= 0 then
			MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, Config.VipGamePassId)
		elseif studio then
			Net.Send("testPurchase", { key = "vip" })
		end
	end, { Enabled = (not vip) or (studio and Config.VipGamePassId == 0), TextColor3 = Color3.fromRGB(40, 30, 10),
		Size = UDim2.new(0, 200, 0, 36), Parent = vipCard })

	for i, p in ipairs(Config.Products) do
		local card = K.card({ LayoutOrder = 10 + i, Parent = sc })
		K.vlist(4).Parent = card
		local owned = p.kind == "cosmetic" and d.cosmetics[p.cosmetic]
		local extra = ""
		if p.kind == "backpack" then
			extra = string.format(" (comprados: %d/%d)", d.paid.backpack or 0, Config.MaxPaidSlots)
		elseif p.kind == "tank" then
			extra = string.format(" (comprados: %d/%d)", d.paid.tank or 0, Config.MaxPaidSlots)
		end
		K.text(string.format("<b>%s</b> · %d Robux%s%s", p.name, p.price, extra, owned and K.color("  ✓ tuyo", K.C.good) or ""), 15,
			K.C.text, { Parent = card })
		local buttons = {}
		local available = (p.productId ~= 0) or (studio and Config.StudioTestPurchases)
		table.insert(buttons, K.button(available and "Comprar" or "No disponible", K.C.accent, function()
			buy(p, studio)
		end, { Enabled = available and not owned, Size = UDim2.new(0, 150, 0, 32) }))
		if owned then
			local hidden = d.cosmetics["hide_" .. p.cosmetic]
			table.insert(buttons, K.button(hidden and "Mostrar" or "Ocultar", K.C.card, function()
				Net.Send("toggleCosmetic", { id = p.cosmetic })
			end, { Size = UDim2.new(0, 110, 0, 32) }))
		end
		K.row(buttons).Parent = card
	end
end

return Shop
