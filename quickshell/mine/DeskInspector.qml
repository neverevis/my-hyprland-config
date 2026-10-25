// Inspetor do editor de widgets: painel lateral (do lado oposto ao widget escolhido) com cabecalho, previa ao vivo,
// abas Layout / Aparencia / Conteudo (cada secao do esquema cai numa aba: DeskState.tabOf), rodape fixo com as acoes.
// Fica dentro de um Loader: sem widget escolhido (ou fora da edicao) nada disso existe.
import QtQuick

Item {
    id: insp
    property var view: null                  // DeskView (para achar o cartao do widget escolhido)
    property rect area: Qt.rect(0, 0, 0, 0)
    property real winW: 0
    readonly property var w: { Settings.desktopWidgets; return DeskState.find(DeskState.selected) }
    readonly property string wtype: w ? w.type : ""
    readonly property var info: wtype !== "" ? DeskState.info(wtype) : null
    readonly property Item target: { if (!view) return null; for (let i = 0; i < view.count; i++) { const it = view.itemAt(i); if (it && it.wid === DeskState.selected) return it } return null }
    readonly property bool rightHalf: !target || target.x + target.width / 2 < winW / 2
    readonly property var allOpts: wtype !== "" ? DeskState.optionsOf(wtype).filter(d => d.key !== "card") : []
    readonly property var layoutLook: allOpts.filter(d => DeskState.tabOf(d) === "layout" && d.key === "look")
    readonly property var layoutRest: allOpts.filter(d => DeskState.tabOf(d) === "layout" && d.key !== "look")
    readonly property var lookOpts: allOpts.filter(d => DeskState.tabOf(d) === "look")
    readonly property var contentOpts: allOpts.filter(d => DeskState.tabOf(d) === "content")
    readonly property var tabList: [["layout", "Layout", "view_grid"], ["look", "Aparência", "palette"]].concat(contentOpts.length ? [["content", "Conteúdo", "listChecks"]] : [])
    readonly property string curTab: tabList.some(t => t[0] === DeskState.inspTab) ? DeskState.inspTab : "layout"
    readonly property bool hasLook: wtype !== "" && DeskState.defs[wtype] && DeskState.defs[wtype].look !== undefined
    property bool moreOpen: false

    width: 420
    height: Math.min(area.height, 780)
    x: rightHalf ? area.x + area.width - width : area.x
    y: area.y + (area.height - height) / 2
    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    property real k: 0
    Component.onCompleted: k = 1
    Behavior on k { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    opacity: k
    transform: Translate { x: (insp.rightHalf ? 1 : -1) * 14 * (1 - insp.k) }
    onWtypeChanged: moreOpen = false

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Theme.gl(Theme.bg, 1)
        border.width: 1; border.color: Theme.border
        // o painel nao deixa o clique cair no fundo (que fecharia a edicao)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
    }

    // pequenos titulos de bloco (iguais aos das secoes do formulario)
    component Head: Row {
        property string icon
        property string text
        spacing: 8
        Rectangle { width: 22; height: 22; radius: 7; color: Theme.tint(0.16)
            UiIcon { anchors.centerIn: parent; name: parent.parent.icon; size: 13; color: Theme.accent } }
        UiText { text: parent.text; color: Theme.text; font.pixelSize: 13; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
    }
    // formulario com as opcoes comuns do inspetor
    component InspForm: OptionsForm {
        width: parent ? parent.width : 300
        compact: true
        collapsible: true
        resettable: true
        sectionIcons: DeskState.secIcons
        openMap: DeskState.secOpen
        openPrefix: DeskState.inspTab + ":"
        onToggled: (key, on) => DeskState.setSecOpen(key, on)
        previewType: insp.wtype
        previewOpts: insp.w ? (insp.w.opts || {}) : ({})
        previewCols: insp.w ? insp.w.cols : 2
        previewRows: insp.w ? insp.w.rows : 2
        get: k => insp.w ? DeskState.opt(insp.w, k) : undefined
        set: (k, v) => { if (insp.w) DeskState.setOpt(insp.w.id, k, v) }
        isShown: d => insp.w ? DeskState.shown(insp.w, d) : false
        defOf: k => insp.wtype !== "" && DeskState.defs[insp.wtype] ? DeskState.defs[insp.wtype][k] : undefined
        reset: k => { if (insp.w) DeskState.resetOpt(insp.w.id, k) }
    }

    // ---- cabecalho ----
    Item {
        id: head
        x: 16; y: 14; width: parent.width - 32; height: 40
        Rectangle { id: hi; width: 40; height: 40; radius: 12; color: Theme.tint(0.18)
            UiIcon { anchors.centerIn: parent; name: insp.info ? insp.info.icon : "dashboard"; size: 20; color: Theme.accent } }
        Column {
            anchors { left: hi.right; leftMargin: 12; right: hc.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            UiText { width: parent.width; elide: Text.ElideRight; text: insp.info ? insp.info.name : ""; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
            UiText { width: parent.width; elide: Text.ElideRight; text: insp.info ? insp.info.desc : ""; color: Theme.muted; font.pixelSize: 12 }
        }
        UiButton { id: hc; anchors.right: parent.right; icon: "close"; kind: "ghost"; onClicked: DeskState.selected = "" }
    }
    // ---- previa ao vivo ----
    WidgetPreview {
        id: pv
        x: 16; y: head.y + head.height + 12; width: parent.width - 32; height: 138
        w: insp.w
    }
    UiSeg {
        id: tabs
        x: 16; y: pv.y + pv.height + 12; width: parent.width - 32
        fill: true
        options: insp.tabList
        value: insp.curTab
        onPicked: v => { DeskState.inspTab = v; sc.toTop() }
    }
    // ---- conteudo da aba ----
    DeskScroll {
        id: sc
        x: 10; y: tabs.y + tabs.height + 8
        width: parent.width - 20
        height: foot.y - y - 4
        contentHeight: tl.item ? tl.item.implicitHeight + 8 : 0
        Item {
            width: parent.width - 6
            Loader {
                id: tl
                x: 6
                width: parent.width - 6
                asynchronous: true
                sourceComponent: insp.curTab === "layout" ? layoutC : insp.curTab === "look" ? lookC : contentC
                opacity: status === Loader.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }
    }
    Component {
        id: layoutC
        Column {
            spacing: 10
            InspForm { visible: insp.layoutLook.length > 0; schema: insp.layoutLook }
            SizePicker {
                width: parent.width
                sizes: insp.info ? insp.info.sizes : []
                cols: insp.w ? insp.w.cols : 1
                rows: insp.w ? insp.w.rows : 1
                onPicked: (c, r) => DeskState.setSize(insp.w.id, c, r)
            }
            InspForm { schema: insp.layoutRest }
        }
    }
    Component {
        id: lookC
        Column {
            spacing: 10
            Head { icon: "cards"; text: "Fundo do cartão" }
            CardStylePicker {
                width: parent.width
                value: insp.w ? DeskState.opt(insp.w, "card") : "auto"
                onPicked: v => { if (insp.w) DeskState.setOpt(insp.w.id, "card", v) }
            }
            InspForm { schema: insp.lookOpts }
        }
    }
    Component {
        id: contentC
        Column {
            spacing: 10
            InspForm { schema: insp.contentOpts }
        }
    }

    // ---- rodape fixo ----
    Rectangle { x: 16; y: foot.y - 1; width: parent.width - 32; height: 1; color: Theme.border }
    Item {
        id: foot
        x: 16; y: parent.height - height - 14
        width: parent.width - 32; height: 34
        Row {
            spacing: 6
            UiButton { icon: "cards"; text: "Duplicar"; kind: "ghost"; onClicked: if (insp.w) DeskState.duplicate(insp.w.id) }
            UiButton { icon: "layers"; text: "Para a frente"; kind: "ghost"; onClicked: if (insp.w) DeskState.bringToFront(insp.w.id) }
        }
        Row {
            anchors.right: parent.right
            spacing: 6
            UiButton { icon: "dotsV"; kind: "ghost"; checked: insp.moreOpen; onClicked: insp.moreOpen = !insp.moreOpen }
            UiButton { icon: "trash"; kind: "danger"; onClicked: if (insp.w) DeskState.remove(insp.w.id) }
        }
    }

    // menu "mais" (copiar/colar estilo, composicao em todos), acima do rodape
    MouseArea { visible: insp.moreOpen; anchors.fill: parent; onClicked: insp.moreOpen = false }
    Rectangle {
        id: more
        visible: insp.moreOpen
        opacity: insp.moreOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        anchors { right: parent.right; rightMargin: 16; bottom: foot.top; bottomMargin: 8 }
        width: 270; height: mcol.implicitHeight + 12
        radius: 14
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.99)
        border.width: 1; border.color: Theme.border
        MouseArea { anchors.fill: parent }
        Column {
            id: mcol
            x: 6; y: 6; width: parent.width - 12
            Repeater {
                model: [
                    { icon: "copy", label: "Copiar estilo", ok: true, act: () => DeskState.copyStyle(insp.w.id) },
                    { icon: "paste", label: "Colar estilo", ok: !!DeskState.styleClip, act: () => DeskState.pasteStyle(insp.w.id) },
                    { icon: "layers", label: "Aplicar composição a todos", ok: insp.hasLook, act: () => DeskState.applyLookAll(insp.w.id) }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: mcol.width; height: 34; radius: 9
                    color: mm.containsMouse && modelData.ok ? Theme.cardHi : "transparent"
                    opacity: modelData.ok ? 1 : 0.4
                    UiIcon { id: mi; x: 10; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 16; color: Theme.muted }
                    UiText { anchors { left: mi.right; leftMargin: 10; verticalCenter: parent.verticalCenter } text: modelData.label; color: Theme.text; font.pixelSize: 13 }
                    MouseArea {
                        id: mm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: modelData.ok ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: { if (!modelData.ok || !insp.w) return; insp.moreOpen = false; modelData.act() }
                    }
                }
            }
        }
    }
}
