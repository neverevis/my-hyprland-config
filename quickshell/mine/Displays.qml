// Monitores (Configuracoes > Monitores): lista do hyprctl, aplicar resolucao / taxa / escala / giro / posicao com a pergunta
// "ficou bom?" (volta sozinho em 15 s). As mudancas ficam em Settings.hyprMonitors (por monitor; o antigo Settings.hyprMonitor,
// de um monitor so, continua valendo e e migrado quando o monitor e mexido) e o HyprSync aplica ao vivo.
// So le o hyprctl com a pagina aberta (use() / release()). Modo de teste (SysAct.dry): nada e gravado nem aplicado, so logado.
// IPC (so em teste): qs -c mine ipc call displays apply <monitor> <mode|scale|transform|x|y> <valor>
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var mons: []          // [{ name, desc, w, h, lw, lh, x, y, scale, transform, mode, modes, vrr, disabled, focused }]
    property int users: 0
    function use() { users++; refresh() }
    function release() { users = Math.max(0, users - 1) }
    function refresh() { if (!lister.running) lister.running = true }
    Process {
        id: lister
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const out = JSON.parse(text).map(m => {
                    const odd = (m.transform ?? 0) % 2 === 1
                    const lw = Math.round((odd ? m.height : m.width) / (m.scale || 1)), lh = Math.round((odd ? m.width : m.height) / (m.scale || 1))
                    return { name: m.name, desc: [m.make, m.model].filter(x => x && x !== "").join(" ") || m.description || "", w: m.width, h: m.height, lw: lw, lh: lh,
                        x: m.x, y: m.y, scale: m.scale, transform: m.transform ?? 0, mode: m.width + "x" + m.height + "@" + Number(m.refreshRate).toFixed(2) + "Hz",
                        modes: m.availableModes || [], vrr: !!m.vrr, disabled: !!m.disabled, focused: !!m.focused }
                })
                if (JSON.stringify(out) !== JSON.stringify(root.mons)) root.mons = out
            } catch (e) { console.warn("Displays: hyprctl invalido", e) }
        } }
    }
    Timer { id: refreshT; interval: 1100; onTriggered: root.refresh() }

    // ---- aplicar + pergunta ----
    property var before: null      // { legacy, map, live } para voltar
    property string pending: ""    // monitor em teste
    property int secsLeft: 0
    Timer { interval: 1000; repeat: true; running: root.secsLeft > 0; onTriggered: { root.secsLeft--; if (root.secsLeft === 0) root.revert() } }
    function clone(o) { return JSON.parse(JSON.stringify(o || {})) }
    function find(name) { return mons.find(m => m.name === name) ?? null }
    function apply(name, patch) {
        const cur = find(name)
        if (!cur) return
        if (secsLeft > 0) keep()   // outra mudanca no meio: a anterior vira definitiva
        before = { legacy: clone(Settings.hyprMonitor), map: clone(Settings.hyprMonitors), live: Object.assign({}, cur) }
        pending = name
        secsLeft = 15
        if (!SysAct.real("monitor " + name + " " + JSON.stringify(patch))) return
        const legacy = Settings.hyprMonitor || {}
        const map = clone(Settings.hyprMonitors)
        const base = map[name] ?? (legacy.output === name ? { mode: legacy.mode, scale: legacy.scale, transform: legacy.transform } : {})
        map[name] = Object.assign({ mode: cur.mode, scale: cur.scale, transform: cur.transform }, base, patch)
        if (legacy.output === name) Settings.hyprMonitor = ({})
        Settings.hyprMonitors = map
        refreshT.restart()
    }
    function keep() { secsLeft = 0; before = null; pending = "" }
    function revert() {
        const b = before
        secsLeft = 0; before = null; pending = ""
        if (!b) return
        if (!SysAct.real("monitor: voltar as configuracoes")) return
        Settings.hyprMonitor = b.legacy; Settings.hyprMonitors = b.map
        // aplica na hora o que era (o arquivo gerado so e relido no proximo reload)
        const l = b.live
        revertProc.command = ["hyprctl", "eval", 'hl.monitor({ output = "' + l.name + '", mode = "' + l.mode + '", position = "' + Math.round(l.x) + "x" + Math.round(l.y) + '", scale = ' + l.scale + ", transform = " + l.transform + " })"]
        revertProc.running = true
        refreshT.restart()
    }
    Process { id: revertProc }

    IpcHandler {
        target: "displays"
        function apply(name: string, key: string, value: string): string {
            if (!SysAct.dry) return "so no modo de teste"
            const p = {}; p[key] = key === "mode" ? value : Number(value)
            root.apply(name, p); return "ok"
        }
        function keep(): void { root.keep() }
        function revert(): void { root.revert() }
        function left(): string { return String(root.secsLeft) }
    }
}
