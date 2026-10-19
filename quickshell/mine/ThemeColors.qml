// Paleta de cores do tema (gerada a partir do wallpaper por PaletteExtractor.qml).
// "t" guarda as cores calculadas (texto #rrggbb); cada papel abaixo e uma cor animada que segue "t".
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var t: ({})   // preenchido pelo PaletteExtractor; vazio = usa as cores padrao
    property bool fading: false   // true durante a troca de paleta: os componentes desligam as proprias animacoes de cor (senao reiniciam a cada passo)

    readonly property var roles: [
        { id: "primary", label: "Destaque" },
        { id: "onPrimary", label: "Sobre o destaque" },
        { id: "secondary", label: "Secundária" },
        { id: "tertiary", label: "Terciária" },
        { id: "primaryContainer", label: "Destaque suave" },
        { id: "secondaryContainer", label: "Secundária suave" },
        { id: "tertiaryContainer", label: "Terciária suave" },
        { id: "background", label: "Fundo" },
        { id: "surface", label: "Superfície" },
        { id: "surfaceHigh", label: "Superfície alta" },
        { id: "outline", label: "Contorno" },
        { id: "text", label: "Texto" },
        { id: "muted", label: "Texto suave" },
        { id: "error", label: "Erro" },
        { id: "onPrimaryContainer", label: "Sobre o destaque suave" },
        { id: "onSecondaryContainer", label: "Sobre a secundária suave" },
        { id: "onTertiaryContainer", label: "Sobre a terciária suave" },
        { id: "onSecondary", label: "Sobre a secundária" },
        { id: "onTertiary", label: "Sobre a terciária" },
        { id: "surfaceLow", label: "Superfície baixa" },
        { id: "surfaceHighest", label: "Superfície mais alta" }
    ]
    readonly property var defaults: ({
        primary: "#bb9af7", onPrimary: "#1d1530", secondary: "#8fb4f0", tertiary: "#e0a8d8",
        background: "#15141b", surface: "#1b1b22", surfaceHigh: "#2a2934", outline: "#403e4d",
        text: "#e6e1e9", muted: "#a09aac", error: "#ff8a9a",
        primaryContainer: "#4a3f6b", secondaryContainer: "#3d4a66", tertiaryContainer: "#5c3d58",
        onPrimaryContainer: "#eadcff", onSecondaryContainer: "#d8e4ff", onTertiaryContainer: "#ffd9f3",
        onSecondary: "#13233f", onTertiary: "#3a1636", surfaceLow: "#18171f", surfaceHighest: "#34333f"
    })

    // propriedades com nome "onX" viram tratadores de sinal no QML (e valiam preto): o texto sobre uma cor e "xInk"
    function prop(id: string): string { return id.startsWith("on") ? id.charAt(2).toLowerCase() + id.slice(3) + "Ink" : id }
    function of(id: string): color { return root[prop(id)] }
    function hexOf(id: string): string { return (root.t[id] ?? root.defaults[id]).toString() }

    property color primary: t.primary ?? defaults.primary
    property color primaryInk: t.onPrimary ?? defaults.onPrimary
    property color secondary: t.secondary ?? defaults.secondary
    property color tertiary: t.tertiary ?? defaults.tertiary
    property color background: t.background ?? defaults.background
    property color surface: t.surface ?? defaults.surface
    property color surfaceHigh: t.surfaceHigh ?? defaults.surfaceHigh
    property color outline: t.outline ?? defaults.outline
    property color text: t.text ?? defaults.text
    property color muted: t.muted ?? defaults.muted
    property color error: t.error ?? defaults.error
    property color primaryContainer: t.primaryContainer ?? defaults.primaryContainer
    property color secondaryContainer: t.secondaryContainer ?? defaults.secondaryContainer
    property color tertiaryContainer: t.tertiaryContainer ?? defaults.tertiaryContainer
    property color primaryContainerInk: t.onPrimaryContainer ?? defaults.onPrimaryContainer
    property color secondaryContainerInk: t.onSecondaryContainer ?? defaults.onSecondaryContainer
    property color tertiaryContainerInk: t.onTertiaryContainer ?? defaults.onTertiaryContainer
    property color secondaryInk: t.onSecondary ?? defaults.onSecondary
    property color tertiaryInk: t.onTertiary ?? defaults.onTertiary
    property color surfaceLow: t.surfaceLow ?? defaults.surfaceLow
    property color surfaceHighest: t.surfaceHighest ?? defaults.surfaceHighest
    property var m: ({})   // todos os papeis do Material You (+ term0..15), como saem do script

}
