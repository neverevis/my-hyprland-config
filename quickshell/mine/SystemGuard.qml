// Cuidados do sistema (pagina Sessao): protecao de volume (teto e saltos), atualizacoes do pacman com aviso,
// outros daemons de notificacao em conflito, sons do shell.
// Desligar/reiniciar/sair com o pacman (ou yay/paru) rodando e protegido no Power.qml (usa busy() daqui).
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    // ---- volume: teto e salto maximo por mudanca ----
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    property real last: -1
    property bool fixing: false
    onVolChanged: {
        if (!sink || !sink.audio || fixing) { last = vol; return }
        let v = vol
        if (Settings.volGuard) {
            const cap = Settings.volMax / 100
            if (v > cap + 0.001) v = cap
            if (last >= 0 && Settings.volJump > 0 && v - last > Settings.volJump / 100 + 0.001) v = last + Settings.volJump / 100
        }
        if (Math.abs(v - vol) > 0.001) { fixing = true; sink.audio.volume = v; fixing = false }
        last = v
    }

    // ---- atualizacoes (checkupdates) ----
    property int updates: -1
    property int notified: -1
    function checkUpdates() { upd.running = false; upd.running = true }
    Process {
        id: upd
        command: ["sh", "-c", "command -v checkupdates >/dev/null && checkupdates 2>/dev/null | wc -l || echo -1"]
        stdout: StdioCollector { onStreamFinished: {
            root.updates = parseInt(text.trim())
            if (Settings.updWarn > 0 && root.updates >= Settings.updWarn && root.notified !== root.updates) {
                root.notified = root.updates
                Quickshell.execDetached(["notify-send", "-a", "Atualizações", "-i", "system-software-update", root.updates + " atualizações disponíveis", "Clique no módulo de atualizações da barra ou rode sudo pacman -Syu"])
            }
        } }
    }
    Timer { interval: Math.max(1, Settings.updHours) * 3600000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.checkUpdates() }

    // ---- pacman rodando? (para nao desligar no meio de uma atualizacao) ----
    function busy(cb) { busyProc.cb = cb; busyProc.running = false; busyProc.running = true }
    Process {
        id: busyProc
        property var cb: null
        command: ["sh", "-c", "pgrep -x 'pacman|yay|paru|makepkg' >/dev/null && echo 1 || echo 0"]
        stdout: StdioCollector { onStreamFinished: { const f = busyProc.cb; busyProc.cb = null; if (f) f(text.trim() === "1") } }
    }

    // ---- conflitos: outros daemons de notificacao ----
    property var conflicts: []
    function scan() { conf.running = false; conf.running = true }
    Process {
        id: conf
        command: ["sh", "-c", "for p in dunst mako swaync fnott notification-daemon xfce4-notifyd; do pgrep -x $p >/dev/null && echo $p; done"]
        stdout: StdioCollector { onStreamFinished: {
            root.conflicts = text.split("\n").filter(x => x)
            if (Settings.killConflicts && root.conflicts.length) { Quickshell.execDetached(["pkill", "-x", root.conflicts.join("|")]); root.conflicts = [] }
        } }
    }
    Timer { interval: 8000; running: true; onTriggered: root.scan() }

    // ---- sons do shell (pw-play, tema freedesktop) ----
    function sound(kind) {
        if (!Settings.sounds) return
        const f = ({ notif: "message-new-instant", volume: "audio-volume-change", shot: "camera-shutter", error: "dialog-warning" })[kind]
        if (f) Quickshell.execDetached(["sh", "-c", 'f=/usr/share/sounds/freedesktop/stereo/$1.oga; [ -f "$f" ] && pw-play --volume ' + (Settings.soundVolume / 100).toFixed(2) + ' "$f"', "sh", f])
    }
}
