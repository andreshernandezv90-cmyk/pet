-- Portal Pets: Rescate Dimensional — arranque del servidor.
-- Carga los servicios, construye el mundo y gestiona la entrada de jugadores.

local Players = game:GetService("Players")

local Services = script:WaitForChild("Services")

local S = {
	World = require(Services.World),
	Data = require(Services.DataService),
	Net = require(Services.Net),
	Plots = require(Services.Plots),
	Inventory = require(Services.Inventory),
	Mining = require(Services.Mining),
	Capture = require(Services.Capture),
	Progress = require(Services.Progress),
	Crafting = require(Services.Crafting),
	Production = require(Services.Production),
	Alchemy = require(Services.Alchemy),
	Essence = require(Services.Essence),
	Fusion = require(Services.Fusion),
	Raid = require(Services.Raid),
	Commerce = require(Services.Commerce),
	DevTools = require(Services.DevTools),
}

local ORDER = { "Data", "Net", "Plots", "Inventory", "Mining", "Capture", "Progress", "Crafting", "Production",
	"Alchemy", "Essence", "Fusion", "Raid", "Commerce", "DevTools" }

S.World.Build()

for _, name in ipairs(ORDER) do
	local mod = S[name]
	if mod.Init then
		mod.Init(S)
	end
end

S.Net.Register("hello", function(player)
	S.Net.PushNow(player)
	S.Capture.Resend(player)
	for id, secs in pairs(S.Mining.RespawnTimes(player)) do
		S.Net.Fire(player, "NodeState", id, secs)
	end
	return { ok = true }
end)

for _, name in ipairs(ORDER) do
	local mod = S[name]
	if mod.Start then
		mod.Start()
	end
end

local function moveToPlot(player, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if hrp and player.Parent then
		task.wait(0.1)
		local cf = S.Plots.SpawnCFrame(player)
		pcall(function()
			player:RequestStreamAroundAsync(cf.Position, 3)
		end)
		char:PivotTo(cf)
		player:SetAttribute("Area", "home")
		S.Capture.OnAreaChanged(player, "home")
	end
end

local function onJoin(player)
	local rec = S.Data.Load(player)
	if not rec or not player.Parent then
		return
	end
	local profile = rec.data
	S.Commerce.CheckVip(player)
	S.Plots.Assign(player)
	S.Production.ApplyOffline(player, profile)
	S.Fusion.OnJoin(player, profile)
	S.Progress.CheckUnlocks(player, profile)
	S.Inventory.RefreshPlayer(player)
	S.Plots.Refresh(player)
	S.Net.PushNow(player)

	player.CharacterAdded:Connect(function(char)
		moveToPlot(player, char)
	end)
	if player.Character then
		task.spawn(moveToPlot, player, player.Character)
	end

	if not rec.persist then
		S.Net.Notify(player, "⚠️ Modo prueba: tu progreso NO se guardara. En Studio activa 'Enable Studio Access to API Services'.", "error")
	end
	S.Net.Notify(player, "¡Bienvenido a Portal Pets: Rescate Dimensional, " .. player.DisplayName .. "!", "info")
end

Players.PlayerAdded:Connect(onJoin)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onJoin, p)
end
