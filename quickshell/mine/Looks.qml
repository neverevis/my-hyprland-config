// Visuais (presets do shell inteiro): o que cada um guarda e escolhido por grupos (widgets, wallpaper, barras, cores,
// animacoes, paineis, tela de bloqueio, Hyprland, fontes). O que e pessoal nunca entra (cidade do clima, apps fixados,
// tarefas, historico do launcher, inatividade...). Os "layouts prontos" (so widgets) continuam no DeskState.
// Aplicar guarda o visual de antes: Looks.undo() volta. Exportar gera um .zip com o wallpaper e as imagens usadas;
// importar aceita so as chaves conhecidas (scripts/looks.py).
// IPC: qs -c mine ipc call looks apply <nome> | undo | save <nome> | list | export <nome> | scan | import <zip>
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var groups: [
        { id: "widgets", label: "Widgets", icon: "dashboard", def: true,
          keys: ["desktopWidgets", "desktopOn", "desktopCardStyle", "desktopCard", "desktopShadow", "desktopTone", "desktopToneColor"] },
        { id: "wallpaper", label: "Wallpaper", icon: "wallpaper", def: true,
          keys: ["wallpaper", "wpTransition", "wpDuration", "wpEasing", "wpWipeAngle", "wpParallax"] },
        { id: "bars", label: "Barras e moldura", icon: "bars", def: true,
          keys: ["bars", "edge", "cornerRadius", "fillet", "topRadius", "outline", "barsPanelMode", "hideDelay", "showDelay"] },
        { id: "colors", label: "Cores e vidro", icon: "palette", def: true,
          keys: ["themeOn", "themeMode", "themeSource", "themePreset", "themeVariant", "userAccent", "userBarColor", "userTextColor",
                 "glass", "glassOpacity", "glassAuto", "shellBlur", "shellGrain", "shellIgnoreAlpha",
                 "themeBorders", "themeBorderA", "themeBorderB", "themeBorderIn", "themeBorderAngle", "themeBorderAlpha", "themeBorderInAlpha"] },
        { id: "anims", label: "Animações", icon: "animation", def: true, keys: ["animCfg"] },
        { id: "panels", label: "Painéis e composição", icon: "frame", def: true,
          keys: ["launcherDocked", "launcherSide", "launcherPos", "launcherOffset", "launcherFillet", "launcherRadius", "launcherWidth", "launcherRows", "launcherIcon",
                 "homeDocked", "homeSide", "homeOffset", "homeFillet", "homeRadius",
                 "wpPickerDocked", "wpPickerSide", "wpPickerOffset", "wpPickerFillet", "wpPickerRadius", "wpPickerGap", "wpPickerCount", "wpCardRadius",
                 "notifDocked", "notifSide", "notifAnchor", "notifCorner", "notifFillet", "notifRadius", "notifWidth",
                 "osdDocked", "osdSide"] },
        { id: "lock", label: "Tela de bloqueio", icon: "lock", def: true, keys: ["lockBlur", "lockDim", "lockMedia", "lockSeconds", "lockClock", "lockClockPos", "lockChars", "lockWallpaper"] },
        { id: "hypr", label: "Hyprland (blur)", icon: "blur", def: false,
          keys: ["blurManaged", "blurEnabled", "blurSize", "blurPasses", "blurNoise", "blurContrast", "blurBrightness", "blurVibrancy"] },
        { id: "fonts", label: "Fontes", icon: "textBox", def: false, keys: ["fontUi", "fontMono"] }
    ]
    readonly property var allKeys: groups.reduce((a, g) => a.concat(g.keys), [])
    function group(id) { return groups.find(g => g.id === id) ?? null }
    function groupsOf(data) { return groups.filter(g => g.keys.some(k => data && data[k] !== undefined)).map(g => g.id) }
    // presets antigos guardavam as cores calculadas (so leitura)
    readonly property var legacy: ({ accent: "userAccent", barColor: "userBarColor", textColor: "userTextColor" })

    readonly property var list: (Settings.presets || []).map(p => Object.assign({ groups: groupsOf(p.data) }, p))
    property string current: ""
    property var undoData: null
    property string undoName: ""
    property string lastError: ""

    function clone(v) { return v === undefined ? undefined : JSON.parse(JSON.stringify(v)) }
    function snapshot(gids) {
        const d = {}
        for (const g of groups) if (gids.indexOf(g.id) >= 0) for (const k of g.keys) if (Settings[k] !== undefined) d[k] = clone(Settings[k])
        return d
    }
    function uniqueName(base) {
        const taken = n => (Settings.presets || []).some(p => p.name === n) || DeskState.builtins.some(p => p.name === n)
        let n = base, i = 2
        while (taken(n)) n = base + " " + i++
        return n
    }
    function defaultGroups() { return groups.filter(g => g.def).map(g => g.id) }
    function save(name, gids) {
        name = uniqueName((name || "").trim() || "Meu visual")
        const l = clone(Settings.presets || [])
        l.push({ name: name, created: Date.now(), data: snapshot(gids && gids.length ? gids : defaultGroups()) })
        Settings.presets = l
        current = name
        return name
    }
    function overwrite(name) {
        const l = clone(Settings.presets || []), p = l.find(x => x.name === name)
        if (!p) return
        p.data = snapshot(groupsOf(p.data)); p.created = Date.now()
        Settings.presets = l
    }
    function rename(name, to) {
        to = (to || "").trim()
        if (!to || to === name || list.some(p => p.name === to) || DeskState.builtins.some(p => p.name === to)) return name
        const l = clone(Settings.presets || []), p = l.find(x => x.name === name)
        if (p) p.name = to
        Settings.presets = l
        if (current === name) current = to
        return to
    }
    function remove(name) { Settings.presets = (Settings.presets || []).filter(p => p.name !== name) }
    function setGroups(name, gids) {   // tira grupos de um visual salvo (para acrescentar e preciso salvar de novo)
        const l = clone(Settings.presets || []), p = l.find(x => x.name === name)
        if (!p) return
        const keep = {}
        for (const g of groups) if (gids.indexOf(g.id) >= 0) for (const k of g.keys) if (p.data[k] !== undefined) keep[k] = p.data[k]
        p.data = keep
        Settings.presets = l
    }

    // aplica so as chaves conhecidas; guarda o estado de antes para desfazer
    function applyData(d, label) {
        const keys = Object.keys(d || {}).map(k => legacy[k] ?? k).filter(k => allKeys.indexOf(k) >= 0)
        if (!keys.length) return false
        const before = {}
        for (const k of keys) before[k] = clone(Settings[k])
        undoData = before; undoName = label
        for (const k0 of Object.keys(d)) {
            const k = legacy[k0] ?? k0
            if (allKeys.indexOf(k) < 0) continue
            if (k === "wallpaper") { if (d[k0] && d[k0] !== Settings.wallpaper) Settings.wallpaper = d[k0]; continue }
            if (Settings[k] === undefined) continue
            Settings[k] = clone(d[k0])
        }
        return true
    }
    function apply(name) {
        const p = (Settings.presets || []).find(x => x.name === name) ?? DeskState.builtins.find(x => x.name === name)
        if (!p) return false
        applyData(p.data || {}, name)
        current = name
        DeskState.lastApplied = name
        undoT.restart()
        return true
    }
    function undo() {
        if (!undoData) return
        const d = undoData
        undoData = null
        for (const k of Object.keys(d)) {
            if (k === "wallpaper") { if (d[k]) Settings.wallpaper = d[k]; continue }
            Settings[k] = clone(d[k])
        }
        current = ""; DeskState.lastApplied = ""
    }
    Timer { id: undoT; interval: 60000; onTriggered: root.undoData = null }   // o desfazer vale por um minuto

    // ---------------- exportar / importar (.zip) ----------------
    readonly property string script: Qt.resolvedUrl("scripts/looks.py").toString().replace("file://", "")
    readonly property string tmpJson: Quickshell.env("HOME") + "/.cache/quickshell-mine/look-export.json"
    property var found: []        // .zip de visuais achados (Downloads, pasta pessoal, pasta de wallpapers)
    property string busy: ""
    signal done(string msg)
    FileView { id: tmpFile; path: root.tmpJson }
    function exportZip(name) {
        const p = (Settings.presets || []).find(x => x.name === name)
        if (!p || busy) return
        tmpFile.setText(JSON.stringify({ app: "quickshell-mine", version: 1, name: p.name, created: p.created, data: p.data }))
        busy = "export"
        proc.command = ["python3", script, "export", tmpJson]
        proc.running = true
    }
    function scan() { if (busy) return; busy = "scan"; proc.command = ["python3", script, "scan", Settings.wpDir]; proc.running = true }
    function importZip(path) {
        if (busy) return
        busy = "import"
        proc.command = ["python3", script, "import", path, Settings.wpDir, JSON.stringify(allKeys.concat(Object.keys(legacy)))]
        proc.running = true
    }
    Process {
        id: proc
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: code => {
            const what = root.busy
            root.busy = ""
            if (code !== 0) { root.lastError = err.text.trim().split("\n").pop() || ("erro " + code); root.done("Falhou: " + root.lastError); return }
            let r = {}
            try { r = JSON.parse(out.text) } catch (e) { root.done("Falhou: resposta invalida"); return }
            if (what === "scan") { root.found = r.files || []; return }
            if (what === "export") { root.done("Exportado em " + r.path); Quickshell.execDetached(["notify-send", "-a", "Quickshell", "Visual exportado", r.path]); return }
            if (what === "import") {
                const l = root.clone(Settings.presets || [])
                const name = root.uniqueName(r.name || "Importado")
                l.push({ name: name, created: Date.now(), imported: true, data: r.data })
                Settings.presets = l
                root.done("Importado como “" + name + "”" + (r.missing && r.missing.length ? " (faltaram " + r.missing.length + " arquivo(s))" : ""))
                root.scan()
            }
        }
    }

    IpcHandler {
        target: "looks"
        function apply(name: string): bool { return root.apply(name) }
        function undo(): void { root.undo() }
        function save(name: string): string { return root.save(name, root.defaultGroups()) }
        function list(): string { return JSON.stringify(root.list.map(p => ({ name: p.name, groups: p.groups }))) }
        function exportZip(name: string): void { root.exportZip(name) }
        function scan(): string { root.scan(); return JSON.stringify(root.found) }
        function importZip(path: string): void { root.importZip(path) }
        function remove(name: string): void { root.remove(name) }
    }
}
