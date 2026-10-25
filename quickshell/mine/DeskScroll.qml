// Rolagem do editor de widgets: Flickable sem arrasto (so roda do mouse, passo fixo) com barra visivel e arrastavel.
// Uso: DeskScroll { contentHeight: col.implicitHeight; Column { width: parent.width ... } }
import QtQuick

Item {
    id: sc
    default property alias data: inner.data
    property real contentHeight: 0
    property alias contentY: fl.contentY
    readonly property real maxY: Math.max(0, contentHeight - height)
    function toTop() { fl.contentY = 0 }
    function clampY(v) { return Math.max(0, Math.min(sc.maxY, v)) }
    clip: true

    Flickable {
        id: fl
        anchors { fill: parent; rightMargin: 10 }
        contentWidth: width
        contentHeight: sc.contentHeight
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        onHeightChanged: contentY = sc.clampY(contentY)
        Item { id: inner; width: fl.width; height: sc.contentHeight }
        WheelHandler {
            target: null
            onWheel: e => fl.contentY = sc.clampY(fl.contentY - e.angleDelta.y * 0.8)
        }
    }
    // barra: trilho fino sempre visivel quando ha o que rolar; o dedo na barra arrasta
    Item {
        id: bar
        visible: sc.maxY > 1
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: 10
        Rectangle {
            id: thumb
            anchors.horizontalCenter: parent.horizontalCenter
            width: bm.containsMouse || bm.pressed ? 6 : 4; radius: width / 2
            height: Math.max(28, bar.height * bar.height / Math.max(1, sc.contentHeight))
            y: sc.maxY > 0 ? fl.contentY / sc.maxY * (bar.height - height) : 0
            color: Theme.text
            opacity: bm.containsMouse || bm.pressed ? 0.5 : 0.25
            Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            id: bm
            anchors.fill: parent
            hoverEnabled: true
            function to(y) { const room = Math.max(1, bar.height - thumb.height); fl.contentY = sc.clampY((y - thumb.height / 2) / room * sc.maxY) }
            onPressed: m => to(m.y)
            onPositionChanged: m => { if (pressed) to(m.y) }
        }
    }
}
