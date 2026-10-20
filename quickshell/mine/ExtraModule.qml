// Modulos de barra (os novos): weather, media, netspeed, gpu, temp, updates, keyboard, recorder, notifs, launcher,
// utils (capturar, cor, microfone, gravar, wallpaper, tema, perfil de energia), caffeine, visualizer, divisor. Nas barras laterais cada um fica compacto (icone em cima
// do valor). Clique e roda fazem a acao natural de cada um (ver comentarios).
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick

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
        signal clicked(var mouse)
        signal wheel(int dy)
        readonly property bool hovered: ma.containsMouse
        implicitWidth: root.vertical ? Math.max(ic.implicitWidth, tx.implicitWidth) : ic.implicitWidth + (tx.text !== "" ? tx.implicitWidth + 6 : 0)
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
            Rectangle {   // pontinho de aviso
                visible: ch.dot
                x: parent.width - 6; y: 1
                width: 7; height: 7; radius: 3.5
                color: Theme.danger
                border.width: 1.5; border.color: Settings.barColor
            }
        }
        UiText { id: tx; text: ch.text; color: ch.tint; font.pixelSize: root.vertical ? 10 : 13; font.features: { "tnum": 1 }
            x: root.vertical ? (ch.width - width) / 2 : (ic.visible ? ic.width + 6 : 0); y: root.vertical ? ic.height + 2 : (ch.height - height) / 2 }
        MouseArea { id: ma; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: m => { if (!root.hasPop) BarState.popLeave(); ch.clicked(m) }; onWheel: w => ch.wheel(w.angleDelta.y) }
        TipHover { text: root.hasPop ? "" : ch.tip; side: root.side; origin: root.origin }
    }

    Loader {
        id: ld
        sourceComponent: ({ weather: weatherC, media: mediaC, netspeed: netC, gpu: gpuC, temp: tempC, updates: updC, keyboard: kbC, recorder: recC,
                            notifs: notifC, launcher: launchC, utils: utilsC, caffeine: cafC, visualizer: visC, privacy: privC, divisor: divC })[root.type] ?? null
    }

    // clima: icone e temperatura; clique atualiza
    Component { id: weatherC; Chip {
        Component.onCompleted: Weather.use(); Component.onDestruction: Weather.release()
        icon: Weather.ready ? Weather.icon(Weather.now.code, Weather.now.day) : "wCloudy"
        text: Weather.ready ? Math.round(Weather.now.temp) + "°" : "--"
        onClicked: Weather.refresh()
    } }
    // midia: icone + titulo; clique toca/pausa, direito proxima, roda troca de faixa
    Component { id: mediaC; Chip {
        readonly property var p: Mpris.players.values.find(x => x.isPlaying) ?? Mpris.players.values[0] ?? null
        visible: !!p
        icon: p && p.isPlaying ? "music" : "pause"
        hot: !!p && p.isPlaying
        text: !p || root.vertical ? "" : (p.trackTitle || p.identity).slice(0, root.opts.max ?? 28) + ((p.trackTitle || "").length > (root.opts.max ?? 28) ? "…" : "")
        onClicked: m => { if (!p) return; if (m.button === Qt.RightButton) p.next(); else if (m.button === Qt.MiddleButton) p.previous(); else p.togglePlaying() }
        onWheel: dy => { if (p) { if (dy < 0) p.next(); else p.previous() } }
    } }
    // rede: download (e upload) por segundo
    Component { id: netC; Chip {
        Component.onCompleted: SysInfo.use(); Component.onDestruction: SysInfo.release()
        function s(b) { return SysInfo.bytes(b ?? 0).replace(" ", "") }
        icon: "network"
        text: root.vertical ? s(SysInfo.d.rx) : "↓" + s(SysInfo.d.rx) + "  ↑" + s(SysInfo.d.tx)
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
        readonly property int n: Settings.notifDnd ? 0 : BarState.notifLive
        icon: Settings.notifDnd ? "bellOff" : (BarState.notifLive > 0 ? "bellRing" : "bell")
        hot: BarState.notifLive > 0
        dot: useDot && n > 0
        text: !useDot && n > 0 ? String(n) : ""
        tip: Settings.notifDnd ? "Não perturbe ligado. Clique desliga, direito limpa." : (BarState.notifLive > 0 ? BarState.notifLive + " notificação(ões). Clique liga o não perturbe, direito limpa." : "Sem notificações. Clique liga o não perturbe.")
        onClicked: m => m.button === Qt.RightButton ? Actions.run("notifClear") : Settings.notifDnd = !Settings.notifDnd
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
