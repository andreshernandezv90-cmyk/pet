-- Simulador minimo y permisivo de la API de Roblox para pruebas de humo.
warn = function(...) print("WARN", ...) end
local SRC = os.getenv("PP_SRC") or "src/"

function math.clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end
function table.find(t, v) for i, x in ipairs(t) do if x == v then return i end end return nil end
function table.clear(t) for k in pairs(t) do t[k] = nil end end
function string.split(s, sep)
	local out = {}
	for part in string.gmatch(s, "([^" .. sep .. "]+)") do table.insert(out, part) end
	return out
end
math.huge = math.huge

-- Vector3 ---------------------------------------------------------------
local V3 = {}
V3.__index = function(v, k)
	if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
	if k == "Unit" then local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z); if m == 0 then return v end; return Vector3.new(v.X / m, v.Y / m, v.Z / m) end
	if k == "Lerp" then return function(a, b, t) return a + (b - a) * t end end
	return nil
end
V3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then a, b = b, a end
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b) return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
V3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
Vector3 = { new = function(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3) end }
Vector3.zero = Vector3.new(0, 0, 0)

-- CFrame (solo posicion; la rotacion se ignora) ---------------------------
local CF = {}
CF.__index = function(c, k)
	if k == "Position" then return c.p end
	if k == "LookVector" then return Vector3.new(0, 0, -1) end
	if k == "X" then return c.p.X end
	if k == "Y" then return c.p.Y end
	if k == "Z" then return c.p.Z end
	if k == "Inverse" then return function(self) return CFrame.new(-self.p.X, -self.p.Y, -self.p.Z) end end
	if k == "Lerp" then return function(a, b, t) return CFrame.new(a.p + (b.p - a.p) * t) end end
	return nil
end
CF.__mul = function(a, b)
	if getmetatable(b) == V3 then return a.p + b end
	return CFrame.new(a.p + b.p)
end
CF.__add = function(a, b) return CFrame.new(a.p + b) end
CF.__sub = function(a, b)
	if getmetatable(b) == V3 then return CFrame.new(a.p - b) end
	return CFrame.new(a.p - b.p)
end
CF.__eq = function(a, b) return a.p == b.p end
CFrame = {
	new = function(x, y, z)
		if type(x) == "table" then return setmetatable({ p = x }, CF) end
		return setmetatable({ p = Vector3.new(x or 0, y or 0, z or 0) }, CF)
	end,
	Angles = function() return setmetatable({ p = Vector3.new() }, CF) end,
	lookAt = function(p) return setmetatable({ p = p }, CF) end,
}

-- Opacos --------------------------------------------------------------------
local C3 = {}
C3.__index = { Lerp = function(a) return a end }
Color3 = {
	fromRGB = function(r, g, b) return setmetatable({ R = r / 255, G = g / 255, B = b / 255 }, C3) end,
	new = function(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3) end,
}
local function opaque(name) return { new = function(...) return { __type = name, ... } end } end
UDim2 = opaque("UDim2"); UDim = opaque("UDim"); Vector2 = opaque("Vector2"); TweenInfo = opaque("TweenInfo")
NumberSequence = opaque("NumberSequence"); ColorSequence = opaque("ColorSequence")
Enum = setmetatable({}, { __index = function(_, a) return setmetatable({}, { __index = function(_, b) return a .. "." .. b end }) end })

Random = { new = function(seed)
	local r = {}
	function r:NextNumber(a, b) a = a or 0; b = b or 1; return a + math.random() * (b - a) end
	function r:NextInteger(a, b) return math.random(a, b) end
	return r
end }
math.randomseed(1)

-- Señales -------------------------------------------------------------------
local function Signal()
	local s = { handlers = {} }
	function s:Connect(fn) table.insert(self.handlers, fn); return { Disconnect = function() end } end
	function s:Fire(...) for _, h in ipairs(self.handlers) do h(...) end end
	function s:Wait() return nil end
	s.Event = s
	return s
end

-- Tareas: spawn corre hasta el primer wait -----------------------------------
local pendingDelays = {}
SCHED = {}
TIME_OFFSET = 0
local realTime = os.time
os.time = function(t) if t then return realTime(t) end return realTime() + TIME_OFFSET end
task = {
	spawn = function(fn, ...)
		local co = coroutine.create(fn)
		local ok, err = coroutine.resume(co, ...)
		if not ok then error(debug.traceback(co, err), 0) end
		if coroutine.status(co) == "suspended" then table.insert(SCHED, co) end
	end,
	defer = function(fn, ...) local args = { ... }; table.insert(pendingDelays, function() fn(table.unpack(args)) end) end,
	delay = function(t, fn, ...) local args = { ... }; table.insert(pendingDelays, function() fn(table.unpack(args)) end) end,
	wait = function()
		if coroutine.isyieldable() then coroutine.yield() end
		return 0
	end,
}
function STEP(seconds)
	TIME_OFFSET = TIME_OFFSET + (seconds or 1)
	local list = SCHED
	SCHED = {}
	for _, co in ipairs(list) do
		local ok, err = coroutine.resume(co)
		if not ok then error(debug.traceback(co, err), 0) end
		if coroutine.status(co) == "suspended" then table.insert(SCHED, co) end
	end
	RUN_DELAYS()
end
function RUN_DELAYS()
	local list = pendingDelays
	pendingDelays = {}
	for _, f in ipairs(list) do f() end
end
wait = task.wait

-- Instancias ------------------------------------------------------------------
local EVENTS = { Touched = 1, Triggered = 1, PromptButtonHoldBegan = 1, PromptButtonHoldEnded = 1, Activated = 1, MouseButton1Down = 1,
	MouseButton1Up = 1, MouseLeave = 1, OnClientEvent = 1, OnServerEvent = 1, Event = 1, CharacterAdded = 1, Changed = 1 }
local Inst = {}
local allInstances = 0
local function newInstance(className)
	allInstances = allInstances + 1
	local o = { __props = { ClassName = className, Name = className }, __children = {}, __attrs = {}, __signals = {} }
	if className:find("Part") or className == "SpawnLocation" then
		o.__props.CFrame = CFrame.new(0, 0, 0)
		o.__props.Size = Vector3.new(4, 1, 2)
		o.__props.Transparency = 0
		o.__props.Color = Color3.new(1, 1, 1)
	end
	return setmetatable(o, Inst)
end
local methods = {}
Inst.__index = function(o, k)
	if methods[k] then return methods[k] end
	local p = o.__props
	if k == "Position" and p.CFrame then return p.CFrame.p end
	if p[k] ~= nil then return p[k] end
	if EVENTS[k] then
		o.__signals[k] = o.__signals[k] or Signal()
		return o.__signals[k]
	end
	for _, c in ipairs(o.__children) do
		if c.__props.Name == k then return c end
	end
	if k == "Parent" or k == "PrimaryPart" or k == "Character" then return nil end
	return nil
end
Inst.__newindex = function(o, k, v)
	if k == "Parent" then
		local old = o.__props.Parent
		if old then
			for i, c in ipairs(old.__children) do if c == o then table.remove(old.__children, i) break end end
		end
		o.__props.Parent = v
		if v then table.insert(v.__children, o) end
		return
	end
	if k == "Position" then o.__props.CFrame = CFrame.new(v); return end
	if k == "Shape" and type(v) ~= "string" then error("bad Shape") end
	o.__props[k] = v
end
Inst.__tostring = function(o) return o.__props.Name end
function methods.FindFirstChild(o, name, rec)
	for _, c in ipairs(o.__children) do
		if c.__props.Name == name then return c end
		if rec then local f = c:FindFirstChild(name, true); if f then return f end end
	end
	return nil
end
function methods.WaitForChild(o, name)
	local c = o:FindFirstChild(name)
	if not c then error("WaitForChild infinito: " .. tostring(name) .. " en " .. tostring(o.__props.Name)) end
	return c
end
function methods.FindFirstChildOfClass(o, cls)
	for _, c in ipairs(o.__children) do if c.__props.ClassName == cls then return c end end
	return nil
end
function methods.GetChildren(o) local t = {}; for i, c in ipairs(o.__children) do t[i] = c end; return t end
function methods.GetDescendants(o)
	local t = {}
	local function walk(x) for _, c in ipairs(x.__children) do table.insert(t, c); walk(c) end end
	walk(o)
	return t
end
function methods.ClearAllChildren(o) for _, c in ipairs(o:GetChildren()) do c.Parent = nil end end
function methods.Destroy(o) o.Parent = nil end
function methods.IsA(o, cls)
	local c = o.__props.ClassName
	if c == cls then return true end
	if cls == "BasePart" then return c == "Part" or c == "WedgePart" or c == "SpawnLocation" end
	if cls == "GuiObject" then return c:find("Text") ~= nil or c == "Frame" or c == "ScrollingFrame" end
	return false
end
function methods.SetAttribute(o, k, v) o.__attrs[k] = v; local s = o.__signals["attr_" .. k]; if s then s:Fire() end end
function methods.GetAttribute(o, k) return o.__attrs[k] end
function methods.GetAttributeChangedSignal(o, k) o.__signals["attr_" .. k] = o.__signals["attr_" .. k] or Signal(); return o.__signals["attr_" .. k] end
function methods.GetPropertyChangedSignal() return Signal() end
function methods.GetPivot(o)
	local pp = o.__props.PrimaryPart
	if pp then return pp.__props.CFrame end
	return o.__props.CFrame or CFrame.new()
end
function methods.PivotTo(o, cf)
	local pp = o.__props.PrimaryPart
	if pp then pp.__props.CFrame = cf else o.__props.CFrame = cf end
end
function methods.IsDescendantOf(o, a) local p = o.__props.Parent; while p do if p == a then return true end; p = p.__props.Parent end; return false end
function methods.Play() end
function methods.BindToClose() end
function methods.Fire(o, ...) o.Event:Fire(...) end
function methods.Kick(o, msg) print("KICK", msg) end
function methods.FireClient(o, player, ...) if o.__onFireClient then o.__onFireClient(player, ...) end end
function methods.FireAllClients(o, ...) if o.__onFireClient then o.__onFireClient(nil, ...) end end
function methods.InvokeServer(o, ...) return o.OnServerInvoke(LOCAL_PLAYER, ...) end
function methods.RequestStreamAroundAsync() end
function methods.GetServerTimeNow() return os.time() end

Instance = { new = function(c) return newInstance(c) end }

-- Servicios ---------------------------------------------------------------------
local services = {}
local function service(name)
	if not services[name] then
		local s = newInstance(name)
		s.__props.Name = name
		services[name] = s
	end
	return services[name]
end
game = newInstance("DataModel")
game.__props.JobId = ""
methods.GetService = function(o, name) return service(name) end
workspace = service("Workspace")
workspace.__props.Gravity = 196.2
workspace.__props.CurrentCamera = newInstance("Camera")
workspace.CurrentCamera.__props.ViewportSize = { X = 1280, Y = 720 }

local tags = {}
local CS = service("CollectionService")
CS.__props.AddTag = function(_, inst, tag) tags[tag] = tags[tag] or {}; table.insert(tags[tag], inst) end
CS.__props.HasTag = function(_, inst, tag) for _, x in ipairs(tags[tag] or {}) do if x == inst then return true end end return false end
CS.__props.GetTagged = function(_, tag) return tags[tag] or {} end
CS.__props.GetInstanceAddedSignal = function() return Signal() end
CS.__props.GetInstanceRemovedSignal = function() return Signal() end
local TS = service("TweenService")
TS.__props.Create = function() return { Play = function() end } end
local RS = service("RunService")
RS.__props.IsStudio = function() return true end
RS.__props.Heartbeat = Signal(); RS.__props.RenderStepped = Signal()
local PPS = service("ProximityPromptService")
PPS.__props.PromptTriggered = Signal()
local MPS = service("MarketplaceService")
MPS.__props.PromptGamePassPurchaseFinished = Signal()
MPS.__props.UserOwnsGamePassAsync = function() return false end
local Players = service("Players")
Players.__props.PlayerAdded = Signal(); Players.__props.PlayerRemoving = Signal()
local playerList = {}
Players.__props.GetPlayers = function() return playerList end
Players.__props.GetPlayerByUserId = function(_, id) for _, p in ipairs(playerList) do if p.UserId == id then return p end end end
Players.__props.GetPlayerFromCharacter = function() return nil end
local HS = service("HttpService")
local guid = 0
HS.__props.GenerateGUID = function() guid = guid + 1; return "guid" .. guid end
service("Lighting"); service("StarterGui").__props.SetCoreGuiEnabled = function() end
service("Debris").__props.AddItem = function() end
service("UserInputService").__props.IsKeyDown = function() return false end

-- DataStore en memoria
local db = {}
service("DataStoreService").__props.GetDataStore = function()
	return {
		UpdateAsync = function(_, key, fn)
			local cur = db[key]
			local res = fn(cur)
			if res ~= nil then db[key] = res end
			return res
		end,
	}
end
DATABASE = db

-- Modulos (require desde archivos) ------------------------------------------------
local function moduleFrom(path, name, className)
	local m = newInstance(className or "ModuleScript")
	m.__props.Name = name
	m.__path = path
	return m
end
local function folderFrom(dir, name)
	local f = newInstance("Folder")
	f.__props.Name = name
	local p = io.popen('ls "' .. dir .. '"')
	for entry in p:lines() do
		local full = dir .. "/" .. entry
		local base = entry:match("^(.-)%.luau$")
		if base then
			if not base:match("^init") then
				moduleFrom(full, base).Parent = f
			end
		else
			folderFrom(full, entry).Parent = f
		end
	end
	p:close()
	return f
end
local loaded = {}
local realRequire = require
function require(ms)
	if type(ms) ~= "table" or not ms.__path then return realRequire(ms) end
	if loaded[ms] ~= nil then return loaded[ms] end
	local env = setmetatable({ script = ms }, { __index = _G, __newindex = function(_, k) error("global assignment: " .. k) end })
	local chunk, err = loadfile(ms.__path, "t", env)
	if not chunk then error(err) end
	local res = chunk()
	loaded[ms] = res
	return res
end
function RUN_SCRIPT(ms)
	local env = setmetatable({ script = ms }, { __index = _G, __newindex = function(_, k) error("global assignment: " .. k) end })
	local chunk, err = loadfile(ms.__path, "t", env)
	if not chunk then error(err) end
	chunk()
end

local shared = folderFrom(SRC .. "shared", "Shared")
shared.Parent = service("ReplicatedStorage")
SERVER_SCRIPT = folderFrom(SRC .. "server", "Server")
SERVER_SCRIPT.__path = SRC .. "server/init.server.luau"
CLIENT_SCRIPT = folderFrom(SRC .. "client", "Client")
CLIENT_SCRIPT.__path = SRC .. "client/init.client.luau"

-- Jugadores ---------------------------------------------------------------------
function MAKE_PLAYER(id, name)
	local p = newInstance("Player")
	p.__props.Name = name
	p.__props.DisplayName = name
	p.__props.UserId = id
	p.__props.Parent = Players
	local char = newInstance("Model")
	char.__props.Name = name
	local hrp = newInstance("Part")
	hrp.__props.Name = "HumanoidRootPart"
	hrp.__props.AssemblyLinearVelocity = Vector3.new()
	hrp.Parent = char
	local hum = newInstance("Humanoid")
	hum.Parent = char
	local head = newInstance("Part"); head.__props.Name = "Head"; head.Parent = char
	char.__props.PrimaryPart = hrp
	p.__props.Character = char
	local pg = newInstance("PlayerGui"); pg.__props.Name = "PlayerGui"; pg.Parent = p
	table.insert(playerList, p)
	return p
end
return true
