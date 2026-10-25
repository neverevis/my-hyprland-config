// Pagina "Conta e Sobre" (kit Set*): cartao do perfil no topo (foto, nome, descricao) e, abaixo, nome de exibicao, nome da
// maquina e os dados do computador (distro, kernel, CPU, GPU, memoria, disco, shell, pacotes, atualizacoes, tempo ligado).
// Trocar o hostname precisa de root: aqui so se copia o comando para rodar num terminal.
import Quickshell
import Quickshell.Io
import QtQuick

SetPage {
    id: page
    title: "Conta e Sobre"
    subtitle: "Você, a máquina e este computador"
    property string host: ""
    property int uptimeS: 0
    property string pkgs: "…"
    property string qsVer: "…"
    property string gpuName: ""
    readonly property var inf: SysInfo.info
    Component.onCompleted: { SysInfo.use(); probe.running = true }
    Component.onDestruction: SysInfo.release()

    Process {
        id: probe
        command: ["sh", "-c", 'cut -d. -f1 /proc/uptime; pacman -Qq 2>/dev/null | wc -l; qs --version 2>/dev/null | head -1; lspci 2>/dev/null | grep -iE "vga|3d controller" | head -1 | sed "s/^[^:]*: //; s/^[^:]*: //"; cat /proc/sys/kernel/hostname']
        stdout: StdioCollector { onStreamFinished: {
            const l = text.split("\n")
            page.uptimeS = parseInt(l[0]) || 0
            page.pkgs = (l[1] || "?").trim()
            page.qsVer = (l[2] || "?").trim()
            page.gpuName = (l[3] || "").trim()
            page.host = (l[4] || "").trim()
        } }
    }
    Timer { interval: 60000; repeat: true; running: true; onTriggered: page.uptimeS += 60 }
    function upText(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d ? d + " d " : "") + (h ? h + " h " : "") + m + " min"
    }

    // ---- cartao do perfil ----
    preview: SetPreview {
        height: 128
        Avatar { id: av; x: SetK.xl; anchors.verticalCenter: parent.verticalCenter; size: 76; editable: true }
        Column {
            anchors { left: av.right; leftMargin: SetK.lg; right: parent.right; rightMargin: SetK.lg; verticalCenter: parent.verticalCenter }
            spacing: 2
            UiText { width: parent.width; elide: Text.ElideRight; text: Profile.name; color: Theme.text; font.family: Theme.fontTitle; font.pixelSize: 24; font.weight: Font.Bold }
            UiText { width: parent.width; elide: Text.ElideRight; visible: text !== ""; text: Profile.desc; color: Theme.muted; font.pixelSize: 13 }
            UiText { topPadding: 4; text: "Clique na foto para trocar (fica em ~/.face)"; color: Theme.muted; font.pixelSize: 11; opacity: 0.8 }
        }
    }

    SetSection {
        title: "Perfil"; icon: "account"
        subtitle: "Aparece nas configurações, no Início, no menu de energia e no bloqueio"
        SetRow {
            icon: "accountEdit"; label: "Nome de exibição"; description: "Vazio = " + Profile.user
            UiField { width: 220; text: Settings.displayName; placeholderText: Profile.user; onAccepted: Settings.displayName = text.trim(); onEditingFinished: Settings.displayName = text.trim() }
        }
        SetChoice {
            icon: "textBox"; label: "Descrição no cabeçalho"
            options: [["distro", "Distribuição", "linux"], ["uptime", "Tempo ligado", "timer"], ["text", "Texto livre", "pencil"]]
            value: Settings.profileDesc; onPicked: v => Settings.profileDesc = v
        }
        SetRow {
            visible: Settings.profileDesc === "text"
            sub: true; label: "Texto"
            UiField { width: 240; text: Settings.profileDescText; placeholderText: "Ex.: Arch + Hyprland"; onAccepted: Settings.profileDescText = text.trim(); onEditingFinished: Settings.profileDescText = text.trim() }
        }
    }

    SetSection {
        title: "Sobre este computador"; icon: "info"
        subtitle: (page.inf.distro || "Linux") + " · kernel " + (page.inf.kernel || "?")
        SetBlock {
            Row {
                spacing: SetK.lg
                ShapeIcon { shape: "cookie12"; icon: "arch"; size: 72; padding: 16; color: Theme.primaryContainer; iconColor: Theme.primaryContainerInk }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    UiText { text: page.inf.distro || "Linux"; color: Theme.text; font.pixelSize: 20; font.weight: Font.Bold }
                    UiText { text: "Kernel " + (page.inf.kernel || "?") + (page.inf.host ? "  ·  " + page.inf.host : ""); color: Theme.muted; font.pixelSize: 13 }
                    Row {
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "danger"]
                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                width: 22; height: 22; radius: 11
                                x: index * -5
                                color: modelData === "danger" ? Theme.danger : Theme.role(modelData)
                                border.width: 2; border.color: Theme.gl(Theme.card, 1)
                            }
                        }
                    }
                }
            }
        }
        SetRow { icon: "chip"; label: "Processador"; description: (page.inf.cpuModel || "?") + (page.inf.cores ? " · " + page.inf.cores + " threads" : "") + (SysInfo.temp !== null ? " · " + Math.round(SysInfo.temp) + " °C" : "") }
        SetRow { icon: "gpu"; label: "Placa de vídeo"; description: (SysInfo.d.gpu ? SysInfo.d.gpu.name : (page.gpuName || "?")) + (SysInfo.d.gpu ? " · " + SysInfo.bytes(SysInfo.d.gpu.memUsed) + " de " + SysInfo.bytes(SysInfo.d.gpu.memTotal) : "") }
        SetRow { icon: "memory"; label: "Memória"; description: (SysInfo.d.memTotal ? SysInfo.bytes(SysInfo.d.memUsed) + " de " + SysInfo.bytes(SysInfo.d.memTotal) : "?") + " · " + Math.round(SysInfo.mem * 100) + " % em uso" }
        SetRow { icon: "disk"; label: "Disco"; description: SysInfo.disks.length ? SysInfo.bytes(SysInfo.disks[0].used) + " de " + SysInfo.bytes(SysInfo.disks[0].total) + " · " + Math.round(SysInfo.disk * 100) + " % em uso" : "?" }
        SetRow { icon: "clock"; label: "Ligado há"; description: page.upText(page.uptimeS) + " · desde o último boot" }
        SetRow { icon: "package"; label: "Pacotes"; description: page.pkgs + " instalados (pacman)" }
        SetRow {
            icon: "download"; label: "Atualizações"
            description: SystemGuard.updates < 0 ? (SystemGuard.checking ? "Verificando…" : "Indisponível") : (SystemGuard.updates === 0 ? "Tudo em dia" : SystemGuard.updates + " pendentes")
            UiButton { text: SystemGuard.updates > 0 ? "Atualizar" : "Verificar"; kind: "ghost"; onClicked: SystemGuard.updates > 0 ? SystemGuard.runUpdate() : SystemGuard.checkUpdates() }
        }
        SetRow { icon: "tune"; label: "Shell"; description: "Quickshell “mine” · " + page.qsVer
            UiButton { icon: "refresh"; text: "Reiniciar"; kind: "ghost"; onClicked: Quickshell.execDetached(["shell-switch", "restart"]) } }
    }

    SetSection {
        title: "Nome da máquina"; icon: "desktop"
        subtitle: "Hoje: " + (page.host || "…") + "; trocar exige administrador, então o shell só copia o comando"
        SetRow {
            id: hr
            readonly property string cmd: "sudo hostnamectl set-hostname " + hf.text.trim()
            readonly property bool valid: /^[A-Za-z0-9][A-Za-z0-9-]{0,62}$/.test(hf.text.trim())
            icon: "desktop"; label: "Novo nome"
            description: hf.text.trim() === "" ? "Letras, números e hífen" : (valid ? cmd : "Nome inválido")
            UiField { id: hf; width: 200; placeholderText: "meu-pc" }
            UiButton { icon: "copy"; text: "Copiar comando"; kind: "accent"; enabled: hr.valid; onClicked: Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", hr.cmd]) }
        }
    }
}
