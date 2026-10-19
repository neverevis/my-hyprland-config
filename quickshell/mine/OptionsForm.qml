// Formulario gerado a partir de um esquema de opcoes (ver DeskState.catalog): seg, switch, slider, text, font, color, image, list.
// get(chave) -> valor atual; set(chave, valor) grava; isShown(def) decide as opcoes condicionais ("when").
// Usado no inspetor da area de trabalho e na pagina Widgets: as duas telas sempre mostram as mesmas opcoes.
import QtQuick

Column {
    id: form
    property var schema: []
    property var get: k => undefined
    property var set: (k, v) => {}
    property var isShown: d => true
    property bool compact: false
    width: parent ? parent.width : 320
    spacing: compact ? 8 : 12

    Repeater {
        model: form.schema
        delegate: Loader {
            id: ld
            required property var modelData
            width: form.width
            active: form.isShown(modelData)
            visible: active
            sourceComponent: ({ seg: segC, switch: switchC, slider: sliderC, text: textC, font: fontC, color: colorC, image: imageC, list: listC, tone: toneC })[modelData.type] ?? null
            property var def: modelData
            property var val: form.get(modelData.key)
        }
    }

    Component {
        id: segC
        Column {
            spacing: 6
            UiText { text: parent.parent.def.label; color: Theme.text; font.pixelSize: 13 }
            Flow {
                width: parent.parent.width
                spacing: 4
                Repeater {
                    model: parent.parent.parent.def.options
                    delegate: Rectangle {
                        required property var modelData
                        readonly property var ld: parent.parent.parent
                        readonly property bool on: ld.val === modelData[0]
                        height: 28; width: cl.implicitWidth + 20; radius: 8
                        color: on ? Theme.accent : (cm.containsMouse ? Theme.cardHi : Theme.track)
                        border.width: 1; border.color: on ? Theme.accent : Theme.border
                        UiText { id: cl; anchors.centerIn: parent; text: modelData[1]; color: parent.on ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: parent.on ? Font.DemiBold : Font.Normal }
                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: form.set(ld.def.key, modelData[0]) }
                    }
                }
            }
        }
    }
    Component {
        id: switchC
        UiSwitch { label: parent.def.label; checked: !!parent.val; onToggled: on => form.set(parent.def.key, on) }
    }
    Component {
        id: sliderC
        UiSlider {
            label: parent.def.label
            from: parent.def.from; to: parent.def.to
            value: parent.val ?? parent.def.def ?? parent.def.from
            suffix: parent.def.suffix ?? ""
            onMoved: v => { const st = parent.def.step ?? 1; form.set(parent.def.key, Math.round(v / st) * st) }
        }
    }
    Component {
        id: textC
        Column {
            spacing: 6
            UiText { text: parent.parent.def.label; color: Theme.text; font.pixelSize: 13 }
            Rectangle {
                width: parent.parent.width; height: parent.parent.def.multiline ? 84 : 34; radius: 10
                color: Theme.track; border.width: 1; border.color: te.activeFocus ? Theme.accent : Theme.border
                TextEdit {
                    font.family: Theme.font
                    id: te
                    anchors { fill: parent; margins: 9 }
                    text: parent.parent.parent.val ?? ""
                    color: Theme.text; font.pixelSize: 13
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                    clip: true
                    Keys.onReturnPressed: e => { if (!parent.parent.parent.def.multiline || (e.modifiers & Qt.ControlModifier)) { focus = false; e.accepted = true } else e.accepted = false }
                    onActiveFocusChanged: if (!activeFocus) form.set(parent.parent.parent.def.key, text)
                    onTextChanged: if (activeFocus && !parent.parent.parent.def.enterOnly) saveT.restart()
                    Timer { id: saveT; interval: 600; onTriggered: form.set(te.parent.parent.parent.def.key, te.text) }
                }
            }
        }
    }
    Component {
        id: listC
        Column {
            spacing: 6
            UiText { text: parent.parent.def.label; color: Theme.text; font.pixelSize: 13 }
            Rectangle {
                width: parent.parent.width; height: Math.max(60, le.contentHeight + 18); radius: 10
                color: Theme.track; border.width: 1; border.color: le.activeFocus ? Theme.accent : Theme.border
                TextEdit {
                    id: le
                    anchors { fill: parent; margins: 9 }
                    text: (parent.parent.parent.val ?? []).join("\n")
                    color: Theme.text; font.pixelSize: 13; font.family: Theme.mono
                    selectByMouse: true
                    onActiveFocusChanged: if (!activeFocus) form.set(parent.parent.parent.def.key, text.split("\n").map(s => s.trim()).filter(s => s !== ""))
                }
            }
        }
    }
    Component {
        id: fontC
        Column {
            id: fc
            spacing: 6
            property bool openList: false
            readonly property var families: Qt.fontFamilies()
            readonly property var matches: { const q = ff.text.toLowerCase(); return families.filter(f => q === "" || f.toLowerCase().includes(q)).slice(0, 8) }
            Row {
                spacing: 8
                UiText { text: fc.parent.def.label; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: fc.parent.val ? "" : "(a do shell)"; color: Theme.muted; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            }
            UiField {
                id: ff
                width: fc.parent.width
                text: fc.parent.val ?? ""
                placeholderText: "Digite para buscar uma fonte instalada…"
                font.family: text !== "" && fc.families.indexOf(text) >= 0 ? text : font.family
                onActiveFocusChanged: if (activeFocus) fc.openList = true
                onAccepted: { fc.openList = false; form.set(fc.parent.def.key, text) }
            }
            Column {
                visible: fc.openList
                width: fc.parent.width
                spacing: 2
                Repeater {
                    model: fc.openList ? fc.matches.concat([""]) : []
                    delegate: Rectangle {
                        required property var modelData
                        width: fc.width; height: 30; radius: 8
                        color: fm.containsMouse ? Theme.cardHi : "transparent"
                        UiText { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } text: modelData === "" ? "Usar a fonte do shell" : modelData
                            font.family: modelData === "" ? Theme.font : modelData; font.pixelSize: 14; color: modelData === "" ? Theme.muted : Theme.text }
                        MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { ff.text = modelData; fc.openList = false; form.set(fc.parent.def.key, modelData) } }
                    }
                }
            }
        }
    }
    Component {
        id: toneC
        ToneSwatches {
            width: parent.width
            label: parent.def.label
            value: parent.val ?? "global"
            allowGlobal: true
            custom: form.get("fgColor") || "#ffffff"
            onPicked: v => form.set(parent.def.key, v)
        }
    }
    Component {
        id: colorC
        ColorField { label: parent.def.label; value: parent.val || "#ffffff"; onPicked: c => form.set(parent.def.key, c.toString()) }
    }
    Component {
        id: imageC
        // miniatura + nome + botao; o nome encolhe (reticencias) para o botao caber sempre
        Item {
            id: ic
            width: parent ? parent.width : 300
            height: 48
            Rectangle {
                id: ith
                width: 64; height: 44; radius: 8; color: Theme.track; clip: true
                anchors.verticalCenter: parent.verticalCenter
                border.width: 1; border.color: Theme.border
                Image { anchors.fill: parent; source: ic.parent.val ? "file://" + ic.parent.val : ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(128, 88); asynchronous: true }
                UiIcon { visible: !ic.parent.val; anchors.centerIn: parent; name: "image"; size: 18; color: Theme.muted }
            }
            Column {
                anchors { left: ith.right; leftMargin: 10; right: ib.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 4
                UiText { width: parent.width; elide: Text.ElideRight; text: ic.parent.def.label; color: Theme.text; font.pixelSize: 13 }
                UiText { width: parent.width; elide: Text.ElideMiddle; text: ic.parent.val ? ic.parent.val.split("/").pop() : "nenhuma"; color: Theme.muted; font.pixelSize: 11 }
            }
            UiButton {
                id: ib
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                icon: "folderOpen"; text: form.compact ? "" : "Escolher…"
                onClicked: { const k = ic.parent.def.key; Pick.image("Imagem do widget", p => form.set(k, p)) }
            }
        }
    }
}
