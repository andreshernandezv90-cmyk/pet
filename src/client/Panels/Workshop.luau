-- Taller: fabricacion de herramientas y construcciones. (GDD 07)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Recipes = require(Shared.Recipes)
local PetStore = require(Shared.PetStore)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)
local Common = require(script.Parent.Common)

local Workshop = { title = "🔨 Taller y construccion" }
local category = "tools"

function Workshop.onOpen(arg)
	if arg == "stations" then
		category = "stations"
	end
end

function Workshop.render(root, UI)
	local d = State.data
	local list = {}
	for _, c in ipairs(Recipes.Categories) do
		table.insert(list, { id = c.id, name = c.name, width = 150 })
	end
	K.tabs(list, category, function(id)
		category = id
		UI.Render()
	end).Parent = root
	local sc = K.scroll({ Name = "Recipes" .. category, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 1, -46), Parent = root })
	K.vlist(8).Parent = sc
	local order = 0
	for _, lineId in ipairs(Recipes.LineOrder) do
		local line = Recipes.Lines[lineId]
		if line.category == category then
			order = order + 1
			local nxt = Recipes.Next(d, lineId)
			local card = K.card({ LayoutOrder = order, Parent = sc })
			K.vlist(4).Parent = card
			local cur = line.get(d)
			local curName = line.names[cur] or (cur > 0 and (line.name .. " " .. cur) or "Sin construir")
			if nxt.maxed then
				K.text("<b>" .. line.name .. "</b> · " .. K.color("Maximo: " .. curName, K.C.gold), 16, K.C.text, { Parent = card })
			else
				K.text(string.format("<b>%s</b>  %s → %s", line.name, K.color(curName, K.C.muted), K.color(nxt.name, K.C.good)), 16, K.C.text,
					{ Parent = card })
				if nxt.desc ~= "" then
					K.text(nxt.desc, 13, K.C.muted, { Parent = card })
				end
				K.text(Common.CostText(d, nxt.cost), 14, K.C.text, { Parent = card })
				local can = not nxt.locked and PetStore.HasCost(d, nxt.cost)
				local label = nxt.locked and ("🔒 " .. (nxt.reason or "Bloqueado")) or (cur == 0 and "Construir" or "Fabricar / Mejorar")
				K.button(label, K.C.good, function()
					Net.Send("craft", { line = lineId })
				end, { Enabled = can, Size = UDim2.new(0, 280, 0, 38), Parent = card })
			end
		end
	end
end

return Workshop
