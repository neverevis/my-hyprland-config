// Pagina "Wallpaper": pasta, transicao, curva, duracao e troca automatica.
import QtQuick

Column {
    spacing: 14

    Card {
        title: "Wallpaper"
        subtitle: Wallpaper.files.length + " imagem(ns) em " + Wallpaper.dir
        Rectangle {
            width: parent.width; height: width * 9 / 16 > 190 ? 190 : width * 9 / 16
            radius: 12; color: Theme.bg; clip: true
            border.width: 1; border.color: Theme.border
            Image {
                anchors.fill: parent
                source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
                sourceSize: Qt.size(640, 360)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
        Flow {
            width: parent.width
            spacing: 6
            UiButton { text: "Abrir seletor"; kind: "accent"; onClicked: Settings.wpPickerOpen = true }
            UiButton { text: "Anterior"; onClicked: Wallpaper.step(-1) }
            UiButton { text: "Próximo"; onClicked: Wallpaper.step(1) }
            UiButton { text: "Aleatório"; onClicked: Wallpaper.random() }
        }
        Row {
            spacing: 10
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Pasta"; color: Theme.text; font.pixelSize: 13; width: 60 }
            UiField {
                width: parent.parent.width - 70
                text: Settings.wpDir
                placeholderText: "~/Imagens/Wallpapers"
                onEditingFinished: Settings.wpDir = text
            }
        }
    }

    Card {
        title: "Transição"
        subtitle: "A animação ao trocar de wallpaper."
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: [["fade", "Fade"], ["slide", "Deslizar"], ["wipe", "Cortina"], ["circle", "Círculo"], ["zoom", "Zoom"], ["random", "Aleatória"], ["none", "Nenhuma"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.wpTransition === modelData[0]
                    onClicked: Settings.wpTransition = modelData[0]
                }
            }
        }
        Text { text: "Animação da transição"; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
        AnimPicker { target: "wallpaper" }
        Text { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: "A curva e a duração vêm das animações nomeadas (página Animação)." }
    }

    Card {
        title: "Troca automática"
        UiSlider { label: "Trocar a cada (0 = desligado)"; from: 0; to: 120; value: Settings.wpInterval; suffix: " min"; onMoved: v => Settings.wpInterval = v }
        UiSwitch { label: "Ordem aleatória"; checked: Settings.wpShuffle; onToggled: on => Settings.wpShuffle = on }
    }

    Card {
        title: "Seletor"
        subtitle: "Como o painel de wallpapers aparece (Super + Ctrl + W)."
        Row {
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Lado"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["bottom", "Baixo"], ["top", "Cima"], ["left", "Esquerda"], ["right", "Direita"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.wpPickerSide === modelData[0]
                    onClicked: Settings.wpPickerSide = modelData[0]
                }
            }
        }
        UiSwitch { label: "Acoplado à moldura"; checked: Settings.wpPickerDocked; onToggled: on => Settings.wpPickerDocked = on }
        UiSlider { label: "Deslocamento"; from: -1000; to: 1000; value: Settings.wpPickerOffset; suffix: " px"; onMoved: v => Settings.wpPickerOffset = v }
        UiSlider { visible: !Settings.wpPickerDocked; label: "Distância da borda"; from: 0; to: 80; value: Settings.wpPickerGap; suffix: " px"; onMoved: v => Settings.wpPickerGap = v }
        UiSlider { label: "Arredondamento do painel"; from: 0; to: 40; value: Settings.wpPickerRadius; suffix: " px"; onMoved: v => Settings.wpPickerRadius = v }
        UiSlider { visible: Settings.wpPickerDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.wpPickerFillet; suffix: " px"; onMoved: v => Settings.wpPickerFillet = v }
        UiSlider { label: "Arredondamento das miniaturas"; from: 0; to: 40; value: Settings.wpCardRadius; suffix: " px"; onMoved: v => Settings.wpCardRadius = v }
        Text { text: "Animação"; color: Theme.text; font.pixelSize: 13 }
        AnimPicker { target: "picker" }
        UiButton { text: "Testar o seletor"; kind: "accent"; onClicked: Settings.wpPickerOpen = true }
    }
}
