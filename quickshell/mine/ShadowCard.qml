// Cartao "Sombras e brilhos" (pagina Aparencia): a sombra das janelas (Hyprland: ligar, tamanho, suavidade, cor preta /
// do tema / escolhida, transparencia, deslocamento, so na janela em foco) e a dos widgets da area de trabalho (estilo,
// intensidade, tamanho, deslocamento, tambem nos cartoes). Previa ao vivo de uma janela e de um widget sobre o wallpaper.
import QtQuick
import QtQuick.Effects

Card {
    id: sc
    icon: "layers"
    title: "Sombras e brilhos"
    subtitle: "A sombra (ou o brilho colorido) em volta das janelas e a dos widgets. Os ícones da barra e do dock não têm sombra."
    Component.onCompleted: HyprConf.refresh()

    readonly property bool winOn: !!HyprConf.value("decoration:shadow:enabled")
    readonly property real winRange: HyprConf.value("decoration:shadow:range") ?? 15
    readonly property color winCol: {
        const m = Settings.winShadowMode, a = Settings.winShadowAlpha / 100
        const c = m === "theme" ? Theme.role(Settings.winShadowRole) : m === "custom" ? Settings.winShadowColor : "black"
        return m === "" ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(c.r, c.g, c.b, a)
    }

    // ---- previa ----
    Rectangle {
        width: parent.width; height: 170; radius: 14; clip: true
        color: Theme.track
        Image { id: wall; anchors.fill: parent; source: Wallpaper.still !== "" ? "file://" + Wallpaper.still : ""; sourceSize: Qt.size(640, 360); fillMode: Image.PreserveAspectCrop; asynchronous: true }
        ShaderEffectSource { id: wallTex; anchors.fill: parent; sourceItem: wall; hideSource: true; visible: false }
        MultiEffect { anchors.fill: parent; source: wallTex; blurEnabled: true; blur: 0.4; blurMax: 24 }
        // janela
        RectangularShadow {
            anchors.fill: win
            visible: sc.winOn
            radius: win.radius
            blur: sc.winRange * 1.3
            offset.y: Settings.winShadowMode === "" ? 0 : Settings.winShadowOffset
            color: sc.winCol
        }
        Rectangle {
            id: win
            x: 28; y: 30; width: parent.width * 0.42; height: 112; radius: 12
            color: Theme.bg; border.width: 2; border.color: Theme.accent
            Row { x: 12; y: 10; spacing: 6; Repeater { model: 3; Rectangle { width: 9; height: 9; radius: 5; color: Theme.muted } } }
            Column {
                x: 12; y: 34; spacing: 8
                Repeater { model: [0.8, 0.6, 0.7]; Rectangle { required property real modelData; width: win.width * modelData - 24; height: 8; radius: 4; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.18) } }
            }
        }
        // widget (relogio sem fundo e um cartao)
        Item {
            id: wdg
            anchors { right: parent.right; rightMargin: 34; verticalCenter: parent.verticalCenter }
            width: parent.width * 0.38; height: 120
            UiText {
                id: clockTxt
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: Qt.formatTime(new Date(), "HH:mm"); color: "white"; font.pixelSize: 44; font.weight: Font.Bold
                layer.enabled: Settings.desktopShadow
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: DeskState.shadowColor(false); shadowBlur: DeskState.shadowBlur(false); shadowVerticalOffset: DeskState.shadowOffset(false); blurMax: 32 }
            }
            RectangularShadow {
                anchors.fill: crd
                visible: Settings.desktopShadow && Settings.desktopShadowCards
                radius: crd.radius; blur: 6 + Settings.desktopShadowSize * 0.4
                offset.y: DeskState.shadowOffset(false) * 2
                color: DeskState.shadowColor(false)
            }
            Rectangle {
                id: crd
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: 86; height: 86; radius: 20
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.desktopCard / 100)
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14)
                UiIcon { anchors.centerIn: parent; name: "sun"; size: 30; color: Theme.accent }
            }
        }
        Rectangle { anchors { left: parent.left; bottom: parent.bottom; margins: 8 } width: pl.implicitWidth + 16; height: 22; radius: 11; color: Qt.rgba(0, 0, 0, 0.45)
            UiText { id: pl; anchors.centerIn: parent; text: "Prévia"; color: "white"; font.pixelSize: 10; font.weight: Font.DemiBold } }
    }

    // ---- janelas ----
    UiLabel { text: "Janelas" }
    UiSwitch { label: "Sombra nas janelas"; icon: "window"; checked: sc.winOn; onToggled: on => HyprConf.set("decoration:shadow:enabled", on) }
    Column {
        visible: sc.winOn
        width: parent.width
        spacing: 12
        UiSlider { label: "Tamanho"; icon: "resize"; from: 0; to: 60; suffix: " px"; value: sc.winRange; onMoved: v => HyprConf.set("decoration:shadow:range", v) }
        UiSlider { label: "Suavidade (1 = espalhada, 4 = concentrada)"; icon: "blur"; from: 1; to: 4; value: HyprConf.value("decoration:shadow:render_power") ?? 3; onMoved: v => HyprConf.set("decoration:shadow:render_power", v) }
        UiText { text: "Cor"; color: Theme.text; font.pixelSize: 13 }
        UiSeg {
            options: [["", "A da minha config", "cog"], ["dark", "Sombra preta", "night"], ["theme", "Brilho do tema", "palette"], ["custom", "Escolher", "eyedropper"]]
            value: Settings.winShadowMode
            onPicked: v => Settings.winShadowMode = v
        }
        UiText { visible: Settings.winShadowMode === ""; width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: "Usa a cor definida na sua configuração do Hyprland (a sua hoje é um brilho fraco na cor do tema)." }
        RoleRow { visible: Settings.winShadowMode === "theme"; label: "Cor do tema"; value: Settings.winShadowRole; roles: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "outline", "text"]; onPicked: v => Settings.winShadowRole = v }
        ColorField { visible: Settings.winShadowMode === "custom"; label: "Minha cor"; value: Settings.winShadowColor; onPicked: c => Settings.winShadowColor = c.toString() }
        UiSlider { visible: Settings.winShadowMode !== ""; label: "Intensidade"; icon: "opacity"; from: 0; to: 100; suffix: " %"; value: Settings.winShadowAlpha; onMoved: v => Settings.winShadowAlpha = v }
        UiSlider { visible: Settings.winShadowMode !== ""; label: "Deslocamento para baixo"; icon: "arrowDown"; from: 0; to: 20; suffix: " px"; value: Settings.winShadowOffset; onMoved: v => Settings.winShadowOffset = v }
        UiSwitch { visible: Settings.winShadowMode !== ""; label: "Só na janela em foco"; icon: "target"; description: "As outras ficam sem sombra: a janela ativa se destaca."; checked: Settings.winShadowFocusOnly; onToggled: on => Settings.winShadowFocusOnly = on }
    }

    // ---- widgets ----
    UiLabel { text: "Widgets da área de trabalho" }
    UiSwitch { label: "Sombra nos widgets"; icon: "dashboard"; description: "Nos widgets sem fundo ela deixa o texto legível sobre qualquer wallpaper."; checked: Settings.desktopShadow; onToggled: on => Settings.desktopShadow = on }
    Column {
        visible: Settings.desktopShadow
        width: parent.width
        spacing: 12
        UiSeg {
            options: [["auto", "Automática", "magic"], ["dark", "Sombra escura", "night"], ["light", "Brilho claro", "sun"], ["accent", "Brilho do tema", "palette"]]
            value: Settings.desktopShadowMode
            onPicked: v => Settings.desktopShadowMode = v
        }
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: Settings.desktopShadowMode === "auto" ? "Escura sobre wallpaper escuro e um brilho claro sobre wallpaper claro, widget por widget." : Settings.desktopShadowMode === "accent" ? "Um brilho na cor de destaque do tema, que muda com o wallpaper." : "A mesma em todos os widgets." }
        UiSlider { label: "Intensidade"; icon: "opacity"; from: 0; to: 100; suffix: " %"; value: Settings.desktopShadowStrength; onMoved: v => Settings.desktopShadowStrength = v }
        UiSlider { label: "Tamanho"; icon: "blur"; from: 0; to: 100; suffix: " %"; value: Settings.desktopShadowSize; onMoved: v => Settings.desktopShadowSize = v }
        UiSlider { label: "Deslocamento para baixo"; icon: "arrowDown"; from: 0; to: 10; suffix: " px"; value: Settings.desktopShadowOffset; onMoved: v => Settings.desktopShadowOffset = v }
        UiSwitch { label: "Também nos widgets com cartão ou vidro"; icon: "cards"; checked: Settings.desktopShadowCards; onToggled: on => Settings.desktopShadowCards = on }
    }
}
