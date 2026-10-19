// Inatividade (sem hypridle): bloqueia a tela, apaga o monitor e, se pedido, suspende depois de N minutos sem uso.
// Respeita os apps que pedem para nao dormir (video no navegador, jogos...) e, se ligado, musica tocando.
// Tempos em minutos (0 = desligado): Settings.idleLock, idleScreenOff, idleSuspend. Configuracoes: pagina "Sessao".
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    readonly property bool ready: true
    readonly property bool mediaPlaying: Mpris.players.values.some(p => p.isPlaying)
    readonly property bool held: Settings.idleMedia && mediaPlaying
    // pausar por um tempo (ex.: assistindo algo fora do navegador): ipc idle hold
    property bool paused: false

    function dispatch(lua) { proc.command = ["hyprctl", "dispatch", lua]; proc.running = false; proc.running = true }
    Process { id: proc }

    IdleMonitor {
        enabled: Settings.idleLock > 0 && !root.held && !root.paused
        timeout: Math.max(1, Settings.idleLock) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle && !Power.locked) Power.lock()
    }
    IdleMonitor {
        id: screenMon
        enabled: Settings.idleScreenOff > 0 && !root.held && !root.paused
        timeout: Math.max(1, Settings.idleScreenOff) * 60
        respectInhibitors: true
        onIsIdleChanged: root.dispatch('hl.dsp.dpms({ action = "' + (isIdle ? "off" : "on") + '" })')
    }
    IdleMonitor {
        enabled: Settings.idleSuspend > 0 && !root.held && !root.paused
        timeout: Math.max(1, Settings.idleSuspend) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Power.run("suspend")
    }

    IpcHandler {
        target: "idle"
        function hold(): bool { root.paused = !root.paused; return root.paused }   // liga/desliga a pausa
        function status(): string { return JSON.stringify({ paused: root.paused, mediaHold: root.held, lock: Settings.idleLock, screenOff: Settings.idleScreenOff, suspend: Settings.idleSuspend }) }
    }
}
