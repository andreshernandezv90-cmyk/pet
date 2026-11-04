-- UIKit: utilidades para construir la interfaz por codigo (sin assets).
-- Botones grandes, textos breves y colores con buen contraste (GDD 18).

local K = {}

K.C = {
	bg = Color3.fromRGB(28, 24, 48),
	panel = Color3.fromRGB(44, 38, 72),
	card = Color3.fromRGB(60, 52, 96),
	cardHi = Color3.fromRGB(82, 72, 130),
	text = Color3.fromRGB(250, 248, 255),
	muted = Color3.fromRGB(190, 182, 220),
	accent = Color3.fromRGB(140, 110, 255),
	good = Color3.fromRGB(80, 200, 120),
	bad = Color3.fromRGB(230, 90, 100),
	warn = Color3.fromRGB(255, 190, 70),
	gold = Color3.fromRGB(255, 210, 90),
	blue = Color3.fromRGB(80, 160, 255),
}

K.TitleFont = Enum.Font.FredokaOne
K.Font = Enum.Font.GothamMedium
K.Bold = Enum.Font.GothamBold

function K.new(className, props, children)
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function K.corner(radius)
	return K.new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function K.stroke(color, thickness)
	return K.new("UIStroke", { Color = color or Color3.new(0, 0, 0), Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.2 })
end

function K.pad(n)
	return K.new("UIPadding", { PaddingTop = UDim.new(0, n), PaddingBottom = UDim.new(0, n), PaddingLeft = UDim.new(0, n),
		PaddingRight = UDim.new(0, n) })
end

function K.vlist(gap, align)
	return K.new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, gap or 6),
		SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = align or Enum.HorizontalAlignment.Left })
end

function K.hlist(gap, valign)
	return K.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, gap or 6),
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = valign or Enum.VerticalAlignment.Center })
end

function K.grid(cellW, cellH, gap)
	return K.new("UIGridLayout", { CellSize = UDim2.new(0, cellW, 0, cellH), CellPadding = UDim2.new(0, gap or 6, 0, gap or 6),
		SortOrder = Enum.SortOrder.LayoutOrder })
end

-- Texto. props extra se aplican al final.
function K.text(text, size, color, props)
	local t = K.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text or "",
		TextSize = size or 16,
		TextColor3 = color or K.C.text,
		Font = K.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
		RichText = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, (size or 16) + 4),
	})
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				t.Parent = v
			else
				t[k] = v
			end
		end
	end
	return t
end

function K.title(text, size, props)
	local t = K.text(text, size or 20, K.C.text, props)
	t.Font = K.TitleFont
	return t
end

-- Boton con esquinas redondeadas. enabled=false lo atenua y desactiva.
function K.button(text, color, onClick, props)
	local b = K.new("TextButton", {
		Text = text,
		TextSize = 16,
		Font = K.Bold,
		TextColor3 = K.C.text,
		BackgroundColor3 = color or K.C.accent,
		AutoButtonColor = true,
		Size = UDim2.new(0, 120, 0, 38),
		TextWrapped = true,
	}, { K.corner(10) })
	local enabled = true
	if props then
		for k, v in pairs(props) do
			if k == "Enabled" then
				enabled = v
			elseif k == "Parent" then
				b.Parent = v
			else
				b[k] = v
			end
		end
	end
	if not enabled then
		b.AutoButtonColor = false
		b.BackgroundColor3 = Color3.fromRGB(90, 86, 110)
		b.TextColor3 = Color3.fromRGB(170, 166, 190)
	end
	if onClick then
		b.Activated:Connect(function()
			if enabled then
				onClick(b)
			end
		end)
	end
	return b
end

function K.frame(props, children)
	local f = K.new("Frame", { BackgroundColor3 = K.C.card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y })
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				f.Parent = v
			else
				f[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = f
		end
	end
	return f
end

-- Tarjeta con esquinas y padding
function K.card(props, children)
	local f = K.frame(props, children)
	K.corner(10).Parent = f
	K.pad(8).Parent = f
	return f
end

function K.scroll(props)
	local s = K.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarImageColor3 = K.C.muted,
	})
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				s.Parent = v
			else
				s[k] = v
			end
		end
	end
	return s
end

-- Barra de progreso 0..1
function K.bar(frac, color, height)
	local back = K.new("Frame", { BackgroundColor3 = Color3.fromRGB(30, 26, 50), BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or 12) }, { K.corner(6) })
	K.new("Frame", { BackgroundColor3 = color or K.C.good, BorderSizePixel = 0,
		Size = UDim2.new(math.clamp(frac or 0, 0, 1), 0, 1, 0), Parent = back }, { K.corner(6) })
	return back
end

-- Fila horizontal de elementos (auto alto)
function K.row(children, gap)
	local f = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
	K.hlist(gap or 6).Parent = f
	for i, c in ipairs(children or {}) do
		c.LayoutOrder = i
		c.Parent = f
	end
	return f
end

-- Pestañas: devuelve el frame de botones
function K.tabs(list, current, onSelect)
	local f = K.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) })
	K.hlist(6).Parent = f
	for i, t in ipairs(list) do
		local b = K.button(t.name, t.id == current and K.C.accent or K.C.card, function()
			onSelect(t.id)
		end, { Size = UDim2.new(0, t.width or 130, 0, 36), LayoutOrder = i })
		b.Parent = f
	end
	return f
end

function K.fmtTime(secs)
	secs = math.max(0, math.floor(secs))
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%d:%02d", m, s)
end

function K.fmtNum(n)
	n = math.floor(n or 0)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("%.1fk", n / 1000)
	end
	return tostring(n)
end

function K.hex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

-- Texto enriquecido coloreado
function K.color(text, c)
	return '<font color="' .. K.hex(c) .. '">' .. text .. "</font>"
end

return K
