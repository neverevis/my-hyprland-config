// Lista de players MPRIS sem duplicatas (playerctld e copias do mesmo navegador) e escolha do player principal:
// o preferido (Settings.mediaPreferred), senao o que tocou por ultimo, senao o primeiro.
pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    readonly property var raw: Mpris.players.values
    readonly property var list: {
        const all = raw.filter(p => (p.dbusName || "").indexOf("playerctld") < 0)
        if (!Settings.mediaDedupe) return all
        const seen = {}, out = []
        for (const p of all) {
            const k = (p.trackTitle || "") + "|" + (p.trackArtist || "") + "|" + Math.round(p.length || 0)
            if ((p.trackTitle || "") !== "" && seen[k] !== undefined) {
                if (p.isPlaying && !out[seen[k]].isPlaying) out[seen[k]] = p
                continue
            }
            seen[k] = out.length; out.push(p)
        }
        return out
    }
    property string lastPlaying: ""
    readonly property var playingNow: list.find(p => p.isPlaying) ?? null
    onPlayingNowChanged: if (playingNow) lastPlaying = playingNow.dbusName || ""
    function pick(i) {
        if (i >= 0 && i < list.length) return list[i]
        const pref = (Settings.mediaPreferred || "").toLowerCase()
        if (pref !== "") { const m = list.find(p => ((p.identity || "") + " " + (p.dbusName || "")).toLowerCase().indexOf(pref) >= 0); if (m) return m }
        return playingNow ?? list.find(p => (p.dbusName || "") === lastPlaying) ?? (list.length > 0 ? list[0] : null)
    }
}
