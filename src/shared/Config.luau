-- Portal Pets: Rescate Dimensional
-- Parametros globales del juego. Todos los numeros de balance son
-- "parametros iniciales para equilibrar en pruebas" (ver GDD, nota de control).

local Config = {}

Config.GameName = "Portal Pets: Rescate Dimensional"
Config.Version = "1.0.0"

-- Persistencia ---------------------------------------------------------------
Config.DataStoreName = "PortalPets_Perfiles_v1"
Config.SchemaVersion = 2 -- v2: Mundo PET continuo (faros, zonas visitadas, NPCs)
Config.AutosaveInterval = 60 -- segundos
Config.SessionLockStale = 180 -- un bloqueo sin renovar por mas de esto se considera abandonado
Config.LoadRetries = 5

-- Inventario -----------------------------------------------------------------
Config.PetStackSize = 50 -- PETs identicos por espacio de tanque/almacen
Config.ResourceStackSize = 100 -- recursos por espacio de mochila
Config.MaxPaidSlots = 60 -- tope de espacios comprados por tipo

-- Capturas -------------------------------------------------------------------
Config.SpawnMin = 7
Config.SpawnMax = 12
Config.SpawnRefresh = 60 -- segundos
Config.EncounterRadius = 30 -- distancia maxima servidor (incluye deambular)
Config.EscapeChanceOnFail = 0.5

-- Produccion -----------------------------------------------------------------
Config.ProductionTick = 5
Config.OfflineMaxSeconds = 2 * 60 * 60
Config.OfflineEfficiency = 0.5

-- Fusiones -------------------------------------------------------------------
Config.FusionDuration = 20 * 60
Config.FusionCooldown = 30 * 60
Config.VipCooldownFactor = 0.8 -- 20% mas rapida (24 min)
Config.FusionSlotsFree = 1
Config.FusionSlotsVip = 2

-- Incursiones ----------------------------------------------------------------
Config.RaidInterval = 60 * 60 -- servidor publicado
Config.RaidIntervalStudio = 5 * 60 -- en Roblox Studio para probar mas rapido
Config.RaidAnnounce = 60
Config.RaidMaxDuration = 5 * 60

-- Cofres secretos ------------------------------------------------------------
Config.ChestCooldown = 20 * 60

-- Monetizacion ---------------------------------------------------------------
-- Reemplaza los productId/gamePassId por los IDs reales de tu experiencia.
-- Mientras valgan 0, en Studio se pueden "comprar" gratis para probar.
Config.VipGamePassId = 0
Config.StudioTestPurchases = true

Config.Products = {
	{ key = "bp1", name = "+1 espacio de mochila", kind = "backpack", amount = 1, price = 9, productId = 0 },
	{ key = "bp5", name = "+5 espacios de mochila", kind = "backpack", amount = 5, price = 39, productId = 0 },
	{ key = "bp10", name = "+10 espacios de mochila", kind = "backpack", amount = 10, price = 69, productId = 0 },
	{ key = "bp20", name = "+20 espacios de mochila", kind = "backpack", amount = 20, price = 119, productId = 0 },
	{ key = "tk1", name = "+1 espacio de tanque", kind = "tank", amount = 1, price = 9, productId = 0 },
	{ key = "tk5", name = "+5 espacios de tanque", kind = "tank", amount = 5, price = 39, productId = 0 },
	{ key = "tk10", name = "+10 espacios de tanque", kind = "tank", amount = 10, price = 69, productId = 0 },
	{ key = "tk20", name = "+20 espacios de tanque", kind = "tank", amount = 20, price = 119, productId = 0 },
	{ key = "hat", name = "Sombrero para PET", kind = "cosmetic", cosmetic = "hat", price = 29, productId = 0 },
	{ key = "trail", name = "Estela magica", kind = "cosmetic", cosmetic = "trail", price = 49, productId = 0 },
	{ key = "wings", name = "Alas", kind = "cosmetic", cosmetic = "wings", price = 79, productId = 0 },
	{ key = "welcome", name = "Paquete de bienvenida", kind = "bundle", cosmetic = "hat", price = 99, productId = 0,
		resources = { madera = 200, piedra = 200, semilla = 10 } },
	{ key = "portal", name = "Portal decorativo", kind = "cosmetic", cosmetic = "portal", price = 129, productId = 0 },
	{ key = "visualpet", name = "PET visual adicional", kind = "cosmetic", cosmetic = "visualpet", price = 149, productId = 0 },
}

-- Herramientas de desarrollo: solo funcionan dentro de Roblox Studio.
Config.DevToolsInStudio = true

-- Seguridad ------------------------------------------------------------------
Config.ActionRateLimit = 20 -- acciones por segundo por jugador (cubeta)
Config.MineCooldown = 0.35
Config.RaidShotCooldown = 0.3
Config.TeleportCooldown = 2

return Config
