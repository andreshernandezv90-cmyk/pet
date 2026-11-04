-- Stats: calculo de bonificaciones de compañeros, fusiones, pociones y topes.
-- Compartido por servidor (autoridad) y cliente (solo para mostrar).
-- (GDD 05, 06, 09, 10, 13 y 19)

local PetCatalog = require(script.Parent.PetCatalog)
local Items = require(script.Parent.Items)
local Progression = require(script.Parent.Progression)

local Stats = {}

Stats.SupportFactor = 0.5 -- apoyos aplican 50% de sus bonos numericos
Stats.ZoneResist = { 0, 0.03, 0.06, 0.09, 0.12 }

-- Bono numerico de un PET individual como compañero
function Stats.PetBonus(speciesId, rarityId, level)
	local sp = PetCatalog.Get(speciesId)
	local r = PetCatalog.Rarity(rarityId)
	local out = {}
	if not sp or not r then
		return out
	end
	local lp = PetCatalog.LevelPower[(level or 0) + 1] or 1
	for stat, base in pairs(sp.bonus) do
		out[stat] = base * r.power * lp
	end
	return out
end

-- Produccion por segundo de un PET trabajador en una estacion (0 si incompatible)
function Stats.WorkRate(speciesId, rarityId, level, stationId)
	local sp = PetCatalog.Get(speciesId)
	local r = PetCatalog.Rarity(rarityId)
	if not sp or not r or not sp.jobs[stationId] then
		return 0
	end
	local lw = PetCatalog.LevelWork[(level or 0) + 1] or 1
	return sp.jobs[stationId] * r.work * lw
end

local function addInto(dst, src, factor)
	for k, v in pairs(src) do
		dst[k] = (dst[k] or 0) + v * factor
	end
end

-- Lista de fusiones activas (no vencidas)
function Stats.ActiveFusions(profile, now)
	local list = {}
	for _, slot in ipairs(profile.fusion.slots) do
		if slot.fusion and slot.fusion.endsAt > now then
			table.insert(list, slot.fusion)
		end
	end
	return list
end

function Stats.EffectActive(profile, potionId, now)
	local t = profile.effects[potionId]
	return t ~= nil and t > now
end

-- Agregado total del jugador. now = os.time() del servidor.
function Stats.Aggregate(profile, now)
	local raw = {}
	local flags = {}
	-- Equipo de exploracion
	for i, id in ipairs(profile.team) do
		local u = profile.units[id]
		if u then
			addInto(raw, Stats.PetBonus(u.s, u.r, u.lv), i == 1 and 1 or Stats.SupportFactor)
			local sp = PetCatalog.Get(u.s)
			if sp then
				for f in pairs(sp.flags) do
					flags[f] = true
				end
			end
		end
	end
	-- Fusiones activas: combinan los atributos de ambos PETs
	for _, f in ipairs(Stats.ActiveFusions(profile, now)) do
		addInto(raw, Stats.PetBonus(f.a.s, f.a.r, f.a.lv), 1)
		addInto(raw, Stats.PetBonus(f.b.s, f.b.r, f.b.lv), 1)
		for _, part in ipairs({ f.a, f.b }) do
			local sp = PetCatalog.Get(part.s)
			if sp then
				for fl in pairs(sp.flags) do
					flags[fl] = true
				end
			end
		end
	end
	-- Pociones
	if Stats.EffectActive(profile, "impulso", now) then
		raw.mineSpeed = (raw.mineSpeed or 0) + 0.20
	end
	if Stats.EffectActive(profile, "mineria", now) then
		raw.oreYield = (raw.oreYield or 0) + 0.30
	end
	if Stats.EffectActive(profile, "succion", now) then
		raw.captureSpeed = (raw.captureSpeed or 0) + 0.25
	end
	if Stats.EffectActive(profile, "instinto", now) then
		flags.instinct = true
	end
	-- Topes por categoria
	local stats = {}
	for stat, info in pairs(PetCatalog.StatInfo) do
		stats[stat] = math.min(raw[stat] or 0, info.cap)
	end
	local collection = Progression.CollectionBonus(profile)
	return {
		stats = stats,
		flags = flags,
		luck = Stats.EffectActive(profile, "fortuna", now) and 2 or 1,
		growthMult = (Stats.EffectActive(profile, "crecimiento", now) and 1.5 or 1) * (1 + stats.growth),
		production = 1 + collection,
	}
end

-- Parametros de captura (tiempo de succion y probabilidad de exito)
function Stats.CaptureParams(agg, profile, speciesId, rarityId)
	local sp = PetCatalog.Get(speciesId)
	local r = PetCatalog.Rarity(rarityId)
	local vac = Items.Vacuums[profile.tools.vacuum] or Items.Vacuums[1]
	local zone = sp and sp.zone or 1
	local chance = r.catchChance - Stats.ZoneResist[zone] + vac.chance + agg.stats.captureEase
	local baitId = profile.activeBait
	local baitBonus = 0
	if baitId and (profile.items.baits[baitId] or 0) > 0 then
		local b = Items.Baits[baitId]
		if b then
			local fav = sp and sp.bait == baitId
			baitBonus = (fav and b.favBonus or b.bonus) * (1 + agg.stats.baitPower)
		end
	end
	chance = math.clamp(chance + baitBonus, 0.05, 0.97)
	local time = (1.5 + (zone - 1) * 0.4 + r.catchTime) * (1 - vac.speed) / (1 + agg.stats.captureSpeed)
	time = math.max(0.6, time)
	return { chance = chance, time = time, baitBonus = baitBonus, range = vac.range }
end

-- Dano por golpe de pico
function Stats.MineDamage(agg, pickLevel)
	local pick = Items.Picks[pickLevel] or Items.Picks[1]
	return pick.damage * (1 + agg.stats.mineSpeed + agg.stats.mineDamage)
end

-- Dano por golpe de hacha (arboles)
function Stats.ChopDamage(agg, axeLevel)
	local axe = Items.Axes[axeLevel or 1] or Items.Axes[1]
	return axe.damage * (1 + agg.stats.mineSpeed * 0.5)
end

-- Multiplicador de botin para un recurso
function Stats.YieldMult(agg, resource, axeLevel)
	local m = 1 + agg.stats.oreYield
	if resource == "cobre" then
		m = m + agg.stats.copperFind
	elseif resource == "madera" then
		local axe = Items.Axes[axeLevel or 1] or Items.Axes[1]
		m = 1 + agg.stats.woodYield + axe.wood
	end
	return m
end

-- Poder de "trabajo" de un PET en el huerto (Musguito/Florin/Brumi)
function Stats.GardenPower(profile, speciesId)
	local total = 0
	local st = profile.stations.garden
	for _, id in ipairs(st.workers) do
		local u = profile.units[id]
		if u and u.s == speciesId then
			total = total + Stats.WorkRate(u.s, u.r, u.lv, "garden")
		end
	end
	return total
end

return Stats
