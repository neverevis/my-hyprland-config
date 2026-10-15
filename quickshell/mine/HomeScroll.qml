// Area rolavel (so com a roda do mouse) usada pelas abas do painel Inicio; os filhos entram numa coluna.
import QtQuick

Flickable {
    id: f
    default property alias content: col.data
    property alias spacing: col.spacing
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: false
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => { f.contentY = Math.max(0, Math.min(Math.max(0, f.contentHeight - f.height), f.contentY - e.angleDelta.y)) }
    }
    Column { id: col; width: f.width; spacing: 10 }
}
