// Escolher uma imagem de qualquer lugar do shell: Pick.image(titulo, path => ...) abre o navegador de imagens proprio
// (PickWindow.qml) e chama a funcao com o caminho escolhido (nada, se cancelar).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    property bool open: false
    property string title: "Escolha uma imagem"
    property var cb: null
    function image(title, cb) { root.title = title || "Escolha uma imagem"; root.cb = cb; root.open = true }
    function done(path) { const f = cb; cb = null; open = false; if (f && path) f(path) }
    function cancel() { cb = null; open = false }
}
