// Esquemas de cores prontos ("Integradas"). Cada um define as cores base; os papeis do Material (containers etc.) sao derivados.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    function mix(a: string, b: string, t: real): string {
        const pa = Qt.color(a), pb = Qt.color(b)
        const h = v => ("0" + Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)).slice(-2)
        return "#" + h(pa.r + (pb.r - pa.r) * t) + h(pa.g + (pb.g - pa.g) * t) + h(pa.b + (pb.b - pa.b) * t)
    }

    // bg/low/lowest/s1/s2: fundos (do mais escuro ao mais claro); text/muted/outline; primary/secondary/tertiary/error; term: 16 cores ANSI
    readonly property var list: [
        { id: "mocha", name: "Catppuccin Mocha", dark: true, bg: "#1e1e2e", lowest: "#11111b", low: "#181825", s1: "#313244", s2: "#45475a", text: "#cdd6f4", muted: "#a6adc8", outline: "#6c7086", primary: "#cba6f7", secondary: "#89b4fa", tertiary: "#f5c2e7", error: "#f38ba8", term: ["#45475a","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#f5c2e7","#94e2d5","#bac2de","#585b70","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#f5c2e7","#94e2d5","#a6adc8"] },
        { id: "macchiato", name: "Catppuccin Macchiato", dark: true, bg: "#24273a", lowest: "#181926", low: "#1e2030", s1: "#363a4f", s2: "#494d64", text: "#cad3f5", muted: "#a5adcb", outline: "#6e738d", primary: "#c6a0f6", secondary: "#8aadf4", tertiary: "#f5bde6", error: "#ed8796", term: ["#494d64","#ed8796","#a6da95","#eed49f","#8aadf4","#f5bde6","#8bd5ca","#b8c0e0","#5b6078","#ed8796","#a6da95","#eed49f","#8aadf4","#f5bde6","#8bd5ca","#a5adcb"] },
        { id: "frappe", name: "Catppuccin Frappé", dark: true, bg: "#303446", lowest: "#232634", low: "#292c3c", s1: "#414559", s2: "#51576d", text: "#c6d0f5", muted: "#a5adce", outline: "#737994", primary: "#ca9ee6", secondary: "#8caaee", tertiary: "#f4b8e4", error: "#e78284", term: ["#51576d","#e78284","#a6d189","#e5c890","#8caaee","#f4b8e4","#81c8be","#b5bfe2","#626880","#e78284","#a6d189","#e5c890","#8caaee","#f4b8e4","#81c8be","#a5adce"] },
        { id: "latte", name: "Catppuccin Latte", dark: false, bg: "#eff1f5", lowest: "#dce0e8", low: "#e6e9ef", s1: "#ccd0da", s2: "#bcc0cc", text: "#4c4f69", muted: "#6c6f85", outline: "#9ca0b0", primary: "#8839ef", secondary: "#1e66f5", tertiary: "#ea76cb", error: "#d20f39", term: ["#5c5f77","#d20f39","#40a02b","#df8e1d","#1e66f5","#ea76cb","#179299","#acb0be","#6c6f85","#d20f39","#40a02b","#df8e1d","#1e66f5","#ea76cb","#179299","#bcc0cc"] },
        { id: "dracula", name: "Dracula", dark: true, bg: "#282a36", lowest: "#191a21", low: "#21222c", s1: "#343746", s2: "#44475a", text: "#f8f8f2", muted: "#bfc2d4", outline: "#6272a4", primary: "#bd93f9", secondary: "#8be9fd", tertiary: "#ff79c6", error: "#ff5555", term: ["#21222c","#ff5555","#50fa7b","#f1fa8c","#bd93f9","#ff79c6","#8be9fd","#f8f8f2","#6272a4","#ff6e6e","#69ff94","#ffffa5","#d6acff","#ff92df","#a4ffff","#ffffff"] },
        { id: "gruvbox", name: "Gruvbox Dark", dark: true, bg: "#282828", lowest: "#1d2021", low: "#232323", s1: "#3c3836", s2: "#504945", text: "#ebdbb2", muted: "#a89984", outline: "#7c6f64", primary: "#fabd2f", secondary: "#83a598", tertiary: "#d3869b", error: "#fb4934", term: ["#282828","#cc241d","#98971a","#d79921","#458588","#b16286","#689d6a","#a89984","#928374","#fb4934","#b8bb26","#fabd2f","#83a598","#d3869b","#8ec07c","#ebdbb2"] },
        { id: "nord", name: "Nord", dark: true, bg: "#2e3440", lowest: "#20242c", low: "#272c36", s1: "#3b4252", s2: "#434c5e", text: "#eceff4", muted: "#d8dee9", outline: "#616e88", primary: "#88c0d0", secondary: "#81a1c1", tertiary: "#b48ead", error: "#bf616a", term: ["#3b4252","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#88c0d0","#e5e9f0","#4c566a","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#8fbcbb","#eceff4"] },
        { id: "tokyo", name: "Tokyo Night", dark: true, bg: "#1a1b26", lowest: "#13131a", low: "#16161e", s1: "#24283b", s2: "#2f334d", text: "#c0caf5", muted: "#9aa5ce", outline: "#565f89", primary: "#7aa2f7", secondary: "#bb9af7", tertiary: "#7dcfff", error: "#f7768e", term: ["#15161e","#f7768e","#9ece6a","#e0af68","#7aa2f7","#bb9af7","#7dcfff","#a9b1d6","#414868","#f7768e","#9ece6a","#e0af68","#7aa2f7","#bb9af7","#7dcfff","#c0caf5"] },
        { id: "rosepine", name: "Rosé Pine", dark: true, bg: "#191724", lowest: "#12101a", low: "#16141f", s1: "#1f1d2e", s2: "#26233a", text: "#e0def4", muted: "#908caa", outline: "#6e6a86", primary: "#c4a7e7", secondary: "#9ccfd8", tertiary: "#ebbcba", error: "#eb6f92", term: ["#26233a","#eb6f92","#31748f","#f6c177","#9ccfd8","#c4a7e7","#ebbcba","#e0def4","#6e6a86","#eb6f92","#31748f","#f6c177","#9ccfd8","#c4a7e7","#ebbcba","#e0def4"] },
        { id: "everforest", name: "Everforest", dark: true, bg: "#2d353b", lowest: "#1e2326", low: "#272e33", s1: "#343f44", s2: "#3d484d", text: "#d3c6aa", muted: "#9da9a0", outline: "#7a8478", primary: "#a7c080", secondary: "#7fbbb3", tertiary: "#d699b6", error: "#e67e80", term: ["#343f44","#e67e80","#a7c080","#dbbc7f","#7fbbb3","#d699b6","#83c092","#d3c6aa","#475258","#e67e80","#a7c080","#dbbc7f","#7fbbb3","#d699b6","#83c092","#d3c6aa"] },
        { id: "kanagawa", name: "Kanagawa", dark: true, bg: "#1f1f28", lowest: "#16161d", low: "#1a1a22", s1: "#2a2a37", s2: "#363646", text: "#dcd7ba", muted: "#c8c093", outline: "#54546d", primary: "#7e9cd8", secondary: "#957fb8", tertiary: "#d27e99", error: "#e46876", term: ["#16161d","#c34043","#76946a","#c0a36e","#7e9cd8","#957fb8","#6a9589","#c8c093","#727169","#e82424","#98bb6c","#e6c384","#7fb4ca","#938aa9","#7aa89f","#dcd7ba"] },
        { id: "onedark", name: "One Dark", dark: true, bg: "#282c34", lowest: "#181a1f", low: "#21252b", s1: "#2c313a", s2: "#3e4451", text: "#abb2bf", muted: "#8b92a0", outline: "#5c6370", primary: "#61afef", secondary: "#c678dd", tertiary: "#56b6c2", error: "#e06c75", term: ["#3f4451","#e06c75","#98c379","#e5c07b","#61afef","#c678dd","#56b6c2","#abb2bf","#4f5666","#e06c75","#98c379","#e5c07b","#61afef","#c678dd","#56b6c2","#ffffff"] },
        { id: "solarized", name: "Solarized Dark", dark: true, bg: "#002b36", lowest: "#001e26", low: "#00252e", s1: "#073642", s2: "#0d4452", text: "#93a1a1", muted: "#839496", outline: "#586e75", primary: "#268bd2", secondary: "#2aa198", tertiary: "#d33682", error: "#dc322f", term: ["#073642","#dc322f","#859900","#b58900","#268bd2","#d33682","#2aa198","#eee8d5","#586e75","#cb4b16","#859900","#b58900","#268bd2","#6c71c4","#2aa198","#fdf6e3"] }
    ]

    function find(id: string): var { return list.find(p => p.id === id) ?? list[0] }

    // papeis do Material derivados das cores base (mesmos nomes que o scripts/material.py devolve)
    function toMaterial(p: var): var {
        const m = {
            primary: p.primary, onPrimary: p.bg, secondary: p.secondary, tertiary: p.tertiary,
            primaryContainer: mix(p.primary, p.bg, 0.72), secondaryContainer: mix(p.secondary, p.bg, 0.72), tertiaryContainer: mix(p.tertiary, p.bg, 0.72),
            onPrimaryContainer: p.text,
            background: p.bg, surface: p.bg,
            surfaceContainerLowest: p.lowest, surfaceContainerLow: p.low, surfaceContainer: p.s1, surfaceContainerHigh: p.s2,
            outline: p.outline, outlineVariant: mix(p.outline, p.bg, 0.55),
            onSurface: p.text, onSurfaceVariant: p.muted,
            error: p.error, onError: p.bg,
            _source: p.primary, _variant: "preset", _mode: p.dark ? "dark" : "light"
        }
        for (let i = 0; i < 16; i++) m["term" + i] = p.term[i]
        return m
    }
}
