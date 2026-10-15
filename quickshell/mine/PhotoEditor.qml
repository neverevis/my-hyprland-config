// Editor da foto de perfil: arraste para posicionar, roda do mouse/slider para o zoom, botoes para girar.
// O circulo mostra o que vira a foto; ao salvar, o recorte (em fracoes da imagem) vai para scripts/set_face.py.
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Scope {
    id: root
    readonly property bool open: Profile.editing !== ""
    property bool alive: false
    onOpenChanged: { if (open) { closeTimer.stop(); alive = true } else closeTimer.restart() }
    Timer { id: closeTimer; interval: 260; onTriggered: root.alive = false }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-photo"
            mask: Region { item: root.open ? dim : null }

            property real p: 0
            Component.onCompleted: p = Qt.binding(() => root.open ? 1 : 0)
            Behavior on p { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            Rectangle {
                id: dim
                anchors.fill: parent
                color: "black"
                opacity: 0.55 * win.p
                MouseArea { anchors.fill: parent; onClicked: Profile.cancel() }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                anchors.verticalCenterOffset: (1 - win.p) * 30
                opacity: win.p
                scale: 0.96 + 0.04 * win.p
                width: 640; height: 520; radius: 24
                color: Theme.bg
                border.width: 1; border.color: Theme.border
                MouseArea { anchors.fill: parent }   // clique no cartao nao fecha

                focus: true
                Keys.onEscapePressed: Profile.cancel()
                Keys.onReturnPressed: ed.save()
                Keys.onEnterPressed: ed.save()
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Plus || e.key === Qt.Key_Equal) ed.setZoom(ed.zoom * 1.1)
                    else if (e.key === Qt.Key_Minus) ed.setZoom(ed.zoom / 1.1)
                    else if (e.key === Qt.Key_R) ed.rotateBy(e.modifiers & Qt.ShiftModifier ? -90 : 90)
                    else if (e.key === Qt.Key_Left) ed.move(-10, 0)
                    else if (e.key === Qt.Key_Right) ed.move(10, 0)
                    else if (e.key === Qt.Key_Up) ed.move(0, -10)
                    else if (e.key === Qt.Key_Down) ed.move(0, 10)
                    else return
                    e.accepted = true
                }

                // ---- cabecalho ----
                Row {
                    x: 24; y: 20
                    spacing: 12
                    Rectangle {
                        width: 36; height: 36; radius: 11; color: Theme.tint(0.18)
                        UiIcon { anchors.centerIn: parent; name: "accountEdit"; size: 20; color: Theme.accent }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "Ajustar foto de perfil"; color: Theme.text; font.pixelSize: 17; font.weight: Font.Bold }
                        Text { text: "Arraste para posicionar · roda do mouse para o zoom"; color: Theme.muted; font.pixelSize: 12 }
                    }
                }
                UiButton { anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 18 } icon: "close"; kind: "ghost"; onClicked: Profile.cancel() }

                // ---- area de recorte ----
                Item {
                    id: ed
                    x: 24; y: 76
                    width: 360; height: 360
                    clip: true
                    readonly property real vp: width
                    property int rot: 0
                    property real zoom: 1
                    property real ox: 0
                    property real oy: 0
                    readonly property bool turned: rot % 180 !== 0
                    readonly property real iw: img.implicitWidth
                    readonly property real ih: img.implicitHeight
                    readonly property real rw: turned ? ih : iw          // tamanho da imagem ja girada
                    readonly property real rh: turned ? iw : ih
                    readonly property real k: rw > 0 && rh > 0 ? vp / Math.min(rw, rh) * zoom : 1   // escala na tela
                    readonly property real mx: Math.max(0, (rw * k - vp) / 2)   // folga para arrastar sem mostrar borda
                    readonly property real my: Math.max(0, (rh * k - vp) / 2)
                    function clampPos() { ox = Math.max(-mx, Math.min(mx, ox)); oy = Math.max(-my, Math.min(my, oy)) }
                    function setZoom(z) { zoom = Math.max(1, Math.min(5, z)); clampPos() }
                    function move(dx, dy) { ox += dx; oy += dy; clampPos() }
                    function rotateBy(d) { rot = (rot + d + 360) % 360; ox = 0; oy = 0; clampPos() }
                    function reset() { rot = 0; zoom = 1; ox = 0; oy = 0 }
                    function save() {
                        if (rw <= 0) return
                        // canto do circulo (0,0 do quadro) nas coordenadas da imagem girada, em fracoes
                        const u0 = rw / 2 - (vp / 2 + ox) / k, v0 = rh / 2 - (vp / 2 + oy) / k, s = vp / k
                        Profile.save(rot, u0 / rw, v0 / rh, s / rw)
                    }
                    Connections { target: Profile; function onEditingChanged() { if (Profile.editing !== "") ed.reset() } }

                    Item {   // so a foto (sem o escurecimento por cima): fonte da previa
                        id: photo
                        anchors.fill: parent
                        clip: true
                    Rectangle { anchors.fill: parent; color: Theme.track; radius: 16 }
                    Image {
                        id: img
                        source: Profile.editing !== "" ? "file://" + Profile.editing : ""
                        autoTransform: true
                        sourceSize: Qt.size(2048, 2048)
                        asynchronous: true
                        smooth: true
                        width: ed.iw * ed.k; height: ed.ih * ed.k
                        x: ed.vp / 2 + ed.ox - width / 2
                        y: ed.vp / 2 + ed.oy - height / 2
                        rotation: ed.rot
                        Behavior on rotation { RotationAnimation { duration: 220; easing.type: Easing.OutCubic; direction: RotationAnimation.Shortest } }
                    }
                    }
                    // fora do circulo fica escurecido (o que sai na foto e so o circulo)
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            const c = getContext("2d"); c.reset()
                            c.fillStyle = Qt.rgba(0, 0, 0, 0.55)
                            c.beginPath(); c.rect(0, 0, width, height)
                            c.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 2, true)
                            c.fill()
                            c.strokeStyle = Qt.rgba(1, 1, 1, 0.85); c.lineWidth = 2
                            c.beginPath(); c.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 2); c.stroke()
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: img.status === Image.Loading
                        text: "Carregando…"; color: Theme.muted; font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        property real lx: 0
                        property real ly: 0
                        onPressed: m => { lx = m.x; ly = m.y }
                        onPositionChanged: m => { ed.move(m.x - lx, m.y - ly); lx = m.x; ly = m.y }
                        onDoubleClicked: ed.reset()
                        onWheel: w => {
                            // zoom em volta do cursor: o ponto embaixo do mouse fica parado
                            const z0 = ed.zoom, z1 = Math.max(1, Math.min(5, z0 * (w.angleDelta.y > 0 ? 1.1 : 1 / 1.1)))
                            const cx = w.x - ed.vp / 2, cy = w.y - ed.vp / 2
                            ed.ox = cx - (cx - ed.ox) * z1 / z0
                            ed.oy = cy - (cy - ed.oy) * z1 / z0
                            ed.zoom = z1
                            ed.clampPos()
                        }
                    }
                }

                // ---- previa e controles ----
                Column {
                    anchors { left: ed.right; leftMargin: 24; right: parent.right; rightMargin: 24; top: ed.top }
                    spacing: 14
                    UiLabel { text: "Prévia" }
                    Row {
                        spacing: 14
                        ShaderEffectSource { id: photoTex; sourceItem: photo; hideSource: false; live: true; visible: false }
                        Repeater {
                            model: [96, 56, 34]
                            delegate: Item {
                                required property var modelData
                                width: modelData; height: modelData
                                anchors.verticalCenter: parent.verticalCenter
                                Item {
                                    id: msk
                                    anchors.fill: parent
                                    visible: false
                                    layer.enabled: true
                                    Rectangle { anchors.fill: parent; radius: width / 2; color: "white" }
                                }
                                MultiEffect {
                                    anchors.fill: parent
                                    source: photoTex
                                    maskEnabled: true
                                    maskSource: msk
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1.0
                                    autoPaddingEnabled: false
                                }
                                Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border.width: 2; border.color: Theme.accent }
                            }
                        }
                    }
                    UiSlider { label: "Zoom"; icon: "magic"; from: 100; to: 500; value: Math.round(ed.zoom * 100); suffix: " %"; onMoved: v => ed.setZoom(v / 100) }
                    UiLabel { text: "Girar" }
                    Row {
                        spacing: 8
                        UiButton { icon: "restore"; text: "Esquerda"; onClicked: ed.rotateBy(-90) }
                        UiButton { icon: "refresh"; text: "Direita"; onClicked: ed.rotateBy(90) }
                    }
                    UiButton { icon: "restore"; text: "Recomeçar"; kind: "ghost"; onClicked: ed.reset() }
                }

                // ---- rodape ----
                Row {
                    anchors { right: parent.right; rightMargin: 24; bottom: parent.bottom; bottomMargin: 20 }
                    spacing: 10
                    UiButton { text: "Cancelar"; kind: "ghost"; onClicked: Profile.cancel() }
                    UiButton { icon: "check"; text: "Salvar foto"; kind: "accent"; onClicked: ed.save() }
                }
                Text {
                    anchors { left: parent.left; leftMargin: 24; bottom: parent.bottom; bottomMargin: 28 }
                    text: "Duplo clique recomeça · R gira · Enter salva"
                    color: Theme.muted; font.pixelSize: 11
                }
            }
        }
    }
}
