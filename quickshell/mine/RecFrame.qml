// Moldura em volta da area que esta sendo gravada (so gravacao de area). Fica FORA da area para nao entrar no video,
// deixa o mouse passar e "respira" devagar. Some quando a gravacao para.
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    // "x,y wxh" -> {x, y, w, h}
    readonly property var r: {
        const m = /^(-?\d+),(-?\d+) (\d+)x(\d+)$/.exec(Recorder.geo)
        return m ? { x: +m[1], y: +m[2], w: +m[3], h: +m[4] } : null
    }
    Variants {
        model: Recorder.active && r ? Quickshell.screens : []
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}          // clique atravessa
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-rec-frame"
            Rectangle {
                x: r.x - modelData.x - 5; y: r.y - modelData.y - 5
                width: r.w + 10; height: r.h + 10
                radius: 6; color: "transparent"
                border.width: 2; border.color: Theme.danger
                SequentialAnimation on opacity {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 0.35; duration: 1100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 1100; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
