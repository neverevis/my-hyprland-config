// Estado de execucao das barras (nao e salvo): progresso de mostrar/esconder de cada uma (0..1).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    property var p: ({})

    // progresso do seletor de wallpaper (0..1), animado com a mesma curva/duracao das barras
    property real pickerProg: Settings.wpPickerOpen ? 1 : 0
    Behavior on pickerProg {
        NumberAnimation {
            duration: Settings.animOf("picker").duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Settings.animOf("picker").curve
        }
    }
    function set(i: int, v: real): void {
        const c = Object.assign({}, p)
        c[i] = v
        p = c
    }
}
