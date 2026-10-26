// Boas-vindas do terminal montadas aqui (fastfetch). Settings.termFetch guarda so o que foi trocado; ligado, gera
// ~/.config/quickshell-mine/fastfetch.jsonc e ~/.config/fish/conf.d/mine-greeting.fish (define fish_greeting, que vence a funcao
// do usuario porque o conf.d carrega antes); desligado, apaga o conf.d. image: "" = a imagem atual do usuario (so leitura), "none" = sem imagem.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    // k, rotulo, icone, modulo do fastfetch, amostra para a maquete
    readonly property var catalog: [
        { k: "userhost", label: "Usuário@computador", icon: "account", mod: "title", sample: (Quickshell.env("USER") || "usuario") + "@" + (Quickshell.env("HOSTNAME") || "arch"), on: true },
        { k: "os", label: "Sistema", icon: "linux", mod: "os", sample: "Arch Linux x86_64", on: true },
        { k: "kernel", label: "Kernel", icon: "chip", mod: "kernel", sample: "6.18.57-2-lts", on: true },
        { k: "uptime", label: "Tempo ligado", icon: "timer", mod: "uptime", sample: "2 horas, 14 min", on: true },
        { k: "packages", label: "Pacotes", icon: "package", mod: "packages", sample: "1243 (pacman)", on: true },
        { k: "shell", label: "Shell", icon: "console", mod: "shell", sample: "fish 4.0", on: true },
        { k: "terminal", label: "Terminal", icon: "console", mod: "terminal", sample: "kitty", on: false },
        { k: "memory", label: "Memória", icon: "memory", mod: "memory", sample: "5,2 GiB / 31,2 GiB", on: true },
        { k: "disk", label: "Disco", icon: "disk", mod: "disk", sample: "210 GiB / 931 GiB", on: false },
        { k: "cpu", label: "CPU", icon: "chip", mod: "cpu", sample: "8 núcleos @ 4,6 GHz", on: false },
        { k: "gpu", label: "GPU", icon: "desktop", mod: "gpu", sample: "placa de vídeo", on: false },
        { k: "colors", label: "Cores", icon: "palette", mod: "colors", sample: "", on: true }
    ]
    function item(k: string): var { return catalog.find(c => c.k === k) ?? null }
    function raw(): var { return Settings.termFetch || ({}) }
    function get(k: string): var { const o = raw(); if (o[k] !== undefined) return o[k]; return k === "on" ? false : (k === "image" || k === "imgSize") ? "" : (item(k) ? item(k).on : undefined) }
    // mexer na imagem ou nos itens liga as boas-vindas do shell (senao a mudanca nao apareceria em lugar nenhum)
    function set(k: string, v): void { const o = Object.assign({}, raw()); if (v === undefined) delete o[k]; else o[k] = v; if (k !== "on") o.on = true; Settings.termFetch = o }
    readonly property bool on: get("on")
    property string err: ""
    property bool busy: false

    // ordem completa: a salva (so chaves conhecidas) e o que faltar no fim, na ordem do catalogo
    function order(): var {
        const saved = Settings.list(raw().order).filter(k => item(k))
        return saved.concat(catalog.map(c => c.k).filter(k => saved.indexOf(k) < 0))
    }
    function active(): var { return order().filter(k => get(k)) }
    function hidden(): var { return order().filter(k => !get(k)) }
    // poe k na posicao idx da lista visivel (e liga); idx < 0 ou k desligado = so reordena
    function place(k: string, idx: int): void {
        const vis = active().filter(x => x !== k), rest = hidden().filter(x => x !== k)
        vis.splice(Math.max(0, Math.min(idx, vis.length)), 0, k)
        const o = Object.assign({}, raw()); o.order = vis.concat(rest); o[k] = true; Settings.termFetch = o
    }
    function remove(k: string): void { set(k, false) }
    function move(k: string, d: int): void {
        const vis = active(), i = vis.indexOf(k)
        if (i >= 0 && i + d >= 0 && i + d < vis.length) place(k, i + d)
    }

    // imagem efetiva: "" = a do usuario se existir; "none" = nenhuma
    readonly property string profile: home + "/.config/fastfetch/profile.png"
    readonly property string image: {
        const v = get("image")
        if (v === "none") return ""
        if (v !== "") return v
        return Terminal.hasProfile ? profile : ""
    }
    // so o kitty (icat) e os terminais com chafa mostram imagem
    // largura da imagem em colunas do terminal (0 = automatico)
    readonly property int imgSize: { const v = parseInt(get("imgSize")); return v > 0 ? Math.max(10, Math.min(60, v)) : 0 }
    readonly property bool canImage: Terminal.id === "kitty" || Terminal.chafa

    function hex(c): string { return "#" + [c.r, c.g, c.b].map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("") }
    function sgr(c): string { return "38;2;" + [c.r, c.g, c.b].map(v => Math.round(v * 255)).join(";") }
    function json(): string {
        const mods = [{ type: "break" }]
        for (const k of active()) {
            const c = item(k)
            if (k === "userhost") mods.push({ type: "title" })
            else if (k === "colors") mods.push({ type: "break" }, { type: "colors", symbol: "circle" })
            else mods.push({ type: c.mod, key: c.label })
        }
        return JSON.stringify({ logo: null, display: { separator: "  ", key: { width: 14 }, color: { keys: sgr(Theme.accent), title: sgr(Theme.accent) } }, modules: mods }, null, 4) + "\n"
    }
    function q(s: string): string { return "'" + String(s).replace(/\\/g, "\\\\").replace(/'/g, "\\'") + "'" }
    function fish(): string {
        const cfg = '$HOME/.config/quickshell-mine/fastfetch.jsonc', img = image
        let t = "# Gerado pelo Quickshell (pagina Terminal). Apague este arquivo para voltar a sua mensagem de boas-vindas.\nfunction fish_greeting\n"
        t += "    command -v fastfetch &> /dev/null; or return\n"
        if (img !== "") {
            t += "    set -l img " + q(img) + "\n    if test -f \"$img\"\n"
            t += "        if test \"$TERM\" = xterm-kitty\n            fastfetch --config " + cfg + " --logo \"$img\" --logo-type kitty-icat" + (imgSize > 0 ? " --logo-width " + imgSize : "") + " --logo-padding-right 3\n            return\n        end\n"
            t += "        if command -v chafa &> /dev/null\n            fastfetch --config " + cfg + " --logo \"$img\" --logo-type chafa --logo-width " + (imgSize > 0 ? imgSize : 18) + " --logo-padding-right 3\n            return\n        end\n    end\n"
        }
        t += "    fastfetch --config " + cfg + " --logo none\nend\n"
        return t
    }

    // um processo por mudanca, com 400 ms de espera; valida com o proprio fastfetch (stderr vira o erro da pagina)
    readonly property string sig: Terminal.fastfetch ? on + "/" + (on ? json() + fish() : "") : ""
    onSigChanged: if (sig !== "") applyT.restart()
    Timer { id: applyT; interval: 400; onTriggered: root.apply() }
    Process {
        id: applyP
        stdout: StdioCollector { onStreamFinished: { root.busy = false; root.err = text.trim().split("\n").filter(l => l.trim() !== "").slice(0, 2).join(" ").replace(/\x1b\[[0-9;]*m/g, "").slice(0, 220) } }
    }
    function apply() {
        const d = home + "/.config/quickshell-mine", conf = home + "/.config/fish/conf.d/mine-greeting.fish"
        if (!on) {
            err = ""
            applyP.command = ["sh", "-c", '[ -e "$1" ] && rm -f "$1"; exit 0', "sh", conf]
        } else {
            busy = true
            applyP.command = ["sh", "-c", 'mkdir -p "$1" "$HOME/.config/fish/conf.d"; printf "%s" "$2" > "$1/fastfetch.jsonc"; printf "%s" "$3" > "$4"; ' +
                'fastfetch --config "$1/fastfetch.jsonc" --logo none 2>&1 >/dev/null', "sh", d, json(), fish(), conf]
        }
        applyP.running = false; applyP.running = true
    }
}
