// Ilha dinamica (modulo "island"): uma pilula que muda de forma conforme o que acontece. Prioridade:
// notificacao nova (alguns segundos) > volume / microfone / midia (ao mudar) > gravando a tela > timer correndo >
// musica tocando > repouso (relogio, janela ativa ou so um ponto). Numa barra com "Largura do conteudo" a propria
// moldura cresce junto: vira um entalhe que respira. Mudanca de forma: animacao "Ilha dinamica" (pagina Animacoes).
// Clique: relogio abre o Inicio; musica toca/pausa (passar o mouse mostra anterior/proxima); notificacao abre a central;
// gravacao para; timer pausa/continua (botao direito zera). A roda do mouse alterna "so repouso" (a ilha volta ao relogio
// mesmo com musica); com Ctrl, ou sobre os botoes, a roda troca de faixa. Com uma ilha ligada em "notificacoes" / "volume",
// os cartoes de notificacao e o indicador de volume nao aparecem (a ilha mostra no lugar).
// Outros modos ativos viram bolinhas ao lado da pilula; clicar numa promove aquele modo. Em repouso pode mostrar a foto, icones de
// estado (microfone / som mudo, sem rede, notificacoes) e o clima. A musica pode abrir sozinha por 3 s ao trocar de faixa, ter
// visualizador em barras ou onda e botoes sempre visiveis. Brilho e luz noturna aparecem como o volume.
// Opcoes: idle (clock | window | weather | dot), avatar, status, notifs, osd, media, visualizer (bars | wave | none), controls (hover | always | never),
// expand, timer, rec, pill.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Networking
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
    property string notifBody: ""
    property bool forceIdle: false   // roda do mouse: fica so no repouso (nao nasce nada no lugar)
    property bool btnHover: false
    property string notifIcon: ""
    property real notifUntil: 0
    property real osdUntil: 0
    property string osdKind: "volume"
    property string forced: ""      // modo promovido pelas bolinhas
    property bool expandNow: false   // musica aberta por alguns segundos depois de trocar de faixa
    property real now: Date.now()
    Timer { interval: 500; repeat: true; running: root.notifUntil > root.now || root.osdUntil > root.now || root.mode === "timer" || root.mode === "rec"; onTriggered: root.now = Date.now() }
    Connections {
        target: NotifHistory
        function onItemsChanged() {
            const n = NotifHistory.items[0]
            if (!n || !root.on("notifs") || Settings.notifDnd || Date.now() - n.time > 2000) return
            root.notifText = n.summary || n.app
            root.notifBody = (n.body || "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim()
            root.notifIcon = n.icon || n.app
            root.forced = ""
            root.now = Date.now(); root.notifUntil = root.now + Math.max(4000, Settings.notifTimeout * 1000)
        }
    }
    // a notificacao some da ilha quando some da tela (expirou ou foi dispensada)
    Connections {
        target: BarState
        function onNotifLiveChanged() { if (BarState.notifLive === 0) root.notifUntil = 0 }
    }
    Connections {
        target: Osd
        function onBumpChanged() { if (root.on("osd")) { root.osdKind = Osd.bumpKind; root.now = Date.now(); root.osdUntil = root.now + 1800 } }
    }
    // brilho e luz noturna: aparecem como o volume (so depois de uns segundos de shell no ar)
    property bool ready: false
    Timer { interval: 4000; running: true; onTriggered: root.ready = true }
    Connections {
        target: Brightness
        function onValueChanged() { if (root.ready && root.on("osd")) { root.osdKind = "bright"; root.now = Date.now(); root.osdUntil = root.now + 1800 } }
    }
    Connections {
        target: Settings
        function onNightTempChanged() { if (root.ready && root.on("osd")) { root.osdKind = "night"; root.now = Date.now(); root.osdUntil = root.now + 1800 } }
        function onNightGammaChanged() { if (root.ready && root.on("osd")) { root.osdKind = "night"; root.now = Date.now(); root.osdUntil = root.now + 1800 } }
    }
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property var timer: {
        Timers.now
        for (const id in Timers.st) if (Timers.st[id].running) { const w = Timers.lookup(id); if (w) return { id: id, w: w } }
        return null
    }
    function activeOf(m) {
        return m === "notif" ? notifUntil > now : m === "osd" ? osdUntil > now : m === "rec" ? Recorder.active && on("rec")
            : m === "timer" ? !!timer && on("timer") : m === "media" ? !!player && on("media") : false
    }
    readonly property string autoMode: notifUntil > now ? "notif"
        : osdUntil > now ? "osd"
        : forceIdle ? "idle"
        : Recorder.active && on("rec") ? "rec"
        : timer && on("timer") ? "timer"
        : player && on("media") ? "media"
        : "idle"
    readonly property string mode: forced !== "" && activeOf(forced) ? forced : autoMode
    // outros modos ativos: bolinhas ao lado da pilula (clicar promove)
    readonly property var others: ["notif", "osd", "rec", "timer", "media"].filter(m => m !== mode && activeOf(m))
    readonly property var badgeIcon: ({ notif: "bell", osd: "volume", rec: "monitor", timer: "timer", media: "music" })
    // musica: abre por 3 s ao trocar de faixa
    readonly property string trackKey: player ? (player.trackTitle || "") + "|" + (player.trackArtist || "") : ""
    onTrackKeyChanged: if (ready && trackKey !== "") { expandNow = true; expandT.restart() }
    Timer { id: expandT; interval: 3000; onTriggered: root.expandNow = false }
    readonly property string idleKind: opts.idle ?? "clock"

    // ---- forma ----
    readonly property real pillH: vertical ? 0 : 26
    readonly property var cur: ({ idle: idleC, media: mediaC, notif: notifC, osd: osdC, rec: recC, timer: timerC })[mode]
    property real targetW: vertical ? 26 : 60
    property real w: targetW
    Behavior on w { MotionAnim { use: "island" } }
    readonly property real badgesLen: others.length > 0 ? others.length * 24 + 4 : 0
    implicitWidth: vertical ? 26 : Math.max(26, w) + badgesLen
    implicitHeight: vertical ? Math.max(26, w) + badgesLen : 26

    // bolinhas dos outros modos
    Row {
        id: badges
        visible: root.others.length > 0
        x: root.vertical ? 0 : Math.max(26, root.w) + 4
        y: root.vertical ? Math.max(26, root.w) + 4 : 0
        spacing: 2
        Repeater {
            model: root.others
            delegate: Rectangle {
                id: bd
                required property string modelData
                width: 22; height: 22; radius: 11
                y: root.vertical ? 0 : 2
                color: bdm.containsMouse ? Qt.rgba(root.ac.r, root.ac.g, root.ac.b, 0.3) : Qt.rgba(root.ac.r, root.ac.g, root.ac.b, 0.14)
                UiIcon { anchors.centerIn: parent; name: root.badgeIcon[bd.modelData] ?? "dot"; size: 12; color: bd.modelData === "rec" ? Theme.danger : root.ac }
                MouseArea { id: bdm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.forceIdle = false; root.forced = bd.modelData } }
            }
        }
    }

    Item {
    id: pillBox
    width: root.vertical ? 26 : Math.max(26, root.w)
    height: root.vertical ? Math.max(26, root.w) : 26
    clip: true
    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        visible: root.opts.pill !== false
        color: root.mode === "rec" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : Qt.rgba(root.ac.r, root.ac.g, root.ac.b, hm.hovered ? 0.2 : 0.11)
        Behavior on color { ColorAnimation { duration: 220 } }
    }
    HoverHandler { id: hm; onHoveredChanged: if (!hovered) root.btnHover = false }

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
    Timer { id: wheelT; interval: 220 }   // evita alternar varias vezes por um giro so da roda
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: m => {
            if (root.mode === "timer" && m.button === Qt.RightButton) { Timers.reset(root.timer.id); return }   // zera o timer
            if (root.mode === "media") { if (root.player) root.player.togglePlaying() }
            else if (root.mode === "notif") { root.notifUntil = 0; Settings.homeOpen = true }
            else if (root.mode === "rec") Recorder.stop()
            else if (root.mode === "timer") { const s = Timers.get(root.timer.id); if (s.running) Timers.pause(root.timer.id); else Timers.start(root.timer.id) }
            else Settings.homeOpen = !Settings.homeOpen
        }
        onWheel: w => {
            if (root.mode === "media" && root.player && ((w.modifiers & Qt.ControlModifier) || root.btnHover)) { if (w.angleDelta.y < 0) root.player.next(); else root.player.previous(); return }
            if (wheelT.running) return
            wheelT.restart()
            root.forceIdle = !root.forceIdle
        }
    }

    }   // pillBox

    // ---- conteudos ----
    Component {
        id: idleC
        Row {
            id: ir
            spacing: 8
            SystemClock { id: clk; precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }
            readonly property var tl: Hyprland.activeToplevel
            readonly property bool wx: root.idleKind === "weather"
            onWxChanged: wx ? Weather.use() : Weather.release()
            Component.onCompleted: if (wx) Weather.use()
            Component.onDestruction: if (wx) Weather.release()
            readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
            Avatar { visible: root.opts.avatar === true && !root.vertical; size: 16; ring: 1; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { visible: root.idleKind === "dot"; width: 6; height: 6; radius: 3; color: root.ac; anchors.verticalCenter: parent.verticalCenter }
            Image {
                visible: root.idleKind === "window" && !!parent.tl
                width: 16; height: 16; sourceSize: Qt.size(32, 32); anchors.verticalCenter: parent.verticalCenter
                source: parent.tl && parent.tl.lastIpcObject ? Icons.app(parent.tl.lastIpcObject.class || "") : ""
            }
            UiIcon { visible: ir.wx; name: Weather.ready ? Weather.icon(Weather.now.code, Weather.now.day) : "wCloudy"; size: 15; color: root.ac; anchors.verticalCenter: parent.verticalCenter }
            UiText {
                visible: root.idleKind !== "dot"
                anchors.verticalCenter: parent.verticalCenter
                text: ir.wx ? (Weather.ready ? Math.round(Weather.now.temp) + "°" : "--")
                    : root.vertical ? Qt.formatDateTime(clk.date, "HH\nmm")
                    : root.idleKind === "window" ? (parent.tl ? parent.tl.title : "").slice(0, 48) : DateTime.formatted(clk.date, root.opts.format || "HH:mm")
                color: root.fg; font.pixelSize: 13; font.weight: Font.DemiBold; font.features: { "tnum": 1 }
            }
            // icones de estado: microfone mudo, sem som, sem rede, notificacoes
            Row {
                visible: root.opts.status === true && !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                UiIcon { visible: Osd.micMuted; name: "micOff"; size: 13; color: Theme.danger }
                UiIcon { visible: Osd.muted; name: "volumeOff"; size: 13; color: Theme.danger }
                UiIcon { visible: !Networking.wifiEnabled && !ir.wired; name: "wifiOff"; size: 13; color: Theme.danger }
                Row {
                    visible: BarState.notifLive > 0 && !Settings.notifDnd
                    spacing: 2
                    UiIcon { name: "bellRing"; size: 13; color: root.ac; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: BarState.notifLive; color: root.ac; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                }
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
                readonly property real cap: root.opts.expand === false || hm.hovered || root.expandNow ? (root.opts.max ?? 260) : Math.min(140, root.opts.max ?? 260)
                width: Math.min(implicitWidth, cap); elide: Text.ElideRight
                text: parent.p ? (parent.p.trackTitle || parent.p.identity) + (parent.p.trackArtist ? "  ·  " + parent.p.trackArtist : "") : ""
                color: root.fg; font.pixelSize: 12; font.weight: Font.Medium
            }
            // visualizador em onda
            Canvas {
                id: waveC
                visible: root.opts.visualizer === "wave" && !root.vertical
                width: 40; height: 16
                anchors.verticalCenter: parent.verticalCenter
                Timer { interval: 70; repeat: true; running: waveC.visible; onTriggered: waveC.requestPaint() }
                onPaint: {
                    const c = getContext("2d"); c.clearRect(0, 0, width, height)
                    c.strokeStyle = Qt.rgba(root.ac.r, root.ac.g, root.ac.b, 1); c.lineWidth = 1.8; c.lineCap = "round"; c.lineJoin = "round"
                    c.beginPath()
                    const n = 14
                    for (let i = 0; i <= n; i++) {
                        const v = Cava.available && Cava.values.length ? Cava.values[Math.min(Cava.values.length - 1, Math.floor(i * Cava.values.length / (n + 1)))] : 0.3 + 0.5 * Math.abs(Math.sin(Date.now() / 300 + i))
                        const x = i * width / n, y = height / 2 + (i % 2 ? -1 : 1) * v * (height / 2 - 2)
                        if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
                    }
                    c.stroke()
                }
                Component.onCompleted: Cava.use()
                Component.onDestruction: Cava.release()
            }
            // barrinhas animadas (cava se houver; senao um pulso)
            Row {
                visible: !root.vertical && (root.opts.visualizer ?? "bars") === "bars"
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
                visible: (root.opts.controls ?? "hover") === "always" ? !root.vertical : ((root.opts.controls ?? "hover") === "hover" && hm.hovered && !root.vertical)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: [["prev", () => root.player.previous()], [root.player && root.player.isPlaying ? "pause" : "play", () => root.player.togglePlaying()], ["next", () => root.player.next()]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 20; height: 20; radius: 10; color: bm.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.16) : "transparent"
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 13; color: root.fg }
                        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]()
                            onContainsMouseChanged: root.btnHover = containsMouse }
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
            // titulo e, embaixo, o comeco do texto da notificacao
            Column {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(Math.max(nt.implicitWidth, nb.implicitWidth), 320)
                spacing: -2
                UiText { id: nt; width: parent.width; elide: Text.ElideRight; text: root.notifText; color: root.fg; font.pixelSize: root.notifBody !== "" ? 11 : 12; font.weight: Font.DemiBold }
                UiText { id: nb; visible: root.notifBody !== ""; width: parent.width; elide: Text.ElideRight; text: root.notifBody; color: root.fg; opacity: 0.65; font.pixelSize: 9 }
            }
        }
    }
    Component {
        id: osdC
        Row {
            spacing: 8
            readonly property string k: root.osdKind
            readonly property bool mic: k === "mic"
            readonly property bool media: k === "media"
            readonly property bool bright: k === "bright"
            readonly property bool night: k === "night"
            readonly property bool vol: !mic && !media && !bright && !night
            UiIcon {
                anchors.verticalCenter: parent.verticalCenter; size: 15; color: root.ac
                name: parent.media ? Osd.mediaIcon : parent.bright ? "sun" : parent.night ? "night" : parent.mic ? (Osd.micMuted ? "micOff" : "mic") : (Osd.muted ? "volumeOff" : Osd.volume < 0.34 ? "volumeLow" : Osd.volume < 0.67 ? "volumeMed" : "volume")
            }
            UiText { visible: parent.media && !root.vertical; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, 240); elide: Text.ElideRight; text: Osd.mediaText; color: root.fg; font.pixelSize: 12 }
            Rectangle {
                visible: (parent.vol || parent.bright || parent.night) && !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                width: 110; height: 5; radius: 2.5; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.18)
                Rectangle { width: parent.width * Math.min(1, parent.parent.bright ? Brightness.value : parent.parent.night ? Settings.nightGamma / 100 : Osd.volume); height: parent.height; radius: 2.5; color: parent.parent.vol && Osd.muted ? Theme.muted : root.ac
                    Behavior on width { NumberAnimation { duration: 120 } } }
            }
            UiText {
                visible: !parent.media && !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                text: parent.mic ? (Osd.micMuted ? "Mudo" : "Ligado") : parent.bright ? Math.round(Brightness.value * 100) + "%" : parent.night ? Settings.nightTemp + " K" : (Osd.muted ? "Mudo" : Math.round(Osd.volume * 100) + "%")
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
