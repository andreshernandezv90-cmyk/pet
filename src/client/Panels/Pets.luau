-- PETs: inventario (pilas e individuos), equipo, mejoras de nivel y PETdex.
-- (GDD 05, 13, 14 y 18)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Progression = require(Shared.Progression)
local Stats = require(Shared.Stats)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)
local Common = require(script.Parent.Common)

local Pets = { title = "🐾 Mis PETs" }
local tab = "inv"
local selected = nil -- "u12" o "k:lumi:rare"

local function entryId(e)
	return e.kind == "unit" and e.unit or ("k:" .. e.key)
end

local function refOf(e)
	if e.kind == "unit" then
		return { unit = e.unit }
	end
	return { key = e.key }
end

function Pets.onOpen(arg)
	if arg then
		tab = arg
	end
end

local function detail(parent, d, e, UI)
	local sp = PetCatalog.Get(e.s)
	local lv = e.lv or 0
	K.vlist(8).Parent = parent
	K.title(Common.PetName(e.s, e.r, lv), 22, { RichText = true, Parent = parent, LayoutOrder = 1 })
	local status = e.kind == "stack" and ("Pila de " .. e.count .. " (🫙 tanque " .. e.tank .. " · 🏠 santuario " .. e.storage .. ")")
		or ({ free = "Disponible", equipped = "Equipado", working = "Trabajando", fused = "Fusionado" })[e.st]
	K.text(string.format("Nivel %d/5 · %s · Zona de origen %d", lv, status, sp.zone), 14, K.C.muted, { Parent = parent, LayoutOrder = 2 })

	local comp = K.card({ LayoutOrder = 3, Parent = parent })
	K.vlist(3).Parent = comp
	K.text("<b>Como compañero:</b> " .. sp.companion, 15, K.C.text, { Parent = comp })
	K.text(Common.BonusText(e.s, e.r, lv), 14, K.C.good, { Parent = comp })
	local flags = Common.FlagsText(e.s)
	if flags ~= "" then
		K.text("Poder: " .. flags, 14, K.C.blue, { Parent = comp })
	end
	local work = K.card({ LayoutOrder = 4, Parent = parent })
	K.vlist(3).Parent = work
	K.text("<b>Como trabajador:</b> " .. sp.work, 15, K.C.text, { Parent = work })
	K.text(Common.WorkText(e.s, e.r, lv), 14, K.C.gold, { Parent = work })

	local actions = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 5, Parent = parent })
	local grid = K.new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 40), CellPadding = UDim2.new(0, 6, 0, 6), Parent = actions })
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	local free = e.kind == "stack" or e.st == "free"
	local teamFull = #d.team >= Progression.TeamSlots(d)
	local function act(text, color, fn, enabled)
		K.button(text, color, fn, { Enabled = enabled ~= false, TextSize = 14, Parent = actions })
	end
	if free then
		act(teamFull and "Equipo lleno" or "Equipar", K.C.accent, function()
			Net.Send("equip", { ref = refOf(e) })
		end, not teamFull)
		if e.kind == "unit" then
			act(e.lock and "Quitar proteccion" or "🔒 Proteger", K.C.card, function()
				Net.Send("lock", { ref = refOf(e) })
			end)
		else
			act("🔒 Proteger uno", K.C.card, function()
				Net.Send("lock", { ref = refOf(e) })
			end)
		end
	elseif e.st == "equipped" then
		act("Quitar del equipo", K.C.bad, function()
			Net.Send("unequip", { unit = e.unit })
		end)
		act("Hacer principal", K.C.accent, function()
			Net.Send("setPrincipal", { unit = e.unit })
		end, d.team[1] ~= e.unit)
	elseif e.st == "working" then
		act("Quitar del trabajo", K.C.bad, function()
			Net.Send("unassign", { unit = e.unit })
		end)
	end
	-- Mejora de nivel
	if lv < PetCatalog.MaxLevel and e.st ~= "fused" then
		local cost = PetCatalog.LevelCosts[lv + 1]
		local have = d.essence[e.s] or 0
		local up = K.card({ LayoutOrder = 6, BackgroundColor3 = K.C.cardHi, Parent = parent })
		K.vlist(4).Parent = up
		K.text(string.format("<b>Mejorar a nivel %d</b> · costo de este paso: %d esencias de %s (tienes %s)",
			lv + 1, cost, sp.name, K.color(tostring(have), have >= cost and K.C.good or K.C.bad)), 14, K.C.text, { Parent = up })
		K.text("Ahora: " .. Common.BonusText(e.s, e.r, lv) .. "\nDespues: " .. Common.BonusText(e.s, e.r, lv + 1), 13, K.C.muted, { Parent = up })
		K.button("⬆️ Mejorar", K.C.gold, function()
			Net.Send("levelUp", { ref = refOf(e), nonce = Net.Nonce() }, nil, function(r)
				if r.ok and r.unit then
					selected = r.unit
					UI.Render()
				end
			end)
		end, { Enabled = have >= cost, TextColor3 = Color3.fromRGB(40, 30, 10), Parent = up })
	elseif lv >= PetCatalog.MaxLevel then
		K.text("⭐ Nivel maximo alcanzado.", 15, K.C.gold, { Parent = parent, LayoutOrder = 6 })
	end
	-- Asignar a estacion
	if free then
		local stations = {}
		for stationId in pairs(sp.jobs) do
			local st = d.stations[stationId]
			if st and st.level >= 1 and #st.workers < PetCatalog.StationSlots[st.level] then
				table.insert(stations, stationId)
			end
		end
		if #stations > 0 then
			local box = K.card({ LayoutOrder = 7, Parent = parent })
			K.vlist(4).Parent = box
			K.text("<b>Asignar a una estacion:</b>", 14, K.C.text, { Parent = box })
			for _, sid in ipairs(stations) do
				K.button(PetCatalog.Stations[sid].name, K.C.good, function()
					Net.Send("assign", { station = sid, ref = refOf(e) })
				end, { Size = UDim2.new(1, 0, 0, 36), Parent = box })
			end
		end
	end
end

local function renderInventory(body, d, UI)
	local entries = PetStore.Entries(d)
	local left = K.scroll({ Name = "PetList", Size = UDim2.new(0.46, 0, 1, 0), Parent = body })
	K.vlist(4).Parent = left
	local tankUsed, tankCap = PetStore.Used(d, "tank"), Progression.TankSlots(d)
	local stUsed, stCap = PetStore.Used(d, "storage"), Progression.PetStorageSlots(d)
	K.text(string.format("🫙 Tanque %d/%d · 🏠 Santuario %d/%d espacios (50 PETs iguales = 1 espacio)", tankUsed, tankCap, stUsed, stCap),
		13, K.C.muted, { Parent = left, LayoutOrder = 0 })
	local found = nil
	if #entries == 0 then
		K.text("Aun no tienes PETs. ¡Viaja a la Zona 1 y captura un Lumi!", 15, K.C.warn, { Parent = left, LayoutOrder = 1 })
	end
	for i, e in ipairs(entries) do
		local id = entryId(e)
		if id == selected then
			found = e
		end
		local b = K.new("TextButton", {
			Size = UDim2.new(1, -10, 0, 40),
			BackgroundColor3 = id == selected and K.C.accent or K.C.card,
			Text = "",
			AutoButtonColor = true,
			LayoutOrder = i,
			Parent = left,
		}, { K.corner(8) })
		local dot = Common.Dot(e.s, e.r)
		dot.Position = UDim2.new(0, 8, 0.5, -11)
		dot.Parent = b
		K.text(Common.EntryLabel(e), 14, K.C.text, { Position = UDim2.new(0, 38, 0, 0), Size = UDim2.new(1, -44, 1, 0),
			AutomaticSize = Enum.AutomaticSize.None, Parent = b })
		b.Activated:Connect(function()
			selected = id
			UI.Render()
		end)
	end
	local right = K.scroll({ Name = "PetDetail", Size = UDim2.new(0.52, 0, 1, 0), Position = UDim2.new(0.48, 0, 0, 0), Parent = body })
	if found then
		detail(right, d, found, UI)
	else
		K.vlist(6).Parent = right
		K.text("Selecciona un PET para ver sus habilidades, equiparlo, mejorarlo o asignarlo a un trabajo.", 15, K.C.muted, { Parent = right })
		K.text("Cada PET individual ocupa un solo rol a la vez: compañero, trabajador o fusion.", 14, K.C.muted, { Parent = right })
	end
end

local function renderTeam(body, d)
	local sc = K.scroll({ Name = "Team", Parent = body })
	K.vlist(8).Parent = sc
	local slots = Progression.TeamSlots(d)
	K.text(string.format("Espacios de equipo: %d (Herreria Nv.2 = 2 · Santuario Nv.3 = 3). El principal aplica 100%%; los apoyos 50%%.",
		slots), 14, K.C.muted, { Parent = sc, LayoutOrder = 0 })
	for i = 1, slots do
		local id = d.team[i]
		local u = id and d.units[id]
		local card = K.card({ LayoutOrder = i, Parent = sc })
		K.vlist(4).Parent = card
		if u then
			K.text((i == 1 and "⭐ Principal: " or "Apoyo: ") .. Common.PetName(u.s, u.r, u.lv), 16, K.C.text, { Parent = card })
			K.text(Common.BonusText(u.s, u.r, u.lv) .. (i == 1 and "" or "  (x50%)"), 14, K.C.good, { Parent = card })
			K.row({
				K.button("Quitar", K.C.bad, function() Net.Send("unequip", { unit = u.id }) end),
				K.button("Principal", K.C.accent, function() Net.Send("setPrincipal", { unit = u.id }) end, { Enabled = i ~= 1 }),
			}).Parent = card
		else
			K.text("Espacio libre — equipa un PET desde Inventario.", 15, K.C.muted, { Parent = card })
		end
	end
	local agg = Stats.Aggregate(d, State.Now())
	local lines = {}
	for stat, v in pairs(agg.stats) do
		if v > 0 then
			table.insert(lines, PetCatalog.StatInfo[stat].name .. " " .. Common.Pct(v) .. "  (tope " .. Common.Pct(PetCatalog.StatInfo[stat].cap) .. ")")
		end
	end
	table.sort(lines)
	local flags = {}
	for f in pairs(agg.flags) do
		table.insert(flags, PetCatalog.FlagInfo[f] or (f == "instinct" and "Instinto salvaje" or f))
	end
	local total = K.card({ LayoutOrder = 10, BackgroundColor3 = K.C.cardHi, Parent = sc })
	K.vlist(4).Parent = total
	K.title("Bonificaciones totales (equipo + fusiones + pociones)", 16, { Parent = total })
	K.text(#lines > 0 and table.concat(lines, "\n") or "Sin bonificaciones activas.", 14, K.C.good, { Parent = total })
	if #flags > 0 then
		K.text("Poderes: " .. table.concat(flags, " · "), 14, K.C.blue, { Parent = total })
	end
	K.text(string.format("Bonificacion de coleccion: +%d%% produccion", math.floor((agg.production - 1) * 100 + 0.5)), 14, K.C.gold,
		{ Parent = total })
end

local function renderDex(body, d)
	local sc = K.scroll({ Name = "Dex", Parent = body })
	K.vlist(8).Parent = sc
	local all = PetCatalog.AllVariants()
	local n = 0
	for _, key in ipairs(all) do
		if d.dex[key] then
			n = n + 1
		end
	end
	local _, complete = Progression.CollectionBonus(d)
	K.text(string.format("PETdex: %d/%d variantes · %d especies con sus 4 rarezas (+1%% produccion cada una)", n, #all, complete), 15,
		K.C.gold, { Parent = sc, LayoutOrder = 0 })
	for _, sp in ipairs(PetCatalog.Species) do
		local row = K.card({ LayoutOrder = sp.num, Parent = sc })
		K.vlist(4).Parent = row
		local seen = (d.captured[sp.id] or 0) > 0
		K.text(string.format("#%02d %s · Zona %d %s", sp.num, seen and sp.name or "???", sp.zone,
			seen and K.color("(" .. d.captured[sp.id] .. " rescatados)", K.C.muted) or ""), 15, K.C.text, { Parent = row })
		local cells = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = row })
		K.hlist(6).Parent = cells
		for i, r in ipairs(PetCatalog.RaritiesFor(sp.id)) do
			local got = d.dex[PetCatalog.Key(sp.id, r.id)]
			K.new("TextLabel", {
				Size = UDim2.new(0, 110, 0, 28),
				BackgroundColor3 = got and r.color:Lerp(Color3.new(0, 0, 0), 0.45) or Color3.fromRGB(50, 46, 70),
				Text = got and r.name or "?",
				TextColor3 = got and K.C.text or K.C.muted,
				Font = K.Bold,
				TextSize = 13,
				LayoutOrder = i,
				Parent = cells,
			}, { K.corner(6) })
		end
	end
end

function Pets.render(root, UI)
	local d = State.data
	local tabs = K.tabs({
		{ id = "inv", name = "Inventario" },
		{ id = "team", name = "Equipo" },
		{ id = "dex", name = "PETdex" },
	}, tab, function(id)
		tab = id
		UI.Render()
	end)
	tabs.Parent = root
	local body = K.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 1, -46), Parent = root })
	if tab == "inv" then
		renderInventory(body, d, UI)
	elseif tab == "team" then
		renderTeam(body, d)
	else
		renderDex(body, d)
	end
end

return Pets
