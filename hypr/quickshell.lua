-- Integracao do Quickshell "mine" com o Hyprland (config em Lua).
-- Instalado em ~/.config/hypr/quickshell.lua e carregado por:  pcall(require, "quickshell")  no fim do hyprland.lua
--
-- TODOS os atalhos do shell estao na tabela `keys` abaixo (uma linha por atalho). O docs/ATALHOS.md e a tabela do
-- README sao gerados dela por scripts/gen-keys-doc.py: mantenha o formato (uma entrada por linha).
--   id       nome unico (usado no quickshell-keys.lua)
--   key      combinacao no formato do Hyprland ("SUPER + C"), ou uma lista { "A", "B" } para varias teclas
--   cmd      comando (roda com sh -c, entao $HOME funciona)
--   desc     descricao (aparece no `hyprctl binds` e na documentacao)
--   grp      grupo na documentacao
--   locked   true = funciona com a tela bloqueada (teclas de midia)
--   release  true = dispara ao SOLTAR a tecla
--   off      true = desligado por padrao (so vale se o usuario der uma tecla em `override`)
--
-- Suas escolhas ficam em ~/.config/hypr/quickshell-keys.lua (criado pelo install.sh; o editor "Atalhos de teclado"
-- das configuracoes escreve nele tambem). Formato:
--   return {
--     conflicts = { settings = "replace", looks = "keep" },   -- id -> "replace" (o atalho do shell vence: o atalho
--                                                              -- antigo da mesma combinacao e removido com hl.unbind)
--                                                              -- ou "keep" (o seu vence: o do shell nao e criado)
--     override  = { settings = "SUPER + ALT + C",             -- id -> outra combinacao (string ou lista),
--                   overview = false },                       -- ou false para desligar aquele atalho
--   }
-- Ordem: este arquivo precisa ser carregado DEPOIS dos seus proprios atalhos (o install.sh poe o require no fim do
-- hyprland.lua), senao o hl.unbind roda antes do atalho existir e nao remove nada.

local AUTOSTART = true   -- inicia o shell ao logar (deixe false se voce ja inicia por outro meio)

local keys = {
    -- paineis
    { id = "settings",   key = "SUPER + C",           cmd = "qs -c mine ipc call settings toggle",        desc = "Configurações do shell", grp = "Painéis" },
    { id = "looks",      key = "SUPER + V",           cmd = "qs -c mine ipc call settings go looks",      desc = "Visuais (presets do shell)", grp = "Painéis" },
    { id = "wallpaper",  key = "SUPER + W",           cmd = "qs -c mine ipc call wallpaper pick",         desc = "Seletor de wallpaper", grp = "Painéis" },
    { id = "wp_random",  key = "SUPER + SHIFT + W",   cmd = "qs -c mine ipc call wallpaper random",       desc = "Wallpaper aleatório", grp = "Painéis" },
    { id = "launcher",   key = "SUPER + TAB",         cmd = "qs -c mine ipc call launcher toggle",        desc = "Launcher de aplicativos", grp = "Painéis" },
    { id = "home",       key = "SUPER + A",           cmd = "qs -c mine ipc call home toggle",            desc = "Painel Início", grp = "Painéis" },
    { id = "home_super", key = "SUPER + SUPER_L",     cmd = "qs -c mine ipc call home toggle",            desc = "Painel Início ao tocar só na tecla Super", grp = "Painéis", release = true, off = true },
    { id = "overview",   key = "SUPER + grave",       cmd = "qs -c mine ipc call overview toggle",        desc = "Visão geral dos workspaces", grp = "Painéis" },
    { id = "overlay",    key = "SUPER + G",           cmd = "qs -c mine ipc call overlay toggle",         desc = "Painel de jogo", grp = "Painéis" },
    { id = "osk",        key = "SUPER + K",           cmd = "qs -c mine ipc call osk toggle",             desc = "Teclado na tela", grp = "Painéis" },
    { id = "desk_edit",  key = "SUPER + ALT + D",     cmd = "qs -c mine ipc call desktop edit",           desc = "Editar widgets da área de trabalho", grp = "Painéis" },
    { id = "clipboard",  key = "SUPER + SHIFT + V",   cmd = "qs -c mine ipc call launcher search ';'",    desc = "Histórico da área de transferência", grp = "Painéis" },
    { id = "emoji",      key = "SUPER + Period",      cmd = "qs -c mine ipc call launcher search ':'",    desc = "Emojis", grp = "Painéis" },
    { id = "notif_clear", key = "CTRL + ALT + C",     cmd = "qs -c mine ipc call notifications clear",    desc = "Limpar notificações", grp = "Painéis" },
    { id = "close",      key = "SUPER + Q",           cmd = "$HOME/.local/bin/qs-close-or-kill",          desc = "Fechar o painel do shell aberto ou a janela ativa", grp = "Painéis" },
    -- apps
    { id = "terminal",   key = "SUPER + Return",      cmd = "sh -c 'qs -c mine ipc call apps terminal || kitty'", desc = "Abrir o terminal padrão", grp = "Apps" },
    -- barras
    { id = "bar_down",   key = "SUPER_L",             cmd = "qs -c mine ipc call bar superdown",          desc = "Segurar Super: mostra barras escondidas e números dos workspaces", grp = "Barras" },
    { id = "bar_up",     key = "SUPER + SUPER_L",     cmd = "qs -c mine ipc call bar superup",            desc = "Soltar Super: esconde de novo", grp = "Barras", release = true },
    -- sessao
    { id = "lock",       key = "SUPER + L",           cmd = "$HOME/.local/bin/session-action lock",       desc = "Bloquear a tela", grp = "Sessão" },
    { id = "power",      key = "CTRL + ALT + Delete", cmd = "$HOME/.local/bin/session-action menu",       desc = "Menu de energia", grp = "Sessão" },
    -- capturas e gravacao
    { id = "shot",       key = "Print",               cmd = "qs -c mine ipc call region open copy",       desc = "Capturar uma área (copia e salva)", grp = "Capturas" },
    { id = "shot_freeze", key = "SUPER + SHIFT + S",  cmd = "qs -c mine ipc call region open copy",       desc = "Capturar uma área (copia e salva)", grp = "Capturas" },
    { id = "shot_lens",  key = "SUPER + SHIFT + ALT + S", cmd = "qs -c mine ipc call region open lens",   desc = "Capturar uma área e buscar no Google Lens", grp = "Capturas" },
    { id = "ocr",        key = "SUPER + SHIFT + T",   cmd = "qs -c mine ipc call region open ocr",        desc = "Copiar o texto de uma área (OCR)", grp = "Capturas" },
    { id = "translate",  key = "SUPER + ALT + T",     cmd = "qs -c mine ipc call screentranslator translate", desc = "Traduzir a tela", grp = "Capturas" },
    { id = "picker",     key = "SUPER + SHIFT + C",   cmd = "hyprpicker -a",                              desc = "Conta-gotas de cor (copia)", grp = "Capturas" },
    { id = "rec",        key = "CTRL + ALT + R",      cmd = "qs -c mine ipc call recorder toggle",        desc = "Gravar a tela (de novo para parar)", grp = "Capturas" },
    { id = "rec_region", key = "SUPER + SHIFT + ALT + R", cmd = "qs -c mine ipc call region open record", desc = "Gravar uma área", grp = "Capturas" },
    { id = "rec_stop",   key = "SUPER + ALT + R",     cmd = "qs -c mine ipc call recorder stop",          desc = "Parar a gravação", grp = "Capturas" },
    -- midia: o shell controla o player e mostra o indicador (OSD) com o que esta tocando
    { id = "media_toggle", key = { "CTRL + SUPER + Space", "XF86AudioPlay", "XF86AudioPause" }, cmd = "$HOME/.local/bin/session-action media toggle",   desc = "Tocar / pausar", grp = "Mídia", locked = true },
    { id = "media_next", key = { "CTRL + SUPER + Equal", "XF86AudioNext" },  cmd = "$HOME/.local/bin/session-action media next",     desc = "Próxima faixa", grp = "Mídia", locked = true },
    { id = "media_prev", key = { "CTRL + SUPER + Minus", "XF86AudioPrev" },  cmd = "$HOME/.local/bin/session-action media previous", desc = "Faixa anterior", grp = "Mídia", locked = true },
    { id = "media_stop", key = { "CTRL + SUPER + Backspace", "XF86AudioStop" }, cmd = "$HOME/.local/bin/session-action media stop",  desc = "Parar a mídia", grp = "Mídia", locked = true },
}

-- escolhas do usuario (opcional)
local okc, user = pcall(require, "quickshell-keys")
if not okc or type(user) ~= "table" then user = {} end
local conflicts = user.conflicts or {}
local override = user.override or {}

local function list(k)
    if type(k) == "table" then return k end
    return { k }
end

for _, b in ipairs(keys) do
    local k = override[b.id]
    local overridden = k ~= nil
    if k == nil and not b.off then k = b.key end
    if k and k ~= false and not (not overridden and conflicts[b.id] == "keep") then
        local opts = { description = "[mine] " .. b.desc }
        if b.locked then opts.locked = true end
        if b.release then opts.release = true end
        for _, combo in ipairs(list(k)) do
            -- "replace": remove o atalho que ja existia nessa combinacao (hl.unbind, API do Hyprland 0.56); vale tambem para a combinacao
            -- escolhida em `override` (o editor das configuracoes usa isso quando voce troca por uma combinacao ja usada)
            if conflicts[b.id] == "replace" then pcall(hl.unbind, combo) end
            hl.bind(combo, hl.dsp.exec_cmd(b.cmd), opts)
        end
    end
end

-- submap vazio usado pelo editor "Atalhos de teclado" (configuracoes) so enquanto grava uma tecla: dentro dele os atalhos
-- normais ficam parados e a combinacao chega na janela das configuracoes. Esc (sem consumir) volta ao normal; o editor
-- tambem volta sozinho depois de 10 s e ao fechar. Nao tem nenhum outro atalho.
hl.define_submap("mine-rec", function()
    hl.bind("ESCAPE", hl.dsp.submap("reset"), { non_consuming = true, description = "[mine-rec] sair da gravacao" })
end)

-- o seletor de wallpaper faz a propria animacao: desliga a animacao de camada do Hyprland nele
hl.layer_rule({ match = { namespace = "mine-wallpaper-picker" }, no_anim = true })

-- blur da moldura e valores globais: gerados pela pagina Blur das configuracoes
pcall(require, "quickshell-blur")

if AUTOSTART then
    -- mine-shell (instalado pelo install.sh) libera o nome de notificacoes e grava log; sem ele, qs direto
    hl.on("hyprland.start", function() hl.exec_cmd("sh -c '[ -x \"$HOME/.local/bin/mine-shell\" ] && exec \"$HOME/.local/bin/mine-shell\" start || exec qs -c mine'") end)
end
