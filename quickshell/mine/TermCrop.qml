// Editor de recorte da imagem das boas-vindas (maquete do terminal): arraste para posicionar, roda do mouse ou controle para o zoom,
// botoes para girar; o quadro de recorte (Livre, Quadrado ou Original) puxa pelos cantos. Ao aplicar, scripts/crop_image.py grava o
// recorte em ~/.config/quickshell-mine/term-logo.png (a original fica intacta) e as boas-vindas passam a usar esse arquivo.
// Criado so com o editor aberto (Loader em TermMock); nada roda parado.
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: cr
    property string src: ""
    signal closed

    readonly property string script: Qt.resolvedUrl("scripts/crop_image.py").toString().replace("file://", "")
    property bool busy: false
    property string err: ""
    focus: true
    Component.onCompleted: { forceActiveFocus(); st.resetFrame() }
    Keys.onEscapePressed: cr.closed()
    Keys.onReturnPressed: cr.apply()
    Keys.onEnterPressed: cr.apply()

    function apply() {
        if (busy || st.cw <= 0) return
        busy = true; err = ""
        const x = (st.fx - st.il) / st.cw, y = (st.fy - st.it) / st.ch, w = st.fw / st.cw, h = st.fh / st.ch
        run.command = ["python3", cr.script, cr.src, TermFetch.logo, String(st.rot), String(x), String(y), String(w), String(h)]
        run.running = true
    }
    Process {
        id: run
        stderr: StdioCollector { id: errC }
        onExited: code => {
            cr.busy = false
            if (code !== 0) { cr.err = "Não consegui recortar esta imagem" + (errC.text.trim() !== "" ? ": " + errC.text.trim().split("\n").pop().slice(0, 120) : ""); return }
            if (TermFetch.imageSrc !== cr.src && cr.src !== TermFetch.logo) TermFetch.set("imageSrc", cr.src)
            TermFetch.set("image", TermFetch.logo)
            TermFetch.imgStamp++
            cr.closed()
        }
    }

    // fundo escurecido: clicar fora fecha
    Rectangle {
        x: -4000; y: -4000; width: 8000; height: 8000
        color: "black"; opacity: 0.45
        MouseArea { anchors.fill: parent; onClicked: cr.closed() }
    }

    Rectangle {
        id: card
        x: Math.round((cr.width - width) / 2); y: 0
        width: Math.min(700, cr.width); height: 440
        radius: 20
        color: Theme.gl(Theme.bg, 1)
        border.width: 1; border.color: Theme.border
        MouseArea { anchors.fill: parent }   // clique no cartao nao fecha

        Row {
            x: 20; y: 16; spacing: 12
            Rectangle { width: 36; height: 36; radius: 11; color: Theme.tint(0.18); UiIcon { anchors.centerIn: parent; name: "crop"; size: 20; color: Theme.accent } }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                UiText { text: "Ajustar imagem"; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                UiText { text: "Arraste para posicionar, roda do mouse para o zoom, puxe os cantos do quadro"; color: Theme.muted; font.pixelSize: 12 }
            }
        }

        // ---- palco ----
        Item {
            id: st
            x: 20; y: 68
            width: Math.min(400, card.width - 260); height: 300
            clip: true
            property int rot: 0
            property real zoom: 1
            property real ox: 0
            property real oy: 0
            property string mode: "free"     // free | square | orig
            property real fx: 0
            property real fy: 0
            property real fw: 100
            property real fh: 100
            readonly property bool turned: rot % 180 !== 0
            readonly property real rw: turned ? img.implicitHeight : img.implicitWidth
            readonly property real rh: turned ? img.implicitWidth : img.implicitHeight
            readonly property real k0: rw > 0 && rh > 0 ? Math.min(width / rw, height / rh) : 1
            readonly property real k: k0 * zoom
            readonly property real cw: rw * k
            readonly property real ch: rh * k
            readonly property real il: width / 2 + ox - cw / 2
            readonly property real it: height / 2 + oy - ch / 2
            readonly property real ratio: mode === "square" ? 1 : mode === "orig" && rh > 0 ? rw / rh : 0

            onRwChanged: resetFrame()
            function clampAll() {
                fw = Math.min(fw, cw); fh = Math.min(fh, ch)
                ox = Math.max(fx + fw - width / 2 - cw / 2, Math.min(fx - width / 2 + cw / 2, ox))
                oy = Math.max(fy + fh - height / 2 - ch / 2, Math.min(fy - height / 2 + ch / 2, oy))
            }
            function resetFrame() {
                if (rw <= 0) return
                zoom = 1; ox = 0; oy = 0
                const w1 = rw * k0, h1 = rh * k0
                let w = w1, h = h1
                if (mode === "square") { w = h = Math.min(w1, h1) }
                else if (mode === "free") { w = w1 * 0.8; h = h1 * 0.8 }
                fw = w; fh = h; fx = (width - w) / 2; fy = (height - h) / 2
            }
            function setMode(m) { mode = m; resetFrame() }
            function rotateBy(d) { rot = (rot + d + 360) % 360; resetFrame() }
            function setZoom(z) {
                const z0 = zoom, z1 = Math.max(1, Math.min(6, z))
                const cx = fx + fw / 2 - width / 2, cy = fy + fh / 2 - height / 2   // zoom em volta do centro do quadro
                ox = cx - (cx - ox) * z1 / z0; oy = cy - (cy - oy) * z1 / z0
                zoom = z1; clampAll()
            }
            // canto do quadro puxado: o oposto fica parado; so dentro da imagem
            function dragCorner(sx, sy, px, py, ax, ay) {
                const l = Math.max(il, 0), r = Math.min(il + cw, width), t = Math.max(it, 0), b = Math.min(it + ch, height)
                const availW = sx > 0 ? r - ax : ax - l, availH = sy > 0 ? b - ay : ay - t
                let w = Math.max(24, Math.abs(px - ax)), h = Math.max(24, Math.abs(py - ay))
                if (ratio > 0) { w = Math.min(w, availW, availH * ratio); h = w / ratio }
                else { w = Math.min(w, availW); h = Math.min(h, availH) }
                fw = w; fh = h; fx = sx > 0 ? ax : ax - w; fy = sy > 0 ? ay : ay - h
            }

            Rectangle { anchors.fill: parent; color: Theme.track; radius: 12 }
            Image {
                id: img
                source: cr.src !== "" ? "file://" + cr.src : ""
                autoTransform: true; asynchronous: true; smooth: true
                sourceSize: Qt.size(2048, 2048)
                width: implicitWidth * st.k; height: implicitHeight * st.k
                x: st.width / 2 + st.ox - width / 2; y: st.height / 2 + st.oy - height / 2
                rotation: st.rot
                Behavior on rotation { RotationAnimation { duration: 200; easing.type: Easing.OutCubic; direction: RotationAnimation.Shortest } }
            }
            // escurece fora do quadro
            Rectangle { x: 0; y: 0; width: st.width; height: st.fy; color: "black"; opacity: 0.55 }
            Rectangle { x: 0; y: st.fy + st.fh; width: st.width; height: st.height - st.fy - st.fh; color: "black"; opacity: 0.55 }
            Rectangle { x: 0; y: st.fy; width: st.fx; height: st.fh; color: "black"; opacity: 0.55 }
            Rectangle { x: st.fx + st.fw; y: st.fy; width: st.width - st.fx - st.fw; height: st.fh; color: "black"; opacity: 0.55 }
            UiText { anchors.centerIn: parent; visible: img.status === Image.Loading; text: "Carregando…"; color: Theme.muted; font.pixelSize: 14 }

            MouseArea {
                anchors.fill: parent
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property real lx: 0
                property real ly: 0
                onPressed: m => { lx = m.x; ly = m.y }
                onPositionChanged: m => { st.ox += m.x - lx; st.oy += m.y - ly; lx = m.x; ly = m.y; st.clampAll() }
                onDoubleClicked: st.resetFrame()
                onWheel: w => st.setZoom(st.zoom * (w.angleDelta.y > 0 ? 1.1 : 1 / 1.1))
            }
            Rectangle { x: st.fx; y: st.fy; width: st.fw; height: st.fh; color: "transparent"; border.width: 2; border.color: "white"; opacity: 0.9 }
            // quatro cantos
            Repeater {
                model: [[-1, -1], [1, -1], [-1, 1], [1, 1]]
                delegate: Rectangle {
                    id: hd
                    required property var modelData
                    readonly property int sx: modelData[0]
                    readonly property int sy: modelData[1]
                    x: st.fx + (sx > 0 ? st.fw : 0) - width / 2; y: st.fy + (sy > 0 ? st.fh : 0) - height / 2
                    width: 13; height: 13; radius: 3
                    color: Theme.bg; border.width: 2; border.color: Theme.accent
                    MouseArea {
                        anchors.centerIn: parent; width: 28; height: 28
                        cursorShape: (hd.sx * hd.sy > 0) ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                        property real ax: 0
                        property real ay: 0
                        onPressed: { ax = hd.sx > 0 ? st.fx : st.fx + st.fw; ay = hd.sy > 0 ? st.fy : st.fy + st.fh }
                        onPositionChanged: m => { if (pressed) { const q = mapToItem(st, m.x, m.y); st.dragCorner(hd.sx, hd.sy, q.x, q.y, ax, ay); st.clampAll() } }
                    }
                }
            }
        }

        // ---- controles ----
        Column {
            anchors { left: st.right; leftMargin: 20; right: parent.right; rightMargin: 20; top: st.top }
            spacing: 12
            UiLabel { text: "Quadro" }
            UiSeg {
                fill: true; value: st.mode
                options: [["free", "Livre"], ["square", "Quadrado"], ["orig", "Original"]]
                onPicked: v => st.setMode(v)
            }
            UiSlider { label: "Zoom"; icon: "magic"; from: 100; to: 600; value: Math.round(st.zoom * 100); suffix: " %"; onMoved: v => st.setZoom(v / 100) }
            UiLabel { text: "Girar" }
            Row {
                spacing: 8
                UiButton { icon: "restore"; text: "Esquerda"; onClicked: st.rotateBy(-90) }
                UiButton { icon: "refresh"; text: "Direita"; onClicked: st.rotateBy(90) }
            }
            UiButton { icon: "restore"; text: "Recomeçar"; kind: "ghost"; onClicked: { st.rot = 0; st.resetFrame() } }
        }

        UiText {
            visible: cr.err !== ""
            x: 20; y: 380; width: parent.width - 40; elide: Text.ElideRight; text: cr.err; color: Theme.danger; font.pixelSize: 12
        }
        UiText { x: 20; y: card.height - 38; text: "Duplo clique recomeça · Enter aplica · Esc fecha"; color: Theme.muted; font.pixelSize: 11 }
        Row {
            anchors { right: parent.right; rightMargin: 20; bottom: parent.bottom; bottomMargin: 16 }
            spacing: 10
            UiButton { text: "Cancelar"; kind: "ghost"; onClicked: cr.closed() }
            UiButton { icon: "check"; text: cr.busy ? "Salvando…" : "Aplicar"; kind: "accent"; enabled: !cr.busy && st.cw > 0; onClicked: cr.apply() }
        }
    }
}
