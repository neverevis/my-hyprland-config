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
        title: "Tema de cores"
        subtitle: "Gera as cores a partir do wallpaper ou usa um esquema pronto (moldura, barras, texto, destaque, janelas, kitty, GTK e Brave)."
        UiSwitch { label: "Usar tema de cores"; checked: Settings.themeOn; onToggled: on => Settings.themeOn = on }
        Row {
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Modo"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["dark", "Escuro"], ["light", "Claro"], ["auto", "Automático"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.themeMode === modelData[0]
                    onClicked: Settings.themeMode = modelData[0]
                }
            }
        }
        Row {
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Origem"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["wallpaper", "Papel de parede"], ["preset", "Integradas"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.themeSource === modelData[0]
                    onClicked: Settings.themeSource = modelData[0]
                }
            }
        }
        Text { visible: Settings.themeSource === "preset" && Settings.themeMode !== "dark"; width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: "Os esquemas integrados têm o próprio claro/escuro (só o Catppuccin Latte é claro); o modo acima vale para o tema do papel de parede." }
        Text { visible: Settings.themeSource === "wallpaper"; text: "Estilo das cores (Material You)"; color: Theme.text; font.pixelSize: 13 }
        Flow {
            visible: Settings.themeSource === "wallpaper"
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
        Flow {
            visible: Settings.themeSource === "preset"
            width: parent.width
            spacing: 8
            Repeater {
                model: Presets.list
                delegate: Rectangle {
                    id: pc
                    required property var modelData
                    readonly property bool cur: Settings.themePreset === modelData.id
                    width: 168; height: 54; radius: 10
                    color: Qt.rgba(1, 1, 1, cur ? 0.10 : (pm.containsMouse ? 0.06 : 0.03))
                    border.width: cur ? 2 : 1; border.color: cur ? Theme.accent : Theme.border
                    Row {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 0
                        Repeater {
                            model: [pc.modelData.bg, pc.modelData.s2, pc.modelData.primary, pc.modelData.secondary, pc.modelData.tertiary]
                            delegate: Rectangle { required property string modelData; width: 12; height: 28; color: modelData }
                        }
                    }
                    Text { anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom; bottomMargin: 5 }
                        width: parent.width - 16; text: pc.modelData.name; color: Theme.text; font.pixelSize: 11; elide: Text.ElideRight }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.themePreset = pc.modelData.id }
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
