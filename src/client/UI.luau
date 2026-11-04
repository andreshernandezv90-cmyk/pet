-- UI: HUD principal, avisos y gestor de paneles.
-- El HUD comunica: donde estas, que puedes hacer ahora y que te falta (GDD 18).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Progression)
local PetStore = require(Shared.PetStore)
local PetCatalog = require(Shared.PetCatalog)
local Items = require(Shared.Items)

local K = require(script.Parent.UIKit)
local State = require(script.Parent.State)
local Net = require(script.Parent.Net)

local player = Players.LocalPlayer

local UI = {}
UI.Panels = {}
UI.current = nil

local gui, hudTop, objectiveLabel, areaLabel, chips, toastHolder, window, windowTitle, content, raidBanner, shotButton
local depositButton, popup
local lastScroll = {}

local AREA_NAMES = {
	home = "🏠 Hogar Dimensional",
	mines = "⛏️ Minas de Zuar",
	realm = "🌀 Reino de los PETs",
	arena = "⚔️ Arena de Incursiones",
}

local function areaName(area)
	if AREA_NAMES[area] then
		return AREA_NAMES[area]
	end
	local k = area and tonumber(string.match(area, "^z(%d)$"))
	if k then
		return "🌸 Zona " .. k .. " · " .. Progression.Zones[k].name
	end
	return "Portal Pets"
end

-- Avisos ---------------------------------------------------------------------------------

local KIND_COLORS = {
	info = K.C.card,
	success = Color3.fromRGB(46, 140, 90),
	error = Color3.fromRGB(170, 60, 75),
	unlock = Color3.fromRGB(150, 100, 255),
	rare = Color3.fromRGB(200, 140, 30),
	raid = Color3.fromRGB(200, 60, 90),
}

function UI.Toast(text, kind)
	if not toastHolder or not text or text == "" then
		return
	end
	local t = K.new("TextLabel", {
		BackgroundColor3 = KIND_COLORS[kind or "info"] or K.C.card,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextSize = 17,
		Font = K.Bold,
		TextColor3 = K.C.text,
		TextWrapped = true,
		Parent = toastHolder,
	}, { K.corner(10), K.pad(8) })
	t.LayoutOrder = -math.floor(os.clock() * 100)
	task.delay(kind == "error" and 4 or 5, function()
		if t.Parent then
			TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			task.wait(0.45)
			t:Destroy()
		end
	end)
	local n = 0
	for _, c in ipairs(toastHolder:GetChildren()) do
		if c:IsA("TextLabel") then
			n = n + 1
		end
	end
	if n > 5 then
		local oldest, lo = nil, -math.huge
		for _, c in ipairs(toastHolder:GetChildren()) do
			if c:IsA("TextLabel") and c.LayoutOrder > lo then
				oldest, lo = c, c.LayoutOrder
			end
		end
		if oldest then
			oldest:Destroy()
		end
	end
end

-- Popup grande en el centro (capturas, recompensas)
function UI.Popup(title, lines, color)
	if popup then
		popup:Destroy()
	end
	popup = K.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		Size = UDim2.new(0, 460, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = K.C.bg,
		Parent = gui,
	}, { K.corner(16), K.stroke(color or K.C.gold, 3), K.pad(16), K.vlist(6, Enum.HorizontalAlignment.Center) })
	K.title(title, 30, { TextColor3 = color or K.C.gold, TextXAlignment = Enum.TextXAlignment.Center, Parent = popup })
	for i, l in ipairs(lines or {}) do
		K.text(l, 17, K.C.text, { TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = i + 1, Parent = popup })
	end
	local p = popup
	local scale = K.new("UIScale", { Scale = 0.6, Parent = p })
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(4, function()
		if p.Parent then
			p:Destroy()
		end
	end)
end

-- Paneles -----------------------------------------------------------------------------------

function UI.Register(id, panel)
	UI.Panels[id] = panel
end

function UI.Render()
	if not UI.current or not window.Visible then
		return
	end
	local panel = UI.Panels[UI.current]
	if not panel or not State.data then
		return
	end
	-- conservar posiciones de desplazamiento
	local scrolls = {}
	for _, d in ipairs(content:GetDescendants()) do
		if d:IsA("ScrollingFrame") then
			scrolls[d.Name] = d.CanvasPosition
		end
	end
	for k, v in pairs(scrolls) do
		lastScroll[UI.current .. ":" .. k] = v
	end
	content:ClearAllChildren()
	windowTitle.Text = panel.title
	local ok, err = pcall(panel.render, content, UI)
	if not ok then
		warn("[PortalPets] Error dibujando panel " .. UI.current .. ": " .. tostring(err))
	end
	for _, d in ipairs(content:GetDescendants()) do
		if d:IsA("ScrollingFrame") then
			local pos = lastScroll[UI.current .. ":" .. d.Name]
			if pos then
				task.defer(function()
					if d.Parent then
						d.CanvasPosition = pos
					end
				end)
			end
		end
	end
end

function UI.Open(id, arg)
	if not UI.Panels[id] then
		return
	end
	if UI.current ~= id then
		lastScroll = {}
	end
	UI.current = id
	local panel = UI.Panels[id]
	if panel.onOpen then
		panel.onOpen(arg)
	end
	window.Visible = true
	UI.Render()
end

function UI.Close()
	window.Visible = false
	UI.current = nil
end

function UI.Toggle(id)
	if window.Visible and UI.current == id then
		UI.Close()
	else
		UI.Open(id)
	end
end

-- HUD ---------------------------------------------------------------------------------------

local function chip(text, color)
	return K.new("TextLabel", {
		BackgroundColor3 = color or K.C.bg,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(0, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = text,
		TextSize = 16,
		Font = K.Bold,
		TextColor3 = K.C.text,
	}, { K.corner(8), K.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
end

function UI.RefreshHud()
	local d = State.data
	if not d then
		return
	end
	local area = player:GetAttribute("Area") or "home"
	areaLabel.Text = areaName(area)
	objectiveLabel.Text = "🎯 " .. Progression.Objective(d)
	for _, c in ipairs(chips:GetChildren()) do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local bp = PetStore.BackpackUsed(d)
	local bpCap = Progression.BackpackSlots(d)
	local tank = PetStore.Used(d, "tank")
	local tankCap = Progression.TankSlots(d)
	local list = {
		{ "🎒 " .. bp .. "/" .. bpCap, bp >= bpCap and K.C.bad or nil },
		{ "🫙 " .. tank .. "/" .. tankCap, tank >= tankCap and K.C.bad or nil },
		{ "⛏️ " .. Items.Picks[d.tools.pick].name },
		{ "🌀 Succ. Nv." .. d.tools.vacuum },
	}
	if d.activeBait and (d.items.baits[d.activeBait] or 0) > 0 then
		local b = Items.Baits[d.activeBait]
		table.insert(list, { b.icon .. " x" .. d.items.baits[d.activeBait] })
	end
	local now = State.Now()
	for id, t in pairs(d.effects) do
		if t > now and Items.Potions[id] then
			table.insert(list, { Items.Potions[id].icon .. " " .. K.fmtTime(t - now), Color3.fromRGB(60, 120, 90) })
		end
	end
	if d.meta and not d.meta.persist then
		table.insert(list, { "⚠️ Sin guardado", K.C.bad })
	end
	for i, c in ipairs(list) do
		local l = chip(c[1], c[2])
		l.LayoutOrder = i
		l.Parent = chips
	end
	depositButton.Visible = area == "home" and (bp > 0 or tank > 0)
end

local BUTTONS = {
	{ id = "map", text = "🗺️\nMapa" },
	{ id = "pets", text = "🐾\nPETs" },
	{ id = "bag", text = "🎒\nMochila" },
	{ id = "workshop", text = "🔨\nTaller" },
	{ id = "stations", text = "🏭\nEstaciones" },
	{ id = "alchemy", text = "⚗️\nAlquimia" },
	{ id = "reactor", text = "⚛️\nReactor" },
	{ id = "fusion", text = "✨\nFusion" },
	{ id = "shop", text = "🛍️\nTienda" },
}

local raidState = nil

function UI.SetRaid(data)
	raidState = data
end

local function updateRaidBanner()
	local r = raidState
	if not r or r.phase == "idle" then
		raidBanner.Visible = false
		shotButton.Visible = false
		return
	end
	raidBanner.Visible = true
	local inArena = player:GetAttribute("Area") == "arena"
	local name = r.species and PetCatalog.Get(r.species) and PetCatalog.Get(r.species).name or "?"
	local title = raidBanner:FindFirstChild("Title")
	local info = raidBanner:FindFirstChild("Info")
	local bar = raidBanner:FindFirstChild("Bar")
	local go = raidBanner:FindFirstChild("Go")
	local myScore = r.scores and r.scores[tostring(player.UserId)] or 0
	local phaseText = {
		announce = "⚠️ Incursion en " .. K.fmtTime(r.timeLeft) .. " · " .. name .. " gigante (" .. (r.zoneName or "") .. ")",
		barrier = "🛡️ Fase 1: rompe la barrera con disparos de resonancia",
		pillars = string.format("🗿 Fase 2: activa los pilares (%d/%d) y esquiva las ondas", r.pillars or 0, r.pillarsTotal or 4),
		final = "💫 Fase 3: entra al circulo rosa para estabilizar al PET",
		reward = "🏆 Recompensas entregadas",
	}
	title.Text = phaseText[r.phase] or r.phase
	info.Text = string.format("Participantes: %d · Tu contribucion: %d", r.participants or 0, myScore)
	local frac = 0
	if r.phase == "barrier" and (r.shieldMax or 0) > 0 then
		frac = r.shield / r.shieldMax
	elseif r.phase == "final" then
		frac = (r.stability or 0) / 100
	elseif r.phase == "pillars" then
		frac = (r.pillars or 0) / math.max(1, r.pillarsTotal or 4)
	end
	bar.Fill.Size = UDim2.new(math.clamp(frac, 0, 1), 0, 1, 0)
	go.Visible = not inArena and r.phase ~= "reward"
	shotButton.Visible = inArena and r.phase == "barrier"
end

function UI.Init()
	gui = K.new("ScreenGui", {
		Name = "PortalPetsUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local uiScale = K.new("UIScale", { Parent = gui })
	local function rescale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		uiScale.Scale = math.clamp(math.min(vp.X / 1150, vp.Y / 680), 0.5, 1.3)
	end
	rescale()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

	-- Esquina superior izquierda: area + objetivo
	hudTop = K.new("Frame", {
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(0, 440, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = K.C.bg,
		BackgroundTransparency = 0.2,
		Parent = gui,
	}, { K.corner(12), K.pad(10), K.vlist(4) })
	areaLabel = K.title("Portal Pets", 20, { Parent = hudTop, LayoutOrder = 1 })
	objectiveLabel = K.text("Cargando tu perfil...", 15, K.C.gold, { Parent = hudTop, LayoutOrder = 2 })

	-- Chips (arriba derecha)
	chips = K.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.new(0, 560, 0, 30),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local cl = K.hlist(6)
	cl.HorizontalAlignment = Enum.HorizontalAlignment.Right
	cl.Wraps = true
	cl.Parent = chips

	-- Barra inferior de botones
	local bar = K.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(0, 0, 0, 66),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = K.C.bg,
		BackgroundTransparency = 0.25,
		Parent = gui,
	}, { K.corner(14), K.pad(6) })
	K.hlist(6).Parent = bar
	local buttons = {}
	for _, b in ipairs(BUTTONS) do
		table.insert(buttons, b)
	end
	local devAdded = false
	local function addButton(i, b)
		local btn = K.button(b.text, K.C.card, function()
			UI.Toggle(b.id)
		end, { Size = UDim2.new(0, 84, 0, 54), TextSize = 13, LayoutOrder = i })
		btn.Parent = bar
	end
	for i, b in ipairs(buttons) do
		addButton(i, b)
	end

	depositButton = K.button("📥 Depositar todo en el santuario", K.C.good, function()
		Net.Send("depositAll", {}, { silent = false })
	end, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -84), Size = UDim2.new(0, 300, 0, 40), Parent = gui })
	depositButton.Visible = false

	-- Avisos
	toastHolder = K.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 96),
		Size = UDim2.new(0, 460, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = gui,
	}, { K.vlist(6, Enum.HorizontalAlignment.Center) })

	-- Banner de incursion
	raidBanner = K.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -134),
		Size = UDim2.new(0, 520, 0, 84),
		BackgroundColor3 = Color3.fromRGB(80, 30, 60),
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = gui,
	}, { K.corner(12), K.stroke(Color3.fromRGB(255, 120, 180), 2) })
	K.title("", 17, { Name = "Title", Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -150, 0, 22), AutomaticSize = Enum.AutomaticSize.None,
		TextScaled = true, Parent = raidBanner })
	K.text("", 14, K.C.muted, { Name = "Info", Position = UDim2.new(0, 10, 0, 32), Size = UDim2.new(1, -150, 0, 18),
		AutomaticSize = Enum.AutomaticSize.None, Parent = raidBanner })
	local rbar = K.new("Frame", { Name = "Bar", Position = UDim2.new(0, 10, 0, 58), Size = UDim2.new(1, -150, 0, 14),
		BackgroundColor3 = Color3.fromRGB(30, 20, 40), Parent = raidBanner }, { K.corner(7) })
	K.new("Frame", { Name = "Fill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 120, 200), Parent = rbar }, { K.corner(7) })
	K.button("Ir a la Arena", Color3.fromRGB(220, 70, 110), function()
		Net.Send("raidGo", {})
	end, { Name = "Go", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 126, 0, 50),
		Parent = raidBanner })

	shotButton = K.button("🎯\nDISPARO", Color3.fromRGB(230, 80, 140), nil, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -100),
		Size = UDim2.new(0, 120, 0, 120),
		TextSize = 22,
		Visible = false,
		Parent = gui,
	})
	shotButton:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)
	local firing = false
	shotButton.MouseButton1Down:Connect(function()
		firing = true
		while firing and shotButton.Visible do
			Net.Send("raidShot", {}, { silent = true })
			UI.ShotFx()
			task.wait(0.32)
		end
	end)
	shotButton.MouseButton1Up:Connect(function()
		firing = false
	end)
	shotButton.MouseLeave:Connect(function()
		firing = false
	end)

	-- Ventana de paneles
	window = K.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.47, 0),
		Size = UDim2.new(0, 820, 0, 500),
		BackgroundColor3 = K.C.panel,
		Visible = false,
		Parent = gui,
	}, { K.corner(16), K.stroke(K.C.accent, 2) })
	windowTitle = K.title("", 24, { Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -80, 0, 30),
		AutomaticSize = Enum.AutomaticSize.None, Parent = window })
	K.button("✕", K.C.bad, function()
		UI.Close()
	end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.new(0, 40, 0, 36), TextSize = 20, Parent = window })
	content = K.new("Frame", {
		Position = UDim2.new(0, 14, 0, 50),
		Size = UDim2.new(1, -28, 1, -62),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = window,
	})

	Net.SetNotifier(UI.Toast)

	State.Changed:Connect(function(d)
		UI.RefreshHud()
		UI.Render()
		if d and d.meta and d.meta.devTools and not devAdded and UI.Panels.dev then
			devAdded = true
			addButton(#buttons + 1, { id = "dev", text = "🛠️\nDev" })
		end
	end)
	player:GetAttributeChangedSignal("Area"):Connect(UI.RefreshHud)

	-- Refresco periodico (temporizadores)
	task.spawn(function()
		while true do
			task.wait(1)
			UI.RefreshHud()
			updateRaidBanner()
			if UI.current and UI.Panels[UI.current] and UI.Panels[UI.current].live then
				UI.Render()
			end
		end
	end)
	RunService.Heartbeat:Connect(function()
		if raidState and raidState.phase ~= "idle" and raidBanner.Visible then
			updateRaidBanner()
		end
	end)
end

-- pequeño efecto visual de disparo (el cliente solo dibuja; el servidor valida)
function UI.ShotFx()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local boss = nil
	for _, m in ipairs(game:GetService("CollectionService"):GetTagged("RaidBoss")) do
		boss = m
	end
	if not hrp or not boss or not boss.PrimaryPart then
		return
	end
	local from, to = hrp.Position, boss.PrimaryPart.Position
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 120, 220)
	local dist = (to - from).Magnitude
	p.Size = Vector3.new(0.4, 0.4, dist)
	p.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist / 2)
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(0.25), { Transparency = 1 }):Play()
	game:GetService("Debris"):AddItem(p, 0.3)
end

return UI
