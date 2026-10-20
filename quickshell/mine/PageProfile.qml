// Pagina "Perfil" (escondida: abre pelo cabecalho da barra lateral): nome, descricao do cabecalho, foto e nome da maquina.
// Trocar o hostname precisa de root: aqui so se copia o comando para rodar num terminal.
import Quickshell
import Quickshell.Io
import QtQuick

Column {
    id: page
    spacing: 14
    property string host: ""
    Process {
        running: true
        command: ["sh", "-c", "cat /proc/sys/kernel/hostname"]
        stdout: StdioCollector { onStreamFinished: page.host = text.trim() }
    }

    Card {
        icon: "account"
        title: "Você"
        subtitle: "O nome e a descrição aparecem no topo da barra lateral das configurações, no Início, no menu de energia e na tela de bloqueio."
        Row {
            spacing: 16
            Avatar { size: 72; editable: true }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                UiText { text: Profile.name; color: Theme.text; font.pixelSize: 18; font.weight: Font.Bold }
                UiText { text: Profile.desc; visible: text !== ""; color: Theme.muted; font.pixelSize: 12 }
                UiText { text: "Clique na foto para trocar (fica salva em ~/.face)"; color: Theme.muted; font.pixelSize: 12 }
            }
        }
        UiLabel { text: "Nome de exibição" }
        UiField { width: 360; text: Settings.displayName; placeholderText: "Vazio = " + Profile.user; onAccepted: Settings.displayName = text.trim(); onEditingFinished: Settings.displayName = text.trim() }
        UiLabel { text: "Descrição no cabeçalho" }
        UiSeg { options: [["distro", "Distribuição", "linux"], ["uptime", "Tempo ligado", "timer"], ["text", "Texto livre", "pencil"]]; value: Settings.profileDesc; onPicked: v => Settings.profileDesc = v }
        UiField { visible: Settings.profileDesc === "text"; width: 360; text: Settings.profileDescText; placeholderText: "Ex.: Arch + Hyprland"; onAccepted: Settings.profileDescText = text.trim(); onEditingFinished: Settings.profileDescText = text.trim() }
    }

    Card {
        id: hc
        icon: "desktop"
        title: "Nome da máquina"
        subtitle: "Hoje: " + (page.host || "…") + ". Mudar o hostname exige permissão de administrador, então o shell só copia o comando para você rodar num terminal."
        UiField { id: hf; width: 360; placeholderText: "Novo nome (letras, números e hífen)" }
        readonly property string cmd: "sudo hostnamectl set-hostname " + hf.text.trim()
        readonly property bool valid: /^[A-Za-z0-9][A-Za-z0-9-]{0,62}$/.test(hf.text.trim())
        UiText { visible: hf.text.trim() !== ""; text: hc.valid ? hc.cmd : "Nome inválido."; color: hc.valid ? Theme.muted : Theme.accent; font.pixelSize: 12; font.family: Theme.mono }
        UiButton { icon: "copy"; text: "Copiar o comando"; kind: "accent"; enabled: hc.valid
            onClicked: Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", hc.cmd]) }
    }
}
