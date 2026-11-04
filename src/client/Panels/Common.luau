-- Common: formatos compartidos por los paneles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetCatalog = require(Shared.PetCatalog)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)
local PetStore = require(Shared.PetStore)

local K = require(script.Parent.Parent.UIKit)

local Common = {}

function Common.RarityColor(r)
	local rar = PetCatalog.Rarity(r)
	return rar and rar.color or K.C.text
end

function Common.PetName(s, r, lv)
	local sp = PetCatalog.Get(s)
	local rar = PetCatalog.Rarity(r)
	local name = (sp and sp.name or s) .. " " .. K.color(rar and rar.name or r, Common.RarityColor(r))
	if lv and lv > 0 then
		name = name .. " " .. K.color(string.rep("★", lv), K.C.gold)
	end
	return name
end

local STATUS = { equipped = "Equipado", working = "Trabajando", fused = "Fusionado", free = "" }

function Common.EntryLabel(e)
	local s = Common.PetName(e.s, e.r, e.lv)
	if e.kind == "stack" then
		s = s .. "  x" .. e.count
		local where = {}
		if e.tank > 0 then
			table.insert(where, "🫙" .. e.tank)
		end
		if e.storage > 0 then
			table.insert(where, "🏠" .. e.storage)
		end
		s = s .. "  " .. K.color(table.concat(where, " "), K.C.muted)
	else
		if e.st ~= "free" then
			s = s .. "  " .. K.color("[" .. STATUS[e.st] .. "]", K.C.blue)
		end
		if e.lock then
			s = s .. " 🔒"
		end
	end
	return s
end

function Common.Pct(v)
	return string.format("+%d%%", math.floor(v * 100 + 0.5))
end

-- Lineas de bonificacion de compañero
function Common.BonusText(s, r, lv)
	local b = Stats.PetBonus(s, r, lv)
	local parts = {}
	for stat, v in pairs(b) do
		local info = PetCatalog.StatInfo[stat]
		table.insert(parts, (info and info.name or stat) .. " " .. Common.Pct(v))
	end
	table.sort(parts)
	return table.concat(parts, " · ")
end

function Common.FlagsText(s)
	local sp = PetCatalog.Get(s)
	local parts = {}
	for f in pairs(sp.flags) do
		table.insert(parts, PetCatalog.FlagInfo[f] or f)
	end
	table.sort(parts)
	return table.concat(parts, " · ")
end

function Common.WorkText(s, r, lv)
	local sp = PetCatalog.Get(s)
	local parts = {}
	for stationId in pairs(sp.jobs) do
		local st = PetCatalog.Stations[stationId]
		local rate = Stats.WorkRate(s, r, lv, stationId)
		local product = PetCatalog.ProductFor(s, stationId)
		if product then
			table.insert(parts, string.format("%s: %.2f %s/s", st.name, rate, Items.Resources[product].icon))
		else
			table.insert(parts, string.format("%s: poder %.2f", st.name, rate))
		end
	end
	table.sort(parts)
	return table.concat(parts, "\n")
end

-- Texto de costo con lo que tienes (verde/rojo)
function Common.CostText(profile, cost)
	local parts = {}
	local keys = {}
	for id in pairs(cost) do
		table.insert(keys, id)
	end
	table.sort(keys, function(a, b)
		return (table.find(Items.ResourceOrder, a) or 99) < (table.find(Items.ResourceOrder, b) or 99)
	end)
	for _, id in ipairs(keys) do
		local need = cost[id]
		local have = PetStore.ResTotal(profile, id)
		local res = Items.Resources[id]
		local c = have >= need and K.C.good or K.C.bad
		table.insert(parts, (res and res.icon or id) .. " " .. K.color(K.fmtNum(have) .. "/" .. need, c))
	end
	return table.concat(parts, "   ")
end

-- Bolita de color de la especie (para listas)
function Common.Dot(s, r)
	local sp = PetCatalog.Get(s)
	return K.new("Frame", { Size = UDim2.new(0, 22, 0, 22), BackgroundColor3 = sp and sp.color or Color3.new(1, 1, 1) },
		{ K.corner(11), K.stroke(Common.RarityColor(r), 2.5) })
end

return Common
