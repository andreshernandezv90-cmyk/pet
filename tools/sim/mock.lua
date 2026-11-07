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

-- CFrame con rotacion real (matriz 3x3 por columnas: right, up, back) ----------
local CF = {}
local function mat(r00, r01, r02, r10, r11, r12, r20, r21, r22)
	return { r00, r01, r02, r10, r11, r12, r20, r21, r22 }
end
local IDM = mat(1, 0, 0, 0, 1, 0, 0, 0, 1)
local function mmul(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			r[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return r
end
local function mvec(m, v)
	return Vector3.new(m[1] * v.X + m[2] * v.Y + m[3] * v.Z, m[4] * v.X + m[5] * v.Y + m[6] * v.Z, m[7] * v.X + m[8] * v.Y + m[9] * v.Z)
end
local function mt(m) return mat(m[1], m[4], m[7], m[2], m[5], m[8], m[3], m[6], m[9]) end
local function newCF(p, m) return setmetatable({ p = p, m = m or IDM }, CF) end
CF.__index = function(c, k)
	if k == "Position" then return c.p end
	if k == "X" then return c.p.X end
	if k == "Y" then return c.p.Y end
	if k == "Z" then return c.p.Z end
	if k == "LookVector" then return Vector3.new(-c.m[3], -c.m[6], -c.m[9]) end
	if k == "RightVector" then return Vector3.new(c.m[1], c.m[4], c.m[7]) end
	if k == "UpVector" then return Vector3.new(c.m[2], c.m[5], c.m[8]) end
	if k == "Rotation" then return newCF(Vector3.new(0, 0, 0), c.m) end
	if k == "Inverse" then return function(self) local it = mt(self.m); return newCF(-mvec(it, self.p), it) end end
	if k == "Lerp" then return function(a, b, t) return newCF(a.p + (b.p - a.p) * t, a.m) end end
	if k == "PointToObjectSpace" then return function(self, v) return mvec(mt(self.m), v - self.p) end end
	if k == "PointToWorldSpace" then return function(self, v) return self.p + mvec(self.m, v) end end
	if k == "VectorToWorldSpace" then return function(self, v) return mvec(self.m, v) end end
	if k == "GetComponents" then return function(self) local m = self.m; return self.p.X, self.p.Y, self.p.Z, m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9] end end
	return nil
end
CF.__mul = function(a, b)
	if getmetatable(b) == V3 then return a.p + mvec(a.m, b) end
	return newCF(a.p + mvec(a.m, b.p), mmul(a.m, b.m))
end
CF.__add = function(a, b) return newCF(a.p + b, a.m) end
CF.__sub = function(a, b)
	if getmetatable(b) == V3 then return newCF(a.p - b, a.m) end
	return newCF(a.p - b.p, a.m)
end
CF.__eq = function(a, b) if not (a.p == b.p) then return false end for i = 1, 9 do if math.abs(a.m[i] - b.m[i]) > 1e-9 then return false end end return true end
local function rx(a) local c, s = math.cos(a), math.sin(a); return mat(1, 0, 0, 0, c, -s, 0, s, c) end
local function ry(a) local c, s = math.cos(a), math.sin(a); return mat(c, 0, s, 0, 1, 0, -s, 0, c) end
local function rz(a) local c, s = math.cos(a), math.sin(a); return mat(c, -s, 0, s, c, 0, 0, 0, 1) end
CFrame = {
	new = function(x, y, z, ...)
		local extra = { ... }
		if type(x) == "table" then
			if y then return CFrame.lookAt(x, y) end
			return newCF(x)
		end
		if #extra == 9 then return newCF(Vector3.new(x, y, z), mat(table.unpack(extra))) end
		return newCF(Vector3.new(x or 0, y or 0, z or 0))
	end,
	Angles = function(a, b, c) return newCF(Vector3.new(0, 0, 0), mmul(mmul(rx(a or 0), ry(b or 0)), rz(c or 0))) end,
	lookAt = function(at, target, up)
		up = up or Vector3.new(0, 1, 0)
		local look = (target - at).Unit
		local right = Vector3.new(look.Y * up.Z - look.Z * up.Y, look.Z * up.X - look.X * up.Z, look.X * up.Y - look.Y * up.X)
		if right.Magnitude < 1e-6 then right = Vector3.new(1, 0, 0) end
		right = right.Unit
		local u = Vector3.new(right.Y * look.Z - right.Z * look.Y, right.Z * look.X - right.X * look.Z, right.X * look.Y - right.Y * look.X)
		return newCF(at, mat(right.X, u.X, -look.X, right.Y, u.Y, -look.Y, right.Z, u.Z, -look.Z))
	end,
	fromAxisAngle = function(axis, a)
		local u = axis.Unit
		local c, s, t = math.cos(a), math.sin(a), 1 - math.cos(a)
		return newCF(Vector3.new(0, 0, 0), mat(t * u.X * u.X + c, t * u.X * u.Y - s * u.Z, t * u.X * u.Z + s * u.Y,
			t * u.X * u.Y + s * u.Z, t * u.Y * u.Y + c, t * u.Y * u.Z - s * u.X,
			t * u.X * u.Z - s * u.Y, t * u.Y * u.Z + s * u.X, t * u.Z * u.Z + c))
	end,
}
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CFrame.identity = newCF(Vector3.new(0, 0, 0))
V3.__index = function(v, k)
	if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
	if k == "Unit" then local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z); if m == 0 then return v end; return Vector3.new(v.X / m, v.Y / m, v.Z / m) end
	if k == "Lerp" then return function(a, b, t) return a + (b - a) * t end end
	if k == "Dot" then return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end end
	if k == "Cross" then return function(a, b) return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end end
	return nil
end
Vector3.one = Vector3.new(1, 1, 1)
Vector3.yAxis = Vector3.new(0, 1, 0)
Vector3.xAxis = Vector3.new(1, 0, 0)
Vector3.zAxis = Vector3.new(0, 0, 1)

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
NumberRange = opaque("NumberRange"); PhysicalProperties = opaque("PhysicalProperties"); NumberSequenceKeypoint = opaque("NumberSequenceKeypoint"); ColorSequenceKeypoint = opaque("ColorSequenceKeypoint")
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
	if k == "Position" then
		local old = o.__props.CFrame
		o.__props.CFrame = old and (old - old.Position + v) or CFrame.new(v)
		return
	end
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
function methods.FindFirstChildWhichIsA(o, cls)
	for _, c in ipairs(o.__children) do if c:IsA(cls) then return c end end
	return nil
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
	if cls == "BasePart" then return c == "Part" or c == "WedgePart" or c == "SpawnLocation" or c == "MeshPart" end
	if cls == "LuaSourceContainer" then return c == "Script" or c == "LocalScript" or c == "ModuleScript" end
	if cls == "GuiObject" then return c:find("Text") ~= nil or c == "Frame" or c == "ScrollingFrame" end
	return false
end
function methods.SetAttribute(o, k, v) o.__attrs[k] = v; local s = o.__signals["attr_" .. k]; if s then s:Fire() end end
function methods.GetAttribute(o, k) return o.__attrs[k] end
function methods.GetAttributeChangedSignal(o, k) o.__signals["attr_" .. k] = o.__signals["attr_" .. k] or Signal(); return o.__signals["attr_" .. k] end
function methods.GetPropertyChangedSignal() return Signal() end
function methods.GetPivot(o)
	local pp = o.__props.PrimaryPart
	if pp then
		local off = pp.__props.PivotOffset
		return off and pp.__props.CFrame * off or pp.__props.CFrame
	end
	return o.__props.CFrame or CFrame.new()
end
function methods.PivotTo(o, cf)
	local pp = o.__props.PrimaryPart
	if pp then
		local off = pp.__props.PivotOffset
		pp.__props.CFrame = off and cf * off:Inverse() or cf
	else
		o.__props.CFrame = cf
	end
end
-- Clonado profundo con referencias internas reasignadas (PrimaryPart, Part0/Part1...)
function methods.Clone(o)
	local map = {}
	local function copy(x)
		local c = newInstance(x.__props.ClassName)
		map[x] = c
		for k, v in pairs(x.__props) do
			if k ~= "Parent" then c.__props[k] = v end
		end
		for k, v in pairs(x.__attrs) do c.__attrs[k] = v end
		for _, ch in ipairs(x.__children) do
			local cc = copy(ch)
			cc.__props.Parent = c
			table.insert(c.__children, cc)
		end
		return c
	end
	local root = copy(o)
	root.__props.Parent = nil
	for orig, c in pairs(map) do
		for k, v in pairs(c.__props) do
			if type(v) == "table" and getmetatable(v) == Inst and k ~= "Parent" and map[v] then c.__props[k] = map[v] end
		end
	end
	return root
end
local function partsOf(o)
	local t = {}
	for _, d in ipairs(o:GetDescendants()) do if d:IsA("BasePart") then table.insert(t, d) end end
	return t
end
-- Caja alineada a los ejes del mundo (suficiente para modelos sin rotar)
function methods.GetBoundingBox(o)
	local lo, hi
	for _, p in ipairs(partsOf(o)) do
		local c, h = p.__props.CFrame.p, p.__props.Size / 2
		local a, b = c - h, c + h
		if not lo then lo, hi = a, b else
			lo = Vector3.new(math.min(lo.X, a.X), math.min(lo.Y, a.Y), math.min(lo.Z, a.Z))
			hi = Vector3.new(math.max(hi.X, b.X), math.max(hi.Y, b.Y), math.max(hi.Z, b.Z))
		end
	end
	if not lo then return CFrame.new(), Vector3.new() end
	return CFrame.new((lo + hi) / 2), hi - lo
end
function methods.GetExtentsSize(o) local _, s = o:GetBoundingBox(); return s end
function methods.GetScale(o) return o.__props.__scale or 1 end
function methods.ScaleTo(o, k)
	local f = k / (o.__props.__scale or 1)
	local pivot = o:GetPivot().p
	for _, p in ipairs(partsOf(o)) do
		local cf = p.__props.CFrame
		p.__props.Size = p.__props.Size * f
		p.__props.CFrame = cf - cf.p + (pivot + (cf.p - pivot) * f)
		if p.__props.PivotOffset then
			local po = p.__props.PivotOffset
			p.__props.PivotOffset = po - po.p + po.p * f
		end
	end
	o.__props.__scale = k
end
-- Partes unidas por Motor6D / Weld / WeldConstraint (recursivo)
function methods.GetConnectedParts(o)
	local model = o.__props.Parent
	while model and model.__props.Parent and model.__props.ClassName ~= "Model" do model = model.__props.Parent end
	local joints = {}
	for _, d in ipairs((model or o):GetDescendants()) do
		local c = d.__props.ClassName
		if (c == "Motor6D" or c == "Weld" or c == "WeldConstraint") and d.__props.Part0 and d.__props.Part1 then
			table.insert(joints, d)
		end
	end
	local seen, out, queue = { [o] = true }, { o }, { o }
	while #queue > 0 do
		local x = table.remove(queue)
		for _, j in ipairs(joints) do
			local other = (j.__props.Part0 == x and j.__props.Part1) or (j.__props.Part1 == x and j.__props.Part0) or nil
			if other and not seen[other] then seen[other] = true; table.insert(out, other); table.insert(queue, other) end
		end
	end
	return out
end
-- Raycast simulado sobre un terreno de alturas: SIM_GROUND(x, z) -> altura o nil.
-- Por defecto, suelo plano en y = 0 (como Terrain.Ground del juego).
SIM_GROUND = function() return 0 end
SIM_RAYS = 0
RaycastParams = { new = function() return { FilterDescendantsInstances = {} } end }
function methods.Raycast(o, origin, dir)
	SIM_RAYS = SIM_RAYS + 1
	local x, z = origin.X, origin.Z
	local h = SIM_GROUND(x, z)
	if h == nil or origin.Y < h or origin.Y + dir.Y > h then return nil end
	local e = 0.05
	local hx = (SIM_GROUND(x + e, z) or h) - (SIM_GROUND(x - e, z) or h)
	local hz = (SIM_GROUND(x, z + e) or h) - (SIM_GROUND(x, z - e) or h)
	local n = Vector3.new(-hx / (2 * e), 1, -hz / (2 * e))
	return { Position = Vector3.new(x, h, z), Normal = n.Unit, Instance = o }
end
-- Animator simulado: registra pistas y estados de reproduccion
function methods.LoadAnimation(o, anim)
	-- Length = 0 imita una pista cuya duracion aun no se conoce (el final llega por Stopped)
	local track = { Animation = anim, IsPlaying = false, Speed = 1, Looped = false, Priority = nil, plays = 0, Length = 0,
		Stopped = Signal() }
	function track:Play(fade, weight, speed) self.IsPlaying = true; self.plays = self.plays + 1; self.Speed = speed or 1 end
	function track:Stop() local was = self.IsPlaying; self.IsPlaying = false; if was then self.Stopped:Fire() end end
	function track:AdjustSpeed(v) self.Speed = v end
	-- Prueba: la pista sin bucle llega a su final
	function track:__finish() self:Stop() end
	o.__tracks = o.__tracks or {}
	table.insert(o.__tracks, track)
	return track
end
function methods.IsDescendantOf(o, a) local p = o.__props.Parent; while p do if p == a then return true end; p = p.__props.Parent end; return false end
function methods.Play() end
function methods.BindToClose() end
function methods.Fire(o, ...) o.Event:Fire(...) end
function methods.Kick(o, msg) o.__props.Kicked = msg; print("KICK", msg) end
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
TERRAIN_OPS = {}
TERRAIN_COLORS = {}
local terrain = newInstance("Terrain")
terrain.__props.Name = "Terrain"
terrain.Parent = workspace
terrain.__props.FillBlock = function(_, cf, size, mat) table.insert(TERRAIN_OPS, { op = "block", cf = cf, size = size, mat = mat }) end
terrain.__props.FillBall = function(_, c, r, mat) table.insert(TERRAIN_OPS, { op = "ball", c = c, r = r, mat = mat }) end
terrain.__props.FillCylinder = function(_, cf, h, r, mat) table.insert(TERRAIN_OPS, { op = "cyl", cf = cf, h = h, r = r, mat = mat }) end
terrain.__props.FillWedge = function(_, cf, size, mat) table.insert(TERRAIN_OPS, { op = "block", cf = cf, size = size, mat = mat }) end
terrain.__props.SetMaterialColor = function(_, mat, c) TERRAIN_COLORS[mat] = c end
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
	local fh = io.open(dir .. "/init.luau", "r")
	if fh then
		fh:close()
		-- carpeta con init.luau = ModuleScript con hijos (regla de Rojo)
		f.__props.ClassName = "ModuleScript"
		f.__path = dir .. "/init.luau"
	end
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
	hrp.__props.Size = Vector3.new(2, 2, 1)
	hrp.Parent = char
	local hum = newInstance("Humanoid")
	hum.__props.HipHeight = 2
	hum.__props.RigType = Enum.HumanoidRigType.R15
	hum.Parent = char
	local head = newInstance("Part"); head.__props.Name = "Head"; head.Parent = char
	char.__props.PrimaryPart = hrp
	p.__props.Character = char
	local pg = newInstance("PlayerGui"); pg.__props.Name = "PlayerGui"; pg.Parent = p
	table.insert(playerList, p)
	return p
end
return true
