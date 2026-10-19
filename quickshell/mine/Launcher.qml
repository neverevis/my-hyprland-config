// Launcher de aplicativos: painel de vidro no centro (ou no topo) com busca; apps ordenados por uso.
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
        else {
            let i = 0, gaps = 0, last = -1
            for (const ch of q) {   // subsequencia (ex.: "ffx" -> Firefox)
                const j = n.indexOf(ch, i)
                if (j < 0) { i = -1; break }
                if (last >= 0) gaps += j - last - 1
                last = j; i = j + 1
            }
            if (i >= 0) s = 300 - gaps
            else {
                const extra = ((e.genericName ?? "") + " " + (e.comment ?? "") + " " + (e.keywords ?? []).join(" ")).toLowerCase()
                if (extra.includes(q)) s = 150
            }
        }
        return s
    }
    // ---- resultados: apps e, com prefixo, outras coisas (item = { name, desc, icon (tema) | glyph (Ico) | big (emoji), act }) ----
    //   /acoes   ;area de transferencia   :emoji   =conta   $comando   ?web   >so apps
    // sem prefixo: conta (se parecer uma), apps, acoes parecidas e buscar na web
    readonly property var prefixes: [["/", "ações"], [";", "área de transferência"], [":", "emoji"], ["=", "conta"], ["$", "comando"], ["?", "web"]]
    readonly property string mode: { const c = query.trim().charAt(0); return ["/", ";", ":", "=", "$", "?", ">"].indexOf(c) >= 0 ? c : "" }
    function appItems(q) {
        q = q.trim().toLowerCase()
        const usage = Settings.launcherUsage ?? {}
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        const scored = []
        for (const e of apps) {
            const boost = Math.min(usage[e.id] ?? 0, 30) * 4
            if (q === "") scored.push({ e: e, s: boost })
            else { const r = rank(e, q); if (r > 0) scored.push({ e: e, s: r + boost }) }
        }
        scored.sort((a, b) => b.s - a.s || (a.e.name ?? "").localeCompare(b.e.name ?? ""))
        return scored.map(x => ({ name: x.e.name, desc: x.e.comment || x.e.genericName || "", icon: x.e.icon, act: () => root.launch(x.e) }))
    }
    function norm(t) { return String(t).normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase() }
    function actionItems(q) {
        const w = norm(q).trim().split(/\s+/).filter(x => x)
        return Actions.list.filter(a => w.every(x => norm(a.name + " " + a.keys).includes(x)))
            .map(a => ({ name: a.name + (a.toggle ? (a.on() ? "  (ligado)" : "  (desligado)") : ""), desc: a.desc ?? "Ação do shell", glyph: a.icon, act: () => a.run() }))
    }
    function mathItems(q, forced) {
        const t = q.trim()
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
    property var clips: []
    Process {
        id: clipProc
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: root.clips = text.split("\n").filter(l => l).slice(0, 300) }
    }
    onModeChanged: if (mode === ";") { clipProc.running = false; clipProc.running = true }
    function clipItems(q) {
        const w = norm(q).trim()
        return clips.filter(l => w === "" || norm(l).includes(w)).slice(0, 60).map(l => {
            const txt = l.split("\t").slice(1).join("\t"), img = /^\[\[ binary data/.test(txt)
            return { name: img ? "Imagem" : txt.replace(/\s+/g, " ").slice(0, 160), desc: img ? txt.replace(/^\[\[ binary data |\]\]$/g, "") : "Enter copia de novo", glyph: img ? "image" : "cards",
                     act: () => Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | cliphist decode | wl-copy', "sh", l]) }
        })
    }
    property var emojis: []
    FileView { id: emojiFile; path: Qt.resolvedUrl("assets/emoji.tsv").toString().replace("file://", ""); onLoaded: root.emojis = text().split("\n").map(l => l.split("\t")) }
    function emojiItems(q) {
        const w = norm(q).trim().split(/\s+/).filter(x => x)
        return emojis.filter(e => w.every(x => (e[1] ?? "").includes(x))).slice(0, 80)
            .map(e => ({ name: e[1], desc: "Enter copia", big: e[0], act: () => { Quickshell.clipboardText = e[0] } }))
    }
    function webItem(q) { return { name: "Buscar na web: " + q.trim(), desc: Settings.launcherEngine.replace(/https?:\/\//, "").split("/")[0], glyph: "web", act: () => Qt.openUrlExternally(Settings.launcherEngine + encodeURIComponent(q.trim())) } }
    function cmdItem(q) { return { name: q.trim() === "" ? "Digite um comando" : "Executar: " + q.trim(), desc: "Roda em segundo plano (sem terminal)", glyph: "send", act: () => { if (q.trim()) Quickshell.execDetached(["sh", "-c", q.trim()]) } } }
    function results(query) {
        const t = query.trim(), rest = t.slice(1)
        switch (mode) {
        case "/": return actionItems(rest)
        case ";": return clipItems(rest)
        case ":": return emojiItems(rest)
        case "=": return mathItems(rest, true)
        case "$": return [cmdItem(rest)]
        case "?": return [webItem(rest)]
        case ">": return appItems(rest)
        }
        const apps = appItems(t)
        if (t === "") return apps
        return mathItems(t, false).concat(apps, t.length >= 3 ? actionItems(t).slice(0, 3) : [], [webItem(t)])
    }
    function run(it) { if (!it) return; Settings.launcherOpen = false; it.act() }
    function launch(e) {
        if (!e) return
        const u = Object.assign({}, Settings.launcherUsage ?? {})
        u[e.id] = (u[e.id] ?? 0) + 1
        Settings.launcherUsage = u
        e.execute()
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
                        color: win.docked ? "transparent" : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.glass ? Math.min(1, Settings.glassOpacity / 100 + 0.08) : 1)
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
                            Text {
                                id: glyph
                                anchors { left: parent.left; leftMargin: 28; verticalCenter: parent.verticalCenter }
                                text: "⌕"; color: Theme.accent; font.pixelSize: 22
                            }
                            TextInput {
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
                                Text { visible: input.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "Buscar…"; color: Theme.muted; font.pixelSize: 16 }
                                // dicas dos prefixos (some ao digitar)
                                Row {
                                    visible: input.text === "" && parent.width > 420
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    spacing: 4
                                    Repeater {
                                        model: root.prefixes
                                        delegate: Rectangle {
                                            required property var modelData
                                            height: 22; width: pt.implicitWidth + 12; radius: 6
                                            color: pm.containsMouse ? Theme.tint(0.2) : Theme.tint(0.08)
                                            Text { id: pt; anchors.centerIn: parent; text: modelData[0] + " " + modelData[1]; color: Theme.muted; font.pixelSize: 10 }
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
                                        source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                                        asynchronous: true
                                        smooth: true
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: width * 0.3
                                        visible: !!row.modelData.glyph
                                        color: Theme.tint(0.16)
                                        UiIcon { anchors.centerIn: parent; name: row.modelData.glyph ?? ""; size: parent.width * 0.55; color: Theme.accent }
                                    }
                                    Text { anchors.centerIn: parent; visible: !!row.modelData.big; text: row.modelData.big ?? ""; font.pixelSize: parent.width * 0.85 }
                                }
                                Column {
                                    anchors { left: ico.right; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                    spacing: 1
                                    Text { width: parent.width; text: row.modelData.name; color: Theme.text; font.pixelSize: 15; font.weight: Font.Medium; elide: Text.ElideRight }
                                    Text {
                                        visible: text !== ""
                                        width: parent.width
                                        text: row.modelData.desc ?? ""
                                        color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: view.currentIndex = row.index
                                    onClicked: root.run(row.modelData)
                                }
                            }
                        }

                        Text {
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
