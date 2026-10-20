// Historico das notificacoes (central do painel Inicio): guarda as ultimas 80 mesmo depois que o aviso some.
// Salvo em ~/.cache/quickshell-mine/notifications.json (sem as acoes: so avisos ainda vivos no servidor tem botoes).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var items: []      // mais nova primeiro: app, summary, body, icon, image, time, id, ref (Notification viva ou null)
    property int unread: 0

    // corpo para exibir: tira a linha-link dos avisos de navegadores Chromium e separa as imagens em paragrafo proprio
    function body(text, app, forPopup) {
        let b = String(text || "")
        const la = String(app || "").toLowerCase()
        if (["brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"].some(s => la.indexOf(s) >= 0)) {
            const parts = b.split("\n\n")
            if (parts.length > 1 && parts[0].indexOf("<a") === 0) b = parts.slice(1).join("\n\n")
        }
        if (forPopup) return b.replace(/<img[^>]*>/gi, "")
        return b.replace(/<img /gi, "\n\n<img width=\"280\" ")
    }

    // aviso sem icone: adivinha um pelo texto (como o end4)
    readonly property var guesses: [["reboot|restart|reinici", "refresh"], ["screenshot|captura|print", "frame"], ["updat|atualiz|upgrade", "download"], ["install|instala", "download"],
        ["music|música|musica|playing|tocando", "music"], ["record|grava", "monitor"], ["wifi|wi-fi|network|rede", "wifi"], ["bluetooth", "bluetooth"], ["volume|áudio|audio", "volume"], ["battery|bateria", "battery"]]
    function guessIcon(app, summary, body) {
        const t = (String(app) + " " + String(summary) + " " + String(body)).toLowerCase()
        for (const g of guesses) if (new RegExp(g[0]).test(t)) return g[1]
        return ""
    }

    function add(n) {
        const it = { app: n.appName || "", summary: n.summary || "", body: n.body || "", icon: n.appIcon || "", image: n.image || "", time: Date.now(), id: Date.now() + Math.random(), ref: n }
        items = [it].concat(items).slice(0, 80)
        unread++
        const id = it.id
        n.closed.connect(() => { root.items = root.items.map(x => x.id === id ? Object.assign({}, x, { ref: null }) : x); saveT.restart() })
        saveT.restart()
    }
    function remove(id) { items = items.filter(x => x.id !== id); saveT.restart() }
    function removeApp(app) { items = items.filter(x => x.app !== app); saveT.restart() }
    function clear() { items = []; unread = 0; saveT.restart() }
    // tempo relativo: agora / N min / N h / ontem / dd/MM
    function ago(t) {
        const m = Math.round((Date.now() - t) / 60000)
        if (m < 1) return "agora"
        if (m < 60) return m + " min"
        if (m < 60 * 24) return Math.round(m / 60) + " h"
        const d0 = new Date(); d0.setHours(0, 0, 0, 0)
        if (t >= d0.getTime() - 86400000) return "ontem"
        return Qt.formatDateTime(new Date(t), "dd/MM")
    }

    FileView {
        id: fv
        printErrors: false
        path: Quickshell.env("HOME") + "/.cache/quickshell-mine/notifications.json"
        onLoaded: {
            try {
                const l = JSON.parse(fv.text())
                if (Array.isArray(l) && root.items.length === 0) root.items = l.slice(0, 80).map(x => Object.assign({}, x, { ref: null }))
            } catch (e) {}
        }
    }
    Timer {
        id: saveT
        interval: 800
        onTriggered: fv.setText(JSON.stringify(root.items.map(x => ({ app: x.app, summary: x.summary, body: x.body, icon: x.icon, image: x.image, time: x.time, id: x.id }))))
    }
}
