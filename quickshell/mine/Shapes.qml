// Formas para recortar imagens e desenhar fundos (Flower.qml desenha e anima a troca entre elas).
// As 35 formas do Material 3 (as mesmas do end4) saem de shapelib/m3shapes.js (porte do RoundedPolygon do androidx);
// shapelib/radial.js transforma cada uma em raios para o morph e em caminho exato para desenhar parada.
// Proprias do shell: rounded (retangulo arredondado, raio do item), square (quadrado reto = sem recorte) e flower (flor de
// petalas e fundura ajustaveis, a do relogio). O Square do M3 aqui e "softsquare". Ids antigos: ghost -> ghostish, pixel -> pixelcircle.
// list: [id, rotulo, icone] para os menus; pts(id) devolve [[x, y], ...] num quadrado de -1 a 1 (y para baixo).
pragma Singleton

import Quickshell
import QtQuick
import "shapelib/radial.js" as R

Singleton {
    id: root
    readonly property var list: [
        ["rounded", "Arredondada", "squareRounded"], ["circle", "Círculo", "circleOutline"], ["flower", "Flor", "flowerOutline"], ["square", "Quadrada", "squareOutline"],
        ["softsquare", "Quadrado suave", "squareRounded"], ["cookie4", "Biscoito 4", "cookie"], ["cookie6", "Biscoito 6", "cookie"], ["cookie7", "Biscoito 7", "cookie"],
        ["cookie9", "Biscoito 9", "cookie"], ["cookie12", "Biscoito 12", "cookie"], ["clover4", "Trevo", "clover"], ["clover8", "Trevo de 8", "clover"],
        ["flower8", "Flor de 8", "flower"], ["sunny", "Sol", "sun"], ["verysunny", "Sol radiante", "sun"], ["burst", "Explosão", "starFourOutline"],
        ["softburst", "Explosão suave", "starFourOutline"], ["boom", "Estouro", "firework"], ["softboom", "Estouro suave", "firework"], ["puffy", "Nuvem", "cloud"],
        ["puffydiamond", "Losango fofo", "cardsDiamond"], ["oval", "Oval", "ellipseOutline"], ["pill", "Pílula", "pill"], ["heart", "Coração", "heart"],
        ["gem", "Gema", "hexagonOutline"], ["diamond", "Losango", "rhombusOutline"], ["triangle", "Triângulo", "triangleOutline"], ["pentagon", "Pentágono", "pentagonOutline"],
        ["slanted", "Inclinada", "shape"], ["arch", "Arco", "shieldOutline"], ["semicircle", "Meio círculo", "circleSlice"], ["clamshell", "Concha", "seal"],
        ["fan", "Leque", "fan"], ["arrow", "Seta", "arrowUpBold"], ["ghostish", "Fantasminha", "ghostOutline"], ["bun", "Pão", "breadSlice"],
        ["pixelcircle", "Pixel", "dotsGrid"], ["pixeltriangle", "Triângulo pixel", "dotsGrid"]
    ]
    // ids validos (antigos convertidos): canon("ghost") = "ghostish"; desconhecido vira "circle"
    function canon(id) { return R.canon(id) }
    // as que o Flower desenha com Rectangle quando paradas (preenchem o retangulo inteiro)
    function isBox(id) { return R.isBox(id) }
    function label(id) { const c = R.canon(id); const e = list.find(x => x[0] === c); return e ? e[1] : "" }
    function pts(id, sides, depth) { return R.contour(id, sides, depth) }
    // raios para o morph (veja shapelib/radial.js)
    function radial(id, sides, depth) { return R.radial(id, sides, depth) }
}
