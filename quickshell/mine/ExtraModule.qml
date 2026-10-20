// Modulos de barra (os novos): weather, media, netspeed, gpu, temp, updates, keyboard, recorder, notifs, launcher,
// utils (capturar, cor, microfone, gravar, wallpaper, tema, perfil de energia), caffeine, visualizer, divisor. Nas barras laterais cada um fica compacto (icone em cima
// do valor). Clique e roda fazem a acao natural de cada um (ver comentarios).
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string type
    property var opts: ({})
    property bool vertical: false
    property string side: "bottom"
    property point origin: Qt.point(0, 0)   // canto da janela da barra na tela (dicas)
    property bool hasPop: false              // o modulo ja tem o cartao de detalhes: sem dica de texto
    implicitWidth: ld.item ? ld.item.implicitWidth : 0
    implicitHeight: ld.item ? ld.item.implicitHeight : 0
    readonly property color fg: Settings.textColor
    readonly property color ac: Settings.accent

    // icone + texto (lado a lado na barra horizontal, empilhados na lateral). tip = dica de texto ao passar o mouse;
    // dot = pontinho de aviso no canto do icone; spin = o icone gira (carregando)
    component Chip: Item {
        id: ch
        property string icon
        property string text
        property string tip: ""
        property color tint: root.fg
        property bool hot: false
        property bool dot: false
        property bool spin: false
        property real ring: -1       // progresso em volta do icone (0..1); -1 = sem anel
        property real textMax: 0     // largura maxima do texto em px (0 = sem limite)
        property real textMin: 0
        property bool nav: false     // aceita os botoes voltar / avancar do mouse
        signal clicked(var mouse)
        signal wheel(int dy)
        readonly property bool hovered: ma.containsMouse
        implicitWidth: root.vertical ? Math.max(ic.implicitWidth, tx.width) : ic.implicitWidth + (tx.text !== "" ? tx.width + 6 : 0)
        implicitHeight: root.vertical ? ic.implicitHeight + (tx.text !== "" ? tx.implicitHeight + 2 : 0) : Math.max(ic.implicitHeight, tx.implicitHeight)
        // fundo de passar o mouse: pilula suave atras do botao
        Rectangle {
            anchors { fill: parent; leftMargin: -6; rightMargin: -6; topMargin: -3; bottomMargin: -3 }
            radius: Math.min(width, height) / 2
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, ma.containsMouse ? 0.13 : 0)
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        UiIcon { id: ic; name: ch.icon; size: 16; color: ch.hot ? root.ac : ch.tint; visible: ch.icon !== ""
            x: root.vertical ? (ch.width - width) / 2 : 0; y: root.vertical ? 0 : (ch.height - height) / 2
            NumberAnimation on rotation { running: ch.spin; from: 0; to: 360; duration: 900; loops: Animation.Infinite; onRunningChanged: if (!running) ic.rotation = 0 }
            Shape {   // anel de progresso (musica)
                visible: ch.ring >= 0
                anchors.centerIn: parent
                width: 1; height: 1
                ShapePath { strokeColor: Qt.rgba(ch.tint.r, ch.tint.g, ch.tint.b, 0.22); fillColor: "transparent"; strokeWidth: 1.8
                    PathAngleArc { centerX: 0; centerY: 0; radiusX: 11; radiusY: 11; startAngle: -90; sweepAngle: 360 } }
                ShapePath { strokeColor: ch.hot ? root.ac : ch.tint; fillColor: "transparent"; strokeWidth: 1.8; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 0; centerY: 0; radiusX: 11; radiusY: 11; startAngle: -90; sweepAngle: 359.9 * Math.max(0, Math.min(1, ch.ring)) } }
            }
            Rectangle {   // pontinho de aviso
                visible: ch.dot
                x: parent.width - 6; y: 1
                width: 7; height: 7; radius: 3.5
                color: Theme.danger
                border.width: 1.5; border.color: Settings.barColor
            }
        }
        UiText { id: tx; text: ch.text; color: ch.tint; font.pixelSize: root.vertical ? 10 : 13; font.features: { "tnum": 1 }
            width: ch.textMax > 0 ? Math.max(ch.textMin, Math.min(implicitWidth, ch.textMax)) : implicitWidth; elide: Text.ElideRight
            x: root.vertical ? (ch.width - width) / 2 : (ic.visible ? ic.width + 6 : 0); y: root.vertical ? ic.height + 2 : (ch.height - height) / 2 }
        MouseArea { id: ma; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: ch.nav ? Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton : Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: m => { if (!root.hasPop) BarState.popLeave(); ch.clicked(m) }; onWheel: w => ch.wheel(w.angleDelta.y) }
        TipHover { text: root.hasPop ? "" : ch.tip; side: root.side; origin: root.origin }
    }

    Loader {
        id: ld
        sourceComponent: ({ weather: weatherC, media: mediaC, netspeed: netC, gpu: gpuC, temp: tempC, updates: updC, keyboard: kbC, recorder: recC,
                            notifs: notifC, launcher: launchC, utils: utilsC, caffeine: cafC, battery: batC, bluetooth: btC, sysicons: sysC, visualizer: visC, privacy: privC, divisor: divC, aiusage: aiC, avatar: avC, livewall: lwC })[root.type] ?? null
    }

    // clima: icone e temperatura; clique atualiza
    Component { id: weatherC; Chip {
        Component.onCompleted: Weather.use(); Component.onDestruction: Weather.release()
        icon: Weather.ready ? Weather.icon(Weather.now.code, Weather.now.day) : "wCloudy"
        text: Weather.ready ? Math.round(Weather.now.temp) + "°" : "--"
        onClicked: Weather.refresh()
    } }
    // midia: icone com anel de progresso + titulo. Esquerdo toca/pausa (ou abre a aba Midia), meio anterior, direito proxima,
    // voltar/avancar do mouse trocam de faixa, roda troca de faixa. Opcoes: artist, clean, ring, lyrics, preferredPlayer,
    // alwaysVisible, minW, maxW, leftClick (toggle | panel)
    Component { id: mediaC; Chip {
        id: mc
        readonly property string pref: String(root.opts.preferredPlayer ?? "").trim().toLowerCase()
        readonly property var plist: Mpris.players.values
        readonly property var p: (pref !== "" ? plist.find(x => ((x.identity || "") + " " + (x.dbusName || "")).toLowerCase().indexOf(pref) >= 0) : null) ?? plist.find(x => x.isPlaying) ?? plist[0] ?? null
        readonly property bool lyr: root.opts.lyrics === true
        onLyrChanged: lyr ? Lyrics.use() : Lyrics.release()
        Component.onCompleted: if (lyr) Lyrics.use()
        Component.onDestruction: if (lyr) Lyrics.release()
        function clean(t) {
            return (t || "").replace(/\s*[\(\[][^\)\]]*(official|video|audio|lyrics?|visuali[sz]er|hd|4k|remaster)[^\)\]]*[\)\]]/ig, "").replace(/\s*[-|]\s*YouTube( Music)?$/i, "").replace(/\s{2,}/g, " ").trim()
        }
        readonly property string title: root.opts.clean === false ? (p ? p.trackTitle : "") : clean(p ? p.trackTitle : "")
        readonly property string line: {
            if (!p) return "Sem mídia"
            if (lyr && Lyrics.index >= 0 && !Lyrics.plain && Lyrics.lines[Lyrics.index]) return "♪ " + Lyrics.lines[Lyrics.index].text
            const t = title || p.identity
            return root.opts.artist === true && p.trackArtist ? p.trackArtist + " • " + t : t
        }
        visible: !!p || root.opts.alwaysVisible === true
        nav: true
        icon: p && p.isPlaying ? "music" : "pause"
        hot: !!p && p.isPlaying
        ring: root.opts.ring !== false && p && p.lengthSupported && p.length > 0 ? p.position / p.length : -1
        text: root.vertical ? "" : line
        textMax: root.opts.maxW ?? 280
        textMin: root.opts.minW ?? 0
        Timer { interval: 1000; repeat: true; running: mc.visible && !!mc.p && mc.p.isPlaying && mc.ring >= 0; onTriggered: mc.p.positionChanged() }
        onClicked: m => {
            if (!p) return
            if (m.button === Qt.RightButton || m.button === Qt.ForwardButton) p.next()
            else if (m.button === Qt.MiddleButton || m.button === Qt.BackButton) p.previous()
            else if (root.opts.leftClick === "panel") Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "home", "go", "media"])
            else p.togglePlaying()
        }
        onWheel: dy => { if (p) { if (dy < 0) p.next(); else p.previous() } }
    } }
    // rede: duas linhas (envio em cima, download embaixo) com largura fixa; esmaece quando parado. Clique abre a aba Rede do Inicio
    Component { id: netC; Item {
        id: nsp
        Component.onCompleted: SysInfo.use(); Component.onDestruction: SysInfo.release()
        function s(b) { return SysInfo.bytes(b ?? 0).replace(" ", "") }
        readonly property real fs: root.vertical ? 9 : 11
        TextMetrics { id: nm; font.pixelSize: nsp.fs; font.family: Theme.font; text: "↓ 000MB" }
        implicitWidth: Math.ceil(nm.advanceWidth) + (root.vertical ? 0 : 20)
        implicitHeight: col2.implicitHeight
        UiIcon { visible: !root.vertical; name: "network"; size: 15; color: root.fg; anchors.verticalCenter: parent.verticalCenter }
        Column {
            id: col2
            x: root.vertical ? 0 : 20
            spacing: -2
            UiText { text: "↑ " + nsp.s(SysInfo.d.tx); color: Theme.tertiary; font.pixelSize: nsp.fs; font.features: { "tnum": 1 }; opacity: (SysInfo.d.tx ?? 0) > 1024 ? 1 : 0.5 }
            UiText { text: "↓ " + nsp.s(SysInfo.d.rx); color: root.ac; font.pixelSize: nsp.fs; font.features: { "tnum": 1 }; opacity: (SysInfo.d.rx ?? 0) > 1024 ? 1 : 0.5 }
        }
        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
            onClicked: { BarState.popLeave(); Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "home", "go", "net"]) } }
    } }
    Component { id: gpuC; Chip {
        Component.onCompleted: SysInfo.use(); Component.onDestruction: SysInfo.release()
        icon: "gpuCard"; text: SysInfo.d.gpu ? Math.round(SysInfo.gpu * 100) + "%" + (root.vertical || !SysInfo.gpuTemp ? "" : " " + SysInfo.gpuTemp + "°") : "--"
    } }
    Component { id: tempC; Chip {
        Component.onCompleted: SysInfo.use(); Component.onDestruction: SysInfo.release()
        icon: "temperature"; text: SysInfo.temp !== null ? SysInfo.temp + "°" : "--"
        tint: SysInfo.temp > 80 ? Theme.danger : root.fg
    } }
    // atualizacoes (checkupdates + AUR): clique atualiza num terminal (avisa ao terminar), direito verifica agora; gira enquanto verifica.
    // Fica vermelho a partir de "updStrong" e destacado a partir de "updWarn" (Sessao > Sistema)
    Component { id: updC; Chip {
        readonly property int count: SystemGuard.updates   // checkupdates fica no SystemGuard (uma vez so para todo o shell)
        readonly property bool strong: Settings.updStrong > 0 && count >= Settings.updStrong
        visible: SystemGuard.checking || count > 0
        icon: SystemGuard.checking ? "refresh" : "package"
        spin: SystemGuard.checking
        text: count < 0 ? "…" : String(count)
        tint: strong ? Theme.danger : root.fg
        hot: !strong && (Settings.updWarn > 0 ? count >= Settings.updWarn : count > 50)
        onClicked: m => {
            if (m.button === Qt.RightButton) { SystemGuard.checkUpdates(); Quickshell.execDetached(["notify-send", "-a", "Atualizações", "-i", "system-software-update", "Atualizações", "Procurando atualizações…"]) }
            else SystemGuard.runUpdate()
        }
    } }
    // layout do teclado: clique troca para o proximo
    Component { id: kbC; Chip {
        id: kb
        property string layout: ""
        icon: "keyboard"
        tip: "Layout do teclado: " + layout + " (clique troca)"
        text: { const m = { "Portuguese (Brazil)": "BR", "English (US)": "US", "English (intl., with AltGr dead keys)": "US-intl" }; return m[layout] ?? layout.slice(0, 3).toUpperCase() }
        Process { id: dv; command: ["hyprctl", "devices", "-j"]; stdout: StdioCollector { onStreamFinished: { try { const k = JSON.parse(text).keyboards; kb.layout = (k.find(x => x.main) ?? k[0]).active_keymap } catch (e) {} } } }
        Component.onCompleted: dv.running = true
        Connections { target: Hyprland; function onRawEvent(ev) { if (ev.name === "activelayout") { dv.running = false; dv.running = true } } }
        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    } }
    // gravando: so aparece durante a gravacao; clique para
    Component { id: recC; Chip {
        visible: Recorder.active
        icon: "monitor"; text: root.vertical ? "" : Recorder.elapsed
        tip: "Gravando a tela. Clique para parar."
        tint: Theme.danger
        SequentialAnimation on opacity { running: Recorder.active; loops: Animation.Infinite; NumberAnimation { to: 0.45; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
        onClicked: Recorder.stop()
    } }
    // notificacoes: sino (com nao perturbe); clique liga/desliga o nao perturbe, direito limpa.
    // Opcao "badge": count (numero ao lado, padrao) | dot (so um pontinho no sino)
    Component { id: notifC; Chip {
        readonly property bool useDot: root.opts.badge === "dot"
        readonly property int n: !Settings.notifDnd && BarState.notifLive > 0 ? BarState.notifLive : NotifHistory.unread   // ao vivo, senao as nao lidas
        icon: Settings.notifDnd ? "bellOff" : (BarState.notifLive > 0 ? "bellRing" : "bell")
        hot: BarState.notifLive > 0 || n > 0
        dot: useDot && n > 0
        text: !useDot && n > 0 ? String(n) : ""
        tip: Settings.notifDnd ? "Não perturbe ligado. Clique desliga, direito limpa." : (BarState.notifLive > 0 ? BarState.notifLive + " notificação(ões). Clique liga o não perturbe, direito limpa." : "Sem notificações. Clique liga o não perturbe.")
        onClicked: m => m.button === Qt.RightButton ? Actions.run("notifClear") : Settings.notifDnd = !Settings.notifDnd
    } }
    // bateria: some sozinha em PC de mesa. Estilos bar/ios/macos/windows/ring/icon/number (BatteryGlyph.qml)
    Component { id: batC; Item {
        visible: Battery.present
        implicitWidth: Battery.present ? bg.implicitWidth : 0
        implicitHeight: Battery.present ? bg.implicitHeight : 0
        BatteryGlyph {
            id: bg
            style: root.opts.style ?? "bar"
            pct: Battery.pct; charging: Battery.charging; low: Battery.low; critical: Battery.critical
            showPct: root.opts.showPercentage !== false; showBolt: root.opts.showCharging !== false
            col: root.fg
            s: root.vertical ? 14 : 16
        }
        TipHover { text: root.hasPop || !Battery.present ? "" : Battery.stateText + " · " + Math.round(Battery.pct * 100) + "%"; side: root.side; origin: root.origin }
    } }
    // bluetooth: icone pelo estado; mostra o nome/carga do aparelho conectado; clique abre a aba Bluetooth do Inicio, direito liga/desliga
    Component { id: btC; Chip {
        readonly property var ad: Bluetooth.defaultAdapter
        readonly property var conn: ad ? ad.devices.values.filter(d => d.connected) : []
        visible: !!ad
        icon: !ad || !ad.enabled ? "btOff" : conn.length > 0 ? "btConnect" : "bluetooth"
        hot: conn.length > 0
        text: conn.length > 0 && !root.vertical ? (conn[0].batteryAvailable ? Math.round(conn[0].battery * 100) + "%" : "") : ""
        tip: !ad ? "" : !ad.enabled ? "Bluetooth desligado" : conn.length > 0 ? conn.map(d => d.name).join(", ") : "Bluetooth ligado, sem aparelhos conectados"
        onClicked: m => { if (m.button === Qt.RightButton) { if (ad) ad.enabled = !ad.enabled } else Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "home", "go", "bt"]) }
    } }
    // icones do sistema juntos: som (roda muda o volume), microfone mudo, rede, bluetooth, aparelhos com pouca carga, bateria
    Component { id: sysC; Grid {
        id: sg
        columns: root.vertical ? 1 : 99
        spacing: root.vertical ? 8 : 10
        readonly property var netDevs: Networking.devices.values
        readonly property bool wifiOn: Networking.wifiEnabled
        readonly property var wifiDev: netDevs.find(d => d.type === DeviceType.Wifi) ?? null
        readonly property var wired: netDevs.find(d => d.type === DeviceType.Wired && d.connected) ?? null
        readonly property bool wifiUp: !!wifiDev && wifiOn && wifiDev.networks.values.some(n => n.connected)
        readonly property var bt: Bluetooth.defaultAdapter
        readonly property int btN: bt ? bt.devices.values.filter(d => d.connected).length : 0
        UiIcon {
            size: 16; color: Osd.muted ? Theme.danger : root.fg
            name: Osd.muted ? "volumeOff" : Osd.volume > 0.66 ? "volume" : Osd.volume > 0.25 ? "volumeMed" : "volumeLow"
            MouseArea { anchors.fill: parent; anchors.margins: -3; cursorShape: Qt.PointingHandCursor
                onClicked: Settings.homeOpen = !Settings.homeOpen
                onWheel: w => { const a = Osd.sink ? Osd.sink.audio : null; if (a) a.volume = Math.max(0, Math.min(Settings.volMax / 100, a.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))) } }
        }
        UiIcon { visible: Osd.micMuted; name: "micOff"; size: 16; color: Theme.danger }
        UiIcon {
            visible: !!sg.wifiDev || !!sg.wired
            size: 16; color: sg.wired || sg.wifiUp ? root.fg : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.5)
            name: sg.wired ? "ethernet" : !sg.wifiOn ? "wifiOff" : sg.wifiUp ? "wifi" : "wifi1"
            MouseArea { anchors.fill: parent; anchors.margins: -3; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "home", "go", "net"]) }
        }
        UiIcon {
            visible: !!sg.bt
            size: 16; color: sg.btN > 0 ? root.ac : (sg.bt && sg.bt.enabled ? root.fg : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.5))
            name: !sg.bt || !sg.bt.enabled ? "btOff" : sg.btN > 0 ? "btConnect" : "bluetooth"
            MouseArea { anchors.fill: parent; anchors.margins: -3; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "home", "go", "bt"]) }
        }
        Repeater {
            model: Battery.lowDevices
            UiIcon {
                required property var modelData
                size: 16; color: Theme.danger
                name: (modelData.iconName ?? "").indexOf("mouse") >= 0 ? "mouse" : (modelData.iconName ?? "").indexOf("keyboard") >= 0 ? "keyboard"
                    : (modelData.iconName ?? "").indexOf("head") >= 0 ? "headphones" : (modelData.iconName ?? "").indexOf("gaming") >= 0 ? "gamepad" : "battery"
            }
        }
        BatteryGlyph {
            visible: Battery.present
            style: "icon"; s: 14; pct: Battery.pct; charging: Battery.charging; low: Battery.low; critical: Battery.critical; col: root.fg
        }
    } }
    Component { id: launchC; Chip { icon: root.opts.icon ?? "apps"; hot: Settings.launcherOpen; tip: "Abrir o launcher"; onClicked: Settings.launcherOpen = !Settings.launcherOpen } }
    Component { id: cafC; Chip { icon: "coffee"; hot: Idle.paused; tip: Idle.paused ? "Manter acordado: ligado (clique desliga)" : "Manter acordado: desligado (clique liga)"; onClicked: Idle.paused = !Idle.paused } }
    // utilidades: cada botao liga/desliga nas opcoes do modulo (padrao: capturar, cor e microfone):
    // capturar uma area, pegar uma cor, gravar a tela, escolher o wallpaper, tema claro/escuro, perfil de energia, microfone (mudo)
    Component { id: utilsC; Grid {
        id: ug
        columns: root.vertical ? 1 : 9
        spacing: root.vertical ? 8 : 12
        readonly property var mic: Pipewire.defaultAudioSource
        readonly property bool micMuted: !!(mic && mic.audio && mic.audio.muted)
        function opt(k, d) { return root.opts[k] ?? d }
        // perfil de energia (power-profiles-daemon): economia -> equilibrado -> desempenho
        readonly property int prof: PowerProfiles.profile
        readonly property string profName: prof === PowerProfile.PowerSaver ? "Economia" : (prof === PowerProfile.Performance ? "Desempenho" : "Equilibrado")
        readonly property string profIcon: prof === PowerProfile.PowerSaver ? "leaf" : (prof === PowerProfile.Performance ? "fire" : "balance")
        function nextProfile() {
            if (PowerProfiles.hasPerformanceProfile)
                PowerProfiles.profile = prof === PowerProfile.PowerSaver ? PowerProfile.Balanced : (prof === PowerProfile.Balanced ? PowerProfile.Performance : PowerProfile.PowerSaver)
            else PowerProfiles.profile = prof === PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
        }
        PwObjectTracker { objects: [ug.mic] }
        Chip { visible: ug.opt("screenSnip", true); icon: "frame"; tip: "Capturar uma área da tela"; onClicked: Actions.run("shot") }
        Chip { visible: ug.opt("colorPicker", true); icon: "palette"; tip: "Pegar uma cor da tela"; onClicked: Actions.run("picker") }
        Chip { visible: ug.opt("record", false); icon: Recorder.active ? "stopCircle" : "recordRec"; tint: Recorder.active ? Theme.danger : root.fg
            text: Recorder.active && !root.vertical ? Recorder.elapsed : ""
            tip: Recorder.active ? "Parar a gravação (" + Recorder.elapsed + ")" : "Gravar a tela"
            onClicked: Recorder.toggle(false) }
        Chip { visible: ug.opt("wallpaper", false); icon: "wallpaper"; hot: Settings.wpPickerOpen; tip: "Escolher o wallpaper"; onClicked: Settings.wpPickerOpen = !Settings.wpPickerOpen }
        Chip { visible: ug.opt("darkMode", false); icon: Settings.themeModeEff === "dark" ? "sun" : "moon"
            tip: Settings.themeModeEff === "dark" ? "Mudar para o tema claro" : "Mudar para o tema escuro"
            onClicked: Settings.themeMode = Settings.themeModeEff === "dark" ? "light" : "dark" }
        Chip { visible: ug.opt("perfProfile", false); icon: ug.profIcon
            tip: "Perfil de energia: " + ug.profName + " (clique muda)"
            onClicked: ug.nextProfile() }
        Chip { visible: ug.opt("mic", true); icon: ug.micMuted ? "micOff" : "mic"; hot: !!(ug.mic && ug.mic.audio && !ug.micMuted)
            tip: ug.micMuted ? "Microfone mudo (clique liga)" : "Microfone ligado (clique silencia)"
            onClicked: if (ug.mic && ug.mic.audio) ug.mic.audio.muted = !ug.mic.audio.muted }
    } }
    // privacidade: aparece quando um app usa o microfone ou compartilha a tela (nos do PipeWire); o visualizador (cava)
    // e o proprio shell nao contam. Passar o mouse diz quem esta usando (detalhes da barra).
    Component { id: privC; Row {
        id: pv
        spacing: 6
        readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream || n.type === PwNodeType.VideoSource)
        PwObjectTracker { objects: pv.streams }
        function appOf(n) { const p = n.properties || {}; return p["application.name"] || p["node.name"] || n.name || "" }
        readonly property var mic: streams.filter(n => n.type === PwNodeType.AudioInStream && !/cava|quickshell|pavucontrol|peak|monitor/i.test(appOf(n)))
        readonly property var screen: streams.filter(n => n.type === PwNodeType.VideoSource && /xdpw|portal|screen|cast/i.test(appOf(n) + " " + (n.description || "")))
        visible: mic.length > 0 || screen.length > 0
        Chip { visible: pv.mic.length > 0; icon: "mic"; tint: Theme.danger; text: ""}
        Chip { visible: pv.screen.length > 0; icon: "monitor"; tint: Theme.danger; text: ""}
    } }
    // mini visualizador (cava): esmaece quando nada esta tocando (opcao dimIdle, padrao ligada)
    Component { id: visC; Item {
        Component.onCompleted: Cava.use(); Component.onDestruction: Cava.release()
        readonly property int n: root.opts.bars ?? 10
        readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)
        implicitWidth: root.vertical ? 18 : n * 4
        implicitHeight: root.vertical ? n * 4 : 18
        visible: Cava.available
        opacity: root.opts.dimIdle === false || playing ? 1 : 0.3
        Behavior on opacity { NumberAnimation { duration: 400 } }
        Repeater {
            model: parent.n
            delegate: Rectangle {
                required property int index
                readonly property real v: Cava.values.length ? Cava.values[Math.floor(index * Cava.values.length / parent.n)] : 0
                readonly property real len: 2 + v * 16
                x: root.vertical ? (18 - len) / 2 : index * 4
                y: root.vertical ? index * 4 : (18 - len) / 2
                width: root.vertical ? len : 2.5; height: root.vertical ? 2.5 : len; radius: 1.25
                color: root.ac
            }
        }
    } }
    // uso da IA (Claude Code, lido dos arquivos locais): % da janela de 5 h; vermelho acima de 90 %. Clique le de novo
    Component { id: aiC; Chip {
        Component.onCompleted: ClaudeUsage.use(); Component.onDestruction: ClaudeUsage.release()
        visible: ClaudeUsage.available || root.opts.alwaysVisible === true
        icon: ClaudeUsage.busyN > 0 ? "creation" : "robot"
        hot: ClaudeUsage.busyN > 0
        text: !ClaudeUsage.ready ? "…" : !ClaudeUsage.available ? "--" : Math.round(ClaudeUsage.frac * 100) + "%"
        tint: ClaudeUsage.frac >= 0.9 ? Theme.danger : root.fg
        onClicked: ClaudeUsage.refresh()
    } }
    // foto de perfil redonda; clique abre o Inicio. Passar o mouse mostra o cartao do perfil
    Component { id: avC; Item {
        implicitWidth: root.vertical ? 24 : 26; implicitHeight: implicitWidth
        Avatar { anchors.centerIn: parent; size: 20; ring: 1.5
            scale: avm.containsMouse ? 1.1 : 0.96; Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } } }
        MouseArea { id: avm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { BarState.popLeave(); Settings.homeOpen = !Settings.homeOpen } }
    } }
    // pausar / continuar o wallpaper animado: so aparece quando o wallpaper atual e um video
    Component { id: lwC; Chip {
        visible: Wallpaper.isVideo(Wallpaper.current)
        icon: Wallpaper.videoPaused ? "play" : "pause"
        hot: !Wallpaper.videoPaused
        tip: Wallpaper.videoPaused ? "Continuar o wallpaper animado" : "Pausar o wallpaper animado"
        onClicked: Wallpaper.videoPaused = !Wallpaper.videoPaused
    } }
    // divisor: uma linha fina, um ponto ou so um espaco entre modulos (style: rect | dot | space; spacing = folga em px)
    Component { id: divC; Item {
        readonly property string st: root.opts.style ?? "rect"
        readonly property real sp: root.opts.spacing ?? 8
        readonly property real along: st === "space" ? sp : (st === "dot" ? dotT.implicitWidth + sp : 1 + sp)
        implicitWidth: root.vertical ? 18 : along
        implicitHeight: root.vertical ? along : 18
        Rectangle {
            visible: parent.st === "rect"
            anchors.centerIn: parent
            width: root.vertical ? 14 : 1; height: root.vertical ? 1 : 14
            radius: 0.5
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.4)
        }
        UiText {
            id: dotT
            visible: parent.st === "dot"
            anchors.centerIn: parent
            text: "•"; color: root.fg; font.pixelSize: 13; opacity: 0.7
        }
    } }
}
