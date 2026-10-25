// Aplicativos (Configuracoes > Aplicativos): lista dos instalados, busca para instalar (repositorio, AUR, Flatpak), remover,
// atualizar tudo num terminal e programas ao iniciar. Tudo so roda com a pagina aberta (use() / release()); o trabalho
// pesado fica em scripts/apps.py (so le). Instalar/remover usa pkexec (o agente polkit do shell pede a senha) e mostra a saida.
// Modo de teste: QS_APPS_DRYRUN=1 ou o arquivo ~/.cache/quickshell-mine/apps-dryrun trocam todo comando por um echo (e logam).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string script: Qt.resolvedUrl("scripts/apps.py").toString().replace("file://", "")
    readonly property bool dry: dryEnv || dryFile
    readonly property bool dryEnv: Quickshell.env("QS_APPS_DRYRUN") === "1"
    property bool dryFile: false

    // ---- instalados ----
    property var apps: []
    property string selected: ""        // linha aberta na lista de instalados
    property int pkgs: 0
    property bool loaded: false
    property bool loading: false
    property bool hasFlatpak: false
    property string helper: ""          // paru ou yay ("" = nenhum)
    property int users: 0               // paginas que estao usando (a lista so carrega com a pagina aberta)
    function use() { users++; if (!loaded && !loading) load() }
    function release() { users = Math.max(0, users - 1) }
    function load() {
        if (lister.running) return
        loading = true; lister.running = true
    }
    Process {
        id: lister
        command: ["python3", root.script, "list"]
        stdout: StdioCollector { onStreamFinished: {
            root.loading = false
            try {
                const d = JSON.parse(text)
                root.apps = d.apps || []; root.pkgs = d.pkgs || 0
                root.hasFlatpak = !!(d.tools && d.tools.flatpak); root.helper = (d.tools && d.tools.helper) || ""
                root.dryFile = !!d.dry
                root.loaded = true
            } catch (e) { console.warn("Apps: lista invalida", e) }
        } }
    }

    // ---- busca (repositorio, AUR, Flatpak); cada fonte chega quando ficar pronta ----
    property string query: ""
    property var repo: []
    property var aur: []
    property var flat: []
    property string aurErr: ""
    property bool sRepo: false
    property bool sAur: false
    property bool sFlat: false
    readonly property bool searching: sRepo || sAur || sFlat
    // lista unica para a ListView: repositorio, Flatpak, AUR (cada um com sua origem)
    property var results: []
    function rebuild() {
        results = repo.map(r => Object.assign({ src: "pacman", name: r.pkg }, r))
            .concat(flat.map(r => Object.assign({}, r, { src: "flatpak" })))
            .concat(aur.map(r => Object.assign({ src: "aur", name: r.pkg }, r)))
    }
    onRepoChanged: rebuild()
    onAurChanged: rebuild()
    onFlatChanged: rebuild()
    function search(q) {
        query = q.trim()
        repoT.stop(); aurT.stop()
        if (query.length < 2) { repo = []; aur = []; flat = []; aurErr = ""; sRepo = sAur = sFlat = false; return }
        repoT.restart(); aurT.restart()
    }
    // repositorio e Flatpak sao locais (rapidos); o AUR espera mais (rede)
    Timer { id: repoT; interval: 250; onTriggered: {
        root.sRepo = true; sr.running = false; sr.command = ["python3", root.script, "search-repo", root.query]; sr.running = true
        if (root.hasFlatpak) { root.sFlat = true; sf.running = false; sf.command = ["python3", root.script, "search-flatpak", root.query]; sf.running = true }
    } }
    Timer { id: aurT; interval: 600; onTriggered: { root.sAur = true; sa.running = false; sa.command = ["python3", root.script, "search-aur", root.query]; sa.running = true } }
    function parse(t) { try { return JSON.parse(t) } catch (e) { return [] } }
    Process { id: sr; stdout: StdioCollector { onStreamFinished: { root.repo = root.parse(text); root.sRepo = false } } }
    Process { id: sf; stdout: StdioCollector { onStreamFinished: { root.flat = root.parse(text); root.sFlat = false } } }
    Process { id: sa; stdout: StdioCollector { onStreamFinished: {
        const d = root.parse(text)
        root.aurErr = d && d.err ? d.err : ""
        root.aur = Array.isArray(d) ? d : []
        root.sAur = false
    } } }

    // ---- tarefa em andamento (instalar / remover): mostra a saida e o resultado ----
    property string jobTitle: ""
    property string jobState: ""        // "" | run | ok | err
    property string jobLog: ""
    property var jobAfter: null
    readonly property bool busy: jobState === "run"
    function validPkg(p) { return /^[A-Za-z0-9][A-Za-z0-9@._+-]*$/.test(p) }
    // roda argv; em modo de teste troca por um echo
    function runJob(title, argv, after) {
        if (busy) return
        console.log("apps: " + (dry ? "[TESTE] " : "") + title + " -> " + argv.join(" "))
        jobTitle = title; jobLog = ""; jobAfter = after || null; jobState = "run"
        job.command = dry ? ["sh", "-c", 'echo "[teste] rodaria: $*"; sleep 1.2', "sh"].concat(argv) : argv
        if (!dry && argv[0] === "pkexec") SysAct.withAgent(() => job.running = true)   // garante quem peca a senha
        else job.running = true
    }
    function closeJob() { if (!busy) { jobState = ""; jobLog = "" } }
    Process {
        id: job
        stdout: SplitParser { onRead: line => { const l = line.split("\r").pop().trim(); if (l !== "") root.jobLog = (root.jobLog + "\n" + l).split("\n").slice(-14).join("\n").trim() } }
        stderr: SplitParser { onRead: line => { const l = line.split("\r").pop().trim(); if (l !== "") root.jobLog = (root.jobLog + "\n" + l).split("\n").slice(-14).join("\n").trim() } }
        onExited: code => {
            root.jobState = code === 0 ? "ok" : "err"
            if (code !== 0 && root.jobLog === "") root.jobLog = "O comando terminou com erro (código " + code + ")."
            if (root.jobAfter) root.jobAfter(code)
            root.load()
            if (!root.dry) SystemGuard.checkUpdates()
        }
    }
    function uninstall(a) {
        if (a.src === "flatpak") { if (validPkg(a.flatpak)) runJob("Removendo " + a.name, ["flatpak", "uninstall", "-y", a.flatpak]); return }
        if (a.pkg === "" || !validPkg(a.pkg)) return
        runJob("Removendo " + a.name, ["pkexec", "pacman", "-Rns", "--noconfirm", a.pkg])
    }
    function install(r) {
        const id = r.pkg
        if (!validPkg(id)) return
        if (r.src === "pacman") runJob("Instalando " + r.name, ["pkexec", "pacman", "-S", "--needed", "--noconfirm", id])
        else if (r.src === "flatpak") runJob("Instalando " + r.name, ["flatpak", "install", "-y", "--user", "flathub", id])
        else if (r.src === "aur" && helper !== "") term("Instalando " + r.name + " (AUR)", helper + ' -S "$1"', [id])
    }

    // ---- terminal (AUR e atualizar tudo: interativo, voce revisa e digita a senha la) ----
    function term(title, shcmd, args) {
        const full = 'echo "' + title + '"; echo; ' + shcmd + '; st=$?; echo; if [ $st -eq 0 ]; then echo "Pronto."; else echo "Terminou com erro ($st)."; fi; read -rp "[Enter fecha] " _'
        const argv = ["sh", "-c", '$0 -e sh -c "$1" sh "$@"', AppCmds.cmd("terminal") || "kitty", full].concat(args || [])
        console.log("apps: " + (dry ? "[TESTE] terminal -> " : "terminal -> ") + full + " " + (args || []).join(" "))
        if (dry) return
        Quickshell.execDetached(argv)
    }
    function updateAll() {
        term("Atualizando o sistema", 'sudo pacman -Syu; h=$(command -v paru || command -v yay); [ -n "$h" ] && "$h" -Sua', [])
    }

    // ---- ao iniciar (XDG autostart do usuario) ----
    property var startup: []
    function loadStartup() { auto.running = false; auto.running = true }
    Process { id: auto; command: ["python3", root.script, "autostart"]
        stdout: StdioCollector { onStreamFinished: root.startup = root.parse(text) } }
    function setStartup(file, on) {
        if (dry) { console.log("apps: [TESTE] autostart " + file + " " + (on ? "on" : "off")); return }
        autoSet.command = ["python3", script, "autostart-set", file, on ? "on" : "off"]
        autoSet.running = false; autoSet.running = true
    }
    Process { id: autoSet; onExited: root.loadStartup() }

    // consultas por IPC (so no modo de teste: nunca pulam a confirmacao fora dele)
    IpcHandler {
        target: "apps"
        function open(id: string): void { root.selected = id }
        function dry(): string { return root.dry ? "sim" : "nao" }
        function find(q: string): void { root.search(q) }
        function counts(): string { return root.apps.length + " apps; busca: repo " + root.repo.length + ", flatpak " + root.flat.length + ", aur " + root.aur.length + (root.aurErr ? " (" + root.aurErr + ")" : "") }
        function run(kind: string, src: string, pkg: string): string {
            if (!root.dry) return "so no modo de teste"
            if (kind === "uninstall") root.uninstall({ src: src, pkg: pkg, flatpak: pkg, name: pkg })
            else if (kind === "install") root.install({ src: src, pkg: pkg, name: pkg })
            else if (kind === "update") root.updateAll()
            else return "?"
            return "ok"
        }
    }
}
