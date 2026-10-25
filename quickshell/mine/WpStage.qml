// WpStage: palco 16:9 que ensaia a transicao de wallpaper de verdade (imagens reais, mesmos shaders e mesma geometria
// do WallpaperWindow). Loop: segura na imagem A, A->B, segura, B->A... Existe um so; nada anima fora de "active"
// e nos intervalos de espera so um Timer roda (sem quadros). As texturas do shader so ficam vivas durante a troca.
import QtQuick
import QtQuick.Effects

Item {
    id: st
    property string sel: "fade"        // transicao escolhida (random sorteia dentre a lista; none corta)
    property bool active: true
    readonly property var pool: ["fade", "slide", "wipe", "circle", "zoom", "dissolve", "ripple", "swirl"]
    property int rnd: 0
    property string trans: "fade"
    property real progress: 0
    property bool playing: false
    property bool fwd: true
    property int plays: 4               // trocas que ainda toca; depois para (sem quadros) ate trocar a escolha, passar o mouse ou clicar
    readonly property bool isShader: Wallpaper.shaderTransitions.indexOf(trans) >= 0

    readonly property int fi: Wallpaper.files.findIndex(f => f.path === Wallpaper.current)
    readonly property string urlA: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
    readonly property string urlB: Wallpaper.files.length > 1 ? Wallpaper.stillUrl(Wallpaper.files[(Math.max(0, fi) + 1) % Wallpaper.files.length].path) : urlA
    readonly property string lowerUrl: fwd ? urlA : urlB
    readonly property string upperUrl: fwd ? urlB : urlA

    width: 420
    height: Math.round(width * 9 / 16)

    // geometria igual a do WallpaperWindow (cortina em qualquer angulo, paralaxe, circulo)
    readonly property int diag: Math.ceil(Math.hypot(width, height))
    readonly property real wa: Settings.wpWipeAngle * Math.PI / 180
    readonly property real dx: Math.cos(wa)
    readonly property real dy: Math.sin(wa)
    readonly property real pLo: Math.min(0, width * dx, height * dy, width * dx + height * dy)
    readonly property real pHi: Math.max(0, width * dx, height * dy, width * dx + height * dy)
    readonly property real ext: pHi - pLo
    readonly property real edgeS: pLo + progress * ext
    readonly property real oldK: ext * Settings.wpParallax / 100
    readonly property real kmax: Math.max(Math.abs(dx) / width, Math.abs(dy) / height)
    readonly property real zoomW: Math.min(1, 4 * Math.abs(dx * dy))
    readonly property real sK: Settings.wpParallax / 100 * 0.5
    readonly property real newK: oldK * 1.25

    onSelChanged: restartLoop()
    onActiveChanged: if (!active) { anim.stop(); playing = false; progress = 0 }
    function restartLoop() {
        anim.stop(); playing = false; progress = 0; plays = 4
        hold.interval = 250; hold.restart()
    }

    Timer {
        id: hold
        interval: 700
        running: st.active && !st.playing && st.plays > 0
        repeat: false
        onTriggered: {
            interval = 700
            if (st.sel === "none" || Wallpaper.duration <= 0) { st.fwd = !st.fwd; st.plays--; restart(); return }
            st.trans = st.sel === "random" ? st.pool[st.rnd++ % st.pool.length] : st.sel
            st.progress = 0
            fx.seed = Math.random() * 10
            st.playing = true
            anim.restart()
        }
    }
    NumberAnimation {
        id: anim
        target: st
        property: "progress"
        from: 0; to: 1
        duration: Math.max(1, Wallpaper.duration)
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Wallpaper.curve
        onFinished: { st.fwd = !st.fwd; st.progress = 0; st.playing = false; st.plays--; if (st.plays > 0) hold.restart() }
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle { anchors.fill: parent; color: Theme.track }
        Image {
            id: baseImg
            width: st.width; height: st.height
            x: st.playing ? (st.trans === "slide" ? -st.progress * st.width * 0.3 : (st.trans === "wipe" ? st.progress * st.oldK * st.dx : 0)) : 0
            y: st.playing && st.trans === "wipe" ? st.progress * st.oldK * st.dy : 0
            scale: !st.playing ? 1 : (st.trans === "wipe" ? 1 + 2 * st.progress * st.oldK * st.kmax * st.zoomW
                : (st.trans === "circle" ? 1 + st.progress * st.sK : 1))
            source: st.lowerUrl
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(480, 270)
            asynchronous: true
        }
        Image {
            id: newImg
            parent: st.trans === "circle" ? newWrap : (st.trans === "wipe" ? wipeInner : plainNew)
            x: st.trans === "wipe" ? ox - wipeClip.x : 0
            y: st.trans === "wipe" ? oy - wipeClip.y : 0
            readonly property real ox: st.trans === "wipe" ? -(1 - st.progress) * st.newK * st.dx : 0
            readonly property real oy: st.trans === "wipe" ? -(1 - st.progress) * st.newK * st.dy : 0
            width: st.width; height: st.height
            scale: st.trans === "wipe" ? 1 + 2 * (1 - st.progress) * st.newK * st.kmax * st.zoomW
                : (st.trans === "circle" ? 1 + (1 - st.progress) * st.sK * 1.25 : 1)
            source: st.upperUrl
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(480, 270)
            asynchronous: true
        }
        Item {   // fonte do circulo (fora do palco, mas visivel)
            id: newWrap
            x: -st.width - 60
            clip: true
            width: st.width; height: st.height
            layer.enabled: true
        }
        Item {
            visible: st.playing
            width: st.width; height: st.height
            clip: true
            x: st.trans === "slide" ? (1 - st.progress) * st.width : 0
            opacity: st.isShader ? 1 : (st.trans === "fade" || st.trans === "zoom" ? st.progress : 1)
            scale: st.trans === "zoom" ? 1.1 - 0.1 * st.progress : 1
            Item { id: plainNew; width: st.width; height: st.height; visible: st.trans !== "circle" && st.trans !== "wipe" }
            Item {
                id: wipeClip
                visible: st.trans === "wipe"
                readonly property real len: st.diag * 3
                width: len; height: len
                x: st.edgeS * st.dx - st.dx * len / 2 - len / 2
                y: st.edgeS * st.dy - st.dy * len / 2 - len / 2
                rotation: Settings.wpWipeAngle
                clip: true
                Item { id: wipeInner; width: wipeClip.len; height: wipeClip.len; rotation: -Settings.wpWipeAngle }
            }
            MultiEffect {
                visible: st.trans === "circle"
                width: st.width; height: st.height
                source: newWrap
                maskEnabled: true
                maskSource: circleMask
            }
        }
        Item {
            id: circleMask
            x: -st.width - 50
            clip: true
            layer.enabled: true
            width: st.width; height: st.height
            Rectangle {
                readonly property real d: st.diag * st.progress
                width: d; height: d; radius: d / 2
                x: st.width / 2 - d / 2
                y: st.height / 2 - d / 2
                color: "white"
            }
        }
        ShaderEffectSource { id: fromTex; sourceItem: baseImg; live: st.isShader && st.playing; hideSource: false; x: -4; width: 1; height: 1 }
        ShaderEffectSource { id: toTex; sourceItem: newImg; live: st.isShader && st.playing; hideSource: false; x: -4; width: 1; height: 1 }
        ShaderEffect {
            id: fx
            visible: st.isShader && st.playing
            width: st.width; height: st.height
            property var source: fromTex
            property var src1: fromTex
            property var src2: toTex
            property real progress: st.progress
            property real aspect: width / Math.max(1, height)
            property real seed: 0
            property color glow: Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, 0.9)
            fragmentShader: st.isShader ? Qt.resolvedUrl("shaders/" + st.trans + ".frag.qsb") : ""
        }
    }
    // cantos arredondados: anel da cor do cartao por fora
    Rectangle {
        anchors.fill: parent; anchors.margins: -14
        radius: SetK.boxRadius - 2 + 14
        color: "transparent"
        border.width: 14
        border.color: Theme.glc(Theme.card, 1)
    }
    Rectangle { anchors.fill: parent; radius: SetK.boxRadius - 2; color: "transparent"; border.width: 1; border.color: Theme.border }
    // parado: clicar (ou passar o mouse) toca de novo
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: st.restartLoop()
        onContainsMouseChanged: if (containsMouse && st.plays <= 0) st.restartLoop()
    }
    Rectangle {
        anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
        width: 28; height: 28; radius: 14
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: st.plays <= 0 && !st.playing ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        UiIcon { anchors.centerIn: parent; name: "refresh"; size: 16; color: "white" }
    }
}
