// Webapps: sites como aplicativos (atalhos .desktop com o navegador em modo --app). scripts/webapp.py cria e apaga;
// o launcher indexa os .desktop sozinho. Navegador: AppCmds "browser".
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var apps: []
    property string msg: ""
    property bool busy: false
    readonly property string script: Qt.resolvedUrl("scripts/webapp.py").toString().replace("file://", "")
    function refresh(): void { lister.running = false; lister.running = true }
    function add(urls: string): void {
        const l = urls.split(/[\n\s]+/).filter(x => x.trim() !== "")
        if (!l.length || busy) return
        busy = true; msg = ""
        const b = AppCmds.cmd("browser")
        adder.command = ["sh", "-c", 'p="$1"; b="$2"; shift 2; for u in "$@"; do python3 "$p" add "$u" "$b"; done', "sh", script, b].concat(l)
        adder.running = false; adder.running = true
    }
    function remove(id: string): void { Quickshell.execDetached(["python3", script, "remove", id]); delay.restart() }
    Timer { id: delay; interval: 600; onTriggered: root.refresh() }
    Process {
        id: lister
        command: ["python3", root.script, "list"]
        stdout: StdioCollector { onStreamFinished: { try { root.apps = JSON.parse(text) } catch (e) { root.apps = [] } } }
    }
    Process {
        id: adder
        stdout: StdioCollector { onStreamFinished: {
            root.busy = false
            const bad = text.split("\n").filter(x => x.startsWith("erro"))
            root.msg = bad.length ? bad[0].replace("erro: ", "Não deu: ") : "Pronto: aparece no launcher."
            root.refresh()
        } }
    }
}
