-- Merchant: NPCs del campamento (Comerciante, Guia, Tienda premium) e
-- intercambio de materiales sin moneda. Todo se valida en el servidor:
-- cercania al comerciante, zona desbloqueada, cantidades enteras y
-- materiales suficientes; con nonce para que un reintento no duplique nada.

local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local WorldConfig = require(Shared.WorldConfig)
local PetStore = require(Shared.PetStore)
local Items = require(Shared.Items)

local Merchant = {}
local S

local function scaled(cost, n)
	local out = {}
	for k, v in pairs(cost) do
		out[k] = v * n
	end
	return out
end

function Merchant.Trade(player, profile, payload)
	local Data = S.Data
	local fresh, cached = Data.CheckNonce(player, payload.nonce)
	if not fresh then
		return cached
	end
	local t = type(payload.id) == "string" and WorldConfig.TradeById[payload.id]
	if not t then
		return { ok = false, msg = "Intercambio invalido." }
	end
	local n = tonumber(payload.n) or 1
	if n % 1 ~= 0 or n < 1 or n > WorldConfig.Trades.maxPerTrade then
		return { ok = false, msg = "Cantidad invalida." }
	end
	if profile.zones.unlocked < t.zone then
		return { ok = false, msg = "Disponible al desbloquear la Zona " .. t.zone .. "." }
	end
	local npc = S.World.Npcs and S.World.Npcs.merchant
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not npc or not hrp or (hrp.Position - npc).Magnitude > WorldConfig.Trades.merchantRange then
		return { ok = false, msg = "Habla con el Comerciante del campamento para intercambiar." }
	end
	-- operacion atomica (sin yields): cobrar y entregar
	if not PetStore.SpendCost(profile, scaled(t.give, n)) then
		return { ok = false, msg = "Te faltan materiales para este intercambio." }
	end
	local get = t.get
	local amount = get.n * n
	local text
	if get.kind == "resource" then
		local added = PetStore.AddToBackpack(profile, get.id, amount)
		if added < amount then
			PetStore.AddToStorage(profile, get.id, amount - added)
		end
		text = "+" .. amount .. " " .. Items.ResName(get.id)
	elseif get.kind == "bait" then
		profile.items.baits[get.id] = (profile.items.baits[get.id] or 0) + amount
		text = "+" .. amount .. " " .. Items.Baits[get.id].name
	elseif get.kind == "potion" then
		profile.items.potions[get.id] = (profile.items.potions[get.id] or 0) + amount
		text = "+" .. amount .. " " .. Items.Potions[get.id].name
	end
	local res = { ok = true, msg = "🤝 Intercambio hecho: " .. (text or t.name) }
	Data.StoreNonce(player, payload.nonce, res)
	return res
end

function Merchant.Init(services)
	S = services
	S.Net.Register("trade", function(player, profile, payload)
		return Merchant.Trade(player, profile, payload)
	end)
end

function Merchant.Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if CollectionService:HasTag(prompt, "NpcPrompt") then
			S.Net.Fire(player, "OpenPanel", prompt:GetAttribute("Panel"), prompt:GetAttribute("Npc"))
		end
	end)
end

return Merchant
