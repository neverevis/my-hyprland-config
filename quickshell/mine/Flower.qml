// Forma desenhada (fundo, contorno ou, branca, mascara de imagem): qualquer id de Shapes.qml (flor de petalas ajustaveis,
// circulo, arredondada, quadrada e as 35 do Material 3). Trocar shape/sides/depth anima a forma atual ate a nova (morph,
// como no end4): os raios das duas sao interpolados (shapelib/radial.js), com a curva "shapes" do Motion (velocidade global
// inclusa; duracao quase zero = troca seca). Uma troca no meio do morph parte da forma que esta na tela.
// Parada: caixas (rounded/square/circle) sao um Rectangle e as outras o caminho exato; nada e recalculado por quadro
// (spin gira o item, nao os pontos).
import QtQuick
import QtQuick.Shapes
import "shapelib/radial.js" as R

Item {
    id: f
    property string shape: "flower"
    property int sides: 12
    property real depth: 0.11
    property color color: "white"
    property color border: "transparent"
    property real borderWidth: 0
    property real radius: Math.min(width, height) * 0.22   // so "rounded"
    property real spin: 0                                  // graus
    property bool animated: true                           // false: troca seca
    property bool align: true                              // gira um pouco no morph quando isso encaixa melhor os lobos

    readonly property string sid: R.canon(shape)
    readonly property bool box: R.isBox(sid)
    readonly property bool morphing: anim.running
    readonly property string spec: sid === "flower" ? "flower|" + Math.max(0, sides) + "|" + depth.toFixed(3) : sid

    // ---- estado do morph (raios em unidades do raio do item) ----
    property real k: 1
    property var mFrom: null
    property var mTo: null
    property real mShift: 0
    property var last: null                 // { sid, sides, depth } da forma na tela

    readonly property real rad: Math.max(0.5, Math.min(width, height) / 2 - borderWidth / 2)
    function radialOf(s) {
        const bw = borderWidth / 2
        return R.radial(s.sid, s.sides, s.depth, Math.max(0.01, (width / 2 - bw) / rad), Math.max(0.01, (height / 2 - bw) / rad),
                        Math.max(0, Math.min(radius, Math.min(width, height) / 2) - bw) / rad)
    }
    function retarget() {
        const now = { sid: sid, sides: sides, depth: depth }
        const prev = last
        last = now
        if (!animated || !visible || !prev || width <= 0 || height <= 0 || anim.duration < 20) {
            anim.stop(); mFrom = null; mTo = null
            return
        }
        // parte do que esta na tela: o quadro atual do morph ou a forma parada anterior (com o tamanho de agora)
        const from = anim.running && mFrom && mTo ? R.frame(mFrom, mTo, k, mShift) : radialOf(prev)
        const to = radialOf(now)
        anim.stop()
        mFrom = from; mTo = to
        mShift = align ? R.bestShift(from, to) : 0
        anim.start()
    }
    onSpecChanged: retarget()
    Component.onCompleted: last = { sid: sid, sides: sides, depth: depth }

    MotionAnim { id: anim; use: "shapes"; target: f; property: "k"; from: 0; to: 1 }
    property alias motion: anim             // a animacao do morph (pausar/sincronizar de fora, ex.: testes)

    // caminho em pixels: quadro do morph, ou a forma exata parada (caixa parada: Rectangle)
    readonly property string path: {
        if (width <= 0 || height <= 0) return ""
        const ox = width / 2, oy = height / 2
        if (morphing && mFrom && mTo) return R.polySvg(R.frame(mFrom, mTo, k, mShift), ox, oy, rad)
        if (box) return ""
        return R.restSvg(sid, sides, depth, ox, oy, rad)
    }

    Shape {
        anchors.fill: parent
        visible: !f.box || f.morphing
        rotation: f.spin
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: f.color
            strokeColor: f.borderWidth > 0 ? f.border : "transparent"
            strokeWidth: f.borderWidth
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: f.path }
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: f.box && !f.morphing
        radius: f.sid === "circle" ? Math.min(width, height) / 2 : f.sid === "rounded" ? f.radius : 0
        color: f.color
        border.width: f.borderWidth; border.color: f.border
    }
}
