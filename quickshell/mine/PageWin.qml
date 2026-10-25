// Pagina "Janelas" (kit Set*): previa de duas janelas com espacos, borda e cantos, sombras, blur do Hyprland e da moldura,
// foco, layout, monitor, atalhos e ajustes do Hyprland. So o que voce muda vira override (HyprConf.qml).
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

SetPage {
    id: page
    title: "Janelas"
    subtitle: "Espaços, bordas, sombras, desfoque e comportamento do Hyprland"
    Component.onCompleted: HyprConf.refresh()

    readonly property int gIn: HyprConf.value("general:gaps_in") ?? 5
    readonly property int gOut: HyprConf.value("general:gaps_out") ?? 10
    readonly property int bSize: HyprConf.value("general:border_size") ?? 2
    readonly property int rnd: HyprConf.value("decoration:rounding") ?? 10
    readonly property bool shOn: !!HyprConf.value("decoration:shadow:enabled")
    readonly property real shRange: HyprConf.value("decoration:shadow:range") ?? 15
    readonly property color shCol: {
        const m = Settings.winShadowMode, a = Settings.winShadowAlpha / 100
        const c = m === "theme" ? Theme.role(Settings.winShadowRole) : m === "custom" ? Settings.winShadowColor : "black"
        return m === "" ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(c.r, c.g, c.b, a)
    }
    readonly property int nChanged: Object.keys(HyprConf.cfg).length
    Timer { id: refreshT; interval: 900; onTriggered: HyprConf.refresh() }

    // ---- previa: duas janelas sobre o wallpaper (parada; muda junto com as opcoes) ----
    preview: SetPreview {
        height: 200
        RoundImage {
            anchors.fill: parent
            radius: SetK.boxRadius + 3
            source: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
            sourceSize: Qt.size(640, 360)
        }
        Item {
            id: stage
            anchors.fill: parent
            readonly property real k: 0.7   // px reais -> px da previa
            readonly property real o: Math.max(6, page.gOut * k + 6)
            readonly property real g: page.gIn * k * 2
            readonly property real bw: Math.max(0, page.bSize * k * 1.5)
            Repeater {
                model: 3
                delegate: Item {
                    id: w
                    required property int index
                    // esquerda inteira; direita dividida em duas
                    readonly property real colW: (stage.width - stage.o * 2 - stage.g) * (index === 0 ? 0.58 : 0.42)
                    readonly property real rowH: (stage.height - stage.o * 2 - stage.g)
                    x: stage.o + (index === 0 ? 0 : (stage.width - stage.o * 2 - stage.g) * 0.58 + stage.g)
                    y: stage.o + (index === 2 ? rowH / 2 + stage.g / 2 : 0)
                    width: colW
                    height: index === 0 ? stage.height - stage.o * 2 : (stage.height - stage.o * 2 - stage.g) / 2
                    RectangularShadow {
                        anchors.fill: win
                        visible: page.shOn
                        radius: win.radius
                        blur: page.shRange * 0.6
                        offset.y: Settings.winShadowMode === "" ? 0 : Settings.winShadowOffset * 0.5
                        color: page.shCol
                    }
                    Rectangle {
                        id: win
                        anchors.fill: parent
                        radius: Math.min(page.rnd * stage.k * 1.4, Math.min(width, height) / 2)
                        color: Theme.bg
                        border.width: stage.bw; border.color: w.index === 0 ? Theme.accent : Theme.cardHi
                        Row { x: 10; y: 8; spacing: 4; Repeater { model: 3; Rectangle { width: 6; height: 6; radius: 3; color: Theme.muted; opacity: 0.7 } } }
                        Column {
                            x: 10; y: 24; spacing: 6
                            Repeater { model: [0.7, 0.5, 0.6]; Rectangle { required property real modelData; width: Math.max(0, win.width * modelData - 20); height: 5; radius: 3; color: Theme.text; opacity: 0.18 } }
                        }
                    }
                }
            }
        }
    }

    // ---- espacos, bordas, cantos ----
    SetSection {
        title: "Espaços e bordas"; icon: "window"
        subtitle: page.nChanged > 0 ? (page.nChanged === 1 ? "1 ajuste seu por cima" : page.nChanged + " ajustes seus por cima") + " dos arquivos do Hyprland" : "Valem na hora; \"Restaurar\" volta ao que está nos arquivos do Hyprland"
        SetHypr { keys: ["general:gaps_in", "general:gaps_out", "general:border_size", "decoration:rounding", "decoration:active_opacity"] }
        SetExpander {
            icon: "tune"; label: "Mais ajustes"; description: "Forma do canto, opacidade das outras janelas e espaço entre workspaces"
            SetHypr { sub: true; keys: ["decoration:rounding_power", "decoration:inactive_opacity", "general:gaps_workspaces"] }
        }
        SetRow {
            visible: page.nChanged > 0
            icon: "restore"; label: "Restaurar tudo"; description: "Volta todas as opções do Hyprland (e o monitor) ao que está nos seus arquivos"
            UiButton { text: "Restaurar"; kind: "ghost"; onClicked: { HyprConf.resetAll(); refreshT.restart() } }
        }
    }

    // ---- sombras das janelas ----
    SetSection {
        title: "Sombras"; icon: "layers"
        subtitle: "A sombra (ou o brilho colorido) em volta das janelas"
        SetHypr { keys: ["decoration:shadow:enabled", "decoration:shadow:range", "decoration:shadow:render_power"] }
        SetChoice {
            visible: page.shOn
            icon: "palette"; label: "Cor da sombra"
            style: "tiles"; columns: 4; thumbHeight: 40
            options: [["", "A da minha config", "cog"], ["dark", "Sombra preta", "night"], ["theme", "Brilho do tema", "palette"], ["custom", "Escolher", "eyedropper"]]
            value: Settings.winShadowMode
            onPicked: v => Settings.winShadowMode = v
        }
        SetColor { visible: page.shOn && Settings.winShadowMode === "theme"; sub: true; label: "Cor do tema"; value: Settings.winShadowRole; roles: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "outline", "text"]; onPicked: v => Settings.winShadowRole = v }
        SetColor { visible: page.shOn && Settings.winShadowMode === "custom"; sub: true; label: "Minha cor"; mode: "hex"; value: Settings.winShadowColor; onPicked: v => Settings.winShadowColor = v.toString() }
        SetExpander {
            visible: page.shOn && Settings.winShadowMode !== ""
            icon: "opacity"; label: "Intensidade e posição"; description: "Transparência, deslocamento e só na janela em foco"
            SetSlider { sub: true; label: "Intensidade"; from: 0; to: 100; unit: " %"; value: Settings.winShadowAlpha; onMoved: v => Settings.winShadowAlpha = Math.round(v) }
            SetSlider { sub: true; label: "Deslocamento para baixo"; from: 0; to: 20; unit: " px"; value: Settings.winShadowOffset; onMoved: v => Settings.winShadowOffset = Math.round(v) }
            SetRow { sub: true; label: "Só na janela em foco"; description: "As outras ficam sem sombra"; checked: Settings.winShadowFocusOnly; onToggled: on => Settings.winShadowFocusOnly = on }
        }
    }

    // ---- blur global do Hyprland e da moldura ----
    SetSection {
        title: "Blur do Hyprland"; icon: "blur"
        subtitle: "Vale para todas as janelas, inclusive a moldura (o Hyprland só aceita um valor global)"
        SetRow { icon: "cog"; label: "Controlar o blur por aqui"; description: "Desligado, vale o que estiver na sua configuração do Hyprland"; checked: Settings.blurManaged; onToggled: on => Settings.blurManaged = on }
        SetRow { enabled: Settings.blurManaged; icon: "blur"; label: "Blur ligado"; checked: Settings.blurEnabled; onToggled: on => Settings.blurEnabled = on }
        SetSlider { enabled: Settings.blurManaged; icon: "resize"; label: "Tamanho"; from: 1; to: 20; def: 3; value: Settings.blurSize; onMoved: v => Settings.blurSize = Math.round(v) }
        SetSlider { enabled: Settings.blurManaged; icon: "layers"; label: "Passes (qualidade)"; from: 1; to: 8; def: 4; value: Settings.blurPasses; onMoved: v => Settings.blurPasses = Math.round(v) }
        SetExpander {
            enabled: Settings.blurManaged
            icon: "tune"; label: "Ajuste fino"; description: "Ruído, contraste, brilho e vibração de cor"
            SetSlider { sub: true; label: "Ruído"; from: 0; to: 100; unit: " ‰"; value: Settings.blurNoise; onMoved: v => Settings.blurNoise = Math.round(v) }
            SetSlider { sub: true; label: "Contraste"; from: 0; to: 200; unit: " %"; value: Settings.blurContrast; onMoved: v => Settings.blurContrast = Math.round(v) }
            SetSlider { sub: true; label: "Brilho"; from: 0; to: 200; unit: " %"; value: Settings.blurBrightness; onMoved: v => Settings.blurBrightness = Math.round(v) }
            SetSlider { sub: true; label: "Vibração de cor"; from: 0; to: 100; unit: " %"; value: Settings.blurVibrancy; onMoved: v => Settings.blurVibrancy = Math.round(v) }
        }
    }
    SetSection {
        title: "Blur da moldura"; icon: "grain"
        subtitle: "Só da moldura e das barras; a força segue o blur acima"
        SetRow { icon: "blur"; label: "Desfocar o fundo da moldura"; checked: Settings.shellBlur; onToggled: on => Settings.shellBlur = on }
        SetExpander {
            icon: "tune"; label: "Ajustes"; description: "Limite de transparência e grão próprio (a transparência fica em Tema e cores)"
            SetSlider { sub: true; label: "Limite de transparência"; from: 0; to: 90; unit: " %"; value: Settings.shellIgnoreAlpha; onMoved: v => Settings.shellIgnoreAlpha = Math.round(v) }
            SetSlider { sub: true; label: "Grão próprio"; from: 0; to: 20; unit: " %"; value: Settings.shellGrain; onMoved: v => Settings.shellGrain = Math.round(v) }
        }
    }

    // ---- foco e layout ----
    SetSection {
        title: "Foco e arrasto"; icon: "target"
        SetHypr { keys: ["decoration:dim_inactive", "decoration:dim_strength", "general:resize_on_border", "general:extend_border_grab_area"] }
    }
    SetSection {
        title: "Layout"; icon: "view_column"
        subtitle: "Como as janelas se organizam sozinhas"
        SetHypr { keys: ["general:layout"] }
        SetExpander {
            icon: "view_grid"; label: "Espiral (dwindle)"
            SetHypr { sub: true; keys: ["dwindle:preserve_split", "dwindle:smart_split", "dwindle:force_split", "dwindle:default_split_ratio"] }
        }
        SetExpander {
            icon: "view_column"; label: "Mestre (master)"
            SetHypr { sub: true; keys: ["master:orientation", "master:mfact", "master:new_status"] }
        }
        SetExpander {
            icon: "layers"; label: "Grupos e workspaces"
            SetHypr { sub: true; keys: ["group:auto_group", "binds:workspace_back_and_forth", "binds:allow_workspace_cycles"] }
        }
    }

    // ---- widgets da area de trabalho (sombra) ----
    SetSection {
        title: "Sombra dos widgets"; icon: "dashboard"
        subtitle: "Nos widgets sem fundo ela deixa o texto legível sobre qualquer wallpaper"
        SetRow { icon: "dashboard"; label: "Sombra nos widgets"; checked: Settings.desktopShadow; onToggled: on => Settings.desktopShadow = on }
        SetChoice {
            visible: Settings.desktopShadow
            icon: "palette"; label: "Cor"
            style: "tiles"; columns: 4; thumbHeight: 40
            options: [["auto", "Automática", "magic"], ["dark", "Sombra escura", "night"], ["light", "Brilho claro", "sun"], ["accent", "Brilho do tema", "palette"]]
            value: Settings.desktopShadowMode
            onPicked: v => Settings.desktopShadowMode = v
        }
        SetExpander {
            visible: Settings.desktopShadow
            icon: "tune"; label: "Intensidade e tamanho"
            SetSlider { sub: true; label: "Intensidade"; from: 0; to: 100; unit: " %"; value: Settings.desktopShadowStrength; onMoved: v => Settings.desktopShadowStrength = Math.round(v) }
            SetSlider { sub: true; label: "Tamanho"; from: 0; to: 100; unit: " %"; value: Settings.desktopShadowSize; onMoved: v => Settings.desktopShadowSize = Math.round(v) }
            SetSlider { sub: true; label: "Deslocamento para baixo"; from: 0; to: 10; unit: " px"; value: Settings.desktopShadowOffset; onMoved: v => Settings.desktopShadowOffset = Math.round(v) }
            SetRow { sub: true; label: "Também nos cartões e vidro"; checked: Settings.desktopShadowCards; onToggled: on => Settings.desktopShadowCards = on }
        }
    }

    // ---- monitor (mudou para a pagina Monitores; mesmas chaves em Settings) ----
    SetSection {
        title: "Monitor"; icon: "monitor"
        subtitle: "Resolução, taxa de atualização, escala e posição das telas"
        SetRow { icon: "monitor"; label: "Resolução, escala e posição"; description: "Mudou para a página Monitores"; link: true; onClicked: Settings.settingsPage = "display" }
    }

    // ---- atalhos (a lista e o editor moraram aqui; agora ficam na pagina Atalhos de teclado) ----
    SetSection {
        title: "Atalhos"; icon: "keyboard"
        subtitle: "Ver, mudar e conferir os atalhos do shell e os seus"
        SetRow { icon: "keyboard"; label: "Atalhos de teclado"; description: "Mudou para a página Atalhos de teclado"; link: true; onClicked: Settings.settingsPage = "keys" }
    }

    // ---- ajustes do Hyprland (o que sobra) ----
    SetSection {
        title: "Sistema"; icon: "cog"
        subtitle: "Cursor, telas, jogos e pequenos comportamentos do Hyprland"
        SetExpander {
            icon: "tune"; label: "Comportamento do Hyprland"
            SetHypr { id: sysH; sub: true; group: "system" }
        }
        SetRow {
            visible: sysH.changed > 0
            icon: "restore"; label: "Restaurar esta seção"; description: sysH.changed === 0 ? "Nada mudado aqui" : sysH.changed === 1 ? "1 opção trocada aqui" : sysH.changed + " opções trocadas aqui"
            UiButton { text: "Restaurar"; kind: "ghost"; onClicked: { sysH.restore(); refreshT.restart() } }
        }
        SetRow {
            icon: "refresh"; label: "Ler os valores de novo"; description: "Pergunta ao Hyprland o que está valendo agora"
            UiButton { text: "Ler"; kind: "ghost"; onClicked: HyprConf.refresh() }
        }
    }
}
