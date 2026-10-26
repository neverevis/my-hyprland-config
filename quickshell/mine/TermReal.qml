// Saida de verdade para a maquete do terminal: roda o fastfetch e o starship com a mesma configuracao que o terminal usaria,
// converte as cores ANSI (SGR) em RichText com a paleta real do terminal (kitty: themes/quickshell.conf + kitty.conf; foot: [colors]).
// Nada roda em loop: um processo de cada por mudanca (300 ms de espera) e so com a pagina visivel.
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: real
    width: 0; height: 0
    property int cols: 60
    readonly property bool alive: visible && (Window.window ? Window.window.visible : true)
    readonly property string home: Quickshell.env("HOME")
    readonly property string cache: home + "/.cache/quickshell-mine"

    // ---- paleta ----
    readonly property var xterm: ["#000000", "#cd0000", "#00cd00", "#cdcd00", "#0000ee", "#cd00cd", "#00cdcd", "#e5e5e5",
                                  "#7f7f7f", "#ff0000", "#00ff00", "#ffff00", "#5c5cff", "#ff00ff", "#00ffff", "#ffffff"]
    property var pal: ({ fg: "", bg: "", c: xterm })
    FileView { id: fTheme; path: real.home + "/.config/kitty/themes/quickshell.conf"; blockLoading: true; printErrors: false }
    FileView { id: fKitty; path: real.home + "/.config/kitty/kitty.conf"; blockLoading: true; printErrors: false }
    FileView { id: fFoot; path: real.home + "/.config/foot/foot.ini"; blockLoading: true; printErrors: false }
    function hex6(v: string): string { const m = /^#?([0-9a-fA-F]{6})/.exec(v || ""); return m ? "#" + m[1].toLowerCase() : "" }
    function loadPal() {
        const c = real.xterm.slice(); let fg = "", bg = ""
        if (Terminal.id === "foot") {
            fFoot.reload()
            let sec = ""
            for (const ln of (fFoot.text() || "").split("\n")) {
                const t = ln.trim()
                if (t === "" || t.startsWith("#")) continue
                const s = /^\[(.+)\]$/.exec(t)
                if (s) { sec = s[1]; continue }
                if (sec !== "colors" && sec !== "colors-dark") continue
                const x = /^([a-z0-9]+)\s*=\s*(\S+)/.exec(t)
                if (!x || !hex6(x[2])) continue
                if (x[1] === "foreground") fg = hex6(x[2])
                else if (x[1] === "background") bg = hex6(x[2])
                else { const r = /^(regular|bright)([0-7])$/.exec(x[1]); if (r) c[(r[1] === "bright" ? 8 : 0) + parseInt(r[2])] = hex6(x[2]) }
            }
        } else {
            fTheme.reload(); fKitty.reload()
            for (const txt of [fTheme.text() || "", fKitty.text() || ""]) for (const ln of txt.split("\n")) {
                const x = /^\s*(foreground|background|color\d+)\s+(\S+)/.exec(ln)
                if (!x || !hex6(x[2])) continue
                if (x[1] === "foreground") fg = hex6(x[2])
                else if (x[1] === "background") bg = hex6(x[2])
                else { const n = parseInt(x[1].slice(5)); if (n < 16) c[n] = hex6(x[2]) }
            }
        }
        pal = { fg: fg, bg: bg, c: c }
    }

    // ---- ANSI -> RichText (uma string; as linhas ficam separadas por \n) ----
    function esc(t: string): string { return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/ /g, "&nbsp;") }
    function rgb(h: string): var { return [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)] }
    function toHex(a): string { return "#" + a.map(v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("") }
    function mix(a: string, b: string, t: real): string { const x = rgb(a), y = rgb(b); return toHex([0, 1, 2].map(i => x[i] + (y[i] - x[i]) * t)) }
    function c256(n: int, P): string {
        if (n < 16) return P.c[n]
        if (n < 232) { const v = n - 16, f = x => x === 0 ? 0 : 55 + 40 * x; return toHex([f(Math.floor(v / 36)), f(Math.floor(v / 6) % 6), f(v % 6)]) }
        const g = 8 + 10 * (n - 232); return toHex([g, g, g])
    }
    function ansiHtml(src: string, P, defFg: string, defBg: string): string {
        const s = src.replace(/[\x01\x02\r]/g, "").replace(/\x1b\][^\x07\x1b]*(\x07|\x1b\\)/g, "")
        const re = /\x1b\[([0-9;:?]*)([A-Za-z])/g
        const st = { fg: "", bg: "", b: false, d: false, i: false, u: false, r: false }
        let out = "", last = 0, m
        function chunk(t) {
            if (!t) return
            let f = st.fg || defFg, b = st.bg
            if (st.r) { const tmp = f; f = b || defBg; b = tmp }
            if (st.d) f = mix(f, defBg, 0.5)
            const css = [(f !== defFg ? "color:" + f : ""), (b ? "background-color:" + b : ""), (st.b ? "font-weight:bold" : ""),
                         (st.i ? "font-style:italic" : ""), (st.u ? "text-decoration:underline" : "")].filter(x => x !== "").join(";")
            out += t.split("\n").map(p => p === "" ? "" : (css ? "<span style='" + css + "'>" + esc(p) + "</span>" : esc(p))).join("\n")
        }
        while ((m = re.exec(s)) !== null) {
            chunk(s.slice(last, m.index)); last = re.lastIndex
            if (m[2] !== "m") continue
            const p = m[1] === "" ? [0] : m[1].split(/[;:]/).map(v => parseInt(v) || 0)
            for (let k = 0; k < p.length; k++) {
                const v = p[k]
                if (v === 0) { st.fg = ""; st.bg = ""; st.b = st.d = st.i = st.u = st.r = false }
                else if (v === 1) st.b = true
                else if (v === 2) st.d = true
                else if (v === 3) st.i = true
                else if (v === 4) st.u = true
                else if (v === 7) st.r = true
                else if (v === 22) { st.b = false; st.d = false }
                else if (v === 23) st.i = false
                else if (v === 24) st.u = false
                else if (v === 27) st.r = false
                else if (v >= 30 && v <= 37) st.fg = P.c[v - 30]
                else if (v >= 90 && v <= 97) st.fg = P.c[v - 82]
                else if (v >= 40 && v <= 47) st.bg = P.c[v - 40]
                else if (v >= 100 && v <= 107) st.bg = P.c[v - 92]
                else if (v === 39) st.fg = ""
                else if (v === 49) st.bg = ""
                else if (v === 38 || v === 48) {
                    let col = ""
                    if (p[k + 1] === 5) { col = c256(p[k + 2] || 0, P); k += 2 }
                    else if (p[k + 1] === 2) { col = toHex([p[k + 2] || 0, p[k + 3] || 0, p[k + 4] || 0]); k += 4 }
                    if (v === 38) st.fg = col; else st.bg = col
                }
            }
        }
        chunk(s.slice(last))
        return out
    }

    // ---- saidas ----
    property string fetchHtml: ""
    property string promptHtml: ""    // todas as linhas menos a ultima
    property string promptLast: ""
    property bool settled: false
    readonly property bool ok: fetchHtml !== "" || promptHtml !== "" || promptLast !== ""
    readonly property string defFg: pal.fg !== "" ? pal.fg : TermFetch.hex(Theme.text)
    readonly property string defBg: pal.bg !== "" ? pal.bg : TermFetch.hex(Qt.darker(Theme.card, 1.5))
    readonly property bool wantFetch: Terminal.fastfetch
    readonly property bool wantPrompt: Terminal.starship

    // greeting: o que o terminal executaria (gerado ligado; o fish_greeting do usuario desligado)
    readonly property string fetchJson: TermFetch.on ? TermFetch.json() : ""
    readonly property string promptToml: TermPrompt.on ? TermPrompt.toml() : ""
    readonly property string sig: [Terminal.id, fetchJson, promptToml, cols, wantFetch, wantPrompt].join("|")
    property string doneSig: ""
    onSigChanged: if (alive) runT.restart()
    onAliveChanged: if (alive) { loadPal(); if (doneSig !== sig) runT.restart() }
    Component.onCompleted: loadPal()
    Timer { id: runT; interval: 300; onTriggered: real.run() }

    Process {
        id: pf
        stdout: StdioCollector { onStreamFinished: { real.fetchHtml = real.ansiHtml(text.replace(/\n+$/, ""), real.pal, real.defFg, real.defBg).replace(/\n/g, "<br>"); real.settled = true } }
    }
    Process {
        id: pp
        stdout: StdioCollector { onStreamFinished: {
            const h = real.ansiHtml(text.replace(/\n+$/, ""), real.pal, real.defFg, real.defBg), l = h.split("\n")
            real.promptLast = l.pop()
            real.promptHtml = l.join("<br>")
            real.settled = true
        } }
    }
    function run() {
        doneSig = sig
        loadPal()
        if (wantFetch) {
            pf.command = ["sh", "-c", 'if [ -n "$2" ]; then mkdir -p "$1"; printf "%s" "$2" > "$1/mock-fastfetch.jsonc"; fastfetch --config "$1/mock-fastfetch.jsonc" --logo none --pipe false 2>/dev/null; ' +
                'else fastfetch --config "$HOME/.config/fastfetch/config-ansi.jsonc" --key-padding-left 5 --logo none --pipe false 2>/dev/null; fi', "sh", cache, fetchJson]
            pf.running = false; pf.running = true
        } else fetchHtml = ""
        if (wantPrompt) {
            pp.command = ["sh", "-c", 'if [ -n "$2" ]; then mkdir -p "$1"; printf "%s" "$2" > "$1/mock-starship.toml"; export STARSHIP_CONFIG="$1/mock-starship.toml"; else unset STARSHIP_CONFIG; fi; ' +
                'cd "$HOME"; STARSHIP_SHELL= starship prompt --terminal-width "$3" 2>/dev/null', "sh", cache, promptToml, String(cols)]
            pp.running = false; pp.running = true
        } else { promptHtml = ""; promptLast = "" }
        if (!wantFetch && !wantPrompt) settled = true
    }
}
