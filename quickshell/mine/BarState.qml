// Estado de execucao das barras (nao e salvo): progresso de mostrar/esconder de cada uma (0..1).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: bs
    property var p: ({})

    // ---- detalhes ao passar o mouse nos modulos (BarPopup.qml) ----
    // pop = { kind, opts, side, rect: {x, y, w, h} na tela }; aparece depois de um tempo parado em cima e some ao sair
    // (a menos que o mouse va para o proprio cartao)
    property var pop: null
    property var popPending: null
    property bool popHover: false
    Timer { id: popShowT; interval: Settings.barPopupDelay; onTriggered: bs.pop = bs.popPending }
    Timer { id: popHideT; interval: 260; onTriggered: if (!bs.popHover) bs.pop = null }
    function popEnter(p) {
        if (!Settings.barPopups) return
        popPending = p; popHideT.stop()
        if (pop) pop = p      // ja aberto: troca na hora (passar de um modulo para o outro)
        else popShowT.restart()
    }
    function popLeave() { popShowT.stop(); popHideT.restart() }
    onPopHoverChanged: if (!popHover) popHideT.restart(); else popHideT.stop()
    // barras com "fit" (largura do conteudo, ex.: o dock): comprimento que os modulos pedem, por indice da barra
    property var fitLen: ({})
    function setFit(i, v) {
        if (Math.abs((fitLen[i] ?? -1) - v) < 0.5) return
        const m = Object.assign({}, fitLen); m[i] = v; fitLen = m
    }

    // progresso do seletor de wallpaper (0..1), animado com a mesma curva/duracao das barras
    // paineis acoplados (seletor de wallpaper, launcher e Inicio) nao dividem a moldura: um espera o outro terminar de recolher (sem corte seco)
    readonly property bool pickerDockedAll: Settings.wpPickerDocked
    readonly property bool launcherDockedAll: Settings.launcherDocked
    readonly property bool homeDockedAll: Settings.homeDocked
    property real pickerRaw: Settings.wpPickerOpen && !(pickerDockedAll && ((launcherDockedAll && launcherProg > 0.02) || (homeDockedAll && homeProg > 0.02))) ? 1 : 0
    Behavior on pickerRaw { id: b_pickerProg; MotionAnim { use: "picker"; out: b_pickerProg.targetValue < 0.5 } }
    readonly property real pickerProg: pickerRaw
    // progresso do launcher (0..1) e profundidade do conteudo dele (o Launcher.qml atualiza; a moldura acopla)
    property real launcherRaw: Settings.launcherOpen && !(launcherDockedAll && ((pickerDockedAll && pickerProg > 0.02) || (homeDockedAll && homeProg > 0.02))) ? 1 : 0
    Behavior on launcherRaw { id: b_launcherProg; MotionAnim { use: "launcher"; out: b_launcherProg.targetValue < 0.5 } }
    readonly property real launcherProg: launcherRaw
    property real launcherDepth: 64
    // painel Inicio: tamanho fixo do conteudo e progresso
    readonly property real homeW: 700
    readonly property real homeH: 556
    property real homeRaw: Settings.homeOpen && !(homeDockedAll && ((pickerDockedAll && pickerProg > 0.02) || (launcherDockedAll && launcherProg > 0.02))) ? 1 : 0
    Behavior on homeRaw { id: b_homeProg; MotionAnim { use: "home"; out: b_homeProg.targetValue < 0.5 } }
    readonly property real homeProg: homeRaw
    // notificacoes: quantidade de cartoes (a moldura cresce ate o bloco), progresso e comprimento do bloco ao longo da borda (animados)
    property int notifCount: 0
    property real notifRaw: notifCount > 0 ? 1 : 0
    Behavior on notifRaw { id: b_notifProg; MotionAnim { use: "notifications"; out: b_notifProg.targetValue < 0.5 } }
    readonly property real notifProg: notifRaw
    property real notifLen: 0
    // indicador de volume (OSD): progresso; tamanho fixo do conteudo (comprimento ao longo da borda x profundidade)
    property real osdRaw: Osd.showing ? 1 : 0
    Behavior on osdRaw { id: b_osd; MotionAnim { use: "osd"; out: b_osd.targetValue < 0.5 } }
    readonly property real osdProg: osdRaw
    readonly property real osdDepth: 46
    function osdLen(vertical: bool): real { return vertical ? 210 : 300 }
    property real notifDepth: 0
    function set(i: int, v: real): void {
        const c = Object.assign({}, p)
        c[i] = v
        p = c
    }
}
