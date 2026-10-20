// Cores e medidas da janela de configuracoes e dos paineis (a cor de destaque vem de Settings.accent).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color bg: Settings.uiOled ? "#000000" : Settings.themeOn ? ThemeColors.background : "#17161d"
    readonly property color sidebar: Settings.uiOled ? "#000000" : Settings.themeOn ? ThemeColors.surface : "#1d1c25"
    readonly property color card: Settings.uiOled ? "#0c0c0e" : Settings.themeOn ? ThemeColors.surfaceHigh : "#23222c"
    readonly property color cardHi: Settings.themeOn ? Qt.lighter(ThemeColors.surfaceHigh, 1.18) : "#2d2c39"
    readonly property color border: Settings.themeOn ? ThemeColors.outline : "#33313f"
    readonly property color text: Settings.themeOn ? ThemeColors.text : "#e8e3ee"
    readonly property color muted: Settings.themeOn ? ThemeColors.muted : "#8f8a99"
    readonly property color accent: Settings.accent
    // fontes (Aparencia > Fontes): vazio = a do sistema
    readonly property string sysFont: Qt.application.font.family
    readonly property string font: Settings.fontUi !== "" ? Settings.fontUi : sysFont
    readonly property string mono: Settings.fontMono !== "" ? Settings.fontMono : "monospace"
    readonly property color accentText: Settings.themeOn ? ThemeColors.primaryInk : "#15131a"
    readonly property color danger: Settings.themeOn ? ThemeColors.error : "#f7768e"
    // ---- tons da paleta (Material): o shell inteiro pode usar mais que o destaque ----
    // com o tema desligado eles saem da cor de destaque escolhida (secundaria e terciaria giram o matiz)
    readonly property bool themed: Settings.themeOn
    function hue(c: color, dh: real, l: real): color { return Qt.hsla((c.hslHue + dh + 1) % 1, Math.max(0.35, c.hslSaturation * 0.85), l, 1) }
    readonly property color primary: accent
    readonly property color secondary: themed ? ThemeColors.secondary : hue(accent, 0.1, 0.72)
    readonly property color tertiary: themed ? ThemeColors.tertiary : hue(accent, -0.12, 0.74)
    readonly property color primaryContainer: themed ? ThemeColors.primaryContainer : Qt.tint(bg, Qt.rgba(accent.r, accent.g, accent.b, 0.34))
    readonly property color secondaryContainer: themed ? ThemeColors.secondaryContainer : Qt.tint(bg, Qt.rgba(secondary.r, secondary.g, secondary.b, 0.3))
    readonly property color tertiaryContainer: themed ? ThemeColors.tertiaryContainer : Qt.tint(bg, Qt.rgba(tertiary.r, tertiary.g, tertiary.b, 0.3))
    readonly property color primaryContainerInk: themed ? ThemeColors.primaryContainerInk : Qt.tint(text, Qt.rgba(accent.r, accent.g, accent.b, 0.3))
    readonly property color secondaryContainerInk: themed ? ThemeColors.secondaryContainerInk : Qt.tint(text, Qt.rgba(secondary.r, secondary.g, secondary.b, 0.3))
    readonly property color tertiaryContainerInk: themed ? ThemeColors.tertiaryContainerInk : Qt.tint(text, Qt.rgba(tertiary.r, tertiary.g, tertiary.b, 0.3))
    readonly property color secondaryInk: themed ? ThemeColors.secondaryInk : "#15131a"
    readonly property color tertiaryInk: themed ? ThemeColors.tertiaryInk : "#15131a"
    readonly property color surfaceLow: themed ? ThemeColors.surfaceLow : "#1a1920"
    readonly property color surfaceHighest: themed ? ThemeColors.surfaceHighest : "#32313d"

    // escolha de cor por nome (opcoes dos widgets, bordas do Hyprland...): id, rotulo
    readonly property var roleList: [
        ["primary", "Destaque"], ["secondary", "Secundária"], ["tertiary", "Terciária"],
        ["primaryContainer", "Destaque suave"], ["secondaryContainer", "Secundária suave"], ["tertiaryContainer", "Terciária suave"],
        ["text", "Texto"], ["surfaceHigh", "Superfície"], ["bg", "Fundo"]
    ]
    // a mesma cor clareada (tema escuro) ou escurecida (claro) ate dar para ler texto nela sobre o fundo
    function readable(c: color): color {
        const l = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
        if (Settings.themeModeEff !== "light") return l < 0.55 ? Qt.lighter(c, 1 + (0.62 - l) * 2.4) : c
        return l > 0.5 ? Qt.darker(c, 1 + (l - 0.42) * 2.4) : c
    }
    function role(id: string): color {
        switch (id) {
        case "primary": return primary
        case "secondary": return secondary
        case "tertiary": return tertiary
        case "primaryContainer": return primaryContainer
        case "secondaryContainer": return secondaryContainer
        case "tertiaryContainer": return tertiaryContainer
        case "onPrimaryContainer": return primaryContainerInk
        case "onSecondaryContainer": return secondaryContainerInk
        case "onTertiaryContainer": return tertiaryContainerInk
        case "surfaceHigh": return card
        case "surfaceLow": return surfaceLow
        case "surfaceHighest": return surfaceHighest
        case "bg": return bg
        case "muted": return muted
        case "outline": return border
        default: return text
        }
    }
    // os tons de uma familia (o widget com tom "secundaria" usa a secundaria, o container dela e o texto sobre ele;
    // "par" e a cor companheira para um segundo elemento, como o ponteiro dos minutos)
    function family(id: string): var {
        if (id === "secondary") return { main: secondary, cont: secondaryContainer, contInk: secondaryContainerInk, mainInk: secondaryInk, pair: tertiary }
        if (id === "tertiary") return { main: tertiary, cont: tertiaryContainer, contInk: tertiaryContainerInk, mainInk: tertiaryInk, pair: primary }
        return { main: primary, cont: primaryContainer, contInk: primaryContainerInk, mainInk: accentText, pair: tertiary }
    }

    // fundo rebaixado (trilhos, campos, seletores) dentro de um cartao
    readonly property color track: Qt.rgba(bg.r, bg.g, bg.b, 0.55)
    // destaque translucido (fundo de item selecionado)
    function tint(a: real): color { return Qt.rgba(accent.r, accent.g, accent.b, a) }

    // cor com a transparencia do vidro (Aparencia > Vidro); k escala a opacidade (1 = a mesma da moldura)
    // conteudo (cartoes): usa a transparencia propria quando "separar fundo e conteudo" esta ligado
    function glc(c: color, k: real): color { return Qt.rgba(c.r, c.g, c.b, Settings.glass ? Math.min(1, Settings.glassContentEff / 100 * k) : 1) }
    function gl(c: color, k: real): color { return Qt.rgba(c.r, c.g, c.b, Settings.glass ? Math.min(1, Settings.glassOpacityEff / 100 * k) : 1) }
}
