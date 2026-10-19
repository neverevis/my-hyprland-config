// Frequencias do audio tocando (cava em modo "raw": 64 faixas de 0 a 1000 por linha, ~60 por segundo).
// So roda enquanto alguem usa (Cava.use()/release()). Sem o cava instalado: available = false.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int users: 0
    function use() { users++ }
    function release() { users = Math.max(0, users - 1) }
    property bool available: false
    property var values: []        // 64 valores 0..1
    property real level: 0         // media (para "esta tocando algo?")
    readonly property string conf: Quickshell.env("HOME") + "/.cache/quickshell-mine/cava.conf"

    Process {
        id: probe
        running: true
        command: ["sh", "-c", "command -v cava >/dev/null && mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' '[general]' 'bars = 64' 'framerate = 50' 'sleep_timer = 2' '[input]' 'method = pipewire' '[output]' 'method = raw' 'raw_target = /dev/stdout' 'data_format = ascii' 'ascii_max_range = 1000' 'bar_delimiter = 59' 'frame_delimiter = 10' '[smoothing]' 'noise_reduction = 66' > \"$1\" && echo ok", "sh", root.conf]
        stdout: StdioCollector { onStreamFinished: root.available = text.trim() === "ok" }
    }
    Process {
        id: cava
        running: root.available && root.users > 0
        command: ["cava", "-p", root.conf]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(x => x !== "").map(x => Math.min(1, parseInt(x) / 1000))
                root.values = v
                root.level = v.length ? v.reduce((a, b) => a + b, 0) / v.length : 0
            }
        }
        onRunningChanged: if (!running) { root.values = []; root.level = 0 }
    }
}
