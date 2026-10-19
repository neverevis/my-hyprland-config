// Icones de apps por arquivo: Icons.path("firefox") -> "file:///usr/share/icons/.../firefox.svg".
// O indice (nome -> arquivo, seguindo o tema de icones e os herdados) e montado por scripts/icons.py em segundo plano
// e guardado em ~/.cache/quickshell-mine/icons.json; na proxima vez o shell ja comeca com ele.
// Por que nao Quickshell.iconPath: ele passa pelo carregador de icones do KDE (KIconLoader), que nao aguenta ser
// chamado ao mesmo tempo da thread de imagens e da principal e derrubava o shell (dock + launcher + notificacoes).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string file: Quickshell.env("HOME") + "/.cache/quickshell-mine/icons.json"
    readonly property string script: Qt.resolvedUrl("scripts/icons.py").toString().replace("file://", "")
    property var dirs: []
    property var ic: ({})
    property string theme: ""
    readonly property int count: Object.keys(ic).length

    function res(n) { const e = root.ic[n]; return e ? "file://" + root.dirs[e[0]] + "/" + n + e[1] : "" }
    // nome do icone (ou caminho) -> url do arquivo; tenta variacoes comuns e depois o reserva; "" se nada servir
    function path(name, fallback) {
        const n = (name || "").trim()
        if (n !== "") {
            if (n.startsWith("/")) return "file://" + n
            if (n.indexOf("://") > 0) return n
            const low = n.toLowerCase(), last = low.split(".").pop()
            const u = res(n) || res(low) || res(last) || res(low.replace(/ /g, "-")) || res(n.replace(/-symbolic$/, ""))
            if (u) return u
        }
        return fallback ? res(fallback) : ""
    }
    // icone de um app pela classe da janela (ou id do .desktop)
    function app(cls) {
        const e = cls ? DesktopEntries.heuristicLookup(cls) : null
        return path(e && e.icon ? e.icon : cls, "application-x-executable")
    }

    FileView {
        id: fv
        path: root.file
        blockLoading: true   // o indice ja existe nas proximas vezes: icones certos desde o primeiro quadro
        onLoaded: {
            try { const d = JSON.parse(text()); root.dirs = d.dirs || []; root.ic = d.icons || {}; root.theme = d.theme || "" }
            catch (e) { console.warn("Icons: indice invalido", e) }
        }
    }
    function rebuild() { build.running = false; build.running = true }
    Process {
        id: build
        command: ["python3", root.script, "auto", root.file]
        running: true
        stdout: StdioCollector { onStreamFinished: fv.reload() }
    }
    IpcHandler {
        target: "icons"
        function rebuild(): void { root.rebuild() }
        function find(name: string): string { return root.path(name, "") }
        function info(): string { return root.theme + " · " + root.count + " ícones" }
    }
}
