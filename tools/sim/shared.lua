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
check(Prog.CanUnlock(p,2), "zona 2: pico de piedra + santuario 2")
p.stations.stone.level=1; p.tools.pick=3
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
print("ALL SHARED TESTS PASSED")
