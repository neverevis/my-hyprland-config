// Pagina "Wallpaper": pasta, transicao, troca automatica e o seletor.
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "wallpaper"
        title: "Wallpaper atual"
        subtitle: Wallpaper.files.length + " imagens em " + Wallpaper.dir
        Rectangle {
            width: parent.width; height: Math.min(200, width * 9 / 16)
            radius: 12; color: Theme.track; clip: true
            border.width: 1; border.color: Theme.border
            Image {
                anchors.fill: parent; anchors.margins: 1
                source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
                sourceSize: Qt.size(720, 400)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
        Flow {
            width: parent.width
            spacing: 6
            UiButton { icon: "images"; text: "Abrir seletor"; kind: "accent"; onClicked: Settings.wpPickerOpen = true }
            UiButton { icon: "prev"; text: "Anterior"; onClicked: Wallpaper.step(-1) }
            UiButton { icon: "next"; text: "Próximo"; onClicked: Wallpaper.step(1) }
            UiButton { icon: "dice"; text: "Aleatório"; onClicked: Wallpaper.random() }
        }
        UiLabel { text: "Pasta" }
        UiField {
            width: parent.width
            text: Settings.wpDir
            placeholderText: "~/Imagens/Wallpapers"
            onEditingFinished: Settings.wpDir = text
        }
    }

    Card {
        icon: "transition"
        title: "Transição"
        subtitle: "A animação ao trocar de wallpaper. Dissolver, Pixelar, Ondas, Persianas e Redemoinho são shaders (a borda acesa usa a cor de destaque)."
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: [["fade", "Fade"], ["slide", "Deslizar"], ["wipe", "Cortina"], ["circle", "Círculo"], ["zoom", "Zoom"],
                        ["dissolve", "Dissolver"], ["pixelate", "Pixelar"], ["ripple", "Ondas"], ["blinds", "Persianas"], ["swirl", "Redemoinho"],
                        ["random", "Aleatória"], ["none", "Nenhuma"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.wpTransition === modelData[0]
                    onClicked: Settings.wpTransition = modelData[0]
                }
            }
        }
        Column {
            visible: Settings.wpTransition === "wipe" || Settings.wpTransition === "random"
            width: parent.width
            spacing: 10
            UiLabel { text: "Direção da cortina" }
            UiSeg {
                options: [[0, "", "arrow_right"], [45, "", "arrow_bottom_right"], [90, "", "arrowDown"], [135, "", "arrow_bottom_left"], [180, "", "arrow_left"], [225, "", "arrow_top_left"], [270, "", "arrowUp"], [315, "", "arrow_top_right"]]
                value: Settings.wpWipeAngle
                onPicked: v => Settings.wpWipeAngle = v
            }
            UiSlider { label: "Ângulo exato"; from: 0; to: 359; value: Settings.wpWipeAngle; suffix: "°"; onMoved: v => Settings.wpWipeAngle = Math.round(v) }
        }
        UiSlider { label: "Movimento dos wallpapers (cortina: posição, círculo: escala)"; from: 0; to: 50; value: Settings.wpParallax; suffix: " %"; onMoved: v => Settings.wpParallax = Math.round(v) }
        UiLabel { text: "Animação" }
        AnimPicker { target: "wallpaper" }
    }

    Card {
        icon: "timer"
        title: "Troca automática"
        UiSlider { label: "Trocar a cada (0 = desligado)"; from: 0; to: 120; value: Settings.wpInterval; suffix: " min"; onMoved: v => Settings.wpInterval = v }
        UiSwitch { label: "Ordem aleatória"; checked: Settings.wpShuffle; onToggled: on => Settings.wpShuffle = on }
    }

    Card {
        icon: "carousel"
        title: "Seletor"
        subtitle: "Como o carrossel de wallpapers aparece."
        UiSwitch { label: "Acoplado à moldura"; description: "Sai da borda da tela como uma barra. Desligado, flutua perto da borda."; checked: Settings.wpPickerDocked; onToggled: on => Settings.wpPickerDocked = on }
        SidePick { value: Settings.wpPickerSide; onPicked: v => Settings.wpPickerSide = v }
        UiSlider { label: "Deslocamento"; from: -1000; to: 1000; value: Settings.wpPickerOffset; suffix: " px"; onMoved: v => Settings.wpPickerOffset = v }
        UiSlider { visible: !Settings.wpPickerDocked; label: "Distância da borda"; from: 0; to: 80; value: Settings.wpPickerGap; suffix: " px"; onMoved: v => Settings.wpPickerGap = v }
        UiLabel { text: "Wallpapers visíveis" }
        UiSeg {
            options: [[1, "1"], [3, "3"], [5, "5"]]
            value: Settings.wpPickerCount
            onPicked: v => Settings.wpPickerCount = v
        }
        UiSlider { label: "Arredondamento do painel"; from: 0; to: 40; value: Settings.wpPickerRadius; suffix: " px"; onMoved: v => Settings.wpPickerRadius = v }
        UiSlider { visible: Settings.wpPickerDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.wpPickerFillet; suffix: " px"; onMoved: v => Settings.wpPickerFillet = v }
        UiSlider { label: "Arredondamento das miniaturas"; from: 0; to: 40; value: Settings.wpCardRadius; suffix: " px"; onMoved: v => Settings.wpCardRadius = v }
        UiLabel { text: "Animação" }
        AnimPicker { target: "picker" }
    }
}
