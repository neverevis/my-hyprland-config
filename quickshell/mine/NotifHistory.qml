// Historico das notificacoes (central do painel Inicio): guarda as ultimas 80 mesmo depois que o aviso some.
// So na memoria (zera ao reiniciar o shell).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    property var items: []      // mais nova primeiro: app, summary, body, icon, image, time
    property int unread: 0
    function add(n) {
        const it = { app: n.appName || "", summary: n.summary || "", body: n.body || "", icon: n.appIcon || "", image: n.image || "", time: Date.now(), id: Date.now() + Math.random() }
        items = [it].concat(items).slice(0, 80)
        unread++
    }
    function remove(id) { items = items.filter(x => x.id !== id) }
    function clear() { items = []; unread = 0 }
    function ago(t) { const m = Math.round((Date.now() - t) / 60000); return m < 1 ? "agora" : m < 60 ? m + " min" : Math.round(m / 60) + " h" }
}
