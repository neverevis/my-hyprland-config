// Pagina "Sobre": a distro, o kernel, a paleta e os numeros da maquina (CPU, GPU, memoria, disco, shell, pacotes, atualizacoes, tempo ligado).
import Quickshell
import Quickshell.Io
import QtQuick

Column {
    id: page
    spacing: 14
    property int uptimeS: 0
    property string pkgs: "…"
    property string qsVer: "…"
    property string gpuName: ""
    readonly property var inf: SysInfo.info
    Component.onCompleted: { SysInfo.use(); probe.running = true }
    Component.onDestruction: SysInfo.release()

    Process {
        id: probe
        command: ["sh", "-c", 'cut -d. -f1 /proc/uptime; pacman -Qq 2>/dev/null | wc -l; qs --version 2>/dev/null | head -1; lspci 2>/dev/null | grep -iE "vga|3d controller" | head -1 | sed "s/^[^:]*: //; s/^[^:]*: //"']
        stdout: StdioCollector { onStreamFinished: {
            const l = text.split("\n")
            page.uptimeS = parseInt(l[0]) || 0
            page.pkgs = (l[1] || "?").trim()
            page.qsVer = (l[2] || "?").trim()
            page.gpuName = (l[3] || "").trim()
        } }
    }
    Timer { interval: 60000; repeat: true; running: true; onTriggered: page.uptimeS += 60 }
    function upText(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d ? d + " d " : "") + (h ? h + " h " : "") + m + " min"
    }

    Card {
        icon: "info"
        title: "Sobre este computador"
        subtitle: "A distribuição, o kernel e as cores do tema."
        Row {
            width: parent.width
            spacing: 18
            ShapeIcon { shape: "cookie12"; icon: "arch"; size: 96; padding: 22; color: Theme.primaryContainer; iconColor: Theme.primaryContainerInk }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                UiText { text: page.inf.distro || "Linux"; color: Theme.text; font.pixelSize: 22; font.weight: Font.Bold }
                UiText { text: "Kernel " + (page.inf.kernel || "?") + (page.inf.host ? "  ·  " + page.inf.host : ""); color: Theme.muted; font.pixelSize: 13 }
                Row {
                    topPadding: 4
                    Repeater {
                        model: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "danger"]
                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            width: 26; height: 26; radius: 13
                            x: index * -6
                            color: modelData === "danger" ? Theme.danger : Theme.role(modelData)
                            border.width: 2; border.color: Theme.gl(Theme.card, 1)
                        }
                    }
                }
            }
        }
    }

    Flow {
        id: grid
        width: parent.width
        spacing: 10
        readonly property real tw: (width - spacing) / 2
        Repeater {
            model: [
                { icon: "chip", label: "Processador", value: page.inf.cpuModel || "?", sub: (page.inf.cores ? page.inf.cores + " threads" : "") + (SysInfo.temp !== null ? "  ·  " + Math.round(SysInfo.temp) + " °C" : "") },
                { icon: "gpu", label: "Placa de vídeo", value: SysInfo.d.gpu ? SysInfo.d.gpu.name : (page.gpuName || "?"), sub: SysInfo.d.gpu ? SysInfo.bytes(SysInfo.d.gpu.memUsed) + " de " + SysInfo.bytes(SysInfo.d.gpu.memTotal) : "" },
                { icon: "memory", label: "Memória", value: SysInfo.d.memTotal ? SysInfo.bytes(SysInfo.d.memUsed) + " de " + SysInfo.bytes(SysInfo.d.memTotal) : "?", sub: Math.round(SysInfo.mem * 100) + " % em uso" },
                { icon: "disk", label: "Disco", value: SysInfo.disks.length ? SysInfo.bytes(SysInfo.disks[0].used) + " de " + SysInfo.bytes(SysInfo.disks[0].total) : "?", sub: SysInfo.disks.length ? Math.round(SysInfo.disk * 100) + " % em uso" : "" },
                { icon: "tune", label: "Shell", value: "Quickshell “mine”", sub: page.qsVer },
                { icon: "package", label: "Pacotes", value: page.pkgs, sub: "instalados (pacman)" },
                { icon: "download", label: "Atualizações", value: SystemGuard.updates < 0 ? (SystemGuard.checking ? "Verificando…" : "Indisponível") : (SystemGuard.updates === 0 ? "Tudo em dia" : SystemGuard.updates + " pendentes"), sub: SystemGuard.updates > 0 ? "Clique para atualizar no terminal" : "Clique para verificar de novo", act: true },
                { icon: "clock", label: "Ligado há", value: page.upText(page.uptimeS), sub: "desde o último boot" }
            ]
            delegate: Rectangle {
                id: tile
                required property var modelData
                width: grid.tw; height: 76; radius: 14
                color: tm.containsMouse && modelData.act ? Theme.cardHi : Theme.glc(Theme.card, 1)
                border.width: 1; border.color: Theme.border
                Rectangle {
                    id: ti
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    width: 42; height: 42; radius: 14; color: Theme.tint(0.16)
                    UiIcon { anchors.centerIn: parent; name: tile.modelData.icon; size: 20; color: Theme.accent }
                }
                Column {
                    anchors { left: ti.right; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    UiText { text: tile.modelData.label; color: Theme.muted; font.pixelSize: 11 }
                    UiText { width: parent.width; elide: Text.ElideRight; text: tile.modelData.value; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                    UiText { width: parent.width; elide: Text.ElideRight; visible: text !== ""; text: tile.modelData.sub; color: Theme.muted; font.pixelSize: 11 }
                }
                MouseArea {
                    id: tm; anchors.fill: parent; hoverEnabled: true
                    enabled: !!tile.modelData.act; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: SystemGuard.updates > 0 ? SystemGuard.runUpdate() : SystemGuard.checkUpdates()
                }
            }
        }
    }

    Card {
        icon: "refresh"
        title: "Shell"
        subtitle: "Recarrega o shell inteiro (útil depois de editar arquivos à mão)."
        UiButton { icon: "refresh"; text: "Reiniciar o shell"; kind: "ghost"; onClicked: Quickshell.execDetached(["shell-switch", "restart"]) }
    }
}
