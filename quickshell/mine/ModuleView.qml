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

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0

    component Label: Text {
        color: Settings.textColor
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
    }

    Loader {
        id: loader
        sourceComponent: ({
            clock: clockC, workspaces: workspacesC, window: windowC,
            cpu: cpuC, memory: memoryC, volume: volumeC, text: textC, tray: trayC, palette: paletteC, power: powerC
        })[root.type] ?? extraC
    }

    Component {
        id: clockC
        Label {
            SystemClock { id: clk; precision: SystemClock.Minutes }
            text: root.vertical ? Qt.formatDateTime(clk.date, "HH\nmm") : Qt.formatDateTime(clk.date, root.opts.format || "ddd dd MMM   HH:mm")
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
            readonly property string iconUrl: cls === "" ? "" : Quickshell.iconPath(entry && entry.icon ? entry.icon : cls.toLowerCase(), true)
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
