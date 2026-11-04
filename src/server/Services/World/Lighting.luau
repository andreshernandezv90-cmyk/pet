-- World/Lighting: ambiente global (atmosfera, cielo, bloom suave, rayos de sol).
-- El cliente ajusta tonos por zona en WorldFx; aqui se fija la base.

local LightingService = game:GetService("Lighting")

local Lighting = {}

local function ensure(className, name)
	local inst = LightingService:FindFirstChild(name)
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		inst.Parent = LightingService
	end
	return inst
end

function Lighting.Setup()
	pcall(function()
		LightingService.ClockTime = 15.6
		LightingService.Brightness = 2.4
		LightingService.EnvironmentDiffuseScale = 1
		LightingService.EnvironmentSpecularScale = 0.5
		LightingService.ShadowSoftness = 0.35
		LightingService.GlobalShadows = true
		LightingService.Ambient = Color3.fromRGB(110, 105, 120)
		LightingService.OutdoorAmbient = Color3.fromRGB(140, 135, 150)
	end)
	local atm = ensure("Atmosphere", "PP_Atmosphere")
	atm.Density = 0.3
	atm.Offset = 0.2
	atm.Color = Color3.fromRGB(205, 220, 240)
	atm.Decay = Color3.fromRGB(120, 130, 160)
	atm.Glare = 0.15
	atm.Haze = 1.4
	ensure("Sky", "PP_Sky")
	local bloom = ensure("BloomEffect", "PP_Bloom")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.6
	local rays = ensure("SunRaysEffect", "PP_SunRays")
	rays.Intensity = 0.05
	rays.Spread = 0.6
	local cc = ensure("ColorCorrectionEffect", "PP_Grade")
	cc.Saturation = 0.12
	cc.Contrast = 0.05
	cc.Brightness = 0.01
end

return Lighting
