// Miniatura esquematica da composicao: a tela, a moldura (se tiver contorno) e cada parte acoplada (saindo da
// moldura, com as curvas de encaixe) ou solta (cartao com folga). dock: { bars, launcher, notifications, osd } -> bool.
// Sem "dock" usa o estado atual das configuracoes.
import QtQuick

Rectangle {
    id: pv
    property var dock: null
    property bool outline: Settings.outline
    readonly property var d: dock ?? ({ bars: Settings.partDocked("bars"), launcher: Settings.partDocked("launcher"), notifications: Settings.partDocked("notifications"), osd: Settings.partDocked("osd") })
    readonly property real k: width / 320
    readonly property color frameC: Qt.rgba(Settings.barColor.r, Settings.barColor.g, Settings.barColor.b, 1)
    readonly property real ed: Math.max(2, 4 * k)
    width: 320; height: width * 9 / 16
    radius: 10 * k
    clip: true
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Qt.darker(Settings.accent, 2.6) }
        GradientStop { position: 1; color: Qt.darker(Settings.accent, 4.2) }
    }
    // moldura
    Rectangle {
        anchors.fill: parent
        visible: pv.outline
        color: "transparent"
        radius: pv.radius
        border.width: pv.ed; border.color: pv.frameC
    }
    // janela de exemplo
    Rectangle {
        x: 26 * pv.k; y: 22 * pv.k; width: 150 * pv.k; height: 92 * pv.k; radius: 6 * pv.k
        color: Qt.rgba(1, 1, 1, 0.07); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)
    }

    // parte acoplada (sai da borda, com as curvas) ou solta (afastada)
    component Part: Item {
        id: p
        property string side: "bottom"
        property bool docked: true
        property real len: 80      // ao longo da borda (unidades da miniatura)
        property real dep: 12      // profundidade
        property real at: 0.5      // posicao ao longo da borda (0..1)
        property color tint: pv.frameC
        readonly property bool vert: side === "left" || side === "right"
        property real lift: 0      // afastamento extra da borda (empilhar sobre outra parte)
        readonly property real ll: len * pv.k
        readonly property real dd: dep * pv.k
        readonly property real gap: docked ? 0 : 7 * pv.k
        readonly property real base: docked ? 0 : (pv.outline ? pv.ed : 0)
        readonly property real cx: (vert ? pv.height : pv.width) * at - ll / 2
        x: side === "left" ? base + gap + lift : side === "right" ? pv.width - base - gap - dd - lift : cx
        y: side === "top" ? base + gap + lift : side === "bottom" ? pv.height - base - gap - dd - lift : cx
        width: vert ? dd : ll
        height: vert ? ll : dd
        Rectangle {
            anchors.fill: parent
            radius: Math.min(width, height) * (p.docked ? 0.35 : 0.42)
            color: p.tint
            border.width: p.docked ? 0 : 1; border.color: Qt.rgba(1, 1, 1, 0.14)
        }
        // acoplada: o lado que toca a borda fica reto (emenda com a moldura)
        Rectangle {
            visible: p.docked
            color: p.tint
            x: p.side === "right" ? parent.width / 2 : 0
            y: p.side === "bottom" ? parent.height / 2 : 0
            width: p.vert ? parent.width / 2 : parent.width
            height: p.vert ? parent.height : parent.height / 2
        }
        // curvas de encaixe (cantinhos concavos) nas duas pontas
        Repeater {
            model: p.docked ? 2 : 0
            delegate: Canvas {
                required property int index
                readonly property real f: 4 * pv.k
                width: f; height: f
                x: p.vert ? (p.side === "left" ? 0 : p.width - f) : (index === 0 ? -f : p.width)
                y: p.vert ? (index === 0 ? -f : p.height) : (p.side === "top" ? 0 : p.height - f)
                onPaint: {
                    const c = getContext("2d"); c.reset(); c.fillStyle = p.tint
                    // quadrado menos um quarto de circulo (o canto oposto a parte)
                    const ox = p.vert ? (p.side === "left" ? f : 0) : (index === 0 ? 0 : f)
                    const oy = p.vert ? (index === 0 ? 0 : f) : (p.side === "top" ? f : 0)
                    c.beginPath(); c.rect(0, 0, f, f); c.moveTo(ox, oy); c.arc(ox, oy, f, 0, Math.PI * 2, true); c.fill("evenodd")
                }
            }
        }
    }

    Part { side: "bottom"; docked: pv.d.bars; len: 104; dep: 11; at: 0.5 }
    Part { side: "bottom"; docked: pv.d.launcher; len: 70; dep: 40; at: 0.5; tint: Qt.lighter(pv.frameC, 1.25); z: 2; lift: (docked ? 11 : 18) * pv.k }
    Part { side: "right"; docked: pv.d.notifications; len: 46; dep: 46; at: 0.2 }
    Part { side: "right"; docked: pv.d.osd; len: 50; dep: 11; at: 0.66; tint: Qt.lighter(pv.frameC, 1.15) }
}
