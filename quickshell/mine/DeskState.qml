// Area de trabalho: catalogo de widgets, edicao do layout e presets (o visual inteiro salvo com um nome).
// Os widgets ficam em Settings.desktopWidgets (cada um com id, type, fx, fy, cols, rows, opts): fx/fy = posicao de 0 a 1
// dentro da area livre da tela; cols/rows = tamanho em celulas da grade). Ao aplicar um preset, quem ja existe
// desliza/muda de forma ate o novo lugar (DesktopLayer anima x, y, largura e altura).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool peek: false             // traz a camada para a frente das janelas (para conferir/capturar)
    property bool editing: false          // modo de edicao (arrastar, trocar tamanho, remover)
    property string dragging: ""          // id do widget sendo arrastado (para as guias)
    readonly property real cell: 150      // lado de uma celula da grade
    readonly property real gap: 14        // espaco entre celulas
    function px(n) { return n * cell + (n - 1) * gap }

    readonly property var catalog: [
        { type: "clock", name: "Relógio", icon: "clock", desc: "Hora e data; digital ou com ponteiros.", sizes: [[2, 1], [1, 1], [2, 2], [3, 1]] },
        { type: "media", name: "Mídia", icon: "music", desc: "Capa, música tocando e controles.", sizes: [[2, 1], [3, 1], [2, 2], [1, 1]] },
        { type: "system", name: "Sistema", icon: "chip", desc: "CPU, memória, disco e tempo ligado.", sizes: [[2, 1], [1, 1], [2, 2]] },
        { type: "calendar", name: "Calendário", icon: "calendar", desc: "O mês, com o dia de hoje marcado.", sizes: [[2, 2], [1, 1], [2, 1]] },
        { type: "user", name: "Usuário", icon: "account", desc: "Sua foto, saudação e tempo ligado.", sizes: [[2, 1], [3, 1], [1, 1]] },
        { type: "notes", name: "Notas", icon: "pencil", desc: "Um bloco de notas que fica salvo.", sizes: [[2, 2], [2, 1], [3, 2], [1, 1]] }
    ]
    function info(type) { return catalog.find(c => c.type === type) ?? catalog[0] }

    function find(id) { return (Settings.desktopWidgets || []).find(w => w.id === id) ?? null }
    function mutate(fn) {
        const list = JSON.parse(JSON.stringify(Settings.desktopWidgets || []))
        fn(list)
        Settings.desktopWidgets = list
    }
    function add(type) {
        const c = info(type)
        const id = type + "-" + Date.now().toString(36)
        // um lugar ainda livre, em cascata a partir do canto de cima a esquerda
        const n = (Settings.desktopWidgets || []).length
        mutate(l => l.push({ id: id, type: type, fx: 0.04 + (n % 5) * 0.06, fy: 0.06 + (n % 5) * 0.08, cols: c.sizes[0][0], rows: c.sizes[0][1], opts: {} }))
        editing = true
        return id
    }
    function remove(id) { mutate(l => { const i = l.findIndex(w => w.id === id); if (i >= 0) l.splice(i, 1) }) }
    function setPos(id, fx, fy) { mutate(l => { const w = l.find(x => x.id === id); if (w) { w.fx = fx; w.fy = fy } }) }
    function setOpt(id, k, v) { mutate(l => { const w = l.find(x => x.id === id); if (w) { w.opts = w.opts || {}; w.opts[k] = v } }) }
    function cycleSize(id) {
        mutate(l => {
            const w = l.find(x => x.id === id)
            if (!w) return
            const s = info(w.type).sizes
            const i = s.findIndex(z => z[0] === w.cols && z[1] === w.rows)
            const n = s[(i + 1) % s.length]
            w.cols = n[0]; w.rows = n[1]
        })
    }
    function bringToFront(id) { mutate(l => { const i = l.findIndex(w => w.id === id); if (i >= 0 && i < l.length - 1) l.push(l.splice(i, 1)[0]) }) }

    // ---------------- presets ----------------
    // o que um preset guarda (o "visual" do shell); o resto das configuracoes fica como esta
    readonly property var presetKeys: ["desktopWidgets", "desktopCard", "bars", "edge", "cornerRadius", "fillet", "topRadius", "outline",
        "glass", "glassOpacity", "shellBlur", "shellGrain", "accent", "barColor", "textColor",
        "themeOn", "themeMode", "themeSource", "themePreset", "themeVariant", "wallpaper"]
    // layouts prontos (so mudam os widgets): bons pontos de partida
    readonly property var builtins: [
        { name: "Painel lateral", builtin: true, icon: "view_column", data: { desktopWidgets: [
            { id: "b-clock", type: "clock", fx: 0.03, fy: 0.05, cols: 2, rows: 1, opts: {} },
            { id: "b-user", type: "user", fx: 0.03, fy: 0.30, cols: 2, rows: 1, opts: {} },
            { id: "b-media", type: "media", fx: 0.03, fy: 0.55, cols: 2, rows: 1, opts: {} },
            { id: "b-system", type: "system", fx: 0.03, fy: 0.80, cols: 2, rows: 1, opts: {} }] } },
        { name: "Centro", builtin: true, icon: "alignCenter", data: { desktopWidgets: [
            { id: "b-clock", type: "clock", fx: 0.5, fy: 0.22, cols: 3, rows: 1, opts: {} },
            { id: "b-media", type: "media", fx: 0.5, fy: 0.62, cols: 3, rows: 1, opts: {} }] } },
        { name: "Canto", builtin: true, icon: "arrow_bottom_right", data: { desktopWidgets: [
            { id: "b-clock", type: "clock", fx: 0.97, fy: 0.08, cols: 1, rows: 1, opts: { style: "analog" } },
            { id: "b-calendar", type: "calendar", fx: 0.97, fy: 0.55, cols: 2, rows: 2, opts: {} },
            { id: "b-system", type: "system", fx: 0.97, fy: 0.97, cols: 2, rows: 1, opts: {} }] } },
        { name: "Mesa", builtin: true, icon: "dashboard", data: { desktopWidgets: [
            { id: "b-user", type: "user", fx: 0.05, fy: 0.08, cols: 3, rows: 1, opts: {} },
            { id: "b-clock", type: "clock", fx: 0.95, fy: 0.08, cols: 2, rows: 2, opts: { style: "analog" } },
            { id: "b-notes", type: "notes", fx: 0.05, fy: 0.9, cols: 2, rows: 2, opts: {} },
            { id: "b-media", type: "media", fx: 0.5, fy: 0.92, cols: 2, rows: 2, opts: {} },
            { id: "b-calendar", type: "calendar", fx: 0.95, fy: 0.9, cols: 2, rows: 2, opts: {} }] } },
        { name: "Limpo", builtin: true, icon: "broom", data: { desktopWidgets: [] } }
    ]
    readonly property var all: builtins.concat(Settings.presets || [])
    property string lastApplied: ""

    function snapshot() {
        const d = {}
        for (const k of presetKeys) if (Settings[k] !== undefined) d[k] = JSON.parse(JSON.stringify(Settings[k]))
        return d
    }
    function uniqueName(base) {
        let n = base, i = 2
        while (all.find(p => p.name === n)) n = base + " " + i++
        return n
    }
    function save(name) {
        name = uniqueName((name || "").trim() || "Meu preset")
        const list = JSON.parse(JSON.stringify(Settings.presets || []))
        list.push({ name: name, created: Date.now(), data: snapshot() })
        Settings.presets = list
        lastApplied = name
        return name
    }
    function overwrite(name) {
        const list = JSON.parse(JSON.stringify(Settings.presets || []))
        const p = list.find(x => x.name === name)
        if (!p) return
        p.data = snapshot(); p.created = Date.now()
        Settings.presets = list
    }
    function rename(name, to) {
        to = (to || "").trim()
        if (!to || to === name || all.find(p => p.name === to)) return name
        const list = JSON.parse(JSON.stringify(Settings.presets || []))
        const p = list.find(x => x.name === name)
        if (p) p.name = to
        Settings.presets = list
        if (lastApplied === name) lastApplied = to
        return to
    }
    function removePreset(name) { Settings.presets = (Settings.presets || []).filter(p => p.name !== name) }
    function apply(name) {
        const p = all.find(x => x.name === name)
        if (!p) return
        const d = p.data || {}
        // widgets que existem nos dois lados (mesmo id) deslizam ate o novo lugar; os outros entram/saem com fade
        for (const k of Object.keys(d)) {
            if (k === "wallpaper") { if (d[k] && d[k] !== Settings.wallpaper) Settings.wallpaper = d[k]; continue }
            if (Settings[k] === undefined) continue
            Settings[k] = JSON.parse(JSON.stringify(d[k]))
        }
        lastApplied = name
    }

    IpcHandler {
        target: "desktop"
        function edit(): void { root.editing = !root.editing }
        function preset(name: string): void { root.apply(name) }
        function toggle(): void { Settings.desktopOn = !Settings.desktopOn }
        function peek(): void { root.peek = !root.peek }
    }
}
