-- Estaciones: extractores, trabajadores, produccion/s, deposito, offline y huerto.
-- (GDD 08 y 09)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)
local Config = require(Shared.Config)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)
local Common = require(script.Parent.Common)

local Stations = { title = "🏭 Estaciones de trabajo", live = true }
local picking = nil -- estacion para la que se elige trabajador
local plantingPlot = nil

function Stations.onOpen()
	picking = nil
	plantingPlot = nil
end

local function rates(d, sid, agg)
	local st = d.stations[sid]
	local out = {}
	for _, id in ipairs(st.workers) do
		local u = d.units[id]
		if u then
			local product = PetCatalog.ProductFor(u.s, sid)
			local r = Stats.WorkRate(u.s, u.r, u.lv, sid) * agg.production
			if product and r > 0 then
				out[product] = (out[product] or 0) + r
			end
		end
	end
	return out
end

local function workerList(card, d, sid)
	local st = d.stations[sid]
	for _, id in ipairs(st.workers) do
		local u = d.units[id]
		if u then
			local row = K.frame({ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), AutomaticSize = Enum.AutomaticSize.None, Parent = card })
			K.text("• " .. Common.PetName(u.s, u.r, u.lv), 14, K.C.text, { Size = UDim2.new(1, -100, 1, 0), AutomaticSize = Enum.AutomaticSize.None,
				Parent = row })
			K.button("Quitar", K.C.bad, function()
				Net.Send("unassign", { unit = id })
			end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 90, 0, 30), TextSize = 13,
				Parent = row })
		end
	end
end

local function pickerFor(parent, d, sid, UI)
	local box = K.card({ BackgroundColor3 = K.C.cardHi, Parent = parent })
	K.vlist(4).Parent = box
	K.text("<b>Elige un PET compatible para " .. PetCatalog.Stations[sid].name .. ":</b>", 14, K.C.text, { Parent = box })
	local any = false
	for _, e in ipairs(PetStore.Entries(d)) do
		local sp = PetCatalog.Get(e.s)
		local free = e.kind == "stack" or e.st == "free"
		if free and sp.jobs[sid] then
			any = true
			local rate = Stats.WorkRate(e.s, e.r, e.lv, sid)
			K.button(Common.PetName(e.s, e.r, e.lv) .. string.format("   (%.2f/s)", rate) .. (e.kind == "stack" and ("  x" .. e.count) or ""),
				K.C.card, function()
					local ref = e.kind == "unit" and { unit = e.unit } or { key = e.key }
					Net.Send("assign", { station = sid, ref = ref })
					picking = nil
				end, { Size = UDim2.new(1, 0, 0, 34), RichText = true, TextSize = 14, Parent = box })
		end
	end
	if not any then
		K.text("No tienes PETs libres compatibles con esta estacion.", 14, K.C.warn, { Parent = box })
	end
	K.button("Cancelar", K.C.bad, function()
		picking = nil
		UI.Render()
	end, { Parent = box })
end

local function gardenCard(card, d, UI)
	local level = d.buildings.garden
	local now = State.Now()
	local agg = Stats.Aggregate(d, now)
	local musg, flor, brumi = Stats.GardenPower(d, "musguito"), Stats.GardenPower(d, "florin"), Stats.GardenPower(d, "brumi")
	K.text(string.format("Crecimiento x%.2f · Musguito riega (+%d%%) · Florin cosecha: %s · Brumi resiembra: %s",
		agg.growthMult * (1 + musg), math.floor(musg * 100), flor > 0 and "si" or "no", brumi > 0 and "si" or "no"), 13, K.C.muted,
		{ Parent = card })
	K.text("🌱 Semillas: " .. PetStore.ResTotal(d, "semilla"), 14, K.C.text, { Parent = card })
	local grid = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card })
	K.grid(140, 86, 6).Parent = grid
	for i = 1, Items.GardenPlots[level] do
		local plot = d.garden.plots[i] or {}
		local cell = K.new("Frame", { BackgroundColor3 = Color3.fromRGB(90, 65, 45), LayoutOrder = i, Parent = grid }, { K.corner(8), K.pad(6),
			K.vlist(3) })
		if plot.crop then
			local def = Items.Crops[plot.crop]
			local p = plot.progress or 0
			K.text(Items.Resources[plot.crop].icon .. " " .. def.name .. " " .. math.floor(p * 100) .. "%", 13, K.C.text, { Parent = cell })
			K.bar(p, p >= 1 and K.C.gold or K.C.good, 8).Parent = cell
			K.button(p >= 1 and "Cosechar" or "Creciendo", K.C.good, function()
				Net.Send("harvest", { plot = i })
			end, { Enabled = p >= 1, Size = UDim2.new(1, 0, 0, 28), TextSize = 13, Parent = cell })
		else
			K.text("Parcela " .. i .. " libre", 13, K.C.muted, { Parent = cell })
			K.button("Sembrar", K.C.accent, function()
				plantingPlot = i
				UI.Render()
			end, { Size = UDim2.new(1, 0, 0, 28), TextSize = 13, Parent = cell })
		end
	end
	if plantingPlot then
		local box = K.card({ BackgroundColor3 = K.C.cardHi, Parent = card })
		K.vlist(4).Parent = box
		K.text("¿Que sembrar en la parcela " .. plantingPlot .. "? (1 semilla)", 14, K.C.text, { Parent = box })
		local buttons = {}
		for _, c in ipairs(Items.CropOrder) do
			local def = Items.Crops[c]
			table.insert(buttons, K.button(Items.Resources[c].icon .. " " .. def.name .. " (" .. K.fmtTime(def.time) .. ")", K.C.good, function()
				Net.Send("plant", { plot = plantingPlot, crop = c })
				plantingPlot = nil
			end, { Size = UDim2.new(0, 170, 0, 34), TextSize = 13 }))
		end
		table.insert(buttons, K.button("Cancelar", K.C.bad, function()
			plantingPlot = nil
			UI.Render()
		end, { Size = UDim2.new(0, 100, 0, 34) }))
		K.row(buttons).Parent = box
	end
end

function Stations.render(root, UI)
	local d = State.data
	local sc = K.scroll({ Name = "StationsScroll", Parent = root })
	K.vlist(8).Parent = sc
	local agg = Stats.Aggregate(d, State.Now())
	K.text(string.format("Produccion offline: hasta %d h al %d%% sin superar el deposito. Bonificacion de coleccion: +%d%%.",
		Config.OfflineMaxSeconds / 3600, Config.OfflineEfficiency * 100, math.floor((agg.production - 1) * 100 + 0.5)), 13, K.C.muted,
		{ Parent = sc, LayoutOrder = 0 })
	for i, sid in ipairs(PetCatalog.StationOrder) do
		local def = PetCatalog.Stations[sid]
		local st = d.stations[sid]
		local card = K.card({ LayoutOrder = i, Parent = sc })
		K.vlist(5).Parent = card
		if st.level < 1 then
			K.text("<b>" .. def.name .. "</b> · " .. K.color("sin construir (Zona " .. def.zone .. ")", K.C.muted), 15, K.C.text, { Parent = card })
			K.button("Ir al Taller", K.C.card, function()
				UI.Open("workshop", sid == "garden" and nil or "stations")
			end, { Size = UDim2.new(0, 160, 0, 32), TextSize = 13, Parent = card })
		else
			local slots = PetCatalog.StationSlots[st.level]
			K.text(string.format("<b>%s Nv.%d</b> · trabajadores %d/%d", def.name, st.level, #st.workers, slots), 16, K.C.text, { Parent = card })
			if sid == "garden" then
				gardenCard(card, d, UI)
			end
			local r = rates(d, sid, agg)
			local parts = {}
			for product, v in pairs(r) do
				table.insert(parts, string.format("%s %.2f/s", Items.ResName(product), v))
			end
			local total = 0
			for _, v in pairs(st.buffer) do
				total = total + v
			end
			local cap = PetCatalog.StationCapacity[st.level]
			if sid ~= "garden" then
				K.text(#parts > 0 and ("Produccion: " .. table.concat(parts, " · ")) or "Sin produccion: asigna PETs compatibles.", 14,
					#parts > 0 and K.C.good or K.C.warn, { Parent = card })
			end
			local stored = {}
			for product, v in pairs(st.buffer) do
				if v >= 1 then
					table.insert(stored, Items.ResName(product) .. " " .. math.floor(v))
				end
			end
			K.text(string.format("Deposito: %d/%d  %s", math.floor(total), cap, table.concat(stored, " · ")), 13, K.C.muted, { Parent = card })
			K.bar(total / cap, total >= cap and K.C.bad or K.C.blue, 10).Parent = card
			workerList(card, d, sid)
			local buttons = {
				K.button("Recoger", K.C.good, function()
					Net.Send("collect", { station = sid })
				end, { Enabled = total >= 1, Size = UDim2.new(0, 130, 0, 34) }),
				K.button("Asignar PET", K.C.accent, function()
					picking = sid
					UI.Render()
				end, { Enabled = #st.workers < slots, Size = UDim2.new(0, 150, 0, 34) }),
			}
			local compat = {}
			for _, sp in ipairs(PetCatalog.Species) do
				if sp.jobs[sid] then
					table.insert(compat, sp.name)
				end
			end
			K.row(buttons).Parent = card
			K.text("Compatibles: " .. table.concat(compat, ", "), 12, K.C.muted, { Parent = card })
			if picking == sid then
				pickerFor(card, d, sid, UI)
			end
		end
	end
end

return Stations
