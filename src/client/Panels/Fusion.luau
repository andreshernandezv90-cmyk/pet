-- Fusion: Resonancia Dimensional de dos PETs de especies distintas. (GDD 10)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Progression = require(Shared.Progression)
local Stats = require(Shared.Stats)
local Config = require(Shared.Config)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)
local Net = require(script.Parent.Parent.Net)
local Common = require(script.Parent.Common)

local Fusion = { title = "✨ Resonancia Dimensional (Fusiones)", live = true }
local pickA, pickB = nil, nil -- entradas elegidas

function Fusion.onOpen()
	pickA, pickB = nil, nil
end

local function refOf(e)
	return e.kind == "unit" and { unit = e.unit } or { key = e.key }
end

local function sameEntry(a, b)
	return a and b and a.kind == b.kind and (a.unit or a.key) == (b.unit or b.key)
end

function Fusion.render(root, UI)
	local d = State.data
	local vip = State.IsVip()
	local slots = Progression.FusionSlots(d, vip)
	local sc = K.scroll({ Name = "FusionScroll", Parent = root })
	K.vlist(8).Parent = sc
	if slots < 1 then
		K.text("Construye el Laboratorio de fusiones en el Taller (requiere Santuario nivel 3 y Zona 4).", 15, K.C.warn,
			{ Parent = sc, LayoutOrder = 0 })
	end
	K.text(string.format("Duracion %d min · recarga %d min%s · %d fusion(es) simultanea(s)%s. Los PETs originales no se pierden.",
		Config.FusionDuration / 60, math.floor(Config.FusionCooldown * (vip and Config.VipCooldownFactor or 1) / 60),
		vip and " (VIP)" or "", math.max(slots, 1), vip and "" or " · VIP: 2 simultaneas y 20% menos recarga"), 13, K.C.muted,
		{ Parent = sc, LayoutOrder = 1 })

	local now = State.Now()
	for i, slot in ipairs(d.fusion.slots) do
		if i <= math.max(slots, #d.fusion.slots) then
			local card = K.card({ LayoutOrder = 10 + i, BackgroundColor3 = K.C.cardHi, Parent = sc })
			K.vlist(4).Parent = card
			if slot.fusion and slot.fusion.endsAt > now then
				local f = slot.fusion
				K.text(string.format("Espacio %d: <b>%s</b> (%s + %s) · quedan %s", i, f.name, Common.PetName(f.a.s, f.a.r, f.a.lv),
					Common.PetName(f.b.s, f.b.r, f.b.lv), K.fmtTime(f.endsAt - now)), 15, K.C.text, { Parent = card })
				K.text("Bonos: " .. Common.BonusText(f.a.s, f.a.r, f.a.lv) .. " · " .. Common.BonusText(f.b.s, f.b.r, f.b.lv), 13, K.C.good,
					{ Parent = card })
				K.button("Terminar ahora", K.C.bad, function()
					Net.Send("endFusion", { slot = i })
				end, { Size = UDim2.new(0, 160, 0, 32), Parent = card })
			elseif (slot.cooldownUntil or 0) > now then
				K.text(string.format("Espacio %d: en recarga · %s", i, K.fmtTime(slot.cooldownUntil - now)), 15, K.C.muted, { Parent = card })
			else
				K.text(string.format("Espacio %d: libre", i), 15, K.C.good, { Parent = card })
			end
		end
	end

	if slots >= 1 then
		local pick = K.card({ LayoutOrder = 30, Parent = sc })
		K.vlist(6).Parent = pick
		K.title("Elige dos PETs libres de especies distintas", 16, { Parent = pick })
		local entries = {}
		for _, e in ipairs(PetStore.Entries(d)) do
			if e.kind == "stack" or e.st == "free" then
				table.insert(entries, e)
			end
		end
		local grid = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			Parent = pick })
		K.grid(240, 34, 6).Parent = grid
		for i, e in ipairs(entries) do
			local isA, isB = sameEntry(e, pickA), sameEntry(e, pickB)
			K.button(Common.PetName(e.s, e.r, e.lv), isA and K.C.accent or (isB and K.C.gold or K.C.card), function()
				if isA then
					pickA = nil
				elseif isB then
					pickB = nil
				elseif not pickA then
					pickA = e
				else
					pickB = e
				end
				UI.Render()
			end, { RichText = true, TextSize = 13, LayoutOrder = i, Parent = grid })
		end
		if pickA and pickB then
			local valid = pickA.s ~= pickB.s
			local name = PetCatalog.FusionName(pickA.s, pickB.s)
			K.text(valid and ("Resultado: <b>" .. name .. "</b> · " .. Common.BonusText(pickA.s, pickA.r, pickA.lv) .. " · " ..
				Common.BonusText(pickB.s, pickB.r, pickB.lv)) or "Deben ser especies distintas.", 14, valid and K.C.good or K.C.bad,
				{ Parent = pick })
			K.button("✨ Fusionar", K.C.accent, function()
				Net.Send("fuse", { a = refOf(pickA), b = refOf(pickB) }, nil, function(r)
					if r.ok then
						pickA, pickB = nil, nil
					end
				end)
			end, { Enabled = valid, Size = UDim2.new(0, 200, 0, 40), Parent = pick })
		end
	end

	local disc = K.card({ LayoutOrder = 40, Parent = sc })
	K.vlist(4).Parent = disc
	local names = {}
	for _, name in pairs(d.fusion.discovered) do
		table.insert(names, tostring(name))
	end
	table.sort(names)
	K.title("Coleccion de fusiones (" .. #names .. ")", 16, { Parent = disc })
	K.text(#names > 0 and table.concat(names, ", ") or "Aun no descubres fusiones.", 14, K.C.muted, { Parent = disc })
end

return Fusion
