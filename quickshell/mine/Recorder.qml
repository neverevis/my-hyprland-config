// Gravacao de tela (wf-recorder): tela inteira ou uma area (slurp), com ou sem o audio do sistema.
// Salva em ~/Vídeos/Gravações; ao parar, notifica. IPC: qs -c mine ipc call recorder toggle | region | stop
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property bool active: proc.running
    property real started: 0
    property real now: Date.now()
    Timer { interval: 1000; repeat: true; running: root.active; onTriggered: root.now = Date.now() }
    readonly property string elapsed: { const s = Math.max(0, Math.round((now - started) / 1000)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }
    property bool audio: false
    property string file: ""
    readonly property string dir: Quickshell.env("HOME") + "/Vídeos/Gravações"

    function start(region) {
        if (active) return
        file = dir + "/gravacao_" + Qt.formatDateTime(new Date(), "yyyyMMdd_HH-mm-ss") + ".mp4"
        const sel = region ? 'g=$(slurp -d -b "#00000066" -c "#ffffffff" -w 2) || exit 0; ' : ""
        proc.command = ["sh", "-c", 'mkdir -p "$1"; ' + sel + 'exec wf-recorder ' + (region ? '-g "$g" ' : "") + (audio ? "--audio " : "") + '-f "$2"', "sh", dir, file]
        started = Date.now(); now = started
        proc.running = true
    }
    function stop() { if (active) Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]) }
    function toggle(region) { active ? stop() : start(region) }
    Process {
        id: proc
        onExited: (code, status) => {
            if (Date.now() - root.started > 1500)
                Quickshell.execDetached(["notify-send", "-a", "Gravação", "-i", "video-x-generic", "Gravação salva", root.file])
        }
    }
    IpcHandler {
        target: "recorder"
        function toggle(): void { root.toggle(false) }
        function region(): void { root.toggle(true) }
        function stop(): void { root.stop() }
    }
}
