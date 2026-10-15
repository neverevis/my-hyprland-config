// Foto de perfil e nome do usuario (usados no Inicio, no menu de energia e na tela de bloqueio).
// change() abre o navegador de imagens e depois o editor (PhotoEditor.qml); o recorte escolhido vira o ~/.face.
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

    property string editing: ""   // imagem aberta no editor de foto ("" = fechado)
    property bool picking: false  // navegador de imagens aberto (antes do editor)
    function pickFile(f: string): void { picking = false; editing = f }
    function save(rot: int, nx: real, ny: real, ns: real): void {
        const f = editing
        editing = ""
        busy = true
        apply.command = [root.py, root.script, f, String(rot), String(nx), String(ny), String(ns)]
        apply.running = true
    }
    function cancel(): void { picking = false; editing = ""; busy = false }

    IpcHandler {
        target: "profile"
        function change(): void { root.change() }
        function edit(path: string): void { root.busy = true; root.editing = path }   // abre o editor direto com uma imagem
        function cancel(): void { root.cancel() }
    }

    function change(): void {
        if (busy) return
        busy = true
        picking = true   // abre o navegador de imagens do proprio shell (PhotoEditor.qml)
    }

    Process {
        id: apply
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") console.warn("perfil: " + text.trim()) }
        onExited: code => { root.busy = false; if (code === 0) root.version++ }
    }
}
