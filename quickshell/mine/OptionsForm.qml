// Formulario gerado a partir de um esquema de opcoes (ver DeskState.catalog): seg, switch, slider, text, font, color, image,
// list, tone. get(chave) -> valor atual; set(chave, valor) grava; isShown(def) decide as opcoes condicionais ("when").
// Com "sec" nas opcoes: blocos agrupados com titulo e icone (sectionIcons), linhas coladas como numa lista de ajustes.
// Por opcao: "icon", "desc" (texto de ajuda). Seg com icones (terceiro item de cada opcao) vira botoes com icone; com
// "preview" (e previewType) cada escolha aparece como o proprio widget em miniatura com aquele valor.
// Usado no inspetor da area de trabalho, na pagina Widgets e em outras paginas (sem "sec", fica uma lista simples).
import QtQuick

Column {
    id: form
    property var schema: []
    property var get: k => undefined
    property var set: (k, v) => {}
    property var isShown: d => true
    property bool compact: false
    property var sectionIcons: ({})
    // miniaturas: tipo do widget, opcoes atuais e tamanho (cols, rows)
    property string previewType: ""
    property var previewOpts: ({})
    property int previewCols: 2
    property int previewRows: 2
    width: parent ? parent.width : 320
    spacing: 0

    readonly property bool grouped: schema.some(d => !!d.sec)
    readonly property real pad: grouped ? (compact ? 10 : 12) : 0
    // primeira/ultima linha visivel de cada secao (para o titulo e os cantos do bloco)
    readonly property var places: {
        const out = {}, vis = schema.filter(d => isShown(d))
        for (let i = 0; i < vis.length; i++) {
            const d = vis[i], p = vis[i - 1], n = vis[i + 1]
            out[d.key] = { head: !p || p.sec !== d.sec, last: !n || n.sec !== d.sec }
        }
        return out
    }
    function merged(key, v) { const o = Object.assign({}, previewOpts || {}); if (v !== "same") o[key] = v; return o }

    Repeater {
        model: form.schema
        delegate: Column {
            id: row
            required property var modelData
            required property int index
            readonly property var place: form.places[modelData.key] ?? ({ head: true, last: true })
            readonly property bool shownNow: form.isShown(modelData)
            visible: shownNow
            width: form.width
            spacing: 0

            // titulo da secao
            Item {
                visible: form.grouped && row.place.head && !!row.modelData.sec
                width: parent.width
                height: visible ? (row.index > 0 ? 40 : 30) : 0
                Row {
                    anchors { left: parent.left; leftMargin: 4; bottom: parent.bottom; bottomMargin: 8 }
                    spacing: 8
                    Rectangle {
                        width: 22; height: 22; radius: 7
                        color: Theme.tint(0.16)
                        visible: !!form.sectionIcons[row.modelData.sec]
                        UiIcon { anchors.centerIn: parent; name: form.sectionIcons[row.modelData.sec] ?? ""; size: 13; color: Theme.accent }
                    }
                    UiText { text: row.modelData.sec ?? ""; color: Theme.text; font.pixelSize: 13; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            // bloco: linhas coladas, cantos arredondados so no comeco e no fim da secao
            Rectangle {
                width: parent.width
                height: ld.height + form.pad * 2
                color: form.grouped ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.045) : "transparent"
                topLeftRadius: row.place.head ? 14 : 3; topRightRadius: topLeftRadius
                bottomLeftRadius: row.place.last ? 14 : 3; bottomRightRadius: bottomLeftRadius
                Loader {
                    id: ld
                    x: form.pad; y: form.pad
                    width: parent.width - form.pad * 2
                    active: row.shownNow
                    sourceComponent: ({ seg: row.modelData.preview && form.previewType !== "" ? previewC : segC, switch: switchC, slider: sliderC, text: textC, font: fontC, color: colorC, image: imageC, list: listC, tone: toneC })[row.modelData.type] ?? null
                    property var def: row.modelData
                    property var val: form.get(row.modelData.key)
                }
            }
            // espaco: fino dentro da secao, maior entre itens soltos
            Item { width: 1; height: form.grouped ? (row.place.last ? 0 : 2) : (form.compact ? 8 : 12) }
        }
    }

    // rotulo com icone (e ajuda embaixo)
    component FormLabel: Column {
        id: lb
        property var dd: ({})
        width: parent ? parent.width : 300
        spacing: 2
        Row {
            spacing: 8
            UiIcon { visible: !!lb.dd.icon; name: lb.dd.icon ?? ""; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: lb.dd.label ?? ""; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
        UiText { visible: !!lb.dd.desc; width: parent.width; text: lb.dd.desc ?? ""; color: Theme.muted; font.pixelSize: 11; wrapMode: Text.WordWrap }
    }

    Component {
        id: segC
        Column {
            id: sc
            readonly property var dd: parent ? parent.def : ({})
            readonly property var vv: parent ? parent.val : undefined
            readonly property bool icons: (dd.options ?? []).some(o => !!o[2])
            spacing: 8
            FormLabel { dd: sc.dd }
            Flow {
                width: sc.width
                spacing: 5
                Repeater {
                    model: sc.dd.options ?? []
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: sc.vv === modelData[0]
                        height: 30; width: chip.implicitWidth + 22; radius: 10
                        color: on ? Theme.accent : (cm.containsMouse ? Theme.cardHi : Theme.track)
                        border.width: 1; border.color: on ? Theme.accent : Theme.border
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Row {
                            id: chip
                            anchors.centerIn: parent
                            spacing: 6
                            UiIcon { visible: !!modelData[2]; name: modelData[2] ?? ""; size: 14; color: parent.parent.on ? Theme.accentText : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                            UiText { text: modelData[1]; color: parent.parent.on ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: parent.parent.on ? Font.DemiBold : Font.Normal; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: form.set(sc.dd.key, modelData[0]) }
                    }
                }
            }
        }
    }
    // escolhas como miniaturas do proprio widget
    Component {
        id: previewC
        Column {
            id: pc
            readonly property var dd: parent ? parent.def : ({})
            readonly property var vv: parent ? parent.val : undefined
            readonly property real nw: DeskState.px(form.previewCols) - 36
            readonly property real nh: DeskState.px(form.previewRows) - 36
            readonly property real tw: form.compact ? 82 : 100
            readonly property real th: Math.round(tw * Math.max(0.58, Math.min(1, nh / nw)))
            spacing: 8
            FormLabel { dd: pc.dd }
            Flow {
                width: pc.width
                spacing: 8
                Repeater {
                    model: pc.dd.options ?? []
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        readonly property bool on: pc.vv === modelData[0]
                        width: pc.tw; height: pc.th + 26; radius: 14
                        color: on ? Theme.tint(0.14) : (tm.containsMouse ? Theme.cardHi : Theme.track)
                        border.width: on ? 2 : 1; border.color: on ? Theme.accent : Theme.border
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Item {
                            id: stage
                            x: 6; y: 6
                            width: parent.width - 12; height: pc.th - 8
                            clip: true
                            Loader {
                                anchors.centerIn: parent
                                width: pc.nw; height: pc.nh
                                scale: Math.min(stage.width / pc.nw, stage.height / pc.nh)
                                sourceComponent: DeskWidgets.component(form.previewType)
                                onLoaded: {
                                    item.cols = form.previewCols; item.rows = form.previewRows
                                    item.opts = Qt.binding(() => form.merged(pc.dd.previewAs ?? pc.dd.key, tile.modelData[0]))
                                }
                            }
                        }
                        Row {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
                            spacing: 4
                            UiIcon { visible: tile.on; name: "check"; size: 12; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            UiText { text: tile.modelData[1]; color: tile.on ? Theme.accent : Theme.text; font.pixelSize: 11; font.weight: tile.on ? Font.Bold : Font.Normal; anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight; width: Math.min(implicitWidth, pc.tw - (tile.on ? 24 : 8)) }
                        }
                        // a miniatura e so imagem: o clique e do cartao
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: form.set(pc.dd.key, tile.modelData[0]) }
                    }
                }
            }
        }
    }
    Component {
        id: switchC
        UiSwitch { readonly property var dd: parent ? parent.def : ({}); label: dd.label ?? ""; icon: dd.icon ?? ""; description: dd.desc ?? ""; checked: !!(parent && parent.val); onToggled: on => form.set(dd.key, on) }
    }
    Component {
        id: sliderC
        Column {
            id: slc
            readonly property var dd: parent ? parent.def : ({})
            readonly property var vv: parent ? parent.val : undefined
            spacing: 0
            UiSlider {
                width: slc.width
                label: slc.dd.label ?? ""
                icon: slc.dd.icon ?? ""
                from: slc.dd.from; to: slc.dd.to
                value: slc.vv ?? slc.dd.def ?? slc.dd.from
                suffix: slc.dd.suffix ?? ""
                onMoved: v => { const st = slc.dd.step ?? 1; form.set(slc.dd.key, Math.round(v / st) * st) }
            }
            UiText { visible: !!slc.dd.desc; width: slc.width; topPadding: 4; text: slc.dd.desc ?? ""; color: Theme.muted; font.pixelSize: 11; wrapMode: Text.WordWrap }
        }
    }
    Component {
        id: textC
        Column {
            id: tc
            readonly property var dd: parent ? parent.def : ({})
            readonly property var vv: parent ? parent.val : undefined
            spacing: 8
            FormLabel { dd: tc.dd }
            Rectangle {
                width: tc.width; height: tc.dd.multiline ? 84 : 34; radius: 10
                color: Theme.track; border.width: 1; border.color: te.activeFocus ? Theme.accent : Theme.border
                TextEdit {
                    id: te
                    font.family: Theme.font
                    anchors { fill: parent; margins: 9 }
                    text: tc.vv ?? ""
                    color: Theme.text; font.pixelSize: 13
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                    clip: true
                    Keys.onReturnPressed: e => { if (!tc.dd.multiline || (e.modifiers & Qt.ControlModifier)) { focus = false; e.accepted = true } else e.accepted = false }
                    onActiveFocusChanged: if (!activeFocus) form.set(tc.dd.key, text)
                    onTextChanged: if (activeFocus && !tc.dd.enterOnly) saveT.restart()
                    Timer { id: saveT; interval: 600; onTriggered: form.set(tc.dd.key, te.text) }
                }
            }
        }
    }
    Component {
        id: listC
        Column {
            id: lc
            readonly property var dd: parent ? parent.def : ({})
            readonly property var vv: parent ? parent.val : undefined
            spacing: 8
            FormLabel { dd: lc.dd }
            Rectangle {
                width: lc.width; height: Math.max(60, le.contentHeight + 18); radius: 10
                color: Theme.track; border.width: 1; border.color: le.activeFocus ? Theme.accent : Theme.border
                TextEdit {
                    id: le
                    anchors { fill: parent; margins: 9 }
                    text: Settings.list(lc.vv).join("\n")
                    color: Theme.text; font.pixelSize: 13; font.family: Theme.mono
                    selectByMouse: true
                    onActiveFocusChanged: if (!activeFocus) form.set(lc.dd.key, text.split("\n").map(s => s.trim()).filter(s => s !== ""))
                }
            }
        }
    }
    Component {
        id: fontC
        Column {
            id: fc
            readonly property var dd: parent ? parent.def : ({})
            readonly property var vv: parent ? parent.val : undefined
            spacing: 8
            property bool openList: false
            readonly property var families: Qt.fontFamilies()
            readonly property var matches: { const q = ff.text.toLowerCase(); return families.filter(f => q === "" || f.toLowerCase().includes(q)).slice(0, 8) }
            Row {
                spacing: 8
                UiIcon { name: fc.dd.icon ?? "font"; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: fc.dd.label ?? ""; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: fc.vv ? "" : "(a do shell)"; color: Theme.muted; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            }
            UiField {
                id: ff
                width: fc.width
                text: fc.vv ?? ""
                placeholderText: "Digite para buscar uma fonte instalada…"
                font.family: text !== "" && fc.families.indexOf(text) >= 0 ? text : font.family
                onActiveFocusChanged: if (activeFocus) fc.openList = true
                onAccepted: { fc.openList = false; form.set(fc.dd.key, text) }
            }
            Column {
                visible: fc.openList
                width: fc.width
                spacing: 2
                Repeater {
                    model: fc.openList ? fc.matches.concat([""]) : []
                    delegate: Rectangle {
                        required property var modelData
                        width: fc.width; height: 34; radius: 8
                        color: fm.containsMouse ? Theme.cardHi : "transparent"
                        UiText { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } text: modelData === "" ? "Usar a fonte do shell" : modelData
                            font.family: modelData === "" ? Theme.font : modelData; font.pixelSize: 15; color: modelData === "" ? Theme.muted : Theme.text }
                        UiText { visible: modelData !== ""; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } text: "12:34 Aa"
                            font.family: modelData; font.pixelSize: 15; color: Theme.muted }
                        MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { ff.text = modelData; fc.openList = false; form.set(fc.dd.key, modelData) } }
                    }
                }
            }
        }
    }
    Component {
        id: toneC
        ToneSwatches {
            readonly property var dd: parent ? parent.def : ({})
            width: parent ? parent.width : 300
            label: dd.label ?? ""
            value: (parent ? parent.val : undefined) ?? "global"
            allowGlobal: true
            custom: form.get("fgColor") || "#ffffff"
            onPicked: v => form.set(dd.key, v)
        }
    }
    Component {
        id: colorC
        ColorField { readonly property var dd: parent ? parent.def : ({}); label: dd.label ?? ""; value: (parent ? parent.val : "") || "#ffffff"; onPicked: c => form.set(dd.key, c.toString()) }
    }
    Component {
        id: imageC
        // miniatura + nome + botao; o nome encolhe (reticencias) para o botao caber sempre
        Item {
            id: ic
            readonly property var dd: parent ? parent.def : ({})
            readonly property var vv: parent ? parent.val : undefined
            width: parent ? parent.width : 300
            height: 52
            Rectangle {
                id: ith
                width: 68; height: 48; radius: 10; color: Theme.track; clip: true
                anchors.verticalCenter: parent.verticalCenter
                border.width: 1; border.color: Theme.border
                Image { anchors.fill: parent; source: ic.vv ? "file://" + ic.vv : ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(136, 96); asynchronous: true }
                UiIcon { visible: !ic.vv; anchors.centerIn: parent; name: "image"; size: 18; color: Theme.muted }
            }
            Column {
                anchors { left: ith.right; leftMargin: 10; right: ib.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 4
                UiText { width: parent.width; elide: Text.ElideRight; text: ic.dd.label ?? ""; color: Theme.text; font.pixelSize: 13 }
                UiText { width: parent.width; elide: Text.ElideMiddle; text: ic.vv ? ic.vv.split("/").pop() : "nenhuma"; color: Theme.muted; font.pixelSize: 11 }
            }
            UiButton {
                id: ib
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                icon: "folderOpen"; text: form.compact ? "" : "Escolher…"
                onClicked: { const k = ic.dd.key; Pick.image("Imagem do widget", p => form.set(k, p)) }
            }
        }
    }
}
