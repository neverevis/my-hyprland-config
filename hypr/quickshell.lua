-- Integracao do Quickshell "mine" com o Hyprland (config em Lua).
-- Instalado em ~/.config/hypr/quickshell.lua e carregado por:  pcall(require, "quickshell")  no hyprland.lua

local AUTOSTART = true   -- inicia o shell ao logar (deixe false se voce ja inicia por outro meio)

-- atalhos
hl.bind("SUPER + C", hl.dsp.exec_cmd("qs -c mine ipc call settings toggle"))    -- janela de configuracoes
hl.bind("SUPER + W", hl.dsp.exec_cmd("qs -c mine ipc call wallpaper pick"))     -- seletor de wallpaper
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("qs -c mine ipc call launcher toggle"))  -- launcher de aplicativos
hl.bind("SUPER + L", hl.dsp.exec_cmd("qs -c mine ipc call session lock"))      -- tela de bloqueio
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("qs -c mine ipc call session menu"))  -- menu de energia
hl.bind("Print", hl.dsp.exec_cmd("qs -c mine ipc call region open copy"))      -- capturar uma area (copia e salva)
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("qs -c mine ipc call region open ocr"))  -- copiar texto da tela
hl.bind("SUPER + G", hl.dsp.exec_cmd("qs -c mine ipc call overlay toggle"))    -- painel de jogo
hl.bind("SUPER + A", hl.dsp.exec_cmd("qs -c mine ipc call home toggle"))       -- painel Inicio
hl.bind("SUPER + grave", hl.dsp.exec_cmd("qs -c mine ipc call overview toggle"))  -- visao geral dos workspaces
-- teclas de midia: o shell controla o player e mostra o indicador (OSD) com o que esta tocando
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("qs -c mine ipc call media toggle"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs -c mine ipc call media toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("qs -c mine ipc call media next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("qs -c mine ipc call media previous"), { locked = true })

-- o seletor de wallpaper faz a propria animacao: desliga a animacao de camada do Hyprland nele
hl.layer_rule({ match = { namespace = "mine-wallpaper-picker" }, no_anim = true })

-- blur da moldura e valores globais: gerados pela pagina Blur das configuracoes
pcall(require, "quickshell-blur")

if AUTOSTART then
    hl.on("hyprland.start", function() hl.exec_cmd("qs -c mine") end)
end
