// Estado de execucao das barras (nao e salvo): progresso de mostrar/esconder de cada uma (0..1).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    property var p: ({})

    // progresso do seletor de wallpaper (0..1), animado com a mesma curva/duracao das barras
    // dois paineis acoplados (seletor e launcher) nao dividem a moldura: um espera o outro terminar de recolher (sem corte seco)
    readonly property bool bothDocked: Settings.launcherDocked && Settings.wpPickerDocked
    property real pickerProg: Settings.wpPickerOpen && !(bothDocked && launcherProg > 0.02) ? 1 : 0
    Behavior on pickerProg {
        NumberAnimation {
            duration: Settings.animOf("picker").duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Settings.animOf("picker").curve
        }
    }
    // progresso do launcher (0..1) e profundidade do conteudo dele (o Launcher.qml atualiza; a moldura acopla)
    property real launcherProg: Settings.launcherOpen && !(bothDocked && pickerProg > 0.02) ? 1 : 0
    Behavior on launcherProg {
        NumberAnimation {
            duration: Settings.animOf("launcher").duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Settings.animOf("launcher").curve
        }
    }
    property real launcherDepth: 64
    // notificacoes: quantidade de cartoes (a moldura cresce ate o bloco), progresso e comprimento do bloco ao longo da borda (animados)
    property int notifCount: 0
    property real notifProg: notifCount > 0 ? 1 : 0
    Behavior on notifProg {
        NumberAnimation {
            duration: Settings.animOf("notifications").duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Settings.animOf("notifications").curve
        }
    }
    property real notifLen: 0
    property real notifDepth: 0
    function set(i: int, v: real): void {
        const c = Object.assign({}, p)
        c[i] = v
        p = c
    }
}
