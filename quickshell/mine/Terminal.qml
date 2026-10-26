// Terminal padrao e visual dos terminais (kitty e foot). Uma fonte da verdade: Settings.defaultTerminal ("" = automatico:
// o primeiro instalado). term/termName/termIcon dizem qual e; runIn(cmd) monta o argv com a opcao de executar de cada terminal;
// prefix e o mesmo como texto de shell. Visual: Settings.termLook guarda so o que foi trocado e vira ~/.config/kitty/mine-look.conf
// e ~/.config/foot/mine-look.ini (incluidos no fim das configs do terminal). Nada roda em loop: um processo ao iniciar (detectar
// o que esta instalado) e um por mudanca.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    // run = argumentos que antecedem o comando; foot recebe o comando direto
    readonly property var all: [
        { id: "kitty", bin: "kitty", name: "kitty", dsk: "kitty.desktop", icon: "kitty", run: ["-e"] },
        { id: "foot", bin: "foot", name: "foot", dsk: "foot.desktop", icon: "foot", run: [] },
        { id: "ghostty", bin: "ghostty", name: "Ghostty", dsk: "com.mitchellh.ghostty.desktop", icon: "com.mitchellh.ghostty", run: ["-e"] },
        { id: "alacritty", bin: "alacritty", name: "Alacritty", dsk: "Alacritty.desktop", icon: "Alacritty", run: ["-e"] },
        { id: "wezterm", bin: "wezterm", name: "WezTerm", dsk: "org.wezfurlong.wezterm.desktop", icon: "org.wezfurlong.wezterm", run: ["start", "--"] },
        { id: "konsole", bin: "konsole", name: "Konsole", dsk: "org.kde.konsole.desktop", icon: "org.kde.konsole", run: ["-e"] },
        { id: "gnome-terminal", bin: "gnome-terminal", name: "Terminal do GNOME", dsk: "org.gnome.Terminal.desktop", icon: "org.gnome.Terminal", run: ["--"] },
        { id: "xfce4-terminal", bin: "xfce4-terminal", name: "Terminal do Xfce", dsk: "xfce4-terminal.desktop", icon: "org.xfce.terminal", run: ["-x"] },
        { id: "ptyxis", bin: "ptyxis", name: "Ptyxis", dsk: "org.gnome.Ptyxis.desktop", icon: "org.gnome.Ptyxis", run: ["--"] }
    ]
    function info(id: string): var { return all.find(t => t.id === id) ?? null }

    // ---- o que esta instalado (uma vez, ao iniciar) ----
    property var installed: []
    property bool loaded: false
    property bool starship: false
    Process {
        id: detect
        command: ["sh", "-c", "for b in " + root.all.map(t => t.bin).join(" ") + " starship; do command -v \"$b\" >/dev/null 2>&1 && echo \"$b\"; done"]
        stdout: StdioCollector { onStreamFinished: {
            const l = text.split("\n").map(s => s.trim()).filter(s => s !== "")
            root.starship = l.indexOf("starship") >= 0
            root.installed = root.all.filter(t => l.indexOf(t.bin) >= 0).map(t => t.id)
            root.loaded = true
        } }
    }
    Component.onCompleted: detect.running = true

    // ---- qual e o terminal ----
    // o campo antigo launcherTerminal continua valendo no automatico (so se nao for o padrao "kitty")
    readonly property string legacy: (Settings.launcherTerminal || "").trim()
    readonly property string autoId: {
        const pref = info(legacy) ? legacy : ""
        if (installed.length) return pref !== "" && installed.indexOf(pref) >= 0 ? pref : installed[0]
        return pref !== "" ? pref : "kitty"
    }
    readonly property var cur: {
        const w = Settings.defaultTerminal || ""
        if (w !== "" && info(w)) return info(w)
        if (w === "" && legacy !== "" && legacy !== "kitty" && !info(legacy)) return { id: "", bin: legacy, name: legacy, dsk: "", icon: "utilities-terminal", run: ["-e"] }
        return info(autoId) ?? info("kitty")
    }
    readonly property string id: cur.id
    readonly property string term: cur.bin
    readonly property string termName: cur.name
    readonly property string termIcon: cur.icon
    readonly property string autoName: (info(autoId) ?? { name: autoId }).name
    readonly property string prefix: [term].concat(cur.run).join(" ") + " "

    function flagsOf(bin: string): var {
        const t = all.find(x => x.bin === bin.split("/").pop())
        return t ? t.run : ["-e"]
    }
    // argv para rodar cmd (lista ou texto de shell) dentro do terminal; bin opcional (texto, pode ter argumentos)
    function runWith(bin: string, cmd): var {
        const w = (bin || term).trim().split(/\s+/)
        const c = typeof cmd === "string" ? ["sh", "-c", cmd] : Array.from(cmd)
        return w.concat(flagsOf(w[0]), c)
    }
    function runIn(cmd): var { return runWith(term, cmd) }
    function open(): void { Quickshell.execDetached([term]) }

    // ---- xdg-terminals.list: apps com Terminal=true usam o escolhido (so reescreve se mudou; guarda copia) ----
    readonly property string xdgWant: loaded && cur.dsk ? cur.dsk : ""
    onXdgWantChanged: if (xdgWant !== "") {
        xdgP.command = ["sh", "-c", 'f="$HOME/.config/xdg-terminals.list"; [ "$(cat "$f" 2>/dev/null)" = "$1" ] && exit 0; [ -f "$f" ] && cp "$f" "$f.bak-mine-$(date +%Y%m%d-%H%M%S)"; printf "%s\\n" "$1" > "$f"', "sh", xdgWant]
        xdgP.running = false; xdgP.running = true
    }
    Process { id: xdgP }

    // ---- visual ----
    readonly property bool lookOk: id === "kitty" || id === "foot"
    readonly property bool hasImage: id === "kitty"
    property var base: ({})         // valores atuais do terminal sem o que o shell trocou
    FileView { id: kf; path: root.home + "/.config/kitty/kitty.conf"; blockLoading: true; printErrors: false }
    FileView { id: ff; path: root.home + "/.config/foot/foot.ini"; blockLoading: true; printErrors: false }
    readonly property var layoutToKitty: ({ fill: "scaled", fit: "cscaled", center: "centered", tile: "tiled" })
    readonly property var layoutFromKitty: ({ scaled: "fill", cscaled: "fit", centered: "center", clamped: "center", tiled: "tile", "mirror-tiled": "tile" })
    function parseKitty(txt: string): var {
        const m = {}
        for (const ln of txt.split("\n")) {
            const x = /^\s*([a-z_0-9]+)\s+(.*?)\s*$/.exec(ln)
            if (x && !ln.trim().startsWith("#")) m[x[1]] = x[2]
        }
        return {
            image: m.background_image && m.background_image !== "none" ? m.background_image : "",
            layout: layoutFromKitty[m.background_image_layout ?? "tiled"] ?? "tile",
            tint: Math.round(parseFloat(m.background_tint ?? "0") * 100) || 0,
            opacity: Math.round(parseFloat(m.background_opacity ?? "1") * 100),
            pad: parseInt(m.window_padding_width ?? "0") || 0,
            font: m.font_family ?? "",
            fontSize: Math.round(parseFloat(m.font_size ?? "11")) || 11,
            cursor: m.cursor_shape ?? "block",
            blink: parseFloat(m.cursor_blink_interval ?? "0.5") !== 0
        }
    }
    function parseFoot(txt: string): var {
        const m = {}
        let sec = "main"
        for (const ln of txt.split("\n")) {
            const t = ln.trim()
            if (t === "" || t.startsWith("#")) continue
            const s = /^\[(.+)\]$/.exec(t)
            if (s) { sec = s[1]; continue }
            const x = /^([a-z0-9-]+)\s*=\s*(.*)$/.exec(t)
            if (x) m[sec + "." + x[1]] = x[2]
        }
        const font = m["main.font"] ?? "monospace:size=8"
        const sz = /size=([0-9.]+)/.exec(font)
        const pad = parseInt((m["main.pad"] ?? "0").split("x")[0]) || 0
        const al = parseFloat(m["colors-dark.alpha"] ?? m["colors.alpha"] ?? "1")
        return { image: "", layout: "tile", tint: 0, opacity: Math.round(al * 100), pad: pad, font: font.split(":")[0].trim(),
                 fontSize: sz ? Math.round(parseFloat(sz[1])) : 8, cursor: m["cursor.style"] ?? "block", blink: (m["cursor.blink"] ?? "no") === "yes" }
    }
    function refreshBase() {
        kf.reload(); ff.reload()
        base = id === "foot" ? parseFoot(ff.text() || "") : parseKitty(kf.text() || "")
    }
    onIdChanged: if (loaded) refreshBase()
    function look(k: string): var { const o = Settings.termLook || ({}); return o[k] !== undefined ? o[k] : base[k] }
    function isSet(k: string): bool { return (Settings.termLook || ({}))[k] !== undefined }
    function setLook(k: string, v): void {
        const o = Object.assign({}, Settings.termLook || ({}))
        if (v === undefined || v === null || (base[k] !== undefined && v === base[k])) delete o[k]; else o[k] = v   // igual ao do terminal = nao e troca
        Settings.termLook = o
    }
    // familia da fonte do terminal (para a previa do prompt)
    readonly property string fontFamily: look("font") || Theme.mono
    readonly property int fontPt: look("fontSize") || 12

    function kittyText(L): string {
        let t = "# Gerado pelo Quickshell (pagina Terminal). Nao edite a mao.\n"
        if (L.image !== undefined) t += "background_image " + (L.image === "" ? "none" : L.image) + "\n"
        if (L.layout !== undefined) t += "background_image_layout " + (layoutToKitty[L.layout] ?? "tiled") + "\n"
        if (L.tint !== undefined) t += "background_tint " + (L.tint / 100).toFixed(2) + "\n"
        if (L.opacity !== undefined) t += "background_opacity " + (L.opacity / 100).toFixed(2) + "\n"
        if (L.pad !== undefined) t += "window_padding_width " + L.pad + "\n"
        if (L.font !== undefined && L.font !== "") t += "font_family " + L.font + "\n"
        if (L.fontSize !== undefined) t += "font_size " + L.fontSize + ".0\n"
        if (L.cursor !== undefined) t += "cursor_shape " + L.cursor + "\n"
        if (L.blink !== undefined) t += "cursor_blink_interval " + (L.blink ? "0.5" : "0") + "\n"
        return t
    }
    function footText(L): string {
        let t = "# Gerado pelo Quickshell (pagina Terminal). Nao edite a mao.\n"
        if (L.font !== undefined || L.fontSize !== undefined) {
            const fam = (L.font !== undefined && L.font !== "" ? L.font : (parseFoot(ff.text() || "").font || "monospace"))
            const sz = L.fontSize !== undefined ? L.fontSize : parseFoot(ff.text() || "").fontSize
            t += "font=" + fam + ":size=" + sz + "\n"
        }
        if (L.pad !== undefined) t += "pad=" + L.pad + "x" + L.pad + "\n"
        if (L.opacity !== undefined) t += "[colors-dark]\nalpha=" + (L.opacity / 100).toFixed(2) + "\n[colors-light]\nalpha=" + (L.opacity / 100).toFixed(2) + "\n"
        if (L.cursor !== undefined || L.blink !== undefined) {
            t += "[cursor]\n"
            if (L.cursor !== undefined) t += "style=" + L.cursor + "\n"
            if (L.blink !== undefined) t += "blink=" + (L.blink ? "yes" : "no") + "\n"
        }
        return t
    }
    readonly property string lookSig: JSON.stringify(Settings.termLook || ({})) + "|" + installed.join()
    onLookSigChanged: genT.restart()
    Timer { id: genT; interval: 350; onTriggered: root.writeLook() }
    Process { id: genP }
    // so cria arquivo/include quando ha algo a gravar (ou o arquivo ja existe); recarrega o kitty so se o conteudo mudou
    function writeLook() {
        if (!loaded) return
        const L = Settings.termLook || ({})
        const empty = Object.keys(L).length === 0
        const sh = [
            'empty=$1; kt=$2; ft=$3; hk=$HOME/.config/kitty; hf=$HOME/.config/foot; ts=$(date +%Y%m%d-%H%M%S); ch=0',
            'if [ -d "$hk" ] && command -v kitty >/dev/null 2>&1; then',
            '  if ! { [ "$empty" = 1 ] && [ ! -f "$hk/mine-look.conf" ]; }; then',
            '    if [ "$(cat "$hk/mine-look.conf" 2>/dev/null)" != "$kt" ]; then printf "%s\\n" "$kt" > "$hk/mine-look.conf"; ch=1; fi',
            '    if ! grep -qxF "include mine-look.conf" "$hk/kitty.conf" 2>/dev/null; then',
            '      [ -f "$hk/kitty.conf" ] && cp "$hk/kitty.conf" "$hk/kitty.conf.bak-mine-$ts"',
            '      printf "\\n# quickshell mine: visual do terminal (pagina Terminal)\\ninclude mine-look.conf\\n" >> "$hk/kitty.conf"',
            '    fi',
            '  fi',
            'fi',
            'if [ -d "$hf" ] && command -v foot >/dev/null 2>&1; then',
            '  if ! { [ "$empty" = 1 ] && [ ! -f "$hf/mine-look.ini" ]; }; then',
            '    [ "$(cat "$hf/mine-look.ini" 2>/dev/null)" != "$ft" ] && printf "%s\\n" "$ft" > "$hf/mine-look.ini"',
            '    if ! grep -qF "mine-look.ini" "$hf/foot.ini" 2>/dev/null; then',
            '      [ -f "$hf/foot.ini" ] && cp "$hf/foot.ini" "$hf/foot.ini.bak-mine-$ts"',
            '      printf "\\n# quickshell mine: visual do terminal (pagina Terminal)\\n[main]\\ninclude=%s/mine-look.ini\\n" "$hf" >> "$hf/foot.ini"',
            '    fi',
            '  fi',
            'fi',
            '[ "$ch" = 1 ] && pkill -USR1 -x kitty; exit 0'
        ].join("\n")
        genP.command = ["sh", "-c", sh, "sh", empty ? "1" : "0", kittyText(L), footText(L)]
        genP.running = false; genP.running = true
    }
}
