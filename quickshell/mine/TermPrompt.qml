// Prompt do terminal montado aqui (starship). Settings.termPrompt guarda so o que foi trocado; ligado, gera
// ~/.config/quickshell-mine/starship.toml e ~/.config/fish/conf.d/mine-prompt.fish (STARSHIP_CONFIG); desligado, apaga o conf.d
// e volta o ~/.config/starship.toml do usuario. segments() e a mesma descricao usada pela previa e pelo TOML, para nao divergirem.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property var defs: ({ on: false, user: false, host: false, dir: true, git: true, dur: true, time: false, env: true, err: true,
        dirStyle: "short", sym: "❯", color: "accent", two: false, gap: true })
    function get(k: string): var { const o = Settings.termPrompt || ({}); return o[k] !== undefined ? o[k] : defs[k] }
    function set(k: string, v): void { const o = Object.assign({}, Settings.termPrompt || ({})); o[k] = v; Settings.termPrompt = o }
    readonly property bool on: get("on")
    property string err: ""
    property bool busy: false

    function hex(c): string { return "#" + [c.r, c.g, c.b].map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("") }
    // cores: a escolhida em "Cor" e as outras duas papeis para git e ambiente; usuario, computador, tempo e hora ficam quietos
    readonly property var pal: {
        const all = { accent: hex(Theme.accent), secondary: hex(Theme.secondary), tertiary: hex(Theme.tertiary) }
        const main = get("color"), rest = ["accent", "secondary", "tertiary"].filter(x => x !== main)
        return { main: all[main] ?? all.accent, git: all[rest[0]], env: all[rest[1]], quiet: hex(Theme.muted), bad: hex(Theme.danger) }
    }
    readonly property string sampleUser: Quickshell.env("USER") || "usuario"
    readonly property string sampleHost: Quickshell.env("HOSTNAME") || "arch"
    readonly property var dirSample: ({ name: "shell", short: "~/projetos/shell", full: "~/projetos/shell" })

    // uma linha de prompt como lista de trechos {t, c, b}; failed = o ultimo comando falhou
    function segments(failed: bool): var {
        const L = [[]], p = pal, add = (t, c, b) => L[L.length - 1].push({ t: t, c: c, b: !!b })
        if (get("user")) add(sampleUser + (get("host") ? "" : " "), p.quiet, true)
        if (get("host")) add((get("user") ? "@" : "") + sampleHost + " ", p.quiet, true)
        if (get("dir")) add(dirSample[get("dirStyle")] + " ", p.main, true)
        if (get("git")) { add("\ue0a0 main ", p.git, true); add("✚1 ", p.git, false) }
        if (get("dur")) add("3s ", p.quiet, false)
        if (get("time")) add("14:32 ", p.quiet, false)
        if (get("env")) add("node v22.1 ", p.env, false)
        if (get("two")) L.push([])
        add(get("sym") + " ", failed && get("err") ? p.bad : p.main, true)
        return L
    }

    function toml(): string {
        const p = pal, q = s => '"' + s + '"'
        const sty = c => "bold " + c
        const mods = []
        let t = "# Gerado pelo Quickshell (pagina Terminal). Nao edite a mao.\n"
        t += "add_newline = " + (get("gap") ? "true" : "false") + "\n"
        if (get("user")) mods.push("$username")
        if (get("host")) mods.push("$hostname")
        if (get("dir")) mods.push("$directory")
        if (get("git")) mods.push("$git_branch", "$git_status")
        if (get("dur")) mods.push("$cmd_duration")
        if (get("time")) mods.push("$time")
        if (get("env")) mods.push("$python", "$nodejs", "$rust")
        if (get("two")) mods.push("$line_break")
        mods.push("$character")
        t += "format = " + q(mods.join("")) + "\n\n"
        if (get("user")) t += "[username]\nshow_always = true\nstyle_user = " + q(sty(p.quiet)) + "\nstyle_root = " + q(sty(p.bad)) + "\nformat = " + q("[$user]($style)" + (get("host") ? "" : " ")) + "\n\n"
        if (get("host")) t += "[hostname]\nssh_only = false\nstyle = " + q(sty(p.quiet)) + "\nformat = " + q("[" + (get("user") ? "@" : "") + "$hostname]($style) ") + "\n\n"
        if (get("dir")) {
            const n = get("dirStyle") === "name" ? 1 : get("dirStyle") === "short" ? 3 : 0
            t += "[directory]\ntruncation_length = " + n + "\ntruncate_to_repo = false\nhome_symbol = \"~\"\nstyle = " + q(sty(p.main)) + "\nformat = " + q("[$path]($style)[$read_only]($read_only_style) ") + "\n\n"
        }
        if (get("git")) {
            t += "[git_branch]\nstyle = " + q(sty(p.git)) + "\nformat = " + q("[$symbol$branch]($style) ") + "\n\n"
            t += "[git_status]\nstyle = " + q(p.git) + "\nformat = " + q("([$all_status$ahead_behind]($style) )") + "\n"
            t += 'staged = "✚${count}"\nmodified = "!${count}"\nuntracked = "?${count}"\ndeleted = "✘${count}"\nrenamed = "»${count}"\nconflicted = "=${count}"\nstashed = "≡"\nahead = "⇡${count}"\nbehind = "⇣${count}"\ndiverged = "⇕"\n\n'
        }
        if (get("dur")) t += "[cmd_duration]\nmin_time = 2000\nstyle = " + q(p.quiet) + "\nformat = " + q("[$duration]($style) ") + "\n\n"
        if (get("time")) t += "[time]\ndisabled = false\ntime_format = \"%H:%M\"\nstyle = " + q(p.quiet) + "\nformat = " + q("[$time]($style) ") + "\n\n"
        if (get("env")) {
            t += "[python]\nstyle = " + q(p.env) + "\nformat = " + q("[py $version]($style) ") + "\n\n"
            t += "[nodejs]\nstyle = " + q(p.env) + "\nformat = " + q("[node $version]($style) ") + "\n\n"
            t += "[rust]\nstyle = " + q(p.env) + "\nformat = " + q("[rs $version]($style) ") + "\n\n"
        }
        const ok = "[" + get("sym") + "](" + sty(p.main) + ")", bad = "[" + get("sym") + "](" + sty(get("err") ? p.bad : p.main) + ")"
        t += "[character]\nsuccess_symbol = " + q(ok) + "\nerror_symbol = " + q(bad) + "\nformat = " + q("$symbol ") + "\n"
        return t
    }

    // grava (ligado) e valida com o proprio starship; desligado, so tira o conf.d. Um processo por mudanca, com 400 ms de espera.
    readonly property string sig: Terminal.starship ? on + "/" + (on ? toml() : "") : ""
    onSigChanged: if (sig !== "") applyT.restart()
    Timer { id: applyT; interval: 400; onTriggered: root.apply() }
    Process {
        id: applyP
        stdout: StdioCollector { onStreamFinished: { root.busy = false; const t = text.trim(); root.err = t.split("\n").filter(l => /warn|error|erro/i.test(l)).slice(0, 2).join(" ").replace(/\x1b\[[0-9;]*m/g, "").slice(0, 220) } }
    }
    function apply() {
        const d = home + "/.config/quickshell-mine", conf = home + "/.config/fish/conf.d/mine-prompt.fish"
        if (!on) {
            err = ""
            applyP.command = ["sh", "-c", '[ -e "$1" ] && rm -f "$1"; exit 0', "sh", conf]
        } else {
            busy = true
            applyP.command = ["sh", "-c", 'mkdir -p "$1" "$HOME/.config/fish/conf.d"; cd "$HOME"; printf "%s" "$2" > "$1/starship.toml"; ' +
                'printf "%s\\n" "set -gx STARSHIP_CONFIG \\$HOME/.config/quickshell-mine/starship.toml" > "$3"; ' +
                'STARSHIP_CONFIG="$1/starship.toml" starship prompt 2>&1 >/dev/null', "sh", d, toml(), conf]
        }
        applyP.running = false; applyP.running = true
    }
}
