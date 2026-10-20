// Letra sincronizada da musica tocando (lrclib.net, sem chave). So busca enquanto alguem usa (Lyrics.use()).
// lines: lista de linhas (t em segundos, text); index = linha atual pela posicao do player.
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    property int users: 0
    function use() { users++; if (users === 1) look() }
    function release() { users = Math.max(0, users - 1) }

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string key: player ? (player.trackArtist || "") + "|" + (player.trackTitle || "") : ""
    property string loadedKey: ""
    property var lines: []
    property bool plain: false       // so letra sem tempo
    property string status: ""      // "", "buscando", "sem letra"
    property real pos: 0
    Timer { interval: 250; repeat: true; running: root.users > 0 && !!root.player && root.player.isPlaying; onTriggered: { root.player.positionChanged(); root.pos = root.player.position } }
    readonly property int index: { let i = -1; for (let k = 0; k < lines.length; k++) { if (lines[k].t <= pos + 0.25) i = k; else break } return i }
    onKeyChanged: if (users > 0) look()

    // tentar de novo (clique no indicador)
    function restart() { loadedKey = ""; look() }

    function look() {
        if (!player || key === loadedKey || !player.trackTitle) return
        loadedKey = key; lines = []; plain = false; status = "buscando"
        const q = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(player.trackArtist || "") + "&track_name=" + encodeURIComponent(player.trackTitle)
            + (player.length > 0 ? "&duration=" + Math.round(player.length) : "")
        req.command = ["curl", "-sf", "--max-time", "12", "-H", "User-Agent: quickshell-mine (https://github.com/neverevis)", q]
        req.running = false; req.running = true
    }
    Process {
        id: req
        stdout: StdioCollector { onStreamFinished: {
            try {
                const j = JSON.parse(text)
                if (j.syncedLyrics) {
                    root.lines = j.syncedLyrics.split("\n").map(l => /^\[(\d+):(\d+(?:\.\d+)?)\]\s?(.*)$/.exec(l)).filter(m => m)
                        .map(m => ({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3] || "♪" }))
                    root.status = ""
                } else if (j.plainLyrics) {
                    root.lines = j.plainLyrics.split("\n").map(l => ({ t: 0, text: l })); root.plain = true; root.status = ""
                } else root.status = "sem letra"
            } catch (e) { root.status = "sem letra" }
        } }
    }
}
