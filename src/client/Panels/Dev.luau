-- Dev: atajos de prueba (solo aparecen y funcionan en Roblox Studio).

local K = require(script.Parent.Parent.UIKit)
local Net = require(script.Parent.Parent.Net)
local Followers = require(script.Parent.Parent.Followers)

local Dev = { title = "🛠️ Herramientas de prueba (Studio)" }

function Dev.render(root)
	local sc = K.scroll({ Name = "DevScroll", Parent = root })
	K.vlist(8).Parent = sc
	K.text("Estas herramientas solo funcionan dentro de Roblox Studio y sirven para probar rapido cada sistema.", 14, K.C.muted,
		{ Parent = sc, LayoutOrder = 0 })
	local cmds = {
		{ "resources", "+500 de cada recurso", K.C.good },
		{ "unlock", "Desbloquear herramientas, edificios y zonas", K.C.accent },
		{ "pets", "+3 de cada variante (63) y +2000 esencias", K.C.gold },
		{ "shiny", "✨ +1 Lumi comun Shiny", Color3.fromRGB(255, 210, 90) },
		{ "shinyspawn", "✨ Forzar/quitar apariciones Shiny (sesion)", Color3.fromRGB(240, 180, 60) },
		{ "raid", "Iniciar incursion ahora", Color3.fromRGB(220, 70, 110) },
		{ "gift", "Crear un regalo en mi zona", Color3.fromRGB(255, 170, 60) },
		{ "reset", "Reiniciar mi perfil", K.C.bad },
	}
	for i, c in ipairs(cmds) do
		K.button(c[2], c[3], function()
			Net.Send("dev", { cmd = c[1] })
		end, { Size = UDim2.new(0, 420, 0, 40), LayoutOrder = i, Parent = sc })
	end

	-- Vista previa de animaciones (solo local, sin datos ni red): compañeros equipados
	-- con modelo importado. Quedate quieto: al moverse, el PET despierta solo.
	local base = #cmds + 1
	local status = K.text("Animaciones de compañeros (equipa un Lumi y quedate quieto):", 14, K.C.muted,
		{ Parent = sc, LayoutOrder = base })
	local anims = {
		{ "happy", "Animacion: Happy (celebrar)" },
		{ "sleep", "Animacion: Sleep (dormir)" },
		{ "wake", "Animacion: despertar" },
	}
	for i, a in ipairs(anims) do
		K.button(a[2], K.C.accent, function()
			local n = Followers.PreviewAnimation(a[1])
			status.Text = n > 0 and (a[2] .. " en " .. n .. " compañero(s)")
				or "Ningun compañero animado la tiene (modelo procedural o sin ids publicados)."
		end, { Size = UDim2.new(0, 420, 0, 40), LayoutOrder = base + i, Parent = sc })
	end
end

return Dev
