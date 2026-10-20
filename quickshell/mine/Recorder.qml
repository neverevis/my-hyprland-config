// Gravacao de tela (wf-recorder): tela inteira ou uma area (slurp), com ou sem o audio do sistema.
// Salva em ~/Vídeos/Gravações; ao parar, notifica. IPC: qs -c mine ipc call recorder toggle | region | stop
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root
    readonly property bool active: proc.running
    property real started: 0
    property real now: Date.now()
    Timer { interval: 1000; repeat: true; running: root.active; onTriggered: root.now = Date.now() }
    readonly property string elapsed: { const s = Math.max(0, Math.round((now - started) / 1000)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }
    property string file: ""
    property string geo: ""   // area gravada ("x,y wxh", coordenadas globais); vazio = tela inteira
    readonly property string dir: (Settings.recDir || "~/Vídeos/Gravações").replace(/^~/, Quickshell.env("HOME"))
    // audio: none | system (o que toca no PC) | mic (microfone) | both (os dois misturados) - pelo PipeWire (nomes do pulse)
    readonly property string audioArg: Settings.recAudio === "system" ? '--audio="@DEFAULT_MONITOR@" ' : Settings.recAudio === "mic" ? '--audio="@DEFAULT_SOURCE@" ' : ""

    // region: false = tela inteira, true = escolher com o slurp, texto "x,y wxh" = essa area (seletor do shell)
    function start(region) {
        if (active) return
        file = dir + "/gravacao_" + Qt.formatDateTime(new Date(), "yyyyMMdd_HH-mm-ss") + ".mp4"
        const geo = typeof region === "string" ? region : ""
        root.geo = geo
        const mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        const sel = region === true ? 'g=$(slurp -d -b "#00000066" -c "#ffffffff" -w 2) || exit 0; ' : (geo ? 'g="$3"; ' : "")
        const both = Settings.recAudio === "both"
        const rec = 'wf-recorder ' + (region ? '-g "$g" ' : (mon ? '-o "$4" ' : "")) + '-x yuv420p ' + (both ? '"$A" ' : root.audioArg) + (Settings.recFps > 0 ? "-r " + Settings.recFps + " " : "") + '-f "$2"'
        // som do PC + microfone: sink virtual temporario com dois loopbacks (descarregados ao terminar); sem pactl/sink, grava so o som do PC
        const mix = both ? 'ds="$(pactl get-default-sink 2>/dev/null).monitor"; dm=$(pactl get-default-source 2>/dev/null); A="--audio=$ds"; ' +
            'm1=$(pactl load-module module-null-sink sink_name=mine_rec_mix sink_properties=device.description=mine_rec_mix 2>/dev/null); ' +
            'if [ -n "$m1" ]; then l1=$(pactl load-module module-loopback source="$ds" sink=mine_rec_mix latency_msec=30 2>/dev/null); l2=$(pactl load-module module-loopback source="$dm" sink=mine_rec_mix latency_msec=30 2>/dev/null); A="--audio=mine_rec_mix.monitor"; fi; ' : ""
        const tail = both ? '; r=$?; for m in $l2 $l1 $m1; do pactl unload-module $m 2>/dev/null; done; exit $r' : ""
        proc.command = ["sh", "-c", 'mkdir -p "$1"; ' + sel + mix + 'notify-send -a Gravação -i media-record "Gravação iniciada" "Salvando em $1"; ' + (both ? "" : "exec ") + rec + tail, "sh", dir, file, geo, mon]
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
        function area(x: int, y: int, w: int, h: int): void { root.toggle(x + "," + y + " " + w + "x" + h) }
    }
}
