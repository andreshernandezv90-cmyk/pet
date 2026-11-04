-- Commerce (CommerceService): productos de desarrollador con recibos
-- idempotentes, pase VIP y cosmeticos. Nada aleatorio se vende con Robux.
-- (GDD 14 y 15)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PetStore = require(Shared.PetStore)

local Commerce = {}
local S

local vipCache = {} -- [player] = bool (pase de juego)
local byProductId = {}
local byKey = {}

for _, p in ipairs(Config.Products) do
	byKey[p.key] = p
	if p.productId and p.productId ~= 0 then
		byProductId[p.productId] = p
	end
end

function Commerce.IsVip(player, profile)
	profile = profile or (S and S.Data.Get(player))
	return (profile and profile.vip == true) or vipCache[player] == true
end

local function grant(player, profile, product)
	if product.kind == "backpack" or product.kind == "tank" then
		local cur = profile.paid[product.kind] or 0
		profile.paid[product.kind] = math.min(Config.MaxPaidSlots, cur + product.amount)
	elseif product.kind == "cosmetic" then
		profile.cosmetics[product.cosmetic] = true
	elseif product.kind == "bundle" then
		if product.cosmetic then
			profile.cosmetics[product.cosmetic] = true
		end
		for id, n in pairs(product.resources or {}) do
			PetStore.AddToStorage(profile, id, n)
		end
	end
	S.Inventory.RefreshPlayer(player)
	S.Plots.Refresh(player)
	S.Net.MarkDirty(player)
	S.Net.Notify(player, "🛍️ Compra completada: " .. product.name .. ". ¡Gracias por apoyar el juego!", "success")
end

local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = S.Data.Get(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local rid = tostring(info.PurchaseId)
	if profile.receipts[rid] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local product = byProductId[info.ProductId]
	if not product then
		warn("[PortalPets] Producto desconocido: " .. tostring(info.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	grant(player, profile, product)
	profile.receipts[rid] = true
	table.insert(profile.receiptOrder, rid)
	while #profile.receiptOrder > 100 do
		local old = table.remove(profile.receiptOrder, 1)
		profile.receipts[old] = nil
	end
	-- guardar de inmediato; si falla, Roblox reintentara y el recibo evita duplicar
	if S.Data.IsPersistent(player) and not S.Data.SaveNow(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Commerce.CheckVip(player)
	if Config.VipGamePassId == 0 then
		return
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.VipGamePassId)
	end)
	if ok then
		vipCache[player] = owns
	end
end

function Commerce.Init(services)
	S = services
	S.Net.Register("testPurchase", function(player, profile, payload)
		if not (RunService:IsStudio() and Config.StudioTestPurchases) then
			return { ok = false, msg = "Solo disponible en Studio." }
		end
		if payload.key == "vip" then
			profile.vip = not profile.vip
			S.Inventory.RefreshPlayer(player)
			S.Plots.Refresh(player)
			return { ok = true, msg = profile.vip and "VIP activado (prueba en Studio)." or "VIP desactivado." }
		end
		local product = type(payload.key) == "string" and byKey[payload.key]
		if not product then
			return { ok = false, msg = "Producto invalido." }
		end
		grant(player, profile, product)
		return { ok = true }
	end)

	S.Net.Register("toggleCosmetic", function(player, profile, payload)
		local id = payload.id
		if type(id) ~= "string" then
			return { ok = false }
		end
		local key = "hide_" .. id
		profile.cosmetics[key] = not profile.cosmetics[key]
		S.Inventory.RefreshPlayer(player)
		return { ok = true, msg = profile.cosmetics[key] and "Cosmetico oculto." or "Cosmetico visible." }
	end)
end

function Commerce.Start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and passId == Config.VipGamePassId then
			vipCache[player] = true
			S.Inventory.RefreshPlayer(player)
			S.Plots.Refresh(player)
			S.Net.MarkDirty(player)
			S.Net.Notify(player, "👑 ¡Ahora eres VIP!", "success")
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		vipCache[player] = nil
	end)
end

return Commerce
