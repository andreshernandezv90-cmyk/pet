-- World/Mines: Minas de Zuar (mundo separado; se integrara al Mundo PET en la Fase D).
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Items)
local Progression = require(Shared.Progression)

local H = require(script.Parent.Helpers)
local part, folder, slab, billboard, signPost, addPrompt, portal, makeNode =
	H.Part, H.Folder, H.Slab, H.Billboard, H.SignPost, H.AddPrompt, H.Portal, H.MakeNode

local World, root
local Mines = {}

-- MINAS DE ZUAR ------------------------------------------------------------------------------

local function buildMines()
	local f = folder("MinasDeZuar", root)
	local M = World.MINES
	slab(f, M, 520, 520, 0, Color3.fromRGB(95, 85, 80), Enum.Material.Slate, "Suelo")
	-- paredes de roca
	for _, d in ipairs({ { 0, -262, 540, 6 }, { 0, 262, 540, 6 }, { -262, 0, 6, 540 }, { 262, 0, 6, 540 } }) do
		part({ Name = "Pared", Size = Vector3.new(d[3], 40, d[4]), Position = M + Vector3.new(d[1], 20, d[2]),
			Color = Color3.fromRGB(80, 70, 65), Material = Enum.Material.Rock }, f)
	end
	World.Spawns.mines = CFrame.new(M + Vector3.new(0, 4, -225)) * CFrame.Angles(0, math.rad(180), 0)
	portal(f, M + Vector3.new(0, 0, -245), 0, "Volver al Hogar", Color3.fromRGB(120, 200, 255), "home")
	signPost(f, M + Vector3.new(14, 0, -222), "Minas de Zuar\nMejora tu pico para llegar mas profundo", Color3.fromRGB(255, 210, 150))

	local rng = Random.new(7)
	local areas = {
		{ type = "stone", z0 = -200, z1 = -120, count = 14, label = "Piedra · Pico de madera" },
		{ type = "copper", z0 = -105, z1 = -30, count = 12, label = "Cobre · Pico de piedra" },
		{ type = "iron", z0 = -15, z1 = 60, count = 10, label = "Hierro · Pico de cobre" },
		{ type = "lunar", z0 = 75, z1 = 150, count = 8, label = "Cristal lunar · Pico de hierro" },
		{ type = "zuarita", z0 = 165, z1 = 235, count = 6, label = "Zuarita · Pico de cristal" },
	}
	for _, a in ipairs(areas) do
		local def = Items.Nodes[a.type]
		signPost(f, M + Vector3.new(-30, 0, a.z0 + 4), a.label, def.color:Lerp(Color3.new(1, 1, 1), 0.4))
		-- franja de color en el suelo
		part({ Name = "Franja", Size = Vector3.new(500, 0.2, a.z1 - a.z0), Position = M + Vector3.new(0, 0.1, (a.z0 + a.z1) / 2),
			Color = def.color:Lerp(Color3.fromRGB(95, 85, 80), 0.75), Material = Enum.Material.Slate }, f)
		for i = 1, a.count do
			local pos = M + Vector3.new(rng:NextNumber(-200, 200), 0, rng:NextNumber(a.z0 + 8, a.z1 - 4))
			makeNode(f, a.type, pos, "mines", rng)
		end
	end
	-- techo de caverna sobre los cristales
	part({ Name = "Techo", Size = Vector3.new(520, 4, 170), Position = M + Vector3.new(0, 30, 160),
		Color = Color3.fromRGB(60, 55, 60), Material = Enum.Material.Rock }, f)
end

function Mines.Build(world, rootFolder)
	World = world
	root = rootFolder
	buildMines()
end

return Mines
