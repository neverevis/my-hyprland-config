// Estado do seletor de area (RegionSelector.qml): congela a tela (grim) e abre o seletor com uma acao escolhida.
// Acoes: copy, ocr, translate, annotate, lens, record. As que mexem na imagem rodam scripts/capture.py.
// IPC: qs -c mine ipc call region open copy | ocr | translate | annotate | lens | record
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root
    property bool open: false
    property string action: "copy"
    property string shape: "rect"          // rect | circle
    property string frozen: ""             // caminho da tela congelada (pronta)
    property string monitor: ""
    property string busy: ""
    property string lastMsg: ""
    property string lastText: ""
    property string lastAction: ""
    readonly property string file: Quickshell.env("HOME") + "/.cache/quickshell-mine/frozen.png"
    readonly property string script: Qt.resolvedUrl("scripts/capture.py").toString().replace("file://", "")
    readonly property var actions: [
        { id: "copy", label: "Copiar", icon: "frame", hint: "Copia e salva em Imagens/Screenshots" },
        { id: "ocr", label: "Texto", icon: "textBox", hint: "Copia o texto da área (OCR)" },
        { id: "translate", label: "Traduzir", icon: "earth", hint: "Lê o texto e copia a tradução para o português" },
        { id: "annotate", label: "Anotar", icon: "pencil", hint: "Abre no satty para desenhar e escrever" },
        { id: "lens", label: "Buscar", icon: "search", hint: "Google Lens (a imagem vai para o litterbox.catbox.moe e some em 1 h)" },
        { id: "record", label: "Gravar", icon: "monitor", hint: "Grava a área escolhida" }
    ]

    function start(a) {
        if (open || grab.running) return
        action = a || "copy"
        Settings.launcherOpen = false; Settings.homeOpen = false; Settings.wpPickerOpen = false
        monitor = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        frozen = ""
        grab.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")"; sleep 0.15; grim ' + (monitor ? '-o "$2" ' : "") + '"$1"', "sh", file, monitor]
        grab.running = true
    }
    Process {
        id: grab
        onExited: code => { if (code === 0) { root.frozen = root.file; root.open = true } }
    }
    function close() { open = false }
    // executa a acao na area (coordenadas da tela congelada)
    function run(x, y, w, h) {
        open = false
        if (action === "record") {
            const m = Hyprland.focusedMonitor
            const g = Math.round(x + (m ? m.x : 0)) + "," + Math.round(y + (m ? m.y : 0)) + " " + Math.round(w) + "x" + Math.round(h)
            Qt.callLater(() => Recorder.start(g))
            return
        }
        busy = action
        lastAction = action
        proc.command = ["python3", script, action, frozen, String(x), String(y), String(w), String(h)].concat(shape === "circle" ? ["circle"] : ["rect"])
        proc.running = true
    }
    Process {
        id: proc
        stdout: StdioCollector { id: out }
        onExited: {
            root.busy = ""
            try { const r = JSON.parse(out.text); root.lastMsg = r.msg; root.lastText = r.text ?? ""; SystemGuard.sound(r.ok ? (root.lastAction === "copy" ? "shot" : "") : "error") } catch (e) { root.lastMsg = "Falhou" }
        }
    }
    IpcHandler {
        target: "region"
        function open(action: string): void { root.start(action) }
        function close(): void { root.close() }
        function last(): string { return root.lastMsg + (root.lastText ? " :: " + root.lastText.slice(0, 200) : "") }
    }
}
