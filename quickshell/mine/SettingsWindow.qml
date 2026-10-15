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
    property var geo: ({})
    readonly property bool panelOpen: Settings.launcherOpen || Settings.wpPickerOpen || Settings.homeOpen
    // painel acoplado aberto agora (retangulo dele na moldura): a janela tenta desviar dele em vez de sumir
    readonly property var busy: Settings.wpPickerOpen ? geo.picker : (Settings.launcherOpen ? geo.launcher : (Settings.homeOpen ? geo.home : null))
    property string page: "bars"

    IpcHandler {
        target: "settings"
        function toggle(): void { Settings.settingsOpen = !Settings.settingsOpen }
        function close(): void { Settings.settingsOpen = false }
        function isopen(): bool { return root.open }
        function go(p: string): void { root.page = p; Settings.settingsOpen = true }   // abre numa pagina (bars, look, wall...)
    }
    // abrir as configuracoes (pelo atalho ou pelo botao do Inicio) fecha os paineis que estiverem abertos
    onOpenChanged: if (open) { Settings.launcherOpen = false; Settings.wpPickerOpen = false; Settings.homeOpen = false; alive = true }
    property bool alive: false   // janela existe (fica ate a animacao de saida terminar)

    readonly property var groups: [
        { label: "Shell", pages: [
            { id: "bars", label: "Barras", icon: "bars", desc: "Onde ficam as barras e o que cada uma mostra." },
            { id: "frame", label: "Moldura", icon: "frame", desc: "O contorno da tela e as curvas que ligam as barras a ele." },
            { id: "look", label: "Aparência", icon: "palette", desc: "Vidro, tema de cores e cores manuais." },
            { id: "blur", label: "Blur", icon: "blur", desc: "Desfoque do Hyprland e da moldura." }
        ] },
        { label: "Painéis", pages: [
            { id: "home", label: "Início", icon: "dashboard", desc: "O painel com mídia, áudio, sistema e conexões (Super)." },
            { id: "launcher", label: "Launcher", icon: "apps", desc: "O menu de aplicativos (Super + Tab)." },
            { id: "wall", label: "Wallpaper", icon: "wallpaper", desc: "Imagem de fundo, transições e o seletor (Super + W)." },
            { id: "notifications", label: "Notificações", icon: "bell", desc: "Os avisos que saem da moldura." }
        ] },
        { label: "Avançado", pages: [
            { id: "anim", label: "Animações", icon: "animation", desc: "Curvas e durações usadas pelas animações do shell." }
        ] }
    ]
    readonly property var cur: groups.reduce((a, g) => a.concat(g.pages), []).find(p => p.id === page) ?? groups[0].pages[0]

    LazyLoader {
        active: root.alive

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

            // ---- entrada/saida: a mesma animacao de camadas do Hyprland (hyprland/animations.lua), feita aqui ----
            // layersIn: slide 500 ms emphasizedDecel | layersOut: slide 400 ms emphasizedAccel | fadeLayers: 500 ms standard
            // (o Hyprland nao anima esta janela: regra no_anim gerada pelo HyprSync)
            property real sp: 0   // deslize: 0 = uma tela inteira acima, 1 = no lugar
            property real fp: 0   // opacidade
            Component.onCompleted: { contentItem.opacity = Qt.binding(() => win.fp); inAnim.start() }
            Connections {
                target: root
                function onOpenChanged() { if (root.open) { outAnim.stop(); inAnim.start() } else { inAnim.stop(); outAnim.start() } }
            }
            ParallelAnimation {
                id: inAnim
                NumberAnimation { target: win; property: "sp"; to: 1; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
                NumberAnimation { target: win; property: "fp"; to: 1; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
            }
            ParallelAnimation {
                id: outAnim
                NumberAnimation { target: win; property: "sp"; to: 0; duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1] }
                NumberAnimation { target: win; property: "fp"; to: 0; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
                onFinished: root.alive = false
            }

            readonly property real bw: Math.min(1000, width - 40)
            readonly property real bh: Math.min(720, height - 80)
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

            Rectangle {
                id: body
                transform: Translate { y: -win.height * (1 - win.sp) }
                x: win.away ? win.cx0 : win.place.x
                y: win.away ? win.cy0 : win.place.y
                width: win.bw; height: win.bh
                // so anima o desvio dos paineis: ao abrir a janela ja nasce no lugar (senao viria do canto, na diagonal)
                property bool settled: false
                Timer { interval: 120; running: win.width > 0; onTriggered: body.settled = true }
                Behavior on x { enabled: body.settled; NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on y { enabled: body.settled; NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                radius: 22
                color: Theme.gl(Theme.bg, 1)
                clip: true
                focus: true
                Keys.onEscapePressed: Settings.settingsOpen = false
                opacity: win.away ? 0 : 1
                scale: win.away ? 0.96 : 1
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                // contorno desenhado por cima de tudo (senao a barra lateral cobre a borda)
                Rectangle { anchors.fill: parent; radius: 22; color: "transparent"; border.width: 1; border.color: Theme.border; z: 100 }

                // ---- barra lateral ----
                Item {
                    id: side
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 232
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
                                Text { text: "Quickshell"; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                                Text { text: "Configurações"; color: Theme.muted; font.pixelSize: 12 }
                            }
                        }

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
                                        readonly property bool on: root.page === modelData.id
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
                                        Text {
                                            anchors { left: navIc.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                            text: nav.modelData.label
                                            color: nav.on ? Theme.text : Theme.muted
                                            font.pixelSize: 14; font.weight: nav.on ? Font.DemiBold : Font.Medium
                                        }
                                        MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = nav.modelData.id }
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
                            Text { text: root.cur.label; color: Theme.text; font.pixelSize: 24; font.weight: Font.Bold }
                            Text { text: root.cur.desc; color: Theme.muted; font.pixelSize: 13; elide: Text.ElideRight; width: parent.width }
                        }
                        UiButton { id: closeBtn; anchors { right: parent.right; top: parent.top } icon: "close"; kind: "ghost"; onClicked: Settings.settingsOpen = false }
                    }

                    Flickable {
                        id: pageFlick
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
                            sourceComponent: ({ bars: barsC, home: homeC, notifications: notifC, launcher: launcherC, frame: frameC, blur: blurC, anim: animC, wall: wallC, look: lookC })[root.page] ?? lookC
                            onSourceComponentChanged: pageFlick.contentY = 0
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
                    Component { id: barsC; PageBars {} }
                    Component { id: homeC; PageHome {} }
                    Component { id: notifC; PageNotifications {} }
                    Component { id: launcherC; PageLauncher {} }
                    Component { id: frameC; PageFrame {} }
                    Component { id: lookC; PageLook {} }
                    Component { id: blurC; PageBlur {} }
                    Component { id: animC; PageAnim {} }
                    Component { id: wallC; PageWallpaper {} }
                }
            }
        }
    }
}
