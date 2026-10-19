// Modulos de barra (os novos): weather, media, netspeed, gpu, temp, updates, keyboard, recorder, notifs, launcher,
// utils (capturar / cor / microfone), caffeine, visualizer. Nas barras laterais cada um fica compacto (icone em cima
// do valor). Clique e roda fazem a acao natural de cada um (ver comentarios).
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick

Item {
    id: root
    property string type
    property var opts: ({})
    property bool vertical: false
    property string side: "bottom"
    implicitWidth: ld.item ? ld.item.implicitWidth : 0
    implicitHeight: ld.item ? ld.item.implicitHeight : 0
    readonly property color fg: Settings.textColor
    readonly property color ac: Settings.accent

    // icone + texto (lado a lado na barra horizontal, empilhados na lateral)
    component Chip: Item {
        id: ch
        property string icon
        property string text
        property color tint: root.fg
        property bool hot: false
        signal clicked(var mouse)
        signal wheel(int dy)
        implicitWidth: root.vertical ? Math.max(ic.implicitWidth, tx.implicitWidth) : ic.implicitWidth + (tx.text !== "" ? tx.implicitWidth + 6 : 0)
        implicitHeight: root.vertical ? ic.implicitHeight + (tx.text !== "" ? tx.implicitHeight + 2 : 0) : Math.max(ic.implicitHeight, tx.implicitHeight)
        opacity: ma.containsMouse ? 0.8 : 1
        UiIcon { id: ic; name: ch.icon; size: 16; color: ch.hot ? root.ac : ch.tint; visible: ch.icon !== ""
            x: root.vertical ? (ch.width - width) / 2 : 0; y: root.vertical ? 0 : (ch.height - height) / 2 }
        Text { id: tx; text: ch.text; color: ch.tint; font.pixelSize: root.vertical ? 10 : 13; font.features: { "tnum": 1 }
            x: root.vertical ? (ch.width - width) / 2 : (ic.visible ? ic.width + 6 : 0); y: root.vertical ? ic.height + 2 : (ch.height - height) / 2 }
        MouseArea { id: ma; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: m => ch.clicked(m); onWheel: w => ch.wheel(w.angleDelta.y) }
    }

    Loader {
        id: ld
        sourceComponent: ({ weather: weatherC, media: mediaC, netspeed: netC, gpu: gpuC, temp: tempC, updates: updC, keyboard: kbC, recorder: recC,
                            notifs: notifC, launcher: launchC, utils: utilsC, caffeine: cafC, visualizer: visC })[root.type] ?? null
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
    // atualizacoes (checkupdates a cada 2 h): clique abre o pacman num terminal
    Component { id: updC; Chip {
        id: up
        property int count: -1
        visible: count !== 0
        icon: "download"; text: count < 0 ? "…" : String(count)
        hot: count > 50
        Process { id: cu; command: ["checkupdates"]; stdout: StdioCollector { onStreamFinished: up.count = text.split("\n").filter(l => l.trim()).length } }
        Timer { interval: 2 * 3600 * 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: { cu.running = false; cu.running = true } }
        onClicked: Quickshell.execDetached(["kitty", "--hold", "sh", "-c", "sudo pacman -Syu"])
    } }
    // layout do teclado: clique troca para o proximo
    Component { id: kbC; Chip {
        id: kb
        property string layout: ""
        icon: "keyboard"
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
        tint: Theme.danger
        SequentialAnimation on opacity { running: Recorder.active; loops: Animation.Infinite; NumberAnimation { to: 0.45; duration: 700 } NumberAnimation { to: 1; duration: 700 } }
        onClicked: Recorder.stop()
    } }
    // notificacoes: sino (com nao perturbe); clique liga/desliga o nao perturbe, direito limpa
    Component { id: notifC; Chip {
        icon: Settings.notifDnd ? "bellOff" : (BarState.notifCount > 0 ? "bellRing" : "bell")
        hot: BarState.notifCount > 0
        text: BarState.notifCount > 0 && !Settings.notifDnd ? String(BarState.notifCount) : ""
        onClicked: m => m.button === Qt.RightButton ? Actions.run("notifClear") : Settings.notifDnd = !Settings.notifDnd
    } }
    Component { id: launchC; Chip { icon: root.opts.icon ?? "apps"; onClicked: Settings.launcherOpen = !Settings.launcherOpen } }
    Component { id: cafC; Chip { icon: "coffee"; hot: Idle.paused; onClicked: Idle.paused = !Idle.paused } }
    // utilidades: capturar uma area, pegar uma cor, microfone (mudo)
    Component { id: utilsC; Grid {
        columns: root.vertical ? 1 : 3
        spacing: root.vertical ? 8 : 12
        readonly property var mic: Pipewire.defaultAudioSource
        PwObjectTracker { objects: [parent.mic] }
        Chip { icon: "frame"; onClicked: Actions.run("shot") }
        Chip { icon: "palette"; onClicked: Actions.run("picker") }
        Chip { icon: parent.mic && parent.mic.audio && parent.mic.audio.muted ? "micOff" : "mic"; hot: !!(parent.mic && parent.mic.audio && !parent.mic.audio.muted)
            onClicked: if (parent.mic && parent.mic.audio) parent.mic.audio.muted = !parent.mic.audio.muted }
    } }
    // mini visualizador (cava)
    Component { id: visC; Item {
        Component.onCompleted: Cava.use(); Component.onDestruction: Cava.release()
        readonly property int n: root.opts.bars ?? 10
        implicitWidth: root.vertical ? 18 : n * 4
        implicitHeight: root.vertical ? n * 4 : 18
        visible: Cava.available
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
}
