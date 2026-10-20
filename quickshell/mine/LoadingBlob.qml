// Indicador de carregamento do Material 3 (o MaterialLoadingIndicator do end4): uma forma que gira devagar e, a cada
// 800 ms, vira a proxima (morph) com um salto de 90 graus e um pulo de tamanho. Tudo para quando invisivel ou parado.
// clicked() so com clickable (ex.: refazer a busca da letra).
import QtQuick

Item {
    id: lb
    property bool running: true
    property real size: 48
    property color color: Theme.primaryContainerInk
    property color bg: Theme.primaryContainer
    property bool showBg: true                     // circulo atras, como no end4
    property bool clickable: false
    property var shapes: ["softburst", "cookie9", "pentagon", "pill", "sunny", "cookie4", "oval"]
    signal clicked()
    implicitWidth: size
    implicitHeight: size

    readonly property bool active: running && visible
    property int step: 0
    property real turn: 0                          // giro continuo
    property real leap: 0                          // saltos de 90 graus
    property real zoom: 0                          // 0 -> 1 a cada salto (cresce ate a metade e volta)

    NumberAnimation on turn { running: lb.active; from: 0; to: 360; duration: 12000; loops: Animation.Infinite }
    Timer { interval: 800; repeat: true; running: lb.active; onTriggered: leapA.restart() }
    ParallelAnimation {
        id: leapA
        ScriptAction { script: lb.step = (lb.step + 1) % Math.max(1, lb.shapes.length) }
        NumberAnimation { target: lb; property: "leap"; to: lb.leap + 90; duration: 350; easing.type: Easing.InOutQuad }
        NumberAnimation { target: lb; property: "zoom"; from: 0; to: 1; duration: 750; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
    }
    onActiveChanged: if (!active) { leapA.stop(); leap = Math.round(leap / 90) * 90 % 360; zoom = 0 }

    Rectangle {
        anchors.fill: parent
        visible: lb.showBg
        radius: width / 2
        color: lb.bg
    }
    Flower {
        readonly property real base: lb.size * 0.7
        readonly property real grow: 1 + 0.2 * (lb.zoom < 0.5 ? lb.zoom * 2 : (1 - lb.zoom) * 2)
        width: base * grow; height: width
        anchors.centerIn: parent
        shape: lb.shapes[lb.step] ?? "circle"
        color: lb.color
        rotation: lb.turn + lb.leap
    }
    MouseArea {
        anchors.fill: parent
        enabled: lb.clickable
        cursorShape: lb.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: lb.clicked()
    }
}
