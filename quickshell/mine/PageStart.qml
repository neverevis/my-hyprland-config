// Pagina "Inicio" das configuracoes (kit Set*): o visual de agora num relance (miniatura, paleta, claro/escuro),
// ajustes rapidos, atalhos para as paginas mais usadas, os visuais salvos e a barra/tela.
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

SetPage {
    id: page
    title: "Olá, " + Profile.name
    subtitle: "O visual de agora e os ajustes que mais se usa"
    property string toast: ""
    Timer { id: toastT; interval: 2400; onTriggered: page.toast = "" }
    function say(t) { toast = t; toastT.restart() }
    // perfil de energia (mesmo nome do bloco Energia do Inicio); le uma vez ao abrir e quando o painel fecha
    property string prof: "balanced"
    readonly property var profNames: ({ "balanced": "Equilibrado", "performance": "Desempenho", "power-saver": "Economia" })
    Process { id: pProf; command: ["powerprofilesctl", "get"]; stdout: StdioCollector { onStreamFinished: page.prof = text.trim() || "balanced" } }
    Component.onCompleted: pProf.running = true
    Connections { target: Settings; function onHomeOpenChanged() { if (!Settings.homeOpen) { pProf.running = false; pProf.running = true } } }

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

    // ---- ajustes rapidos (os mesmos botoes e a mesma ordem do painel Inicio: Settings.homeToggles via Toggles) ----
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
                model: Toggles.norm(Settings.homeToggles)
                delegate: Rectangle {
                    id: qt
                    required property var modelData
                    readonly property var t: Toggles.find(modelData.id)
                    readonly property bool bi: !!(t && t.builtin)
                    // Wi-Fi e Bluetooth vem direto dos servicos; Energia e do painel (abre o painel)
                    readonly property string id: modelData.id
                    // rede: o mesmo rotulo e estado do painel Inicio (Wi-Fi quando ha placa; senao Rede e o cabo)
                    readonly property var devs: Networking.devices.values
                    readonly property var wdev: devs.find(d => d.type === DeviceType.Wifi) ?? null
                    readonly property var cdev: devs.find(d => d.type === DeviceType.Wired && d.connected) ?? null
                    readonly property var wcur: wdev ? (wdev.networks.values.find(n => n.connected) ?? null) : null
                    readonly property string lbl: id === "wifi" ? (wdev ? "Wi-Fi" : "Rede") : (t ? t.label : "")
                    readonly property bool on: { Toggles.deps(); Networking.wifiEnabled; return id === "wifi" ? (wdev ? Networking.wifiEnabled : !!cdev) : id === "bt" ? !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) : id === "profile" ? false : (t ? t.on() : false) }
                    readonly property bool avail: { Toggles.deps(); return id === "bt" ? !!Bluetooth.defaultAdapter : (t && t.avail ? t.avail() : true) }
                    readonly property string icn: { Toggles.deps(); return id === "wifi" ? (wdev ? (Networking.wifiEnabled ? "wifi" : "wifiOff") : (cdev ? "ethernet" : "wifiOff")) : id === "bt" ? (on ? "bluetooth" : "btOff") : (t ? (t.iconNow ? t.iconNow() : t.icon) : "cog") }
                    readonly property string sub: { Toggles.deps(); return id === "wifi" ? (wdev ? (!Networking.wifiEnabled ? "Desligado" : (wcur ? wcur.name : (cdev ? "Cabo conectado" : "Ligado"))) : (cdev ? "Cabo · " + cdev.name : "Sem conexão")) : id === "bt" ? (!Bluetooth.defaultAdapter ? "Sem adaptador" : (on ? "Ligado" : "Desligado")) : id === "profile" ? (page.profNames[page.prof] ?? page.prof) : (t ? t.sub() : "") }
                    width: qg.tw; height: 60; radius: 16
                    opacity: avail ? 1 : 0.55
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
                        UiIcon { anchors.centerIn: parent; name: qt.icn; size: 18; color: qt.on ? Theme.accentText : Theme.accent }
                    }
                    Column {
                        anchors { left: qi.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        UiText { width: parent.width; elide: Text.ElideRight; text: qt.lbl; color: qt.on ? Theme.accentText : Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        UiText { width: parent.width; elide: Text.ElideRight; text: qt.sub; color: qt.on ? Qt.rgba(Theme.accentText.r, Theme.accentText.g, Theme.accentText.b, 0.75) : Theme.muted; font.pixelSize: 11 }
                    }
                    MouseArea {
                        id: qm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!qt.avail) return
                            if (qt.id === "wifi") { if (qt.wdev) Networking.wifiEnabled = !Networking.wifiEnabled; else Settings.settingsPage = "net" }
                            else if (qt.id === "bt") Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                            else if (qt.id === "profile") Settings.homeOpen = true
                            else if (qt.t) qt.t.click()
                        }
                    }
                }
            }
        }
        UiText {
            leftPadding: SetK.xs
            color: Theme.muted; font.pixelSize: SetK.fDesc
            textFormat: Text.RichText
            text: "Os mesmos do painel Início · <a href=\"edit\" style=\"color:" + Theme.accent + "\">Editar</a>"
            onLinkActivated: { Settings.settingsSub = "home"; Settings.settingsReveal = "Painel Início"; Settings.settingsPage = "panels" }
            HoverHandler { cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor }
        }
    }

    // ---- atalhos (uma fileira leve de chips; o menu lateral e o caminho principal) ----
    SetSection {
        title: "Ir para"
        icon: "link"
        boxed: false
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: [["theme", "Tema e cores", "palette"], ["wall", "Wallpaper", "wallpaper"], ["bars", "Barras e moldura", "bars"],
                        ["desktop", "Área de trabalho", "view_grid"], ["panels", "Painéis", "dock"], ["anim", "Animações", "animation"]]
                delegate: Rectangle {
                    id: sc
                    required property var modelData
                    height: 30; width: scr.implicitWidth + 22; radius: 15
                    scale: scm.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    color: scm.containsMouse ? Theme.tint(0.16) : Theme.track
                    border.width: 1; border.color: scm.containsMouse ? Theme.tint(0.5) : Theme.border
                    Row {
                        id: scr
                        anchors.centerIn: parent
                        spacing: 6
                        UiIcon { name: sc.modelData[2]; size: 13; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: sc.modelData[1]; color: Theme.text; font.pixelSize: SetK.fDesc; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: scm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.settingsPage = sc.modelData[0] }
                }
            }
        }
    }

    // ---- visuais salvos ----
    SetSection {
        title: "Visuais salvos"
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
