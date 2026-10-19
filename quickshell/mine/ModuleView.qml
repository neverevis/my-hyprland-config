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
    property point origin: Qt.point(0, 0)   // canto da janela da barra na tela (para os detalhes ao passar o mouse)

    // detalhes ao passar o mouse: que cartao cada modulo abre (opcao "popup" desliga)
    readonly property string popKind: root.opts.popup === false ? "" : ({ clock: "calendar", weather: "weather", cpu: "system", memory: "system", gpu: "system",
        temp: "system", netspeed: "system", media: "media", volume: "volume", privacy: "privacy", updates: "updates" })[root.type] ?? ""
    HoverHandler {
        enabled: root.popKind !== ""
        onHoveredChanged: {
            if (!hovered) { BarState.popLeave(); return }
            const p = root.mapToItem(null, 0, 0)
            BarState.popEnter({ kind: root.popKind, opts: root.opts, side: root.side, type: root.type,
                                rect: { x: p.x + root.origin.x, y: p.y + root.origin.y, w: root.width, h: root.height } })
        }
    }

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
            cpu: cpuC, memory: memoryC, volume: volumeC, text: textC, tray: trayC, palette: paletteC, power: powerC, taskbar: taskbarC, island: islandC
        })[root.type] ?? extraC
    }

    Component {
        id: clockC
        Label {
            SystemClock { id: clk; precision: SystemClock.Minutes }
            text: root.vertical ? Qt.formatDateTime(clk.date, Settings.clock24 ? "HH\nmm" : "h\nmm") : Qt.formatDateTime(clk.date, root.opts.format || (Settings.clock24 ? "ddd dd MMM   HH:mm" : "ddd dd MMM   h:mm AP"))
            opacity: cm.containsMouse ? 0.75 : 1
            Behavior on opacity { NumberAnimation { duration: 120 } }
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
        TaskbarModule { opts: root.opts; vertical: root.vertical; side: root.side; origin: root.origin }
    }
    Component {
        id: islandC
        IslandModule { opts: root.opts; vertical: root.vertical }
    }
    Component {
        id: extraC
        ExtraModule { type: root.type; opts: root.opts; vertical: root.vertical; side: root.side }
    }

    Component {
        id: workspacesC
        WorkspacesModule { vertical: root.vertical; opts: root.opts }
    }

    Component {
        id: cpuC
        SystemMeter { kind: "cpu"; opts: root.opts; vertical: root.vertical }
    }

    Component {
        id: memoryC
        SystemMeter { kind: "memory"; opts: root.opts; vertical: root.vertical }
    }

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
        TrayModule { vertical: root.vertical; side: root.side; opts: root.opts }
    }

    Component {
        id: windowC
        // janela ativa: icone do app + titulo (nas barras laterais, so o icone)
        Row {
            id: winRow
            spacing: 8
            readonly property var tl: Hyprland.activeToplevel
            readonly property string cls: tl && tl.lastIpcObject ? (tl.lastIpcObject.class ?? "") : ""
            readonly property var entry: cls !== "" ? DesktopEntries.heuristicLookup(cls) : null
            readonly property string iconUrl: cls === "" ? "" : Icons.path(entry && entry.icon ? entry.icon : cls, "")
            Image {
                visible: winRow.iconUrl !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: 18; height: 18
                source: winRow.iconUrl
                sourceSize: Qt.size(36, 36)
                fillMode: Image.PreserveAspectFit
            }
            Label {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 320)
                elide: Text.ElideRight
                text: winRow.tl ? winRow.tl.title : ""
            }
        }
    }



}
