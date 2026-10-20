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
        if (p.kind === "tip" ? !Settings.barTips : !Settings.barPopups) return
        popPending = p; popHideT.stop()
        if (pop) pop = p      // ja aberto: troca na hora (passar de um modulo para o outro)
        else popShowT.restart()
    }
    function popLeave() { popShowT.stop(); popHideT.restart() }
    onPopHoverChanged: if (!popHover) popHideT.restart(); else popHideT.stop()
    // dica de texto (kind "tip"): qualquer modulo/botao chama tipEnter(texto, lado, retangulo na tela) ao passar o mouse e popLeave() ao sair
    function tipEnter(text, side, rect) {
        if (!text) return
        popEnter({ kind: "tip", text: text, side: side, rect: rect, opts: ({}) })
    }
    // mostrar / esconder todas as barras (IPC "bar"; nao e salvo)
    property bool barsOpen: true
    // Super segurado (IPC "bar superdown" / "bar superup", ligados a uma tecla no Hyprland): depois de Settings.superDelay revela as barras
    // escondidas e os workspaces mostram numeros. A trava de 20 s evita ficar preso se o "superup" nunca chegar.
    property bool superHeld: false
    property bool superDown: false
    function superSet(on) {
        superHeld = on
        if (on) { superT.restart(); superSafe.restart() } else { superT.stop(); superSafe.stop(); superDown = false }
    }
    Timer { id: superT; interval: Math.max(0, Settings.superDelay); onTriggered: bs.superDown = bs.superHeld }
    Timer { id: superSafe; interval: 20000; onTriggered: bs.superSet(false) }
    // mouse encostado na borda de cada lado (faixa fina, ver EdgeReveal em shell.qml): revela a barra escondida daquele lado
    property var edgeHover: ({ top: false, right: false, bottom: false, left: false })
    function setEdge(side, on) {
        if (edgeHover[side] === on) return
        const c = Object.assign({}, edgeHover); c[side] = on; edgeHover = c
    }
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
    readonly property bool leftDockedAll: Settings.leftDocked
    property real pickerRaw: Settings.wpPickerOpen && !(pickerDockedAll && ((launcherDockedAll && launcherProg > 0.02) || (homeDockedAll && homeProg > 0.02) || (leftDockedAll && leftProg > 0.02))) ? 1 : 0
    Behavior on pickerRaw { id: b_pickerProg; MotionAnim { use: "picker"; out: b_pickerProg.targetValue < 0.5 } }
    readonly property real pickerProg: pickerRaw
    // progresso do launcher (0..1) e profundidade do conteudo dele (o Launcher.qml atualiza; a moldura acopla)
    property real launcherRaw: Settings.launcherOpen && !(launcherDockedAll && ((pickerDockedAll && pickerProg > 0.02) || (homeDockedAll && homeProg > 0.02) || (leftDockedAll && leftProg > 0.02))) ? 1 : 0
    Behavior on launcherRaw { id: b_launcherProg; MotionAnim { use: "launcher"; out: b_launcherProg.targetValue < 0.5 } }
    readonly property real launcherProg: launcherRaw
    property real launcherDepth: 64
    // painel Inicio: tamanho fixo do conteudo e progresso
    readonly property real homeW: 700
    readonly property real homeH: 556
    property real homeRaw: Settings.homeOpen && !(homeDockedAll && ((pickerDockedAll && pickerProg > 0.02) || (launcherDockedAll && launcherProg > 0.02) || (leftDockedAll && leftProg > 0.02))) ? 1 : 0
    Behavior on homeRaw { id: b_homeProg; MotionAnim { use: "home"; out: b_homeProg.targetValue < 0.5 } }
    readonly property real homeProg: homeRaw
    // barra lateral esquerda (IA, tradutor): acoplada na borda esquerda, como o Inicio
    property bool leftWide: false
    property real leftW: leftWide ? 760 : 520
    Behavior on leftW { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    readonly property real leftH: 680
    property real leftRaw: Settings.leftOpen && !(leftDockedAll && ((pickerDockedAll && pickerProg > 0.02) || (launcherDockedAll && launcherProg > 0.02) || (homeDockedAll && homeProg > 0.02))) ? 1 : 0
    Behavior on leftRaw { id: b_leftProg; MotionAnim { use: "home"; out: b_leftProg.targetValue < 0.5 } }
    readonly property real leftProg: leftRaw
    // notificacoes: quantidade de cartoes (a moldura cresce ate o bloco), progresso e comprimento do bloco ao longo da borda (animados)
    property int notifCount: 0
    property int notifLive: 0   // notificacoes ainda na tela (mesmo se a ilha dinamica mostra no lugar dos cartoes)
    property real notifRaw: notifCount > 0 ? 1 : 0
    Behavior on notifRaw { id: b_notifProg; MotionAnim { use: "notifications"; out: b_notifProg.targetValue < 0.5 } }
    readonly property real notifProg: notifRaw
    property real notifLen: 0
    // indicador de volume (OSD): progresso; tamanho fixo do conteudo (comprimento ao longo da borda x profundidade)
    property real osdRaw: Osd.showing && !Settings.islandOsd ? 1 : 0
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
