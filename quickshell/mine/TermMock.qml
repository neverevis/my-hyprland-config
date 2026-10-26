// Maquete do terminal escolhido (pagina Terminal): janela com a transparencia, imagem de fundo, margem, fonte e cursor de verdade,
// as boas-vindas (imagem + linhas) e o prompt montado a partir de TermPrompt/TermFetch com valores de exemplo.
// As pecas (trechos do prompt e linhas das boas-vindas) arrastam para reordenar, para a bandeja "Pecas disponiveis" (tira) e de volta;
// o x ao passar o mouse tambem tira, tocar numa peca da bandeja poe de volta. Clicar na imagem escolhe outra; no fundo, abre o Visual.
// Nada roda parado: o cursor so pisca com a janela visivel e a opcao ligada.
import Quickshell
import QtQuick

Item {
    id: root
    signal visualRequested
    width: parent ? parent.width : 600
    height: col.implicitHeight

    readonly property bool showPrompt: Terminal.starship && TermPrompt.on
    readonly property bool showFetch: Terminal.fastfetch && TermFetch.on
    readonly property int fpx: Math.max(12, Math.min(18, Math.round(Terminal.fontPt * 1.33)))
    readonly property int lineH: Math.round(fpx * 1.5)
    readonly property real opq: (Terminal.look("opacity") ?? 100) / 100
    readonly property color termBg: Qt.darker(Theme.card, 1.5)
    readonly property string bgImg: Terminal.hasImage ? (Terminal.look("image") || "") : ""
    readonly property string layout: Terminal.look("layout") || "tile"
    readonly property real charW: tm.advanceWidth
    TextMetrics { id: tm; font.family: Terminal.fontFamily; font.pixelSize: root.fpx; text: "M" }

    // ---- arrastar (um controlador so; as pecas so avisam) ----
    property string dGroup: ""
    property string dKey: ""
    property bool dTray: false
    property real dX: 0
    property real dY: 0
    property int dIdx: -1
    property rect marker: Qt.rect(0, 0, 0, 0)
    readonly property bool dragging: dGroup !== ""
    function api(g) { return g === "prompt" ? TermPrompt : TermFetch }
    function meta(g, k) { return g === "prompt" ? TermPrompt.piece(k) : TermFetch.item(k) }
    function rep(g) { return g === "prompt" ? pRep : fRep }
    function startDrag(g, k, tray) { dGroup = g; dKey = k; dTray = tray; dIdx = -1 }
    function inRect(it, x, y) { const p = it.mapToItem(root, 0, 0); return x >= p.x && x <= p.x + it.width && y >= p.y && y <= p.y + it.height }
    function items(g) { const r = rep(g), l = []; for (let i = 0; i < r.count; i++) { const it = r.itemAt(i); if (it && it.key !== dKey) l.push(it) } return l }
    function indexAt(g, x, y) {
        const vert = g === "fetch"
        let n = 0
        for (const it of items(g)) {
            const p = it.mapToItem(root, 0, 0)
            const before = vert ? p.y + it.height / 2 < y : (p.y + it.height < y || (y >= p.y && p.x + it.width / 2 < x))
            if (before) n++
        }
        return n
    }
    function markerFor(g, idx) {
        const l = items(g), vert = g === "fetch"
        if (l.length === 0) { const c = g === "prompt" ? pFlow : fCol, p = c.mapToItem(root, 0, 0); return Qt.rect(p.x, p.y, vert ? 40 : 2, vert ? 2 : root.lineH) }
        const last = idx >= l.length, it = l[last ? l.length - 1 : idx], p = it.mapToItem(root, 0, 0)
        if (vert) return Qt.rect(p.x, p.y + (last ? it.height : 0) - 1, it.width, 2)
        return Qt.rect(p.x + (last ? it.width : 0) - 1, p.y, 2, it.height)
    }
    function moveDrag(x, y) {
        dX = x; dY = y
        if (inRect(tray, x, y) || !inRect(mock, x, y)) { dIdx = -1; marker = Qt.rect(0, 0, 0, 0); return }
        dIdx = indexAt(dGroup, x, y)
        marker = markerFor(dGroup, dIdx)
    }
    function endDrag() {
        const g = dGroup, k = dKey, a = api(g)
        if (g === "") return
        if (dTray) { if (dIdx >= 0) a.place(k, dIdx) }
        else if (inRect(tray, dX, dY)) a.remove(k)
        else if (dIdx >= 0) a.place(k, dIdx)
        dGroup = ""; dKey = ""; dIdx = -1
    }
    function pickImage() { Pick.image("Imagem das boas-vindas", p => TermFetch.set("image", p)) }

    // area de arrasto de uma peca (ctl = TermMock)
    component DragArea: MouseArea {
        id: da
        property var ctl
        property string group
        property string key
        property bool tray: false
        property point p0
        property bool moved: false
        property bool wasMoved: false
        hoverEnabled: true
        cursorShape: da.moved ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPressed: m => { p0 = Qt.point(m.x, m.y); moved = false; wasMoved = false }
        onPositionChanged: m => {
            if (!pressed) return
            if (!moved && Math.hypot(m.x - p0.x, m.y - p0.y) > 6) { moved = true; ctl.startDrag(group, key, tray) }
            if (moved) { const q = mapToItem(ctl, m.x, m.y); ctl.moveDrag(q.x, q.y) }
        }
        onReleased: { if (moved) { wasMoved = true; moved = false; ctl.endDrag() } }
        onCanceled: { if (moved) { moved = false; ctl.endDrag() } }
        onClicked: if (tray && !wasMoved) ctl.api(group).place(key, 9999)
    }
    // x que tira a peca da maquete
    component DropX: Rectangle {
        id: dx
        property var ctl
        property string group
        property string key
        width: 16; height: 16; radius: 8
        color: xm.containsMouse ? Theme.danger : Theme.cardHi
        border.width: 1; border.color: Theme.border
        UiIcon { anchors.centerIn: parent; name: "close"; size: 10; color: xm.containsMouse ? Theme.card : Theme.muted }
        MouseArea { id: xm; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ctl.api(group).remove(key) }
    }

    Column {
        id: col
        width: parent.width
        spacing: SetK.md

        // ---- a janela ----
        Rectangle {
            id: mock
            width: parent.width
            height: Math.max(190, content.implicitHeight + Math.min(60, Terminal.look("pad") ?? 0) * 2 + 8)
            radius: 12
            clip: true
            color: "transparent"
            border.width: 1; border.color: Theme.border
            readonly property int pad: Math.max(10, Math.min(48, Terminal.look("pad") ?? 0))

            Image {
                anchors.fill: parent; asynchronous: true; fillMode: Image.PreserveAspectCrop; sourceSize.width: 900
                source: Wallpaper.stillUrl(Wallpaper.current)
            }
            Rectangle { anchors.fill: parent; color: root.termBg; opacity: root.opq }
            Image {
                visible: root.bgImg !== ""
                anchors.fill: parent; asynchronous: true; opacity: root.opq; sourceSize.width: 900
                source: root.bgImg !== "" ? "file://" + root.bgImg : ""
                fillMode: root.layout === "fill" ? Image.PreserveAspectCrop : root.layout === "fit" ? Image.PreserveAspectFit : root.layout === "center" ? Image.Pad : Image.Tile
            }
            Rectangle { visible: root.bgImg !== ""; anchors.fill: parent; color: root.termBg; opacity: ((Terminal.look("tint") ?? 0) / 100) * root.opq }
            MouseArea { id: bgClick; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.visualRequested() }
            UiText {
                visible: bgClick.containsMouse && !root.dragging
                anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
                text: "Clique no fundo para ajustar o visual"; color: Theme.text; opacity: 0.7; font.pixelSize: 11
            }

            Column {
                id: content
                x: mock.pad; y: mock.pad
                width: mock.width - mock.pad * 2
                spacing: 0

                // boas-vindas: imagem + linhas
                Row {
                    visible: root.showFetch
                    spacing: SetK.lg
                    bottomPadding: root.lineH
                    Rectangle {
                        id: imgBox
                        visible: TermFetch.canImage
                        width: 112; height: 112; radius: 8; clip: true
                        color: "transparent"
                        border.width: fImg.status === Image.Ready ? 0 : 1; border.color: Theme.border
                        Image { id: fImg; anchors.fill: parent; asynchronous: true; fillMode: Image.PreserveAspectCrop; sourceSize.width: 256
                                source: TermFetch.image !== "" ? "file://" + TermFetch.image : "" }
                        Column {
                            visible: fImg.status !== Image.Ready
                            anchors.centerIn: parent; spacing: 4
                            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "image"; size: 22; color: Theme.muted }
                            UiText { text: TermFetch.image === "" ? "Sem imagem" : "Carregando…"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                        }
                        Rectangle { anchors.fill: parent; radius: 8; color: Theme.tint(0.16); visible: imgMa.containsMouse; border.width: 1; border.color: Theme.accent }
                        MouseArea { id: imgMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pickImage() }
                        Rectangle {
                            visible: TermFetch.image !== "" && imgMa.containsMouse
                            x: parent.width - 22; y: 6; width: 16; height: 16; radius: 8; z: 2
                            color: nm.containsMouse ? Theme.danger : Theme.cardHi; border.width: 1; border.color: Theme.border
                            UiIcon { anchors.centerIn: parent; name: "close"; size: 10; color: nm.containsMouse ? Theme.card : Theme.muted }
                            MouseArea { id: nm; anchors.fill: parent; anchors.margins: -3; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: TermFetch.set("image", "none") }
                        }
                    }
                    Column {
                        id: fCol
                        Repeater {
                            id: fRep
                            model: TermFetch.active()
                            delegate: Item {
                                id: fl
                                required property string modelData
                                readonly property string key: modelData
                                readonly property var meta: TermFetch.item(modelData)
                                width: Math.max(180, flRow.implicitWidth + 24); height: root.lineH
                                opacity: root.dGroup === "fetch" && root.dKey === key ? 0.3 : 1
                                Rectangle { anchors.fill: parent; anchors.margins: -1; radius: 5; color: Theme.tint(0.10); visible: fh.hovered || fda.containsMouse; border.width: 1; border.color: Theme.border }
                                HoverHandler { id: fh }
                                Row {
                                    id: flRow
                                    anchors.verticalCenter: parent.verticalCenter; x: 4; spacing: 8
                                    UiText { visible: fl.key !== "userhost" && fl.key !== "colors"; width: root.charW * 14; text: fl.meta.label; color: Theme.accent; font.family: Terminal.fontFamily; font.pixelSize: root.fpx; elide: Text.ElideRight }
                                    UiText { visible: fl.key !== "colors"; text: fl.key === "terminal" ? Terminal.termName : fl.meta.sample; color: fl.key === "userhost" ? Theme.accent : Theme.text
                                             font.bold: fl.key === "userhost"; font.family: Terminal.fontFamily; font.pixelSize: root.fpx }
                                    Row {
                                        visible: fl.key === "colors"; spacing: 6; anchors.verticalCenter: parent.verticalCenter
                                        Repeater { model: [Theme.danger, Theme.accent, Theme.secondary, Theme.tertiary, Theme.muted, Theme.text]
                                                   delegate: Rectangle { required property color modelData; width: root.fpx * 0.8; height: width; radius: width / 2; color: modelData } }
                                    }
                                }
                                DragArea { id: fda; anchors.fill: parent; ctl: root; group: "fetch"; key: fl.key }
                                DropX { visible: (fh.hovered || fda.containsMouse) && !root.dragging; x: parent.width - 8; y: -6; z: 3; ctl: root; group: "fetch"; key: fl.key }
                            }
                        }
                    }
                }

                // comando anterior (falhou) so para dar contexto
                Column {
                    visible: root.showPrompt
                    width: parent.width
                    Repeater {
                        model: root.showPrompt ? TermPrompt.segments(true) : []
                        delegate: Row {
                            required property var modelData
                            required property int index
                            Repeater { model: modelData; delegate: UiText { required property var modelData; text: modelData.t; color: modelData.c; font.bold: modelData.b; font.family: Terminal.fontFamily; font.pixelSize: root.fpx; textFormat: Text.PlainText } }
                            UiText { visible: index === TermPrompt.segments(true).length - 1; text: "git psuh"; color: Theme.text; font.family: Terminal.fontFamily; font.pixelSize: root.fpx }
                        }
                    }
                }
                Item { visible: root.showPrompt && TermPrompt.get("gap"); width: 1; height: root.lineH }

                // prompt atual: pecas arrastaveis
                Flow {
                    id: pFlow
                    width: parent.width
                    Repeater {
                        id: pRep
                        model: root.showPrompt ? TermPrompt.active() : []
                        delegate: Item {
                            id: pc
                            required property string modelData
                            readonly property string key: modelData
                            width: pcRow.implicitWidth + 4; height: root.lineH
                            opacity: root.dGroup === "prompt" && root.dKey === key ? 0.3 : 1
                            Rectangle { anchors.fill: parent; anchors.margins: -1; radius: 5; color: Theme.tint(0.10); visible: ph.hovered || pda.containsMouse; border.width: 1; border.color: Theme.border }
                            HoverHandler { id: ph }
                            Row {
                                id: pcRow
                                anchors.verticalCenter: parent.verticalCenter; x: 2
                                Repeater { model: TermPrompt.pieceSegs(pc.key); delegate: UiText { required property var modelData; text: modelData.t; color: modelData.c; font.bold: modelData.b; font.family: Terminal.fontFamily; font.pixelSize: root.fpx; textFormat: Text.PlainText } }
                            }
                            DragArea { id: pda; anchors.fill: parent; ctl: root; group: "prompt"; key: pc.key }
                            DropX { visible: (ph.hovered || pda.containsMouse) && !root.dragging; x: parent.width - 10; y: -7; z: 3; ctl: root; group: "prompt"; key: pc.key }
                        }
                    }
                    Row { visible: !TermPrompt.get("two") || !root.showPrompt; height: root.lineH; Loader { sourceComponent: cursorLine } }
                }
                Row { visible: root.showPrompt && TermPrompt.get("two"); height: root.lineH; Loader { sourceComponent: cursorLine } }
            }

            // simbolo do prompt + texto digitado + cursor
            Component {
                id: cursorLine
                Row {
                    height: root.lineH
                    UiText { anchors.verticalCenter: parent.verticalCenter; text: root.showPrompt ? TermPrompt.symSeg(false).t : "$ "; color: root.showPrompt ? TermPrompt.symSeg(false).c : Theme.text; font.bold: true; font.family: Terminal.fontFamily; font.pixelSize: root.fpx }
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.charW; height: root.lineH - 4
                        Rectangle {
                            id: cur
                            readonly property string shape: Terminal.look("cursor") || "block"
                            color: Theme.text
                            width: shape === "beam" ? 2 : parent.width
                            height: shape === "underline" ? 2 : parent.height
                            y: shape === "underline" ? parent.height - 2 : 0
                            SequentialAnimation on opacity {
                                running: mock.visible && Terminal.look("blink") === true && !root.dragging
                                loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 500 }
                                NumberAnimation { to: 1; duration: 500 }
                            }
                        }
                    }
                }
            }
        }

        // ---- bandeja ----
        Rectangle {
            id: tray
            width: parent.width
            height: trayCol.implicitHeight + SetK.md * 2
            radius: SetK.innerRadius
            color: Theme.track
            border.width: 1
            border.color: root.dragging && !root.dTray && root.inRect(tray, root.dX, root.dY) ? Theme.accent : Theme.border
            Column {
                id: trayCol
                x: SetK.md; y: SetK.md; width: parent.width - SetK.md * 2; spacing: SetK.sm
                UiText { text: "Peças disponíveis"; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.DemiBold }
                UiText {
                    visible: !root.showPrompt && !root.showFetch
                    width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc
                    text: Terminal.loaded ? "Ligue o prompt ou as boas-vindas montados aqui (mais abaixo) para mexer nas peças." : "Procurando o que está instalado…"
                }
                UiText {
                    visible: (root.showPrompt && TermPrompt.hidden().length === 0) && (root.showFetch ? TermFetch.hidden().length === 0 : true)
                    width: parent.width; color: Theme.muted; font.pixelSize: SetK.fDesc
                    text: "Todas as peças estão em uso. Arraste uma para cá para tirar."
                }
                UiText { visible: root.showPrompt && TermPrompt.hidden().length > 0; text: "Prompt"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                Flow {
                    visible: root.showPrompt && TermPrompt.hidden().length > 0
                    width: parent.width; spacing: SetK.sm
                    Repeater { model: root.showPrompt ? TermPrompt.hidden() : []; delegate: trayChip }
                }
                UiText { visible: root.showFetch && TermFetch.hidden().length > 0; text: "Boas-vindas"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                Flow {
                    visible: root.showFetch && TermFetch.hidden().length > 0
                    width: parent.width; spacing: SetK.sm
                    Repeater { model: root.showFetch ? TermFetch.hidden() : []; delegate: trayChip }
                }
                UiText {
                    visible: root.showPrompt || root.showFetch
                    width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc
                    text: "Arraste as peças para reordenar, ou para fora e para dentro. Os controles abaixo fazem o mesmo."
                }
            }
        }
    }

    Component {
        id: trayChip
        Rectangle {
            id: tc
            required property string modelData
            readonly property string key: modelData
            readonly property string group: TermPrompt.piece(modelData) ? "prompt" : "fetch"
            readonly property var meta: root.meta(group, modelData)
            width: tcRow.implicitWidth + 20; height: 30; radius: 8
            color: tma.containsMouse ? Theme.tint(0.12) : Theme.card
            border.width: 1; border.color: tma.containsMouse ? Theme.accent : Theme.border
            opacity: root.dKey === key && root.dTray ? 0.3 : 1
            Row {
                id: tcRow
                anchors.centerIn: parent; spacing: 6
                UiIcon { anchors.verticalCenter: parent.verticalCenter; name: tc.meta.icon; size: 14; color: Theme.muted }
                UiText { anchors.verticalCenter: parent.verticalCenter; text: tc.meta.label; color: Theme.text; font.pixelSize: SetK.fDesc }
            }
            DragArea { id: tma; anchors.fill: parent; ctl: root; group: tc.group; key: tc.key; tray: true }
        }
    }

    // peca no ar durante o arrasto
    Rectangle {
        visible: root.dragging
        z: 100
        x: root.dX - width / 2; y: root.dY - height / 2
        width: gRow.implicitWidth + 20; height: 30; radius: 8
        color: Theme.cardHi; border.width: 1; border.color: Theme.accent
        Row {
            id: gRow
            anchors.centerIn: parent; spacing: 6
            UiIcon { anchors.verticalCenter: parent.verticalCenter; name: root.dragging ? root.meta(root.dGroup, root.dKey).icon : "info"; size: 14; color: Theme.accent }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: root.dragging ? root.meta(root.dGroup, root.dKey).label : ""; color: Theme.text; font.pixelSize: SetK.fDesc }
        }
    }
    // onde a peca vai cair
    Rectangle {
        visible: root.dragging && root.dIdx >= 0
        z: 90; color: Theme.accent; radius: 1
        x: root.marker.x; y: root.marker.y; width: root.marker.width; height: root.marker.height
    }
}
