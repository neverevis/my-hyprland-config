// Acoes do sistema das paginas Som, Rede, Monitores e Data/hora (Configuracoes): modo de teste e tarefas com senha de administrador.
// Modo de teste: QS_SYS_DRYRUN=1 ou o arquivo ~/.cache/quickshell-mine/sys-dryrun trocam toda acao que mexe no sistema por um log
// ("sys: [TESTE] ..."); leituras continuam normais. Quem muda algo chama SysAct.real("o que") e so age se vier true.
// runJob(titulo, argv) roda um comando (pkexec: o agente polkit do shell pede a senha) e guarda o resultado para a pagina mostrar.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property bool dry: dryEnv || dryFile
    readonly property bool dryEnv: Quickshell.env("QS_SYS_DRYRUN") === "1"
    property bool dryFile: false
    // paginas chamam ao abrir (o arquivo pode ter sido criado depois do shell iniciar)
    function check() { if (!chk.running) chk.running = true }
    Process { id: chk; command: ["sh", "-c", 'test -e "$HOME/.cache/quickshell-mine/sys-dryrun"']; onExited: code => root.dryFile = code === 0 }
    Component.onCompleted: { check(); agentChk.running = true }

    // ---- agente de polkit: sem nenhum agente na sessao o pkexec falha ("textual authentication agent").
    // Se nenhum outro agente estiver rodando, o do shell (PolkitWindow) se liga sozinho, mesmo com Settings.polkitOn desligado.
    property bool otherAgent: true
    property bool agentChecked: false
    readonly property bool shellAgent: Settings.polkitOn || (agentChecked && !otherAgent)
    Process {
        id: agentChk
        command: ["pgrep", "-f", "polkit-gnome-authentication-agent|polkit-kde-authentication-agent|hyprpolkitagent|lxpolkit|polkit-mate|mate-polkit|xfce-polkit|polkit-efl"]
        onExited: code => { root.otherAgent = code === 0; root.agentChecked = true }
    }
    // roda fn quando houver quem pedir a senha: confere de novo os agentes e espera o do shell registrar (ate 3 s)
    property var pendingFns: []
    function withAgent(fn) {
        if (Settings.polkitRegistered) { fn(); return }
        pendingFns = pendingFns.concat([fn])
        agentChk.running = true
        agentWait.n = 0; agentWait.restart()
    }
    Timer {
        id: agentWait
        property int n: 0
        interval: 150; repeat: true
        onTriggered: {
            n++
            if (!(Settings.polkitRegistered || (root.agentChecked && root.otherAgent) || n >= 20)) return
            stop()
            const fns = root.pendingFns; root.pendingFns = []
            for (const f of fns) f()
        }
    }
    // registra a acao; true = pode executar de verdade
    function real(what) { console.log("sys: " + (dry ? "[TESTE] " : "") + what); return !dry }

    // ---- tarefa com senha (fuso, NTP) ----
    property string jobTitle: ""
    property string jobState: ""        // "" | run | ok | err
    property string jobLog: ""
    property string jobFriendly: ""     // frase em pt-BR do que falhou; o log cru fica numa linha menor
    property var retry: null            // refaz a ultima tarefa
    property var jobAfter: null
    readonly property bool busy: jobState === "run"
    function runJob(title, argv, after) {
        if (busy) return
        console.log("sys: " + (dry ? "[TESTE] " : "") + title + " -> " + argv.join(" "))
        jobTitle = title; jobLog = ""; jobFriendly = ""; jobAfter = after || null; jobState = "run"
        retry = () => runJob(title, argv, after)
        job.command = dry ? ["sh", "-c", 'echo "[teste] rodaria: $*"; sleep 1', "sh"].concat(argv) : argv
        if (!dry && argv[0] === "pkexec") withAgent(() => job.running = true)
        else job.running = true
    }
    function closeJob() { if (!busy) { jobState = ""; jobLog = ""; jobFriendly = ""; retry = null } }
    function retryJob() { if (!busy && retry) retry() }
    Process {
        id: job
        stdout: SplitParser { onRead: line => { const l = line.trim(); if (l !== "") root.jobLog = (root.jobLog + "\n" + l).split("\n").slice(-8).join("\n").trim() } }
        stderr: SplitParser { onRead: line => { const l = line.trim(); if (l !== "") root.jobLog = (root.jobLog + "\n" + l).split("\n").slice(-8).join("\n").trim() } }
        onExited: code => {
            root.jobState = code === 0 ? "ok" : "err"
            if (code !== 0) root.jobFriendly = code === 126 || code === 127 ? "A senha não foi confirmada, então nada mudou. Tente de novo." : "Não deu para concluir a mudança. Tente de novo."
            if (code !== 0 && root.jobLog === "") root.jobLog = "Código de saída " + code + "."
            if (root.jobAfter) root.jobAfter(code === 0)
            root.jobAfter = null
        }
    }

    // consultas por IPC (so no modo de teste)
    IpcHandler {
        target: "sys"
        function dry(): string { return root.dry ? "sim" : "nao" }
        function tz(zone: string): string {
            if (!root.dry) return "so no modo de teste"
            if (!/^[A-Za-z0-9_+\/-]+$/.test(zone)) return "?"
            root.runJob("Fuso horário", ["pkexec", "timedatectl", "set-timezone", zone]); return "ok"
        }
        function ntp(on: string): string {
            if (!root.dry) return "so no modo de teste"
            root.runJob("Sincronização automática", ["pkexec", "timedatectl", "set-ntp", on === "1" ? "true" : "false"]); return "ok"
        }
    }
}
