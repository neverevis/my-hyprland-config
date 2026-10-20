// Um modulo de barra. "type" escolhe qual (clock, workspaces, window, cpu, memory, volume, text);
// "opts" tem as opcoes dele; "vertical" e verdadeiro nas barras laterais.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

Item {
    id: root
    property string type
    property var opts: ({})
    property bool vertical: false
    property string side: "bottom"
    property int barIdx: -1
    property point origin: Qt.point(0, 0)   // canto da janela da barra na tela (para os detalhes ao passar o mouse)

    // detalhes ao passar o mouse: que cartao cada modulo abre (opcao "popup" desliga)
    readonly property string popKind: root.opts.popup === false ? "" : ({ clock: "calendar", weather: "weather", cpu: "resources", memory: "resources", disk: "resources", swap: "resources", gpu: "system",
        temp: "system", netspeed: "net", aiusage: "ai", avatar: "profile", media: "media", volume: "volume", privacy: "privacy", updates: "updates", battery: "battery", bluetooth: "bt" })[root.type] ?? ""
    readonly property bool hasPop: popKind !== ""
    HoverHandler {
        enabled: root.popKind !== ""
        onHoveredChanged: {
            if (!hovered) { BarState.popLeave(); return }
            const p = root.mapToItem(null, 0, 0)
            BarState.popEnter({ kind: root.popKind, opts: root.opts, side: root.side, type: root.type,
                                rect: { x: p.x + root.origin.x, y: p.y + root.origin.y, w: root.width, h: root.height } })
        }
    }

    readonly property bool itemVisible: loader.item ? loader.item.visible : false   // modulos que se escondem (atualizacoes, bateria...) nao deixam vao
    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0

    component Label: UiText {
        color: Settings.textColor
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
    }

    Loader {
        id: loader
        sourceComponent: ({
            clock: clockC, workspaces: workspacesC, window: windowC,
            cpu: cpuC, memory: memoryC, disk: diskC, swap: swapC, volume: volumeC, text: textC, tray: trayC, palette: paletteC, power: powerC, taskbar: taskbarC, island: islandC
        })[root.type] ?? extraC
    }

    Component {
        id: clockC
        Item {
            id: ck
            implicitWidth: col.implicitWidth
            implicitHeight: col.implicitHeight
            opacity: cm.containsMouse ? 0.75 : 1
            Behavior on opacity { NumberAnimation { duration: 120 } }
            SystemClock { id: clk; precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }
            Column {
                id: col
                spacing: 1
                Label {
                    width: col.width
                    text: root.vertical ? Qt.formatDateTime(clk.date, Settings.clock24 ? "HH\nmm" : "h\nmm") : DateTime.formatted(clk.date, root.opts.format)
                }
                // barra lateral: data curta (dia/mes) embaixo da hora
                Label {
                    visible: root.vertical && root.opts.shortDate !== false
                    width: col.width
                    text: Qt.formatDateTime(clk.date, "dd/MM")
                    font.pixelSize: 10
                    opacity: 0.7
                }
            }
            MouseArea {   // clique no relogio abre o painel Inicio
                id: cm
                anchors.fill: parent; anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.homeOpen = !Settings.homeOpen
            }
        }
    }

    Component {
        id: powerC
        // botao de energia: abre o menu (bloquear, suspender, sair, reiniciar, desligar)
        UiIcon {
            name: "power"
            size: 17
            color: pwm.containsMouse ? Settings.accent : Settings.textColor
            Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 120 } }
            scale: pwm.pressed ? 0.88 : (pwm.containsMouse ? 1.1 : 1)
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            MouseArea {
                id: pwm
                anchors.fill: parent; anchors.margins: -5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Power.menuOpen = true
            }
            TipHover { text: "Menu de energia"; side: root.side; origin: root.origin; enabled: !root.hasPop }
        }
    }

    Component {
        id: textC
        // na barra lateral o texto fica deitado ao longo da barra (girado), em vez de estourar a espessura
        Item {
            implicitWidth: root.vertical ? tl.implicitHeight : tl.implicitWidth
            implicitHeight: root.vertical ? tl.implicitWidth : tl.implicitHeight
            Label {
                id: tl
                anchors.centerIn: parent
                text: root.opts.text ?? ""
                rotation: root.vertical ? (root.side === "right" ? 90 : -90) : 0
            }
        }
    }

    Component {
        id: taskbarC
        TaskbarModule { opts: root.opts; vertical: root.vertical; side: root.side; origin: root.origin; barIdx: root.barIdx }
    }
    Component {
        id: islandC
        IslandModule { opts: root.opts; vertical: root.vertical }
    }
    Component {
        id: extraC
        ExtraModule { type: root.type; opts: root.opts; vertical: root.vertical; side: root.side; origin: root.origin; hasPop: root.popKind !== "" }
    }

    Component {
        id: workspacesC
        WorkspacesModule { vertical: root.vertical; side: root.side; origin: root.origin; opts: root.opts }
    }

    Component {
        id: cpuC
        SystemMeter { kind: "cpu"; opts: root.opts; vertical: root.vertical }
    }

    Component {
        id: memoryC
        SystemMeter { kind: "memory"; opts: root.opts; vertical: root.vertical }
    }

    Component { id: diskC; SystemMeter { kind: "disk"; opts: root.opts; vertical: root.vertical } }
    Component { id: swapC; SystemMeter { kind: "swap"; opts: root.opts; vertical: root.vertical } }

    Component {
        id: volumeC
        Loader {
            sourceComponent: root.opts.display === "slider" ? volSliderC : volMeterC
        }
    }
    Component { id: volMeterC; VolumeModule { opts: root.opts; vertical: root.vertical } }
    Component {
        id: volSliderC
        VolumeSlider { opts: root.opts; vertical: root.vertical }
    }

    Component {
        id: paletteC
        PaletteModule { vertical: root.vertical; opts: root.opts }
    }

    Component {
        id: trayC
        TrayModule { vertical: root.vertical; side: root.side; opts: root.opts; origin: root.origin }
    }

    Component {
        id: windowC
        // janela ativa: icone do app + classe (pequena) e titulo; sem janela focada usa a maior do workspace, e sem nenhuma
        // mostra "Área de trabalho". Nas barras laterais, so o icone. Opcao showClass (padrao ligada) liga/desliga a linha da classe.
        Row {
            id: winRow
            spacing: 8
            readonly property var focusedWs: Hyprland.focusedWorkspace
            readonly property var tl: Hyprland.activeToplevel
            // maior janela do workspace atual (quando nada esta focado)
            readonly property var biggest: {
                if (tl || !focusedWs) return null
                let best = null, area = -1
                for (const t of focusedWs.toplevels.values) {
                    const o = t.lastIpcObject
                    if (!o || !o.size) continue
                    const a = o.size[0] * o.size[1]
                    if (a > area) { area = a; best = t }
                }
                return best
            }
            readonly property var cur: tl ?? biggest
            readonly property string cls: cur && cur.lastIpcObject ? (cur.lastIpcObject.class ?? "") : ""
            readonly property string title: cur ? (cur.title ?? "") : ""
            readonly property bool desktop: !cur
            readonly property var entry: cls !== "" ? DesktopEntries.heuristicLookup(cls) : null
            readonly property string iconUrl: desktop ? Icons.path("user-desktop", "") : (cls === "" ? "" : Icons.path(entry && entry.icon ? entry.icon : cls, "application-x-executable"))
            readonly property bool showClass: root.opts.showClass !== false
            readonly property string line1: desktop ? "Área de trabalho" : (entry && entry.name ? entry.name : cls)
            readonly property string line2: desktop ? "Workspace " + (focusedWs ? focusedWs.id : 1) : title
            Image {
                visible: winRow.iconUrl !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: 18; height: 18
                source: winRow.iconUrl
                sourceSize: Qt.size(36, 36)
                fillMode: Image.PreserveAspectFit
                opacity: winRow.desktop ? 0.7 : 1
            }
            Column {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(Math.max(winRow.showClass ? l1.implicitWidth : 0, l2.implicitWidth), 320)
                spacing: -1
                Label {
                    id: l1
                    visible: winRow.showClass
                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    font.pixelSize: 10
                    opacity: 0.65
                    text: winRow.line1
                }
                Label {
                    id: l2
                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    font.pixelSize: winRow.showClass ? 12 : 14
                    text: winRow.showClass || !winRow.desktop ? winRow.line2 : winRow.line1
                }
            }
            TipHover { text: root.vertical ? winRow.line1 + (winRow.title !== "" ? " · " + winRow.title : "") : ""; side: root.side; origin: root.origin }
        }
    }

}
