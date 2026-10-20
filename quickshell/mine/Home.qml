// Painel "Inicio": abas na lateral (Inicio, Midia, Audio, Sistema, Conexao, Bluetooth).
// Acoplado a moldura (sai da borda como o launcher) ou flutuante, conforme Settings.home*.
// IPC:  qs -c mine ipc call home toggle | open | close | go <aba>
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick

Scope {
    id: root
    property var geo: ({ home: null })        // resultado de Geometry.compute (vem do shell.qml)
    readonly property bool open: Settings.homeOpen
    property bool alive: false
    property string tab: "home"
    property int scrollReq: 0
    property bool editMode: false   // editando os botoes rapidos
    property string dialog: ""      // janelinha aberta sobre a aba ("night")

    readonly property var tabs: [
        { id: "home", label: "Início", icon: "home" },
        { id: "media", label: "Mídia", icon: "music" },
        { id: "notifs", label: "Notificações", icon: "bell" },
        { id: "agenda", label: "Agenda", icon: "calendar" },
        { id: "audio", label: "Áudio", icon: "volume" },
        { id: "system", label: "Sistema", icon: "chip" },
        { id: "net", label: "Conexão", icon: "wifi" },
        { id: "vpn", label: "VPN", icon: "shield" },
        { id: "bt", label: "Bluetooth", icon: "bluetooth" }
    ]

    IpcHandler {
        target: "home"
        function toggle(): void { Settings.homeOpen = !Settings.homeOpen }
        function open(): void { Settings.homeOpen = true }
        function close(): void { Settings.homeOpen = false }
        function go(t: string): void { root.tab = t; Settings.homeOpen = true }
        function edit(): void { root.tab = "home"; root.editMode = !root.editMode; Settings.homeOpen = true }   // edicao dos botoes rapidos
        function popup(name: string): void { root.dialog = name === "off" ? "" : name; Settings.homeOpen = true }
        function scroll(y: int): void { root.scrollReq = y }   // diagnostico: rola a aba atual
    }
    onOpenChanged: {
        if (open) { closeTimer.stop(); Settings.launcherOpen = false; Settings.wpPickerOpen = false; alive = true }
        else closeTimer.restart()
    }
    Timer { id: closeTimer; interval: Motion.durationOf("home", true) + 120; onTriggered: { root.alive = false; root.tab = "home"; root.dialog = ""; root.editMode = false } }

    function fmt(sec) { sec = Math.max(0, Math.floor(sec || 0)); return Math.floor(sec / 60) + ":" + ("0" + (sec % 60)).slice(-2) }
    function bytes(b) {
        b = b || 0
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GiB"
        if (b >= 1048576) return (b / 1048576).toFixed(0) + " MiB"
        return (b / 1024).toFixed(0) + " KiB"
    }
    function rate(b) {
        b = b || 0
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
        if (b >= 1024) return (b / 1024).toFixed(0) + " KB/s"
        return Math.round(b) + " B/s"
    }
    function dur(sec) {
        sec = Math.floor(sec || 0)
        const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60)
        return (d > 0 ? d + " d " : "") + (h > 0 ? h + " h " : "") + m + " min"
    }

    // ---- sistema (scripts/sysinfo.py: uma linha JSON por segundo, so com o painel aberto) ----
    readonly property string sysScript: Qt.resolvedUrl("scripts/sysinfo.py").toString().replace("file://", "")
    property var sys: ({})
    property var st: ({})
    property var disks: []
    property var cpuH: []
    property var memH: []
    property var gpuH: []
    property var rxH: []
    property var txH: []
    function push(a, v) { const r = a.slice(-39); r.push(v || 0); return r }
    Process {
        running: root.alive
        command: ["python3", root.sysScript]
        stdout: SplitParser {
            onRead: line => {
                let d
                try { d = JSON.parse(line) } catch (e) { return }
                root.sys = d
                if (d.static) root.st = d.static
                if (d.disks) root.disks = d.disks
                root.cpuH = root.push(root.cpuH, d.cpu)
                root.memH = root.push(root.memH, d.memTotal ? d.memUsed / d.memTotal * 100 : 0)
                root.gpuH = root.push(root.gpuH, d.gpu ? d.gpu.usage : 0)
                root.rxH = root.push(root.rxH, d.rx)
                root.txH = root.push(root.txH, d.tx)
            }
        }
    }

    // ---- perfil de energia e enderecos IP ----
    property string profile: "balanced"
    property var ips: ({})
    Process { id: pProf; command: ["powerprofilesctl", "get"]; stdout: StdioCollector { onStreamFinished: root.profile = text.trim() || "balanced" } }
    Process {
        id: pIp
        command: ["sh", "-c", "ip -4 -o addr show scope global | awk '{print $2\" \"$4}'"]
        stdout: StdioCollector { onStreamFinished: { const m = {}; text.trim().split("\n").forEach(l => { const p = l.split(" "); if (p.length > 1) m[p[0]] = p[1].split("/")[0] }); root.ips = m } }
    }
    function refresh() { pProf.running = false; pProf.running = true; pIp.running = false; pIp.running = true }
    Timer { interval: 5000; repeat: true; running: root.alive; onTriggered: root.refresh() }
    onAliveChanged: if (alive) refresh()

    Process { id: pAct }
    function run(cmd) { pAct.command = cmd; pAct.running = false; pAct.running = true }
    readonly property var profileNames: ({ "balanced": "Equilibrado", "performance": "Desempenho", "power-saver": "Economia" })
    function cycleProfile() {
        const next = { "balanced": "performance", "performance": "power-saver", "power-saver": "balanced" }[root.profile] ?? "balanced"
        root.profile = next
        run(["powerprofilesctl", "set", next])
    }

    // ---- midia ----
    readonly property var players: Mpris.players.values
    property int playerPick: -1   // -1 = automatico (o que esta tocando)
    readonly property var player: playerPick >= 0 && playerPick < players.length ? players[playerPick]
        : (players.find(p => p.isPlaying) ?? (players.length > 0 ? players[0] : null))

    // ---- audio ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    // apps tocando som: no Quickshell os streams de saida (Stream/Output/Audio) tem isSink = true
    readonly property var streams: nodes.filter(n => n.audio && n.isStream && n.type === PwNodeType.AudioOutStream)
    // apps gravando / ouvindo o microfone (Stream/Input/Audio)
    readonly property var inStreams: nodes.filter(n => n.audio && n.isStream && n.type === PwNodeType.AudioInStream)
    PwObjectTracker { objects: root.alive ? root.nodes.filter(n => n.audio) : [] }
    function nodeName(n) { return n ? (n.description || n.nickname || n.name || "?") : "" }
    // nome de um app do mixer: nome do app (ou descricao / nome do no) e, se houver, " • titulo da midia"
    function appLabel(n) {
        const p = n.properties || {}
        const base = p["application.name"] || n.description || n.name || "App"
        return base + (p["media.name"] ? " • " + p["media.name"] : "")
    }
    function appIcon(n) {
        const p = n.properties || {}
        return Icons.path(p["application.icon-name"] || "", "") || Icons.app(p["application.process.binary"] || p["application.name"] || p["node.name"] || "")
    }
    function volIcon(a) { return !a || a.muted ? "volumeOff" : (a.volume > 0.66 ? "volume" : (a.volume > 0.25 ? "volumeMed" : "volumeLow")) }

    // ---- rede ----
    readonly property var netDevs: Networking.devices.values
    readonly property var wifiDev: netDevs.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDev: netDevs.find(d => d.type === DeviceType.Wired && d.connected) ?? netDevs.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifiNets: wifiDev ? wifiDev.networks.values : []
    readonly property var wifiCur: wifiNets.find(n => n.connected) ?? null

    // ---- bluetooth ----
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btDevs: bt ? bt.devices.values : []
    readonly property var btConnected: btDevs.filter(d => d.connected)

    // criada uma vez e so mostrada/escondida (criar o painel inteiro na hora travava 1-2 quadros da animacao)
    LazyLoader {
        active: true

        PanelWindow {
            id: win
            // fica sempre mapeada (esconder com visible recriava a janela inteira a cada abertura); fechada: sem mouse, sem teclado, nada desenhado
            mask: root.alive ? null : noInput
            Region { id: noInput }
            Component.onCompleted: contentItem.visible = Qt.binding(() => root.alive)
            Connections { target: root; function onAliveChanged() { if (root.alive) panel.forceActiveFocus() } }
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.alive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-home"

            // ---- geometria (mesmo esquema do launcher) ----
            readonly property bool docked: Settings.homeDocked
            readonly property string side: Settings.homeSide
            readonly property real e: Settings.edge
            readonly property real cw: BarState.homeW
            readonly property real ch: BarState.homeH
            property real fprog: root.open ? 1 : 0
            Behavior on fprog { id: fpB; MotionAnim { use: "home"; out: fpB.targetValue < 0.5 } }
            readonly property real pp: docked ? BarState.homeProg : fprog
            readonly property var pk: root.geo.home
            readonly property rect dbox: !pk ? Qt.rect(0, 0, 0, 0) : (
                side === "top" ? Qt.rect(pk.rect.x + (pk.rect.w - cw) / 2, pk.rect.y + e + 8, cw, ch)
                : side === "bottom" ? Qt.rect(pk.rect.x + (pk.rect.w - cw) / 2, pk.rect.y + 12, cw, ch)
                : side === "left" ? Qt.rect(pk.rect.x + e + 8, pk.rect.y + (pk.rect.h - ch) / 2, cw, ch)
                : Qt.rect(pk.rect.x + 12, pk.rect.y + (pk.rect.h - ch) / 2, cw, ch))
            readonly property rect fbox: Qt.rect((width - cw) / 2, (height - ch) / 2 + (1 - pp) * 18, cw, ch)
            readonly property rect box: docked ? dbox : fbox
            readonly property real fullDepth: docked && pk ? pk.t : 0
            readonly property real vis: docked ? Math.max(0, e + (fullDepth - e) * pp) : 0
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
                    opacity: win.docked ? Math.max(0, Math.min(1, win.pp * 4)) : Math.max(0, Math.min(1, win.pp * 1.6))

                    Rectangle {
                        id: panel
                        x: win.box.x; y: win.box.y
                        width: win.box.width; height: win.box.height
                        radius: win.docked ? 0 : Settings.homeRadius + 6
                        color: win.docked ? "transparent" : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.glass ? Math.min(1, Settings.glassOpacityEff / 100 + 0.08) : 1)
                        border.width: win.docked ? 0 : 1; border.color: Theme.border
                        scale: win.docked ? 1 : 0.94 + 0.06 * win.pp
                        transformOrigin: Item.Top
                        focus: true
                        Keys.onEscapePressed: { if (root.dialog !== "") root.dialog = ""; else Settings.homeOpen = false }
                        Keys.onTabPressed: { const i = root.tabs.findIndex(t => t.id === root.tab); root.tab = root.tabs[(i + 1) % root.tabs.length].id }
                        MouseArea { anchors.fill: parent }

                        // ---------- abas (lateral) ----------
                        Rectangle {
                            id: rail
                            x: 12; y: 12; width: 56; height: parent.height - 24
                            radius: 16
                            color: Theme.gl(Theme.card, 1.15)
                            border.width: 1; border.color: Theme.border
                            Column {
                                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 7 }
                                spacing: 6
                                Repeater {
                                    model: root.tabs
                                    delegate: Rectangle {
                                        id: rt
                                        required property var modelData
                                        readonly property bool on: root.tab === modelData.id
                                        width: 42; height: 42; radius: 12
                                        color: on ? Theme.accent : (rtm.containsMouse ? Theme.cardHi : "transparent")
                                        Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 140 } }
                                        UiIcon { anchors.centerIn: parent; name: rt.modelData.icon; size: 20; color: rt.on ? Theme.accentText : (rtm.containsMouse ? Theme.text : Theme.muted) }
                                        MouseArea { id: rtm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.tab = rt.modelData.id }
                                    }
                                }
                            }
                            Rectangle {   // energia (abre o menu)
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: gearBtn.top; bottomMargin: 6 }
                                width: 42; height: 42; radius: 12
                                color: pwm.containsMouse ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : "transparent"
                                UiIcon { anchors.centerIn: parent; name: "power"; size: 20; color: pwm.containsMouse ? Theme.danger : Theme.muted }
                                MouseArea { id: pwm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Power.menuOpen = true }
                            }
                            Rectangle {
                                id: gearBtn
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 7 }
                                width: 42; height: 42; radius: 12
                                color: gm.containsMouse ? Theme.cardHi : "transparent"
                                UiIcon { anchors.centerIn: parent; name: "cog"; size: 20; color: gm.containsMouse ? Theme.text : Theme.muted }
                                MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.settingsOpen = true }
                            }
                        }

                        // ---------- cabecalho ----------
                        Item {
                            id: header
                            anchors { left: rail.right; leftMargin: 14; right: parent.right; rightMargin: 12; top: parent.top; topMargin: 12 }
                            height: 36
                            UiText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.tabs.find(t => t.id === root.tab) ?? root.tabs[0]).label
                                color: Theme.text; font.pixelSize: 18; font.weight: Font.Bold
                            }
                            UiButton { anchors { right: parent.right; verticalCenter: parent.verticalCenter } icon: "close"; kind: "ghost"; onClicked: Settings.homeOpen = false }
                        }

                        // ---------- conteudo da aba ----------
                        Loader {
                            id: pageL
                            anchors { left: rail.right; leftMargin: 12; right: parent.right; rightMargin: 12; top: header.bottom; topMargin: 10; bottom: parent.bottom; bottomMargin: 12 }
                            sourceComponent: ({ home: pHome, media: pMedia, notifs: pNotifs, agenda: pAgenda, audio: pAudio, system: pSystem, net: pNet, vpn: pVpn, bt: pBt })[root.tab] ?? pHome
                            opacity: 0
                            onLoaded: fadeIn.restart()
                            Connections { target: root; function onScrollReqChanged() { if (pageL.item && pageL.item.contentY !== undefined) pageL.item.contentY = root.scrollReq } }
                            NumberAnimation { id: fadeIn; target: pageL; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                        }
                        // janelinha sobre a aba (clique fora fecha)
                        Rectangle {
                            visible: root.dialog !== ""
                            anchors { left: rail.right; leftMargin: 12; right: parent.right; rightMargin: 12; top: header.bottom; topMargin: 10; bottom: parent.bottom; bottomMargin: 12 }
                            radius: 14
                            color: Qt.rgba(0, 0, 0, 0.5)
                            MouseArea { anchors.fill: parent; onClicked: root.dialog = "" }
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 24, 440); height: Math.min(parent.height - 16, dlgItem.implicitHeight)
                                radius: 16; clip: true
                                color: Theme.bg
                                border.width: 1; border.color: Theme.border
                                MouseArea { anchors.fill: parent }
                                NightDialog { id: dlgItem; visible: root.dialog === "night"; anchors.fill: parent; onCloseRequested: root.dialog = "" }
                            }
                        }
                        Component { id: pHome; HomeMain { home: root } }
                        Component { id: pMedia; HomeMedia { home: root } }
                        Component { id: pAudio; HomeAudio { home: root } }
                        Component { id: pSystem; HomeSystem { home: root } }
                        Component { id: pNet; HomeNet { home: root } }
                        Component { id: pVpn; HomeVpn { home: root } }
                        Component { id: pBt; HomeBt { home: root } }
                        Component { id: pNotifs; HomeNotifs { home: root } }
                        Component { id: pAgenda; HomeAgenda { home: root } }
                    }
                }
            }
        }
    }
}
