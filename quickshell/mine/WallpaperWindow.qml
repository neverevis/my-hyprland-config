// Wallpaper por tras de tudo (uma janela por tela, camada Background) com transicoes em QML:
// fade, slide (deslizar), wipe (cortina), circle (circulo que cresce do centro), zoom, none e, com shader (shaders/*.frag),
// dissolve (dissolver com borda acesa), pixelate, ripple (ondas), blinds (persianas) e swirl (redemoinho).
// Os shaders recebem as duas imagens como texturas (ShaderEffectSource, atualizadas so durante a troca).
// Tudo fica num "palco" que recebe desfoque/escurecimento (sempre ou so com janelas no workspace) e a paralaxe por
// workspace (o wallpaper desliza ao trocar de workspace, com a animacao de workspaces). Videos (mp4, webm, mkv, mov)
// fazem a transicao com o primeiro quadro e depois rodam em loop, mudos. Modos: fill (normal), centered (a imagem
// numa forma no centro, sobre a cor do tema) e collage (mosaico).
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import QtMultimedia

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
        WlrLayershell.layer: Wallpaper.peek ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.namespace: "mine-wallpaper"

        property string shown: ""       // imagem totalmente visivel
        property string incoming: ""    // imagem entrando (durante a transicao)
        property string trans: "fade"
        property real progress: 0
        readonly property bool isShader: Wallpaper.shaderTransitions.indexOf(trans) >= 0

        readonly property string target: Wallpaper.preview !== "" ? Wallpaper.preview : Wallpaper.current
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
            if (newImg.status === Image.Ready && newImg.source.toString() === Wallpaper.stillUrl(path)) anim.restart()
        }

        NumberAnimation {
            id: anim
            target: win
            property: "progress"
            from: 0; to: 1
            duration: Wallpaper.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Wallpaper.curve
            onRunningChanged: Wallpaper.busy = running
            onStarted: if (win.isShader) fx.seed = Math.random() * 10
            // a de baixo carrega em segundo plano; a camada nova so some quando ela estiver pronta (sem decodificar na hora e travar)
            onFinished: { win.shown = win.incoming; win.settle() }
        }
        function settle() {
            if (baseImg.status === Image.Ready && baseImg.source.toString() === Wallpaper.stillUrl(shown)) incoming = ""
        }

        // ---- palco: wallpaper + transicoes. Recebe o desfoque/escurecimento e a paralaxe por workspace ----
        readonly property var ws: Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace ? Hyprland.focusedMonitor.activeWorkspace : null
        readonly property int wsCount: Math.max(2, Settings.overviewRows * Settings.overviewCols)
        readonly property real wsFrac: ws ? Math.max(0, Math.min(1, ((ws.id - 1) % wsCount) / (wsCount - 1))) : 0.5
        readonly property real px: Settings.wpWsParallax / 100      // zoom extra que da folga para o deslize
        property real pf: wsFrac
        Behavior on pf { MotionAnim { use: "hyprWorkspaces" } }
        // tem janela no workspace atual? (desfoque so com janelas)
        readonly property bool hasWins: ws ? Hyprland.toplevels.values.some(t => t.workspace && t.workspace.id === ws.id) : false
        readonly property real blurWant: Settings.wpBlurWhen === "always" || (Settings.wpBlurWhen === "windows" && hasWins) ? Settings.wpBlur / 100 : 0
        property real blurV: blurWant
        Behavior on blurV { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        readonly property real dimWant: Settings.wpDimWhen === "always" || (Settings.wpDimWhen === "windows" && hasWins) ? Settings.wpDim / 100 : 0
        property real dimV: dimWant
        Behavior on dimV { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        // desfoque dividido: so uma faixa (25 / 50 % da tela, de um dos lados) fica desfocada, com a borda suave (140 px)
        readonly property real splitFrac: Settings.wpBlurSplit === "25" ? 0.28 : (Settings.wpBlurSplit === "50" ? 0.54 : 1)
        readonly property bool splitOn: splitFrac < 1
        property real core: splitFrac * width
        Behavior on core { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        readonly property real feather: Math.min(140, core)
        Component { id: fullFx; MultiEffect { blurEnabled: true; blur: win.blurV; blurMax: 64; autoPaddingEnabled: false } }
        Component {
            id: splitFx
            Item {
                id: sfx
                property var source
                ShaderEffect { anchors.fill: parent; property var source: sfx.source }
                MultiEffect {
                    anchors.fill: parent
                    source: sfx.source
                    blurEnabled: true; blur: win.blurV; blurMax: 64; autoPaddingEnabled: false
                    maskEnabled: true; maskSource: splitMask
                }
            }
        }
        Item {
            id: splitMask
            x: -win.width - 120      // fora da tela, mas visivel (item invisivel nao atualiza a textura)
            width: win.width; height: win.height
            layer.enabled: true
            readonly property real a: Math.max(0, (win.core - win.feather) / Math.max(1, win.width))
            readonly property real b: Math.min(1, win.core / Math.max(1, win.width))
            readonly property bool atLeft: Settings.wpBlurSide !== "right"
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: splitMask.atLeft ? "white" : "transparent" }
                    GradientStop { position: splitMask.atLeft ? splitMask.a : 1 - splitMask.b; color: splitMask.atLeft ? "white" : "transparent" }
                    GradientStop { position: splitMask.atLeft ? splitMask.b : 1 - splitMask.a; color: splitMask.atLeft ? "transparent" : "white" }
                    GradientStop { position: 1; color: splitMask.atLeft ? "transparent" : "white" }
                }
            }
        }

        // centralizado so na tela de bloqueio: 0 = a forma no centro (bloqueado), 1 = a forma cobre a tela (o wallpaper normal)
        readonly property bool lockedOnly: Settings.wpMode === "centered" && Settings.wpCenterLocked
        property real cp: lockedOnly && !Power.locked ? 1 : 0
        Behavior on cp { NumberAnimation { duration: Power.locked ? 650 : 800; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1] } }

        Item {
            id: stage
            width: win.width; height: win.height
            visible: Settings.wpMode === "fill" || (win.lockedOnly && win.cp > 0.001)
            transform: [
                Scale { origin.x: win.width / 2; origin.y: win.height / 2; xScale: 1 + win.px; yScale: 1 + win.px },
                Translate { x: Settings.wpWsVertical ? 0 : (0.5 - win.pf) * win.px * win.width; y: Settings.wpWsVertical ? (0.5 - win.pf) * win.px * win.height : 0 }
            ]
            layer.enabled: win.blurV > 0.002
            layer.effect: win.splitOn ? splitFx : fullFx

            // pre-carga da proxima imagem provavel (mantem a imagem decodificada no cache)
            Image {
                visible: false
                source: Wallpaper.preload !== "" ? Wallpaper.stillUrl(Wallpaper.preload) : ""
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
                source: win.shown !== "" ? Wallpaper.stillUrl(win.shown) : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.width, win.height)
                asynchronous: true
                smooth: true
                onStatusChanged: if (!anim.running && win.incoming !== "" && win.shown === win.incoming) win.settle()
            }

            // imagem entrando: um Image so, que muda de "pai" conforme a transicao (assim carrega uma vez):
            //   circulo: dentro de newWrap (vira textura para a mascara redonda do MultiEffect)
            //   cortina: dentro de um recorte girado (sem texturas extras: barato para a GPU)
            //   fade / deslizar / zoom: direto na camada nova
            Image {
                id: newImg
                parent: win.trans === "circle" ? newWrap : (win.trans === "wipe" ? wipeInner : plainNew)
                x: win.trans === "wipe" ? win.ox - wipeClip.x : 0
                y: win.trans === "wipe" ? win.oy - wipeClip.y : 0
                width: win.width; height: win.height
                scale: win.trans === "wipe" ? 1 + 2 * (1 - win.progress) * win.newK * win.kmax * win.zoomW
                    : (win.trans === "circle" ? 1 + (1 - win.progress) * win.sK * 1.25 : 1)
                source: win.incoming !== "" ? Wallpaper.stillUrl(win.incoming) : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.width, win.height)
                asynchronous: true
                smooth: true
                onStatusChanged: if (status === Image.Ready && win.incoming !== "" && !anim.running) anim.restart()
            }
            // cortina: a imagem nova tambem anda na direcao da cortina, mais devagar que a borda (deslocamento o)
            readonly property real ox: trans === "wipe" ? -(1 - progress) * newK * dx : 0
            readonly property real oy: trans === "wipe" ? -(1 - progress) * newK * dy : 0

            Item {   // fonte do circulo (fora da tela, mas visivel: item invisivel nao atualiza a textura)
                id: newWrap
                x: -win.width - 60
                clip: true
                width: win.width; height: win.height
                // camada sempre ligada: ligar/desligar a cada troca deixava o MultiEffect com a textura velha (o circulo nao crescia mais)
                layer.enabled: true
            }

            Item {
                id: layerNew
                visible: win.incoming !== ""
                height: win.height
                clip: true
                // slide: entra pela direita
                width: win.width
                x: win.trans === "slide" ? (1 - win.progress) * win.width : 0
                // com shader a camada nova fica opaca por baixo do efeito (que cobre a tela): com opacidade 0 o Qt deixa de
                // desenhar esse ramo e o shader recebia uma textura vazia (flash escuro)
                opacity: win.isShader ? 1 : (win.trans === "fade" || win.trans === "zoom" ? win.progress : 1)
                scale: win.trans === "zoom" ? 1.1 - 0.1 * win.progress : 1

                Item { id: plainNew; width: win.width; height: win.height; visible: win.trans !== "circle" && win.trans !== "wipe" }

                // cortina em qualquer angulo: um quadrado enorme girado recorta a tela; a borda da frente e a linha da cortina
                Item {
                    id: wipeClip
                    visible: win.trans === "wipe"
                    readonly property real len: win.diag * 3
                    width: len; height: len
                    x: win.edgeS * win.dx - win.dx * len / 2 - len / 2
                    y: win.edgeS * win.dy - win.dy * len / 2 - len / 2
                    rotation: Settings.wpWipeAngle
                    clip: true
                    Item {   // desfaz o giro: dentro dele as coordenadas sao as da tela, deslocadas pelo canto do recorte
                        id: wipeInner
                        width: wipeClip.len; height: wipeClip.len
                        rotation: -Settings.wpWipeAngle
                    }
                }

                MultiEffect {
                    visible: win.trans === "circle"
                    width: win.width; height: win.height
                    source: newWrap
                    maskEnabled: true
                    maskSource: circleMask
                }
            }

            // mascara do circulo (cresce do centro da tela)
            Item {
                id: circleMask
                x: -win.width - 50        // fora da tela, mas visivel: item invisivel nao atualiza a textura da mascara
                clip: true                // o circulo grande nao vaza para dentro da tela
                layer.enabled: true       // sempre ligada (mesmo motivo do newWrap); so redesenha quando o circulo muda
                width: win.width; height: win.height
                Rectangle {
                    readonly property real d: win.diag * win.progress
                    width: d; height: d; radius: d / 2
                    x: win.width / 2 - d / 2
                    y: win.height / 2 - d / 2
                    color: "white"
                }
            }

            // ---- transicoes com shader: as duas imagens viram texturas e o shader mistura ----
            // texturas vivas so durante a troca (tirar uma copia so, de forma assincrona, deixava o primeiro quadro com a
            // textura da troca anterior: piscava o wallpaper velho)
            ShaderEffectSource { id: fromTex; sourceItem: baseImg; live: win.isShader && win.incoming !== ""; hideSource: false; x: -4; width: 1; height: 1 }
            ShaderEffectSource { id: toTex; sourceItem: newImg; live: win.isShader && win.incoming !== ""; hideSource: false; x: -4; width: 1; height: 1 }
            ShaderEffect {
                id: fx
                visible: win.isShader && win.incoming !== ""
                width: win.width; height: win.height
                property var source: fromTex   // o shader padrao (sem fragmentShader) procura "source"
                property var src1: fromTex
                property var src2: toTex
                property real progress: win.progress
                property real aspect: width / Math.max(1, height)
                property real seed: 0
                property color glow: Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, 0.9)
                fragmentShader: win.isShader ? Qt.resolvedUrl("shaders/" + win.trans + ".frag.qsb") : ""
            }

            // video: depois da transicao (feita com o primeiro quadro), o video aparece por cima e roda em loop.
            // So existe com wallpaper de video: o player carrega o decodificador (ffmpeg, CUDA, Mesa) e custa ~150 MB
            Loader {
                anchors.fill: parent
                active: Wallpaper.isVideo(win.shown)
                sourceComponent: Video {
                id: vid
                anchors.fill: parent
                readonly property bool on: Wallpaper.isVideo(win.shown) && win.incoming === ""
                source: on ? "file://" + win.shown : ""
                loops: MediaPlayer.Infinite
                muted: true
                fillMode: VideoOutput.PreserveAspectCrop
                opacity: on && playbackState === MediaPlayer.PlayingState ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
                // parado com janela em tela cheia (ou sempre, se escolhido) para economizar a placa de video
                readonly property bool hold: Wallpaper.videoPaused || Settings.wpVideoPause && win.ws && Hyprland.toplevels.values.some(t => t.workspace && t.workspace.id === win.ws.id && t.lastIpcObject && t.lastIpcObject.fullscreen > 0)
                autoPlay: true
                onSourceChanged: if (source.toString() !== "") Qt.callLater(play)
                onHoldChanged: if (on) { if (hold) pause(); else play() }
                }
            }
        }
        // escurecer (por cima do palco)
        Rectangle { anchors.fill: parent; color: "black"; opacity: win.dimV; visible: opacity > 0.002 && Settings.wpMode === "fill" }

        // ---- modos alternativos: centralizado numa forma e mosaico (sobre a cor do tema) ----
        Rectangle {
            anchors.fill: parent
            visible: Settings.wpMode !== "fill" && win.cp < 0.999
            opacity: win.lockedOnly ? 1 - Math.max(0, (win.cp - 0.9) / 0.1) : 1
            color: Theme.role(Settings.wpBgRole)
            Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 600 } }
            ShapedImage {
                id: centerImg
                visible: Settings.wpMode === "centered"
                readonly property real d: Math.min(win.width, win.height) * Settings.wpCenterSize / 100
                readonly property real cover: Math.hypot(win.width, win.height) * 1.5
                width: d; height: d
                scale: 1 + (cover / d - 1) * Math.min(1, win.cp)
                anchors.centerIn: parent
                shape: Settings.wpCenterShape; sides: Settings.wpCenterSides
                source: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
                sourceSize: Qt.size(d * 1.5, d * 1.5)
                RotationAnimation on spin { running: Settings.wpCenterSpin && centerImg.visible; from: 0; to: 360; duration: 120000; loops: Animation.Infinite }
            }
            // mosaico em arvore (Collage.qml): fundo = a imagem principal desfocada, e as imagens entram voando
            Image {
                id: colBack
                anchors.fill: parent
                visible: Settings.wpMode === "collage"
                readonly property string pri: { const l = col.pics; const i = (Collage.leafRects ?? []).findIndex(r => r.id === Collage.primary); return l[i >= 0 ? i : 0] ?? "" }
                source: pri ? Wallpaper.stillUrl(pri) : ""
                sourceSize: Qt.size(win.width / 4, win.height / 4)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                layer.enabled: visible
                layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 48; autoPaddingEnabled: false; brightness: -0.22 }
            }
            Item {
                id: col
                visible: Settings.wpMode === "collage"
                anchors.fill: parent
                anchors.margins: Settings.wpCollageMargin
                readonly property var rects: Collage.leafRects ?? []
                readonly property var pics: {
                    const out = rects.map(r => r.img)
                    const used = out.filter(x => x)
                    let i = Wallpaper.indexOfCurrent()
                    if (!out[0] && Wallpaper.current !== "") out[0] = Wallpaper.current   // a primeira vazia = o wallpaper atual
                    for (let k = 0; k < out.length; k++) {
                        let guard = 0
                        while (!out[k] && Wallpaper.files.length > 1 && guard++ < Wallpaper.files.length) { i = (i + 1) % Wallpaper.files.length; const p = Wallpaper.files[i].path; if (out.indexOf(p) < 0) out[k] = p }
                    }
                    return out
                }
                Repeater {
                    model: col.rects.length
                    delegate: RoundImage {
                        id: tile
                        required property int index
                        readonly property var r: col.rects[index] ?? { x: 0, y: 0, w: 1, h: 1 }
                        readonly property real g: Settings.wpCollageGap / 2
                        property real ent: Settings.wpCollageEntrance ? 0 : 1
                        // entrada: cada imagem vem de uma direcao, pequena, e assenta no lugar
                        readonly property real ang: (index * 2.399 + 0.7)
                        NumberAnimation on ent { running: Settings.wpCollageEntrance; from: 0; to: 1; duration: 520 + index * 70; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
                        x: r.x * col.width + g + (1 - ent) * Math.cos(ang) * win.width * 0.5
                        y: r.y * col.height + g + (1 - ent) * Math.sin(ang) * win.height * 0.5
                        width: r.w * col.width - 2 * g; height: r.h * col.height - 2 * g
                        scale: 0.25 + 0.75 * ent
                        opacity: Math.min(1, ent * 2)
                        radius: Settings.wpCollageRadius
                        source: col.pics[index] ? Wallpaper.stillUrl(col.pics[index]) : ""
                        sourceSize: Qt.size(width, height)
                    }
                }
            }
        }
    }
}
