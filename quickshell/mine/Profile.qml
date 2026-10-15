// Foto de perfil e nome do usuario (usados no Inicio, no menu de energia e na tela de bloqueio).
// change() abre um seletor de arquivo; a imagem escolhida e recortada em quadrado e vira o ~/.face.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string user: Quickshell.env("USER") || "?"
    readonly property string name: user.charAt(0).toUpperCase() + user.slice(1)
    readonly property string initial: user.charAt(0).toUpperCase()
    readonly property string facePath: Quickshell.env("HOME") + "/.face"
    property int version: 0   // muda a cada troca: forca as imagens a recarregar (sem cache)
    readonly property string face: "file://" + facePath + "?v=" + version
    property bool busy: false

    readonly property string py: Quickshell.env("HOME") + "/.local/share/quickshell-mine/venv/bin/python"
    readonly property string script: Qt.resolvedUrl("scripts/set_face.py").toString().replace("file://", "")

    function change(): void {
        if (busy) return
        busy = true
        pick.running = true
    }

    Process {
        id: pick
        command: ["zenity", "--file-selection", "--title=Escolha sua foto de perfil",
                  "--file-filter=Imagens | *.png *.jpg *.jpeg *.webp *.bmp *.gif *.PNG *.JPG *.JPEG *.WEBP"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim()
                if (f === "") { root.busy = false; return }
                apply.command = [root.py, root.script, f]
                apply.running = true
            }
        }
        onExited: code => { if (code !== 0) root.busy = false }
    }
    Process {
        id: apply
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") console.warn("perfil: " + text.trim()) }
        onExited: code => { root.busy = false; if (code === 0) root.version++ }
    }
}
