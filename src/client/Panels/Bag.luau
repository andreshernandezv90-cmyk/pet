-- Mochila: recursos portatiles, almacen del hogar, pociones y cebos. (GDD 14)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Items)
local PetStore = require(Shared.PetStore)
local Progression = require(Shared.Progression)
local Config = require(Shared.Config)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)

local Bag = { title = "🎒 Mochila y almacen", live = true }

local function resGrid(parent, tbl, order)
	local grid = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order, Parent = parent })
	K.grid(176, 34, 6).Parent = grid
	local any = false
	for i, id in ipairs(Items.ResourceOrder) do
		local n = tbl[id]
		if n and n >= 1 then
			any = true
			K.new("TextLabel", {
				BackgroundColor3 = K.C.card,
				Text = "  " .. Items.Resources[id].icon .. " " .. Items.Resources[id].name .. ": " .. K.fmtNum(n),
				TextColor3 = K.C.text,
				TextSize = 13,
				Font = K.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = i,
				Parent = grid,
			}, { K.corner(6) })
		end
	end
	if not any then
		K.text("Vacio.", 14, K.C.muted, { Parent = grid })
	end
end

function Bag.render(root)
	local d = State.data
	local sc = K.scroll({ Name = "BagScroll", Parent = root })
	K.vlist(8).Parent = sc
	local home = Players.LocalPlayer:GetAttribute("Area") == "home"
	local used, cap = PetStore.BackpackUsed(d), Progression.BackpackSlots(d)

	K.title(string.format("🎒 Mochila: %d/%d espacios (%d recursos iguales por espacio)", used, cap, Config.ResourceStackSize), 17,
		{ Parent = sc, LayoutOrder = 1 })
	resGrid(sc, d.res.backpack, 2)
	K.button(home and "📥 Depositar todo en el santuario" or "📥 Depositar (debes estar en el Hogar)", K.C.good, function()
		Net.Send("depositAll", {})
	end, { Enabled = home, Size = UDim2.new(0, 360, 0, 40), LayoutOrder = 3, Parent = sc })
	K.text("Consejo: los recursos de la mochila y del almacen se usan juntos para fabricar.", 13, K.C.muted, { Parent = sc, LayoutOrder = 4 })

	K.title("🏠 Almacen del santuario", 17, { Parent = sc, LayoutOrder = 5 })
	resGrid(sc, d.res.storage, 6)

	-- Pociones
	K.title("⚗️ Pociones", 17, { Parent = sc, LayoutOrder = 7 })
	local now = State.Now()
	local potions = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 8, Parent = sc })
	K.vlist(4).Parent = potions
	local anyPotion = false
	for i, id in ipairs(Items.PotionOrder) do
		local def = Items.Potions[id]
		local n = d.items.potions[id] or 0
		local active = d.effects[id] and d.effects[id] > now
		if n > 0 or active then
			anyPotion = true
			local row = K.card({ LayoutOrder = i, Parent = potions })
			K.text(string.format("%s <b>%s</b> x%d — %s %s", def.icon, def.name, n, def.desc,
				active and K.color("(activa " .. K.fmtTime(d.effects[id] - now) .. ")", K.C.good) or ""), 14, K.C.text,
				{ Size = UDim2.new(1, -110, 0, 20), Parent = row })
			K.button("Beber", K.C.accent, function()
				Net.Send("usePotion", { potion = id })
			end, { Enabled = n > 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 96, 0, 34),
				Parent = row })
		end
	end
	if not anyPotion then
		K.text("No tienes pociones. Preparalas en el Laboratorio de alquimia (Zona 3).", 14, K.C.muted, { Parent = potions })
	end

	-- Cebos
	K.title("🎣 Cebos", 17, { Parent = sc, LayoutOrder = 9 })
	local baits = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 10, Parent = sc })
	K.vlist(4).Parent = baits
	local anyBait = false
	for i, id in ipairs(Items.BaitOrder) do
		local def = Items.Baits[id]
		local n = d.items.baits[id] or 0
		if n > 0 then
			anyBait = true
			local isActive = d.activeBait == id
			local row = K.card({ LayoutOrder = i, Parent = baits })
			K.text(string.format("%s <b>%s</b> x%d %s", def.icon, def.name, n, isActive and K.color("(activo)", K.C.good) or ""), 14,
				K.C.text, { Size = UDim2.new(1, -130, 0, 20), Parent = row })
			K.button(isActive and "Desactivar" or "Activar", isActive and K.C.bad or K.C.accent, function()
				Net.Send("setBait", { bait = isActive and false or id })
			end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 116, 0, 34), Parent = row })
		end
	end
	if not anyBait then
		K.text("No tienes cebos. Preparalos en la Estacion de cebos (Zona 3).", 14, K.C.muted, { Parent = baits })
	end
end

return Bag
