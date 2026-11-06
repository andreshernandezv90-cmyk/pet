-- Reactor de Esencias: seleccion de duplicados + vista previa exacta + confirmacion.
-- Conversion determinista: comun 2, raro 3, epico 5, legendario 10, mitico 15. (GDD 12)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)
local Common = require(script.Parent.Common)

local Reactor = { title = "⚛️ Reactor de Esencias" }
local selection = {} -- [key] = n
local confirming = false

function Reactor.onOpen()
	selection = {}
	confirming = false
end

function Reactor.render(root, UI)
	local d = State.data
	local left = K.scroll({ Name = "ReactorList", Size = UDim2.new(0.6, 0, 1, 0), Parent = root })
	K.vlist(4).Parent = left
	K.text("Solo se pueden reciclar PETs ordinarios en pilas. Los equipados, trabajadores, fusionados, mejorados o protegidos se excluyen.",
		13, K.C.muted, { Parent = left, LayoutOrder = 0 })
	local order = 0
	local anyStack = false
	local protectedShiny = 0
	for _, e in ipairs(PetStore.Entries(d)) do
		if e.kind == "stack" and e.shiny then
			protectedShiny = protectedShiny + e.count -- los Shiny estan protegidos (GDD 23)
			selection[e.key] = nil
		elseif e.kind == "stack" then
			anyStack = true
			order = order + 1
			local n = math.min(selection[e.key] or 0, e.count)
			selection[e.key] = n > 0 and n or nil
			local row = K.card({ LayoutOrder = order, Parent = left })
			K.text(Common.PetName(e.s, e.r) .. string.format("  (tienes %d · %d esencias c/u)", e.count, PetCatalog.Rarity(e.r).essence), 14,
				K.C.text, { Parent = row, LayoutOrder = 1 })
			local function set(v)
				selection[e.key] = math.clamp(v, 0, e.count)
				if selection[e.key] == 0 then
					selection[e.key] = nil
				end
				confirming = false
				UI.Render()
			end
			local ctrl = K.row({
				K.button("-10", K.C.card, function() set(n - 10) end, { Size = UDim2.new(0, 52, 0, 30), TextSize = 13 }),
				K.button("-1", K.C.card, function() set(n - 1) end, { Size = UDim2.new(0, 44, 0, 30), TextSize = 13 }),
				K.text(tostring(n), 18, n > 0 and K.C.gold or K.C.muted, { Size = UDim2.new(0, 50, 0, 30), AutomaticSize = Enum.AutomaticSize.None,
					TextXAlignment = Enum.TextXAlignment.Center }),
				K.button("+1", K.C.card, function() set(n + 1) end, { Size = UDim2.new(0, 44, 0, 30), TextSize = 13 }),
				K.button("+10", K.C.card, function() set(n + 10) end, { Size = UDim2.new(0, 52, 0, 30), TextSize = 13 }),
				K.button("Todos menos 1", K.C.cardHi, function() set(e.count - 1) end, { Size = UDim2.new(0, 120, 0, 30), TextSize = 12 }),
			}, 4)
			ctrl.LayoutOrder = 2
			ctrl.Parent = row
			K.vlist(4).Parent = row
		end
	end
	if not anyStack then
		K.text("No tienes PETs repetidos en pilas.", 15, K.C.warn, { Parent = left, LayoutOrder = 1 })
	end
	if protectedShiny > 0 then
		K.text("✨ " .. protectedShiny .. " PETs Shiny protegidos: el Reactor no los recicla.", 13, K.C.muted, { Parent = left, LayoutOrder = order + 1 })
	end

	local right = K.scroll({ Name = "ReactorPreview", Size = UDim2.new(0.38, 0, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), Parent = root })
	K.vlist(6).Parent = right
	K.title("Vista previa exacta", 18, { Parent = right, LayoutOrder = 1 })
	local bySpecies = {}
	local total = 0
	for key, n in pairs(selection) do
		local s, r = PetCatalog.ParseKey(key)
		if s then
			bySpecies[s] = (bySpecies[s] or 0) + n * PetCatalog.Rarity(r).essence
			total = total + n
		end
	end
	local lines = {}
	for s, v in pairs(bySpecies) do
		table.insert(lines, string.format("+%d esencias de %s (tienes %d)", v, PetCatalog.Get(s).name, d.essence[s] or 0))
	end
	table.sort(lines)
	K.text(total > 0 and (total .. " PETs seleccionados:\n" .. table.concat(lines, "\n")) or "Selecciona cantidades a la izquierda.", 14,
		total > 0 and K.C.good or K.C.muted, { Parent = right, LayoutOrder = 2 })
	if confirming then
		K.text("¿Seguro? Esta conversion no se puede deshacer.", 14, K.C.warn, { Parent = right, LayoutOrder = 3 })
		K.button("✅ Confirmar conversion", K.C.good, function()
			local items = {}
			for k, v in pairs(selection) do
				items[k] = v
			end
			Net.Send("reactor", { items = items, nonce = Net.Nonce() }, nil, function(r)
				if r.ok then
					selection = {}
				end
				confirming = false
				UI.Render()
			end)
		end, { Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 4, Parent = right })
		K.button("Cancelar", K.C.bad, function()
			confirming = false
			UI.Render()
		end, { Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 5, Parent = right })
	else
		K.button("⚛️ Convertir", K.C.accent, function()
			confirming = true
			UI.Render()
		end, { Enabled = total > 0, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 4, Parent = right })
	end
	-- Saldos de esencias
	K.title("Tus esencias", 16, { Parent = right, LayoutOrder = 6 })
	local bal = {}
	for _, sp in ipairs(PetCatalog.Species) do
		local v = d.essence[sp.id] or 0
		if v > 0 then
			table.insert(bal, sp.name .. ": " .. v)
		end
	end
	K.text(#bal > 0 and table.concat(bal, "\n") or "Aun no tienes esencias.", 13, K.C.muted, { Parent = right, LayoutOrder = 7 })
	K.text("Mejoras: 50 / 200 / 500 / 1000 / 5000 (total 6750 por PET). Las esencias solo sirven para su misma especie.", 12, K.C.muted,
		{ Parent = right, LayoutOrder = 8 })
end

return Reactor
