-- Guia del bosque: explica las mecanicas principales con dialogos breves.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Progression)

local K = require(script.Parent.Parent.UIKit)
local State = require(script.Parent.Parent.State)

local Guide = { title = "🧙 Guia del bosque" }
local page = 1

local PAGES = {
	{ "¡Bienvenido al Mundo PET!", "Este bosque enorme tiene cinco zonas. Sigue el camino hacia el este: cada zona tiene sus PETs, su boca de mina y su faro." },
	{ "Capturar PETs", "Acercate a un PET salvaje y manten F (o el boton) para usar tu Succionador. Los PETs que ves son solo tuyos: nadie te los quita." },
	{ "Rarezas", "Comun, Raro, Epico, Legendario y Mitico. Los mas raros brillan mas y cuestan mas de capturar. La pocion Fortuna mejora la suerte." },
	{ "Minas de Zuar", "Las Minas de Zuar son otro mundo: la Cantera siempre esta abierta y cada galeria se abre con su zona. Entra por la boca de mina de cada zona o desde el Mapa. Tus vetas son solo tuyas y cambian cada pocos minutos." },
	{ "Herramientas", "En el Taller de tu santuario mejoras el pico (minerales mas duros), el hacha (mas madera) y el succionador (capturas mas faciles)." },
	{ "Barreras", "Las cortinas magicas separan las zonas. Puedes ver la siguiente, pero solo la cruzas cuando cumples sus requisitos. Acercate a la puerta para verlos." },
	{ "Extractores", "En tu parcela, asigna PETs a los extractores y produciran recursos incluso cuando no estes conectado (hasta 2 horas)." },
	{ "Faros y regalos", "Los faros se activan al visitar una zona y te permiten volver rapido. Explora el bosque: a veces aparecen regalos escondidos." },
}

function Guide.onOpen()
	page = 1
end

function Guide.render(root, UI)
	local d = State.data
	local p = PAGES[page]
	local box = K.card({ Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = K.C.cardHi, Parent = root })
	K.vlist(10).Parent = box
	K.title(p[1], 24, { Parent = box, LayoutOrder = 1 })
	K.text(p[2], 18, K.C.text, { Parent = box, LayoutOrder = 2 })
	if page == 6 and d.zones.unlocked < 5 then
		local nextZone = d.zones.unlocked + 1
		local lines = {}
		for _, st in ipairs(Progression.Status(d, nextZone)) do
			table.insert(lines, (st.ok and "✅ " or "❌ ") .. st.text)
		end
		K.text("Para la Zona " .. nextZone .. ":\n" .. table.concat(lines, "\n"), 16, K.C.gold, { Parent = box, LayoutOrder = 3 })
	end
	K.text(page .. " / " .. #PAGES, 14, K.C.muted, { Parent = box, LayoutOrder = 4 })
	local row = K.row({
		K.button("◀ Anterior", K.C.card, function()
			page = math.max(1, page - 1)
			UI.Render()
		end, { Enabled = page > 1, Size = UDim2.new(0, 150, 0, 40) }),
		K.button(page < #PAGES and "Siguiente ▶" or "¡Entendido!", K.C.accent, function()
			if page < #PAGES then
				page = page + 1
				UI.Render()
			else
				UI.Close()
			end
		end, { Size = UDim2.new(0, 170, 0, 40) }),
	}, 10)
	row.LayoutOrder = 5
	row.Parent = box
end

return Guide
