// Estado de execucao das barras (nao e salvo): progresso de mostrar/esconder de cada uma (0..1).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    property var p: ({})

    // progresso do seletor de wallpaper (0..1), animado com a mesma curva/duracao das barras
    // paineis acoplados (seletor de wallpaper, launcher e Inicio) nao dividem a moldura: um espera o outro terminar de recolher (sem corte seco)
    readonly property bool pickerDockedAll: Settings.wpPickerDocked
    readonly property bool launcherDockedAll: Settings.launcherDocked
    readonly property bool homeDockedAll: Settings.homeDocked
    property real pickerProg: Settings.wpPickerOpen && !(pickerDockedAll && ((launcherDockedAll && launcherProg > 0.02) || (homeDockedAll && homeProg > 0.02))) ? 1 : 0
    Behavior on pickerProg {
        NumberAnimation {
            duration: Settings.animOf("picker").duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Settings.animOf("picker").curve
        }
    }
    // progresso do launcher (0..1) e profundidade do conteudo dele (o Launcher.qml atualiza; a moldura acopla)
    property real launcherProg: Settings.launcherOpen && !(launcherDockedAll && ((pickerDockedAll && pickerProg > 0.02) || (homeDockedAll && homeProg > 0.02))) ? 1 : 0
    Behavior on launcherProg {
        NumberAnimation {
            duration: Settings.animOf("launcher").duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Settings.animOf("launcher").curve
        }
    }
    property real launcherDepth: 64
    // painel Inicio: tamanho fixo do conteudo e progresso
    readonly property real homeW: 580
    readonly property real homeH: 452
    property real homeProg: Settings.homeOpen && !(homeDockedAll && ((pickerDockedAll && pickerProg > 0.02) || (launcherDockedAll && launcherProg > 0.02))) ? 1 : 0
    Behavior on homeProg {
        NumberAnimation {
            duration: Settings.animOf("home").duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Settings.animOf("home").curve
        }
    }
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
