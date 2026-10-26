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

    // ---- pecas e ordem (termPrompt.order guarda a ordem; o que faltar entra no fim, na ordem padrao) ----
    readonly property var pieces: [
        { k: "user", label: "Usuário", icon: "account" }, { k: "host", label: "Computador", icon: "desktop" }, { k: "dir", label: "Pasta", icon: "folder" },
        { k: "git", label: "Git", icon: "branch" }, { k: "dur", label: "Tempo do comando", icon: "timer" }, { k: "time", label: "Hora", icon: "clock" },
        { k: "env", label: "Ambiente", icon: "package" }
    ]
    function piece(k: string): var { return pieces.find(c => c.k === k) ?? null }
    function order(): var {
        const saved = Settings.list((Settings.termPrompt || ({})).order).filter(k => piece(k))
        return saved.concat(pieces.map(c => c.k).filter(k => saved.indexOf(k) < 0))
    }
    function active(): var { return order().filter(k => get(k)) }
    function hidden(): var { return order().filter(k => !get(k)) }
    function place(k: string, idx: int): void {
        const vis = active().filter(x => x !== k), rest = hidden().filter(x => x !== k)
        vis.splice(Math.max(0, Math.min(idx, vis.length)), 0, k)
        const o = Object.assign({}, Settings.termPrompt || ({})); o.order = vis.concat(rest); o[k] = true; Settings.termPrompt = o
    }
    function remove(k: string): void { set(k, false) }
    function move(k: string, d: int): void {
        const vis = active(), i = vis.indexOf(k)
        if (i >= 0 && i + d >= 0 && i + d < vis.length) place(k, i + d)
    }
    // usuario seguido do computador viram usuario@computador
    function joined(): bool { const v = active(), i = v.indexOf("user"); return i >= 0 && v[i + 1] === "host" }

    // trechos {t, c, b} de uma peca
    function pieceSegs(k: string): var {
        const p = pal, j = joined()
        switch (k) {
        case "user": return [{ t: sampleUser + (j ? "" : " "), c: p.quiet, b: true }]
        case "host": return [{ t: (j ? "@" : "") + sampleHost + " ", c: p.quiet, b: true }]
        case "dir": return [{ t: dirSample[get("dirStyle")] + " ", c: p.main, b: true }]
        case "git": return [{ t: "\ue0a0 main ", c: p.git, b: true }, { t: "✚1 ", c: p.git, b: false }]
        case "dur": return [{ t: "3s ", c: p.quiet, b: false }]
        case "time": return [{ t: "14:32 ", c: p.quiet, b: false }]
        case "env": return [{ t: "node v22.1 ", c: p.env, b: false }]
        }
        return []
    }
    function symSeg(failed: bool): var { return { t: get("sym") + " ", c: failed && get("err") ? pal.bad : pal.main, b: true } }

    // uma linha de prompt como lista de trechos {t, c, b}; failed = o ultimo comando falhou
    function segments(failed: bool): var {
        const L = [[]]
        for (const k of active()) for (const s of pieceSegs(k)) L[L.length - 1].push(s)
        if (get("two")) L.push([])
        L[L.length - 1].push(symSeg(failed))
        return L
    }

    function toml(): string {
        const p = pal, q = s => '"' + s.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'
        const sty = c => "bold " + c
        const mods = []
        let t = "# Gerado pelo Quickshell (pagina Terminal). Nao edite a mao.\n"
        t += "add_newline = " + (get("gap") ? "true" : "false") + "\n"
        const mm = { user: ["$username"], host: ["$hostname"], dir: ["$directory"], git: ["$git_branch", "$git_status"], dur: ["$cmd_duration"], time: ["$time"], env: ["$python", "$nodejs", "$rust"] }
        for (const k of active()) for (const m of mm[k]) mods.push(m)
        if (get("two")) mods.push("$line_break")
        mods.push("$character")
        t += "format = " + q(mods.join("")) + "\n\n"
        if (get("user")) t += "[username]\nshow_always = true\nstyle_user = " + q(sty(p.quiet)) + "\nstyle_root = " + q(sty(p.bad)) + "\nformat = " + q("[$user]($style)" + (joined() ? "" : " ")) + "\n\n"
        if (get("host")) t += "[hostname]\nssh_only = false\nstyle = " + q(sty(p.quiet)) + "\nformat = " + q("[" + (joined() ? "@" : "") + "$hostname]($style) ") + "\n\n"
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
        // no formato do starship $ [ ] ( ) \ sao especiais: escapa com \ (o q() depois dobra a barra para o TOML)
        const s = get("sym").replace(/[\\$\[\]()]/g, c => "\\" + c)
        const ok = "[" + s + "](" + sty(p.main) + ")", bad = "[" + s + "](" + sty(get("err") ? p.bad : p.main) + ")"
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
