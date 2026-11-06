-- Proteccion de datos entre implementaciones (docs/COMPATIBILIDAD_ASTRA.md):
-- un perfil ajeno (otra version, p. ej. Astra v0.6 esquema 4) o futuro nunca se
-- migra ni se sobrescribe; los perfiles propios antiguos se migran sin perdidas.
-- Ejecutar: lua5.4 tools/sim/persistence.lua
dofile("tools/sim/mock.lua")
local function check(c, msg) if not c then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
local warnings = {}
warn = function(...) local t = {} for i, v in ipairs({ ... }) do t[i] = tostring(v) end table.insert(warnings, table.concat(t, " ")) print("WARN", ...) end
RUN_SCRIPT(SERVER_SCRIPT)
local RS = game:GetService("ReplicatedStorage")
local Schema = require(RS.Shared.ProfileSchema)
local Config = require(RS.Shared.Config)
local S = {}
for _, m in ipairs(SERVER_SCRIPT.Services:GetChildren()) do S[m.Name] = require(m) end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
local function join(id, name)
	local p = MAKE_PLAYER(id, name)
	Players.PlayerAdded:Fire(p)
	RUN_DELAYS()
	return p
end
local function leave(p)
	Players.PlayerRemoving:Fire(p)
	RUN_DELAYS()
end

-- Clasificacion -------------------------------------------------------------
check(Schema.Classify(nil) == "empty", "registro vacio")
check(Schema.Classify({ data = Schema.Default() }) == "own", "perfil propio actual")
local v2 = Schema.Default(); v2.schemaVersion = 2; v2.lineage = nil
check(Schema.Classify({ data = v2 }) == "own", "perfil propio v2 sin linaje (anterior a la Fase D)")
check(Schema.Classify({ profile = {} }) == "foreign", "sin envoltorio data: ajeno")
check(Schema.Classify("texto") == "foreign", "valor no tabla: ajeno")
check(Schema.Classify({ data = { schemaVersion = 4 } }) == "foreign", "esquema 4 (Astra v0.6): ajeno")
check(Schema.Classify({ data = { schemaVersion = 2, lineage = "astra" } }) == "foreign", "linaje ajeno")
check(Schema.Classify({ data = { schemaVersion = 3 } }) == "foreign", "v3 sin linaje: ajeno")
check(Schema.Classify({ data = { schemaVersion = Config.SchemaVersion + 1, lineage = "main" } }) == "foreign", "version futura propia: no se degrada")

-- Studio: perfiles ajenos -> perfil temporal, registro intacto -----------------------------
local astra = { data = { schemaVersion = 4, petInstances = { { id = "a1", speciesId = "lumi", rarityId = "mythic", isShiny = true, level = 5 } },
	essenceBySpecies = { lumi = 900 } }, lock = nil }
DATABASE["u_301"] = astra
local before = snapshot(DATABASE["u_301"])
local A = join(301, "AstraVeterano")
check(S.DataService.Get(A) ~= nil and not S.DataService.IsPersistent(A), "Studio: juega con perfil temporal sin guardar")
check(snapshot(DATABASE["u_301"]) == before, "registro de Astra intacto al entrar")
S.DataService.SaveNow(A)
leave(A)
check(snapshot(DATABASE["u_301"]) == before, "registro de Astra intacto al guardar y salir")
local found = false
for _, w in ipairs(warnings) do if w:find("otra version") then found = true end end
check(found, "aviso en Output")

DATABASE["u_302"] = { raw = true, coins = 5 }
local before2 = snapshot(DATABASE["u_302"])
local B = join(302, "Formato")
leave(B)
check(snapshot(DATABASE["u_302"]) == before2, "formato desconocido intacto")

-- Servidor publicado: expulsion con aviso, sin escribir ---------------------------------
RunService.__props.IsStudio = function() return false end
DATABASE["u_303"] = { data = { schemaVersion = 4 } }
local before3 = snapshot(DATABASE["u_303"])
local C = join(303, "Publicado")
check(C.Kicked ~= nil and S.DataService.Get(C) == nil, "publicado: expulsa con aviso")
check(snapshot(DATABASE["u_303"]) == before3, "publicado: registro ajeno intacto")
RunService.__props.IsStudio = function() return true end

-- Perfil propio v2 -> v3 sin perdidas -------------------------------------------------
local own = Schema.Default()
own.schemaVersion = 2
own.lineage = nil
own.mines = nil
own.zones.unlocked = 4
own.tools.pick = 3
own.story.visitedMines = true
own.res.storage.piedra = 321
own.stacks.storage["talpa:rare"] = 3
own.essence.talpa = 77
DATABASE["u_304"] = { data = own }
local D = join(304, "Propio")
local pd = S.DataService.Get(D)
check(S.DataService.IsPersistent(D) and pd.schemaVersion == 3 and pd.lineage == "main", "propio v2 migrado a v3 con linaje")
check(pd.zones.unlocked == 4 and pd.tools.pick == 3 and pd.res.storage.piedra == 321 and pd.stacks.storage["talpa:rare"] == 3
	and pd.essence.talpa == 77 and pd.story.visitedMines == true and type(pd.mines.visited) == "table", "migracion v3 sin perdida de datos")
-- otra implementacion escribe encima mientras jugamos: no la pisamos
DATABASE["u_304"] = { data = { schemaVersion = 4, lineage = "astra" } }
local before4 = snapshot(DATABASE["u_304"])
S.DataService.SaveNow(D)
check(snapshot(DATABASE["u_304"]) == before4, "al guardar no se sobrescribe un registro ajeno aparecido despues")
leave(D)
check(snapshot(DATABASE["u_304"]) == before4, "ni al salir")

-- Perfil propio normal se sigue guardando
local E = join(305, "Nuevo")
local pe = S.DataService.Get(E)
pe.res.storage.madera = 12
leave(E)
check(DATABASE["u_305"] and DATABASE["u_305"].data.res.storage.madera == 12 and DATABASE["u_305"].data.lineage == "main"
	and DATABASE["u_305"].lock == nil, "perfil propio nuevo guardado con linaje y bloqueo liberado")
print("ALL PERSISTENCE TESTS PASSED")
