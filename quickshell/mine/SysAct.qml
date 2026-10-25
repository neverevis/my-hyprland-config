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
    Component.onCompleted: check()
    // registra a acao; true = pode executar de verdade
    function real(what) { console.log("sys: " + (dry ? "[TESTE] " : "") + what); return !dry }

    // ---- tarefa com senha (fuso, NTP) ----
    property string jobTitle: ""
    property string jobState: ""        // "" | run | ok | err
    property string jobLog: ""
    property var jobAfter: null
    readonly property bool busy: jobState === "run"
    function runJob(title, argv, after) {
        if (busy) return
        console.log("sys: " + (dry ? "[TESTE] " : "") + title + " -> " + argv.join(" "))
        jobTitle = title; jobLog = ""; jobAfter = after || null; jobState = "run"
        job.command = dry ? ["sh", "-c", 'echo "[teste] rodaria: $*"; sleep 1', "sh"].concat(argv) : argv
        job.running = true
    }
    function closeJob() { if (!busy) { jobState = ""; jobLog = "" } }
    Process {
        id: job
        stdout: SplitParser { onRead: line => { const l = line.trim(); if (l !== "") root.jobLog = (root.jobLog + "\n" + l).split("\n").slice(-8).join("\n").trim() } }
        stderr: SplitParser { onRead: line => { const l = line.trim(); if (l !== "") root.jobLog = (root.jobLog + "\n" + l).split("\n").slice(-8).join("\n").trim() } }
        onExited: code => {
            root.jobState = code === 0 ? "ok" : "err"
            if (code !== 0 && root.jobLog === "") root.jobLog = code === 126 || code === 127 ? "Cancelado ou sem permissão." : "O comando saiu com erro " + code + "."
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
