// Pagina "Aparencia": vidro e cores.
import QtQuick

Column {
    spacing: 14

    Card {
        title: "Vidro"
        subtitle: "Moldura translúcida com o fundo desfocado."
        UiSwitch { label: "Ativar vidro (blur)"; checked: Settings.glass; onToggled: on => Settings.glass = on }
        UiSlider { label: "Opacidade"; from: 10; to: 100; value: Settings.glassOpacity; suffix: " %"; onMoved: v => Settings.glassOpacity = v }
    }
    Card {
        title: "Brilho interno"
        subtitle: "A borda da moldura e dos elementos que saem dela (barras, launcher, seletor, notificações) acende por dentro do vidro, na cor de destaque."
        UiSwitch { label: "Ativar brilho interno"; checked: Settings.glowOn; onToggled: on => Settings.glowOn = on }
        UiSlider { label: "Alcance"; from: 4; to: 36; value: Settings.glowSize; suffix: " px"; onMoved: v => Settings.glowSize = Math.round(v) }
        UiSlider { label: "Intensidade"; from: 5; to: 100; value: Settings.glowOpacity; suffix: " %"; onMoved: v => Settings.glowOpacity = Math.round(v) }
    }
    Card {
        title: "Tema do wallpaper"
        subtitle: "Gera as cores a partir da imagem de fundo (moldura, barras, texto, destaque e janelas)."
        UiSwitch { label: "Usar cores do wallpaper"; checked: Settings.themeOn; onToggled: on => Settings.themeOn = on }
        Row {
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Modo"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["dark", "Escuro"], ["light", "Claro"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.themeMode === modelData[0]
                    onClicked: Settings.themeMode = modelData[0]
                }
            }
        }
        Text { text: "Estilo das cores (Material You)"; color: Theme.text; font.pixelSize: 13 }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: [["tonalspot", "Tonal spot"], ["vibrant", "Vibrante"], ["expressive", "Expressivo"], ["fidelity", "Fiel à imagem"], ["content", "Conteúdo"], ["neutral", "Neutro"], ["monochrome", "Monocromático"], ["rainbow", "Arco-íris"], ["fruitsalad", "Salada de frutas"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.themeVariant === modelData[0]
                    onClicked: Settings.themeVariant = modelData[0]
                }
            }
        }
        UiSwitch { label: "Aplicar nas bordas das janelas (Hyprland)"; checked: Settings.themeBorders; onToggled: on => Settings.themeBorders = on }
        UiSwitch { label: "Aplicar no kitty"; checked: Settings.themeKitty; onToggled: on => Settings.themeKitty = on }
        UiSwitch { label: "Aplicar nos apps GTK"; checked: Settings.themeGtk; onToggled: on => Settings.themeGtk = on }
        UiSwitch { label: "Aplicar no Brave"; checked: Settings.themeBrave; onToggled: on => Settings.themeBrave = on }
        Flow {
            width: parent.width
            spacing: 14
            Repeater {
                model: ThemeColors.roles
                delegate: Column {
                    required property var modelData
                    spacing: 4
                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 34; height: 34; radius: 17; color: ThemeColors.of(modelData.id); border.width: 1; border.color: Theme.border }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: Theme.muted; font.pixelSize: 10 }
                }
            }
        }
    }
    Card {
        title: "Cores"
        subtitle: Settings.themeOn ? "Em uso apenas com o tema do wallpaper desligado." : ""
        ColorField { label: "Moldura e barras"; value: Settings.userBarColor; onPicked: c => Settings.userBarColor = c.toString() }
        ColorField { label: "Texto dos módulos"; value: Settings.userTextColor; onPicked: c => Settings.userTextColor = c.toString() }
        ColorField { label: "Destaque desta janela"; value: Settings.userAccent; onPicked: c => Settings.userAccent = c.toString() }
    }
}
