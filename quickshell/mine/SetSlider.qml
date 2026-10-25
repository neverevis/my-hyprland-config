// SetSlider: linha com barra deslizante no fim e o valor num chip (clique no chip para digitar; Ctrl + roda ajusta).
// - from/to/step, unit (" %", " px", " ms"), zeroLabel ("Desligado", "Auto") mostrado quando o valor e o minimo.
// - ticks: true desenha marcas nos passos (so se forem poucos). def: valor padrao (mostra o botao de restaurar).
// - moved(v) dispara ao vivo durante o arraste (o valor ja vem arredondado ao passo).
// Exemplo:  SetSlider { icon: "opacity"; label: "Opacidade"; from: 10; to: 100; unit: " %"; def: 60; value: Settings.glassOpacity; onMoved: v => Settings.glassOpacity = v }
import QtQuick

SetRow {
    id: s
    property real from: 0
    property real to: 100
    property real value: 0
    property real step: 1
    property string unit: ""
    property string zeroLabel: ""
    property var def: undefined
    property bool ticks: false
    property int trackWidth: Math.max(140, Math.min(240, s.width * 0.34))
    signal moved(real v)

    canReset: def !== undefined && Math.abs(value - def) > 1e-6
    onReset: moved(def)

    function snap(v) {
        const st = step > 0 ? step : 1
        const r = Math.round((v - from) / st) * st + from
        return Math.max(from, Math.min(to, Math.round(r * 1000) / 1000))
    }
    function fmt(v) { return (zeroLabel !== "" && v <= from) ? zeroLabel : (Math.round(v * 100) / 100) + unit }

    Item {
        id: area
        width: s.trackWidth; height: 28
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        readonly property real ratio: s.to > s.from ? Math.max(0, Math.min(1, (s.value - s.from) / (s.to - s.from))) : 0
        readonly property int nTicks: s.ticks && s.step > 0 ? Math.round((s.to - s.from) / s.step) : 0
        Rectangle { id: trk; anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.cardHi }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: knob.x + knob.width / 2; height: 6; radius: 3; color: Theme.accent }
        Repeater {
            model: area.nTicks > 0 && area.nTicks <= 20 ? area.nTicks + 1 : 0
            delegate: Rectangle {
                required property int index
                x: 9 + index / area.nTicks * (area.width - 18) - 1
                y: area.height / 2 + 6
                width: 2; height: 4; radius: 1
                color: index / area.nTicks <= area.ratio ? Theme.accent : Theme.border
            }
        }
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
            anchors.topMargin: -6; anchors.bottomMargin: -6
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            function upd(x) {
                const t = Math.max(0, Math.min(1, (x - knob.width / 2) / (area.width - knob.width)))
                const v = s.snap(s.from + t * (s.to - s.from))
                if (v !== s.value) s.moved(v)
            }
            onPressed: m => upd(m.x)
            onPositionChanged: m => { if (pressed) upd(m.x) }
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            acceptedModifiers: Qt.ControlModifier   // so com Ctrl: a roda sozinha rola a pagina
            onWheel: e => { const st = s.step > 0 ? s.step : 1; s.moved(s.snap(s.value + (e.angleDelta.y > 0 ? st : -st))) }
        }
    }
    // valor: clique para digitar (Enter aplica, Esc cancela)
    Rectangle {
        id: chip
        property bool editing: false
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: Math.max(56, (editing ? input.contentWidth + 12 : valText.implicitWidth) + 18)
        height: 28; radius: 9
        color: editing ? Theme.bg : (cm.containsMouse ? Theme.cardHi : Theme.track)
        border.width: 1; border.color: editing ? Theme.accent : Theme.border
        UiText {
            id: valText; visible: !chip.editing; anchors.centerIn: parent
            text: s.fmt(s.value); color: Theme.text; font.pixelSize: SetK.fChip; font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
        MouseArea {
            id: cm
            anchors.fill: parent
            visible: !chip.editing
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
            onClicked: { input.text = String(Math.round(s.value * 100) / 100); chip.editing = true; input.forceActiveFocus(); input.selectAll() }
        }
        TextInput {
            id: input
            visible: chip.editing
            anchors.centerIn: parent
            font.family: Theme.font; font.pixelSize: SetK.fChip; font.weight: Font.DemiBold
            color: Theme.text; selectionColor: Theme.accent; selectedTextColor: Theme.accentText
            validator: DoubleValidator {}
            function commit() {
                if (!chip.editing) return
                chip.editing = false
                const v = parseFloat(text.replace(",", "."))
                if (!isNaN(v)) s.moved(s.snap(v))
            }
            onAccepted: commit()
            onActiveFocusChanged: if (!activeFocus) commit()
            Keys.onEscapePressed: e => { chip.editing = false; e.accepted = true }
        }
    }
}
