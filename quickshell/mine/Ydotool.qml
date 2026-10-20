// Injecao de teclas para o teclado na tela (ydotool). Precisa do daemon: systemctl --user enable --now ydotool
// (e acesso a /dev/uinput). Sem o daemon, as teclas nao fazem nada e o teclado avisa.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool ready: false
    function check() { chk.running = false; chk.running = true }
    Process {
        id: chk
        command: ["sh", "-c", 's="${YDOTOOL_SOCKET:-$XDG_RUNTIME_DIR/.ydotool_socket}"; [ -S "$s" ] || [ -S /tmp/.ydotool_socket ]'] 
        onExited: code => root.ready = code === 0
    }
    // codes: lista de codigos evdev; mods: modificadores segurados durante a tecla
    function tap(code: int, mods: var): void {
        const seq = []
        for (const m of mods) seq.push(m + ":1")
        seq.push(code + ":1", code + ":0")
        for (let i = mods.length - 1; i >= 0; i--) seq.push(mods[i] + ":0")
        Quickshell.execDetached(["ydotool", "key"].concat(seq))
    }
    // solta tudo que o teclado pode ter deixado preso (ao fechar)
    function releaseAll(): void {
        Quickshell.execDetached(["ydotool", "key", "42:0", "54:0", "29:0", "97:0", "56:0", "100:0", "125:0"])
    }
}
