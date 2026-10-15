// Cores e medidas da janela de configuracoes (a cor de destaque vem de Settings.accent).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color bg: "#17161d"
    readonly property color sidebar: "#1d1c25"
    readonly property color card: "#23222c"
    readonly property color cardHi: "#2d2c39"
    readonly property color border: "#33313f"
    readonly property color text: "#e8e3ee"
    readonly property color muted: "#8f8a99"
    readonly property color accent: Settings.accent
    readonly property color accentText: "#15131a"
    readonly property color danger: "#f7768e"
}
