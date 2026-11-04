-- Exporta la escena construida por el servidor a JSON para tools/preview/render.py
-- Uso: lua5.4 tools/preview/export.lua salida.json [nivel_santuario] [jugadores]
dofile("tools/sim/mock.lua")
local A = arg or {}
local out = A[1] or os.getenv("PP_OUT") or "scene.json"
local level = tonumber(A[2] or os.getenv("PP_LEVEL") or "1")
local nplayers = tonumber(A[3] or os.getenv("PP_PLAYERS") or "1")
RUN_SCRIPT(SERVER_SCRIPT)
local S = {}
for _, m in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[m.Name] = require(m) end
local Players = game:GetService("Players")
for i = 1, nplayers do
	local p = MAKE_PLAYER(1000 + i, "Jugador" .. i)
	Players.PlayerAdded:Fire(p)
	RUN_DELAYS()
	local prof = S.DataService.Get(p)
	prof.buildings.sanctuary = math.max(1, level - (i - 1))
	if level >= 2 then prof.stations.stone.level = 1; prof.stations.copper.level = 2 end
	if level >= 3 then prof.buildings.alchemy = 1; prof.buildings.garden = 2; prof.stations.garden.level = 2
		prof.garden.plots = { { crop = "baya", progress = 1 }, { crop = "flor", progress = 0.4 }, {}, {} } end
	S.Plots.Refresh(p)
end
local function num(x) return string.format("%.3f", x) end
local function col(c) return "[" .. num(c.R) .. "," .. num(c.G) .. "," .. num(c.B) .. "]" end
local f = io.open(out, "w")
f:write('{"parts":[\n')
local first = true
local count = 0
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and (d.Transparency or 0) < 0.97 then
		local cf = d.CFrame
		local mesh = nil
		for _, c in ipairs(d.__children) do
			if c.ClassName == "SpecialMesh" then mesh = tostring(c.MeshType) end
		end
		local shape = d.__props.Shape and tostring(d.__props.Shape) or "Enum.PartType.Block"
		local m = cf.m
		local line = string.format('{"cls":"%s","shape":"%s","mesh":%s,"p":[%s,%s,%s],"r":[%s],"s":[%s,%s,%s],"c":%s,"t":%s,"mat":"%s"}',
			d.ClassName, shape, mesh and ('"' .. mesh .. '"') or "null", num(cf.p.X), num(cf.p.Y), num(cf.p.Z),
			table.concat({ num(m[1]), num(m[2]), num(m[3]), num(m[4]), num(m[5]), num(m[6]), num(m[7]), num(m[8]), num(m[9]) }, ","),
			num(d.Size.X), num(d.Size.Y), num(d.Size.Z), col(d.Color or Color3.new(1, 1, 1)), num(d.Transparency or 0), tostring(d.Material))
		f:write((first and "" or ",\n") .. line)
		first = false
		count = count + 1
	end
end
f:write('\n],"terrain":[\n')
first = true
for _, o in ipairs(TERRAIN_OPS) do
	local line
	if o.op == "block" then
		local m = o.cf.m
		line = string.format('{"op":"block","p":[%s,%s,%s],"r":[%s],"s":[%s,%s,%s],"mat":"%s"}', num(o.cf.p.X), num(o.cf.p.Y), num(o.cf.p.Z),
			table.concat({ num(m[1]), num(m[2]), num(m[3]), num(m[4]), num(m[5]), num(m[6]), num(m[7]), num(m[8]), num(m[9]) }, ","),
			num(o.size.X), num(o.size.Y), num(o.size.Z), tostring(o.mat))
	elseif o.op == "ball" then
		line = string.format('{"op":"ball","p":[%s,%s,%s],"r":%s,"mat":"%s"}', num(o.c.X), num(o.c.Y), num(o.c.Z), num(o.r), tostring(o.mat))
	else
		line = string.format('{"op":"cyl","p":[%s,%s,%s],"h":%s,"r":%s,"mat":"%s"}', num(o.cf.p.X), num(o.cf.p.Y), num(o.cf.p.Z), num(o.h), num(o.r), tostring(o.mat))
	end
	f:write((first and "" or ",\n") .. line)
	first = false
end
f:write('\n],"colors":{')
first = true
for mat, c in pairs(TERRAIN_COLORS) do
	f:write((first and "" or ",") .. '"' .. tostring(mat) .. '":' .. col(c))
	first = false
end
local plots = {}
for i, cf in ipairs(S.World.PlotCenters) do
	local m = cf.m
	table.insert(plots, string.format('{"p":[%s,%s,%s],"r":[%s]}', num(cf.p.X), num(cf.p.Y), num(cf.p.Z),
		table.concat({ num(m[1]), num(m[2]), num(m[3]), num(m[4]), num(m[5]), num(m[6]), num(m[7]), num(m[8]), num(m[9]) }, ",")))
end
f:write('},"plots":[' .. table.concat(plots, ",") .. ']}\n')
f:close()
local function countParts(inst)
	local n = 0
	if not inst then return 0 end
	for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then n = n + 1 end end
	return n
end
local W = workspace:FindFirstChild("World")
print("partes exportadas: " .. count .. ", operaciones de terreno: " .. #TERRAIN_OPS)
print(string.format("Santuario estatico: %d partes | parcelas dinamicas: %d | minas: %d | reino: %d",
	countParts(W:FindFirstChild("Hogar")), countParts(workspace:FindFirstChild("Plots")), countParts(W:FindFirstChild("MinasDeZuar")),
	countParts(W:FindFirstChild("ReinoHub")) + countParts(W:FindFirstChild("Zona1")) + countParts(W:FindFirstChild("Zona2"))
	+ countParts(W:FindFirstChild("Zona3")) + countParts(W:FindFirstChild("Zona4")) + countParts(W:FindFirstChild("Zona5"))))
