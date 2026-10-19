// Aparencia do sistema (pagina Sistema): temas de icones e de cursor instalados (com previa), fontes do sistema,
// instalar temas (pacman ou yay, num terminal: a senha e digitada por voce) e baixar fontes do Google Fonts.
// O trabalho fica em scripts/systheme.py; o cursor escolhido tambem vai para o Hyprland (HyprSync.cursorLua).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string script: Qt.resolvedUrl("scripts/systheme.py").toString().replace("file://", "")
    property var icons: []
    property var cursors: []
    property var cur: ({})
    property var installed: []          // pacotes do catalogo ja instalados
    property bool hasYay: false
    property string msg: ""
    property string busy: ""            // o que esta rodando agora (aplicar, baixar fonte, instalar)
    property bool loaded: false

    // catalogo para baixar: nome, pacote, se e do AUR e uma linha sobre o estilo
    readonly property var iconPkgs: [
        { name: "Papirus", pkg: "papirus-icon-theme", desc: "Colorido, enorme (claro e escuro)" },
        { name: "Breeze", pkg: "breeze-icons", desc: "O do KDE, limpo" },
        { name: "elementary", pkg: "elementary-icon-theme", desc: "Arredondado, estilo macOS" },
        { name: "Deepin", pkg: "deepin-icon-theme", desc: "Suave e brilhante" },
        { name: "Tela Circle", pkg: "tela-circle-icon-theme-git", aur: true, desc: "Ícones redondos, várias cores" },
        { name: "Colloid", pkg: "colloid-icon-theme-git", aur: true, desc: "Material, moderno" },
        { name: "Fluent", pkg: "fluent-icon-theme-git", aur: true, desc: "Estilo Windows 11" },
        { name: "Qogir", pkg: "qogir-icon-theme", aur: true, desc: "Plano e colorido" },
        { name: "WhiteSur", pkg: "whitesur-icon-theme", aur: true, desc: "Estilo macOS Big Sur" },
        { name: "Kora", pkg: "kora-icon-theme", aur: true, desc: "Gradientes suaves" }
    ]
    readonly property var cursorPkgs: [
        { name: "Capitaine", pkg: "capitaine-cursors", desc: "Inspirado no macOS" },
        { name: "Vanilla DMZ", pkg: "xcursor-vanilla-dmz", desc: "O clássico do X" },
        { name: "Bibata", pkg: "bibata-cursor-theme-bin", aur: true, desc: "Arredondado, com animação" },
        { name: "Phinger", pkg: "phinger-cursors", aur: true, desc: "Mão desenhada, moderno" },
        { name: "Catppuccin Mocha", pkg: "catppuccin-cursors-mocha", aur: true, desc: "Pastel, várias cores" },
        { name: "Rosé Pine", pkg: "rose-pine-hyprcursor", aur: true, desc: "Para o hyprcursor" }
    ]
    readonly property var fontSuggestions: [
        { family: "Google Sans Flex", tag: "Variável: largura e arredondamento" }, { family: "Roboto Flex", tag: "Variável: largura" },
        { family: "Inter", tag: "Interface" }, { family: "Rubik", tag: "Arredondada" }, { family: "Nunito", tag: "Arredondada" },
        { family: "Outfit", tag: "Geométrica" }, { family: "Manrope", tag: "Moderna" }, { family: "Figtree", tag: "Amigável" },
        { family: "Lexend", tag: "Leitura fácil" }, { family: "Plus Jakarta Sans", tag: "Moderna" }, { family: "Space Grotesk", tag: "Técnica" },
        { family: "DM Sans", tag: "Limpa" }, { family: "JetBrains Mono", tag: "Código" }, { family: "Fira Code", tag: "Código com ligaduras" },
        { family: "IBM Plex Mono", tag: "Código" }
    ]
    function hasFont(f) { return Qt.fontFamilies().indexOf(f) >= 0 }

    function load() {
        if (!lister.running) { lister.step = 0; lister.command = ["python3", script, "icons"]; lister.running = true }
        pk.running = false; pk.running = true
    }
    // lista icones, depois cursores, depois os valores atuais (um processo so, em sequencia)
    Process {
        id: lister
        property int step: 0
        stdout: StdioCollector { onStreamFinished: {
            let d = null
            try { d = JSON.parse(text) } catch (e) {}
            if (lister.step === 0) root.icons = d || []
            else if (lister.step === 1) root.cursors = d || []
            else { root.cur = d || {}; root.loaded = true }
        } }
        onExited: {
            if (step >= 2) return
            step++
            command = ["python3", root.script, step === 1 ? "cursors" : "current"]
            Qt.callLater(() => lister.running = true)
        }
    }
    Process {
        id: pk
        command: ["sh", "-c", "command -v yay >/dev/null && echo YAY; pacman -Q " + root.iconPkgs.concat(root.cursorPkgs).map(p => p.pkg).join(" ") + " 2>/dev/null | cut -d' ' -f1"]
        stdout: StdioCollector { onStreamFinished: { const l = text.split("\n").filter(x => x); root.hasYay = l.indexOf("YAY") >= 0; root.installed = l.filter(x => x !== "YAY") } }
    }

    // ---- aplicar ----
    function run(args, label, after) {
        if (act.running) return
        busy = label; msg = ""
        act.after = after || null
        act.command = ["python3", script].concat(args)
        act.running = true
    }
    Process {
        id: act
        property var after: null
        stdout: StdioCollector { onStreamFinished: {
            let r = null
            try { r = JSON.parse(text) } catch (e) {}
            root.msg = r && r.ok ? (r.files ? r.files + " arquivo(s) de fonte instalado(s)." : "") : (r && r.err ? r.err : "Não deu certo.")
            const f = act.after; act.after = null; root.busy = ""
            if (f) f(r)
        } }
    }
    function setIcons(name) {
        cur = Object.assign({}, cur, { icons: name })
        run(["apply-icons", name], "Aplicando ícones…", () => Icons.rebuild())
    }
    function setCursor(name, size) {
        cur = Object.assign({}, cur, { cursor: name, cursorSize: size })
        Settings.sysCursor = name; Settings.sysCursorSize = size
        run(["apply-cursor", name, String(size)], "Aplicando o cursor…")
    }
    function setFont(family, size) { cur = Object.assign({}, cur, { font: family, fontSize: size }); run(["apply-font", family, String(size)], "Aplicando a fonte…") }
    function setMono(family, size) { cur = Object.assign({}, cur, { mono: family, monoSize: size }); run(["apply-mono", family, String(size)], "Aplicando a fonte…") }
    function download(family, then) { run(["gfont", family], "Baixando " + family + "…", r => { if (then) then(r) }) }

    // ---- instalar num terminal (pacman pede a senha la; yay para o AUR) ----
    function install(p) {
        if (term.running) return
        const cmd = p.aur ? "yay -S --needed " + p.pkg : "sudo pacman -S --needed " + p.pkg
        busy = "Instalando " + p.name + " no terminal…"
        term.command = [Settings.launcherTerminal || "kitty", "-e", "sh", "-c", "echo 'Instalando " + p.name + " (" + p.pkg + ")'; echo; " + cmd + "; echo; echo 'Pronto. Enter fecha esta janela.'; read x"]
        term.running = true
    }
    Process { id: term; onExited: { root.busy = ""; root.load() } }
}
