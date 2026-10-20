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

    // ---- atualizacoes (checkupdates + AUR pelo yay/paru) ----
    // updates = total (repositorios + AUR); -1 = ainda verificando / sem checkupdates
    property int updates: -1
    property int updRepo: 0
    property int updAurN: 0
    property bool checking: false
    property int notified: -1
    function checkUpdates() { checking = true; upd.running = false; upd.running = true }
    Process {
        id: upd
        command: ["sh", "-c", 'command -v checkupdates >/dev/null || { echo "-1 0"; exit; }; r=$(checkupdates 2>/dev/null | wc -l); a=0; if [ "$1" = 1 ]; then h=$(command -v yay || command -v paru); [ -n "$h" ] && a=$("$h" -Qua 2>/dev/null | wc -l); fi; echo "$r $a"', "sh", Settings.updAur ? "1" : "0"]
        stdout: StdioCollector { onStreamFinished: {
            const p = text.trim().split(/\s+/).map(x => parseInt(x))
            root.checking = false
            root.updRepo = p[0] ?? -1; root.updAurN = p[1] ?? 0
            root.updates = root.updRepo < 0 ? -1 : root.updRepo + root.updAurN
            if (Settings.updWarn > 0 && root.updates >= Settings.updWarn && root.notified !== root.updates) {
                root.notified = root.updates
                Quickshell.execDetached(["notify-send", "-a", "Atualizações", "-i", "system-software-update", root.updates + " atualizações disponíveis", "Clique no módulo de atualizações da barra ou rode sudo pacman -Syu"])
            }
        } }
    }
    Timer { interval: Math.max(1, Settings.updHours) * 3600000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.checkUpdates() }
    // atualizar de verdade num terminal (pacman, e o yay/paru se o AUR estiver ligado): ao terminar, avisa e confere de novo
    function runUpdate() {
        if (updRun.running) return
        updRun.running = true
    }
    Process {
        id: updRun
        command: ["kitty", "sh", "-c", 'h=; [ "$1" = 1 ] && h=$(command -v yay || command -v paru); if [ -n "$h" ]; then "$h" -Syu; else sudo pacman -Syu; fi; st=$?; if [ $st -eq 0 ]; then notify-send -a Atualizações -i system-software-update "Atualização concluída" "O sistema foi atualizado."; else notify-send -a Atualizações -i dialog-warning "Atualização interrompida" "O terminal terminou com erro (código $st)."; fi; echo; read -r -p "Pressione Enter para fechar" _', "sh", Settings.updAur ? "1" : "0"]
        onExited: root.checkUpdates()
    }

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
