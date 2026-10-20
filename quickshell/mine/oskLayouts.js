// Layouts do teclado na tela (OnScreenKeyboard.qml). Cada tecla tem: l (rotulo normal), s (rotulo com shift), c (codigo evdev,
// linux/input-event-codes.h), w (largura relativa), t (tipo), ic (icone). Tipos: (vazio) = tecla normal, shift, caps, mod (ctrl/alt/win/altgr).
// Teclas mortas (' ` ~ ^ ¨) saem como o layout do sistema as interpretar: o teclado so manda codigos de tecla.
.pragma library

function k(l, s, c, w) { return { l: l, s: s, c: c, w: w || 1, ic: "", t: "" } }
function f(l, c, w, ic) { return { l: l, s: l, c: c, w: w || 1, ic: ic || "", t: "" } }
function letters(str, codes) { return str.split("").map((ch, i) => k(ch, ch.toUpperCase(), codes[i])) }

var fnRow = [f("Esc", 1, 1.4)].concat([59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 87, 88].map((c, i) => f("F" + (i + 1), c)))
var qRow = [16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
var aRow = [30, 31, 32, 33, 34, 35, 36, 37, 38]
var zRow = [44, 45, 46, 47, 48, 49, 50]
var numRow = function (symbols) { return symbols.map((p, i) => k(p[0], p[1], 2 + i)) }   // codigos 2..11 = 1..0
var bottom = [
    { l: "Ctrl", s: "Ctrl", c: 29, w: 1.4, t: "mod", ic: "" }, { l: "Win", s: "Win", c: 125, w: 1.2, t: "mod", ic: "" }, { l: "Alt", s: "Alt", c: 56, w: 1.2, t: "mod", ic: "" },
    f("", 57, 6), { l: "AltGr", s: "AltGr", c: 100, w: 1.2, t: "mod", ic: "" }, { l: "Ctrl", s: "Ctrl", c: 97, w: 1.2, t: "mod", ic: "" },
    f("←", 105), f("↑", 103), f("↓", 108), f("→", 106)
]
var enter = f("", 28, 1.8, "keyboardReturn")
var back = f("", 14, 2, "backspace")
var tab = f("", 15, 1.5, "keyboardTab")
var shiftL = { l: "", s: "", c: 42, w: 2, t: "shift", ic: "shiftKey" }
var shiftR = { l: "", s: "", c: 54, w: 2.2, t: "shift", ic: "shiftKey" }
var caps = { l: "Caps", s: "Caps", c: 58, w: 1.9, t: "caps", ic: "caps" }

var abnt2 = [
    fnRow,
    [k("'", "\"", 41)].concat(numRow([["1", "!"], ["2", "@"], ["3", "#"], ["4", "$"], ["5", "%"], ["6", "¨"], ["7", "&"], ["8", "*"], ["9", "("], ["0", ")"]]),
        [k("-", "_", 12), k("=", "+", 13), back]),
    [tab].concat(letters("qwertyuiop", qRow), [k("´", "`", 26), k("[", "{", 27), enter]),
    [caps].concat(letters("asdfghjkl", aRow), [k("ç", "Ç", 39), k("~", "^", 40), k("]", "}", 43)]),
    [shiftL, k("\\", "|", 86)].concat(letters("zxcvbnm", zRow), [k(",", "<", 51), k(".", ">", 52), k(";", ":", 53), k("/", "?", 89), shiftR]),
    bottom
]

var us = [
    fnRow,
    [k("`", "~", 41)].concat(numRow([["1", "!"], ["2", "@"], ["3", "#"], ["4", "$"], ["5", "%"], ["6", "^"], ["7", "&"], ["8", "*"], ["9", "("], ["0", ")"]]),
        [k("-", "_", 12), k("=", "+", 13), back]),
    [tab].concat(letters("qwertyuiop", qRow), [k("[", "{", 26), k("]", "}", 27), k("\\", "|", 43, 1.5)]),
    [caps].concat(letters("asdfghjkl", aRow), [k(";", ":", 39), k("'", "\"", 40), enter]),
    [shiftL].concat(letters("zxcvbnm", zRow), [k(",", "<", 51), k(".", ">", 52), k("/", "?", 53), shiftR]),
    bottom
]

var layouts = { abnt2: { name: "ABNT2 (pt-BR)", rows: abnt2 }, us: { name: "US", rows: us } }
function get(id) { return (layouts[id] || layouts.abnt2).rows }
function names() { return Object.keys(layouts).map(i => [i, layouts[i].name]) }
