// Pagina "Tema e cores" (kit Set*): previa do shell em miniatura, claro/escuro, de onde vem a paleta (wallpaper com
// estilos do Material You, conta-gotas, ou esquemas prontos), transparencia, fontes e o tema nos outros programas.
import Quickshell
import Quickshell.Io
import QtQuick

SetPage {
    id: page
    title: "Tema e cores"
    subtitle: "Paleta, claro ou escuro, transparência e fontes"

    readonly property real paneAlpha: Settings.glass ? (Settings.glassAuto ? Settings.glassOpacityAuto : Settings.glassOpacity) / 100 : 1
    readonly property real cardAlpha: Settings.glass && Settings.glassSplit ? Settings.glassContent / 100 : paneAlpha
    readonly property var variantInfo: ({
        auto: "Escolhe sozinho pela imagem: se ela for calma, usa tons neutros", wallpaper: "As cores que mais aparecem na imagem",
        tonalspot: "Tons suaves da cor principal", vibrant: "Cores mais vivas e saturadas", expressive: "Gira as cores para dar mais contraste",
        fidelity: "A cor principal da imagem, sem mudar", content: "Fiel à imagem, com cores vizinhas de apoio", neutral: "Quase cinza, com um toque da cor",
        monochrome: "Só tons de cinza", rainbow: "Várias cores, pouco ligadas à imagem", fruitsalad: "Ainda mais cores, bem alegre"
    })

    // conta-gotas: a cor escolhida vira a semente da paleta
    Process {
        id: picker
        command: ["hyprpicker", "--format=hex", "--no-fancy"]
        stdout: StdioCollector { onStreamFinished: { const h = text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(h)) { Settings.themeSeed = h.toLowerCase(); if (!Settings.themeOn) Settings.themeOn = true; Settings.themeSource = "wallpaper" } } }
    }

    // ---- previa: o shell em miniatura sobre o wallpaper (parada; muda junto com as opcoes) ----
    preview: SetPreview {
        height: 216
        RoundImage {
            anchors.fill: parent
            radius: SetK.boxRadius + 3
            source: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
            sourceSize: Qt.size(640, 360)
        }
        // painel (cartao do Inicio)
        Rectangle {
            x: 24; y: 22
            width: Math.min(300, parent.width * 0.44); height: parent.height - 44 - 34
            radius: 16
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, page.paneAlpha)
            border.width: 1; border.color: Theme.border
            Column {
                anchors { fill: parent; margins: 14 }
                spacing: 10
                Row {
                    spacing: 10
                    Rectangle { width: 30; height: 30; radius: 15; color: Theme.primaryContainer
                        UiIcon { anchors.centerIn: parent; name: "account"; size: 16; color: Theme.primaryContainerInk } }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        UiText { text: "Bom dia, " + Profile.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        UiText { text: "3 notificações"; color: Theme.muted; font.pixelSize: 11 }
                    }
                }
                Rectangle {
                    width: parent.width; height: 40; radius: 12
                    color: Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, page.cardAlpha)
                    Row {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        UiIcon { name: "volume"; size: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Rectangle { width: 120; height: 5; radius: 3; color: Theme.cardHi; anchors.verticalCenter: parent.verticalCenter
                            Rectangle { width: 78; height: 5; radius: 3; color: Theme.accent } }
                    }
                    Rectangle {
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        width: 32; height: 18; radius: 9; color: Theme.accent
                        Rectangle { x: 16; y: 2; width: 14; height: 14; radius: 7; color: Theme.accentText }
                    }
                }
                Row {
                    spacing: 6
                    Rectangle { width: 64; height: 24; radius: 12; color: Theme.accent
                        UiText { anchors.centerIn: parent; text: "Ação"; color: Theme.accentText; font.pixelSize: 11; font.weight: Font.DemiBold } }
                    Rectangle { width: 64; height: 24; radius: 12; color: Theme.secondaryContainer
                        UiText { anchors.centerIn: parent; text: "Outra"; color: Theme.secondaryContainerInk; font.pixelSize: 11 } }
                }
            }
        }
        // paleta
        Column {
            anchors { right: parent.right; top: parent.top; margins: 18 }
            spacing: 6
            Repeater {
                model: ["primary", "secondary", "tertiary", "primaryContainer"]
                delegate: Rectangle { required property string modelData; width: 22; height: 22; radius: 11; color: Theme.role(modelData); border.width: 2; border.color: Qt.rgba(1, 1, 1, 0.5) }
            }
        }
        // barra na moldura
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 32
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, page.paneAlpha)
            Row {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 6
                Repeater { model: 4; delegate: Rectangle { required property int index; width: index === 0 ? 20 : 8; height: 8; radius: 4; color: index === 0 ? Theme.accent : Theme.muted; opacity: index === 0 ? 1 : 0.5 } }
            }
            UiText { anchors.centerIn: parent; text: "12:34"; color: Theme.text; font.family: Theme.fontNumbers; font.pixelSize: 13; font.weight: Font.DemiBold }
            Row {
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 10
                UiIcon { name: "wifi"; size: 14; color: Theme.text }
                UiIcon { name: "volume"; size: 14; color: Theme.text }
                UiIcon { name: "bell"; size: 14; color: Theme.accent }
            }
        }
    }

    // ---- claro / escuro ----
    SetSection {
        title: "Modo"
        icon: "themeAuto"
        SetChoice {
            label: ""
            style: "tiles"
            thumbHeight: 64
            columns: 3
            options: [["dark", "Escuro", "night"], ["light", "Claro", "sun"], ["auto", "Automático", "themeAuto"]]
            value: Settings.themeMode
            onPicked: v => Settings.themeMode = v
            thumb: Item {
                id: mt
                property var opt
                property bool on
                property bool hovered
                readonly property var pal: ({ dark: ["#1d1b22", "#2b2832", "#e6e1e9"], light: ["#f4eff6", "#ffffff", "#1d1b20"] })
                Repeater {
                    model: mt.opt && mt.opt[0] === "auto" ? ["dark", "light"] : [mt.opt ? mt.opt[0] : "dark"]
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        x: index * mt.width / 2
                        width: mt.opt && mt.opt[0] === "auto" ? mt.width / 2 : mt.width
                        height: mt.height
                        radius: 10
                        color: mt.pal[modelData][0]
                        Rectangle { x: 10; y: 10; width: parent.width * 0.6; height: 8; radius: 4; color: Theme.accent }
                        Rectangle { x: 10; y: 24; width: parent.width - 20; height: parent.height - 34; radius: 6; color: mt.pal[modelData][1]
                            Rectangle { x: 6; y: 6; width: parent.width * 0.5; height: 4; radius: 2; color: mt.pal[modelData][2]; opacity: 0.7 } }
                    }
                }
            }
        }
    }

    // ---- de onde vem a paleta ----
    SetSection {
        title: "Cores"
        icon: "palette"
        SetRow {
            icon: "palette"; label: "Tema de cores"; description: "Paleta do wallpaper ou de um esquema"
            checked: Settings.themeOn; onToggled: on => Settings.themeOn = on
        }
        SetChoice {
            enabled: Settings.themeOn
            icon: "image"; label: "Origem"
            description: Settings.themeSource === "preset" && Settings.themeMode !== "dark" ? "Esquemas prontos têm o próprio modo" : (Settings.themeMode === "auto" ? "Claro das 7 h às 18 h" : "")
            options: [["wallpaper", "Wallpaper", "image"], ["preset", "Esquemas", "palette"]]
            value: Settings.themeSource
            onPicked: v => Settings.themeSource = v
        }
        SetChoice {
            visible: Settings.themeSource === "wallpaper"
            enabled: Settings.themeOn
            icon: "magic"; label: "Estilo da paleta"
            description: page.variantInfo[Settings.themeVariant] ?? ""
            style: "tiles"; minTile: 104; thumbHeight: 44
            options: [["auto", "Automático", "auto"], ["wallpaper", "Wallpaper", "wallpaper"], ["tonalspot", "Tonal", "palette"], ["vibrant", "Vibrante", "lightning"],
                      ["expressive", "Expressivo", "magic"], ["fidelity", "Fiel", "eye"], ["content", "Conteúdo", "image"], ["neutral", "Neutro", "balance"],
                      ["monochrome", "Mono", "moon"], ["rainbow", "Arco-íris", "firework"], ["fruitsalad", "Salada", "leaf"]]
            value: Settings.themeVariant
            onPicked: v => Settings.themeVariant = v
        }
        SetRow {
            visible: Settings.themeSource === "wallpaper"
            enabled: Settings.themeOn
            icon: "eyedropper"; label: "Cor de origem"
            description: Settings.themeSeed !== "" ? "Fixa em " + Settings.themeSeed : "Automática, do wallpaper"
            canReset: Settings.themeSeed !== ""
            onReset: Settings.themeSeed = ""
            // cores que existem no wallpaper: clique para usar uma como origem
            Row {
                spacing: 4
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                Repeater {
                    model: ThemeColors.wall.slice(0, 5)
                    delegate: Rectangle {
                        required property string modelData
                        width: 22; height: 22; radius: 11; color: modelData
                        border.width: Settings.themeSeed === modelData.toLowerCase() ? 2 : 1
                        border.color: Settings.themeSeed === modelData.toLowerCase() ? Theme.accent : Qt.rgba(1, 1, 1, 0.18)
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.themeSeed = modelData.toLowerCase() }
                    }
                }
            }
            UiButton { icon: "eyedropper"; text: picker.running ? "Esc cancela" : "Da tela"; enabled: !picker.running; onClicked: picker.running = true }
        }
        SetChoice {
            visible: Settings.themeSource === "preset"
            enabled: Settings.themeOn
            icon: "palette"; label: "Esquema"
            style: "tiles"; minTile: 150; thumbHeight: 56
            options: Presets.all.map(p => [p.id, p.name, ""])
            value: Settings.themePreset
            onPicked: v => { Settings.themePreset = v; Settings.themePresetPrimary = ""; Settings.themePresetSecondary = "" }
            thumb: Rectangle {
                id: pt
                property var opt
                property bool on
                property bool hovered
                readonly property var pr: opt ? Presets.find(opt[0]) : null
                radius: 10
                color: pr ? pr.bg : "transparent"
                Row {
                    anchors.centerIn: parent
                    spacing: 5
                    Repeater {
                        model: pt.pr ? [pt.pr.primary, pt.pr.secondary, pt.pr.tertiary, pt.pr.s2] : []
                        delegate: Rectangle { required property string modelData; width: 16; height: 16; radius: 8; color: modelData; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.2) }
                    }
                }
            }
        }
        Repeater {
            model: Settings.themeSource === "preset" ? [["Destaque", "themePresetPrimary", "star"], ["Secundária", "themePresetSecondary", "starOutline"]] : []
            delegate: SetRow {
                id: acRow
                required property var modelData
                enabled: Settings.themeOn
                icon: modelData[2]; label: modelData[0]
                description: (Settings[modelData[1]] || "") === "" ? "Do esquema" : Settings[modelData[1]]
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    Repeater {
                        model: Presets.accents(Presets.find(Settings.themePreset)).filter((a, i) => acRow.modelData[1] === "themePresetPrimary" || i > 0).slice(0, 9)
                        delegate: Rectangle {
                            id: sw
                            required property var modelData
                            required property int index
                            readonly property string key: acRow.modelData[1]
                            readonly property bool sel: (Settings[key] || "") === (index === 0 && key === "themePresetPrimary" ? "" : modelData.color)
                            width: 22; height: 22; radius: 11; color: modelData.color
                            border.width: sel ? 2 : 1; border.color: sel ? Theme.accent : Qt.rgba(1, 1, 1, 0.2)
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings[sw.key] = (sw.index === 0 && sw.key === "themePresetPrimary") ? "" : sw.modelData.color }
                        }
                    }
                }
            }
        }
        SetExpander {
            visible: Settings.themeSource === "preset"
            icon: "folderOpen"; label: "Seus esquemas"; description: "Importar ou abrir a pasta"
            SetBlock {
                sub: true
                Row {
                    spacing: SetK.sm
                    UiButton { icon: "folderOpen"; text: "Abrir pasta"; onClicked: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && xdg-open "$1"', "sh", Presets.dir]) }
                    UiButton { icon: "refresh"; text: "Recarregar"; kind: "ghost"; onClicked: Presets.reload() }
                }
                Row {
                    spacing: SetK.sm
                    UiField { id: schF; width: 260; placeholderText: "Caminho de um .json"; onAccepted: schB.clicked() }
                    UiButton { id: schB; icon: "plus"; text: "Importar"; onClicked: if (schF.text.trim() !== "") { Presets.importFile(schF.text.trim()); schF.text = "" } }
                }
                UiText { visible: Presets.importMsg !== ""; text: Presets.importMsg; color: Theme.muted; font.pixelSize: 12 }
                UiText { width: parent.width; elide: Text.ElideRight; color: Theme.muted; font.pixelSize: 11; text: "Mínimo: name, dark, bg, text, primary, secondary, tertiary, error (veja exemplo.json.txt)" }
            }
        }
        SetExpander {
            icon: "swatch"; label: "Paleta completa"; description: "Todas as cores do tema atual"
            lazy: Component {
                SetBlock {
                    sub: true
                    Flow {
                        width: parent.width
                        spacing: SetK.md
                        Repeater {
                            model: ThemeColors.roles
                            delegate: Column {
                                required property var modelData
                                width: 64
                                spacing: 4
                                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 28; height: 28; radius: 14; color: ThemeColors.of(modelData.id); border.width: 1; border.color: Theme.border }
                                UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.label; color: Theme.muted; font.pixelSize: 10 }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- transparencia ----
    SetSection {
        title: "Transparência"
        icon: "opacity"
        SetRow {
            icon: "glass"; label: "Vidro"; description: "Moldura e painéis translúcidos"
            checked: Settings.glass; onToggled: on => Settings.glass = on
        }
        SetSlider {
            visible: Settings.glass && !Settings.glassAuto
            icon: "opacity"; label: Settings.glassSplit ? "Opacidade do fundo" : "Opacidade"
            from: 10; to: 100; step: 5; unit: " %"; def: 60
            value: Settings.glassOpacity; onMoved: v => Settings.glassOpacity = Math.round(v)
        }
        SetRow {
            icon: "night"; label: "Fundo OLED"; description: "Preto puro nos painéis e janelas"
            checked: Settings.uiOled; onToggled: on => Settings.uiOled = on
        }
        SetExpander {
            visible: Settings.glass
            icon: "tune"; label: "Ajuste fino"; description: "Automática ou separada por camada"
            SetRow {
                sub: true; label: "Opacidade automática"; description: "Pelo wallpaper (agora " + Settings.glassOpacityAuto + "%)"
                checked: Settings.glassAuto; onToggled: on => Settings.glassAuto = on
            }
            SetRow {
                sub: true; label: "Separar fundo e conteúdo"; description: "Cartões com transparência própria"
                checked: Settings.glassSplit; onToggled: on => Settings.glassSplit = on
            }
            SetSlider {
                visible: Settings.glassSplit
                sub: true; label: "Opacidade do conteúdo"
                from: 10; to: 100; step: 5; unit: " %"; def: 60
                value: Settings.glassContent; onMoved: v => Settings.glassContent = Math.round(v)
            }
        }
    }

    // ---- fontes ----
    SetSection {
        title: "Fontes"
        icon: "font"
        SetBlock {
            Rectangle {
                width: parent.width; height: fprev.implicitHeight + 24; radius: 12; color: Theme.track
                Column {
                    id: fprev
                    x: 14; y: 12; width: parent.width - 28; spacing: 4
                    UiText { text: "Bom dia, " + Profile.name + " — 12:34"; color: Theme.text; font.family: Theme.fontTitle; font.pixelSize: 20; font.weight: Font.Bold }
                    UiText { width: parent.width; elide: Text.ElideRight; text: "A rápida raposa marrom pula sobre o cão preguiçoso. 0123456789"; color: Theme.muted; font.pixelSize: 13 }
                    UiText { text: "$ qs -c mine ipc call panels status"; color: Theme.accent; font.pixelSize: 12; font.family: Theme.mono }
                }
            }
        }
        SetExpander {
            icon: "textBox"; label: "Fontes por papel"; description: "Interface: " + Theme.font
            SetBlock {
                sub: true
                OptionsForm {
                    width: parent.width
                    schema: [{ key: "fontUi", label: "Interface", type: "font" }, { key: "fontNumbers", label: "Números (relógios)", type: "font" }, { key: "fontTitle", label: "Títulos", type: "font" }, { key: "fontReading", label: "Leitura (notas)", type: "font" }, { key: "fontExpressive", label: "Decorativa (widgets)", type: "font" }, { key: "fontMono", label: "Monoespaçada", type: "font" }]
                    get: k => Settings[k]
                    set: (k, v) => Settings[k] = v
                }
            }
        }
    }

    // ---- o tema fora do shell ----
    SetSection {
        title: "Outros programas"
        icon: "brush"
        SetExpander {
            enabled: Settings.themeOn
            icon: "apps"; label: "Tema nos aplicativos"
            description: [Settings.themeGtk ? "GTK" : "", Settings.themeQt ? "Qt" : "", Settings.themeKitty ? "kitty" : "", Settings.themeBrave ? "Brave" : ""].filter(x => x).join(", ") || "Nenhum"
            SetRow { sub: true; label: "Apps GTK"; description: "GTK 3 e 4 (Nautilus, GNOME)"; checked: Settings.themeGtk; onToggled: on => Settings.themeGtk = on }
            SetRow { sub: true; label: "Apps Qt / KDE"; description: "Gera quickshell.colors (aponte o qtengine)"; checked: Settings.themeQt; onToggled: on => Settings.themeQt = on }
            SetRow { sub: true; label: "kitty"; description: "16 cores, fundo e cursor"; checked: Settings.themeKitty; onToggled: on => Settings.themeKitty = on }
            SetRow { sub: true; label: "Brave"; description: "Cor do tema do navegador"; checked: Settings.themeBrave; onToggled: on => Settings.themeBrave = on }
        }
        SetExpander {
            enabled: Settings.themeOn
            icon: "frame"; label: "Bordas das janelas"; description: "Cores do Hyprland pelo tema"
            checked: Settings.themeBorders; onToggled: on => Settings.themeBorders = on
            SetBlock {
                sub: true
                visible: Settings.themeBorders
                // previa: uma janela ativa e uma inativa
                Row {
                    id: bprev
                    spacing: 14
                    readonly property color ca: ThemeColors.of(Settings.themeBorderA)
                    readonly property color cb: Settings.themeBorderB !== "" ? ThemeColors.of(Settings.themeBorderB) : ca
                    readonly property color ci: ThemeColors.of(Settings.themeBorderIn)
                    Rectangle {
                        width: 120; height: 60; radius: 10
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Qt.rgba(bprev.ca.r, bprev.ca.g, bprev.ca.b, Settings.themeBorderAlpha / 100) }
                            GradientStop { position: 1; color: Qt.rgba(bprev.cb.r, bprev.cb.g, bprev.cb.b, Settings.themeBorderAlpha / 100) }
                        }
                        Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 8; color: Theme.card
                            UiText { anchors.centerIn: parent; text: "Ativa"; color: Theme.text; font.pixelSize: 12 } }
                    }
                    Rectangle {
                        width: 120; height: 60; radius: 10; color: Theme.card
                        border.width: 3; border.color: Qt.rgba(bprev.ci.r, bprev.ci.g, bprev.ci.b, Settings.themeBorderInAlpha / 100)
                        UiText { anchors.centerIn: parent; text: "Inativa"; color: Theme.muted; font.pixelSize: 12 }
                    }
                }
            }
            SetColor { visible: Settings.themeBorders; sub: true; label: "Ativa"; value: Settings.themeBorderA; onPicked: v => Settings.themeBorderA = v }
            SetColor { visible: Settings.themeBorders; sub: true; label: "Gradiente com"; allowNone: true; value: Settings.themeBorderB; onPicked: v => Settings.themeBorderB = v }
            SetSlider { visible: Settings.themeBorders && Settings.themeBorderB !== ""; sub: true; label: "Ângulo do gradiente"; from: 0; to: 360; step: 15; unit: "°"; def: 45; value: Settings.themeBorderAngle; onMoved: v => Settings.themeBorderAngle = Math.round(v) }
            SetSlider { visible: Settings.themeBorders; sub: true; label: "Opacidade da ativa"; from: 10; to: 100; step: 5; unit: " %"; def: 100; value: Settings.themeBorderAlpha; onMoved: v => Settings.themeBorderAlpha = Math.round(v) }
            SetColor { visible: Settings.themeBorders; sub: true; label: "Inativa"; value: Settings.themeBorderIn; onPicked: v => Settings.themeBorderIn = v }
            SetSlider { visible: Settings.themeBorders; sub: true; label: "Opacidade da inativa"; from: 0; to: 100; step: 5; unit: " %"; def: 100; value: Settings.themeBorderInAlpha; onMoved: v => Settings.themeBorderInAlpha = Math.round(v) }
        }
        SetExpander {
            icon: "pencil"; label: "Cores fixas"
            description: Settings.themeOn ? "Valem com o tema de cores desligado" : "Moldura, texto e destaque"
            SetColor { sub: true; mode: "hex"; label: "Moldura e barras"; roles: ["background", "surface", "surfaceHigh", "primaryContainer"]; value: Settings.userBarColor; onPicked: v => Settings.userBarColor = v }
            SetColor { sub: true; mode: "hex"; label: "Texto dos módulos"; roles: ["text", "muted", "primary"]; value: Settings.userTextColor; onPicked: v => Settings.userTextColor = v }
            SetColor { sub: true; mode: "hex"; label: "Destaque"; roles: ["primary", "secondary", "tertiary"]; value: Settings.userAccent; onPicked: v => Settings.userAccent = v }
        }
    }
}
