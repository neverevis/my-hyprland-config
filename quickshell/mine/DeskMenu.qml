// Menu de clique direito da area de trabalho (desenhado pela DesktopLayer): posicao, widget clicado (ou "") e submenu.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    property bool open: false
    property real x: 0
    property real y: 0
    property string wid: ""
    property string sub: ""          // "add" | "presets" | ""
    function show(px, py, id) { x = px; y = py; wid = id ?? ""; sub = ""; open = true }
    function close() { open = false; sub = "" }
}
