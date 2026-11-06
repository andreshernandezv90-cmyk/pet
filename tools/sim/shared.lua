local ROOT = (os.getenv("PP_SRC") or "src/") .. "shared/"
Color3 = { fromRGB = function(r,g,b) return {R=r/255,G=g/255,B=b/255, Lerp=function(self) return self end} end,
  new = function(r,g,b) return {R=r,G=g,B=b} end }
function math.clamp(x,a,b) if x<a then return a elseif x>b then return b end return x end
function table.find(t,v) for i,x in ipairs(t) do if x==v then return i end end return nil end
local cache = {}
local Shared = setmetatable({}, {__index=function(_,k) return {__mod=k} end})
local realRequire = require
function require(proxy)
  if type(proxy)=="table" and proxy.__mod then
    local name = proxy.__mod
    if cache[name] then return cache[name] end
    local env = setmetatable({script={Parent=Shared}}, {__index=_G})
    local chunk = assert(loadfile(ROOT..name..".luau","t",env))
    cache[name] = chunk()
    return cache[name]
  end
  return realRequire(proxy)
end
local function check(c, msg) if not c then error("FAIL: "..msg, 2) end print("ok  "..msg) end

local PC = require(Shared.PetCatalog)
local Items = require(Shared.Items)
local Schema = require(Shared.ProfileSchema)
local Store = require(Shared.PetStore)
local Prog = require(Shared.Progression)
local Stats = require(Shared.Stats)
local Recipes = require(Shared.Recipes)

check(#PC.AllVariants()==63, "63 variantes (15x4 + 3 miticos)")
local sum=0 for _,c in ipairs(PC.LevelCosts) do sum=sum+c end
check(sum==6750, "costo total niveles 6750")
local zc={} for _,s in ipairs(PC.Species) do zc[s.zone]=(zc[s.zone] or 0)+1 end
check(zc[1]==1 and zc[2]==2 and zc[3]==3 and zc[4]==4 and zc[5]==5, "especies por zona 1+2+3+4+5")
check(PC.FusionName("lumi","talpa")=="Lumital", "nombre de fusion Lumital")
check(PC.ParseKey("rocon:mythic")==nil and PC.ParseKey("lumi:mythic")=="lumi", "solo Lumi/Nox/Eclipsar tienen mitico")
-- Reactor ejemplo B: 5 Lumi comunes + 1 raro = 13
check(5*PC.Rarity("common").essence + 1*PC.Rarity("rare").essence == 13, "reactor 5 comunes + 1 raro = 13")
-- Lumi mitico nivel 0 => x2.0 mineria; nivel 5 => x4.0
local b0 = Stats.PetBonus("lumi","mythic",0).mineSpeed
local b5 = Stats.PetBonus("lumi","mythic",5).mineSpeed
check(math.abs(b0-1.0)<1e-9 and math.abs(b5-3.0)<1e-9, "Lumi mitico x2.00 (nv0) y x4.00 (nv5)")
check(math.abs(Stats.PetBonus("lumi","common",0).mineSpeed-0.10)<1e-9, "Lumi comun x1.10")

local p = Schema.Default()
check(Prog.TankSlots(p)==3 and Prog.BackpackSlots(p)==5, "capacidades iniciales 3/5")
check(Prog.TeamSlots(p)==1, "1 espacio de equipo al inicio")
-- pilas de 50
for i=1,150 do assert(Store.CanAdd(p,"tank","lumi:common",1)); Store.Add(p,"tank","lumi:common",1) end
check(Store.Used(p,"tank")==3, "150 Lumi comunes = 3 espacios")
check(not Store.CanAdd(p,"tank","lumi:common",1), "151 no cabe en tanque de 3")
check(not Store.CanAdd(p,"tank","lumi:rare",1), "nueva pila no cabe con tanque lleno")
check(Store.Give(p,"lumi","rare",false)=="storage", "si el tanque esta lleno va al almacen")
-- deposito
local moved = Store.DepositPets(p)
check(moved==150 and Store.Used(p,"tank")==0, "depositar tanque al santuario")
check(Store.Used(p,"storage")==4, "almacen: 3 pilas lumi comun + 1 rara")
-- individualizar / liberar
local u = Store.Individualize(p,"lumi:common")
check(u and p.stacks.storage["lumi:common"]==149, "individualizar saca 1 de la pila")
u.st="equipped"; table.insert(p.team,u.id)
check(Prog.TeamSlots(p)==1 and #p.team==1, "equipado")
Store.Release(p,u)
check(p.units[u.id]==nil and p.stacks.storage["lumi:common"]==150 and #p.team==0, "al liberar vuelve a su pila")
local u2 = Store.Resolve(p,{key="lumi:common"}); u2.lv=1; Store.Release(p,u2)
check(p.units[u2.id]~=nil, "evolucionado conserva identidad")
-- Take (reactor)
check(Store.Take(p,"lumi:common",149) and p.stacks.storage["lumi:common"]==nil, "reactor descuenta pila")
check(not Store.Take(p,"lumi:common",1), "no se puede descontar lo que no hay")
-- mochila
check(Store.BackpackRoom(p,"piedra")==500, "mochila 5x100")
check(Store.AddToBackpack(p,"piedra",130)==130 and Store.BackpackUsed(p)==2, "130 piedra = 2 espacios")
check(Store.BackpackRoom(p,"piedra")==370 and Store.BackpackRoom(p,"madera")==300, "espacio restante por recurso")
p.res.storage.madera=40
check(Store.HasCost(p,{madera=30,piedra=40}), "tiene costo combinado")
check(Store.SpendCost(p,{madera=30,piedra=40}) and p.res.storage.madera==10 and p.res.backpack.piedra==90, "gasta almacen y luego mochila")
-- recetas
for _,id in ipairs(Recipes.LineOrder) do local n=Recipes.Next(p,id); assert(n, id) end
check(Recipes.Next(p,"garden").locked, "huerto bloqueado hasta zona 3")
check(not Recipes.Next(p,"pick").locked and Recipes.Next(p,"pick").level==2, "siguiente pico nivel 2")
-- objetivos y desbloqueos
print("   objetivo:", Prog.Objective(p))
p.tools.pick=2; p.buildings.sanctuary=2
check(not Prog.CanUnlock(p,2), "zona 2 tambien pide extractor de piedra")
p.stations.stone.level=1
check(Prog.CanUnlock(p,2), "zona 2: pico de piedra + santuario 2 + extractor de piedra")
p.tools.pick=3
check(Prog.CanUnlock(p,3), "zona 3: pico cobre + extractor")
check(not Prog.CanUnlock(p,5), "zona 5 requiere mision")
-- stats y captura
local agg = Stats.Aggregate(p, 1000)
local cp = Stats.CaptureParams(agg,p,"lumi","common")
print(string.format("   captura Lumi comun: chance %.2f tiempo %.2fs", cp.chance, cp.time))
check(cp.chance>0.8 and cp.time>1, "parametros de captura razonables")
local cp2 = Stats.CaptureParams(agg,p,"eclipsar","mythic")
print(string.format("   captura Eclipsar mitico: chance %.2f tiempo %.2fs", cp2.chance, cp2.time))
p.effects.fortuna = 2000
check(Stats.Aggregate(p,1000).luck==2, "pocion fortuna x2")
-- topes
for i=1,3 do local x=Store.Give(p,"lumi","mythic",true) end
local un = Store.Resolve(p,{key="lumi:mythic"}); un.lv=5; un.st="equipped"; table.insert(p.team,un.id)
p.buildings.forge=2
local un2 = Store.Resolve(p,{key="lumi:mythic"}); un2.lv=5; un2.st="equipped"; table.insert(p.team,un2.id)
local a2 = Stats.Aggregate(p,1000)
check(a2.stats.mineSpeed<=2.0+1e-9, "tope de velocidad de mineria respetado ("..a2.stats.mineSpeed..")")

-- Configuracion de regiones (WorldConfig)
local WC = require(Shared.WorldConfig)
check(#WC.Regions == 5, "5 regiones configuradas")
for _, r in ipairs(WC.Regions) do
	check((r.mine.chances.piedra or 0) == 1, "mina de la zona " .. r.id .. " siempre tiene piedra")
	for _, sp in ipairs(PC.SpeciesInZone(r.id)) do assert(sp.zone == r.id) end
end
check(WC.Regions[5].mine.chances.zuarita == 0.25 and WC.Regions[1].mine.chances.cobre == 0.15, "tabla de minerales del diseño")

-- Migracion v1 -> v2 (segura e idempotente)
local v1 = Schema.Default()
v1.schemaVersion = 1
v1.world = nil
v1.zones.unlocked = 3
v1.zones.parkour = { z1 = true }
v1.captured = { lumi = 4, rocon = 1 }
v1.stacks.storage["lumi:rare"] = 7
v1.essence.lumi = 99
local m = Schema.Migrate(v1)
check(m.schemaVersion == 3 and m.lineage == "main" and m.world.beacons.z1 and m.world.beacons.z2 and not m.world.beacons.z3, "v1->v3: faros de zonas ya visitadas y linaje propio")
check(m.stacks.storage["lumi:rare"] == 7 and m.essence.lumi == 99 and m.zones.unlocked == 3, "v1->v2 conserva PETs, esencias y zonas")
local copy = Schema.DeepCopy(m)
m.schemaVersion = 1
Schema.Migrate(m)
local same = true
for k in pairs(copy.world.beacons) do if not m.world.beacons[k] then same = false end end
for k in pairs(m.world.beacons) do if not copy.world.beacons[k] then same = false end end
check(same and m.stacks.storage["lumi:rare"] == 7, "migracion idempotente")

-- Progresion completa sin dependencias circulares:
-- se simula un jugador que solo fabrica lo que sus materiales permiten obtener.
local function obtainable(pp, res)
	local node = WC.MineralNode[res]
	if node then
		for _, r in ipairs(WC.Regions) do
			if r.id <= pp.zones.unlocked and (r.mine.chances[res] or 0) > 0 and pp.tools.pick >= Items.Nodes[node].pick then
				return true
			end
		end
		return false
	end
	local src = WC.ResourceSources[res]
	if not src then return false end
	if (src.zone or 1) > pp.zones.unlocked then return false end
	if src.building and (pp.buildings[src.building] or 0) < 1 then return false end
	if src.station and pp.stations[src.station].level < 1 then return false end
	if src.species and (pp.captured[src.species] or 0) <= 0 then return false end
	return true
end
local function apply(pp, line, lv)
	local id = line.id
	if id == "pick" then pp.tools.pick = lv
	elseif id == "axe" then pp.tools.axe = lv
	elseif id == "vacuum" then pp.tools.vacuum = lv
	elseif id == "sanctuary" then pp.buildings.sanctuary = lv
	elseif id == "forge" then pp.buildings.forge = lv
	elseif id == "petstorage" then pp.buildings.petStorage = lv
	elseif id == "garden" then pp.buildings.garden = lv; pp.stations.garden.level = lv
	elseif id == "alchemy" then pp.buildings.alchemy = lv
	elseif id == "bait" then pp.buildings.bait = lv
	elseif id == "fusionlab" then pp.buildings.fusionLab = lv
	elseif line.station then pp.stations[line.station].level = lv
	elseif line.deco then pp.decorations[line.deco] = true end
end
local sim = Schema.Default()
local violations = {}
local order = {}
for _ = 1, 200 do
	local changed = false
	for _, sp in ipairs(PC.Species) do
		if sp.zone <= sim.zones.unlocked then sim.captured[sp.id] = 1 end
	end
	while sim.zones.unlocked < 5 and Prog.CanUnlock(sim, sim.zones.unlocked + 1) do
		sim.zones.unlocked = sim.zones.unlocked + 1
		table.insert(order, "Zona " .. sim.zones.unlocked)
		changed = true
	end
	for _, id in ipairs(Recipes.LineOrder) do
		local n = Recipes.Next(sim, id)
		if n and not n.maxed and not n.locked then
			local ok = true
			for res in pairs(n.cost) do
				if not obtainable(sim, res) then
					ok = false
					violations[id .. " nv" .. n.level .. " (" .. res .. ")"] = true
				end
			end
			if ok then
				apply(sim, n.line, n.level)
				table.insert(order, n.name)
				changed = true
			end
		end
	end
	if not changed then break end
end
local vlist = {}
for k in pairs(violations) do table.insert(vlist, k) end
table.sort(vlist)
if #vlist > 0 then print("   recetas disponibles con materiales aun no recolectables: " .. table.concat(vlist, ", ")) end
check(#vlist == 0, "ninguna receta disponible pide materiales que aun no se pueden recolectar")
check(sim.zones.unlocked == 5, "la progresion llega a la Zona 5")
local unfinished = {}
for _, id in ipairs(Recipes.LineOrder) do
	if not Recipes.Next(sim, id).maxed then table.insert(unfinished, id) end
end
check(#unfinished == 0, "todas las mejoras son alcanzables (" .. table.concat(unfinished, ",") .. ")")
local zonesOrder = {}
for i, o in ipairs(order) do if o:match("^Zona") then table.insert(zonesOrder, o .. " (paso " .. i .. ")") end end
print("   orden: " .. table.concat(zonesOrder, ", "))

-- Taller: requisitos explicitos
local fresh = Schema.Default()
local vac3 = Recipes.Requirements(fresh, "vacuum", 3)
local texts = {}
for _, r in ipairs(vac3) do table.insert(texts, r.text .. (r.ok and " ✓" or " ✗")) end
print("   succionador 3 requiere: " .. table.concat(texts, " · "))
check(Recipes.Next(fresh, "vacuum").locked == false, "succionador 2 disponible desde el inicio (petalos de la zona 1)")
local hasZone2 = false
for _, r in ipairs(vac3) do if r.text == "Desbloquear la Zona 2" then hasZone2 = true end end
check(hasZone2, "succionador 3 explica que necesita la Zona 2")
local pk = Recipes.Next(fresh, "pick")
check(pk.locked == false and #pk.requirements == 1 and pk.requirements[1].ok, "pico de piedra: solo requiere tener el pico de madera")
print("ALL SHARED TESTS PASSED")
