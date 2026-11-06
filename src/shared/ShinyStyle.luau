-- ShinyStyle: apariencia de las variantes Shiny, separada de la logica de juego.
--
-- Shiny es SOLO visual (GDD 23): nunca cambia estadisticas, habilidades,
-- produccion ni combate. Este modulo decide como se ve:
--   * Paleta: por defecto se calcula girando el tono de los colores de la
--     especie; cada especie puede tener su propia paleta en ShinyStyle.Species.
--   * Particulas ligeras (moviles): pocas, cortas y sin luz extra.
--   * Modelos importados: PetAssets busca primero "<Modelo>_<rareza>_shiny" y
--     "<Modelo>_shiny" (ver docs/ART_PIPELINE.md); si no existen, usa el modelo
--     normal con las particulas Shiny.

local ShinyStyle = {}

ShinyStyle.Icon = "✨"

-- Particulas provisionales (bajo coste en moviles)
ShinyStyle.Particles = {
	rate = 3, -- particulas por segundo
	lifetime = { 0.6, 1.0 },
	size = 0.22, -- multiplicado por el tamaño del PET
	speed = { 0.4, 1.0 },
	lightEmission = 0.5,
	defaultColor = Color3.fromRGB(255, 236, 140),
}

-- Apariencias personalizadas por especie (vacio = paleta automatica).
-- Ejemplo para el futuro:
--   lumi = { color = Color3.fromRGB(150, 220, 255), color2 = Color3.fromRGB(230, 250, 255),
--            particle = Color3.fromRGB(180, 230, 255), model = "Lumi" },
ShinyStyle.Species = {}

local function shift(c, hueShift)
	local h, s, v = c:ToHSV()
	return Color3.fromHSV((h + hueShift) % 1, math.clamp(s * 1.1 + 0.05, 0, 1), math.clamp(v * 1.05, 0, 1))
end

-- Paleta Shiny de una especie: { color, color2, particle }
function ShinyStyle.Palette(sp)
	local custom = ShinyStyle.Species[sp.id]
	if custom and custom.color then
		return {
			color = custom.color,
			color2 = custom.color2 or custom.color,
			particle = custom.particle or ShinyStyle.Particles.defaultColor,
		}
	end
	return {
		color = shift(sp.color, 0.42),
		color2 = shift(sp.color2 or sp.color, 0.42),
		particle = ShinyStyle.Particles.defaultColor,
	}
end

return ShinyStyle
