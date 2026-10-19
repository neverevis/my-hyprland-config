// Volume como icone + barra: arraste a barra (ou clique) para ajustar, a roda do mouse muda o volume, clique no icone = mudo.
// Opcoes: width (comprimento da barra), height (espessura), color, step (%), showValue
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property var opts: ({})
    property bool vertical: false

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    readonly property color col: opts.color ? opts.color : (Settings.themeOn ? ThemeColors.primary : Settings.textColor)
    readonly property real len: opts.width ?? 90
    readonly property real thick: Math.max(4, Math.min(14, (opts.height ?? 6)))
    readonly property real vol: audio ? Math.min(1, audio.volume) : 0
    readonly property bool muted: !!(audio && audio.muted)
    readonly property real shownVol: muted ? 0 : vol
    readonly property real iconS: 18
    readonly property real step: (opts.step ?? 5) / 100

    function setVol(v) { if (audio) { audio.volume = Math.max(0, Math.min(1, v)); if (audio.muted && v > 0) audio.muted = false } }

    implicitWidth: vertical ? Math.max(iconS, 16) : iconS + 8 + len + (opts.showValue ? 34 : 0)
    implicitHeight: vertical ? iconS + 8 + len : Math.max(iconS, 16)

    // ---- icone: alto-falante com ondas conforme o volume ----
    Item {
        id: icon
        width: root.iconS; height: root.iconS
        x: 0; y: 0
        opacity: root.muted ? 0.55 : 1
        Shape {
            anchors.fill: parent
            ShapePath {
                fillColor: root.col; strokeColor: "transparent"
                PathSvg { path: "M2 7 L6 7 L10.5 3 L10.5 15 L6 11 L2 11 Z" }
            }
            ShapePath {   // onda pequena
                fillColor: "transparent"; strokeColor: root.col; strokeWidth: 1.6; capStyle: ShapePath.RoundCap
                PathSvg { path: root.shownVol > 0.02 ? "M13 6.5 A3.5 3.5 0 0 1 13 11.5" : "M0 0" }
            }
            ShapePath {   // onda grande
                fillColor: "transparent"; strokeColor: root.col; strokeWidth: 1.6; capStyle: ShapePath.RoundCap
                PathSvg { path: root.shownVol > 0.45 ? "M15.2 4.2 A7 7 0 0 1 15.2 13.8" : "M0 0" }
            }
            ShapePath {   // mudo: risco
                fillColor: "transparent"; strokeColor: root.col; strokeWidth: 1.8; capStyle: ShapePath.RoundCap
                PathSvg { path: root.muted ? "M13 6.5 L17 11.5 M17 6.5 L13 11.5" : "M0 0" }
            }
        }
        MouseArea {
            anchors { fill: parent; margins: -3 }
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.audio) root.audio.muted = !root.audio.muted
        }
    }

    // ---- barra ----
    Item {
        id: track
        x: root.vertical ? (root.width - width) / 2 : root.iconS + 8
        y: root.vertical ? root.iconS + 8 : (root.height - height) / 2
        width: root.vertical ? root.thick + 8 : root.len
        height: root.vertical ? root.len : root.thick + 8

        Rectangle {   // trilho
            id: rail
            anchors.centerIn: parent
            width: root.vertical ? root.thick : parent.width
            height: root.vertical ? parent.height : root.thick
            radius: root.thick / 2
            color: Qt.rgba(root.col.r, root.col.g, root.col.b, 0.22)
        }
        Rectangle {   // preenchimento (anima ao mudar, mas acompanha o dedo sem atraso ao arrastar)
            id: fill
            radius: root.thick / 2
            color: root.col
            opacity: root.muted ? 0.4 : 1
            x: rail.x; y: root.vertical ? rail.y + rail.height * (1 - root.shownVol) : rail.y
            width: root.vertical ? rail.width : rail.width * root.shownVol
            height: root.vertical ? rail.height * root.shownVol : rail.height
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 90 } }
            Behavior on height { enabled: !drag.pressed; NumberAnimation { duration: 90 } }
        }
        Rectangle {   // bolinha (aparece ao passar o mouse / arrastar)
            width: root.thick + 6; height: width; radius: width / 2
            color: root.col
            opacity: drag.pressed || drag.containsMouse ? 1 : 0
            scale: drag.pressed ? 1.15 : 1
            Behavior on opacity { NumberAnimation { duration: 120 } }
            x: root.vertical ? rail.x + (rail.width - width) / 2 : rail.x + rail.width * root.shownVol - width / 2
            y: root.vertical ? rail.y + rail.height * (1 - root.shownVol) - height / 2 : rail.y + (rail.height - height) / 2
        }
        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function at(mx, my) {
                const r = root.vertical ? 1 - (my - rail.y) / rail.height : (mx - rail.x) / rail.width
                root.setVol(Math.round(r * 100) / 100)
            }
            onPressed: m => at(m.x, m.y)
            onPositionChanged: m => { if (pressed) at(m.x, m.y) }
            onWheel: w => root.setVol(root.vol + (w.angleDelta.y > 0 ? root.step : -root.step))
        }
    }
    // roda do mouse tambem no icone e no valor
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: w => root.setVol(root.vol + (w.angleDelta.y > 0 ? root.step : -root.step))
        z: -1
    }

    UiText {
        visible: !!root.opts.showValue
        x: root.vertical ? (root.width - width) / 2 : track.x + track.width + 6
        y: root.vertical ? track.y + track.height + 2 : (root.height - height) / 2
        text: root.audio ? (root.muted ? "mudo" : Math.round(root.vol * 100) + "%") : "--"
        color: Settings.textColor; font.pixelSize: 12
    }
}
