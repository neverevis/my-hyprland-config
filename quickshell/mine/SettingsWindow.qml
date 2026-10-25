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
        function open(): void { Settings.settingsOpen = true }
        function close(): void { Settings.settingsOpen = false }
        function isopen(): bool { return root.open }
        function go(p: string): void { Settings.settingsPage = p; Settings.settingsOpen = true }   // abre numa pagina (ids novos ou antigos: theme, wall, look, hypr...)
        function scroll(y: int): void { root.scrollTo(y) }   // rola a pagina aberta (para testes)
        function compose(mode: string): void { Settings.applyComposition(mode) }   // integrated | independent
        function search(q: string): void { Settings.settingsOpen = true; root.searchFor(q) }   // abre ja buscando
        function find(q: string): void { Settings.settingsOpen = true; root.findFor(q) }       // abre direto no melhor resultado
        function pages(): string { return root.allPages.map(p => p.id).join(" ") }                  // ids das paginas (teste rapido)
    }
    // abrir as configuracoes (pelo atalho ou pelo botao do Inicio) fecha os paineis que estiverem abertos
    onOpenChanged: if (open) { if (!windowed) { Settings.launcherOpen = false; Settings.wpPickerOpen = false; Settings.homeOpen = false } alive = true } else if (windowed) alive = false
    property bool alive: false   // janela existe (fica ate a animacao de saida terminar)


    // ---- arquitetura: dois grupos (Personalizacao e Sistema). Paginas novas usam o kit Set*; as antigas ficam
    // hospedadas na entrada mais proxima ate serem migradas. ids antigos continuam valendo (aliases abaixo).
    readonly property var groups: [
        { label: "Personalização", pages: [
            { id: "start", label: "Início", icon: "home", desc: "O visual de agora e os ajustes rápidos." },
            { id: "theme", label: "Tema e cores", icon: "palette", desc: "Paleta, claro ou escuro, transparência e fontes." },
            { id: "wall", label: "Wallpaper", icon: "wallpaper", desc: "Imagem de fundo, estilo, transição e o seletor." },
            { id: "desktop", label: "Área de trabalho", icon: "view_grid", desc: "Widgets sobre o wallpaper e layouts prontos." },
            { id: "bars", label: "Barras e moldura", icon: "bars", desc: "Onde ficam as barras, o que mostram e a moldura." },
            { id: "panels", label: "Painéis", icon: "dock", desc: "Início, launcher, notificações, visão geral e barra lateral." },
            { id: "win", label: "Janelas", icon: "window", desc: "Hyprland: espaços, bordas, sombras, desfoque e atalhos." },
            { id: "anim", label: "Animações", icon: "animation", desc: "Curvas e molas de tudo o que se move." },
            { id: "looks", label: "Visuais", icon: "layers", desc: "Salvar, aplicar e trocar o visual inteiro." }
        ] },
        { label: "Sistema", pages: [
            { id: "keys", label: "Atalhos de teclado", icon: "keyboard", desc: "Ver, criar e mudar atalhos." },
            { id: "apps", label: "Aplicativos", icon: "apps", desc: "Instalar, remover e abrir ao iniciar." },
            { id: "sound", label: "Som", icon: "volume", desc: "Saídas, entradas e volume por aplicativo." },
            { id: "net", label: "Rede e Bluetooth", icon: "wifi", desc: "Wi-Fi, cabo, VPN e dispositivos." },
            { id: "display", label: "Monitores", icon: "monitor", desc: "Resolução, escala e posição das telas." },
            { id: "input", label: "Mouse e teclado", icon: "mouse", desc: "Cursor, mouse, ícones, fontes e apps padrão." },
            { id: "power", label: "Energia e sessão", icon: "power", desc: "Bloqueio, inatividade, energia e hora." },
            { id: "time", label: "Data, hora e idioma", icon: "clockOutline", desc: "Fuso, formato e idioma." },
            { id: "tools", label: "Ferramentas", icon: "wrench", desc: "Captura, gravação, prateleira e painel de jogo." },
            { id: "account", label: "Conta e Sobre", icon: "accountCircle", desc: "Seu nome, a máquina e este computador." }
        ] }
    ]
    readonly property var allPages: groups.reduce((a, g) => a.concat(g.pages), [])
    // id antigo -> [entrada nova, cartao para rolar, sub-pagina]
    readonly property var aliases: ({
        overview: ["start"], look: ["theme"], frame: ["bars", "Janela de configurações"], blur: ["win", "Blur do Hyprland"], hypr: ["win"],
        home: ["panels", "", "home"], launcher: ["panels", "", "launcher"], notifications: ["panels", "", "notifications"],
        system: ["input"], session: ["power"], wallpaper: ["wall"], about: ["account", "Sobre este computador"], profile: ["account"]
    })
    readonly property string curId: (aliases[Settings.settingsPage] ?? [Settings.settingsPage])[0]
    function normalize() {
        const a = aliases[Settings.settingsPage]
        if (!a) return
        if (a[2]) Settings.settingsSub = a[2]
        if (a[1]) Settings.settingsReveal = a[1]
        Settings.settingsPage = a[0]
    }
    Connections { target: Settings; function onSettingsPageChanged() { root.normalize() } }
    Component.onCompleted: normalize()
    function pageInfo(id) { const a = aliases[id]; const k = a ? a[0] : id; return allPages.find(p => p.id === k) ?? null }

    // ---- busca: indice montado a partir das proprias paginas (secoes/cartoes, linhas, interruptores e controles) ----
    // cada pagina e criada uma vez escondida (assincrono), percorrida e destruida; assim o indice nunca fica desatualizado
    property var index: []
    property bool indexing: false
    property string query: ""
    function norm(t) { return String(t ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase() }
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
    readonly property var cur: pageInfo(curId) ?? groups[0].pages[0]

    // ---- paginas e indice de busca (fora da janela: o launcher tambem procura opcoes com ela fechada) ----
    readonly property var comps: ({ start: startC, theme: themeC, wall: wallC, desktop: desktopC, bars: barsC, panels: panelsC, win: winC, anim: animC, looks: looksC,
        keys: keysC, apps: appsC, sound: soundC, net: netC, display: displayC, input: systemC, power: sessionC, time: timeC, tools: toolsC, account: accountC })
    // o que a busca percorre: cada entrada; Paineis vira uma fonte por painel (a sub-pagina vai junto no resultado)
    readonly property var indexSources: allPages.reduce((a, pg) => a.concat(pg.id === "panels"
        ? [{ pg: pg, comp: homeC, sub: "home" }, { pg: pg, comp: launcherC, sub: "launcher" }, { pg: pg, comp: notifC, sub: "notifications" }]
        : [{ pg: pg, comp: comps[pg.id], sub: "" }]), [])
    Item { id: indexHost; visible: false; width: 760; height: 10 }
    Component { id: startC; PageStart {} }
    Component { id: themeC; PageTheme {} }
    Component { id: wallC; PageWall {} }
    Component { id: desktopC; PageDesktop {} }
    Component { id: barsC; Column { spacing: 14; PageBars { width: parent.width; geo: root.geo } PageFrame { width: parent.width } } }
    Component { id: panelsC; PagePanels {} }
    Component { id: homeC; PageHome {} }
    Component { id: launcherC; PageLauncher {} }
    Component { id: notifC; PageNotifications {} }
    Component { id: winC; Column { spacing: 14; PageHypr { width: parent.width } ShadowCard { width: parent.width } PageBlur { width: parent.width } } }
    Component { id: animC; PageAnim {} }
    Component { id: looksC; PageLooks {} }
    Component { id: systemC; PageSystem {} }
    Component { id: sessionC; PageSession {} }
    Component { id: toolsC; PageTools {} }
    Component { id: accountC; Column { spacing: 14; PageProfile { width: parent.width } PageAbout { width: parent.width } } }
    Component { id: keysC; SetSoon { title: "Atalhos de teclado"; icon: "keyboard"; plans: ["Lista com busca", "Gravar uma tecla", "Criar e mudar atalhos do Hyprland"]
        links: [["Atalhos atuais (só leitura)", "keyboard", "win", "Atalhos"]] } }
    Component { id: appsC; SetSoon { title: "Aplicativos"; icon: "apps"; plans: ["Instalar e remover programas", "Apps ao iniciar", "Apps padrão"]
        links: [["Apps ao iniciar", "rocket", "win", "Apps ao iniciar"], ["Aplicativos padrão", "apps", "input", "Aplicativos padrão"], ["Webapps", "web", "input", "Webapps"]] } }
    Component { id: soundC; SetSoon { title: "Som"; icon: "volume"; plans: ["Saídas e entradas", "Volume por aplicativo", "Equalizador"]
        links: [["Indicador de volume", "volume", "bars", "Indicador de volume"]] } }
    Component { id: netC; SetSoon { title: "Rede e Bluetooth"; icon: "wifi"; plans: ["Wi-Fi e cabo", "VPN", "Dispositivos Bluetooth"] } }
    Component { id: displayC; SetSoon { title: "Monitores"; icon: "monitor"; plans: ["Resolução e escala", "Posição das telas", "Luz noturna"]
        links: [["Resolução e escala", "monitor", "win", "Monitor"]] } }
    Component { id: timeC; SetSoon { title: "Data, hora e idioma"; icon: "clockOutline"; plans: ["Fuso horário", "Formato da hora", "Idioma e teclado"]
        links: [["Formato do relógio", "clock", "power", "Hora e data"]] } }
    function walk(o, card, out, src) {
        if (!o) return
        let c = card
        const base = { page: src.pg.id, sub: src.sub, pageLabel: src.pg.label }
        if (typeof o.title === "string" && o.title !== "" && o.subtitle !== undefined) { c = o.title; out.push(Object.assign({ card: o.title, label: "", desc: o.subtitle ?? "" }, base)) }
        else if (typeof o.label === "string" && o.label.length > 1 && (o.checked !== undefined || o.from !== undefined || o.setRow === true) && c !== "")
            out.push(Object.assign({ card: c, label: o.label, desc: o.description ?? "" }, base))
        if (o.item) walk(o.item, c, out, src)
        for (const ch of o.children ?? []) walk(ch, c, out, src)
    }
    function buildIndex() {
        if (root.index.length || root.indexing) return
        root.indexing = true
        const srcs = root.indexSources.slice()
        const out = []
        const next = () => {
            const src = srcs.shift()
            if (!src) {   // sem repetidos (o mesmo controle pode existir em grupos escondidos da pagina)
                const seen = {}
                root.index = out.filter(e => { const k = e.page + "|" + e.sub + "|" + e.card + "|" + e.label; if (seen[k]) return false; seen[k] = true; return true })
                root.indexing = false
                return
            }
            const inc = src.comp.incubateObject(indexHost, { width: 760 }, Qt.Asynchronous)
            const done = () => { if (inc.object) { root.walk(inc.object, "", out, src); inc.object.destroy() } Qt.callLater(next) }
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
        Component.onCompleted: { takePending(); takeReveal() }
        Connections { target: root; function onPendingOpenChanged() { body.takePending() } }
        function tryFind() { if (pendingFind === "" || root.indexing || !root.index.length) return; const r = root.results; pendingFind = ""; if (r.length) open(r[0]) }
        Connections { target: root; function onIndexingChanged() { if (!root.indexing) body.tryFind() } }
        // outra pagina pediu para rolar ate um cartao (Settings.settingsReveal)
        function takeReveal() { if (Settings.settingsReveal === "") return; revealT.card = Settings.settingsReveal; revealT.label = ""; revealT.interval = 160; revealT.restart(); Settings.settingsReveal = "" }
        Connections { target: Settings; function onSettingsRevealChanged() { body.takeReveal() } }
        // abre um resultado: vai para a pagina (e sub-pagina), rola ate a linha (abre o expansor dela) e acende
        function open(r) {
            const pageChanged = root.curId !== r.page || (r.sub && Settings.settingsSub !== r.sub)
            search.text = ""
            body.forceActiveFocus()
            if (r.sub) Settings.settingsSub = r.sub
            Settings.settingsPage = r.page
            revealT.card = r.card
            revealT.label = r.label ?? ""
            revealT.interval = pageChanged ? 140 : 30
            revealT.restart()
        }
        Timer {
            id: revealT
            property string card: ""
            property string label: ""
            onTriggered: {
                const page = pageLoader.item
                let sec = null, row = null
                const kids = o => (o.item ? [o.item] : []).concat(Array.from(o.children ?? []))
                const findSec = o => { if (sec || !o) return; if (o.title === card && o.subtitle !== undefined) { sec = o; return } for (const ch of kids(o)) findSec(ch) }
                findSec(page)
                if (!sec) return
                if (label !== "") {
                    const findRow = o => { if (row || !o) return; if (o.label === label && o.pulse) { row = o; return } for (const ch of kids(o)) findRow(ch) }
                    findRow(sec)
                }
                const target = row ?? sec
                // abre os expansores no caminho ate a linha
                for (let p = target.parent; p && p !== page; p = p.parent) if (p.expander === true) p.open = true
                Qt.callLater(() => {
                    const y = target.mapToItem(page, 0, 0).y
                    pageFlick.contentY = Math.max(0, Math.min(Math.max(0, pageFlick.contentHeight - pageFlick.height), y - 24))
                    if (target.pulse) target.pulse()
                })
            }
        }
        Keys.onEscapePressed: { if (root.query !== "") { root.query = ""; search.text = "" } else Settings.settingsOpen = false }
        // teclado: Ctrl+F busca; Tab / Shift+Tab (ou Ctrl+PageDown / PageUp) trocam de pagina; setas e PageUp/PageDown rolam
        function stepPage(d) {
            const ids = root.allPages.map(p => p.id)
            const i = Math.max(0, ids.indexOf(root.curId))
            Settings.settingsPage = ids[(i + d + ids.length) % ids.length]
        }
        function scrollBy(dy) { const f = pageFlick; f.contentY = Math.max(0, Math.min(Math.max(0, f.contentHeight - f.height), f.contentY + dy)) }
        Keys.onPressed: e => {
            const ctrl = e.modifiers & Qt.ControlModifier
            if (ctrl && e.key === Qt.Key_F) { search.forceActiveFocus(); e.accepted = true }
            else if (e.key === Qt.Key_Tab || (ctrl && e.key === Qt.Key_PageDown)) { stepPage(1); e.accepted = true }
            else if (e.key === Qt.Key_Backtab || (ctrl && e.key === Qt.Key_PageUp)) { stepPage(-1); e.accepted = true }
            else if (e.key === Qt.Key_Down) { scrollBy(90); e.accepted = true }
            else if (e.key === Qt.Key_Up) { scrollBy(-90); e.accepted = true }
            else if (e.key === Qt.Key_PageDown) { scrollBy(pageFlick.height * 0.85); e.accepted = true }
            else if (e.key === Qt.Key_PageUp) { scrollBy(-pageFlick.height * 0.85); e.accepted = true }
        }

        // contorno desenhado por cima de tudo (senao a barra lateral cobre a borda)
        Rectangle { visible: !root.windowed; anchors.fill: parent; radius: 22; color: "transparent"; border.width: 1; border.color: Theme.border; z: 100 }

        // ---- barra lateral: icone + nome; em janela estreita recolhe para so os icones (o botao do topo abre por cima) ----
        readonly property bool narrow: width < 1000
        property bool collapsePref: false
        property bool peek: false
        readonly property bool collapsed: narrow ? !peek : collapsePref
        onNarrowChanged: peek = false
        Item {
            id: side
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: body.collapsed ? 68 : 248
            Behavior on width { NumberAnimation { duration: SetK.base; easing.type: Easing.BezierSpline; easing.bezierCurve: SetK.ease } }
            clip: true
            z: 5
            readonly property real inner: width - 24
            // um unico retangulo com cantos arredondados so na esquerda (o da direita fica cortado): o vidro nao dobra
            Rectangle { x: 0; y: 0; width: parent.width + 40; height: parent.height; radius: 22; color: Theme.gl(Theme.sidebar, 1) }
            Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: Theme.border; opacity: 0.6 }

            Column {
                id: sideTop
                x: 12; y: 14
                width: side.inner
                spacing: SetK.sm
                // recolher / abrir a barra lateral
                Item {
                    width: parent.width; height: 34
                    Rectangle {
                        width: 44; height: 34; radius: 10
                        color: colM.containsMouse ? Theme.cardHi : "transparent"
                        UiIcon { anchors.centerIn: parent; name: body.collapsed ? "menu" : "menuOpen"; size: 19; color: Theme.muted }
                        MouseArea { id: colM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (body.narrow) body.peek = !body.peek; else body.collapsePref = !body.collapsePref } }
                    }
                }
                // cabecalho: foto e nome; o clique leva a Conta e Sobre
                Item {
                    width: parent.width; height: 52
                    Rectangle { anchors.fill: parent; radius: 12; color: prM.containsMouse ? Theme.cardHi : "transparent" }
                    Row {
                        x: body.collapsed ? (parent.width - 36) / 2 : 6
                        spacing: 12
                        anchors.verticalCenter: parent.verticalCenter
                        Avatar { size: 36; ring: 2 }
                        Column {
                            visible: !body.collapsed
                            anchors.verticalCenter: parent.verticalCenter
                            UiText { text: Profile.name; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }
                            UiText { text: Profile.desc || "Configurações"; color: Theme.muted; font.pixelSize: 12; width: side.inner - 60; elide: Text.ElideRight }
                        }
                    }
                    MouseArea { id: prM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { body.peek = false; Settings.settingsPage = "account" } }
                    Component.onCompleted: SysInfo.use()
                    Component.onDestruction: SysInfo.release()
                }
                // busca (recolhida: so a lupa, que abre a barra e foca o campo)
                Item {
                    width: parent.width; height: 36
                    UiField {
                        id: search
                        visible: !body.collapsed
                        anchors.fill: parent
                        placeholderText: "Buscar opção  (Ctrl+F)"
                        leftPadding: 32
                        onTextChanged: root.query = text
                        onActiveFocusChanged: if (activeFocus) root.buildIndex()
                        Keys.onEscapePressed: { text = ""; body.forceActiveFocus() }
                        Keys.onReturnPressed: if (root.results.length) body.open(root.results[0])
                        UiIcon { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } name: "search"; size: 15; color: Theme.muted }
                    }
                    Rectangle {
                        visible: body.collapsed
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 44; height: 36; radius: 10
                        color: sM.containsMouse ? Theme.cardHi : Theme.track
                        border.width: 1; border.color: Theme.border
                        UiIcon { anchors.centerIn: parent; name: "search"; size: 16; color: Theme.muted }
                        MouseArea { id: sM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (body.narrow) body.peek = true; else body.collapsePref = false; search.forceActiveFocus() } }
                    }
                }
            }
            // lista das paginas: rola quando nao cabe (ao passar o mouse por cima, a roda rola)
            Flickable {
                id: navFlick
                anchors { left: parent.left; right: parent.right; top: sideTop.bottom; bottom: sideBottom.top; leftMargin: 12; rightMargin: 12; topMargin: 6; bottomMargin: 8 }
                contentHeight: navCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: navCol
                    width: navFlick.width
                    spacing: 2
                Repeater {
                    model: root.groups
                    delegate: Column {
                        id: grp
                        required property var modelData
                        required property int index
                        width: parent.width
                        spacing: 2
                        Item {
                            width: parent.width; height: grp.index === 0 ? 28 : 40
                            UiText {
                                visible: !body.collapsed
                                anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 6 }
                                text: grp.modelData.label; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold
                            }
                            Rectangle { visible: body.collapsed && grp.index > 0; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 } height: 1; color: Theme.border }
                        }
                        Repeater {
                            model: grp.modelData.pages
                            delegate: Rectangle {
                                id: nav
                                required property var modelData
                                readonly property bool on: root.query === "" && root.curId === modelData.id
                                width: grp.width; height: 38; radius: 11
                                color: on ? Theme.tint(0.14) : (navMouse.containsMouse ? Theme.card : "transparent")
                                Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 120 } }
                                // marca da pagina aberta
                                Rectangle {
                                    visible: nav.on
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                    width: 3; height: 16; radius: 2; color: Theme.accent
                                }
                                UiIcon {
                                    id: navIc
                                    x: body.collapsed ? (parent.width - width) / 2 : 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    name: nav.modelData.icon; size: 18
                                    color: nav.on ? Theme.accent : Theme.muted
                                }
                                UiText {
                                    visible: !body.collapsed
                                    anchors { left: navIc.right; leftMargin: 12; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    elide: Text.ElideRight
                                    text: nav.modelData.label
                                    color: nav.on ? Theme.text : Theme.muted
                                    font.pixelSize: 13; font.weight: nav.on ? Font.DemiBold : Font.Medium
                                }
                                MouseArea {
                                    id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { search.text = ""; body.peek = false; Settings.settingsPage = nav.modelData.id }
                                    onContainsMouseChanged: {
                                        if (containsMouse && body.collapsed) { tip.text = nav.modelData.label; tip.y = nav.mapToItem(body, 0, 0).y + (nav.height - tip.height) / 2 }
                                        else if (tip.text === nav.modelData.label) tip.text = ""
                                    }
                                }
                            }
                        }
                    }
                }
            }
            }

            // arquivo de configuracao (clique abre, direito copia o caminho) e restaurar (pede confirmacao)
            Column {
                id: sideBottom
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
                spacing: 4
                UiButton {
                    id: cfgBtn
                    property bool copied: false
                    width: parent.width
                    icon: copied ? "check" : "pencil"
                    text: body.collapsed ? "" : (copied ? "Caminho copiado" : "Arquivo de configuração")
                    kind: "ghost"
                    onClicked: Qt.openUrlExternally(Qt.resolvedUrl("settings.json"))
                    MouseArea {
                        anchors.fill: parent; acceptedButtons: Qt.RightButton
                        onClicked: { Quickshell.clipboardText = Qt.resolvedUrl("settings.json").toString().replace("file://", ""); cfgBtn.copied = true; cfgT.restart() }
                    }
                    Timer { id: cfgT; interval: 1500; onTriggered: cfgBtn.copied = false }
                }
                UiButton {
                    id: resetBtn
                    property bool armed: false
                    width: parent.width
                    icon: "restore"
                    text: body.collapsed ? "" : (armed ? "Clique de novo para confirmar" : "Restaurar padrão")
                    kind: armed ? "danger" : "ghost"
                    onClicked: { if (armed) { Settings.reset(); armed = false } else { armed = true; disarm.restart() } }
                    Timer { id: disarm; interval: 4000; onTriggered: resetBtn.armed = false }
                }
            }
        }
        // dica com o nome da pagina (barra lateral recolhida)
        Rectangle {
            id: tip
            property string text: ""
            visible: text !== "" && body.collapsed
            z: 50
            x: side.width + 6
            width: tipT.implicitWidth + 20; height: 28; radius: 8
            color: Theme.cardHi
            border.width: 1; border.color: Theme.border
            UiText { id: tipT; anchors.centerIn: parent; text: tip.text; color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium }
        }

        // ---- conteudo: coluna centralizada (largura maxima da pagina; as do kit usam 760) ----
        Item {
            id: content
            anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }
            readonly property bool kit: !!(pageLoader.item && pageLoader.item.kitPage) && root.query === ""
            readonly property real colW: Math.min(kit ? SetK.maxWidth : 900, width - 72)
            readonly property real colX: Math.max(36, (width - colW) / 2)

            UiButton { id: closeBtn; z: 10; anchors { right: parent.right; top: parent.top; margins: 14 } icon: "close"; kind: "ghost"; onClicked: Settings.settingsOpen = false }

            // cabecalho das paginas antigas e da busca (as do kit trazem o proprio titulo)
            Item {
                id: header
                visible: !content.kit
                x: content.colX
                y: 24
                width: content.colW
                height: visible ? 50 + (jumps.visible ? 44 : 0) : 0
                Column {
                    anchors { left: parent.left; right: parent.right; rightMargin: 40; top: parent.top }
                    spacing: 3
                    UiText { text: root.query !== "" ? "Busca" : root.cur.label; color: Theme.text; font.family: Theme.fontTitle; font.pixelSize: SetK.fPage; font.weight: Font.Bold }
                    UiText {
                        text: root.query === "" ? root.cur.desc : (root.indexing && !root.index.length ? "Montando o índice…" : root.results.length + (root.results.length === 1 ? " resultado" : " resultados") + " para “" + root.query + "”")
                        color: Theme.muted; font.pixelSize: 13; elide: Text.ElideRight; width: parent.width
                    }
                }
                // "Nesta pagina": um atalho para cada cartao (rola ate ele e acende a borda)
                Flickable {
                    id: jumps
                    property var cards: []
                    visible: root.query === "" && cards.length >= 3
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 32
                    contentWidth: jumpRow.implicitWidth
                    clip: true
                    interactive: false
                    WheelHandler { onWheel: e => { const f = jumps; f.contentX = Math.max(0, Math.min(Math.max(0, f.contentWidth - f.width), f.contentX - e.angleDelta.y - e.angleDelta.x)) } }
                    Row {
                        id: jumpRow
                        spacing: 6
                        Repeater {
                            model: jumps.cards
                            delegate: Rectangle {
                                required property var modelData
                                height: 30; width: jr.implicitWidth + 22; radius: 15
                                color: jm.containsMouse ? Theme.tint(0.16) : Theme.track
                                border.width: 1; border.color: jm.containsMouse ? Theme.tint(0.5) : Theme.border
                                Row {
                                    id: jr
                                    anchors.centerIn: parent
                                    spacing: 6
                                    UiIcon { visible: !!modelData.icon; name: modelData.icon; size: 13; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                                    UiText { text: modelData.title; color: Theme.text; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                }
                                MouseArea { id: jm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { revealT.card = modelData.title; revealT.label = ""; revealT.interval = 10; revealT.restart() } }
                            }
                        }
                    }
                }
                Timer {
                    id: jumpT
                    interval: 250
                    onTriggered: {
                        const out = [], page = pageLoader.item
                        if (!page || page.kitPage) { jumps.cards = []; return }
                        const find = o => { if (!o) return; if (typeof o.title === "string" && o.title !== "" && o.subtitle !== undefined && o.visible) { out.push({ title: o.title, icon: o.icon ?? "" }); return } for (const ch of (o.item ? [o.item] : []).concat(Array.from(o.children ?? []))) find(ch) }
                        find(page)
                        jumps.cards = out
                        jumps.contentX = 0
                    }
                }
            }

            Flickable {
                id: pageFlick
                Connections { target: root; function onScrollTo(y) { pageFlick.contentY = Math.max(0, Math.min(pageFlick.contentHeight - pageFlick.height, y)) } }
                anchors { left: parent.left; right: parent.right; top: header.visible ? header.bottom : parent.top; bottom: parent.bottom; topMargin: header.visible ? 18 : 0 }
                contentHeight: pageLoader.implicitHeight + (content.kit ? 56 : 28)
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
                    x: content.colX
                    y: content.kit ? 28 : 0
                    width: content.colW
                    sourceComponent: root.comps[root.curId] ?? startC
                    visible: root.query === ""
                    onSourceComponentChanged: { pageFlick.contentY = 0; pageIn.restart(); jumpT.restart() }
                    onLoaded: jumpT.restart()
                    // troca de pagina: entra subindo um pouco e aparecendo (curto: e navegacao frequente)
                    property real shift: 0
                    transform: Translate { y: pageLoader.shift }
                    ParallelAnimation {
                        id: pageIn
                        NumberAnimation { target: pageLoader; property: "opacity"; from: 0.4; to: 1; duration: 160; easing.type: Easing.OutCubic }
                        NumberAnimation { target: pageLoader; property: "shift"; from: 8; to: 0; duration: 180; easing.type: Easing.OutCubic }
                    }
                }
            }
            // barra de rolagem fina (so aparece se a pagina for maior que a janela)
            Rectangle {
                visible: pageFlick.contentHeight > pageFlick.height && root.query === ""
                anchors.right: parent.right; anchors.rightMargin: 6
                y: pageFlick.y + pageFlick.contentY / pageFlick.contentHeight * pageFlick.height
                width: 4; radius: 2
                height: Math.max(30, pageFlick.height * pageFlick.height / pageFlick.contentHeight)
                color: Theme.border
            }
            // ---- resultados da busca ----
            Flickable {
                id: resFlick
                visible: root.query !== ""
                x: content.colX
                width: content.colW
                anchors { top: header.bottom; bottom: parent.bottom; topMargin: 18; bottomMargin: 14 }
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
