// Cores e medidas da janela de configuracoes e dos paineis (a cor de destaque vem de Settings.accent).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color bg: Settings.themeOn ? ThemeColors.background : "#17161d"
    readonly property color sidebar: Settings.themeOn ? ThemeColors.surface : "#1d1c25"
    readonly property color card: Settings.themeOn ? ThemeColors.surfaceHigh : "#23222c"
    readonly property color cardHi: Settings.themeOn ? Qt.lighter(ThemeColors.surfaceHigh, 1.18) : "#2d2c39"
    readonly property color border: Settings.themeOn ? ThemeColors.outline : "#33313f"
    readonly property color text: Settings.themeOn ? ThemeColors.text : "#e8e3ee"
    readonly property color muted: Settings.themeOn ? ThemeColors.muted : "#8f8a99"
    readonly property color accent: Settings.accent
    readonly property color accentText: Settings.themeOn ? ThemeColors.onPrimary : "#15131a"
    readonly property color danger: Settings.themeOn ? ThemeColors.error : "#f7768e"
    // fundo rebaixado (trilhos, campos, seletores) dentro de um cartao
    readonly property color track: Qt.rgba(bg.r, bg.g, bg.b, 0.55)
    // destaque translucido (fundo de item selecionado)
    function tint(a: real): color { return Qt.rgba(accent.r, accent.g, accent.b, a) }

    // cor com a transparencia do vidro (Aparencia > Vidro); k escala a opacidade (1 = a mesma da moldura)
    function gl(c: color, k: real): color { return Qt.rgba(c.r, c.g, c.b, Settings.glass ? Math.min(1, Settings.glassOpacity / 100 * k) : 1) }
}
