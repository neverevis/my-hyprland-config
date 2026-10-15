// Seletor de cor: quadrado de saturacao/brilho, barra de matiz e campo hexadecimal.
import QtQuick

Column {
    id: root
    property color value: "#000000"
    signal picked(color c)

    property real h: 0
    property real s: 0
    property real v: 0
    property bool dragging: false
    spacing: 8

    function syncFrom(c) {
        if (dragging) return
        if (c.hsvHue >= 0) h = c.hsvHue
        s = c.hsvSaturation
        v = c.hsvValue
    }
    onValueChanged: syncFrom(value)
    Component.onCompleted: syncFrom(value)
    function emit() { root.picked(Qt.hsva(h, s, v, 1)) }

    // saturacao (x) e brilho (y)
    Rectangle {
        width: 260; height: 150; radius: 6
        color: Qt.hsva(root.h, 1, 1, 1)
        clip: true
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#ffffffff" }
                GradientStop { position: 1; color: "#00ffffff" }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#00000000" }
                GradientStop { position: 1; color: "#ff000000" }
            }
        }
        Rectangle {
            x: root.s * parent.width - 7; y: (1 - root.v) * parent.height - 7
            width: 14; height: 14; radius: 7
            color: "transparent"; border.width: 2; border.color: "#ffffff"
        }
        MouseArea {
            anchors.fill: parent
            function upd(m) {
                root.s = Math.max(0, Math.min(1, m.x / width))
                root.v = 1 - Math.max(0, Math.min(1, m.y / height))
                root.emit()
            }
            onPressed: m => { root.dragging = true; upd(m) }
            onPositionChanged: m => { if (pressed) upd(m) }
            onReleased: root.dragging = false
        }
    }

    // matiz
    Rectangle {
        width: 260; height: 16; radius: 8
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.000; color: "#ff0000" }
            GradientStop { position: 0.167; color: "#ffff00" }
            GradientStop { position: 0.333; color: "#00ff00" }
            GradientStop { position: 0.500; color: "#00ffff" }
            GradientStop { position: 0.667; color: "#0000ff" }
            GradientStop { position: 0.833; color: "#ff00ff" }
            GradientStop { position: 1.000; color: "#ff0000" }
        }
        Rectangle {
            x: root.h * (parent.width - 8); y: -2
            width: 8; height: 20; radius: 3
            color: "#ffffff"; border.width: 1; border.color: "#888888"
        }
        MouseArea {
            anchors.fill: parent
            function upd(m) { root.h = Math.max(0, Math.min(0.999, m.x / width)); root.emit() }
            onPressed: m => { root.dragging = true; upd(m) }
            onPositionChanged: m => { if (pressed) upd(m) }
            onReleased: root.dragging = false
        }
    }

    Row {
        spacing: 8
        UiField {
            width: 110
            text: root.value.toString()
            maximumLength: 7
            onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) root.picked(text)
        }
        Rectangle { width: 28; height: 28; radius: 6; color: root.value; border.width: 1; border.color: "#555" }
    }
}
