// Pagina "Moldura": a composicao do shell (o que cresce da moldura e o que flutua solto), o contorno e as curvas,
// e o indicador de volume (que tambem pode sair da moldura).
import QtQuick

Column {
    id: page
    spacing: 14

    Card {
        icon: "layers"
        title: "Composição"
        subtitle: "Integrado: barras e painéis nascem da moldura, como uma peça só. Independente: cada um é uma superfície solta, com fundo próprio. Dá para misturar parte a parte."
        // tres modos prontos com miniatura
        Row {
            width: parent.width
            spacing: 12
            Repeater {
                model: [
                    { id: "integrated", label: "Integrado", desc: "Tudo sai da moldura", dock: { bars: true, launcher: true, notifications: true, osd: true } },
                    { id: "independent", label: "Independente", desc: "Superfícies soltas", dock: { bars: false, launcher: false, notifications: false, osd: false } },
                    { id: "mixed", label: "Misto", desc: "Escolha parte a parte", dock: Settings.composition === "mixed" ? null : { bars: true, launcher: false, notifications: true, osd: false } }
                ]
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    readonly property bool on: Settings.composition === modelData.id
                    width: (parent.width - 24) / 3; height: pv.height + 66; radius: 14
                    color: on ? Theme.tint(0.14) : (tm.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: on ? 2 : 1; border.color: on ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: 120 } }
                    CompPreview {
                        id: pv
                        x: 10; y: 10; width: parent.width - 20
                        dock: tile.modelData.dock
                    }
                    Column {
                        anchors { left: parent.left; leftMargin: 14; top: pv.bottom; topMargin: 10 }
                        spacing: 2
                        Text { text: tile.modelData.label; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Text { text: tile.modelData.id === "mixed" && tile.on ? "Em uso (personalizado)" : tile.modelData.desc; color: tile.on ? Theme.accent : Theme.muted; font.pixelSize: 11 }
                    }
                    UiIcon { visible: tile.on; anchors { right: parent.right; rightMargin: 14; bottom: parent.bottom; bottomMargin: 16 } name: "check"; size: 18; color: Theme.accent }
                    MouseArea {
                        id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (tile.modelData.id !== "mixed") Settings.applyComposition(tile.modelData.id)
                    }
                }
            }
        }
        UiLabel { text: "Parte a parte" }
        Column {
            width: parent.width
            spacing: 4
            Repeater {
                model: Settings.compParts
                delegate: Rectangle {
                    id: pr
                    required property var modelData
                    readonly property bool docked: Settings.partDocked(modelData.id)
                    width: parent.width; height: 50; radius: 12
                    color: prm.containsMouse ? Theme.cardHi : "transparent"
                    MouseArea { id: prm; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                    UiIcon { id: pic; anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } name: pr.modelData.icon; size: 17; color: pr.docked ? Theme.accent : Theme.muted }
                    Column {
                        anchors { left: pic.right; leftMargin: 12; right: seg.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        Text { text: pr.modelData.label; color: Theme.text; font.pixelSize: 13 }
                        Text { visible: !!pr.modelData.hint; width: parent.width; elide: Text.ElideRight; text: pr.modelData.hint ?? ""; color: Theme.muted; font.pixelSize: 11 }
                    }
                    UiSeg {
                        id: seg
                        anchors { right: go.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        options: [[true, "Na moldura", "frame"], [false, "Solto", "cards"]]
                        value: pr.docked
                        onPicked: v => Settings.setPartDocked(pr.modelData.id, v)
                    }
                    UiButton {
                        id: go
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        icon: "chevRight"; kind: "ghost"
                        opacity: pr.modelData.page === "frame" ? 0 : 1
                        enabled: pr.modelData.page !== "frame"
                        onClicked: Settings.settingsPage = pr.modelData.page
                    }
                }
            }
        }
    }

    Card {
        icon: "frame"
        title: "Contorno"
        subtitle: "A faixa fina que contorna a tela inteira. Sem ela, só as barras e os painéis aparecem (eles continuam nascendo da borda da tela)."
        UiSwitch { label: "Contorno na tela"; description: "Desligado, só as barras e os painéis aparecem."; checked: Settings.outline; onToggled: on => Settings.outline = on }
        UiSlider { label: "Espessura"; icon: "frame"; from: 2; to: 16; value: Settings.edge; suffix: " px"; onMoved: v => Settings.edge = v }
        UiSlider { label: "Cantos da tela"; icon: "rounded"; from: 0; to: 40; value: Settings.cornerRadius; suffix: " px"; onMoved: v => Settings.cornerRadius = v }
    }
    Card {
        icon: "curve"
        title: "Curvas das barras"
        subtitle: "Como a faixa fina sobe até cada barra acoplada."
        UiSlider { label: "Curva da subida"; from: 0; to: 30; value: Settings.fillet; suffix: " px"; onMoved: v => Settings.fillet = v }
        UiSlider { label: "Cantos do topo das barras"; from: 0; to: 30; value: Settings.topRadius; suffix: " px"; onMoved: v => Settings.topRadius = v }
    }
    Card {
        icon: "volume"
        title: "Indicador de volume"
        subtitle: "Aparece quando o volume ou o microfone mudam e com as teclas de mídia (mostrando o que está tocando)."
        UiSwitch { label: "Mostrar o indicador"; icon: "eye"; checked: Settings.osdOn; onToggled: on => Settings.osdOn = on }
        Row {
            spacing: 10
            Text { text: "Lado"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: 90 }
            UiSeg {
                options: [["left", "Esquerda"], ["top", "Topo"], ["bottom", "Base"], ["right", "Direita"]]
                value: Settings.osdSide
                onPicked: v => Settings.osdSide = v
            }
        }
        UiSlider { label: "Tempo na tela"; icon: "timer"; from: 600; to: 4000; value: Settings.osdTimeout; suffix: " ms"; onMoved: v => Settings.osdTimeout = Math.round(v / 100) * 100 }
        Row {
            spacing: 8
            UiButton { icon: "play"; text: "Mostrar agora"; onClicked: Osd.preview() }
        }
        AnimPicker { target: "osd" }
    }
}
