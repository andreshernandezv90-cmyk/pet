-- Production (WorkerProduction): extractores, asignacion de trabajadores,
-- huerto automatizado, capacidades y produccion desconectado. (GDD 08 y 09)
--   * Offline: hasta 2 h, 50% de eficiencia, nunca supera el deposito.
--   * El servidor calcula el tiempo transcurrido al volver (sin simular nada en segundo plano).

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PetCatalog = require(Shared.PetCatalog)
local PetStore = require(Shared.PetStore)
local Stats = require(Shared.Stats)
local Items = require(Shared.Items)

local Production = {}
local S

local function bufferTotal(st)
	local t = 0
	for _, v in pairs(st.buffer) do
		t = t + v
	end
	return t
end
Production.BufferTotal = bufferTotal

-- Produccion por segundo de una estacion: { [recurso] = tasa }
function Production.Rates(profile, stationId, agg)
	local st = profile.stations[stationId]
	local out = {}
	if st.level < 1 or stationId == "garden" then
		return out
	end
	local mult = agg and agg.production or 1
	for _, id in ipairs(st.workers) do
		local u = profile.units[id]
		if u then
			local product = PetCatalog.ProductFor(u.s, stationId)
			local rate = Stats.WorkRate(u.s, u.r, u.lv, stationId) * mult
			if product and rate > 0 then
				out[product] = (out[product] or 0) + rate
			end
		end
	end
	return out
end

-- Acumula produccion de una estacion hasta "now". efficiency < 1 para offline.
function Production.Accrue(profile, stationId, now, efficiency, maxSeconds)
	local st = profile.stations[stationId]
	if st.level < 1 or stationId == "garden" then
		st.updatedAt = now
		return {}
	end
	if (st.updatedAt or 0) <= 0 then
		st.updatedAt = now
		return {}
	end
	local dt = now - st.updatedAt
	if maxSeconds then
		dt = math.min(dt, maxSeconds)
	end
	st.updatedAt = now
	if dt <= 0 then
		return {}
	end
	local agg = Stats.Aggregate(profile, now)
	local rates = Production.Rates(profile, stationId, agg)
	local cap = PetCatalog.StationCapacity[st.level]
	local room = cap - bufferTotal(st)
	local gained = {}
	for product, rate in pairs(rates) do
		if room <= 0 then
			break
		end
		local add = math.min(rate * dt * (efficiency or 1), room)
		if add > 0 then
			st.buffer[product] = (st.buffer[product] or 0) + add
			room = room - add
			gained[product] = add
		end
	end
	return gained
end

local function gardenPowers(profile)
	return Stats.GardenPower(profile, "musguito"), Stats.GardenPower(profile, "florin"), Stats.GardenPower(profile, "brumi")
end

-- Avanza cultivos dt segundos; Florin cosecha y Brumi resiembra (si hay semillas)
local function growGarden(profile, dt, now, oneCycle)
	local level = profile.buildings.garden
	if level < 1 or dt <= 0 then
		return 0, 0
	end
	local agg = Stats.Aggregate(profile, now)
	local musguito, florin, brumi = gardenPowers(profile)
	local speed = agg.growthMult * (1 + musguito)
	local harvested, replanted = 0, 0
	local st = profile.stations.garden
	local cap = PetCatalog.StationCapacity[math.clamp(level, 1, 5)]
	local rng = Random.new()
	for i = 1, Items.GardenPlots[level] do
		local plot = profile.garden.plots[i]
		if plot and plot.crop then
			local def = Items.Crops[plot.crop]
			plot.progress = math.min(1, (plot.progress or 0) + dt * speed / def.time)
			if plot.progress >= 1 and florin > 0 and bufferTotal(st) < cap then
				local crop = plot.crop
				local n = rng:NextInteger(def.yield[1], def.yield[2])
				st.buffer[crop] = (st.buffer[crop] or 0) + n
				st.buffer.semilla = (st.buffer.semilla or 0) + rng:NextInteger(def.seeds[1], def.seeds[2])
				harvested = harvested + 1
				plot.crop = nil
				plot.progress = 0
				if brumi > 0 and PetStore.SpendCost(profile, { semilla = 1 }) then
					plot.crop = crop
					plot.progress = 0
					replanted = replanted + 1
				end
			end
		end
	end
	return harvested, replanted
end

function Production.AccrueAll(player, profile)
	local now = os.time()
	for id in pairs(profile.stations) do
		Production.Accrue(profile, id, now)
	end
end

-- Al entrar: produccion desconectado
function Production.ApplyOffline(player, profile)
	local now = os.time()
	local summary = {}
	for id, st in pairs(profile.stations) do
		if st.level >= 1 and id ~= "garden" and (st.updatedAt or 0) > 0 then
			local elapsed = math.min(now - st.updatedAt, Config.OfflineMaxSeconds)
			if elapsed > 30 then
				st.updatedAt = now - elapsed
				local g = Production.Accrue(profile, id, now, Config.OfflineEfficiency)
				for k, v in pairs(g) do
					summary[k] = (summary[k] or 0) + v
				end
			end
		end
		st.updatedAt = now
	end
	local last = profile.lastSave or 0
	if last > 0 and profile.buildings.garden >= 1 then
		local elapsed = math.min(now - last, Config.OfflineMaxSeconds)
		if elapsed > 30 then
			growGarden(profile, elapsed, now, true)
		end
	end
	local parts = {}
	for k, v in pairs(summary) do
		if v >= 1 then
			table.insert(parts, string.format("+%d %s", math.floor(v), Items.ResName(k)))
		end
	end
	if #parts > 0 then
		S.Net.Notify(player, "⏰ Mientras no estabas tus PETs produjeron: " .. table.concat(parts, ", ") .. ". ¡Recogelo en Estaciones!", "success")
	end
end

local function result(ok, msg)
	return { ok = ok, msg = msg }
end

function Production.Init(services)
	S = services
	local Net = S.Net

	Net.Register("assign", function(player, profile, payload)
		local sid = payload.station
		local def = type(sid) == "string" and PetCatalog.Stations[sid]
		if not def then
			return result(false, "Estacion invalida.")
		end
		local st = profile.stations[sid]
		if st.level < 1 then
			return result(false, "Primero construye " .. def.name .. " en el Taller.")
		end
		if #st.workers >= PetCatalog.StationSlots[st.level] then
			return result(false, "No hay puestos libres. Mejora la estacion.")
		end
		local ref = payload.ref
		local key = type(ref) == "table" and (ref.key or (ref.unit and profile.units[ref.unit] and PetCatalog.Key(profile.units[ref.unit].s, profile.units[ref.unit].r)))
		local s = key and PetCatalog.ParseKey(key)
		local sp = s and PetCatalog.Get(s)
		if not sp or not sp.jobs[sid] then
			return result(false, "Ese PET no sabe trabajar en " .. def.name .. ".")
		end
		local now = os.time()
		Production.Accrue(profile, sid, now)
		local unit = PetStore.Resolve(profile, ref)
		if not unit then
			return result(false, "Ese PET no esta disponible.")
		end
		unit.st = "working"
		table.insert(st.workers, unit.id)
		S.Plots.Refresh(player)
		return result(true, sp.name .. " ahora trabaja en " .. def.name .. ".")
	end)

	Net.Register("unassign", function(player, profile, payload)
		local u = type(payload.unit) == "string" and profile.units[payload.unit]
		if not u or u.st ~= "working" then
			return result(false, "Ese PET no esta trabajando.")
		end
		local now = os.time()
		for sid, st in pairs(profile.stations) do
			if table.find(st.workers, u.id) then
				Production.Accrue(profile, sid, now)
			end
		end
		PetStore.Release(profile, u)
		S.Plots.Refresh(player)
		return result(true, "PET de vuelta al inventario.")
	end)

	Net.Register("collect", function(player, profile, payload)
		local sid = payload.station
		local st = type(sid) == "string" and profile.stations[sid]
		if not st then
			return result(false, "Estacion invalida.")
		end
		Production.Accrue(profile, sid, os.time())
		local parts = {}
		for k, v in pairs(st.buffer) do
			local n = math.floor(v)
			if n > 0 then
				PetStore.AddToStorage(profile, k, n)
				st.buffer[k] = v - n
				table.insert(parts, "+" .. n .. " " .. Items.ResName(k))
			end
		end
		if #parts == 0 then
			return result(false, "Aun no hay nada que recoger.")
		end
		return result(true, "Recogido al almacen: " .. table.concat(parts, ", "))
	end)

	Net.Register("plant", function(player, profile, payload)
		local level = profile.buildings.garden
		local i = tonumber(payload.plot)
		local crop = payload.crop
		if level < 1 then
			return result(false, "Construye el Huerto primero.")
		end
		if not i or i < 1 or i > Items.GardenPlots[level] or i % 1 ~= 0 then
			return result(false, "Parcela invalida.")
		end
		if type(crop) ~= "string" or not Items.Crops[crop] then
			return result(false, "Cultivo invalido.")
		end
		local plot = profile.garden.plots[i]
		if plot.crop then
			return result(false, "Esa parcela ya tiene un cultivo.")
		end
		if not PetStore.SpendCost(profile, { semilla = 1 }) then
			return result(false, "Necesitas 1 semilla (se consiguen talando arboles y cosechando).")
		end
		plot.crop = crop
		plot.progress = 0
		S.Plots.Refresh(player)
		return result(true, "Sembraste " .. Items.Crops[crop].name .. ".")
	end)

	Net.Register("harvest", function(player, profile, payload)
		local i = tonumber(payload.plot)
		local plot = i and profile.garden.plots[i]
		if not plot or not plot.crop then
			return result(false, "No hay cultivo ahi.")
		end
		if (plot.progress or 0) < 1 then
			return result(false, "Aun no esta listo.")
		end
		local def = Items.Crops[plot.crop]
		local rng = Random.new()
		local n = rng:NextInteger(def.yield[1], def.yield[2])
		local seeds = rng:NextInteger(def.seeds[1], def.seeds[2])
		PetStore.AddToStorage(profile, plot.crop, n)
		PetStore.AddToStorage(profile, "semilla", seeds)
		local name = def.name
		plot.crop = nil
		plot.progress = 0
		S.Plots.Refresh(player)
		return result(true, string.format("Cosechaste +%d %s y +%d semillas.", n, name, seeds))
	end)
end

function Production.Start()
	task.spawn(function()
		local last = os.time()
		while true do
			task.wait(Config.ProductionTick)
			local now = os.time()
			local dt = now - last
			last = now
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = S.Data.Get(player)
				if profile then
					local active = false
					for id, st in pairs(profile.stations) do
						if st.level >= 1 and #st.workers > 0 then
							active = true
						end
						Production.Accrue(profile, id, now)
					end
					if profile.buildings.garden >= 1 then
						local readyBefore = 0
						for _, plot in ipairs(profile.garden.plots) do
							if plot.crop and (plot.progress or 0) >= 1 then
								readyBefore = readyBefore + 1
							end
							if plot.crop then
								active = true
							end
						end
						local h = growGarden(profile, dt, now, false)
						local readyAfter = 0
						for _, plot in ipairs(profile.garden.plots) do
							if plot.crop and (plot.progress or 0) >= 1 then
								readyAfter = readyAfter + 1
							end
						end
						if h > 0 or readyAfter ~= readyBefore then
							S.Plots.Refresh(player)
						end
					end
					if active then
						S.Net.MarkDirty(player)
					end
				end
			end
		end
	end)
end

return Production
