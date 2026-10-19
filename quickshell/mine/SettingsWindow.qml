// Janela de configuracoes (barra lateral + paginas). Todas as mudancas valem ao vivo e ficam salvas.
// Abra/feche com:  qs -c mine ipc call settings toggle
// Quando o launcher, o seletor ou o Inicio abrem, a janela desliza para fora do caminho deles se couber na tela;
// se nao couber, so some (nao fecha) e volta quando eles fecham.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    readonly property bool open: Settings.settingsOpen
    readonly property bool windowed: Settings.settingsWindowed   // janela normal do Hyprland (senao: camada do shell, que desvia dos paineis)
    property var geo: ({})
    readonly property bool panelOpen: Settings.launcherOpen || Settings.wpPickerOpen || Settings.homeOpen
    // painel acoplado aberto agora (retangulo dele na moldura): a janela tenta desviar dele em vez de sumir
    readonly property var busy: Settings.wpPickerOpen ? geo.picker : (Settings.launcherOpen ? geo.launcher : (Settings.homeOpen ? geo.home : null))
    signal scrollTo(int y)

    IpcHandler {
        target: "settings"
        function toggle(): void { Settings.settingsOpen = !Settings.settingsOpen }
        function close(): void { Settings.settingsOpen = false }
        function isopen(): bool { return root.open }
        function go(p: string): void { Settings.settingsPage = p; Settings.settingsOpen = true }   // abre numa pagina (bars, look, wall...)
        function scroll(y: int): void { root.scrollTo(y) }   // rola a pagina aberta (para testes)
        function compose(mode: string): void { Settings.applyComposition(mode) }   // integrated | independent
        function search(q: string): void { Settings.settingsOpen = true; root.searchFor(q) }   // abre ja buscando
        function find(q: string): void { Settings.settingsOpen = true; root.findFor(q) }       // abre direto no melhor resultado
        function pages(): string { return root.allPages.map(p => p.id).join(" ") }                  // ids das paginas (teste rapido)
    }
    // abrir as configuracoes (pelo atalho ou pelo botao do Inicio) fecha os paineis que estiverem abertos
    onOpenChanged: if (open) { if (!windowed) { Settings.launcherOpen = false; Settings.wpPickerOpen = false; Settings.homeOpen = false } alive = true } else if (windowed) alive = false
    property bool alive: false   // janela existe (fica ate a animacao de saida terminar)

    readonly property var groups: [
        { label: "Visual", pages: [
            { id: "looks", label: "Visuais", icon: "layers", desc: "Presets do shell inteiro: salvar o visual de agora, aplicar com desfazer, exportar e importar." },
            { id: "look", label: "Aparência", icon: "palette", desc: "Vidro, tema de cores a partir do wallpaper, bordas das janelas, fontes e cores manuais." },
            { id: "frame", label: "Moldura", icon: "frame", desc: "O que nasce da moldura e o que flutua solto, o contorno, as curvas e o indicador de volume." },
            { id: "blur", label: "Blur", icon: "blur", desc: "Desfoque do Hyprland e da moldura." },
            { id: "anim", label: "Animações", icon: "animation", desc: "Curvas e molas de tudo o que se move, inclusive as janelas do Hyprland." }
        ] },
        { label: "Componentes", pages: [
            { id: "bars", label: "Barras", icon: "bars", desc: "Onde ficam as barras e o que cada uma mostra." },
            { id: "home", label: "Início", icon: "dashboard", desc: "O painel com mídia, áudio, sistema e conexões (Super)." },
            { id: "launcher", label: "Launcher", icon: "apps", desc: "O menu de aplicativos (Super + Tab)." },
            { id: "notifications", label: "Notificações", icon: "bell", desc: "Os avisos dos aplicativos." }
        ] },
        { label: "Área de trabalho", pages: [
            { id: "wall", label: "Wallpaper", icon: "wallpaper", desc: "Imagem de fundo, transições e o seletor (Super + W)." },
            { id: "desktop", label: "Widgets", icon: "view_grid", desc: "Widgets na área de trabalho, a cor deles e os layouts prontos." },
            { id: "session", label: "Sessão", icon: "power", desc: "Tela de bloqueio, menu de energia e foto de perfil." }
        ] }
    ]
    readonly property var allPages: groups.reduce((a, g) => a.concat(g.pages), [])
    function pageInfo(id) { return allPages.find(p => p.id === id) ?? null }

    // ---- busca: indice montado a partir das proprias paginas (titulos dos cartoes, interruptores e controles) ----
    // cada pagina e criada uma vez escondida (assincrono), percorrida e destruida; assim o indice nunca fica desatualizado
    property var index: []
    property bool indexing: false
    property string query: ""
    function norm(t) { return String(t ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase() }
    readonly property var results: {
        const q = norm(query).trim()
        if (q === "") return []
        const words = q.split(/\s+/)
        const out = []
        for (const e of index) {
            const hay = norm(e.label + " " + e.card + " " + e.desc + " " + e.pageLabel)
            if (!words.every(w => hay.includes(w))) continue
            const l = norm(e.label || e.card)
            const sc = (l.startsWith(q) ? 100 : l.includes(q) ? 60 : 20) + (e.label === "" ? 5 : 0)
            out.push(Object.assign({ score: sc }, e))
        }
        out.sort((a, b) => b.score - a.score)
        return out.slice(0, 40)
    }
    signal searchFor(string q)
    signal findFor(string q)
    readonly property var cur: groups.reduce((a, g) => a.concat(g.pages), []).find(p => p.id === Settings.settingsPage) ?? groups[0].pages[0]

    // ---- paginas e indice de busca (fora da janela: o launcher tambem procura opcoes com ela fechada) ----
    readonly property var comps: ({ bars: barsC, home: homeC, notifications: notifC, launcher: launcherC, frame: frameC, blur: blurC, anim: animC, wall: wallC, look: lookC, session: sessionC, desktop: desktopC, looks: looksC })
    Item { id: indexHost; visible: false; width: 900; height: 10 }
    Component { id: barsC; PageBars { geo: root.geo } }
    Component { id: homeC; PageHome {} }
    Component { id: notifC; PageNotifications {} }
    Component { id: launcherC; PageLauncher {} }
    Component { id: frameC; PageFrame {} }
    Component { id: lookC; PageLook {} }
    Component { id: blurC; PageBlur {} }
    Component { id: animC; PageAnim {} }
    Component { id: wallC; PageWallpaper {} }
    Component { id: sessionC; PageSession {} }
    Component { id: desktopC; PageDesktop {} }
    Component { id: looksC; PageLooks {} }
    function walk(o, card, out, pg) {
        if (!o) return
        let c = card
        if (typeof o.title === "string" && o.title !== "" && o.subtitle !== undefined) { c = o.title; out.push({ page: pg.id, pageLabel: pg.label, card: o.title, label: "", desc: o.subtitle ?? "" }) }
        else if (typeof o.label === "string" && o.label.length > 1 && (o.checked !== undefined || o.from !== undefined) && c !== "")
            out.push({ page: pg.id, pageLabel: pg.label, card: c, label: o.label, desc: o.description ?? "" })
        if (o.item) walk(o.item, c, out, pg)
        for (const ch of o.children ?? []) walk(ch, c, out, pg)
    }
    function buildIndex() {
        if (root.index.length || root.indexing) return
        root.indexing = true
        const pages = root.allPages.slice()
        const out = []
        const next = () => {
            const pg = pages.shift()
            if (!pg) {   // sem repetidos (o mesmo controle pode existir em grupos escondidos da pagina)
                const seen = {}
                root.index = out.filter(e => { const k = e.page + "|" + e.card + "|" + e.label; if (seen[k]) return false; seen[k] = true; return true })
                root.indexing = false
                return
            }
            const inc = root.comps[pg.id].incubateObject(indexHost, { width: 900 }, Qt.Asynchronous)
            const done = () => { if (inc.object) { root.walk(inc.object, "", out, pg); inc.object.destroy() } Qt.callLater(next) }
            if (inc.status !== Component.Loading) done()
            else inc.onStatusChanged = st => { if (st !== Component.Loading) done() }
        }
        next()
    }
    // abrir um resultado de fora (launcher): abre a janela e vai ate o cartao
    property var pendingOpen: null
    function show(r) { pendingOpen = r; Settings.settingsOpen = true }

    // ---- conteudo da janela (o mesmo na camada do shell e na janela normal do Hyprland) ----
    Component {
        id: bodyC
    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.windowed ? 0 : 22
        color: Theme.gl(Theme.bg, 1)
        clip: true
        focus: true
        // ---- busca e abrir um resultado (iguais nas duas formas de janela) ----
        Connections { target: root; function onSearchFor(q) { search.text = q; root.buildIndex() } }
        Connections { target: root; function onFindFor(q) { body.pendingFind = q; search.text = q; root.buildIndex(); body.tryFind() } }
        property string pendingFind: ""
        function takePending() { if (root.pendingOpen) { const r = root.pendingOpen; root.pendingOpen = null; Qt.callLater(() => body.open(r)) } }
        Component.onCompleted: takePending()
        Connections { target: root; function onPendingOpenChanged() { body.takePending() } }
        function tryFind() { if (pendingFind === "" || root.indexing || !root.index.length) return; const r = root.results; pendingFind = ""; if (r.length) open(r[0]) }
        Connections { target: root; function onIndexingChanged() { if (!root.indexing) body.tryFind() } }
        // abre um resultado: vai para a pagina, rola ate o cartao e acende a borda dele
        function open(r) {
            const pageChanged = Settings.settingsPage !== r.page
            search.text = ""
            body.forceActiveFocus()
            Settings.settingsPage = r.page
            revealT.card = r.card
            revealT.interval = pageChanged ? 120 : 30
            revealT.restart()
        }
        Timer {
            id: revealT
            property string card: ""
            onTriggered: {
                const page = pageLoader.item
                let found = null
                const find = o => { if (found || !o) return; if (o.title === card && o.subtitle !== undefined) { found = o; return } for (const ch of o.children ?? []) find(ch) }
                find(page)
                if (!found) return
                const y = found.mapToItem(page, 0, 0).y
                pageFlick.contentY = Math.max(0, Math.min(Math.max(0, pageFlick.contentHeight - pageFlick.height), y - 6))
                if (found.pulse) found.pulse()
            }
        }
        Keys.onEscapePressed: { if (root.query !== "") { root.query = ""; search.text = "" } else Settings.settingsOpen = false }
        Keys.onPressed: e => { if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_F) { search.forceActiveFocus(); e.accepted = true } }

        // contorno desenhado por cima de tudo (senao a barra lateral cobre a borda)
        Rectangle { visible: !root.windowed; anchors.fill: parent; radius: 22; color: "transparent"; border.width: 1; border.color: Theme.border; z: 100 }

        // ---- barra lateral ----
        Item {
            id: side
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 244
            clip: true
            // um unico retangulo com cantos arredondados so na esquerda (o da direita fica cortado): o vidro nao dobra
            Rectangle { x: 0; y: 0; width: parent.width + 40; height: parent.height; radius: 22; color: Theme.gl(Theme.sidebar, 1) }
            Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border; opacity: 0.6 }

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16; topMargin: 20 }
                spacing: 4

                Row {
                    spacing: 12
                    bottomPadding: 18
                    leftPadding: 4
                    Rectangle {
                        width: 38; height: 38; radius: 12
                        color: Theme.accent
                        UiIcon { anchors.centerIn: parent; name: "tune"; size: 20; color: Theme.accentText }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        UiText { text: "Quickshell"; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                        UiText { text: "Configurações"; color: Theme.muted; font.pixelSize: 12 }
                    }
                }

                // busca
                UiField {
                    id: search
                    width: parent.width
                    placeholderText: "Buscar opção…  (Ctrl+F)"
                    leftPadding: 32
                    onTextChanged: root.query = text
                    onActiveFocusChanged: if (activeFocus) root.buildIndex()
                    Keys.onEscapePressed: { text = ""; body.forceActiveFocus() }
                    Keys.onReturnPressed: if (root.results.length) body.open(root.results[0])
                    UiIcon { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } name: "search"; size: 15; color: Theme.muted }
                }
                Item { width: 1; height: 6 }
                Repeater {
                    model: root.groups
                    delegate: Column {
                        id: grp
                        required property var modelData
                        width: parent.width
                        spacing: 3
                        UiLabel { text: grp.modelData.label.toUpperCase(); leftPadding: 10; topPadding: 10; bottomPadding: 4; font.pixelSize: 11 }
                        Repeater {
                            model: grp.modelData.pages
                            delegate: Rectangle {
                                id: nav
                                required property var modelData
                                readonly property bool on: root.query === "" && Settings.settingsPage === modelData.id
                                width: grp.width; height: 38; radius: 11
                                color: on ? Theme.tint(0.16) : (navMouse.containsMouse ? Theme.card : "transparent")
                                Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 120 } }
                                UiIcon {
                                    id: navIc
                                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    width: 20
                                    name: nav.modelData.icon; size: 18
                                    color: nav.on ? Theme.accent : Theme.muted
                                }
                                UiText {
                                    anchors { left: navIc.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: nav.modelData.label
                                    color: nav.on ? Theme.text : Theme.muted
                                    font.pixelSize: 14; font.weight: nav.on ? Font.DemiBold : Font.Medium
                                }
                                MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { search.text = ""; Settings.settingsPage = nav.modelData.id } }
                            }
                        }
                    }
                }
            }

            // restaurar: pede confirmacao (segundo clique em ate 4 s)
            UiButton {
                id: resetBtn
                property bool armed: false
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16 }
                icon: "restore"
                text: armed ? "Clique de novo para confirmar" : "Restaurar padrão"
                kind: armed ? "danger" : "ghost"
                onClicked: { if (armed) { Settings.reset(); armed = false } else { armed = true; disarm.restart() } }
                Timer { id: disarm; interval: 4000; onTriggered: resetBtn.armed = false }
            }
        }

        // ---- conteudo ----
        Item {
            anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }

            Item {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 28; rightMargin: 20; topMargin: 20 }
                height: 52
                Column {
                    anchors { left: parent.left; right: closeBtn.left; verticalCenter: parent.verticalCenter }
                    spacing: 3
                    UiText { text: root.query !== "" ? "Busca" : root.cur.label; color: Theme.text; font.pixelSize: 24; font.weight: Font.Bold }
                    UiText {
                        text: root.query === "" ? root.cur.desc : (root.indexing && !root.index.length ? "Montando o índice…" : root.results.length + (root.results.length === 1 ? " resultado" : " resultados") + " para “" + root.query + "”")
                        color: Theme.muted; font.pixelSize: 13; elide: Text.ElideRight; width: parent.width
                    }
                }
                UiButton { id: closeBtn; anchors { right: parent.right; top: parent.top } icon: "close"; kind: "ghost"; onClicked: Settings.settingsOpen = false }
            }

            Flickable {
                id: pageFlick
                Connections { target: root; function onScrollTo(y) { pageFlick.contentY = Math.max(0, Math.min(pageFlick.contentHeight - pageFlick.height, y)) } }
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; topMargin: 18 }
                contentHeight: pageLoader.implicitHeight + 28
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: false   // so a roda do mouse rola (arrastar nao)
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    acceptedModifiers: Qt.NoModifier
                    onWheel: e => { const f = pageFlick; f.contentY = Math.max(0, Math.min(Math.max(0, f.contentHeight - f.height), f.contentY - e.angleDelta.y)) }
                }
                Loader {
                    id: pageLoader
                    x: 28
                    width: pageFlick.width - 56
                    sourceComponent: ({ bars: barsC, home: homeC, notifications: notifC, launcher: launcherC, frame: frameC, blur: blurC, anim: animC, wall: wallC, look: lookC, session: sessionC, desktop: desktopC, looks: looksC })[Settings.settingsPage] ?? lookC
                    visible: root.query === ""
                    onSourceComponentChanged: { pageFlick.contentY = 0; pageIn.restart() }
                    // troca de pagina: entra subindo um pouco e aparecendo
                    property real shift: 0
                    transform: Translate { y: pageLoader.shift }
                    ParallelAnimation {
                        id: pageIn
                        NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        NumberAnimation { target: pageLoader; property: "shift"; from: 14; to: 0; duration: 260; easing.type: Easing.OutCubic }
                    }
                }
            }
            // barra de rolagem fina (so aparece se a pagina for maior que a janela)
            Rectangle {
                visible: pageFlick.contentHeight > pageFlick.height
                anchors.right: parent.right; anchors.rightMargin: 8
                y: pageFlick.y + pageFlick.contentY / pageFlick.contentHeight * pageFlick.height
                width: 4; radius: 2
                height: Math.max(30, pageFlick.height * pageFlick.height / pageFlick.contentHeight)
                color: Theme.border
            }
            // ---- resultados da busca ----
            Flickable {
                id: resFlick
                visible: root.query !== ""
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; topMargin: 18; leftMargin: 28; rightMargin: 28; bottomMargin: 14 }
                contentHeight: resCol.implicitHeight
                clip: true
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                WheelHandler { onWheel: e => { const f = resFlick; f.contentY = Math.max(0, Math.min(Math.max(0, f.contentHeight - f.height), f.contentY - e.angleDelta.y)) } }
                Connections { target: root; function onQueryChanged() { resFlick.contentY = 0 } }
            Column {
                id: resCol
                width: resFlick.width
                spacing: 6
                UiText { visible: root.results.length === 0 && root.index.length > 0; text: "Nada encontrado. Tente outra palavra (ex.: blur, mola, relógio, bloqueio)."; color: Theme.muted; font.pixelSize: 13 }
                Repeater {
                    model: root.results
                    delegate: Rectangle {
                        id: rr
                        required property var modelData
                        required property int index
                        width: parent.width; height: 54; radius: 12
                        color: rrm.containsMouse || (index === 0) ? Theme.cardHi : Theme.track
                        border.width: 1; border.color: index === 0 ? Theme.tint(0.45) : Theme.border
                        Rectangle {
                            id: rrIc
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            width: 32; height: 32; radius: 9
                            color: Theme.tint(0.16)
                            UiIcon { anchors.centerIn: parent; name: (root.pageInfo(rr.modelData.page) ?? {}).icon ?? "cog"; size: 16; color: Theme.accent }
                        }
                        Column {
                            anchors { left: rrIc.right; leftMargin: 12; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            spacing: 2
                            UiText { width: parent.width; elide: Text.ElideRight; text: rr.modelData.label || rr.modelData.card; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            UiText { width: parent.width; elide: Text.ElideRight; text: rr.modelData.pageLabel + "  ›  " + rr.modelData.card + (rr.modelData.desc ? "  ·  " + rr.modelData.desc : ""); color: Theme.muted; font.pixelSize: 11 }
                        }
                        MouseArea { id: rrm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: body.open(rr.modelData) }
                    }
                }
            }
            }

        }
    }
    }

    // ---- janela normal do Hyprland (padrao): os paineis do shell abrem por cima dela; nada desvia nem some ----
    LazyLoader {
        active: root.open && root.windowed

        FloatingWindow {
            id: fw
            title: "Configurações do shell"
            implicitWidth: 1160
            implicitHeight: 800
            minimumSize: Qt.size(820, 560)
            color: "transparent"
            onClosed: Settings.settingsOpen = false
            Loader { anchors.fill: parent; sourceComponent: bodyC; focus: true }
        }
    }

    LazyLoader {
        active: root.alive && !root.windowed

        PanelWindow {
            id: win
            // tela inteira e transparente (so a janela de verdade recebe o mouse): assim ela pode deslizar sem o compositor redimensionar nada
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: win.away || !root.open ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "mine-settings"
            // area que pega o mouse: um item proprio, sem transformacoes e sempre o mesmo (o Region nao acompanha
            // deslocamentos por transform nem troca de item direito; quando ficava desatualizado os cliques atravessavam a janela)
            mask: Region { item: hit }
            Item {
                id: hit
                readonly property bool on: !win.away && root.open
                x: on ? body.x : 0; y: on ? body.y : 0
                width: on ? body.width : 0; height: on ? body.height : 0
            }

            // ---- entrada/saida: animacao "Janela de configuracoes" (pagina Animacoes); por padrao a mesma das camadas do Hyprland
            // (slide 500 ms emphasizedDecel / 400 ms emphasizedAccel). O fade usa a curva padrao, com o tempo da animacao.
            // (o Hyprland nao anima esta janela: regra no_anim gerada pelo HyprSync)
            property real sp: 0   // deslize: 0 = uma tela inteira acima, 1 = no lugar
            property real fp: 0   // opacidade
            Component.onCompleted: { contentItem.opacity = Qt.binding(() => Math.min(1, win.fp)); inAnim.start() }
            Connections {
                target: root
                function onOpenChanged() { if (root.open) { outAnim.stop(); inAnim.start() } else { inAnim.stop(); outAnim.start() } }
            }
            ParallelAnimation {
                id: inAnim
                MotionAnim { target: win; property: "sp"; to: 1; use: "settings" }
                NumberAnimation { target: win; property: "fp"; to: 1; duration: Math.max(1, Motion.durationOf("settings", false)); easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
            }
            ParallelAnimation {
                id: outAnim
                MotionAnim { target: win; property: "sp"; to: 0; use: "settings"; out: true }
                NumberAnimation { target: win; property: "fp"; to: 0; duration: Math.max(1, Motion.durationOf("settings", true)); easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
                onFinished: root.alive = false
            }

            readonly property real bw: Math.min(1160, width - 60)
            readonly property real bh: Math.min(800, height - 90)
            readonly property real cx0: (width - bw) / 2
            readonly property real cy0: (height - bh) / 2
            readonly property var place: {
                const m = 16
                if (!root.panelOpen) return { ok: true, x: cx0, y: cy0 }
                if (!root.busy) return { ok: false, x: cx0, y: cy0 }   // flutuante ou ainda esperando outro painel recolher
                const R = root.busy.rect, sd = root.busy.side
                if (cx0 + bw <= R.x - m || R.x + R.w + m <= cx0 || cy0 + bh <= R.y - m || R.y + R.h + m <= cy0) return { ok: true, x: cx0, y: cy0 }
                if (sd === "bottom") { const y = Math.min(cy0, R.y - m - bh); return { ok: y >= m, x: cx0, y: y } }
                if (sd === "top") { const y = Math.max(cy0, R.y + R.h + m); return { ok: y + bh <= height - m, x: cx0, y: y } }
                if (sd === "left") { const x = Math.max(cx0, R.x + R.w + m); return { ok: x + bw <= width - m, x: x, y: cy0 } }
                const x = Math.min(cx0, R.x - m - bw); return { ok: x >= m, x: x, y: cy0 }
            }
            readonly property bool away: !place.ok

            // conteudo: posicao, desvio dos paineis acoplados e animacao de entrada/saida ficam aqui
            Loader {
                id: body
                sourceComponent: bodyC
                focus: true
                transform: Translate { y: -win.height * (1 - win.sp) }
                x: win.away ? win.cx0 : win.place.x
                y: win.away ? win.cy0 : win.place.y
                width: win.bw; height: win.bh
                // so anima o desvio dos paineis: ao abrir a janela ja nasce no lugar (senao viria do canto, na diagonal)
                property bool settled: false
                Timer { interval: 120; running: win.width > 0; onTriggered: body.settled = true }
                Behavior on x { enabled: body.settled; NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on y { enabled: body.settled; NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                opacity: win.away ? 0 : 1
                scale: win.away ? 0.96 : 1
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

        }
    }
}
