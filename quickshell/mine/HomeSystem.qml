// Aba "Sistema": graficos de CPU, memoria, GPU e rede; informacoes do sistema e uso dos discos.
import QtQuick

Item {
    id: pg
    property var home
    readonly property var s: home.sys
    readonly property var g: s.gpu ?? null

    component Stat: HomeCard {
        id: sc
        property string value
        property string detail
        property var values: []
        property var values2: []
        property real max: 100
        property color color2: Theme.muted
        UiText { anchors { right: parent.right; top: parent.top; topMargin: -34 } text: sc.value; color: Theme.text; font.pixelSize: 18; font.weight: Font.Bold }
        MiniGraph {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: dt.top; bottomMargin: 6 }
            values: sc.values; values2: sc.values2; max: sc.max; color2: sc.color2
        }
        UiText { id: dt; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } text: sc.detail; color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight }
    }

    Grid {
        id: grid
        width: parent.width
        columns: 2; spacing: 10
        readonly property real cw: (width - 10) / 2
        Stat {
            width: grid.cw; height: 128
            title: "CPU"; icon: "chip"
            value: Math.round(pg.s.cpu ?? 0) + "%"
            values: pg.home.cpuH
            detail: (pg.s.cpuTemp ? pg.s.cpuTemp + " °C · " : "") + (pg.home.st.cores ?? "?") + " núcleos · carga " + (pg.s.load ? pg.s.load[0] : "–")
        }
        Stat {
            width: grid.cw; height: 128
            title: "Memória"; icon: "memory"
            value: pg.s.memTotal ? Math.round(pg.s.memUsed / pg.s.memTotal * 100) + "%" : "–"
            values: pg.home.memH
            detail: pg.home.bytes(pg.s.memUsed) + " de " + pg.home.bytes(pg.s.memTotal)
        }
        Stat {
            width: grid.cw; height: 128
            title: "GPU"; icon: "gpu"
            value: pg.g ? pg.g.usage + "%" : "–"
            values: pg.home.gpuH
            detail: pg.g ? pg.g.temp + " °C · " + pg.home.bytes(pg.g.memUsed) + " de " + pg.home.bytes(pg.g.memTotal) : "Sem dados da GPU"
        }
        Stat {
            width: grid.cw; height: 128
            title: "Rede"; icon: "lan"
            value: ""
            max: 0
            values: pg.home.rxH; values2: pg.home.txH
            color2: Theme.muted
            detail: "↓ " + pg.home.rate(pg.s.rx) + "   ↑ " + pg.home.rate(pg.s.tx)
        }
    }

    Row {
        anchors { top: grid.bottom; topMargin: 10; bottom: parent.bottom }
        width: parent.width
        spacing: 10

        component InfoRow: Item {
            id: ir
            property string icon
            property string label
            property string value
            width: parent ? parent.width : 100; height: 19
            UiIcon { id: ii; name: ir.icon; size: 13; color: Theme.muted; width: 16; anchors.verticalCenter: parent.verticalCenter }
            UiText { anchors { left: ii.right; leftMargin: 7; verticalCenter: parent.verticalCenter } text: ir.label; color: Theme.muted; font.pixelSize: 12; width: 56 }
            UiText { anchors { left: ii.right; leftMargin: 66; right: parent.right; verticalCenter: parent.verticalCenter } text: ir.value; color: Theme.text; font.pixelSize: 12; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight }
        }

        HomeCard {
            width: (parent.width - 10) / 2; height: parent.height
            title: "Sistema"; icon: "desktop"
            Column {
                width: parent.width
                spacing: 3
                InfoRow { icon: "chip"; label: "CPU"; value: (pg.home.st.cpuModel ?? "").replace(/\(R\)|\(TM\)|CPU /g, "").replace(/\s+/g, " ") }
                InfoRow { icon: "gpu"; label: "GPU"; value: pg.g ? pg.g.name.replace("NVIDIA ", "") : "–" }
                InfoRow { icon: "arch"; label: "Sistema"; value: pg.home.st.distro ?? "" }
                InfoRow { icon: "linux"; label: "Kernel"; value: pg.home.st.kernel ?? "" }
                InfoRow { icon: "dashboard"; label: "Interface"; value: pg.home.st.wm ?? "" }
                InfoRow { icon: "clock"; label: "Ativo"; value: pg.home.dur(pg.s.uptime) }
            }
        }
        HomeCard {
            width: (parent.width - 10) / 2; height: parent.height
            title: "Armazenamento"; icon: "disk"
            Column {
                width: parent.width
                spacing: 9
                Repeater {
                    model: pg.home.disks
                    delegate: Column {
                        required property var modelData
                        width: parent.width
                        spacing: 4
                        readonly property real r: modelData.total ? modelData.used / modelData.total : 0
                        Item {
                            width: parent.width; height: 15
                            UiText { text: modelData.mount; color: Theme.text; font.pixelSize: 12 }
                            UiText { anchors.right: parent.right; text: (modelData.used / 1073741824).toFixed(0) + " / " + (modelData.total / 1073741824).toFixed(0) + " GiB"; color: Theme.muted; font.pixelSize: 12 }
                        }
                        Rectangle {
                            width: parent.width; height: 6; radius: 3; color: Theme.cardHi
                            Rectangle { width: parent.width * parent.parent.r; height: 6; radius: 3; color: parent.parent.r > 0.9 ? Theme.danger : Theme.accent }
                        }
                    }
                }
                InfoRow { icon: "swap_vertical"; label: "Swap"; value: pg.home.bytes(pg.s.swapUsed) + " de " + pg.home.bytes(pg.s.swapTotal) }
            }
        }
    }
}
