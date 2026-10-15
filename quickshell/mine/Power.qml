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

    function run(id: string): void {
        menuOpen = false
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
