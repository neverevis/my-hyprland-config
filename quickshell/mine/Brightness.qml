// Brilho da tela (brightnessctl). Sem backlight (PC de mesa) fica "available: false" e nada acontece.
// Usado pelos cantos ativos (roda do mouse). value = 0..1.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool available: false
    property real value: 0
    property int users: 0
    function use() { users++ }
    function release() { users = Math.max(0, users - 1) }

    // descobre se existe um dispositivo de backlight (uma vez)
    Process {
        id: probe
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && brightnessctl -m -c backlight info 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
        running: true
    }
    function parse(t) {
        // formato: nome,classe,atual,percentual%,maximo
        const f = t.trim().split(",")
        if (f.length < 5) { available = false; return }
        available = true
        value = Math.max(0, Math.min(1, parseInt(f[2]) / Math.max(1, parseInt(f[4]))))
    }
    function refresh() { if (available) { probe.running = false; probe.running = true } }
    // d em fracao (ex.: 0.05); o minimo e 1% para a tela nao apagar
    function step(d) {
        if (!available) return
        value = Math.max(0.01, Math.min(1, value + d))
        Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(value * 100) + "%"])
    }
}
