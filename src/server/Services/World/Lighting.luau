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
		LightingService.ClockTime = 14.8
		LightingService.Brightness = 2.1
		LightingService.EnvironmentDiffuseScale = 0.9
		LightingService.EnvironmentSpecularScale = 0.2 -- menos reflejos que compitan con personajes e interfaz
		LightingService.ShadowSoftness = 0.35
		LightingService.GlobalShadows = true
		LightingService.Ambient = Color3.fromRGB(110, 105, 120)
		LightingService.OutdoorAmbient = Color3.fromRGB(140, 135, 150)
	end)
	local atm = ensure("Atmosphere", "PP_Atmosphere")
	atm.Density = 0.24
	atm.Offset = 0.15
	atm.Color = Color3.fromRGB(205, 220, 240)
	atm.Decay = Color3.fromRGB(120, 130, 160)
	atm.Glare = 0
	atm.Haze = 0.8
	ensure("Sky", "PP_Sky")
	local bloom = ensure("BloomEffect", "PP_Bloom")
	-- bloom suave: solo los neones mas intensos brillan, sin velar la escena
	bloom.Intensity = 0.15
	bloom.Size = 18
	bloom.Threshold = 2.2
	local rays = ensure("SunRaysEffect", "PP_SunRays")
	rays.Intensity = 0.02
	rays.Spread = 0.6
	local cc = ensure("ColorCorrectionEffect", "PP_Grade")
	cc.Saturation = 0.06
	cc.Contrast = 0.04
	cc.Brightness = 0.01
end

return Lighting
