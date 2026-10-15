// Painel "Inicio": cartao do usuario, player de midia, atalhos (Wi-Fi, Bluetooth, cafeina, nao perturbe, perfil de energia, vidro) e relogio.
// Acoplado a moldura (sai da borda como o launcher) ou flutuante, conforme Settings.home*.
// IPC:  qs -c mine ipc call home toggle | open | close
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

Scope {
    id: root
    property var geo: ({ home: null })        // resultado de Geometry.compute (vem do shell.qml)
    readonly property bool open: Settings.homeOpen
    property bool alive: false

    IpcHandler {
        target: "home"
        function toggle(): void { Settings.homeOpen = !Settings.homeOpen }
        function open(): void { Settings.homeOpen = true }
        function close(): void { Settings.homeOpen = false }
    }
    onOpenChanged: {
        if (open) { closeTimer.stop(); Settings.launcherOpen = false; Settings.wpPickerOpen = false; Settings.settingsOpen = false; alive = true }
        else closeTimer.restart()
    }
    Timer { id: closeTimer; interval: 520; onTriggered: root.alive = false }

    // ---- estado dos atalhos (consultado ao abrir e a cada poucos segundos enquanto aberto) ----
    property bool wifiOn: false
    property bool btOn: false
    property string profile: "balanced"
    property string upText: ""
    property string hostName: ""

    Process { id: pWifi; command: ["nmcli", "radio", "wifi"]; stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" } }
    Process { id: pBt; command: ["sh", "-c", "timeout 2 bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo yes || echo no"]; stdout: StdioCollector { onStreamFinished: root.btOn = text.trim() === "yes" } }
    Process { id: pProf; command: ["powerprofilesctl", "get"]; stdout: StdioCollector { onStreamFinished: root.profile = text.trim() || "balanced" } }
    Process { id: pUp; command: ["cat", "/proc/uptime"]; stdout: StdioCollector { onStreamFinished: {
        const sec = Math.floor(parseFloat(text.split(" ")[0]) || 0), h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60)
        root.upText = (h > 0 ? h + (h === 1 ? " hora " : " horas ") : "") + m + (m === 1 ? " minuto" : " minutos")
    } } }
    Process { id: pHost; command: ["cat", "/etc/hostname"]; stdout: StdioCollector { onStreamFinished: root.hostName = text.trim() } }
    function refresh() { pWifi.running = false; pWifi.running = true; pBt.running = false; pBt.running = true; pProf.running = false; pProf.running = true; pUp.running = false; pUp.running = true }
    Timer { interval: 4000; repeat: true; running: root.alive; onTriggered: root.refresh() }
    onAliveChanged: if (alive) { refresh(); pHost.running = false; pHost.running = true }

    Process { id: pAct }
    function run(cmd) { pAct.command = cmd; pAct.running = false; pAct.running = true }
    function toggleWifi() { root.wifiOn = !root.wifiOn; run(["nmcli", "radio", "wifi", root.wifiOn ? "on" : "off"]) }
    function toggleBt() { root.btOn = !root.btOn; run(["timeout", "4", "bluetoothctl", "power", root.btOn ? "on" : "off"]) }
    function cycleProfile() {
        const next = { "balanced": "performance", "performance": "power-saver", "power-saver": "balanced" }[root.profile] ?? "balanced"
        root.profile = next
        run(["powerprofilesctl", "set", next])
    }
    // cafeina: mantem um "inhibit" de ociosidade enquanto estiver ligada
    property bool caffeine: false
    Process { id: pCaf; running: root.caffeine; command: ["systemd-inhibit", "--what=idle:sleep", "--who=Quickshell", "--why=Cafeina", "--mode=block", "sleep", "infinity"] }

    // ---- midia ----
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? (players.length > 0 ? players[0] : null)

    function fmt(sec) { sec = Math.max(0, Math.floor(sec || 0)); return Math.floor(sec / 60) + ":" + ("0" + (sec % 60)).slice(-2) }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "mine-home"

            // ---- geometria (mesmo esquema do launcher) ----
            readonly property bool docked: Settings.homeDocked
            readonly property string side: Settings.homeSide
            readonly property real e: Settings.edge
            readonly property real cw: BarState.homeW
            readonly property real ch: BarState.homeH
            property real fprog: root.open ? 1 : 0
            Behavior on fprog {
                NumberAnimation {
                    duration: Settings.animOf("home").duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Settings.animOf("home").curve
                }
            }
            readonly property real pp: docked ? BarState.homeProg : fprog
            readonly property var pk: root.geo.home
            readonly property rect dbox: !pk ? Qt.rect(0, 0, 0, 0) : (
                side === "top" ? Qt.rect(pk.rect.x + (pk.rect.w - cw) / 2, pk.rect.y + e + 8, cw, ch)
                : side === "bottom" ? Qt.rect(pk.rect.x + (pk.rect.w - cw) / 2, pk.rect.y + 12, cw, ch)
                : side === "left" ? Qt.rect(pk.rect.x + e + 8, pk.rect.y + (pk.rect.h - ch) / 2, cw, ch)
                : Qt.rect(pk.rect.x + 12, pk.rect.y + (pk.rect.h - ch) / 2, cw, ch))
            readonly property rect fbox: Qt.rect((width - cw) / 2, (height - ch) / 2 + (1 - Math.min(1, pp)) * 18, cw, ch)
            readonly property rect box: docked ? dbox : fbox
            readonly property real fullDepth: docked && pk ? pk.t : 0
            readonly property real vis: docked ? Math.max(0, Math.min(fullDepth, e + (fullDepth - e) * pp)) : 0
            readonly property rect clipR: !docked || !pk ? Qt.rect(0, 0, 0, 0)
                : side === "top" ? Qt.rect(pk.rect.x, 0, pk.rect.w, vis)
                : side === "bottom" ? Qt.rect(pk.rect.x, height - vis, pk.rect.w, vis)
                : side === "left" ? Qt.rect(0, pk.rect.y, vis, pk.rect.h)
                : Qt.rect(width - vis, pk.rect.y, vis, pk.rect.h)
            readonly property real lag: docked ? fullDepth - vis : 0

            MouseArea { anchors.fill: parent; onClicked: Settings.homeOpen = false }

            Item {
                id: holder
                x: win.docked ? win.clipR.x : 0
                y: win.docked ? win.clipR.y : 0
                width: win.docked ? win.clipR.width : win.width
                height: win.docked ? win.clipR.height : win.height
                clip: win.docked
                MouseArea { anchors.fill: parent; visible: win.docked }

                Item {
                    id: inner
                    x: -holder.x + (win.side === "left" ? -win.lag : (win.side === "right" ? win.lag : 0))
                    y: -holder.y + (win.side === "top" ? -win.lag : (win.side === "bottom" ? win.lag : 0))
                    width: win.width; height: win.height
                    opacity: win.docked ? Math.max(0, Math.min(1, win.pp * 1.4 - 0.2)) : Math.max(0, Math.min(1, win.pp * 1.6))

                    Rectangle {
                        id: panel
                        x: win.box.x; y: win.box.y
                        width: win.box.width; height: win.box.height
                        radius: win.docked ? 0 : Settings.homeRadius + 6
                        color: win.docked ? "transparent" : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.glass ? Math.min(1, Settings.glassOpacity / 100 + 0.08) : 1)
                        border.width: win.docked ? 0 : 1; border.color: Theme.border
                        scale: win.docked ? 1 : 0.94 + 0.06 * Math.min(1, win.pp)
                        transformOrigin: Item.Top
                        focus: true
                        Keys.onEscapePressed: Settings.homeOpen = false
                        MouseArea { anchors.fill: parent }

                        // ---------- cabecalho ----------
                        Text { x: 22; y: 14; text: "Início"; color: Theme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
                        Row {
                            anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 8 }
                            spacing: 8
                            component HBtn: Rectangle {
                                id: hb
                                property string glyph
                                signal clicked()
                                width: 34; height: 34; radius: 10
                                color: hbm.containsMouse ? Theme.cardHi : Theme.card
                                border.width: 1; border.color: Theme.border
                                Text { anchors.centerIn: parent; text: hb.glyph; color: Theme.text; font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font" }
                                MouseArea { id: hbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hb.clicked() }
                            }
                            HBtn { glyph: String.fromCodePoint(0xF013); onClicked: { Settings.homeOpen = false; Settings.settingsOpen = true } }
                            HBtn { glyph: String.fromCodePoint(0xF00D); onClicked: Settings.homeOpen = false }
                        }

                        // mascara arredondada compartilhada (fora da area visivel: item invisivel nao atualiza a textura)
                        Rectangle { id: round14; x: -width - 30; y: 0; width: 200; height: 200; radius: 14; layer.enabled: true; color: "white" }
                        Rectangle { id: round10; x: -width - 30; y: 220; width: 200; height: 200; radius: 10; layer.enabled: true; color: "white" }

                        // ---------- cartao do usuario ----------
                        Rectangle {
                            id: userCard
                            x: 16; y: 54; width: parent.width - 32; height: 130; radius: 14
                            color: Theme.card; border.width: 1; border.color: Theme.border
                            Image {
                                id: bgImg
                                x: 1; y: 1; width: parent.width - 2; height: parent.height - 2
                                source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
                                sourceSize: Qt.size(560, 160)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false
                            }
                            MultiEffect {
                                x: 1; y: 1; width: parent.width - 2; height: parent.height - 2
                                source: bgImg
                                maskEnabled: true
                                maskSource: round14
                                blurEnabled: true; blurMax: 24; blur: 0.5
                                brightness: -0.45
                            }
                            // avatar: ~/.face se existir, senao a inicial
                            Rectangle {
                                id: avatar
                                x: 22; y: 22; width: 86; height: 86; radius: 43
                                color: Qt.rgba(1, 1, 1, 0.12)
                                border.width: 2; border.color: Theme.accent
                                Text { anchors.centerIn: parent; text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase(); color: Theme.text; font.pixelSize: 36; font.weight: Font.Bold; visible: faceImg.status !== Image.Ready }
                                Image { id: faceImg; anchors.fill: parent; anchors.margins: 2; source: "file://" + Quickshell.env("HOME") + "/.face"; fillMode: Image.PreserveAspectCrop; visible: false; asynchronous: true }
                                MultiEffect { anchors.fill: faceImg; source: faceImg; visible: faceImg.status === Image.Ready; maskEnabled: true; maskSource: faceMask }
                                Rectangle { id: faceMask; x: -200; width: 82; height: 82; radius: 41; layer.enabled: true; color: "white" }
                            }
                            Column {
                                anchors { left: avatar.right; leftMargin: 22; verticalCenter: parent.verticalCenter }
                                spacing: 4
                                Text { text: Quickshell.env("USER"); color: "white"; font.pixelSize: 20; font.weight: Font.Bold }
                                Text { text: Quickshell.env("USER") + "@" + (root.hostName || "linux"); color: Qt.rgba(1, 1, 1, 0.78); font.pixelSize: 13 }
                                Text { text: "Tempo ativo – " + root.upText; color: Qt.rgba(1, 1, 1, 0.78); font.pixelSize: 13; visible: root.upText !== "" }
                                Text { text: "Quickshell"; color: Qt.rgba(1, 1, 1, 0.78); font.pixelSize: 13 }
                            }
                        }

                        // ---------- midia ----------
                        Rectangle {
                            id: mediaCard
                            x: 16; y: 194; width: 296; height: 142; radius: 14
                            color: Theme.card; border.width: 1; border.color: Theme.border
                            readonly property var pl: root.player
                            Item {
                                visible: !mediaCard.pl
                                anchors.fill: parent
                                Text { anchors.centerIn: parent; text: "Nada tocando"; color: Theme.muted; font.pixelSize: 13 }
                            }
                            Item {
                                visible: !!mediaCard.pl
                                anchors.fill: parent
                                Image {
                                    id: art
                                    x: 12; y: 12; width: 80; height: 80
                                    source: mediaCard.pl ? mediaCard.pl.trackArtUrl : ""
                                    sourceSize: Qt.size(160, 160)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: false
                                }
                                Rectangle { x: 12; y: 12; width: 80; height: 80; radius: 10; color: Theme.cardHi; visible: art.status !== Image.Ready }
                                MultiEffect { x: 12; y: 12; width: 80; height: 80; source: art; visible: art.status === Image.Ready; maskEnabled: true; maskSource: round10 }
                                Column {
                                    x: 104; y: 14; width: parent.width - 116
                                    spacing: 3
                                    Text { width: parent.width; text: mediaCard.pl ? mediaCard.pl.trackTitle : ""; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                    Text { width: parent.width; text: mediaCard.pl ? mediaCard.pl.trackArtist : ""; color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight }
                                    Text { width: parent.width; text: mediaCard.pl ? (mediaCard.pl.isPlaying ? "Reproduzindo" : "Pausado") + (mediaCard.pl.lengthSupported ? " · " + root.fmt(mediaCard.pl.position) + " / " + root.fmt(mediaCard.pl.length) : "") : ""; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
                                }
                                Timer { interval: 1000; repeat: true; running: !!mediaCard.pl && mediaCard.pl.isPlaying && root.alive; onTriggered: mediaCard.pl.positionChanged() }
                                // barra de progresso
                                Rectangle {
                                    x: 12; y: 102; width: parent.width - 24; height: 5; radius: 2.5
                                    color: Qt.rgba(1, 1, 1, 0.12)
                                    visible: !!mediaCard.pl && mediaCard.pl.lengthSupported && mediaCard.pl.length > 0
                                    Rectangle { width: parent.width * Math.max(0, Math.min(1, mediaCard.pl ? mediaCard.pl.position / Math.max(1, mediaCard.pl.length) : 0)); height: parent.height; radius: 2.5; color: Theme.accent }
                                }
                                // controles
                                Row {
                                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                                    spacing: 10
                                    component MBtn: Rectangle {
                                        id: mb
                                        property string glyph
                                        property bool main: false
                                        signal clicked()
                                        width: main ? 34 : 28; height: width; radius: width / 2
                                        color: mbm.containsMouse ? Theme.cardHi : (main ? Theme.accent : "transparent")
                                        Text { anchors.centerIn: parent; text: mb.glyph; color: mb.main ? Theme.accentText : Theme.text; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font" }
                                        MouseArea { id: mbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mb.clicked() }
                                    }
                                    MBtn { glyph: String.fromCodePoint(0xF048); onClicked: if (mediaCard.pl && mediaCard.pl.canGoPrevious) mediaCard.pl.previous() }
                                    MBtn { main: true; glyph: String.fromCodePoint(mediaCard.pl && mediaCard.pl.isPlaying ? 0xF04C : 0xF04B); onClicked: if (mediaCard.pl && mediaCard.pl.canTogglePlaying) mediaCard.pl.togglePlaying() }
                                    MBtn { glyph: String.fromCodePoint(0xF051); onClicked: if (mediaCard.pl && mediaCard.pl.canGoNext) mediaCard.pl.next() }
                                }
                            }
                        }

                        // ---------- relogio ----------
                        Rectangle {
                            x: 16; y: 346; width: 296; height: 90; radius: 14
                            color: Theme.card; border.width: 1; border.color: Theme.border
                            SystemClock { id: clk; precision: SystemClock.Minutes }
                            Text { x: 20; anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDateTime(clk.date, "HH:mm"); color: Theme.text; font.pixelSize: 38; font.weight: Font.Bold }
                            Column {
                                anchors { left: parent.left; leftMargin: 138; verticalCenter: parent.verticalCenter }
                                spacing: 3
                                Text { text: clk.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, dd/MM/yyyy"); color: Theme.text; font.pixelSize: 12 }
                                Text { text: clk.date.toLocaleDateString(Qt.locale("pt_BR"), "MMMM"); color: Theme.muted; font.pixelSize: 12 }
                            }
                        }

                        // ---------- atalhos ----------
                        component Tile: Rectangle {
                            id: tl
                            property string glyph
                            property string label
                            property bool on: false
                            signal clicked()
                            width: 124; height: 80; radius: 14
                            color: on ? Theme.accent : (tlm.containsMouse ? Theme.cardHi : Theme.card)
                            border.width: 1; border.color: on ? Theme.accent : Theme.border
                            Column {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: tl.glyph; color: tl.on ? Theme.accentText : Theme.text; font.pixelSize: 22; font.family: "JetBrainsMono Nerd Font" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: tl.label; color: tl.on ? Theme.accentText : Theme.text; font.pixelSize: 12; elide: Text.ElideRight; width: tl.width - 12; horizontalAlignment: Text.AlignHCenter }
                            }
                            MouseArea { id: tlm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tl.clicked() }
                        }
                        Grid {
                            x: 324; y: 194
                            columns: 2; spacing: 8
                            Tile { glyph: String.fromCodePoint(0xF1EB); label: "Wi-Fi"; on: root.wifiOn; onClicked: root.toggleWifi() }
                            Tile { glyph: String.fromCodePoint(0xF293); label: "Bluetooth"; on: root.btOn; onClicked: root.toggleBt() }
                            Tile { glyph: String.fromCodePoint(0xF0F4); label: "Cafeína"; on: root.caffeine; onClicked: root.caffeine = !root.caffeine }
                            Tile { glyph: String.fromCodePoint(0xF1F6); label: "Não perturbe"; on: Settings.notifDnd; onClicked: Settings.notifDnd = !Settings.notifDnd }
                            Tile { glyph: String.fromCodePoint(0xF0E7); label: ({ "balanced": "Equilibrado", "performance": "Desempenho", "power-saver": "Economia" })[root.profile] ?? root.profile; on: root.profile === "performance"; onClicked: root.cycleProfile() }
                            Tile { glyph: String.fromCodePoint(0xF06E); label: "Vidro"; on: Settings.glass; onClicked: Settings.glass = !Settings.glass }
                        }
                    }
                }
            }
        }
    }
}
