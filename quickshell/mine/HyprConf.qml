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
        { key: "input:natural_scroll", group: "mouse", label: "Rolagem natural", type: "switch" },
        { key: "misc:focus_on_activate", group: "system", label: "Apps que pedem atenção ganham o foco", type: "switch" },
        { key: "misc:vrr", group: "system", label: "Taxa variável (VRR / FreeSync)", type: "seg", options: [[0, "Desligada"], [1, "Sempre"], [2, "Só em tela cheia"]] },
        { key: "cursor:inactive_timeout", group: "system", label: "Esconder o cursor parado (0 = nunca)", type: "slider", from: 0, to: 30, suffix: " s" }
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
            + ', position = ' + luaVal(cur.x !== undefined ? cur.x + "x" + cur.y : "auto") + ', scale = ' + luaVal(m.scale || cur.scale || 1) + ' })'
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
