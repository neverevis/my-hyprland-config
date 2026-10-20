// Opcoes do Hyprland pela pagina Hyprland: so o que voce muda vira "override" (Settings.hyprCfg, chave "secao:opcao" e o valor),
// gravado pelo HyprSync em ~/.config/hypr/quickshell-blur.lua (carregado por ultimo pelo hyprland.lua) e aplicado ao vivo
// (hyprctl eval). "Restaurar" tira o override e recarrega a config (volta ao valor dos seus arquivos / HyprMod).
// Valores atuais: scripts/hyprget.py. Monitor: Settings.hyprMonitor (output, mode, scale). Apps ao iniciar: Settings.hyprAutostart.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property var groups: [
        { id: "windows", label: "Janelas", icon: "window" },
        { id: "shadow", label: "Sombra e foco", icon: "layers" },
        { id: "layout", label: "Layout", icon: "view_column" },
        { id: "keyboard", label: "Teclado", icon: "keyboard" },
        { id: "mouse", label: "Mouse", icon: "mouse" },
        { id: "system", label: "Sistema", icon: "cog" }
    ]
    readonly property var options: [
        { key: "general:gaps_in", group: "windows", label: "Espaço entre janelas", type: "slider", from: 0, to: 40, suffix: " px" },
        { key: "general:gaps_out", group: "windows", label: "Espaço até a borda da tela", type: "slider", from: 0, to: 60, suffix: " px" },
        { key: "general:gaps_workspaces", group: "windows", label: "Espaço entre workspaces (ao trocar)", type: "slider", from: 0, to: 200, suffix: " px" },
        { key: "general:border_size", group: "windows", label: "Espessura da borda", type: "slider", from: 0, to: 8, suffix: " px" },
        { key: "decoration:rounding", group: "windows", label: "Arredondamento", type: "slider", from: 0, to: 40, suffix: " px" },
        { key: "decoration:rounding_power", group: "windows", label: "Forma do canto (2 = círculo, mais = squircle)", type: "slider", from: 1, to: 10, step: 0.1, float: true },
        { key: "decoration:active_opacity", group: "windows", label: "Opacidade da janela ativa", type: "slider", from: 0.3, to: 1, step: 0.01, float: true, pct: true },
        { key: "decoration:inactive_opacity", group: "windows", label: "Opacidade das outras janelas", type: "slider", from: 0.3, to: 1, step: 0.01, float: true, pct: true },
        { key: "decoration:dim_inactive", group: "shadow", label: "Escurecer as janelas sem foco", type: "switch" },
        { key: "decoration:dim_strength", group: "shadow", label: "Quanto escurecer", type: "slider", from: 0, to: 1, step: 0.01, float: true, pct: true, when: "decoration:dim_inactive" },
        { key: "decoration:shadow:enabled", group: "shadow", label: "Sombra nas janelas", type: "switch" },
        { key: "decoration:shadow:range", group: "shadow", label: "Tamanho da sombra", type: "slider", from: 0, to: 60, suffix: " px", when: "decoration:shadow:enabled" },
        { key: "decoration:shadow:render_power", group: "shadow", label: "Suavidade da sombra", type: "slider", from: 1, to: 4, when: "decoration:shadow:enabled" },
        { key: "general:resize_on_border", group: "shadow", label: "Redimensionar puxando a borda", type: "switch" },
        { key: "general:layout", group: "layout", label: "Como as janelas se organizam", type: "seg", options: [["dwindle", "Espiral"], ["master", "Mestre"], ["scrolling", "Rolagem"]] },
        { key: "dwindle:preserve_split", group: "layout", label: "Manter a divisão ao reorganizar (espiral)", type: "switch" },
        { key: "dwindle:smart_split", group: "layout", label: "Divisão inteligente (segue o cursor)", type: "switch" },
        { key: "dwindle:force_split", group: "layout", label: "Lado da nova janela (espiral)", type: "seg", options: [[0, "Automático"], [1, "Esquerda/cima"], [2, "Direita/baixo"]] },
        { key: "dwindle:default_split_ratio", group: "layout", label: "Proporção da divisão (100 % = metade)", type: "slider", from: 0.1, to: 1.9, step: 0.05, float: true },
        { key: "master:orientation", group: "layout", label: "Onde fica a janela principal (mestre)", type: "seg", options: [["left", "Esquerda"], ["right", "Direita"], ["top", "Cima"], ["bottom", "Baixo"], ["center", "Centro"]] },
        { key: "master:mfact", group: "layout", label: "Tamanho da janela principal (mestre)", type: "slider", from: 0.1, to: 0.9, step: 0.01, float: true, pct: true },
        { key: "master:new_status", group: "layout", label: "Janela nova no layout mestre", type: "seg", options: [["slave", "Ao lado"], ["master", "Vira a principal"], ["inherit", "Como a atual"]] },
        { key: "input:kb_layout", group: "keyboard", label: "Layouts (separados por vírgula, ex.: br,us)", type: "text" },
        { key: "input:kb_variant", group: "keyboard", label: "Variantes (ex.: ,intl)", type: "text" },
        { key: "input:kb_options", group: "keyboard", label: "Trocar de layout com", type: "seg", options: [["", "Nada"], ["grp:alt_shift_toggle", "Alt+Shift"], ["grp:win_space_toggle", "Super+Espaço"], ["grp:caps_toggle", "Caps Lock"]] },
        { key: "input:numlock_by_default", group: "keyboard", label: "Num Lock ligado ao iniciar", type: "switch" },
        { key: "input:repeat_delay", group: "keyboard", label: "Espera para repetir a tecla", type: "slider", from: 150, to: 800, suffix: " ms" },
        { key: "input:repeat_rate", group: "keyboard", label: "Repetições por segundo", type: "slider", from: 10, to: 80 },
        { key: "input:sensitivity", group: "mouse", label: "Velocidade do mouse", type: "slider", from: -1, to: 1, step: 0.05, float: true },
        { key: "input:accel_profile", group: "mouse", label: "Aceleração", type: "seg", options: [["", "Padrão"], ["adaptive", "Adaptativa"], ["flat", "Desligada (linear)"]] },
        { key: "input:follow_mouse", group: "mouse", label: "Foco segue o mouse", type: "seg", options: [[0, "Não"], [1, "Sempre"], [2, "Só o cursor"], [3, "Só o clique"]] },
        { key: "input:force_no_accel", group: "mouse", label: "Aceleração totalmente desligada (raw)", type: "switch" },
        { key: "input:left_handed", group: "mouse", label: "Mouse para canhotos", type: "switch" },
        { key: "input:natural_scroll", group: "mouse", label: "Rolagem natural", type: "switch" },
        { key: "misc:focus_on_activate", group: "system", label: "Apps que pedem atenção ganham o foco", type: "switch" },
        { key: "misc:vrr", group: "system", label: "Taxa variável (VRR / FreeSync)", type: "seg", options: [[0, "Desligada"], [1, "Sempre"], [2, "Só em tela cheia"]] },
        { key: "cursor:inactive_timeout", group: "system", label: "Esconder o cursor parado (0 = nunca)", type: "slider", from: 0, to: 30, suffix: " s" },
        { key: "cursor:hide_on_key_press", group: "system", label: "Esconder o cursor ao digitar", type: "switch" },
        { key: "cursor:warp_on_change_workspace", group: "system", label: "Cursor vai para a janela ao trocar de workspace", type: "seg", options: [[0, "Não"], [1, "Sim"], [2, "Sempre"]] },
        { key: "cursor:no_hardware_cursors", group: "system", label: "Cursor por hardware", type: "seg", options: [[0, "Ligado"], [1, "Desligado"], [2, "Automático"]] },
        { key: "general:extend_border_grab_area", group: "shadow", label: "Área para agarrar a borda", type: "slider", from: 0, to: 40, suffix: " px", when: "general:resize_on_border" },
        { key: "general:allow_tearing", group: "system", label: "Permitir tearing (jogos, menos latência)", type: "switch" },
        { key: "misc:enable_swallow", group: "system", label: "Terminal engole o app que abre (swallow)", type: "switch" },
        { key: "misc:animate_manual_resizes", group: "system", label: "Animar ao redimensionar com o mouse", type: "switch" },
        { key: "misc:close_special_on_empty", group: "system", label: "Fechar o workspace especial quando esvaziar", type: "switch" },
        { key: "misc:disable_hyprland_logo", group: "system", label: "Esconder o logo do Hyprland", type: "switch" },
        { key: "misc:disable_splash_rendering", group: "system", label: "Esconder a frase de abertura", type: "switch" },
        { key: "misc:mouse_move_enables_dpms", group: "system", label: "Mexer o mouse acorda a tela", type: "switch" },
        { key: "misc:key_press_enables_dpms", group: "system", label: "Apertar uma tecla acorda a tela", type: "switch" },
        { key: "misc:middle_click_paste", group: "mouse", label: "Colar com o botão do meio", type: "switch" },
        { key: "xwayland:force_zero_scaling", group: "system", label: "Apps X11 nítidos (sem escala borrada)", type: "switch" },
        { key: "group:auto_group", group: "layout", label: "Agrupar janelas arrastadas sobre outra", type: "switch" },
        { key: "binds:workspace_back_and_forth", group: "layout", label: "Repetir o atalho do workspace volta ao anterior", type: "switch" },
        { key: "binds:allow_workspace_cycles", group: "layout", label: "Permitir ciclo entre workspaces", type: "switch" },
        { key: "render:direct_scanout", group: "system", label: "Direct scanout (tela cheia sem composição)", type: "seg", options: [[0, "Não"], [1, "Sim"], [2, "Automático"]] },
        { key: "animations:enabled", group: "system", label: "Animações do Hyprland", type: "switch" }
    ]
    function opt(key) { return options.find(o => o.key === key) ?? null }
    readonly property var cfg: Settings.hyprCfg || ({})
    property var cur: ({})            // valores lidos do Hyprland
    property var monitors: []
    function value(key) { return cfg[key] !== undefined ? cfg[key] : cur[key] }
    function overridden(key) { return cfg[key] !== undefined }
    function set(key, v) { const c = Object.assign({}, cfg); c[key] = v; Settings.hyprCfg = c }
    function reset(key) { const c = Object.assign({}, cfg); delete c[key]; Settings.hyprCfg = c }
    function resetAll() { Settings.hyprCfg = ({}); Settings.hyprMonitor = ({}) }

    // ---- Lua para o quickshell-blur.lua / hyprctl eval ----
    function luaVal(v) {
        if (typeof v === "boolean") return v ? "true" : "false"
        if (typeof v === "number") return String(Math.round(v * 1000) / 1000)
        return '"' + String(v).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'
    }
    function tableOf(map) {
        const t = {}
        for (const k in map) {
            if (!opt(k)) continue
            const path = k.split(":")
            let o = t
            for (let i = 0; i < path.length - 1; i++) { o[path[i]] = o[path[i]] ?? {}; o = o[path[i]] }
            o[path[path.length - 1]] = map[k]
        }
        const ser = o => "{ " + Object.keys(o).map(k => k + " = " + (typeof o[k] === "object" ? ser(o[k]) : luaVal(o[k]))).join(", ") + " }"
        return Object.keys(t).length ? ser(t) : ""
    }
    function configLua() { const t = tableOf(cfg); return t ? "hl.config(" + t + ")" : "" }
    function monitorLua() {
        const m = Settings.hyprMonitor || {}
        if (!m.output) return ""
        const cur = monitors.find(x => x.name === m.output) ?? {}
        return 'hl.monitor({ output = ' + luaVal(m.output) + ', mode = ' + luaVal(m.mode || cur.mode || "preferred")
            + ', position = ' + luaVal(cur.x !== undefined ? cur.x + "x" + cur.y : "auto") + ', scale = ' + luaVal(m.scale || cur.scale || 1)
            + (m.transform !== undefined ? ', transform = ' + Math.round(m.transform) : (cur.transform ? ', transform = ' + cur.transform : '')) + ' })'
    }
    function autostartLua() {
        const l = (Settings.list(Settings.hyprAutostart)).filter(x => x && x.trim())
        if (!l.length) return ""
        return 'hl.on("hyprland.start", function()\n' + l.map(c => '    hl.exec_cmd(' + luaVal(c.trim()) + ')').join("\n") + '\nend)'
    }
    function lua() { return [configLua(), monitorLua(), autostartLua()].filter(x => x).join("\n") }

    // ---- leitura dos valores atuais ----
    readonly property string script: Qt.resolvedUrl("scripts/hyprget.py").toString().replace("file://", "")
    function refresh() { proc.running = false; proc.running = true }
    Process {
        id: proc
        command: ["python3", root.script].concat(root.options.map(o => o.key))
        stdout: StdioCollector { onStreamFinished: { try { const d = JSON.parse(text); root.monitors = d._monitors || []; delete d._monitors; root.cur = d } catch (e) {} } }
    }
}
