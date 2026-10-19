// Ilha dinamica (modulo "island"): uma pilula que muda de forma conforme o que acontece. Prioridade:
// notificacao nova (alguns segundos) > volume / microfone / midia (ao mudar) > gravando a tela > timer correndo >
// musica tocando > repouso (relogio, janela ativa ou so um ponto). Numa barra com "Largura do conteudo" a propria
// moldura cresce junto: vira um entalhe que respira. Mudanca de forma: animacao "Ilha dinamica" (pagina Animacoes).
// Clique: relogio abre o Inicio; musica toca/pausa (passar o mouse mostra anterior/proxima); notificacao abre a central;
// gravacao para; timer pausa/continua. Opcoes: idle (clock | window | dot), notifs, osd, media, timer, rec, pill.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: root
    property var opts: ({})
    property bool vertical: false
    readonly property color fg: Settings.textColor
    readonly property color ac: Settings.accent
    function on(k) { return opts[k] !== false }

    // ---- o que mostrar ----
    property string notifText: ""
    property string notifIcon: ""
    property real notifUntil: 0
    property real osdUntil: 0
    property real now: Date.now()
    Timer { interval: 500; repeat: true; running: root.notifUntil > root.now || root.osdUntil > root.now || root.mode === "timer" || root.mode === "rec"; onTriggered: root.now = Date.now() }
    Connections {
        target: NotifHistory
        function onItemsChanged() {
            const n = NotifHistory.items[0]
            if (!n || !root.on("notifs") || Settings.notifDnd || Date.now() - n.time > 2000) return
            root.notifText = n.summary || n.app
            root.notifIcon = n.icon || n.app
            root.now = Date.now(); root.notifUntil = root.now + 5000
        }
    }
    Connections {
        target: Osd
        function onBumpChanged() { if (root.on("osd")) { root.now = Date.now(); root.osdUntil = root.now + 1800 } }
    }
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property var timer: {
        Timers.now
        for (const id in Timers.st) if (Timers.st[id].running) { const w = Timers.lookup(id); if (w) return { id: id, w: w } }
        return null
    }
    readonly property string mode: notifUntil > now ? "notif"
        : osdUntil > now ? "osd"
        : Recorder.active && on("rec") ? "rec"
        : timer && on("timer") ? "timer"
        : player && on("media") ? "media"
        : "idle"
    readonly property string idleKind: opts.idle ?? "clock"

    // ---- forma ----
    readonly property real pillH: vertical ? 0 : 26
    readonly property var cur: ({ idle: idleC, media: mediaC, notif: notifC, osd: osdC, rec: recC, timer: timerC })[mode]
    property real targetW: vertical ? 26 : 60
    property real w: targetW
    Behavior on w { MotionAnim { use: "island" } }
    implicitWidth: vertical ? 26 : Math.max(26, w)
    implicitHeight: vertical ? Math.max(26, w) : 26

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        visible: root.opts.pill !== false
        color: root.mode === "rec" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : Qt.rgba(root.ac.r, root.ac.g, root.ac.b, hm.hovered ? 0.2 : 0.11)
        Behavior on color { ColorAnimation { duration: 220 } }
    }
    HoverHandler { id: hm }
    clip: true

    // o conteudo troca com um fade rapido; a largura segue o conteudo (animada)
    Loader {
        id: ld
        anchors.centerIn: parent
        sourceComponent: root.cur
        onLoaded: { item.opacity = 0; fadeIn.restart() }
        onItemChanged: if (item) root.targetW = (root.vertical ? item.implicitHeight : item.implicitWidth) + 22
        Connections { target: ld.item; ignoreUnknownSignals: true; function onImplicitWidthChanged() { if (!root.vertical) root.targetW = ld.item.implicitWidth + 22 } }
        NumberAnimation { id: fadeIn; target: ld.item; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: m => {
            if (root.mode === "media") { if (root.player) root.player.togglePlaying() }
            else if (root.mode === "notif") { root.notifUntil = 0; Settings.homeOpen = true }
            else if (root.mode === "rec") Recorder.stop()
            else if (root.mode === "timer") { const s = Timers.get(root.timer.id); if (s.running) Timers.pause(root.timer.id); else Timers.start(root.timer.id) }
            else Settings.homeOpen = !Settings.homeOpen
        }
        onWheel: w => { if (root.mode === "media" && root.player) { if (w.angleDelta.y < 0) root.player.next(); else root.player.previous() } }
    }

    // ---- conteudos ----
    Component {
        id: idleC
        Row {
            spacing: 8
            SystemClock { id: clk; precision: SystemClock.Minutes }
            readonly property var tl: Hyprland.activeToplevel
            Rectangle { visible: root.idleKind === "dot"; width: 6; height: 6; radius: 3; color: root.ac; anchors.verticalCenter: parent.verticalCenter }
            Image {
                visible: root.idleKind === "window" && !!parent.tl
                width: 16; height: 16; sourceSize: Qt.size(32, 32); anchors.verticalCenter: parent.verticalCenter
                source: parent.tl && parent.tl.lastIpcObject ? Icons.app(parent.tl.lastIpcObject.class || "") : ""
            }
            UiText {
                visible: root.idleKind !== "dot"
                anchors.verticalCenter: parent.verticalCenter
                text: root.vertical ? Qt.formatDateTime(clk.date, "HH\nmm")
                    : root.idleKind === "window" ? (parent.tl ? parent.tl.title : "").slice(0, 48) : Qt.formatDateTime(clk.date, root.opts.format || "HH:mm")
                color: root.fg; font.pixelSize: 13; font.weight: Font.DemiBold; font.features: { "tnum": 1 }
            }
        }
    }
    Component {
        id: mediaC
        Row {
            spacing: 8
            readonly property var p: root.player
            RoundImage {
                width: 18; height: 18; radius: 9; anchors.verticalCenter: parent.verticalCenter
                source: parent.p ? (parent.p.trackArtUrl || "") : ""
                sourceSize: Qt.size(48, 48)
                RotationAnimation on rotation { running: !!(root.player && root.player.isPlaying); from: 0; to: 360; duration: 9000; loops: Animation.Infinite }
            }
            UiText {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.opts.max ?? 260); elide: Text.ElideRight
                text: parent.p ? (parent.p.trackTitle || parent.p.identity) + (parent.p.trackArtist ? "  ·  " + parent.p.trackArtist : "") : ""
                color: root.fg; font.pixelSize: 12; font.weight: Font.Medium
            }
            // barrinhas animadas (cava se houver; senao um pulso)
            Row {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        required property int index
                        readonly property real v: Cava.available && Cava.values.length ? Cava.values[Math.floor(index * Cava.values.length / 4)] : 0.3 + 0.6 * Math.abs(Math.sin((root.now / 260) + index))
                        width: 2.5; height: 3 + 11 * v; radius: 1.25; color: root.ac
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Component.onCompleted: Cava.use()
                Component.onDestruction: Cava.release()
                Timer { interval: 120; repeat: true; running: !Cava.available; onTriggered: root.now = Date.now() }
            }
            // passar o mouse: anterior / proxima
            Row {
                visible: hm.hovered && !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: [["prev", () => root.player.previous()], [root.player && root.player.isPlaying ? "pause" : "play", () => root.player.togglePlaying()], ["next", () => root.player.next()]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 20; height: 20; radius: 10; color: bm.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.16) : "transparent"
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 13; color: root.fg }
                        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
                    }
                }
            }
        }
    }
    Component {
        id: notifC
        Row {
            spacing: 8
            Image {
                width: 16; height: 16; sourceSize: Qt.size(32, 32); anchors.verticalCenter: parent.verticalCenter
                source: Icons.path(root.notifIcon, "dialog-information")
            }
            UiText {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 320); elide: Text.ElideRight
                text: root.notifText; color: root.fg; font.pixelSize: 12; font.weight: Font.DemiBold
            }
        }
    }
    Component {
        id: osdC
        Row {
            spacing: 8
            readonly property bool mic: Osd.bumpKind === "mic"
            readonly property bool media: Osd.bumpKind === "media"
            UiIcon {
                anchors.verticalCenter: parent.verticalCenter; size: 15; color: root.ac
                name: parent.media ? Osd.mediaIcon : parent.mic ? (Osd.micMuted ? "micOff" : "mic") : (Osd.muted ? "volumeOff" : Osd.volume < 0.34 ? "volumeLow" : Osd.volume < 0.67 ? "volumeMed" : "volume")
            }
            UiText { visible: parent.media && !root.vertical; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, 240); elide: Text.ElideRight; text: Osd.mediaText; color: root.fg; font.pixelSize: 12 }
            Rectangle {
                visible: !parent.media && !parent.mic && !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                width: 110; height: 5; radius: 2.5; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.18)
                Rectangle { width: parent.width * Math.min(1, Osd.volume); height: parent.height; radius: 2.5; color: Osd.muted ? Theme.muted : root.ac
                    Behavior on width { NumberAnimation { duration: 120 } } }
            }
            UiText {
                visible: !parent.media && !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                text: parent.mic ? (Osd.micMuted ? "Mudo" : "Ligado") : (Osd.muted ? "Mudo" : Math.round(Osd.volume * 100) + "%")
                color: root.fg; font.pixelSize: 12; font.features: { "tnum": 1 }
            }
        }
    }
    Component {
        id: recC
        Row {
            spacing: 7
            Rectangle {
                width: 9; height: 9; radius: 4.5; color: Theme.danger; anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0.35; duration: 600 } NumberAnimation { to: 1; duration: 600 } }
            }
            UiText { visible: !root.vertical; anchors.verticalCenter: parent.verticalCenter; text: "Gravando " + Recorder.elapsed; color: root.fg; font.pixelSize: 12; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
        }
    }
    Component {
        id: timerC
        Row {
            spacing: 7
            readonly property var t: root.timer
            readonly property real total: t ? Timers.total(t.w) : 0
            readonly property real remain: t ? (total > 0 ? Math.max(0, total - Timers.elapsed(t.id)) : Timers.elapsed(t.id)) : 0
            readonly property string phase: t ? Timers.get(t.id).phase : "focus"
            UiIcon { name: phase === "focus" ? "timer" : "coffee"; size: 15; color: phase === "focus" ? root.ac : Theme.tertiary; anchors.verticalCenter: parent.verticalCenter }
            UiText {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                text: { const s = Math.round(parent.remain / 1000); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") + (parent.phase === "focus" ? "" : "  pausa") }
                color: root.fg; font.pixelSize: 12; font.weight: Font.DemiBold; font.features: { "tnum": 1 }
            }
        }
    }
}
