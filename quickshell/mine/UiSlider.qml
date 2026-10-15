// Linha com nome, valor e uma barra arrastavel (Ctrl + roda do mouse tambem ajusta).
import QtQuick

Item {
    id: r
    property string label
    property string icon
    property real from: 0
    property real to: 100
    property int value: 0
    property string suffix: ""
    signal moved(int v)

    height: 50
    width: parent ? parent.width : 300

    Row {
        spacing: 8
        UiIcon { visible: r.icon !== ""; name: r.icon; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
        Text { text: r.label; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
    }
    // valor: clique para digitar (Enter aplica, Esc cancela; fica entre "from" e "to")
    Rectangle {
        id: pill
        property bool editing: false
        anchors.right: parent.right
        width: Math.max(44, (editing ? input.contentWidth + unit.implicitWidth + 4 : valText.implicitWidth) + 16)
        height: 24; radius: 7
        color: editing ? Theme.bg : (pm.containsMouse ? Theme.cardHi : Theme.track)
        border.width: 1; border.color: editing ? Theme.accent : Theme.border
        Behavior on width { NumberAnimation { duration: 90 } }
        Text { id: valText; visible: !pill.editing; anchors.centerIn: parent; text: r.value + r.suffix; color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium }
        MouseArea {
            id: pm
            anchors.fill: parent
            visible: !pill.editing
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
            onClicked: { input.text = String(r.value); pill.editing = true; input.forceActiveFocus(); input.selectAll() }
        }
        Row {
            visible: pill.editing
            anchors.centerIn: parent
            spacing: 2
            TextInput {
                id: input
                color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium
                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                validator: IntValidator { bottom: Math.floor(Math.min(r.from, 0) - 100000); top: Math.ceil(r.to + 100000) }
                function commit() {
                    if (!pill.editing) return
                    pill.editing = false
                    const v = parseInt(text)
                    if (!isNaN(v)) r.moved(Math.round(Math.max(r.from, Math.min(r.to, v))))
                }
                onAccepted: commit()
                onActiveFocusChanged: if (!activeFocus) commit()
                Keys.onEscapePressed: e => { pill.editing = false; e.accepted = true }
                Keys.onUpPressed: text = String(Math.min(r.to, (parseInt(text) || 0) + 1))
                Keys.onDownPressed: text = String(Math.max(r.from, (parseInt(text) || 0) - 1))
            }
            Text { id: unit; text: r.suffix.trim(); color: Theme.muted; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    Item {
        id: area
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 22
        readonly property real ratio: r.to > r.from ? Math.max(0, Math.min(1, (r.value - r.from) / (r.to - r.from))) : 0

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.cardHi }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: knob.x + knob.width / 2; height: 6; radius: 3; color: Theme.accent }
        Rectangle {
            id: knob
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: 9
            x: area.ratio * (area.width - width)
            color: Theme.accent
            border.width: 4; border.color: Theme.accentText
            scale: mouse.pressed ? 1.15 : (mouse.containsMouse ? 1.06 : 1)
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function upd(x) {
                const t = Math.max(0, Math.min(1, (x - knob.width / 2) / (area.width - knob.width)))
                r.moved(Math.round(r.from + t * (r.to - r.from)))
            }
            onPressed: m => upd(m.x)
            onPositionChanged: m => { if (pressed) upd(m.x) }
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            acceptedModifiers: Qt.ControlModifier   // so com Ctrl: a roda sozinha continua rolando a pagina
            onWheel: e => { const st = Math.max(1, Math.round((r.to - r.from) / 100)); r.moved(Math.max(r.from, Math.min(r.to, r.value + (e.angleDelta.y > 0 ? st : -st)))) }
        }
    }
}
