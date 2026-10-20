// Launcher de aplicativos: painel de vidro no centro (ou no topo) com busca; apps ordenados por uso (favoritos primeiro).
// Modos por prefixo (configuraveis): acoes, area de transferencia (com miniaturas), emoji, simbolos, conta, comando,
// web, atalhos do Hyprland, so apps. Sem prefixo tambem acha opcoes do shell (indice da janela de configuracoes).
// Abra/feche com:  qs -c mine ipc call launcher toggle     (Super + Space no Hyprland)
// Setas / Ctrl+N / Ctrl+P escolhem, Enter abre, Esc fecha. Configuracoes: pagina "Launcher".
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Scope {
    id: root
    property var geo: ({ launcher: null })   // resultado de Geometry.compute (vem do shell.qml)
    readonly property bool open: Settings.launcherOpen   // pedido do usuario
    property bool alive: false                            // janela existe (fica ate a animacao de saida terminar)
    property string query: ""
    property string pending: ""
    signal searchFor(string q)

    IpcHandler {
        target: "launcher"
        function toggle(): void { Settings.launcherOpen = !Settings.launcherOpen }
        function open(): void { Settings.launcherOpen = true }
        function close(): void { Settings.launcherOpen = false }
        function search(q: string): void { root.pending = q; Settings.launcherOpen = true; root.searchFor(q) }   // abre ja com o texto (ex.: "=2+2", ":fogo")
    }
    onOpenChanged: {
        if (open) { closeTimer.stop(); Settings.wpPickerOpen = false; Settings.homeOpen = false; query = ""; alive = true }
        else if (Settings.launcherDocked) closeTimer.restart()   // acoplado: espera a moldura recolher
        else alive = false                                        // flutuante: quem anima a saida e o Hyprland
    }
    Timer { id: closeTimer; interval: Motion.durationOf("launcher", true) + 80; onTriggered: root.alive = false }

    // ---- tamanho do conteudo (compartilhado: a moldura acoplada cresce ate ele) ----
    readonly property var list: root.results(root.query)
    readonly property int rows: Math.max(3, Settings.launcherRows)
    readonly property real rowH: Math.max(40, Settings.launcherIcon + 20)
    readonly property real shown: Math.min(list.length, rows)
    readonly property real contentTarget: 64 + (shown > 0 ? shown * rowH + 16 : 0)
    property real contentH: contentTarget
    Behavior on contentH { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    onContentHChanged: BarState.launcherDepth = contentH
    Component.onCompleted: BarState.launcherDepth = contentH

    // ---- busca ----
    function rank(e, q) {
        const n = (e.name ?? "").toLowerCase()
        let s = 0
        if (n === q) s = 1000
        else if (n.startsWith(q)) s = 800 - n.length
        else if (n.includes(" " + q)) s = 600 - n.length
        else if (n.includes(q)) s = 500 - n.indexOf(q)
        else if (Settings.launcherFuzzy) {
            let i = 0, gaps = 0, last = -1
            for (const ch of q) {   // subsequencia (ex.: "ffx" -> Firefox)
                const j = n.indexOf(ch, i)
                if (j < 0) { i = -1; break }
                if (last >= 0) gaps += j - last - 1
                last = j; i = j + 1
            }
            if (i >= 0) s = 300 - gaps
        }
        if (s === 0) {
            const extra = ((e.genericName ?? "") + " " + (e.comment ?? "") + " " + (e.keywords ?? []).join(" ")).toLowerCase()
            if (extra.includes(q)) s = 150
        }
        return s
    }
    // ---- resultados: apps e, com prefixo, outras coisas ----
    // item = { name, desc, icon (tema) | glyph (Ico) | big (emoji/simbolo) | thumb (imagem), keys (atalho), act, alt (clique direito), fav }
    // prefixos configuraveis na pagina Launcher (Settings.launcherPrefixes guarda so os trocados)
    readonly property var prefixDefaults: ({ actions: "/", clipboard: ";", emoji: ":", symbols: ".", math: "=", cmd: "$", web: "?", keys: "<", apps: ">", translate: "!" })
    readonly property var prefixLabels: [["actions", "ações"], ["clipboard", "área de transferência"], ["emoji", "emoji"], ["symbols", "símbolos"],
        ["math", "conta"], ["cmd", "comando"], ["web", "web"], ["keys", "atalhos"], ["translate", "traduzir"], ["apps", "só apps"]]
    readonly property var pfx: Object.assign({}, prefixDefaults, Settings.launcherPrefixes || {})
    readonly property var prefixes: prefixLabels.filter(x => pfx[x[0]]).map(x => [pfx[x[0]], x[1]])
    // o que aparece sem prefixo
    readonly property var dflt: Object.assign({ math: true, actions: true, settings: true, web: true }, Settings.launcherDefaults || {})
    readonly property string mode: {
        const t = query.replace(/^\s+/, "")
        let best = "", len = 0
        for (const k in pfx) { const p = pfx[k]; if (p && t.startsWith(p) && p.length > len) { best = k; len = p.length } }
        return best
    }
    readonly property string rest: mode ? query.replace(/^\s+/, "").slice(pfx[mode].length) : query
    function appItems(q) {
        q = q.trim().toLowerCase()
        const usage = Settings.launcherUsage ?? {}, favs = root.arr(Settings.launcherFavs), hidden = root.arr(Settings.launcherHidden)
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay && hidden.indexOf(e.id) < 0)
        const scored = []
        for (const e of apps) {
            const fav = favs.indexOf(e.id) >= 0
            const boost = Math.min(usage[e.id] ?? 0, 30) * 4 + (fav ? (q === "" ? 10000 - favs.indexOf(e.id) : 200) : 0)
            if (q === "") scored.push({ e: e, s: boost, fav: fav })
            else { const r = rank(e, q); if (r > 0) scored.push({ e: e, s: r + boost, fav: fav }) }
        }
        scored.sort((a, b) => b.s - a.s || (a.e.name ?? "").localeCompare(b.e.name ?? ""))
        return scored.map(x => ({ name: x.e.name, desc: x.e.comment || x.e.genericName || "", icon: x.e.icon, fav: x.fav,
                                  act: () => root.launch(x.e), alt: () => root.toggleFav(x.e.id), altHint: x.fav ? "tirar dos favoritos" : "favoritar" }))
    }
    function arr(v) { return Settings.list(v) }
    function toggleFav(id) { const l = arr(Settings.launcherFavs).slice(), i = l.indexOf(id); if (i >= 0) l.splice(i, 1); else l.push(id); Settings.launcherFavs = l }
    function norm(t) { return String(t).normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase() }
    // acoes com argumento (como no end4): "todo texto", "dark", "light", "wipeclipboard"
    function argActions(q) {
        const m = q.trim().match(/^(\S+)\s*(.*)$/)
        if (!m) return []
        const c = norm(m[1]), a = m[2].trim(), out = []
        if (c.length >= 2 && ("todo".startsWith(c) || "tarefa".startsWith(c)) && a !== "")
            out.push({ name: "Nova tarefa: " + a, desc: "Adiciona à lista da Agenda", glyph: "check", act: () => { Settings.homeTodo = Array.from(Settings.homeTodo ?? []).concat([{ text: a, done: false }]) } })
        if (c.length >= 2 && "dark".startsWith(c) && a === "") out.push({ name: "Tema escuro", desc: "Ação do shell", glyph: "themeAuto", act: () => Settings.themeMode = "dark" })
        if (c.length >= 2 && "light".startsWith(c) && a === "") out.push({ name: "Tema claro", desc: "Ação do shell", glyph: "themeAuto", act: () => Settings.themeMode = "light" })
        if (c.length >= 3 && ("wipeclipboard".startsWith(c) || "limparareadetransferencia".startsWith(c)) && a === "")
            out.push({ name: "Apagar todo o histórico da área de transferência", desc: "cliphist wipe", glyph: "trash", act: () => Quickshell.execDetached(["cliphist", "wipe"]) })
        return out
    }
    function actionItems(q) {
        const w = norm(q).trim().split(/\s+/).filter(x => x)
        return argActions(q).concat(Actions.list.filter(a => w.every(x => norm(a.name + " " + a.keys).includes(x)))
            .map(a => ({ name: a.name + (a.toggle ? (a.on() ? "  (ligado)" : "  (desligado)") : ""), desc: a.desc ?? "Ação do shell", glyph: a.icon, act: () => a.run() })))
    }
    // qalc (unidades, moedas, porcentagens): roda 30 ms depois de parar de digitar; a conta simples em JS continua instantanea
    property string qalcQ: ""
    property string qalcOut: ""
    readonly property string qalcWant: {
        const t = (mode === "math" ? rest : (mode === "" ? query : "")).trim()
        if (t === "" || t.length > 80 || !/[0-9]/.test(t)) return ""
        if (mode === "math") return t
        return /\d\s*[a-zA-Z°€$µ]+\s+(to|in|em|para)\s+[a-zA-Z€$°µ]+/i.test(t) || /%\s*(of|de)\s+\d/i.test(t) ? t : ""
    }
    onQalcWantChanged: { qalcT.stop(); if (qalcWant !== "") qalcT.start() }
    Timer { id: qalcT; interval: 30; onTriggered: { qalcProc.running = false; qalcProc.running = true } }
    Process {
        id: qalcProc
        command: ["qalc", "-t", root.qalcWant]
        property string asked: ""
        onStarted: asked = root.qalcWant
        stdout: StdioCollector { onStreamFinished: { root.qalcQ = qalcProc.asked; root.qalcOut = text.trim() } }
    }
    function qalcItem(t) {
        const o = qalcOut
        if (qalcQ !== t || o === "" || /error|warning|unknown/i.test(o) || o === t) return []
        return [{ name: "= " + o, desc: t + "  ·  Enter copia o resultado", glyph: "calc", act: () => { Quickshell.clipboardText = o } }]
    }
    function mathItems(q, forced) {
        const t = q.trim()
        const qi = qalcItem(t)
        if (qi.length) return qi
        if (t === "" || (!forced && !/[0-9]/.test(t)) || (!forced && !/[-+*/^%()]|sqrt|sin|cos|log/.test(t))) return []
        if (!/^[0-9a-z+\-*/%^().,\s]+$/i.test(t)) return []
        let ex = t.replace(/,/g, ".").replace(/\^/g, "**").replace(/\bpi\b/g, "Math.PI").replace(/\be\b/g, "Math.E")
            .replace(/\b(sqrt|sin|cos|tan|asin|acos|atan|abs|round|floor|ceil|log10|log2|exp|pow|min|max)\b/g, "Math.$1").replace(/\bln\b/g, "Math.log").replace(/\blog\b(?!\d)/g, "Math.log10")
        if (/[a-z]/i.test(ex.replace(/Math\.[a-zA-Z0-9]+/g, ""))) return []
        let v
        try { v = eval(ex) } catch (e) { return [] }
        if (typeof v !== "number" || !isFinite(v)) return []
        const out = Math.abs(v) >= 1e15 || (Math.abs(v) < 1e-6 && v !== 0) ? v.toExponential(6) : String(Math.round(v * 1e10) / 1e10)
        return [{ name: "= " + out.replace(".", ","), desc: t + "  ·  Enter copia o resultado", glyph: "calc", act: () => { Quickshell.clipboardText = out } }]
    }
    // area de transferencia (scripts/clip.py: imagens viram miniaturas); textos fixados ficam no topo
    readonly property string clipScript: Qt.resolvedUrl("scripts/clip.py").toString().replace("file://", "")
    property var clips: []
    Process {
        id: clipProc
        command: ["python3", root.clipScript, "list", "300"]
        stdout: StdioCollector { onStreamFinished: { try { root.clips = JSON.parse(text) } catch (e) { root.clips = [] } } }
    }
    onModeChanged: {
        if (mode === "clipboard") { clipProc.running = false; clipProc.running = true }
        if (mode === "keys" && !keysLoaded) { keysProc.running = false; keysProc.running = true }
    }
    function pinClip(t) { const l = arr(Settings.launcherClipPins).slice(), i = l.indexOf(t); if (i >= 0) l.splice(i, 1); else l.unshift(t); Settings.launcherClipPins = l }
    function clipItems(q) {
        const w = norm(q).trim(), pins = arr(Settings.launcherClipPins)
        const pinned = pins.filter(t => w === "" || norm(t).includes(w)).map(t => ({ name: t.replace(/\s+/g, " ").slice(0, 160), desc: "Fixado · clique direito solta", glyph: "tag",
            act: () => { Quickshell.clipboardText = t }, alt: () => root.pinClip(t), altHint: "soltar" }))
        const hist = clips.filter(c => w === "" || norm(c.text).includes(w)).slice(0, 80).map(c => {
            const img = c.img !== "" || /^\[\[ binary data/.test(c.text)
            const txt = c.text
            return { name: img ? "Imagem" : txt.replace(/\s+/g, " ").slice(0, 160), desc: img ? txt.replace(/^\[\[ binary data |\]\]$/g, "") : "Enter copia · clique direito fixa · Delete apaga",
                     glyph: img ? "image" : "cards", thumb: c.img,
                     act: () => Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", c.line]),
                     alt: img ? null : () => root.pinClip(txt), altHint: "fixar",
                     del: () => { Quickshell.execDetached(["python3", root.clipScript, "delete", c.line]); root.clips = root.clips.filter(x => x.line !== c.line) } }
        })
        return pinned.concat(hist)
    }
    // emoji e simbolos: copiar ou digitar no app (wtype, depois que o launcher fecha)
    function pick(text) {
        Quickshell.clipboardText = text
        if (Settings.launcherPick === "type") Quickshell.execDetached(["sh", "-c", 'sleep 0.25; wtype -- "$1"', "sh", text])
    }
    readonly property string pickHint: Settings.launcherPick === "type" ? "Enter digita no app" : "Enter copia"
    property var emojis: []
    FileView { id: emojiFile; path: Qt.resolvedUrl("assets/emoji.tsv").toString().replace("file://", ""); onLoaded: root.emojis = text().split("\n").map(l => l.split("\t")) }
    function emojiItems(q) {
        const w = norm(q).trim().split(/\s+/).filter(x => x)
        return emojis.filter(e => w.every(x => (e[1] ?? "").includes(x))).slice(0, 80)
            .map(e => ({ name: e[1], desc: root.pickHint, big: e[0], act: () => root.pick(e[0]) }))
    }
    property var symbols: []
    FileView { path: Qt.resolvedUrl("assets/symbols.tsv").toString().replace("file://", ""); onLoaded: root.symbols = text().split("\n").filter(l => l).map(l => l.split("\t")) }
    function symbolItems(q) {
        const w = norm(q).trim().split(/\s+/).filter(x => x)
        return symbols.filter(e => w.every(x => norm(e[1] ?? "").includes(x) || e[0] === x)).slice(0, 120)
            .map(e => ({ name: e[1].charAt(0).toUpperCase() + e[1].slice(1), desc: root.pickHint, big: e[0], act: () => root.pick(e[0]) }))
    }
    // atalhos do Hyprland (scripts/keybinds.py le a config em Lua)
    property var keybinds: []
    property bool keysLoaded: false
    Process {
        id: keysProc
        command: ["python3", Qt.resolvedUrl("scripts/keybinds.py").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { root.keybinds = JSON.parse(text); root.keysLoaded = true } catch (e) {} } }
    }
    function keyItems(q) {
        const w = norm(q).trim().split(/\s+/).filter(x => x)
        return keybinds.filter(k => w.every(x => norm(k.label + " " + k.keys + " " + k.section).includes(x)))
            .map(k => ({ name: k.label, desc: k.section, glyph: "keyboard", keys: k.keys, act: () => { Quickshell.clipboardText = k.keys } }))
    }
    // tradutor (trans): "!texto" traduz para o portugues; "!en texto" para o ingles (codigo de 2 letras no inicio)
    property string trIn: ""
    property string trOut: ""
    readonly property string trWant: mode === "translate" ? rest.trim() : ""
    onTrWantChanged: { if (trWant !== "") trT.restart(); else { trOut = ""; trIn = "" } }
    Timer { id: trT; interval: 450; onTriggered: { const m = /^([a-z]{2})\s+(.+)$/i.exec(root.trWant); trProc.lang = m ? m[1].toLowerCase() : "pt"; trProc.txt = m ? m[2] : root.trWant
        trProc.running = false; trProc.running = true } }
    Process {
        id: trProc
        property string lang: "pt"
        property string txt: ""
        command: ["trans", "-b", "-no-autocorrect", ":" + lang, txt]
        stdout: StdioCollector { onStreamFinished: { root.trIn = root.trWant; root.trOut = text.trim() } }
    }
    function translateItems() {
        if (trWant === "") return [{ name: "Digite um texto para traduzir", desc: "Para o português; comece com o código para outra língua (ex.: !en bom dia)", glyph: "earth", act: () => {} }]
        if (trIn !== trWant || trOut === "") return [{ name: "Traduzindo…", desc: trWant, glyph: "earth", act: () => {} }]
        return [{ name: trOut, desc: "Enter copia a tradução", glyph: "earth", act: () => { Quickshell.clipboardText = root.trOut } }]
    }
    // busca na web: %s no endereco vira o texto (senao vai no fim); sites excluidos viram -site:
    function webUrl(q) {
        const ex = (Settings.launcherExclude || []).filter(x => x).map(x => " -site:" + x).join("")
        const term = encodeURIComponent(q.trim() + ex), e = Settings.launcherEngine
        return e.indexOf("%s") >= 0 ? e.replace("%s", term) : e + term
    }
    function webItem(q) { return { name: "Buscar na web: " + q.trim(), desc: Settings.launcherEngine.replace(/https?:\/\//, "").split("/")[0], glyph: "web", act: () => Qt.openUrlExternally(root.webUrl(q)) } }
    function cmdItems(q) {
        const c = q.trim()
        if (c === "") return [{ name: "Digite um comando", desc: "Enter roda em segundo plano; a segunda opção abre no terminal", glyph: "send", act: () => {} }]
        return [{ name: "Executar: " + c, desc: "Em segundo plano (sem terminal)", glyph: "send", act: () => Quickshell.execDetached(["sh", "-c", c]) },
                { name: "Executar no terminal: " + c, desc: (Settings.launcherTerminal || "kitty") + " (fica aberto no fim)", glyph: "desktop",
                  act: () => Quickshell.execDetached([Settings.launcherTerminal || "kitty", "sh", "-c", c + '; echo; read -rp "[Enter fecha] " _']) }]
    }
    // opcoes do shell (indice da janela de configuracoes): abre direto no cartao
    property var settingsRef: null
    function settingItems(q) {
        if (!settingsRef) return []
        if (!settingsRef.index.length) return []   // o indice e montado ao abrir o launcher (onAliveChanged)
        const w = norm(q).trim().split(/\s+/).filter(x => x)
        if (!w.length) return []
        return settingsRef.index.filter(e => w.every(x => norm(e.label + " " + e.card + " " + e.desc + " " + e.pageLabel).includes(x))).slice(0, 4)
            .map(e => ({ name: e.label || e.card, desc: "Configurações › " + e.pageLabel + (e.label ? " › " + e.card : ""), glyph: "cog", act: () => root.settingsRef.show(e) }))
    }
    function results(query) {
        const t = query.trim(), r = rest
        switch (mode) {
        case "actions": return actionItems(r)
        case "clipboard": return clipItems(r)
        case "emoji": return emojiItems(r)
        case "symbols": return symbolItems(r)
        case "math": return mathItems(r, true)
        case "cmd": return cmdItems(r)
        case "web": return [webItem(r)]
        case "keys": return keyItems(r)
        case "translate": return translateItems()
        case "apps": return appItems(r)
        }
        const apps = appItems(t)
        if (t === "") return apps
        return (dflt.math ? mathItems(t, false) : []).concat(apps,
            dflt.actions && t.length >= 3 ? actionItems(t).slice(0, 3) : [],
            dflt.settings && t.length >= 3 ? settingItems(t) : [],
            dflt.web ? [webItem(t)] : [])
    }
    onAliveChanged: if (alive && dflt.settings && settingsRef && !settingsRef.index.length) settingsRef.buildIndex()
    function run(it) { if (!it) return; Settings.launcherOpen = false; it.act() }
    function launch(e) {
        if (!e) return
        const u = Object.assign({}, Settings.launcherUsage ?? {})
        u[e.id] = (u[e.id] ?? 0) + 1
        Settings.launcherUsage = u
        if (e.runInTerminal && e.command && e.command.length) Quickshell.execDetached({ command: [Settings.launcherTerminal || "kitty", "-e"].concat(Array.from(e.command)), workingDirectory: e.workingDirectory || "" })
        else e.execute()
    }

    // a janela e criada uma vez (ao iniciar) e so mostrada/escondida: criar na hora custava 1-2 quadros no inicio da animacao
    // (recriada so quando muda entre acoplado e flutuante, porque o nome da camada muda)
    property bool ready: true
    Connections { target: Settings; function onLauncherDockedChanged() { root.ready = false; Qt.callLater(() => root.ready = true) } }
    LazyLoader {
        active: root.ready

        PanelWindow {
            id: win
            // acoplado: fica sempre mapeada (so some o conteudo); flutuante: mapeia ao abrir, para o Hyprland animar a entrada
            visible: docked || root.alive
            mask: root.alive ? null : noInput
            Region { id: noInput }
            Component.onCompleted: contentItem.visible = Qt.binding(() => root.alive)
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.alive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            // flutuante: o Hyprland anima a janela; acoplado: sem animacao do Hyprland (quem anima e a moldura)
            WlrLayershell.namespace: docked ? "mine-launcher-docked" : "mine-launcher"

            // ---- geometria ----
            readonly property bool docked: Settings.launcherDocked
            readonly property string side: Settings.launcherSide
            readonly property bool vert: side === "left" || side === "right"
            readonly property real e: Settings.edge
            readonly property real cw: Math.min(Settings.launcherWidth, width - 100)   // largura do conteudo
            readonly property real ch: root.contentH                                    // altura do conteudo
            // progresso da moldura (so no modo acoplado; flutuante fica sempre aberto)
            readonly property real pp: docked ? BarState.launcherProg : 1

            readonly property var pk: root.geo.launcher
            // acoplado: retangulo do conteudo dentro da "barra" calculada pela moldura
            readonly property rect dbox: !pk ? Qt.rect(0, 0, 0, 0) : (
                side === "top" ? Qt.rect(pk.rect.x, pk.rect.y + e + 8, pk.rect.w, ch)
                : side === "bottom" ? Qt.rect(pk.rect.x, pk.rect.y + 12, pk.rect.w, ch)
                : side === "left" ? Qt.rect(pk.rect.x + e + 8, pk.rect.y, cw, pk.rect.h)
                : Qt.rect(pk.rect.x + 12, pk.rect.y, cw, pk.rect.h))
            // flutuante: centro ou topo
            readonly property rect fbox: Qt.rect((width - cw) / 2, Settings.launcherPos === "top" ? 110 : (height - ch) / 2 - 60, cw, ch)
            readonly property rect box: docked ? dbox : fbox

            // acoplado: parte visivel do painel (cresce da borda) recorta o conteudo, que sobe junto
            readonly property real fullDepth: docked && pk ? pk.t : 0
            readonly property real vis: docked ? Math.max(0, e + (fullDepth - e) * pp) : 0
            readonly property rect clipR: !docked || !pk ? Qt.rect(0, 0, 0, 0)
                : side === "top" ? Qt.rect(pk.rect.x, 0, pk.rect.w, vis)
                : side === "bottom" ? Qt.rect(pk.rect.x, height - vis, pk.rect.w, vis)
                : side === "left" ? Qt.rect(0, pk.rect.y, vis, pk.rect.h)
                : Qt.rect(width - vis, pk.rect.y, vis, pk.rect.h)
            readonly property real lag: docked ? fullDepth - vis : 0

            MouseArea { anchors.fill: parent; onClicked: Settings.launcherOpen = false }

            Item {
                id: holder
                x: win.docked ? win.clipR.x : 0
                y: win.docked ? win.clipR.y : 0
                width: win.docked ? win.clipR.width : win.width
                height: win.docked ? win.clipR.height : win.height
                clip: win.docked
                MouseArea { anchors.fill: parent; visible: win.docked }   // clique no painel nao fecha

                Item {
                    id: inner
                    x: -holder.x + (win.side === "left" ? -win.lag : (win.side === "right" ? win.lag : 0))
                    y: -holder.y + (win.side === "top" ? -win.lag : (win.side === "bottom" ? win.lag : 0))
                    width: win.width; height: win.height
                    opacity: win.docked ? Math.max(0, Math.min(1, win.pp * 4)) : 1

                    // ---- painel (conteudo) ----
                    Rectangle {
                        id: panel
                        x: win.box.x; y: win.box.y
                        width: win.box.width; height: win.box.height
                        radius: win.docked ? 0 : Settings.launcherRadius
                        color: win.docked ? "transparent" : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.glass ? Math.min(1, Settings.glassOpacityEff / 100 + 0.08) : 1)
                        border.width: win.docked ? 0 : 1; border.color: Theme.border
                                                clip: true
                        MouseArea { anchors.fill: parent }

                        // ---- campo de busca ----
                        Item {
                            id: bar
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: 64
                            Rectangle {
                                anchors { fill: parent; margins: 10 }
                                radius: Math.max(8, Settings.launcherRadius - 8)
                                color: Settings.glass ? Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, 0.7) : Theme.card
                            }
                            UiText {
                                id: glyph
                                anchors { left: parent.left; leftMargin: 28; verticalCenter: parent.verticalCenter }
                                text: "⌕"; color: Theme.accent; font.pixelSize: 22
                            }
                            TextInput {
                                font.family: Theme.font
                                id: input
                                anchors { left: glyph.right; leftMargin: 12; right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
                                color: Theme.text; font.pixelSize: 16
                                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                                clip: true
                                focus: true
                                Connections {
                                    target: root
                                    function onAliveChanged() { if (root.alive) { input.text = root.pending; root.pending = ""; view.currentIndex = 0; view.positionViewAtBeginning(); input.forceActiveFocus() } }
                                    function onSearchFor(q) { if (root.alive) { input.text = q; root.pending = "" } }
                                }
                                onTextChanged: { root.query = text; view.currentIndex = 0 }
                                UiText { visible: input.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "Buscar…"; color: Theme.muted; font.pixelSize: 16 }
                                // dicas dos prefixos (some ao digitar)
                                Row {
                                    id: chips
                                    // sem espaco para os nomes: so o caractere (o nome aparece ao passar o mouse)
                                    readonly property bool compact: parent.width < 820
                                    visible: input.text === "" && parent.width > 420
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    spacing: 4
                                    Repeater {
                                        model: root.prefixes
                                        delegate: Rectangle {
                                            required property var modelData
                                            height: 22; width: pt.implicitWidth + 12; radius: 6
                                            color: pm.containsMouse ? Theme.tint(0.2) : Theme.tint(0.08)
                                            UiText { id: pt; anchors.centerIn: parent; text: chips.compact && !pm.containsMouse ? modelData[0] : modelData[0] + " " + modelData[1]; color: pm.containsMouse ? Theme.text : Theme.muted; font.pixelSize: 10 }
                                            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { input.text = modelData[0]; input.forceActiveFocus() } }
                                        }
                                    }
                                }

                                Keys.onEscapePressed: Settings.launcherOpen = false
                                Keys.onDownPressed: view.currentIndex = Math.min(view.count - 1, view.currentIndex + 1)
                                Keys.onUpPressed: view.currentIndex = Math.max(0, view.currentIndex - 1)
                                Keys.onTabPressed: view.currentIndex = (view.currentIndex + 1) % Math.max(1, view.count)
                                Keys.onReturnPressed: root.run(root.list[view.currentIndex])
                                Keys.onEnterPressed: root.run(root.list[view.currentIndex])
                                Keys.onPressed: e => {
                                    const it = root.list[view.currentIndex]
                                    if (e.key === Qt.Key_Delete && it && it.del) { it.del(); e.accepted = true; return }
                                    if ((e.key === Qt.Key_Menu || (e.key === Qt.Key_F10 && (e.modifiers & Qt.ShiftModifier))) && it && it.alt) { it.alt(); e.accepted = true; return }
                                    if (e.modifiers & Qt.ControlModifier) {
                                        if (e.key === Qt.Key_N || e.key === Qt.Key_J) { view.currentIndex = Math.min(view.count - 1, view.currentIndex + 1); e.accepted = true }
                                        else if (e.key === Qt.Key_P || e.key === Qt.Key_K) { view.currentIndex = Math.max(0, view.currentIndex - 1); e.accepted = true }
                                    }
                                }
                            }
                        }

                        // ---- resultados ----
                        ListView {
                            id: view
                            anchors { left: parent.left; right: parent.right; top: bar.bottom; bottom: parent.bottom; leftMargin: 10; rightMargin: 10; bottomMargin: 10 }
                            model: root.list
                            clip: true
                            interactive: false
                            currentIndex: 0
                            highlightMoveDuration: 90
                            boundsBehavior: Flickable.StopAtBounds
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: e => { view.contentY = Math.max(0, Math.min(Math.max(0, view.contentHeight - view.height), view.contentY - e.angleDelta.y)) }
                            }

                            delegate: Rectangle {
                                id: row
                                required property int index
                                required property var modelData
                                readonly property bool cur: ListView.isCurrentItem
                                width: ListView.view.width
                                height: root.rowH
                                radius: Math.max(8, Settings.launcherRadius - 8)
                                color: cur ? Theme.cardHi : "transparent"
                                Rectangle {
                                    visible: row.cur
                                    width: 3; height: parent.height * 0.5; radius: 2; color: Theme.accent
                                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                }
                                Item {
                                    id: ico
                                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                                    width: Settings.launcherIcon; height: width
                                    Image {
                                        anchors.fill: parent
                                        visible: !!row.modelData.icon
                                        sourceSize: Qt.size(width * 2, height * 2)
                                        source: row.modelData.icon ? Icons.path(row.modelData.icon, "application-x-executable") : ""
                                        asynchronous: true
                                        smooth: true
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: width * 0.3
                                        visible: !!row.modelData.glyph
                                        color: Theme.tint(0.16)
                                        UiIcon { anchors.centerIn: parent; name: row.modelData.glyph ?? ""; size: parent.width * 0.55; color: Theme.accent }
                                    }
                                    UiText { anchors.centerIn: parent; visible: !!row.modelData.big; text: row.modelData.big ?? ""; font.pixelSize: parent.width * 0.85; color: Theme.text }
                                    RoundImage {
                                        visible: !!row.modelData.thumb
                                        anchors.centerIn: parent
                                        width: parent.width * 1.6; height: parent.height; radius: 6
                                        source: row.modelData.thumb ? "file://" + row.modelData.thumb : ""
                                        sourceSize: Qt.size(160, 100)
                                    }
                                }
                                // favorito / atalho (teclas) no canto direito
                                Row {
                                    id: tail
                                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                    spacing: 4
                                    UiIcon { visible: !!row.modelData.fav; name: "sparkle"; size: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                                    Repeater {
                                        model: row.modelData.keys ? row.modelData.keys.split(" + ") : []
                                        delegate: Rectangle {
                                            required property string modelData
                                            height: 22; width: Math.max(22, kt.implicitWidth + 12); radius: 6
                                            color: Theme.track; border.width: 1; border.color: Theme.border
                                            UiText { id: kt; anchors.centerIn: parent; text: modelData; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                                        }
                                    }
                                }
                                Column {
                                    anchors { left: ico.right; leftMargin: row.modelData.thumb ? 14 + ico.width * 0.3 : 14; right: tail.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 1
                                    UiText { width: parent.width; text: row.modelData.name; color: Theme.text; font.pixelSize: 15; font.weight: Font.Medium; elide: Text.ElideRight }
                                    UiText {
                                        visible: text !== ""
                                        width: parent.width
                                        text: row.modelData.desc ?? ""
                                        color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onEntered: view.currentIndex = row.index
                                    onClicked: m => { if (m.button === Qt.RightButton) { if (row.modelData.alt) row.modelData.alt() } else root.run(row.modelData) }
                                }
                            }
                        }

                        UiText {
                            visible: root.list.length === 0 && input.text !== ""
                            anchors { horizontalCenter: parent.horizontalCenter; top: bar.bottom; topMargin: 6 }
                            text: "Nada encontrado"; color: Theme.muted; font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
