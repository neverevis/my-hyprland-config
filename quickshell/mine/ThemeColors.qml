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
        { id: "error", label: "Erro" }
    ]
    readonly property var defaults: ({
        primary: "#bb9af7", onPrimary: "#1d1530", secondary: "#8fb4f0", tertiary: "#e0a8d8",
        background: "#15141b", surface: "#1b1b22", surfaceHigh: "#2a2934", outline: "#403e4d",
        text: "#e6e1e9", muted: "#a09aac", error: "#ff8a9a",
        primaryContainer: "#4a3f6b", secondaryContainer: "#3d4a66", tertiaryContainer: "#5c3d58"
    })

    function of(id: string): color { return root[id] }
    function hexOf(id: string): string { return (root.t[id] ?? root.defaults[id]).toString() }

    property color primary: t.primary ?? defaults.primary
    property color onPrimary: t.onPrimary ?? defaults.onPrimary
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
    property var m: ({})   // todos os papeis do Material You (+ term0..15), como saem do script

}
