// Pagina "Inicio" das configuracoes (kit Set*): o visual de agora num relance (miniatura, paleta, claro/escuro),
// ajustes rapidos, atalhos para as paginas mais usadas, os visuais salvos e a barra/tela.
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Olá, " + Profile.name
    subtitle: "O visual de agora e os ajustes que mais se usa"
    property string toast: ""
    Timer { id: toastT; interval: 2400; onTriggered: page.toast = "" }
    function say(t) { toast = t; toastT.restart() }

    // ---- o visual de agora ----
    preview: SetPreview {
        height: 232
        Row {
            anchors { fill: parent; margins: SetK.lg }
            spacing: SetK.xl
            LookPreview {
                id: lp
                width: Math.min(340, parent.width * 0.5)
                anchors.verticalCenter: parent.verticalCenter
                look: Looks.snapshot(Looks.groups.map(g => g.id))
            }
            Column {
                width: parent.width - lp.width - SetK.xl
                anchors.verticalCenter: parent.verticalCenter
                spacing: SetK.md
                Column {
                    width: parent.width
                    spacing: 2
                    UiText { width: parent.width; elide: Text.ElideMiddle; text: Wallpaper.current.split("/").pop() || "Sem wallpaper"; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                    UiText { text: Settings.themeOn ? (Settings.themeSource === "preset" ? "Esquema " + (Presets.find(Settings.themePreset).name ?? "") : "Paleta do wallpaper") : "Cores fixas"; color: Theme.muted; font.pixelSize: 12 }
                }
                Row {
                    spacing: 6
                    Repeater {
                        model: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer"]
                        delegate: Rectangle { required property string modelData; width: 26; height: 26; radius: 13; color: Theme.role(modelData); border.width: 1; border.color: Theme.border }
                    }
                }
                UiSeg {
                    options: [["dark", "Escuro", "night"], ["light", "Claro", "sun"], ["auto", "Auto", "themeAuto"]]
                    value: Settings.themeMode
                    onPicked: v => Settings.themeMode = v
                }
                Row {
                    spacing: SetK.sm
                    UiButton { icon: "wallpaper"; text: "Trocar wallpaper"; kind: "accent"; onClicked: Settings.wpPickerOpen = true }
                    UiButton { icon: "layers"; text: "Salvar visual"; kind: "ghost"
                        onClicked: page.say("Salvo como “" + Looks.save(Looks.uniqueName("Meu visual"), Looks.defaultGroups()) + "”") }
                }
                UiText { visible: page.toast !== ""; text: page.toast; color: Theme.accent; font.pixelSize: 12 }
            }
        }
    }

    // ---- ajustes rapidos ----
    SetSection {
        title: "Ajustes rápidos"
        icon: "tune"
        boxed: false
        Grid {
            id: qg
            width: parent.width
            columns: width > 600 ? 4 : 2
            spacing: SetK.sm
            readonly property real tw: (width - spacing * (columns - 1)) / columns
            Repeater {
                model: [
                    { icon: "glass", label: "Vidro", on: () => Settings.glass, run: () => Settings.glass = !Settings.glass },
                    { icon: "dashboard", label: "Widgets", on: () => Settings.desktopOn, run: () => Settings.desktopOn = !Settings.desktopOn },
                    { icon: "night", label: "Luz noturna", on: () => NightLight.active, run: () => NightLight.toggle() },
                    { icon: "bellOff", label: "Não perturbe", on: () => Settings.notifDnd, run: () => Settings.notifDnd = !Settings.notifDnd },
                    { icon: "eyeOff", label: "Contra clarão", on: () => Settings.antiFlash, run: () => Settings.antiFlash = !Settings.antiFlash },
                    { icon: "palette", label: "Tema de cores", on: () => Settings.themeOn, run: () => Settings.themeOn = !Settings.themeOn },
                    { icon: "coffee", label: "Manter acordado", on: () => Idle.paused, run: () => Idle.paused = !Idle.paused },
                    { icon: "blur", label: "Desfoque widgets", on: () => Settings.desktopBlur, run: () => Settings.desktopBlur = !Settings.desktopBlur }
                ]
                delegate: Rectangle {
                    id: qt
                    required property var modelData
                    readonly property bool on: { Settings.glass; Settings.desktopOn; Settings.notifDnd; Settings.antiFlash; Settings.themeOn; Settings.desktopBlur; NightLight.active; Idle.paused; return modelData.on() }
                    width: qg.tw; height: 60; radius: 16
                    color: on ? Theme.accent : (qm.containsMouse ? Theme.cardHi : Theme.glc(Theme.card, 1))
                    border.width: 1; border.color: on ? Theme.accent : Theme.border
                    scale: qm.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: SetK.fast } }
                    Rectangle {
                        id: qi
                        x: SetK.md; anchors.verticalCenter: parent.verticalCenter
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

    // ---- atalhos para as paginas mais usadas ----
    SetSection {
        title: "Ir para"
        icon: "link"
        boxed: false
        Grid {
            id: sg
            width: parent.width
            columns: width > 600 ? 3 : 2
            spacing: SetK.sm
            readonly property real tw: (width - spacing * (columns - 1)) / columns
            Repeater {
                model: [["theme", "Tema e cores", "palette"], ["wall", "Wallpaper", "wallpaper"], ["bars", "Barras e moldura", "bars"],
                        ["desktop", "Área de trabalho", "view_grid"], ["panels", "Painéis", "dock"], ["anim", "Animações", "animation"]]
                delegate: Rectangle {
                    id: sc
                    required property var modelData
                    width: sg.tw; height: 56; radius: 16
                    color: scm.containsMouse ? Theme.cardHi : Theme.glc(Theme.card, 1)
                    border.width: 1; border.color: scm.containsMouse ? Theme.tint(0.5) : Theme.border
                    Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: SetK.fast } }
                    Rectangle {
                        id: si
                        x: SetK.md; anchors.verticalCenter: parent.verticalCenter
                        width: 32; height: 32; radius: 10
                        color: Theme.tint(0.14)
                        UiIcon { anchors.centerIn: parent; name: sc.modelData[2]; size: 17; color: Theme.accent }
                    }
                    UiText { anchors { left: si.right; leftMargin: SetK.md; right: chev.left; rightMargin: 6; verticalCenter: parent.verticalCenter } elide: Text.ElideRight; text: sc.modelData[1]; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                    UiIcon { id: chev; anchors { right: parent.right; rightMargin: SetK.md; verticalCenter: parent.verticalCenter } name: "chevRight"; size: 16; color: Theme.muted }
                    MouseArea { id: scm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.settingsPage = sc.modelData[0] }
                }
            }
        }
    }

    // ---- visuais salvos ----
    SetSection {
        title: "Visuais"
        icon: "layers"
        SetRow {
            visible: !!Looks.undoData
            icon: "restore"; label: "Aplicado: " + Looks.undoName; description: "Não gostou? Volte ao de antes"
            UiButton { text: "Desfazer"; kind: "accent"; onClicked: { Looks.undo(); page.say("Voltou ao visual de antes") } }
        }
        SetBlock {
            Row {
                id: lr
                width: parent.width
                spacing: SetK.sm
                readonly property int n: 4
                readonly property real tw: (width - spacing * (n - 1)) / n
                Repeater {
                    model: Looks.list.slice(0, lr.n - 1)
                    delegate: Column {
                        id: lk
                        required property var modelData
                        width: lr.tw
                        spacing: 6
                        Rectangle {
                            width: parent.width; height: width * 9 / 16 + 4; radius: 12
                            color: Theme.track
                            border.width: lkm.containsMouse ? 2 : 1; border.color: lkm.containsMouse ? Theme.accent : Theme.border
                            LookPreview { anchors.centerIn: parent; width: parent.width - 6; look: lk.modelData.data }
                            MouseArea { id: lkm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Looks.apply(lk.modelData.name); page.say("Aplicado: " + lk.modelData.name) } }
                        }
                        UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: lk.modelData.name; color: Theme.muted; font.pixelSize: SetK.fDesc }
                    }
                }
                // ver todos / salvar o primeiro
                Column {
                    width: lr.tw
                    spacing: 6
                    Rectangle {
                        width: parent.width; height: width * 9 / 16 + 4; radius: 12
                        color: allm.containsMouse ? Theme.cardHi : Theme.track
                        border.width: 1; border.color: allm.containsMouse ? Theme.tint(0.5) : Theme.border
                        UiIcon { anchors.centerIn: parent; name: Looks.list.length ? "chevRight" : "plus"; size: 22; color: Theme.accent }
                        MouseArea { id: allm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.settingsPage = "looks" }
                    }
                    UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Looks.list.length ? "Ver todos (" + Looks.list.length + ")" : "Criar visual"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                }
            }
        }
    }

    // ---- barra e tela ----
    SetSection {
        title: "Barra e tela"
        icon: "bars"
        SetChoice {
            icon: "bars"; label: "Posição da barra"
            iconsOnly: true
            options: [["top", "Cima", "arrowUp"], ["left", "Esquerda", "arrowLeft"], ["bottom", "Baixo", "arrowDown"], ["right", "Direita", "arrowRight"]]
            value: (Settings.bars[0] && Settings.bars[0].side) || "bottom"
            onPicked: v => Settings.setBar(0, "side", v)
        }
        SetChoice {
            icon: "frame"; label: "Estilo das peças"
            description: Settings.composition === "mixed" ? "Hoje está misto; escolher ajusta tudo" : ""
            options: [["integrated", "Integrado", "frame"], ["independent", "Solto", "layers"]]
            value: Settings.composition
            onPicked: v => Settings.applyComposition(v)
        }
        SetChoice {
            icon: "squareRounded"; label: "Fundo dos módulos"
            readonly property bool pills: !Settings.bars.some(b => Settings.sectionsOf(b).some(sc => Array.from(sc.modules ?? []).some(m => m.pill === false)))
            options: [["yes", "Com fundo", "squareRounded"], ["no", "Sem fundo", "squareOutline"]]
            value: pills ? "yes" : "no"
            onPicked: v => Settings.mutate(bs => { for (const b of bs) for (const sc of (b.sections ?? [])) for (const m of (sc.modules ?? [])) m.pill = (v === "yes") })
        }
        SetChoice {
            icon: "rounded"; label: "Cantos da tela"
            options: [["no", "Não", "squareOutline"], ["yes", "Sim", "rounded"], ["auto", "Sem tela cheia", "fullscreen"]]
            value: Settings.cornerMode
            onPicked: v => Settings.cornerMode = v
        }
    }
}
