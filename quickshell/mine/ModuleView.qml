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
            cpu: cpuC, memory: memoryC, volume: volumeC, text: textC, tray: trayC, palette: paletteC
        })[root.type]
    }

    Component {
        id: clockC
        Label {
            SystemClock { id: clk; precision: SystemClock.Minutes }
            text: root.vertical ? Qt.formatDateTime(clk.date, "HH\nmm") : Qt.formatDateTime(clk.date, root.opts.format || "ddd dd MMM   HH:mm")
        }
    }

    Component {
        id: textC
        Label { text: root.opts.text ?? "" }
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
        Label {
            width: Math.min(implicitWidth, root.vertical ? 24 : 320)
            elide: Text.ElideRight
            visible: !root.vertical
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
        }
    }



}
