-- Integracao do Quickshell "mine" com o Hyprland (config em Lua).
-- Instalado em ~/.config/hypr/quickshell.lua e carregado por:  pcall(require, "quickshell")  no hyprland.lua

local AUTOSTART = true   -- inicia o shell ao logar (deixe false se voce ja inicia por outro meio)

-- atalhos
hl.bind("SUPER + C", hl.dsp.exec_cmd("qs -c mine ipc call settings toggle"))    -- janela de configuracoes
hl.bind("SUPER + W", hl.dsp.exec_cmd("qs -c mine ipc call wallpaper pick"))     -- seletor de wallpaper
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("qs -c mine ipc call launcher toggle"))  -- launcher de aplicativos

-- o seletor de wallpaper faz a propria animacao: desliga a animacao de camada do Hyprland nele
hl.layer_rule({ match = { namespace = "mine-wallpaper-picker" }, no_anim = true })

-- blur da moldura e valores globais: gerados pela pagina Blur das configuracoes
pcall(require, "quickshell-blur")

if AUTOSTART then
    hl.on("hyprland.start", function() hl.exec_cmd("qs -c mine") end)
end
