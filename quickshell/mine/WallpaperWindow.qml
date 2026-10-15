// Wallpaper por tras de tudo (uma janela por tela, camada Background) com transicoes em QML:
// fade, slide (deslizar), wipe (cortina), circle (circulo que cresce do centro), zoom, none.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "black"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "mine-wallpaper"

        property string shown: ""       // imagem totalmente visivel
        property string incoming: ""    // imagem entrando (durante a transicao)
        property string trans: "fade"
        property real progress: 0

        readonly property string target: Wallpaper.current
        readonly property int diag: Math.ceil(Math.hypot(width, height))

        // ---- cortina em qualquer angulo: a borda varre a tela na direcao d; os wallpapers andam junto (paralaxe) ----
        readonly property real wa: Settings.wpWipeAngle * Math.PI / 180
        readonly property real dx: Math.cos(wa)
        readonly property real dy: Math.sin(wa)
        readonly property real pLo: Math.min(0, width * dx, height * dy, width * dx + height * dy)   // extensao da tela projetada em d
        readonly property real pHi: Math.max(0, width * dx, height * dy, width * dx + height * dy)
        readonly property real ext: pHi - pLo
        readonly property real edgeS: pLo + progress * ext                                            // posicao da borda
        readonly property real oldK: ext * Settings.wpParallax / 100                                  // deslocamento maximo do antigo
        // nas diagonais os deslocamentos deixariam cantos descobertos: um zoom minimo (so quando o angulo nao e reto) cobre
        readonly property real kmax: Math.max(Math.abs(dx) / width, Math.abs(dy) / height)
        readonly property real zoomW: Math.min(1, 4 * Math.abs(dx * dy))
        // circulo: mesma ideia, mas em escala (o antigo cresce, o novo assenta de um pouco maior ate o tamanho certo)
        readonly property real sK: Settings.wpParallax / 100 * 0.5
        readonly property real newK: oldK * 1.25                                                      // e do novo (um pouco mais, chega ao lugar no fim)

        onTargetChanged: go(target)
        Component.onCompleted: go(target)

        function go(path) {
            if (path === "" || path === shown) return
            if (anim.running) anim.complete()          // termina a transicao anterior
            if (shown === "" || Settings.wpTransition === "none" || Wallpaper.duration <= 0) { shown = path; return }
            trans = Wallpaper.pickTransition()
            progress = 0
            incoming = path                              // a animacao comeca quando a imagem carregar
            if (newImg.status === Image.Ready && newImg.source.toString() === "file://" + path) anim.restart()
        }

        NumberAnimation {
            id: anim
            target: win
            property: "progress"
            from: 0; to: 1
            duration: Wallpaper.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Wallpaper.curve
            onFinished: { win.shown = win.incoming; win.incoming = "" }
        }

        // pre-carga da proxima imagem provavel (mantem a imagem decodificada no cache)
        Image {
            visible: false
            source: Wallpaper.preload !== "" ? "file://" + Wallpaper.preload : ""
            sourceSize: Qt.size(win.width, win.height)
            asynchronous: true
        }

        // imagem atual (embaixo)
        Image {
            id: baseImg
            width: win.width; height: win.height
            // slide: a atual recua um pouco; cortina: a atual anda na mesma direcao da cortina, mais devagar (paralaxe)
            x: win.incoming === "" ? 0 : (win.trans === "slide" ? -win.progress * win.width * 0.3
                : (win.trans === "wipe" ? win.progress * win.oldK * win.dx : 0))
            y: win.incoming !== "" && win.trans === "wipe" ? win.progress * win.oldK * win.dy : 0
            scale: win.incoming === "" ? 1 : (win.trans === "wipe" ? 1 + 2 * win.progress * win.oldK * win.kmax * win.zoomW
                : (win.trans === "circle" ? 1 + win.progress * win.sK : 1))
            source: win.shown !== "" ? "file://" + win.shown : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.width, win.height)
            asynchronous: false
            smooth: true
        }

        // imagem entrando: carregada aqui (fora da tela, mas visivel) e mostrada pelo MultiEffect abaixo (que tambem aplica as mascaras);
        // o zoom de cobertura da cortina acontece aqui dentro, para a mascara nao escalar junto
        Item {
            id: newWrap
            x: -win.width - 60
            width: win.width; height: win.height
            layer.enabled: true
            Image {
                id: newImg
                anchors.centerIn: parent
                width: win.width; height: win.height
                scale: win.trans === "wipe" ? 1 + 2 * (1 - win.progress) * win.newK * win.kmax * win.zoomW
                    : (win.trans === "circle" ? 1 + (1 - win.progress) * win.sK * 1.25 : 1)
                source: win.incoming !== "" ? "file://" + win.incoming : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.width, win.height)
                asynchronous: true
                smooth: true
                onStatusChanged: if (status === Image.Ready && win.incoming !== "" && !anim.running) anim.restart()
            }
        }

        Item {
            id: layerNew
            visible: win.incoming !== ""
            height: win.height
            clip: true
            // slide: entra pela direita
            width: win.width
            x: win.trans === "slide" ? (1 - win.progress) * win.width : 0
            opacity: win.trans === "fade" || win.trans === "zoom" ? win.progress : 1
            scale: win.trans === "zoom" ? 1.1 - 0.1 * win.progress : 1

            MultiEffect {
                // cortina: a imagem nova tambem anda na direcao da cortina, mais devagar que a borda (a mascara acompanha o deslocamento)
                x: win.trans === "wipe" ? -(1 - win.progress) * win.newK * win.dx : 0
                y: win.trans === "wipe" ? -(1 - win.progress) * win.newK * win.dy : 0
                width: win.width; height: win.height
                source: newWrap
                maskEnabled: win.trans === "circle" || win.trans === "wipe"
                maskSource: win.trans === "wipe" ? wipeMask : circleMask
            }
        }

        // mascara da cortina: um retangulo girado cuja borda da frente e a linha da cortina (em coordenadas da imagem nova, ja deslocada)
        Item {
            id: wipeMask
            x: -win.width - 50
            layer.enabled: true
            width: win.width; height: win.height
            Rectangle {
                readonly property real len: win.diag * 3
                readonly property real qx: win.edgeS * win.dx + (1 - win.progress) * win.newK * win.dx   // ponto da borda no sistema da imagem
                readonly property real qy: win.edgeS * win.dy + (1 - win.progress) * win.newK * win.dy
                width: len; height: len
                x: qx - win.dx * len / 2 - len / 2
                y: qy - win.dy * len / 2 - len / 2
                rotation: Settings.wpWipeAngle
                color: "white"
            }
        }

        // mascara do circulo (cresce do centro da tela)
        Item {
            id: circleMask
            x: -win.width - 50        // fora da tela, mas visivel: item invisivel nao atualiza a textura da mascara
            layer.enabled: true
            width: win.width; height: win.height
            Rectangle {
                readonly property real d: win.diag * win.progress
                width: d; height: d; radius: d / 2
                x: win.width / 2 - d / 2
                y: win.height / 2 - d / 2
                color: "white"
            }
        }
    }
}
