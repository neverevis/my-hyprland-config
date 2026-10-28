// Area de arrasto de uma peca da maquete ou da barra de pecas (ctl = TermMock, que e o unico controlador do arrasto).
// tray: a peca vem da barra (soltar na maquete poe a peca); tap: clique sem arrastar.
import QtQuick

MouseArea {
    id: da
    property var ctl
    property string group
    property string key
    property bool tray: false
    property bool canDrag: true
    property point p0
    property bool moved: false
    property bool wasMoved: false
    signal tap
    hoverEnabled: true
    cursorShape: da.moved ? Qt.ClosedHandCursor : (canDrag ? Qt.OpenHandCursor : Qt.PointingHandCursor)
    onPressed: m => { p0 = Qt.point(m.x, m.y); moved = false; wasMoved = false }
    onPositionChanged: m => {
        if (!pressed || !canDrag) return
        if (!moved && Math.hypot(m.x - p0.x, m.y - p0.y) > 6) { moved = true; ctl.startDrag(group, key, tray) }
        if (moved) { const q = mapToItem(ctl, m.x, m.y); ctl.moveDrag(q.x, q.y) }
    }
    onReleased: { if (moved) { wasMoved = true; moved = false; ctl.endDrag() } }
    onCanceled: { if (moved) { moved = false; ctl.endDrag() } }
    onClicked: if (!wasMoved) tap()
}
