-- Followers: dibuja los compañeros equipados y fusiones de TODOS los jugadores
-- (visibles pero no capturables), mas cosmeticos: estela, alas y etiqueta VIP.
-- Se basa en atributos replicados del jugador, sin trafico extra.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetModels = require(Shared.PetModels)
local PetAnimator = require(Shared.PetAnimator)
local PetCatalog = require(Shared.PetCatalog)

local Followers = {}
local folder
local byPlayer = {} -- [player] = { key = string, list = { {model, extra, pos} } }

local function clear(player)
	local data = byPlayer[player]
	if data then
		for _, f in ipairs(data.list) do
			if f.anim then
				f.anim:Destroy()
			end
			f.model:Destroy()
			if f.extra then
				f.extra:Destroy()
			end
		end
	end
	byPlayer[player] = nil
end

local function rebuild(player)
	local key = (player:GetAttribute("Followers") or "") .. "|" .. tostring(player:GetAttribute("PetHat"))
	local data = byPlayer[player]
	if data and data.key == key then
		return
	end
	clear(player)
	data = { key = key, list = {} }
	byPlayer[player] = data
	local hat = player:GetAttribute("PetHat") == true
	local spec = player:GetAttribute("Followers") or ""
	for item in string.gmatch(spec, "[^,]+") do
		local parts = string.split(item, ":")
		local entry
		if parts[1] == "F" then
			local m = PetModels.Build(parts[2], parts[3], { scale = 1.25, hat = hat })
			local extra = PetModels.Build(parts[4], parts[5], { scale = 0.6 })
			m.Parent = folder
			extra.Parent = folder
			entry = { model = m, extra = extra, fusion = true }
		elseif parts[1] == "V" then
			local m = PetModels.Build(parts[2], parts[3], { scale = 0.8, hat = hat })
			m.Parent = folder
			entry = { model = m }
		elseif PetCatalog.Get(parts[1]) then
			local m = PetModels.Build(parts[1], parts[2], { scale = 0.85, hat = hat })
			m.Parent = folder
			entry = { model = m }
		end
		if entry then
			entry.anim = PetAnimator.Attach(entry.model) -- nil con el modelo procedural
			entry.phase = math.random() * 6
			table.insert(data.list, entry)
		end
	end
end

-- Solo para pruebas en Studio (panel Dev): reproduce Happy / Sleep / Wake en los
-- compañeros del jugador local. No es una mecanica del juego.
function Followers.PreviewAnimation(action)
	local data = byPlayer[Players.LocalPlayer]
	local n = 0
	for _, f in ipairs(data and data.list or {}) do
		if f.anim then
			local ok
			if action == "happy" then
				ok = f.anim:Celebrate() ~= nil
			elseif action == "sleep" then
				ok = f.anim:Sleep()
			elseif action == "wake" then
				f.anim:Wake()
				ok = true
			end
			if ok then
				n = n + 1
			end
		end
	end
	return n
end

local function cosmetics(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	-- Estela
	local wantTrail = player:GetAttribute("Trail") == true
	local trail = hrp:FindFirstChild("PP_Trail")
	if wantTrail and not trail then
		local a0 = Instance.new("Attachment")
		a0.Name = "PP_TrailA0"
		a0.Position = Vector3.new(0, 1, 0)
		a0.Parent = hrp
		local a1 = Instance.new("Attachment")
		a1.Name = "PP_TrailA1"
		a1.Position = Vector3.new(0, -1.5, 0)
		a1.Parent = hrp
		trail = Instance.new("Trail")
		trail.Name = "PP_Trail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.6
		trail.LightEmission = 1
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 120, 230), Color3.fromRGB(120, 200, 255))
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Parent = hrp
	elseif not wantTrail and trail then
		trail:Destroy()
	end
	-- Alas
	local wantWings = player:GetAttribute("Wings") == true
	local wings = char:FindFirstChild("PP_Wings")
	if wantWings and not wings then
		wings = Instance.new("Model")
		wings.Name = "PP_Wings"
		for _, sx in ipairs({ -1, 1 }) do
			local w = Instance.new("Part")
			w.Size = Vector3.new(0.2, 2.6, 3.4)
			w.Material = Enum.Material.Neon
			w.Color = Color3.fromRGB(200, 230, 255)
			w.Transparency = 0.35
			w.CanCollide = false
			w.CanQuery = false
			w.CanTouch = false
			w.Massless = true
			w.CFrame = hrp.CFrame * CFrame.new(sx * 1.2, 0.8, 0.9) * CFrame.Angles(0, sx * 0.5, sx * 0.3)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hrp
			weld.Part1 = w
			weld.Parent = w
			w.Parent = wings
		end
		wings.Parent = char
	elseif not wantWings and wings then
		wings:Destroy()
	end
	-- Etiqueta VIP y luz de Lumi
	local head = char:FindFirstChild("Head")
	if head then
		local wantVip = player:GetAttribute("VIP") == true
		local tag = head:FindFirstChild("PP_VIP")
		if wantVip and not tag then
			tag = Instance.new("BillboardGui")
			tag.Name = "PP_VIP"
			tag.Size = UDim2.new(0, 80, 0, 24)
			tag.StudsOffset = Vector3.new(0, 2.6, 0)
			tag.MaxDistance = 80
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1, 0, 1, 0)
			t.Text = "👑 VIP"
			t.Font = Enum.Font.FredokaOne
			t.TextScaled = true
			t.TextColor3 = Color3.fromRGB(255, 215, 90)
			t.TextStrokeTransparency = 0.3
			t.Parent = tag
			tag.Parent = head
		elseif not wantVip and tag then
			tag:Destroy()
		end
	end
	local flags = player:GetAttribute("Flags") or ""
	local wantLight = string.find(flags, "light") ~= nil
	local light = hrp:FindFirstChild("PP_Light")
	if wantLight and not light then
		light = Instance.new("PointLight")
		light.Name = "PP_Light"
		light.Range = 22
		light.Brightness = 1.6
		light.Color = Color3.fromRGB(255, 240, 180)
		light.Parent = hrp
	elseif not wantLight and light then
		light:Destroy()
	end
end

local function watch(player)
	for _, attr in ipairs({ "Followers", "PetHat" }) do
		player:GetAttributeChangedSignal(attr):Connect(function()
			rebuild(player)
		end)
	end
	for _, attr in ipairs({ "Trail", "Wings", "VIP", "Flags" }) do
		player:GetAttributeChangedSignal(attr):Connect(function()
			cosmetics(player)
		end)
	end
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 10)
		char:WaitForChild("Head", 10)
		cosmetics(player)
	end)
	rebuild(player)
	cosmetics(player)
end

function Followers.Init()
	folder = Instance.new("Folder")
	folder.Name = "Compañeros"
	folder.Parent = workspace
	for _, p in ipairs(Players:GetPlayers()) do
		watch(p)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(clear)

	RunService.RenderStepped:Connect(function(dt)
		local alpha = math.clamp(dt * 8, 0, 1)
		for player, data in pairs(byPlayer) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local base = hrp.CFrame
				local hum = char:FindFirstChildOfClass("Humanoid")
				local airborne = hum ~= nil and hum.FloorMaterial == Enum.Material.Air
				for i, f in ipairs(data.list) do
					f.phase = f.phase + dt * 4
					local side = (i % 2 == 0) and 1 or -1
					local back = 3.5 + math.floor((i - 1) / 2) * 3
					local target = (base * CFrame.new(side * 3, 0, back)).Position
					local bob = f.anim and 0 or math.abs(math.sin(f.phase)) * 0.6
					local groundY = hrp.Position.Y - 1.5 + bob
					target = Vector3.new(target.X, groundY, target.Z)
					local prev = f.pos
					f.pos = f.pos and f.pos:Lerp(target, alpha) or target
					if f.anim then
						if airborne and f.anim:Has("Jump") then
							f.anim:Play("Jump")
						else
							local moved = prev and Vector3.new(f.pos.X - prev.X, 0, f.pos.Z - prev.Z).Magnitude or 0
							f.anim:SetMoveSpeed(dt > 0 and moved / dt or 0)
						end
					end
					local look = base.LookVector
					local cf = CFrame.lookAt(f.pos, f.pos + Vector3.new(look.X, 0, look.Z))
					f.model:PivotTo(cf)
					if f.extra then
						f.extra:PivotTo(cf * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, math.sin(f.phase) * 0.3, 0))
					end
				end
			end
		end
	end)
end

return Followers
