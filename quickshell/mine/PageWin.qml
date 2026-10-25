// Pagina "Janelas" (kit Set*): previa de duas janelas com espacos, borda e cantos, sombras, blur do Hyprland e da moldura,
// foco, layout, monitor, apps ao iniciar, atalhos e ajustes do Hyprland. So o que voce muda vira override (HyprConf.qml).
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

    // ---- monitor: troca e pergunta se ficou bom (volta sozinha em 15 s) ----
    readonly property var mon: HyprConf.monitors[0] ?? null
    property var before: null
    property int secsLeft: 0
    Timer { interval: 1000; repeat: true; running: page.secsLeft > 0; onTriggered: { page.secsLeft--; if (page.secsLeft === 0) page.revert() } }
    function applyMon(patch) {
        if (!mon) return
        before = JSON.parse(JSON.stringify(Settings.hyprMonitor || {}))
        Settings.hyprMonitor = Object.assign({ output: mon.name, mode: mon.mode, scale: mon.scale }, Settings.hyprMonitor || {}, patch)
        secsLeft = 15
        refreshT.restart()
    }
    function revert() { secsLeft = 0; Settings.hyprMonitor = before || ({}); before = null; refreshT.restart() }

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
        subtitle: page.nChanged > 0 ? page.nChanged + " ajuste(s) seu(s) por cima dos arquivos do Hyprland" : "Valem na hora; \"Restaurar\" volta ao que está nos arquivos do Hyprland"
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

    // ---- monitor ----
    SetSection {
        title: "Monitor"; icon: "monitor"
        subtitle: page.mon ? page.mon.name + " · " + page.mon.mode + " · escala " + page.mon.scale : "Resolução, taxa de atualização e escala"
        SetRow {
            visible: page.secsLeft > 0
            icon: "timer"; label: "Ficou bom? Volta em " + page.secsLeft + " s"; description: "Se a tela ficar estranha, ela volta sozinha"
            UiButton { icon: "check"; text: "Manter"; kind: "accent"; onClicked: { page.secsLeft = 0; page.before = null } }
            UiButton { icon: "restore"; text: "Voltar"; kind: "ghost"; onClicked: page.revert() }
        }
        SetBlock {
            Flow {
                width: parent.width
                spacing: SetK.sm
                Repeater {
                    // uma por resolucao/taxa arredondada (sem as quase iguais)
                    model: { const seen = {}, out = []; for (const m of (page.mon ? page.mon.modes : [])) { const k = m.replace(/\.\d+Hz$/, ""); if (!seen[k]) { seen[k] = 1; out.push(m) } } return out.slice(0, 16) }
                    delegate: UiButton {
                        required property string modelData
                        text: modelData.replace(/(\d+)\.\d+Hz$/, "$1 Hz").replace("@", "  ")
                        kind: page.mon && page.mon.mode === modelData ? "accent" : "ghost"
                        onClicked: page.applyMon({ mode: modelData })
                    }
                }
            }
        }
        SetChoice {
            icon: "resize"; label: "Escala"
            options: [[1, "100%"], [1.25, "125%"], [1.5, "150%"], [1.75, "175%"], [2, "200%"]]
            value: page.mon ? page.mon.scale : 1
            onPicked: v => page.applyMon({ scale: v })
        }
        SetChoice {
            icon: "rotate"; label: "Orientação"
            options: [[0, "Normal"], [1, "90°"], [2, "180°"], [3, "270°"]]
            value: page.mon ? (Settings.hyprMonitor && Settings.hyprMonitor.transform !== undefined ? Settings.hyprMonitor.transform : page.mon.transform) : 0
            onPicked: v => page.applyMon({ transform: v })
        }
    }

    // ---- apps ao iniciar ----
    SetSection {
        title: "Apps ao iniciar"; icon: "rocket"
        subtitle: "Comandos que o Hyprland roda ao entrar na sessão, além dos seus arquivos"
        Repeater {
            model: Settings.list(Settings.hyprAutostart)
            delegate: SetRow {
                required property string modelData
                required property int index
                icon: "play"; label: modelData
                UiButton { icon: "trash"; kind: "danger"; onClicked: { const l = Settings.list(Settings.hyprAutostart); l.splice(index, 1); Settings.hyprAutostart = l } }
            }
        }
        SetRow {
            icon: "plus"; label: "Novo comando"
            UiField { id: asF; width: 260; placeholderText: "ex.: discord --start-minimized"; onAccepted: asB.clicked() }
            UiButton { id: asB; icon: "plus"; text: "Adicionar"; kind: "accent"; onClicked: { const c = asF.text.trim(); if (!c) return; Settings.hyprAutostart = (Settings.list(Settings.hyprAutostart)).concat([c]); asF.text = "" } }
        }
    }

    // ---- atalhos (so leitura) ----
    SetSection {
        title: "Atalhos"; icon: "keyboard"
        subtitle: "Lidos dos seus arquivos do Hyprland; no launcher, digite < para buscar"
        SetExpander {
            icon: "listCheck"; label: "Ver os atalhos"; description: "Lista com busca"
            lazy: Component {
                SetBlock {
                    id: kb
                    sub: true
                    property var binds: []
                    Process {
                        running: true
                        command: ["python3", Qt.resolvedUrl("scripts/keybinds.py").toString().replace("file://", "")]
                        stdout: StdioCollector { onStreamFinished: { try { kb.binds = JSON.parse(text) } catch (e) {} } }
                    }
                    UiField { id: kbF; width: parent.width; placeholderText: "Buscar atalho…" }
                    Repeater {
                        model: kb.binds.filter(b => { const q = kbF.text.toLowerCase(); return !q || (b.label + " " + b.keys + " " + b.section).toLowerCase().includes(q) }).slice(0, 40)
                        delegate: Item {
                            required property var modelData
                            width: parent.width; height: 30
                            UiText { anchors.verticalCenter: parent.verticalCenter; width: parent.width - kr.width - 12; elide: Text.ElideRight; text: modelData.label; color: Theme.text; font.pixelSize: 13 }
                            Row {
                                id: kr
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                spacing: 4
                                Repeater {
                                    model: modelData.keys.split(" + ")
                                    delegate: Rectangle {
                                        required property string modelData
                                        height: 22; width: Math.max(22, kt.implicitWidth + 12); radius: 6; color: Theme.track; border.width: 1; border.color: Theme.border
                                        UiText { id: kt; anchors.centerIn: parent; text: modelData; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
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
            icon: "restore"; label: "Restaurar esta seção"; description: sysH.changed + " trocada(s) aqui"
            UiButton { text: "Restaurar"; kind: "ghost"; onClicked: { sysH.restore(); refreshT.restart() } }
        }
        SetRow {
            icon: "refresh"; label: "Ler os valores de novo"; description: "Pergunta ao Hyprland o que está valendo agora"
            UiButton { text: "Ler"; kind: "ghost"; onClicked: HyprConf.refresh() }
        }
    }
}
