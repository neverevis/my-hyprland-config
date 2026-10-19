// NumberAnimation com a animacao escolhida para um lugar (use: id do alvo em Settings.animTargets).
// out: true na saida (fechar/esconder). Dentro de um Behavior, use "out: bh.targetValue < 0.5" (o Behavior
// define o valor-alvo antes de comecar, entao a curva certa ja vale na hora).
import QtQuick

NumberAnimation {
    property string use: "bars"
    property bool out: false
    readonly property var m: Motion.of(use, out)
    duration: m.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: m.curve
}
