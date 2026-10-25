// Aplicativos (Configuracoes > Aplicativos): lista dos instalados, busca para instalar (repositorio, AUR, Flatpak), remover,
// atualizar tudo num terminal e programas ao iniciar. Tudo so roda com a pagina aberta (use() / release()); o trabalho
// pesado fica em scripts/apps.py (so le). Instalar/remover usa pkexec (o agente polkit do shell pede a senha) e mostra a saida.
// A janela "Aplicativos" (AppsWindow.qml) usa tambem: pacotes (apps.py packages), orfaos e atualizacoes (apps.py updates), carregados 1x por abertura.
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
    property bool listErr: false
    property bool hasFlatpak: false
    property string helper: ""          // paru ou yay ("" = nenhum)
    property int users: 0               // paginas que estao usando (a lista so carrega com a pagina aberta)
    function use() { users++; if (!loaded && !loading) load() }
    function release() { users = Math.max(0, users - 1) }

    // ---- janela Aplicativos (so existe aberta; ao fechar descarta pacotes e atualizacoes) ----
    property bool windowOpen: false
    property string tab: "apps"         // apps | pkgs | install | updates
    onWindowOpenChanged: if (!windowOpen) { pkgList = []; pkgLoaded = false; pkgQuery = ""; pkgFilter = "all"; updLoaded = false; updRepo = []; updAur = []; selPkg = "" }
    function openWindow(t) { if (t) tab = t; windowOpen = true }

    // ---- pacotes (todos do banco local) ----
    property var pkgList: []
    property bool pkgLoaded: false
    property bool pkgLoading: false
    property bool pkgErr: false
    property string pkgQuery: ""
    property string pkgFilter: "all"    // all | explicit | aur | orphan
    property string pkgSort: "name"     // name | size
    property string selPkg: ""
    function loadPkgs() { if (pkgProc.running) return; pkgLoading = true; pkgErr = false; pkgProc.running = true }
    readonly property var orphans: pkgList.filter(p => p.orphan)
    readonly property var pkgShown: {
        const q = pkgQuery.toLowerCase(), f = pkgFilter
        let l = pkgList.filter(p => (f === "all" || (f === "explicit" && p.explicit) || (f === "aur" && p.foreign) || (f === "orphan" && p.orphan))
            && (q === "" || p.name.toLowerCase().includes(q) || p.desc.toLowerCase().includes(q)))
        if (pkgSort === "size") l = l.slice().sort((a, b) => b.size - a.size)
        return l
    }
    Process {
        id: pkgProc
        command: ["python3", root.script, "packages"]
        stdout: StdioCollector { onStreamFinished: {
            root.pkgLoading = false
            try { root.pkgList = JSON.parse(text).pkgs || []; root.pkgLoaded = true; root.pkgErr = false } catch (e) { console.warn("Apps: pacotes invalidos", e); root.pkgErr = true }
        } }
    }
    // remocao protegida: antes de rodar, confere (pacman -Rs --print, sem root) se sairia algo de que o shell precisa
    // ou se o pacman recusaria por dependencias; so entao chama o pkexec. Dados do shell: data/shell-deps.json (gerado do install.sh).
    property var rmNames: []
    property string rmTitle: ""
    function removePkg(p) { removeMany("Removendo " + p.name, [p.name]) }
    function removeOrphans() { removeMany("Removendo " + orphans.length + (orphans.length === 1 ? " órfão" : " órfãos"), orphans.map(p => p.name)) }
    function removeMany(title, names) {
        const n = names.filter(validPkg)
        if (busy || n.length === 0) return
        rmNames = n; rmTitle = title
        jobTitle = "Conferindo " + (n.length === 1 ? n[0] : n.length + " pacotes"); jobLog = ""; jobAfter = null; jobState = "run"
        retry = () => removeMany(title, names)
        chk.command = ["python3", root.script, "rmcheck"].concat(n); chk.running = false; chk.running = true
    }
    function refuse(msg) { jobTitle = rmTitle; jobLog = msg; jobState = "err"; jobFriendly = msg.indexOf("O shell precisa") === 0 ? "" : "Não deu para conferir a remoção. Tente de novo." }
    Process {
        id: chk
        stdout: StdioCollector { onStreamFinished: {
            let d = null
            try { d = JSON.parse(text) } catch (e) { root.refuse("Não consegui conferir as dependências."); return }
            if (d.required.length > 0) {
                root.refuse("O shell precisa disto para funcionar: " + d.required.map(r => r.pkg + " (" + r.why + ")").join("; ") + ". A remoção foi bloqueada.")
                return
            }
            if (d.err) { root.refuse("O pacman recusaria: " + d.err.slice(0, 500)); return }
            root.jobState = ""
            const nm = root.rmNames, tt = root.rmTitle
            root.runJob(tt, ["pkexec", "pacman", "-Rns", "--noconfirm"].concat(nm))
            root.retry = () => root.removeMany(tt, nm)
        } }
    }

    // ---- atualizacoes pendentes (checkupdates + AUR) ----
    property var updRepo: []
    property var updAur: []
    property bool updLoaded: false
    property bool updLoading: false
    property bool updErr: false
    property bool updTool: true
    function loadUpdates() { if (updProc.running) return; updLoading = true; updErr = false; updProc.running = true }
    Process {
        id: updProc
        command: ["python3", root.script, "updates"]
        stdout: StdioCollector { onStreamFinished: {
            root.updLoading = false
            try { const d = JSON.parse(text); root.updRepo = d.repo || []; root.updAur = d.aur || []; root.updTool = !!d.tool; root.updLoaded = true } catch (e) { console.warn("Apps: atualizacoes invalidas", e); root.updErr = true }
        } }
    }
    function load() {
        if (lister.running) return
        loading = true; listErr = false; lister.running = true
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
            } catch (e) { console.warn("Apps: lista invalida", e); root.listErr = true }
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
    property string jobFriendly: ""     // frase em pt-BR do que falhou (o log cru fica em linha menor)
    property var retry: null            // refaz a ultima tarefa (botao Tentar de novo)
    property var jobAfter: null
    readonly property bool busy: jobState === "run"
    function validPkg(p) { return /^[A-Za-z0-9][A-Za-z0-9@._+-]*$/.test(p) }
    // roda argv; em modo de teste troca por um echo
    function runJob(title, argv, after) {
        if (busy) return
        console.log("apps: " + (dry ? "[TESTE] " : "") + title + " -> " + argv.join(" "))
        jobTitle = title; jobLog = ""; jobFriendly = ""; jobAfter = after || null; jobState = "run"
        retry = () => runJob(title, argv, after)
        job.command = dry ? ["sh", "-c", 'echo "[teste] rodaria: $*"; sleep 1.2', "sh"].concat(argv) : argv
        if (!dry && argv[0] === "pkexec") SysAct.withAgent(() => job.running = true)   // garante quem peca a senha
        else job.running = true
    }
    function closeJob() { if (!busy) { jobState = ""; jobLog = ""; jobFriendly = ""; retry = null } }
    function retryJob() { if (!busy && retry) retry() }
    Process {
        id: job
        stdout: SplitParser { onRead: line => { const l = line.split("\r").pop().trim(); if (l !== "") root.jobLog = (root.jobLog + "\n" + l).split("\n").slice(-14).join("\n").trim() } }
        stderr: SplitParser { onRead: line => { const l = line.split("\r").pop().trim(); if (l !== "") root.jobLog = (root.jobLog + "\n" + l).split("\n").slice(-14).join("\n").trim() } }
        onExited: code => {
            root.jobState = code === 0 ? "ok" : "err"
            if (code !== 0) root.jobFriendly = job.command[0] === "pkexec" && (code === 126 || code === 127) ? "A senha não foi confirmada, nada foi mudado. Tente de novo." : "Não deu para concluir. Tente de novo ou veja o detalhe abaixo."
            if (code !== 0 && root.jobLog === "") root.jobLog = "Código de saída " + code + "."
            if (root.jobAfter) root.jobAfter(code)
            root.load()
            if (root.pkgLoaded) root.loadPkgs()
            if (!root.dry) SystemGuard.checkUpdates()
        }
    }
    function uninstall(a) {
        if (a.src === "flatpak") { if (validPkg(a.flatpak)) runJob("Removendo " + a.name, ["flatpak", "uninstall", "-y", a.flatpak]); return }
        if (a.pkg === "" || !validPkg(a.pkg)) return
        removeMany("Removendo " + a.name, [a.pkg])
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
        stdout: StdioCollector { onStreamFinished: { root.startupLoaded = true; root.startup = root.parse(text) } } }
    property bool startupLoaded: false
    function setStartup(file, on) {
        if (dry) { console.log("apps: [TESTE] autostart " + file + " " + (on ? "on" : "off")); return }
        autoSet.command = ["python3", script, "autostart-set", file, on ? "on" : "off"]
        autoSet.running = false; autoSet.running = true
    }
    property bool startupErr: false
    Process { id: autoSet; onExited: code => { root.startupErr = code !== 0; root.loadStartup() } }

    // consultas por IPC (so no modo de teste: nunca pulam a confirmacao fora dele)
    IpcHandler {
        target: "apps"
        function open(t: string): void { root.openWindow(t) }          // abre a janela (apps | pkgs | install | updates)
        function window(): void { root.windowOpen = !root.windowOpen }  // alterna
        function close(): void { root.windowOpen = false }
        function select(id: string): void { root.selected = id }
        function findpkg(q: string): string {                           // teste: nomes filtrados na aba Pacotes
            root.pkgQuery = q
            if (!root.pkgLoaded) { root.loadPkgs(); return "carregando" }
            return root.pkgShown.length + ": " + root.pkgShown.slice(0, 30).map(p => p.name).join(" ")
        }
        function dry(): string { return root.dry ? "sim" : "nao" }
        function find(q: string): void { root.search(q) }
        function counts(): string { return root.apps.length + " apps; busca: repo " + root.repo.length + ", flatpak " + root.flat.length + ", aur " + root.aur.length + (root.aurErr ? " (" + root.aurErr + ")" : "") }
        function run(kind: string, src: string, pkg: string): string {
            if (!root.dry) return "so no modo de teste"
            if (kind === "uninstall") root.uninstall({ src: src, pkg: pkg, flatpak: pkg, name: pkg })
            else if (kind === "install") root.install({ src: src, pkg: pkg, name: pkg })
            else if (kind === "rmpkg") root.removePkg({ name: pkg })
            else if (kind === "rmorphans") root.removeOrphans()
            else if (kind === "update") root.updateAll()
            else return "?"
            return "ok"
        }
    }
}
