// Pagina "Geral": o visual de agora em miniatura (wallpaper, moldura, barras, widgets), a paleta do tema, claro/escuro,
// interruptores rapidos e um atalho para cada pagina das configuracoes.
import Quickshell
import Quickshell.Io
import QtQuick

Column {
    id: page
    spacing: 14
    property var pages: []          // a janela passa os grupos de paginas (SettingsWindow.groups)
    property string toast: ""
    Timer { id: toastT; interval: 2400; onTriggered: page.toast = "" }

    Card {
        icon: "sparkle"
        title: "Seu visual"
        subtitle: "Como está agora. Salve como um visual para voltar a ele depois (página Visuais)."
        Row {
            width: parent.width
            spacing: 18
            LookPreview {
                id: lp
                width: Math.min(380, parent.width * 0.48)
                look: Looks.snapshot(Looks.groups.map(g => g.id))
            }
            Column {
                width: parent.width - lp.width - 18
                spacing: 12
                UiText { width: parent.width; elide: Text.ElideMiddle; text: Wallpaper.current.split("/").pop(); color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                // paleta do tema
                Row {
                    spacing: 6
                    Repeater {
                        model: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer"]
                        delegate: Rectangle {
                            required property string modelData
                            width: 30; height: 30; radius: 15
                            color: Theme.role(modelData)
                            border.width: 1; border.color: Theme.border
                        }
                    }
                }
                UiSeg {
                    options: [["dark", "Escuro", "night"], ["light", "Claro", "sun"], ["auto", "Automático", "themeAuto"]]
                    value: Settings.themeMode
                    onPicked: v => Settings.themeMode = v
                }
                Flow {
                    width: parent.width
                    spacing: 6
                    UiButton { icon: "wallpaper"; text: "Trocar wallpaper"; kind: "accent"; onClicked: Settings.wpPickerOpen = true }
                    UiButton { icon: "layers"; text: "Salvar como visual"; kind: "ghost"
                        onClicked: { const n = Looks.save(Looks.uniqueName("Meu visual"), Looks.defaultGroups()); page.toast = "Salvo como “" + n + "”"; toastT.restart() } }
                }
                UiText { visible: page.toast !== ""; text: page.toast; color: Theme.accent; font.pixelSize: 12 }
            }
        }
    }

    // ---- esquema de cores (Material You) + conta-gotas ----
    Process {
        id: picker
        command: ["hyprpicker", "--format=hex", "--no-fancy"]
        stdout: StdioCollector { onStreamFinished: { const h = text.trim(); if (/^#[0-9a-fA-F]{6}$/.test(h)) { Settings.themeSeed = h.toLowerCase(); if (!Settings.themeOn) Settings.themeOn = true; Settings.themeSource = "wallpaper" } } }
    }
    Card {
        visible: Settings.themeOn && Settings.themeSource === "wallpaper"
        icon: "palette"
        title: "Esquema de cores"
        subtitle: "Como o Material You monta a paleta. Automático escolhe pelo colorido do wallpaper (calmo fica neutro)."
        Flow {
            width: parent.width
            spacing: 8
            readonly property real tw: (width - 8 * 3) / 4
            Repeater {
                model: [["auto", "Automático", "auto"], ["content", "Conteúdo", "image"], ["expressive", "Expressivo", "magic"], ["fidelity", "Fiel à imagem", "eye"],
                        ["fruitsalad", "Salada de frutas", "leaf"], ["monochrome", "Mono", "moon"], ["neutral", "Neutro", "balance"], ["rainbow", "Arco-íris", "firework"],
                        ["tonalspot", "Tonal spot", "palette"], ["vibrant", "Vibrante", "lightning"], ["wallpaper", "Do wallpaper", "wallpaper"]]
                delegate: Rectangle {
                    id: sv
                    required property var modelData
                    readonly property bool on: Settings.themeVariant === modelData[0]
                    width: parent.tw; height: 48; radius: on ? 12 : 24
                    color: on ? Theme.accent : (sm.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: 1; border.color: on ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on radius { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        UiIcon { name: sv.modelData[2]; size: 17; color: sv.on ? Theme.accentText : Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: sv.modelData[1]; color: sv.on ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.themeVariant = sv.modelData[0] }
                }
            }
        }
        Row {
            spacing: 10
            UiButton { icon: "eyedropper"; text: picker.running ? "Escolhendo… (Esc cancela)" : "Escolher cor da tela"; kind: "ghost"; enabled: !picker.running; onClicked: picker.running = true }
            Rectangle { visible: Settings.themeSeed !== ""; width: 32; height: 32; radius: 16; color: Settings.themeSeed || "transparent"; border.width: 2; border.color: Theme.border; anchors.verticalCenter: parent.verticalCenter }
            UiButton { visible: Settings.themeSeed !== ""; icon: "close"; text: "Voltar à cor do wallpaper"; kind: "ghost"; onClicked: Settings.themeSeed = "" }
        }
        UiText { visible: Settings.themeSeed !== ""; width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: "Paleta gerada só da cor " + Settings.themeSeed + ", sem olhar para o wallpaper." }
    }

    // ---- barra e cantos da tela ----
    Card {
        icon: "bars"
        title: "Barra e tela"
        subtitle: "Atalhos para o que mais se mexe. O resto fica nas páginas Barras e Moldura."
        Column {
            width: parent.width
            spacing: 8
            UiLabel { text: "Posição da primeira barra" }
            UiSeg {
                options: [["top", "Cima", "arrowUp"], ["left", "Esquerda", "arrowLeft"], ["bottom", "Baixo", "arrowDown"], ["right", "Direita", "arrowRight"]]
                value: (Settings.bars[0] && Settings.bars[0].side) || "bottom"
                onPicked: v => Settings.setBar(0, "side", v)
            }
        }
        Column {
            width: parent.width
            spacing: 8
            UiLabel { text: "Estilo das peças" }
            UiSeg {
                options: [["integrated", "Integrado", "frame"], ["independent", "Independente", "layers"]]
                value: Settings.composition
                onPicked: v => Settings.applyComposition(v)
            }
            UiText { visible: Settings.composition === "mixed"; text: "Hoje está misto (parte a parte, na página Moldura); escolher um destes ajusta tudo."; color: Theme.muted; font.pixelSize: 12 }
        }
        Column {
            width: parent.width
            spacing: 8
            UiLabel { text: "Módulos da barra" }
            UiSeg {
                readonly property bool pills: !Settings.bars.some(b => Settings.sectionsOf(b).some(sc => Array.from(sc.modules ?? []).some(m => m.pill === false)))
                options: [["yes", "Com fundo", "squareRounded"], ["no", "Sem fundo", "squareOutline"]]
                value: pills ? "yes" : "no"
                onPicked: v => Settings.mutate(bs => { for (const b of bs) for (const sc of (b.sections ?? [])) for (const m of (sc.modules ?? [])) m.pill = (v === "yes") })
            }
        }
        Column {
            width: parent.width
            spacing: 8
            UiLabel { text: "Cantos arredondados da tela" }
            UiSeg {
                options: [["no", "Não", "squareOutline"], ["yes", "Sim", "rounded"], ["auto", "Fora da tela cheia", "fullscreen"]]
                value: Settings.cornerMode
                onPicked: v => Settings.cornerMode = v
            }
        }
    }

    Card {
        icon: "tune"
        title: "Ajustes rápidos"
        subtitle: "Os que mais se liga e desliga."
        Flow {
            id: qf
            width: parent.width
            spacing: 8
            readonly property real tw: (width - 8 * 3) / 4
            Repeater {
                model: [
                    { icon: "glass", label: "Vidro", on: () => Settings.glass, run: () => Settings.glass = !Settings.glass },
                    { icon: "dashboard", label: "Widgets", on: () => Settings.desktopOn, run: () => Settings.desktopOn = !Settings.desktopOn },
                    { icon: "night", label: "Luz noturna", on: () => NightLight.active, run: () => NightLight.toggle() },
                    { icon: "bellOff", label: "Não perturbe", on: () => Settings.notifDnd, run: () => Settings.notifDnd = !Settings.notifDnd },
                    { icon: "eyeOff", label: "Contra clarão", on: () => Settings.antiFlash, run: () => Settings.antiFlash = !Settings.antiFlash },
                    { icon: "palette", label: "Tema do wallpaper", on: () => Settings.themeOn, run: () => Settings.themeOn = !Settings.themeOn },
                    { icon: "coffee", label: "Manter acordado", on: () => Idle.paused, run: () => Idle.paused = !Idle.paused },
                    { icon: "blur", label: "Desfoque dos widgets", on: () => Settings.desktopBlur, run: () => Settings.desktopBlur = !Settings.desktopBlur }
                ]
                delegate: Rectangle {
                    id: qt
                    required property var modelData
                    readonly property bool on: { Settings.glass; Settings.desktopOn; Settings.notifDnd; Settings.antiFlash; Settings.themeOn; Settings.desktopBlur; NightLight.active; Idle.paused; return modelData.on() }
                    width: qf.tw; height: 64; radius: 14
                    color: on ? Theme.accent : (qm.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: 1; border.color: on ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Rectangle {
                        id: qi
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 36; radius: 12
                        color: qt.on ? Qt.rgba(Theme.accentText.r, Theme.accentText.g, Theme.accentText.b, 0.16) : Theme.tint(0.14)
                        UiIcon { anchors.centerIn: parent; name: qt.modelData.icon; size: 18; color: qt.on ? Theme.accentText : Theme.accent }
                    }
                    Column {
                        anchors { left: qi.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        UiText { width: parent.width; elide: Text.ElideRight; text: qt.modelData.label; color: qt.on ? Theme.accentText : Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        UiText { text: qt.on ? "Ligado" : "Desligado"; color: qt.on ? Qt.rgba(Theme.accentText.r, Theme.accentText.g, Theme.accentText.b, 0.75) : Theme.muted; font.pixelSize: 11 }
                    }
                    MouseArea { id: qm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: qt.modelData.run() }
                }
            }
        }
    }

    // um atalho por pagina, nos grupos da barra lateral
    Repeater {
        model: page.pages
        delegate: Column {
            id: grp
            required property var modelData
            width: page.width
            spacing: 8
            UiLabel { text: grp.modelData.label.toUpperCase(); font.pixelSize: 11; leftPadding: 4 }
            Flow {
                id: pf
                width: parent.width
                spacing: 8
                readonly property real tw: (width - 8 * 2) / 3
                Repeater {
                    model: grp.modelData.pages.filter(p => p.id !== "overview")
                    delegate: Rectangle {
                        id: pt
                        required property var modelData
                        width: pf.tw; height: 78; radius: 14
                        color: pm.containsMouse ? Theme.cardHi : Theme.glc(Theme.card, 1)
                        border.width: 1; border.color: pm.containsMouse ? Theme.tint(0.5) : Theme.border
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            id: pi
                            x: 14; y: 14
                            width: 34; height: 34; radius: 11
                            color: Theme.tint(0.16)
                            UiIcon { anchors.centerIn: parent; name: pt.modelData.icon; size: 18; color: Theme.accent }
                        }
                        Column {
                            anchors { left: pi.right; leftMargin: 12; right: parent.right; rightMargin: 12; top: parent.top; topMargin: 12 }
                            spacing: 2
                            UiText { text: pt.modelData.label; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                            UiText { width: parent.width; text: pt.modelData.desc; color: Theme.muted; font.pixelSize: 11; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
                        }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.settingsPage = pt.modelData.id }
                    }
                }
            }
        }
    }
}
