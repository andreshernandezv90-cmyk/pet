-- Portal Pets: Rescate Dimensional — arranque del cliente.

local StarterGui = game:GetService("StarterGui")

local State = require(script.State)
local Net = require(script.Net)
local UI = require(script.UI)
local Encounters = require(script.Encounters)
local Followers = require(script.Followers)
local WorldFx = require(script.WorldFx)

local Panels = script:WaitForChild("Panels")

Net.Init()
UI.Init()

UI.Register("map", require(Panels.Map))
UI.Register("pets", require(Panels.Pets))
UI.Register("bag", require(Panels.Bag))
UI.Register("workshop", require(Panels.Workshop))
UI.Register("stations", require(Panels.Stations))
UI.Register("alchemy", require(Panels.Alchemy))
UI.Register("reactor", require(Panels.Reactor))
UI.Register("fusion", require(Panels.Fusion))
UI.Register("shop", require(Panels.Shop))
UI.Register("dev", require(Panels.Dev))

Net.On("State", function(view)
	State.Set(view)
end)
Net.On("Notify", function(text, kind)
	UI.Toast(text, kind)
end)
Net.On("OpenPanel", function(panel, spot)
	local arg = nil
	if spot == "bait" then
		arg = "bait"
	end
	UI.Open(panel, arg)
end)
Net.On("Raid", function(data)
	UI.SetRaid(data)
end)

Encounters.Init()
Followers.Init()
WorldFx.Init()

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

-- Pide el estado inicial (reintenta mientras el perfil se carga)
task.spawn(function()
	for _ = 1, 30 do
		local r = Net.Call("hello", {}, { silent = true })
		if r.ok then
			break
		end
		task.wait(1)
	end
end)
