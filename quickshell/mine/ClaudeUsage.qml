// Uso do Claude Code lido de arquivos locais (~/.claude/projects, pelo scripts/claude_usage.py): sem rede, sem chaves.
// Tokens da janela de 5 h contra o limite escolhido (Settings.aiLimit), quando a janela zera e as sessoes ativas.
// So consulta enquanto alguem usa (modulo/cartao chama ClaudeUsage.use()). Sem ~/.claude: available = false e tudo fica quieto.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int users: 0
    function use() { users++; if (!ready && !busy) refresh() }
    function release() { users = Math.max(0, users - 1) }

    property bool ready: false
    property bool busy: false
    property bool available: true       // false = nada local para ler
    property real tokens5h: 0
    property real tokensDay: 0
    property real tokensWeek: 0
    property real reset: 0              // epoch (s) em que a janela de 5 h zera; 0 = sem uso na janela
    property int msgs: 0
    property var sessions: []           // [{ project, busy, age }]
    readonly property real limit: Math.max(1000, Settings.aiLimit)
    readonly property real frac: Math.min(1, tokens5h / limit)
    readonly property int busyN: sessions.filter(s => s.busy).length
    function fmt(n) { return n >= 1e6 ? (n / 1e6).toFixed(1) + " M" : n >= 1e3 ? Math.round(n / 1e3) + " mil" : String(Math.round(n)) }
    property real nowS: Date.now() / 1000
    Timer { interval: 30000; repeat: true; running: root.users > 0 && root.reset > 0; onTriggered: root.nowS = Date.now() / 1000 }
    readonly property string resetText: {
        if (reset <= 0) return "janela livre"
        const s = Math.max(0, Math.round(reset - nowS)), h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        return s <= 0 ? "zerando" : "zera em " + (h > 0 ? h + " h " : "") + m + " min"
    }

    function refresh() { if (!busy) { busy = true; proc.running = true } }
    Timer { interval: Math.max(30, Settings.aiInterval) * 1000; repeat: true; running: root.users > 0; onTriggered: root.refresh() }
    Process {
        id: proc
        command: ["python3", "-I", Qt.resolvedUrl("scripts/claude_usage.py").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const j = JSON.parse(text)
                root.available = !!j.ok
                if (j.ok) { root.tokens5h = j.tokens5h; root.tokensDay = j.tokensDay; root.tokensWeek = j.tokensWeek; root.reset = j.reset; root.msgs = j.msgs5h; root.sessions = j.sessions; root.nowS = Date.now() / 1000 }
            } catch (e) { root.available = false }
            root.ready = true; root.busy = false
        } }
        onExited: code => { if (code !== 0) { root.available = false; root.ready = true; root.busy = false } }
    }
    IpcHandler {
        target: "aiusage"
        function refresh(): void { root.refresh() }
        function status(): string { return JSON.stringify({ ready: root.ready, available: root.available, tokens5h: root.tokens5h, limit: root.limit, reset: root.resetText, sessions: root.sessions.length }) }
    }
}
