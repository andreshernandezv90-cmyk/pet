-- Items: recursos, herramientas, nodos, cebos y pociones.
-- (GDD secciones 02, 06, 07 y 09)

local Items = {}

-- Recursos ---------------------------------------------------------------------
Items.Resources = {
	madera = { name = "Madera", icon = "🪵", world = "Hogar" },
	piedra = { name = "Piedra", icon = "🪨", world = "Minas" },
	cobre = { name = "Cobre", icon = "🟠", world = "Minas" },
	hierro = { name = "Hierro", icon = "⛓️", world = "Minas" },
	lunar = { name = "Cristal lunar", icon = "🌙", world = "Minas" },
	zuarita = { name = "Zuarita", icon = "💎", world = "Minas" },
	petalo = { name = "Petalo luminoso", icon = "🌸", world = "Zona 1" },
	engranaje = { name = "Engranaje antiguo", icon = "⚙️", world = "Zona 2" },
	hongo = { name = "Hongo sombrio", icon = "🍄", world = "Zona 3" },
	elemental = { name = "Chispa elemental", icon = "🔥", world = "Zona 4" },
	estelar = { name = "Polvo estelar", icon = "✨", world = "Zona 5" },
	baya = { name = "Baya", icon = "🫐", world = "Huerto" },
	raiz = { name = "Raiz", icon = "🥕", world = "Huerto" },
	flor = { name = "Flor", icon = "🌼", world = "Huerto" },
	semilla = { name = "Semilla", icon = "🌱", world = "Huerto" },
	polvo = { name = "Polvo de Zuarita", icon = "🔷", world = "Trabajo" },
	cuarzo = { name = "Cuarzo aereo", icon = "🌬️", world = "Trabajo" },
	prisma = { name = "Fragmento prismatico", icon = "🔺", world = "Trabajo" },
	gravedad = { name = "Fragmento gravitacional", icon = "🌀", world = "Trabajo" },
	astral = { name = "Energia astral", icon = "⭐", world = "Trabajo" },
	eclipse = { name = "Fragmento del eclipse", icon = "🌑", world = "Trabajo" },
}
Items.ResourceOrder = {
	"madera", "piedra", "cobre", "hierro", "lunar", "zuarita",
	"petalo", "engranaje", "hongo", "elemental", "estelar",
	"baya", "raiz", "flor", "semilla",
	"polvo", "cuarzo", "prisma", "gravedad", "astral", "eclipse",
}

function Items.ResName(id)
	local r = Items.Resources[id]
	return r and (r.icon .. " " .. r.name) or id
end

-- Picos (GDD 02, Minas de Zuar) -----------------------------------------------
Items.Picks = {
	{ level = 1, name = "Pico de madera", damage = 1.0, unlocks = "piedra" },
	{ level = 2, name = "Pico de piedra", damage = 1.6, unlocks = "cobre" },
	{ level = 3, name = "Pico de cobre", damage = 2.3, unlocks = "hierro" },
	{ level = 4, name = "Pico de hierro", damage = 3.2, unlocks = "cristal lunar" },
	{ level = 5, name = "Pico de cristal", damage = 4.5, unlocks = "Zuarita" },
}

-- Succionador de Resonancia (GDD 06) -------------------------------------------
Items.Vacuums = {
	{ level = 1, name = "Succionador basico", chance = 0.00, speed = 0.00, range = 14, raid = 1.0 },
	{ level = 2, name = "Succionador reforzado", chance = 0.06, speed = 0.10, range = 16, raid = 1.3 },
	{ level = 3, name = "Succionador magnetico", chance = 0.12, speed = 0.20, range = 18, raid = 1.6 },
	{ level = 4, name = "Succionador dimensional", chance = 0.18, speed = 0.30, range = 20, raid = 2.0 },
	{ level = 5, name = "Succionador maestro", chance = 0.25, speed = 0.40, range = 24, raid = 2.5 },
}

-- Nodos recolectables ---------------------------------------------------------------
-- hp: golpes de pico de madera. pick: nivel minimo. yield: {min,max}. respawn: seg.
Items.Nodes = {
	tree = { name = "Arbol", resource = "madera", hp = 3, pick = 1, yield = { 3, 5 }, respawn = 20, action = "Talar",
		color = Color3.fromRGB(70, 140, 60) },
	stone = { name = "Roca", resource = "piedra", hp = 3, pick = 1, yield = { 3, 5 }, respawn = 20, action = "Minar",
		color = Color3.fromRGB(130, 130, 135) },
	copper = { name = "Veta de cobre", resource = "cobre", hp = 4.5, pick = 2, yield = { 2, 4 }, respawn = 25, action = "Minar",
		color = Color3.fromRGB(205, 120, 60) },
	iron = { name = "Veta de hierro", resource = "hierro", hp = 6, pick = 3, yield = { 2, 3 }, respawn = 30, action = "Minar",
		color = Color3.fromRGB(160, 160, 175) },
	lunar = { name = "Cristal lunar", resource = "lunar", hp = 8, pick = 4, yield = { 1, 3 }, respawn = 35, action = "Minar",
		color = Color3.fromRGB(170, 190, 255) },
	zuarita = { name = "Deposito de Zuarita", resource = "zuarita", hp = 10, pick = 5, yield = { 1, 2 }, respawn = 45, action = "Minar",
		color = Color3.fromRGB(70, 230, 210) },
	petalo = { name = "Flor luminosa", resource = "petalo", hp = 2, pick = 1, yield = { 1, 3 }, respawn = 25, action = "Recoger",
		color = Color3.fromRGB(255, 190, 230) },
	engranaje = { name = "Chatarra de engranajes", resource = "engranaje", hp = 3, pick = 1, yield = { 1, 3 }, respawn = 25, action = "Recoger",
		color = Color3.fromRGB(190, 160, 90) },
	hongo = { name = "Hongo sombrio", resource = "hongo", hp = 3, pick = 1, yield = { 1, 3 }, respawn = 25, action = "Recoger",
		color = Color3.fromRGB(150, 90, 220) },
	elemental = { name = "Nucleo elemental", resource = "elemental", hp = 4, pick = 1, yield = { 1, 2 }, respawn = 30, action = "Recoger",
		color = Color3.fromRGB(255, 110, 60) },
	estelar = { name = "Polvo estelar", resource = "estelar", hp = 4, pick = 1, yield = { 1, 2 }, respawn = 35, action = "Recoger",
		color = Color3.fromRGB(255, 245, 170) },
}

-- Cultivos del huerto ---------------------------------------------------------------
Items.Crops = {
	baya = { name = "Baya", time = 60, yield = { 3, 4 }, seeds = { 1, 2 } },
	raiz = { name = "Raiz", time = 120, yield = { 3, 4 }, seeds = { 1, 2 } },
	flor = { name = "Flor", time = 180, yield = { 2, 4 }, seeds = { 1, 2 } },
}
Items.CropOrder = { "baya", "raiz", "flor" }
Items.GardenPlots = { 2, 4, 6, 8, 10 }

-- Cebos (estacion de cebos) --------------------------------------------------------
Items.Baits = {
	berry = { name = "Cebo de bayas", icon = "🫐", bonus = 0.10, favBonus = 0.25, cost = { baya = 3, petalo = 1 } },
	root = { name = "Cebo de raices", icon = "🥕", bonus = 0.10, favBonus = 0.25, cost = { raiz = 3, hongo = 1 } },
	flower = { name = "Cebo floral", icon = "🌼", bonus = 0.10, favBonus = 0.25, cost = { flor = 3, elemental = 1 } },
	star = { name = "Cebo estelar", icon = "✨", bonus = 0.12, favBonus = 0.30, cost = { baya = 2, raiz = 2, flor = 2, estelar = 1 } },
}
Items.BaitOrder = { "berry", "root", "flower", "star" }

-- Pociones (laboratorio de alquimia) -------------------------------------------------
Items.Potions = {
	fortuna = { name = "Fortuna", icon = "🍀", desc = "x2 modificador de suerte de aparicion.", duration = 15 * 60,
		cost = { flor = 2, lunar = 1, petalo = 2 } },
	mineria = { name = "Mineria abundante", icon = "⛏️", desc = "+30% recursos extraidos.", duration = 20 * 60,
		cost = { raiz = 3, cobre = 10 } },
	succion = { name = "Succion veloz", icon = "🌪️", desc = "+25% velocidad de captura.", duration = 15 * 60,
		cost = { baya = 3, engranaje = 2 } },
	impulso = { name = "Impulso de Zuar", icon = "💨", desc = "+20% velocidad de mineria.", duration = 20 * 60,
		cost = { raiz = 2, baya = 2, hierro = 5 } },
	instinto = { name = "Instinto salvaje", icon = "👁️", desc = "Revela PETs cercanos a traves de muros.", duration = 10 * 60,
		cost = { flor = 2, hongo = 2 } },
	crecimiento = { name = "Crecimiento magico", icon = "🌿", desc = "x1.5 velocidad de cultivos.", duration = 30 * 60,
		cost = { baya = 2, raiz = 2, flor = 2 } },
}
Items.PotionOrder = { "fortuna", "mineria", "succion", "impulso", "instinto", "crecimiento" }
Items.PotionMaxStack = 60 * 60 -- una pocion repetida extiende la duracion hasta 60 min

return Items
