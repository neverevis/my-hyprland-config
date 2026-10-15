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
            x: win.incoming !== "" && win.trans === "slide" ? -win.progress * win.width * 0.3 : 0
            source: win.shown !== "" ? "file://" + win.shown : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.width, win.height)
            asynchronous: false
            smooth: true
        }

        // imagem entrando: carregada aqui (oculta) e mostrada pelo MultiEffect abaixo (que tambem aplica a mascara do circulo)
        Image {
            id: newImg
            visible: false
            width: win.width; height: win.height
            source: win.incoming !== "" ? "file://" + win.incoming : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.width, win.height)
            asynchronous: true
            smooth: true
            onStatusChanged: if (status === Image.Ready && win.incoming !== "" && !anim.running) anim.restart()
        }

        Item {
            id: layerNew
            visible: win.incoming !== ""
            height: win.height
            clip: true
            // wipe: a "cortina" abre da esquerda para a direita; slide: entra pela direita
            width: win.trans === "wipe" ? win.progress * win.width : win.width
            x: win.trans === "slide" ? (1 - win.progress) * win.width : 0
            opacity: win.trans === "fade" || win.trans === "zoom" ? win.progress : 1
            scale: win.trans === "zoom" ? 1.1 - 0.1 * win.progress : 1

            MultiEffect {
                x: 0; y: 0
                width: win.width; height: win.height
                source: newImg
                maskEnabled: win.trans === "circle"
                maskSource: circleMask
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
