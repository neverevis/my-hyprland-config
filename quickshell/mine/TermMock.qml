// Maquete do terminal escolhido (pagina Terminal): barra de icones (pecas que arrastam + ajustes em popover) e a janela com a
// transparencia, imagem de fundo, margem, fonte e cursor de verdade. O normal e a saida de verdade (fastfetch/starship, TermReal);
// com o mouse em cima ou durante um arrasto ela some num fade e aparecem as pecas (chips) para arrastar e reordenar.
// A imagem das boas-vindas e uma so, por cima das duas visoes: selecionavel (contorno + 4 cantos que mudam o tamanho em colunas inteiras)
// e com menu (trocar, ajustar com recorte e zoom, tirar). Nada roda parado: o cursor so pisca com a janela visivel e a opcao ligada.
import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: root
    width: parent ? parent.width : 600
    height: col.implicitHeight

    readonly property bool showPrompt: Terminal.starship && TermPrompt.on
    readonly property bool showFetch: Terminal.fastfetch   // aparece sempre: editar aqui liga as boas-vindas do shell
    readonly property int fpx: Math.max(12, Math.min(18, Math.round(Terminal.fontPt * 1.33)))
    readonly property int lineH: Math.round(fpx * 1.5)
    readonly property real opq: (Terminal.look("opacity") ?? 100) / 100
    readonly property color termBg: real.pal.bg !== "" ? real.pal.bg : Qt.darker(Theme.card, 1.5)
    readonly property color termFg: real.pal.fg !== "" ? real.pal.fg : Theme.text
    // pecas (chips) so com o mouse na maquete, durante um arrasto, no destaque de uma peca ou se a saida de verdade falhou
    readonly property bool org: hov.hovered || dragging || flashP > 0 || (real.settled && !real.ok)
    property real pOrg: org ? 1 : 0
    Behavior on pOrg { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    property real chipH: 0
    readonly property int rounding: HyprConf.value("decoration:rounding") ?? 12
    readonly property int bw: HyprConf.value("general:border_size") ?? 1
    readonly property bool blurOn: Settings.blurEnabled && opq < 1
    readonly property real scl: root.fpx / Math.max(1, Terminal.fontPt * 1.33)
    // imagem: colunas do terminal; durante o arrasto de um canto vale a escolha provisoria
    property int dragCols: 0
    property int dSx: 1
    property int dSy: 1
    property real dW0: 0
    property real dH0: 0
    readonly property bool resizing: dragCols > 0
    readonly property int imgCols: dragCols > 0 ? dragCols : TermFetch.imgSize
    readonly property real imgW: imgCols > 0 ? imgCols * charW : 112
    readonly property real imgH: fImg.status === Image.Ready && fImg.implicitWidth > 0 ? Math.max(20, Math.round(imgW * fImg.implicitHeight / fImg.implicitWidth)) : Math.min(imgW, 112)
    readonly property real imgOffX: resizing && dSx < 0 ? dW0 - imgW : 0     // o canto oposto ao puxado fica parado
    readonly property real imgOffY: resizing && dSy < 0 ? dH0 - imgH : 0
    readonly property string imgUrl: TermFetch.image === "" ? "" : "file://" + TermFetch.image + (TermFetch.image === TermFetch.logo ? "?v=" + TermFetch.imgStamp : "")
    TermReal { id: real; cols: Math.max(20, Math.floor((mock.width - mock.pad * 2) / Math.max(1, root.charW))) }
    readonly property string bgImg: Terminal.hasImage ? (Terminal.look("image") || "") : ""
    readonly property string layout: Terminal.look("layout") || "tile"
    readonly property real charW: tm.advanceWidth
    TextMetrics { id: tm; font.family: Terminal.fontFamily; font.pixelSize: root.fpx; text: "M" }

    // destaque curto de uma peca (clicar num icone ja em uso mostra onde ela esta na maquete)
    property string flashKey: ""
    property real flashP: 0
    function flash(k) { flashKey = k; flashAnim.restart() }
    SequentialAnimation {
        id: flashAnim
        NumberAnimation { target: root; property: "flashP"; to: 1; duration: 120 }
        PauseAnimation { duration: 800 }
        NumberAnimation { target: root; property: "flashP"; to: 0; duration: 260 }
    }

    // ---- arrastar (um controlador so; as pecas so avisam) ----
    property string dGroup: ""      // prompt | fetch | flag (erro) | image
    property string dKey: ""
    property bool dTray: false      // veio da barra de icones
    property real dX: 0
    property real dY: 0
    property int dIdx: -1
    property rect marker: Qt.rect(0, 0, 0, 0)
    readonly property bool dragging: dGroup !== ""
    function api(g) { return g === "prompt" ? TermPrompt : TermFetch }
    function meta(g, k) {
        if (g === "prompt") return TermPrompt.piece(k)
        if (g === "flag") return { icon: "info", label: "Erro do último comando" }
        if (g === "image") return { icon: "image", label: "Imagem" }
        return TermFetch.item(k)
    }
    function rep(g) { const c = chipL.item; return c ? (g === "prompt" ? c.pRep : c.fRep) : null }
    function startDrag(g, k, tray) { dGroup = g; dKey = k; dTray = tray; dIdx = -1 }
    function inRect(it, x, y) { const p = it.mapToItem(root, 0, 0); return x >= p.x && x <= p.x + it.width && y >= p.y && y <= p.y + it.height }
    function items(g) { const r = rep(g), l = []; if (!r) return l; for (let i = 0; i < r.count; i++) { const it = r.itemAt(i); if (it && it.key !== dKey) l.push(it) } return l }
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
        if (l.length === 0) { const c = g === "prompt" ? chipL.item?.pFlow : chipL.item?.fCol; if (!c) return Qt.rect(0, 0, 0, 0); const p = c.mapToItem(root, 0, 0); return Qt.rect(p.x, p.y, vert ? 40 : 2, vert ? 2 : root.lineH) }
        const last = idx >= l.length, it = l[last ? l.length - 1 : idx], p = it.mapToItem(root, 0, 0)
        if (vert) return Qt.rect(p.x, p.y + (last ? it.height : 0) - 1, it.width, 2)
        return Qt.rect(p.x + (last ? it.width : 0) - 1, p.y, 2, it.height)
    }
    function moveDrag(x, y) {
        dX = x; dY = y
        if (!inRect(mock, x, y)) { dIdx = -1; marker = Qt.rect(0, 0, 0, 0); return }
        if (dGroup === "flag" || dGroup === "image") { dIdx = 0; marker = Qt.rect(0, 0, 0, 0); return }
        dIdx = indexAt(dGroup, x, y)
        marker = markerFor(dGroup, dIdx)
    }
    // poe a peca na posicao idx; ligar o prompt/boas-vindas faz parte da edicao
    function place(g, k, idx) {
        if (g === "prompt") { if (!TermPrompt.on) TermPrompt.set("on", true); TermPrompt.place(k, idx) }
        else { TermFetch.place(k, idx); if (!TermFetch.on) TermFetch.set("on", true) }
    }
    // soltar dentro da maquete poe/reordena; soltar fora (na barra ou em qualquer lugar) tira a peca que estava na maquete
    function endDrag() {
        const g = dGroup, k = dKey, idx = dIdx, fromTray = dTray
        if (g === "") return
        dGroup = ""; dKey = ""; dIdx = -1
        if (g === "prompt" || g === "fetch") {
            if (idx >= 0) place(g, k, idx)
            else if (!fromTray) api(g).remove(k)
        } else if (g === "flag") { if (idx >= 0) TermPrompt.set("err", true) }
        else if (g === "image") { if (idx >= 0) toolClick("image", "image") }
    }
    // clique num icone da barra: poe o que nao esta em uso, mostra onde esta o que ja esta
    function toolClick(g, k) {
        if (g === "flag") { TermPrompt.set("err", !TermPrompt.get("err")); return }
        if (g === "image" || k === "image") { if (TermFetch.image === "") pickImage(); else flash("image"); return }
        if (tbar.used(g, k)) flash(k)
        else place(g, k, 9999)
    }
    function pickImage() { Pick.image("Imagem das boas-vindas", p => TermFetch.set("image", p)) }

    // ---- menu da imagem e editor de recorte ----
    property bool menuOpen: false
    property real menuX: 0
    property real menuY: 0
    property bool cropOpen: false
    property string cropSrc: ""
    function openMenu() {
        if (TermFetch.image === "") { pickImage(); return }
        const p = imgLay.mapToItem(root, 0, 0)
        menuX = Math.max(4, Math.min(p.x, root.width - 214))
        menuY = p.y + imgLay.height + 6
        if (menuY + 128 > root.height) menuY = Math.max(4, root.height - 132)
        menuOpen = true
    }
    function openCrop() {
        cropSrc = TermFetch.image === TermFetch.logo && TermFetch.imageSrc !== "" ? TermFetch.imageSrc : TermFetch.image
        menuOpen = false
        cropOpen = true
    }

    // cursor da maquete (o das pecas fica em cursorLine)
    component Cur: Item {
        id: cu
        property var ctl
        width: ctl.charW; height: ctl.lineH - 4
        Rectangle {
            readonly property string shape: Terminal.look("cursor") || "block"
            color: cu.ctl.termFg
            width: shape === "beam" ? 2 : parent.width
            height: shape === "underline" ? 2 : parent.height
            y: shape === "underline" ? parent.height - 2 : 0
            SequentialAnimation on opacity {
                running: cu.visible && cu.ctl.visible && Terminal.look("blink") === true
                loops: Animation.Infinite
                NumberAnimation { to: 0; duration: 500 }
                NumberAnimation { to: 1; duration: 500 }
            }
        }
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

        TermToolbar { id: tbar; ctl: root }

        // ---- a janela ----
        Rectangle {
            id: mock
            width: parent.width
            height: Math.max(220, Math.max(realCol.implicitHeight, root.chipH) + mock.pad * 2 + 8)
            radius: Math.min(root.rounding, 24)
            clip: true
            color: "transparent"
            border.width: Math.max(1, root.bw); border.color: Theme.border
            readonly property int pad: Math.max(8, Math.min(60, Math.round((Terminal.look("pad") ?? 0) * root.scl)))
            HoverHandler { id: hov }

            // fundo desfocado como o Hyprland faz em janelas transparentes (so com o blur ligado e a janela translucida)
            Image {
                id: wpImg
                anchors.fill: parent; asynchronous: true; fillMode: Image.PreserveAspectCrop; sourceSize.width: 600
                source: Wallpaper.stillUrl(Wallpaper.current)
            }
            Loader {
                anchors.fill: parent
                active: root.blurOn && mock.visible
                sourceComponent: Item {
                    ShaderEffectSource { id: wpSrc; anchors.fill: parent; sourceItem: wpImg; hideSource: true; visible: false }
                    MultiEffect {
                        anchors.fill: parent; source: wpSrc; autoPaddingEnabled: false
                        blurEnabled: true; blur: 1
                        blurMax: Math.max(4, Math.min(64, Math.round(Settings.blurSize * Settings.blurPasses * 1.6)))
                    }
                }
            }
            Rectangle { anchors.fill: parent; color: root.termBg; opacity: root.opq }
            Image {
                visible: root.bgImg !== ""
                anchors.fill: parent; asynchronous: true; opacity: root.opq; sourceSize.width: 900
                source: root.bgImg !== "" ? "file://" + root.bgImg : ""
                fillMode: root.layout === "fill" ? Image.PreserveAspectCrop : root.layout === "fit" ? Image.PreserveAspectFit : root.layout === "center" ? Image.Pad : Image.Tile
            }
            Rectangle { visible: root.bgImg !== ""; anchors.fill: parent; color: root.termBg; opacity: ((Terminal.look("tint") ?? 0) / 100) * root.opq }
            UiText {
                visible: root.pOrg < 0.5 && (root.showPrompt || root.showFetch)
                anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
                text: "Passe o mouse para mover as peças"; color: Theme.text; opacity: 0.45; font.pixelSize: 11
            }

            // saida de verdade do fastfetch e do starship
            Column {
                id: realCol
                visible: root.pOrg < 0.99
                opacity: 1 - root.pOrg
                x: mock.pad; y: mock.pad
                width: mock.width - mock.pad * 2
                Row {
                    visible: real.fetchHtml !== "" || TermFetch.canImage
                    spacing: SetK.lg
                    bottomPadding: root.lineH
                    Item { visible: TermFetch.canImage; width: root.imgW; height: root.imgH }   // a imagem em si fica por cima (imgLay)
                    UiText {
                        visible: real.fetchHtml !== ""
                        text: real.fetchHtml; textFormat: Text.RichText; wrapMode: Text.NoWrap; color: root.termFg
                        font.family: Terminal.fontFamily; font.pixelSize: root.fpx; lineHeight: root.lineH; lineHeightMode: Text.FixedHeight
                    }
                }
                UiText {
                    visible: real.promptHtml !== ""
                    text: real.promptHtml; textFormat: Text.RichText; wrapMode: Text.NoWrap; color: root.termFg
                    font.family: Terminal.fontFamily; font.pixelSize: root.fpx; lineHeight: root.lineH; lineHeightMode: Text.FixedHeight
                }
                Row {
                    UiText {
                        text: real.promptLast !== "" ? real.promptLast : "$&nbsp;"; textFormat: Text.RichText; wrapMode: Text.NoWrap; color: root.termFg
                        font.family: Terminal.fontFamily; font.pixelSize: root.fpx; height: root.lineH; verticalAlignment: Text.AlignVCenter
                    }
                    Item { width: root.charW; height: root.lineH; Cur { ctl: root; anchors.verticalCenter: parent.verticalCenter } }
                }
            }

            // pecas arrastaveis (so existem com o mouse em cima, no arrasto ou no destaque)
            Loader {
                id: chipL
                active: root.org || root.pOrg > 0.01
                opacity: root.pOrg
                x: mock.pad; y: mock.pad
                width: mock.width - mock.pad * 2
                sourceComponent: chipsC
            }

            // ---- a imagem das boas-vindas (por cima das duas visoes) ----
            Item {
                id: imgLay
                visible: root.showFetch && TermFetch.canImage
                z: 6
                x: mock.pad + root.imgOffX; y: mock.pad + root.imgOffY
                width: root.imgW; height: root.imgH
                property int hcount: 0
                readonly property bool sel: imgMa.containsMouse || hcount > 0 || root.resizing || root.menuOpen || (root.flashKey === "image" && root.flashP > 0)
                Rectangle {
                    anchors.fill: parent; radius: 8; clip: true; color: "transparent"
                    border.width: fImg.status === Image.Ready ? 0 : 1; border.color: Theme.border
                    Image { id: fImg; anchors.fill: parent; asynchronous: true; fillMode: Image.PreserveAspectFit; sourceSize.width: 512; source: root.imgUrl }
                    Column {
                        visible: fImg.status !== Image.Ready
                        anchors.centerIn: parent; spacing: 4
                        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "image"; size: 22; color: Theme.muted }
                        UiText { text: TermFetch.image === "" ? "Sem imagem" : "Carregando…"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                    }
                }
                Rectangle {
                    anchors.fill: parent; radius: 8; color: "transparent"; border.width: 1; border.color: Theme.accent; opacity: imgLay.sel ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
                MouseArea { id: imgMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openMenu() }
                // 4 cantos: mudam a largura em colunas inteiras (10 a 60), mantendo a proporcao; o canto oposto fica parado
                Repeater {
                    model: [[-1, -1], [1, -1], [-1, 1], [1, 1]]
                    delegate: Rectangle {
                        id: hd
                        required property var modelData
                        readonly property int sx: modelData[0]
                        readonly property int sy: modelData[1]
                        visible: imgLay.sel && !root.menuOpen && TermFetch.image !== ""
                        x: (sx > 0 ? imgLay.width : 0) - width / 2; y: (sy > 0 ? imgLay.height : 0) - height / 2
                        width: 13; height: 13; radius: 3; z: 3
                        color: Theme.bg; border.width: 2; border.color: Theme.accent
                        MouseArea {
                            id: hm
                            anchors.centerIn: parent; width: 28; height: 28
                            hoverEnabled: true
                            cursorShape: hd.sx * hd.sy > 0 ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                            property real x0: 0
                            property real y0: 0
                            property real w0: 0
                            property real h0: 0
                            onContainsMouseChanged: imgLay.hcount += containsMouse ? 1 : -1
                            onPressed: m => {
                                const q = mapToItem(root, m.x, m.y)
                                x0 = q.x; y0 = q.y; w0 = root.imgW; h0 = root.imgH
                                root.dSx = hd.sx; root.dSy = hd.sy; root.dW0 = w0; root.dH0 = h0
                                root.dragCols = Math.max(10, Math.min(60, Math.round(w0 / root.charW)))
                            }
                            onPositionChanged: m => {
                                if (!pressed) return
                                const q = mapToItem(root, m.x, m.y)
                                const dwx = hd.sx * (q.x - x0), dwy = hd.sy * (q.y - y0) * (w0 / Math.max(1, h0))
                                const dw = Math.abs(dwx) >= Math.abs(dwy) ? dwx : dwy
                                root.dragCols = Math.max(10, Math.min(60, Math.round((w0 + dw) / root.charW)))
                            }
                            onReleased: { const c = root.dragCols; root.dragCols = 0; if (c > 0) TermFetch.set("imgSize", c) }
                            onCanceled: root.dragCols = 0
                        }
                    }
                }
            }
        }
    }

    // ---- pecas da maquete (prompt, boas-vindas) ----
    Component {
        id: chipsC
        Column {
            id: content
            spacing: 0
            property alias pRep: pRep
            property alias fRep: fRep
            property alias pFlow: pFlow
            property alias fCol: fCol
            onImplicitHeightChanged: root.chipH = implicitHeight
            Component.onCompleted: root.chipH = implicitHeight

            // boas-vindas: imagem + linhas
            Row {
                visible: root.showFetch
                spacing: SetK.lg
                bottomPadding: root.lineH
                Item { visible: TermFetch.canImage; width: root.imgW; height: root.imgH }
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
                            Rectangle { anchors.fill: parent; anchors.margins: -1; radius: 5; color: Theme.tint(0.25); opacity: root.flashKey === fl.key ? root.flashP : 0; border.width: 1; border.color: Theme.accent }
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
                            TermDrag { id: fda; anchors.fill: parent; ctl: root; group: "fetch"; key: fl.key }
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
                        Rectangle { anchors.fill: parent; anchors.margins: -1; radius: 5; color: Theme.tint(0.25); opacity: root.flashKey === pc.key ? root.flashP : 0; border.width: 1; border.color: Theme.accent }
                        HoverHandler { id: ph }
                        Row {
                            id: pcRow
                            anchors.verticalCenter: parent.verticalCenter; x: 2
                            Repeater { model: TermPrompt.pieceSegs(pc.key); delegate: UiText { required property var modelData; text: modelData.t; color: modelData.c; font.bold: modelData.b; font.family: Terminal.fontFamily; font.pixelSize: root.fpx; textFormat: Text.PlainText } }
                        }
                        TermDrag { id: pda; anchors.fill: parent; ctl: root; group: "prompt"; key: pc.key }
                        DropX { visible: (ph.hovered || pda.containsMouse) && !root.dragging; x: parent.width - 10; y: -7; z: 3; ctl: root; group: "prompt"; key: pc.key }
                    }
                }
                Row { visible: !TermPrompt.get("two") || !root.showPrompt; height: root.lineH; Loader { sourceComponent: cursorLine } }
            }
            Row { visible: root.showPrompt && TermPrompt.get("two"); height: root.lineH; Loader { sourceComponent: cursorLine } }
        }
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
                    readonly property string shape: Terminal.look("cursor") || "block"
                    color: Theme.text
                    width: shape === "beam" ? 2 : parent.width
                    height: shape === "underline" ? 2 : parent.height
                    y: shape === "underline" ? parent.height - 2 : 0
                    SequentialAnimation on opacity {
                        running: mock.visible && root.pOrg > 0.5 && Terminal.look("blink") === true && !root.dragging
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }
            }
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
        visible: root.dragging && root.dIdx >= 0 && root.marker.width > 0
        z: 90; color: Theme.accent; radius: 1
        x: root.marker.x; y: root.marker.y; width: root.marker.width; height: root.marker.height
    }

    // ---- menu da imagem (so existe aberto) ----
    Loader {
        active: root.menuOpen
        z: 60
        x: 0; y: 0; width: root.width; height: root.height
        sourceComponent: Item {
            focus: true
            Component.onCompleted: forceActiveFocus()
            Keys.onEscapePressed: root.menuOpen = false
            MouseArea { x: -4000; y: -4000; width: 8000; height: 8000; onPressed: root.menuOpen = false }
            Rectangle {
                x: root.menuX; y: root.menuY; width: 210; height: mcol.implicitHeight + 12
                radius: 14; color: Theme.gl(Theme.bg, 1); border.width: 1; border.color: Theme.border
                MouseArea { anchors.fill: parent }
                opacity: 0; scale: 0.96; transformOrigin: Item.TopLeft
                Component.onCompleted: { opacity = 1; scale = 1 }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Column {
                    id: mcol
                    x: 6; y: 6; width: parent.width - 12
                    Repeater {
                        model: [["folderOpen", "Trocar imagem", "pick"], ["crop", "Ajustar (cortar e zoom)", "crop"], ["trash", "Sem imagem", "none"]]
                        delegate: Rectangle {
                            id: mi
                            required property var modelData
                            width: parent.width; height: 36; radius: 9
                            color: mia.containsMouse ? Theme.cardHi : "transparent"
                            Row {
                                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                                spacing: 10
                                UiIcon { anchors.verticalCenter: parent.verticalCenter; name: mi.modelData[0]; size: 17; color: mi.modelData[2] === "none" ? Theme.danger : Theme.muted }
                                UiText { anchors.verticalCenter: parent.verticalCenter; text: mi.modelData[1]; color: Theme.text; font.pixelSize: 13 }
                            }
                            MouseArea {
                                id: mia; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const a = mi.modelData[2]
                                    root.menuOpen = false
                                    if (a === "pick") root.pickImage()
                                    else if (a === "crop") root.openCrop()
                                    else TermFetch.set("image", "none")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- editor de recorte (so existe aberto) ----
    Loader {
        active: root.cropOpen
        z: 80
        x: 0; y: 0; width: root.width; height: root.height
        sourceComponent: TermCrop { src: root.cropSrc; onClosed: root.cropOpen = false }
    }
}
