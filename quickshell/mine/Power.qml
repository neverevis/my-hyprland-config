// Acoes de energia/sessao e o estado do menu de energia e da tela de bloqueio.
//   qs -c mine ipc call session menu | lock | suspend | logout | reboot | poweroff
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool menuOpen: false
    property bool locked: false

    readonly property var actions: [
        { id: "lock", label: "Bloquear", icon: "lock", key: "B", confirm: false },
        { id: "suspend", label: "Suspender", icon: "sleep", key: "S", confirm: false },
        { id: "logout", label: "Sair", icon: "logout", key: "L", confirm: true, verb: "Saindo" },
        { id: "reboot", label: "Reiniciar", icon: "restart", key: "R", confirm: true, verb: "Reiniciando" },
        { id: "poweroff", label: "Desligar", icon: "power", key: "D", confirm: true, verb: "Desligando" }
    ]

    // desligar/reiniciar/sair com o pacman rodando: avisa e so faz se pedir de novo em 15 s
    property real forceUntil: 0
    function run(id: string): void {
        menuOpen = false
        if (Settings.sessionGuard && (id === "logout" || id === "reboot" || id === "poweroff") && Date.now() > forceUntil) {
            SystemGuard.busy((b, kind) => {
                if (b) {
                    root.forceUntil = Date.now() + 15000
                    Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Sessão", "-i", "dialog-warning", kind === "dl" ? "Um download está em andamento" : "Uma atualização está rodando", (kind === "dl" ? "Espere o download terminar. Para " : "Espere o pacman terminar. Para ") + (id === "poweroff" ? "desligar" : id === "reboot" ? "reiniciar" : "sair") + " mesmo assim, peça de novo em 15 segundos."])
                } else { root.forceUntil = Date.now() + 2000; root.run(id) }
            })
            return
        }
        if (id === "lock") lock()
        else if (id === "suspend") { lock(); suspendTimer.restart() }   // bloqueia antes de dormir
        else if (id === "logout") Quickshell.execDetached(["uwsm", "stop"])
        else if (id === "reboot") Quickshell.execDetached(["systemctl", "reboot"])
        else if (id === "poweroff") Quickshell.execDetached(["systemctl", "poweroff"])
    }
    function lock(): void { menuOpen = false; locked = true }
    Timer { id: suspendTimer; interval: 700; onTriggered: Quickshell.execDetached(["systemctl", "suspend"]) }

    IpcHandler {
        target: "session"
        function menu(): void { root.menuOpen = !root.menuOpen }
        function lock(): void { root.lock() }
        function suspend(): void { root.run("suspend") }
        function logout(): void { root.run("logout") }
        function reboot(): void { root.run("reboot") }
        function poweroff(): void { root.run("poweroff") }
        function islocked(): bool { return root.locked }
    }
}
