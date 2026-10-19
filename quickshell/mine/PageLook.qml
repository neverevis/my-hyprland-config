// Pagina "Aparencia": vidro, tema de cores (wallpaper ou esquemas prontos) e cores manuais.
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "glass"
        title: "Vidro"
        subtitle: "Moldura e painéis translúcidos, com o fundo desfocado."
        UiSwitch { label: "Ativar vidro"; checked: Settings.glass; onToggled: on => Settings.glass = on }
        UiSwitch { visible: Settings.glass; label: "Opacidade automática"; description: "Pelo wallpaper, como no end4: fundo calmo deixa mais transparente, fundo vivo deixa mais opaco (agora " + Settings.glassOpacityAuto + "%)."; checked: Settings.glassAuto; onToggled: on => Settings.glassAuto = on }
        UiSlider { visible: Settings.glass && !Settings.glassAuto; label: "Opacidade"; from: 10; to: 100; value: Settings.glassOpacity; suffix: " %"; onMoved: v => Settings.glassOpacity = v }
    }

    ShadowCard {}

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
            UiText {
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
                        UiText {
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
                        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: Theme.muted; font.pixelSize: 10 }
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
        UiSwitch { icon: "frame"; label: "Bordas das janelas"; description: "Cores das bordas ativas e inativas do Hyprland."; checked: Settings.themeBorders; onToggled: on => Settings.themeBorders = on }
        Column {
            visible: Settings.themeBorders
            width: parent.width
            spacing: 10
            // previa: uma janela ativa e uma inativa com as cores escolhidas
            Row {
                spacing: 14
                Rectangle {
                    width: 120; height: 64; radius: 10; color: Theme.card
                    Rectangle {
                        anchors.fill: parent; radius: 10; color: "transparent"; border.width: 3; border.color: "transparent"
                        Rectangle {
                            anchors.fill: parent; radius: 10; z: -1
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Qt.rgba(ThemeColors.of(Settings.themeBorderA).r, ThemeColors.of(Settings.themeBorderA).g, ThemeColors.of(Settings.themeBorderA).b, Settings.themeBorderAlpha / 100) }
                                GradientStop { position: 1; color: Settings.themeBorderB !== "" ? Qt.rgba(ThemeColors.of(Settings.themeBorderB).r, ThemeColors.of(Settings.themeBorderB).g, ThemeColors.of(Settings.themeBorderB).b, Settings.themeBorderAlpha / 100) : Qt.rgba(ThemeColors.of(Settings.themeBorderA).r, ThemeColors.of(Settings.themeBorderA).g, ThemeColors.of(Settings.themeBorderA).b, Settings.themeBorderAlpha / 100) }
                            }
                        }
                    }
                    Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 8; color: Theme.card }
                    UiText { anchors.centerIn: parent; text: "Ativa"; color: Theme.text; font.pixelSize: 12 }
                }
                Rectangle {
                    width: 120; height: 64; radius: 10; color: Theme.card
                    border.width: 3; border.color: Qt.rgba(ThemeColors.of(Settings.themeBorderIn).r, ThemeColors.of(Settings.themeBorderIn).g, ThemeColors.of(Settings.themeBorderIn).b, Settings.themeBorderInAlpha / 100)
                    UiText { anchors.centerIn: parent; text: "Inativa"; color: Theme.muted; font.pixelSize: 12 }
                }
            }
            RoleRow { label: "Ativa"; value: Settings.themeBorderA; onPicked: v => Settings.themeBorderA = v }
            RoleRow { label: "Gradiente com"; value: Settings.themeBorderB; allowNone: true; onPicked: v => Settings.themeBorderB = v }
            UiSlider { visible: Settings.themeBorderB !== ""; label: "Ângulo do gradiente"; from: 0; to: 360; value: Settings.themeBorderAngle; suffix: "°"; onMoved: v => Settings.themeBorderAngle = Math.round(v) }
            UiSlider { label: "Opacidade da ativa"; from: 10; to: 100; value: Settings.themeBorderAlpha; suffix: " %"; onMoved: v => Settings.themeBorderAlpha = Math.round(v) }
            RoleRow { label: "Inativa"; value: Settings.themeBorderIn; onPicked: v => Settings.themeBorderIn = v }
            UiSlider { label: "Opacidade da inativa"; from: 0; to: 100; value: Settings.themeBorderInAlpha; suffix: " %"; onMoved: v => Settings.themeBorderInAlpha = Math.round(v) }
        }
        UiSwitch { icon: "desktop"; label: "kitty"; description: "Cores do terminal (16 cores, fundo e cursor)."; checked: Settings.themeKitty; onToggled: on => Settings.themeKitty = on }
        UiSwitch { icon: "apps"; label: "Apps GTK"; description: "GTK 3 e 4 (Nautilus, configurações do GNOME…)."; checked: Settings.themeGtk; onToggled: on => Settings.themeGtk = on }
        UiSwitch { icon: "web"; label: "Brave"; description: "Cor do tema do navegador."; checked: Settings.themeBrave; onToggled: on => Settings.themeBrave = on }
    }

    Card {
        icon: "textBox"
        title: "Fontes"
        subtitle: "Do shell inteiro: barras, painéis, widgets e esta janela. Vazio usa a fonte do sistema."
        OptionsForm {
            width: parent.width
            schema: [{ key: "fontUi", label: "Interface", type: "font" }, { key: "fontMono", label: "Monoespaçada (código, notas, contas)", type: "font" }]
            get: k => Settings[k]
            set: (k, v) => Settings[k] = v
        }
        Rectangle {
            width: parent.width; height: fprev.implicitHeight + 24; radius: 12; color: Theme.track
            Column {
                id: fprev
                x: 14; y: 12; width: parent.width - 28; spacing: 4
                UiText { text: "Bom dia, " + Profile.name + " — 12:34"; color: Theme.text; font.pixelSize: 20; font.weight: Font.Bold }
                UiText { width: parent.width; wrapMode: Text.WordWrap; text: "A rápida raposa marrom pula sobre o cão preguiçoso. 0123456789"; color: Theme.muted; font.pixelSize: 13 }
                UiText { text: "$ qs -c mine ipc call panels status"; color: Theme.accent; font.pixelSize: 12; font.family: Theme.mono }
            }
        }
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
