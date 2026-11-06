-- MineVeins: reparto privado de vetas de una galeria de las Minas de Zuar.
-- Logica pura (sin instancias) para poder probarla y reutilizarla:
--   1) se tira el dado de cada mineral por separado con mine.chances
--      (no son excluyentes; la piedra siempre aparece);
--   2) cada mineral presente recibe al menos una veta;
--   3) el resto de vetas se reparte con WorldConfig.Mines.veinWeights.
-- El resultado es por jugador y por ciclo; lo decide siempre el servidor.

local WorldConfig = require(script.Parent.WorldConfig)

local MineVeins = {}

-- Minerales presentes en este ciclo (lista ordenada de recursos)
function MineVeins.RollPresent(region, rng)
	local present = {}
	for _, res in ipairs(WorldConfig.Mines.order) do
		local c = region.mine.chances[res] or 0
		if c > 0 and (c >= 1 or rng:NextNumber() < c) then
			table.insert(present, res)
		end
	end
	if #present == 0 then
		table.insert(present, "piedra")
	end
	return present
end

-- socketIds: lista de ids de veta de la galeria. Devuelve { [id] = nodeType }, presentes
function MineVeins.Roll(region, socketIds, rng)
	local present = MineVeins.RollPresent(region, rng)
	local weights = WorldConfig.Mines.veinWeights
	local nodeType = WorldConfig.Mines.nodeType
	local order = {}
	for i, id in ipairs(socketIds) do
		order[i] = id
	end
	for i = #order, 2, -1 do -- barajar (Fisher-Yates)
		local j = rng:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	local types = {}
	local idx = 1
	-- garantia: una veta por mineral presente (de mas raro a mas comun)
	for i = #present, 1, -1 do
		if idx <= #order then
			types[order[idx]] = nodeType[present[i]]
			idx = idx + 1
		end
	end
	local total = 0
	for _, res in ipairs(present) do
		total = total + (weights[res] or 1)
	end
	while idx <= #order do
		local roll = rng:NextNumber() * total
		local pick = present[1]
		for _, res in ipairs(present) do
			roll = roll - (weights[res] or 1)
			if roll <= 0 then
				pick = res
				break
			end
		end
		types[order[idx]] = nodeType[pick]
		idx = idx + 1
	end
	return types, present
end

-- Recurso de un tipo de nodo (para textos)
function MineVeins.ResourceOf(nodeType)
	for res, t in pairs(WorldConfig.Mines.nodeType) do
		if t == nodeType then
			return res
		end
	end
	return nil
end

return MineVeins
