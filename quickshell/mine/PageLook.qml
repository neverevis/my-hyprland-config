// Pagina "Aparencia": vidro, tema de cores (wallpaper ou esquemas prontos) e cores manuais.
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "glass"
        title: "Vidro"
        subtitle: "Moldura e painéis translúcidos, com o fundo desfocado."
        UiSwitch { label: "Ativar vidro"; checked: Settings.glass; onToggled: on => Settings.glass = on }
        UiSlider { visible: Settings.glass; label: "Opacidade"; from: 10; to: 100; value: Settings.glassOpacity; suffix: " %"; onMoved: v => Settings.glassOpacity = v }
    }

    Card {
        icon: "palette"
        title: "Tema de cores"
        subtitle: "Cores geradas do wallpaper (Material You) ou um esquema pronto, aplicadas no shell e nos apps marcados abaixo."
        UiSwitch { label: "Usar tema de cores"; checked: Settings.themeOn; onToggled: on => Settings.themeOn = on }

        Column {
            width: parent.width
            spacing: 12
            enabled: Settings.themeOn
            opacity: enabled ? 1 : 0.45

            Row {
                spacing: 12
                width: parent.width
                Column {
                    spacing: 8
                    UiLabel { text: "Modo" }
                    UiSeg {
                        options: [["dark", "Escuro", "night"], ["light", "Claro", "sun"], ["auto", "Automático", "themeAuto"]]
                        value: Settings.themeMode
                        onPicked: v => Settings.themeMode = v
                    }
                }
                Column {
                    spacing: 8
                    UiLabel { text: "Origem" }
                    UiSeg {
                        options: [["wallpaper", "Wallpaper", "image"], ["preset", "Integradas", "palette"]]
                        value: Settings.themeSource
                        onPicked: v => Settings.themeSource = v
                    }
                }
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
                text: Settings.themeMode === "auto" ? "Automático: claro das 7 h às 18 h, escuro no resto do dia."
                    : (Settings.themeSource === "preset" && Settings.themeMode !== "dark" ? "Os esquemas integrados têm o próprio claro/escuro (só o Catppuccin Latte é claro); o modo vale para o tema do wallpaper." : "")
                visible: text !== ""
            }

            // ---- estilos do Material You ----
            UiLabel { visible: Settings.themeSource === "wallpaper"; text: "Estilo das cores" }
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

            // ---- esquemas prontos ----
            Grid {
                id: presetGrid
                visible: Settings.themeSource === "preset"
                width: parent.width
                columns: 3
                spacing: 8
                Repeater {
                    model: Presets.list
                    delegate: Rectangle {
                        id: pc
                        required property var modelData
                        readonly property bool cur: Settings.themePreset === modelData.id
                        width: (presetGrid.width - 16) / 3; height: 64; radius: 12
                        color: pc.modelData.bg
                        border.width: cur ? 2 : 1
                        border.color: cur ? Theme.accent : Qt.rgba(1, 1, 1, pm.containsMouse ? 0.25 : 0.1)
                        Text {
                            anchors { left: parent.left; leftMargin: 12; top: parent.top; topMargin: 11 }
                            width: parent.width - 40
                            text: pc.modelData.name; color: pc.modelData.text; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight
                        }
                        Row {
                            anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 11 }
                            spacing: 5
                            Repeater {
                                model: [pc.modelData.primary, pc.modelData.secondary, pc.modelData.tertiary, pc.modelData.s2]
                                delegate: Rectangle { required property string modelData; width: 14; height: 14; radius: 7; color: modelData; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.2) }
                            }
                        }
                        Rectangle {
                            visible: pc.cur
                            anchors { right: parent.right; top: parent.top; margins: 8 }
                            width: 20; height: 20; radius: 10; color: Theme.accent
                            UiIcon { anchors.centerIn: parent; name: "check"; size: 13; color: Theme.accentText }
                        }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.themePreset = pc.modelData.id }
                    }
                }
            }

            UiLabel { text: "Paleta atual" }
            Flow {
                width: parent.width
                spacing: 12
                Repeater {
                    model: ThemeColors.roles
                    delegate: Column {
                        required property var modelData
                        spacing: 5
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 30; height: 30; radius: 15; color: ThemeColors.of(modelData.id); border.width: 1; border.color: Theme.border }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: Theme.muted; font.pixelSize: 10 }
                    }
                }
            }
        }
    }

    Card {
        icon: "brush"
        title: "Aplicar o tema em"
        subtitle: "Além do Quickshell, o tema pode colorir outros programas."
        enabled: Settings.themeOn
        opacity: enabled ? 1 : 0.45
        UiSwitch { icon: "frame"; label: "Bordas das janelas"; description: "Gradiente das bordas ativas e inativas do Hyprland."; checked: Settings.themeBorders; onToggled: on => Settings.themeBorders = on }
        UiSwitch { icon: "desktop"; label: "kitty"; description: "Cores do terminal (16 cores, fundo e cursor)."; checked: Settings.themeKitty; onToggled: on => Settings.themeKitty = on }
        UiSwitch { icon: "apps"; label: "Apps GTK"; description: "GTK 3 e 4 (Nautilus, configurações do GNOME…)."; checked: Settings.themeGtk; onToggled: on => Settings.themeGtk = on }
        UiSwitch { icon: "web"; label: "Brave"; description: "Cor do tema do navegador."; checked: Settings.themeBrave; onToggled: on => Settings.themeBrave = on }
    }

    Card {
        icon: "pencil"
        title: "Cores manuais"
        subtitle: Settings.themeOn ? "Em uso só com o tema de cores desligado." : "Cores fixas da moldura, do texto e do destaque."
        ColorField { label: "Moldura e barras"; value: Settings.userBarColor; onPicked: c => Settings.userBarColor = c.toString() }
        ColorField { label: "Texto dos módulos"; value: Settings.userTextColor; onPicked: c => Settings.userTextColor = c.toString() }
        ColorField { label: "Destaque"; value: Settings.userAccent; onPicked: c => Settings.userAccent = c.toString() }
    }
}
