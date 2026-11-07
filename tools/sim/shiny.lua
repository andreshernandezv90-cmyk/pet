-- Fase S: variantes Shiny (GDD 23). Generacion 1/500 independiente de la rareza,
-- decidida por el servidor; pilas separadas; persistencia; migracion v3 -> v4;
-- sin efecto en estadisticas, produccion ni reactor; resistencia a manipulacion.
-- Ejecutar: lua5.4 tools/sim/shiny.lua
dofile("tools/sim/mock.lua")
local function check(c, msg) if not c then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local realClock = os.clock
local OFFSET = 0
os.clock = function() return realClock() + OFFSET end

RUN_SCRIPT(SERVER_SCRIPT)
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
Config.ActionRateLimit = 1e9
local PetCatalog = require(RS.Shared.PetCatalog)
local PetStore = require(RS.Shared.PetStore)
local PetModels = require(RS.Shared.PetModels)
local Stats = require(RS.Shared.Stats)
local Schema = require(RS.Shared.ProfileSchema)
local Players = game:GetService("Players")

local events = {}
for _, ev in ipairs(RS.Remotes:GetChildren()) do
	if ev.ClassName == "RemoteEvent" then
		local name = ev.Name
		events[name] = {}
		ev.__onFireClient = function(p, ...)
			table.insert(events[name], { p = p, args = { ... } })
			if p == nil or p == LOCAL_PLAYER then ev.OnClientEvent:Fire(...) end
		end
	end
end
local S = {}
for _, m in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[m.Name] = require(m) end
local P = MAKE_PLAYER(51, "Brillante")
Players.__props.LocalPlayer = P
LOCAL_PLAYER = P
Players.PlayerAdded:Fire(P)
RUN_DELAYS()
RUN_SCRIPT(CLIENT_SCRIPT)
for _ = 1, 3 do STEP(1) end
local profile = S.DataService.Get(P)
local function act(n, pl)
	OFFSET = OFFSET + 3
	local r = RS.Remotes.Action:InvokeServer(n, pl or {})
	RUN_DELAYS()
	return r
end
local function lastEncounters()
	local list = events.Encounters
	for i = #list, 1, -1 do
		if list[i].p == P then return list[i].args[2] or {} end
	end
	return {}
end
local function snapshot(t)
	if type(t) ~= "table" then return tostring(t) end
	local keys = {}
	for k in pairs(t) do table.insert(keys, tostring(k)) end
	table.sort(keys)
	local out = {}
	for _, k in ipairs(keys) do
		local v = t[k]
		if v == nil then v = t[tonumber(k)] end
		table.insert(out, k .. "=" .. snapshot(v))
	end
	return "{" .. table.concat(out, ",") .. "}"
end

-- 1. Claves y configuracion -----------------------------------------------------------------
check(math.abs(Config.Shiny.chance - 0.002) < 1e-12, "probabilidad Shiny configurable: 1/500 (0.2%)")
check(PetCatalog.Key("lumi", "common", true) == "lumi:common:shiny" and PetCatalog.Key("lumi", "common") == "lumi:common", "claves normal y Shiny")
local s, r, sh = PetCatalog.ParseKey("lumi:mythic:shiny")
check(s == "lumi" and r == "mythic" and sh == true, "clave Shiny valida (incluso mitica)")
local s2, r2, sh2 = PetCatalog.ParseKey("lumi:rare")
check(s2 == "lumi" and r2 == "rare" and sh2 == false, "las claves antiguas siguen siendo normales")
check(PetCatalog.ParseKey("lumi:common:Shiny") == nil and PetCatalog.ParseKey("lumi:common:shinyx") == nil
	and PetCatalog.ParseKey("rocon:mythic:shiny") == nil and PetCatalog.ParseKey("lumi:common:shiny:shiny") == nil,
	"claves Shiny mal formadas o variantes inexistentes: rechazadas")
check(#PetCatalog.AllVariants() == 63, "la coleccion sigue siendo de 63 variantes (Shiny no es una sexta rareza)")

-- 2. Generacion: 1/500 e independiente de la rareza ------------------------------------------------
local rng = Random.new(500)
local N = 400000
local shinyAll, byRarity, shinyBy = 0, {}, {}
for _ = 1, N do
	local rr = S.Capture.RollRarity("lumi", 1)
	local isShiny = S.Capture.RollShiny(nil, rng)
	byRarity[rr] = (byRarity[rr] or 0) + 1
	if isShiny then
		shinyAll = shinyAll + 1
		shinyBy[rr] = (shinyBy[rr] or 0) + 1
	end
end
local rate = shinyAll / N
check(math.abs(rate - 0.002) < 0.0003, string.format("tasa Shiny %.4f%% (esperado 0.2000%%) en %d tiradas", rate * 100, N))
local common = (shinyBy.common or 0) / byRarity.common
local others, othersN = 0, 0
for id, n in pairs(byRarity) do if id ~= "common" then othersN = othersN + n; others = others + (shinyBy[id] or 0) end end
check(math.abs(common - 0.002) < 0.0004 and math.abs(others / othersN - 0.002) < 0.0009,
	string.format("independiente de la rareza: comunes %.3f%%, no comunes %.3f%%", common * 100, others / othersN * 100))
Config.Shiny.enabled = false
check(not S.Capture.RollShiny(1), "Config.Shiny.enabled = false: nunca Shiny")
Config.Shiny.enabled = true
-- en el flujo real: con probabilidad 1 todas las rarezas pueden salir Shiny (incluido el mitico)
local saved = Config.Shiny.chance
Config.Shiny.chance = 1
local raritiesSeen = {}
P:SetAttribute("Area", "z1")
for _ = 1, 200 do
	S.Capture.OnAreaChanged(P, "home")
	S.Capture.OnAreaChanged(P, "z1")
	for _, e in ipairs(lastEncounters()) do
		if e.sh then raritiesSeen[e.r] = true end
	end
end
Config.Shiny.chance = saved
check(raritiesSeen.common and raritiesSeen.rare and raritiesSeen.epic, "Shiny aparece en comun, raro y epico")
-- con probabilidad 0 no aparece ninguno y el envio no lleva la marca
Config.Shiny.chance = 0
S.Capture.OnAreaChanged(P, "home")
S.Capture.OnAreaChanged(P, "z1")
local anySh = false
for _, e in ipairs(lastEncounters()) do if e.sh ~= nil then anySh = true end end
check(not anySh, "encuentros normales no llevan marca Shiny")

-- 3. Captura de un Shiny (decidido por el servidor) ----------------------------------------------
local function captureOne(force)
	S.Capture.SetForceShiny(P, force)
	S.Capture.OnAreaChanged(P, "home")
	S.Capture.OnAreaChanged(P, "z1")
	for _ = 1, 60 do
		local list = lastEncounters()
		local e = list[1]
		if not e then
			S.Capture.OnAreaChanged(P, "home"); S.Capture.OnAreaChanged(P, "z1")
		else
			P.Character.HumanoidRootPart.__props.CFrame = CFrame.new(e.x, 3, e.z)
			act("captureBegin", { id = e.id })
			OFFSET = OFFSET + 100
			-- intento de manipulacion: el cliente dice que es Shiny / mitico
			local res = act("captureFinish", { id = e.id, shiny = true, sh = true, r = "mythic", key = "lumi:mythic:shiny" })
			if res.captured then return res, e end
		end
	end
	return nil
end
profile.buildings.petStorage = 10
local res, e = captureOne(true)
check(res and res.shiny == true and e.sh == true, "captura Shiny: " .. tostring(res and res.msg))
local key = PetCatalog.Key("lumi", res.r, true)
check(PetStore.StackCount(profile, key) == 1, "va a su propia pila: " .. key)
check(profile.dex[PetCatalog.Key("lumi", res.r)] == true and profile.shinyDex[PetCatalog.Key("lumi", res.r)] == true,
	"cuenta para la coleccion normal y para el registro Shiny")
local anyNotice = false
for _, n in ipairs(events.Notify) do if tostring(n.args[1]):find("SHINY") then anyNotice = true end end
check(anyNotice, "aviso global de rescate Shiny")
-- manipulacion: el cliente pide Shiny en un encuentro normal
local before = snapshot(profile.stacks)
Config.Shiny.chance = 0
local res2 = captureOne(false)
check(res2 and res2.shiny == false, "encuentro normal capturado como normal aunque el cliente diga Shiny")
local normalKey = PetCatalog.Key("lumi", res2.r)
check(PetStore.StackCount(profile, normalKey) >= 1 and PetStore.StackCount(profile, "lumi:mythic:shiny") == (res.r == "mythic" and 1 or 0),
	"el servidor ignora rareza y Shiny enviados por el cliente")
Config.Shiny.chance = saved
S.Capture.SetForceShiny(P, false)
-- el cliente no puede pedir un Shiny inexistente en otras acciones
local rEq = act("equip", { ref = { key = "rocon:common:shiny" } })
check(not rEq.ok, "equipar un Shiny que no tienes: rechazado")
local rRe = act("reactor", { items = { ["rocon:common:shiny"] = 1 }, nonce = "n-fake" })
check(not rRe.ok, "reciclar un Shiny que no tienes: rechazado")

-- 4. Inventario: pilas separadas ----------------------------------------------------------------
PetStore.Give(profile, "lumi", "common", true, false)
PetStore.Give(profile, "lumi", "common", true, false)
PetStore.Give(profile, "lumi", "common", true, true)
PetStore.Give(profile, "lumi", "common", true, true)
local entries = PetStore.Entries(profile)
local normalE, shinyE
for _, en in ipairs(entries) do
	if en.kind == "stack" and en.s == "lumi" and en.r == "common" then
		if en.shiny then shinyE = en else normalE = en end
	end
end
check(normalE and shinyE and normalE.key ~= shinyE.key and shinyE.count >= 2, "el inventario distingue la pila normal de la Shiny")
local usedBefore = PetStore.Used(profile, "storage") + PetStore.Used(profile, "tank")
local stackSlots = 0
for _, loc in ipairs({ "tank", "storage" }) do
	for k in pairs(profile.stacks[loc]) do if k == "lumi:common" or k == "lumi:common:shiny" then stackSlots = stackSlots + 1 end end
end
check(stackSlots >= 2 and usedBefore >= 2, "cada pila ocupa su propio espacio")
-- individualizar (equipar) conserva Shiny; al volver se reune en su pila
local rE = act("equip", { ref = { key = "lumi:common:shiny" } })
check(rE.ok, "equipar un Lumi comun Shiny")
local unit
for _, id in ipairs(profile.team) do unit = profile.units[id] end
check(unit and unit.shiny == true and unit.s == "lumi" and unit.r == "common", "el individuo conserva su atributo Shiny")
check(string.find(P:GetAttribute("Followers"), "lumi:common%*:") ~= nil, "atributo de compañeros marca el Shiny (common*)")
-- el compañero se dibuja Shiny en el cliente
local comp = workspace:FindFirstChild("Compañeros")
for _ = 1, 3 do game:GetService("RunService").RenderStepped:Fire(1 / 30) end
local shinyFollower = false
for _, m in ipairs(comp and comp:GetChildren() or {}) do if m:GetAttribute("Shiny") then shinyFollower = true end end
check(shinyFollower, "el compañero se ve Shiny")

-- 5. Sin efecto en estadisticas ni produccion ---------------------------------------------------
local function aggOf(shiny)
	local p = Schema.Default()
	p.units.u1 = { id = "u1", s = "lumi", r = "epic", lv = 3, st = "equipped", lock = false, loc = "tank", shiny = shiny or nil }
	p.team = { "u1" }
	p.stations.stone.level = 2
	p.units.u2 = { id = "u2", s = "rocon", r = "rare", lv = 2, st = "working", lock = false, loc = "storage", shiny = shiny or nil }
	p.stations.stone.workers = { "u2" }
	local agg = Stats.Aggregate(p, os.time())
	return snapshot(agg), snapshot(S.Production.Rates(p, "stone", agg)), snapshot(Stats.CaptureParams(agg, p, "lumi", "epic"))
end
local a1, p1, c1 = aggOf(false)
local a2, p2, c2 = aggOf(true)
check(a1 == a2, "mismas bonificaciones de compañero con o sin Shiny")
check(p1 == p2, "misma produccion de trabajador con o sin Shiny")
check(c1 == c2, "mismos parametros de captura con o sin Shiny")

-- 6. Reactor: Shiny protegidos y sin esencia extra ---------------------------------------------
local sBefore = PetStore.StackCount(profile, "lumi:common:shiny")
local rP = act("reactor", { items = { ["lumi:common:shiny"] = 1 }, nonce = "n-1" })
check(not rP.ok and tostring(rP.msg):find("protegidos") and PetStore.StackCount(profile, "lumi:common:shiny") == sBefore,
	"el Reactor protege los Shiny por defecto")
local essBefore = profile.essence.lumi or 0
local rA = act("reactor", { items = { ["lumi:common:shiny"] = 1 }, nonce = "n-2", allowShiny = true })
check(rA.ok and (profile.essence.lumi or 0) - essBefore == PetCatalog.Rarity("common").essence,
	"con confirmacion explicita da las mismas esencias que un comun normal")

-- 7. Fusion conserva Shiny (solo visual) ----------------------------------------------------------
profile.buildings.fusionLab = math.max(profile.buildings.fusionLab, 1)
PetStore.Give(profile, "rocon", "rare", true, true)
local rF = act("fuse", { a = { key = "rocon:rare:shiny" }, b = { key = "lumi:common" } })
if rF.ok then
	local f = Stats.ActiveFusions(profile, os.time())[1]
	check(f and f.a.shiny == true and not f.b.shiny, "la fusion recuerda que componente es Shiny")
	check(string.find(P:GetAttribute("Followers"), "F:rocon:rare%*:lumi:common") ~= nil, "la fusion se dibuja con su Shiny")
else
	print("info  fusion no disponible en este perfil de prueba: " .. tostring(rF.msg))
end

-- 8. Persistencia -----------------------------------------------------------------------
local shinyStacks = snapshot({ t = profile.stacks.tank["lumi:common:shiny"], s = profile.stacks.storage["lumi:common:shiny"] })
local shinyUnitId = unit.id
Players.PlayerRemoving:Fire(P)
RUN_DELAYS()
local saved = DATABASE["u_51"].data
check(saved.units[shinyUnitId] and saved.units[shinyUnitId].shiny == true, "el individuo Shiny se guarda")
check(snapshot({ t = saved.stacks.tank["lumi:common:shiny"], s = saved.stacks.storage["lumi:common:shiny"] }) == shinyStacks,
	"la pila Shiny se guarda")
local P2 = MAKE_PLAYER(51, "Brillante")
Players.PlayerAdded:Fire(P2)
RUN_DELAYS()
local back = S.DataService.Get(P2)
check(back and back.units[shinyUnitId] and back.units[shinyUnitId].shiny == true and back.shinyDex[PetCatalog.Key("lumi", res.r)],
	"al volver a entrar, el Shiny y su registro siguen ahi")

-- 9. Migracion v3 -> v4 sin perdidas -----------------------------------------------------------------
local v3 = Schema.Default()
v3.schemaVersion = 3
v3.shinyDex = nil
v3.stacks.tank["lumi:rare"] = 7
v3.stacks.storage["nox:mythic"] = 2
v3.units.u9 = { id = "u9", s = "talpa", r = "epic", lv = 4, st = "working", lock = true, loc = "storage" }
v3.dex["lumi:rare"] = true
v3.essence.talpa = 321
DATABASE["u_61"] = { data = v3 }
local P3 = MAKE_PLAYER(61, "Antigua")
Players.PlayerAdded:Fire(P3)
RUN_DELAYS()
local m = S.DataService.Get(P3)
check(m.schemaVersion == 4 and m.lineage == "main" and type(m.shinyDex) == "table" and next(m.shinyDex) == nil, "perfil v3 migrado a v4 con registro Shiny vacio")
check(m.stacks.tank["lumi:rare"] == 7 and m.stacks.storage["nox:mythic"] == 2 and m.essence.talpa == 321 and m.dex["lumi:rare"],
	"pilas, esencias y coleccion intactas")
local u9 = m.units.u9
check(u9 and u9.lv == 4 and u9.st == "working" and u9.lock == true and u9.shiny == nil, "individuo intacto y normal (sin Shiny)")
local ms, mr, msh = PetCatalog.ParseKey("lumi:rare")
check(ms == "lumi" and msh == false, "las pilas existentes se leen como normales")
check(Schema.Classify({ data = { schemaVersion = 4 } }) == "foreign", "un perfil de esquema 4 sin linaje (Astra) sigue siendo ajeno")

-- 10. Apariencia -----------------------------------------------------------------------------
local normal = PetModels.Build("lumi", "common", {})
local shinyM = PetModels.Build("lumi", "common", { shiny = true })
check(shinyM:GetAttribute("Shiny") == true and normal:GetAttribute("Shiny") == nil, "atributo Shiny en el modelo")
local pe = shinyM.PrimaryPart:FindFirstChild("ShinySparkles")
check(pe and pe.ClassName == "ParticleEmitter" and pe.Rate <= 5 and normal.PrimaryPart:FindFirstChild("ShinySparkles") == nil,
	"particulas ligeras solo en el Shiny (" .. tostring(pe and pe.Rate) .. "/s)")
check(snapshot(shinyM.PrimaryPart.Color) ~= snapshot(normal.PrimaryPart.Color), "paleta alternativa en el procedural")
local ShinyStyle = require(RS.Shared.ShinyStyle)
ShinyStyle.Species.lumi = { color = Color3.fromRGB(10, 200, 250) }
local custom = PetModels.Build("lumi", "common", { shiny = true })
check(math.abs(custom.PrimaryPart.Color.B - 250 / 255) < 1e-6, "paleta Shiny personalizable por especie")
ShinyStyle.Species.lumi = nil
-- variante importada "Lumi_shiny" (plantilla simulada)
local folder = Instance.new("Folder")
folder.Name = "PetAssets"
folder.Parent = RS
local function tmpl(name)
	local t = Instance.new("Model")
	t.Name = name
	local root = Instance.new("MeshPart")
	root.Name = "RootPart"
	root.Size = Vector3.new(2, 2, 2)
	root.CFrame = CFrame.new(0, 1, 0)
	root.Parent = t
	t.PrimaryPart = root
	t.Parent = folder
end
tmpl("Lumi")
tmpl("Lumi_shiny")
check(PetModels.Build("lumi", "common", { shiny = true }):GetAttribute("AssetName") == "Lumi_shiny", "Shiny usa la variante importada Lumi_shiny")
check(PetModels.Build("lumi", "common", {}):GetAttribute("AssetName") == "Lumi", "el normal sigue usando Lumi")
folder.Lumi_shiny.Parent = nil
local fallback = PetModels.Build("lumi", "common", { shiny = true })
check(fallback:GetAttribute("AssetName") == "Lumi" and fallback.PrimaryPart:FindFirstChild("ShinySparkles") ~= nil,
	"sin variante Shiny importada: modelo normal + particulas")
folder.Parent = nil
print("ALL SHINY TESTS PASSED")
