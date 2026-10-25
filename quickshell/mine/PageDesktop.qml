// Pagina "Area de trabalho" (kit Set*): widgets sobre o wallpaper. Mostrar/editar/travar, adicionar (chips por grupo),
// os widgets na tela (linha com opcoes completas so no aberto), aparencia, comportamento, layouts prontos, clima e animacao.
// Lista "Na tela": modelo estavel (ids) + corpo pesado num Loader so quando aberto (regras de desempenho do RULES.md).
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Área de trabalho"
    subtitle: ((Settings.desktopWidgets || []).length === 0 ? "Nenhum widget na tela" : (Settings.desktopWidgets || []).length === 1 ? "1 widget na tela" : (Settings.desktopWidgets || []).length + " widgets na tela") + ". Clique direito no fundo abre o menu."
    property string toast: ""
    property string openId: DeskState.selected
    // ids dos widgets: so muda quando entra/sai um widget (o array novo a cada opcao alterada recriava a lista inteira)
    property var wids: []
    function syncIds() { const n = (Settings.desktopWidgets || []).map(w => w.id); if (n.join("|") !== wids.join("|")) wids = n }
    Connections { target: Settings; function onDesktopWidgetsChanged() { page.syncIds() } }
    Component.onCompleted: syncIds()
    Timer { id: toastT; interval: 2200; onTriggered: page.toast = "" }
    function say(s) { toast = s; toastT.restart() }

    SetSection {
        title: "Widgets"; icon: "dashboard"
        SetRow { icon: "eye"; label: "Mostrar os widgets"; description: "Por cima do wallpaper e por baixo das janelas"; checked: Settings.desktopOn; onToggled: on => Settings.desktopOn = on }
        SetRow {
            icon: "pencil"; label: "Editar na tela"; description: "Arraste, redimensione e ajuste direto na área de trabalho"
            UiButton { icon: DeskState.editing ? "check" : "pencil"; text: DeskState.editing ? "Terminar edição" : "Editar"; kind: "accent"; onClicked: { DeskState.editing = !DeskState.editing; if (DeskState.editing) Settings.settingsOpen = false } }
        }
        SetRow { icon: DeskState.locked ? "lock" : "lockOpen"; label: "Travar posições"; description: "Os widgets deixam de ser arrastados"; checked: Settings.desktopLocked; onToggled: on => Settings.desktopLocked = on }
    }

    // ---- adicionar: chips compactos por grupo ----
    SetSection {
        title: "Adicionar"; icon: "plus"
        SetBlock {
            Repeater {
                model: DeskState.groups
                delegate: Column {
                    id: grp
                    required property var modelData
                    width: parent.width
                    spacing: SetK.sm
                    UiText { text: grp.modelData.label; color: Theme.muted; font.pixelSize: SetK.fDesc; font.weight: Font.DemiBold }
                    Flow {
                        width: parent.width
                        spacing: SetK.sm
                        Repeater {
                            model: DeskState.catalog.filter(c => c.group === grp.modelData.id)
                            delegate: Rectangle {
                                id: chip
                                required property var modelData
                                height: 38; width: cr.implicitWidth + 30; radius: 12
                                color: cm.containsMouse ? Theme.cardHi : Theme.track
                                border.width: 1; border.color: cm.containsMouse ? Theme.accent : Theme.border
                                Row {
                                    id: cr
                                    anchors.centerIn: parent
                                    spacing: 8
                                    UiIcon { name: chip.modelData.icon; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                                    UiText { text: chip.modelData.name; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                                }
                                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { Settings.desktopOn = true; const id = DeskState.add(chip.modelData.type); page.openId = id; page.say(chip.modelData.name + " adicionado") } }
                            }
                        }
                    }
                }
            }
            UiText { visible: page.toast !== ""; text: page.toast; color: Theme.accent; font.pixelSize: 12 }
        }
    }

    // ---- na tela: um item por widget; o corpo (previa + opcoes) so existe no aberto ----
    SetSection {
        title: "Na tela"; icon: "tune"; subtitle: "Clique num widget para ver todas as opções dele"
        SetRow { visible: !page.wids.length; icon: "dashboard"; label: "Nenhum widget ainda"; description: "Escolha um em Adicionar" }
        Repeater {
            model: page.wids
            delegate: Column {
                id: row
                required property var modelData
                required property int index
                readonly property var w: { Settings.desktopWidgets; return DeskState.find(modelData) }
                readonly property var info: w ? DeskState.info(w.type) : null
                readonly property bool open: page.openId === modelData
                width: parent.width
                SetRow {
                    icon: row.info ? row.info.icon : "dashboard"
                    label: row.info ? row.info.name : ""
                    description: row.w ? row.w.cols + "×" + row.w.rows + "  ·  " + ({ auto: "fundo padrão", card: "cartão", glass: "vidro", none: "sem fundo" })[DeskState.opt(row.w, "card")] ?? "estilo próprio" + (DeskState.opt(row.w, "lock") ? "  ·  na tela de bloqueio" : "") + (DeskState.opt(row.w, "place") !== "free" ? "  ·  posição automática" : "") : ""
                    divider: row.index > 0
                    rowClick: true
                    onClicked: page.openId = row.open ? "" : row.modelData
                    UiButton { icon: "cards"; kind: "ghost"; onClicked: DeskState.duplicate(row.modelData) }
                    UiButton { icon: "trash"; kind: "ghost"; onClicked: { if (page.openId === row.modelData) page.openId = ""; DeskState.remove(row.modelData) } }
                    UiIcon { name: "chevDown"; size: 20; color: Theme.muted; rotation: row.open ? 180 : 0 }
                }
                Loader {
                    id: body
                    active: row.open
                    asynchronous: true
                    width: parent.width
                    height: item ? item.height : 0
                    sourceComponent: SetBlock {
                        WidgetPreview {
                            width: parent.width
                            height: Math.min(240, Math.max(150, width * 0.34))
                            w: row.w
                        }
                        SizePicker {
                            width: parent.width
                            sizes: row.info ? row.info.sizes : []
                            cols: row.w ? row.w.cols : 1
                            rows: row.w ? row.w.rows : 1
                            onPicked: (c, r) => DeskState.setSize(row.modelData, c, r)
                        }
                        OptionsForm {
                            width: parent.width
                            sectionIcons: DeskState.secIcons
                            previewType: row.w ? row.w.type : ""
                            previewOpts: row.w ? (row.w.opts || {}) : ({})
                            previewCols: row.w ? row.w.cols : 2
                            previewRows: row.w ? row.w.rows : 2
                            schema: row.w ? DeskState.optionsOf(row.w.type) : []
                            get: k => row.w ? DeskState.opt(row.w, k) : undefined
                            set: (k, v) => DeskState.setOpt(row.modelData, k, v)
                            isShown: d => row.w ? DeskState.shown(row.w, d) : false
                        }
                    }
                }
            }
        }
    }

    // ---- aparencia padrao ----
    SetSection {
        title: "Aparência"; icon: "palette"
        SetRow {
            icon: "cards"; label: "Fundo padrão"; description: "Cada widget pode ter o próprio nas opções dele"
            below: CardStylePicker { width: parent ? parent.width : 300; withAuto: false; value: Settings.desktopCardStyle; onPicked: v => Settings.desktopCardStyle = v }
        }
        SetSlider { icon: "glass"; label: "Opacidade do cartão"; from: 0; to: 100; unit: " %"; value: Settings.desktopCard; onMoved: v => Settings.desktopCard = Math.round(v) }
        SetRow {
            icon: "swatch"; label: "Cor dos widgets"
            description: Settings.desktopTone === "auto" ? "Automática: texto claro ou escuro conforme o wallpaper"
                : Settings.desktopTone === "neutral" ? "Neutra: só o texto do tema, sem destaque"
                : Settings.desktopTone === "custom" ? "Uma cor só para todos" : Settings.desktopTone.indexOf("wall") === 0 ? "Uma cor do wallpaper (muda junto com ele)" : "Tom suave dessa cor da paleta"
            below: ToneSwatches { width: parent ? parent.width : 300; label: ""; value: Settings.desktopTone; custom: Settings.desktopToneColor; onPicked: v => Settings.desktopTone = v }
        }
        SetRow { visible: Settings.desktopTone === "custom"; sub: true; label: "Minha cor"
            below: ColorField { width: parent ? parent.width : 300; label: ""; value: Settings.desktopToneColor; onPicked: c => Settings.desktopToneColor = c.toString() } }
        SetChoice { icon: "grid"; label: "Tamanho da grade"; options: [["default", "Padrão", "view_grid"], ["compact", "Compacta", "grid"]]; value: Settings.desktopGridSize; onPicked: v => Settings.desktopGridSize = v }
        SetRow { icon: "layers"; label: "Sombra nos widgets"; description: "Texto legível sobre qualquer wallpaper (ajuste em Janelas)"; checked: Settings.desktopShadow; onToggled: on => Settings.desktopShadow = on }
        SetRow { icon: "blur"; label: "Desfoque atrás dos widgets"; description: "O desfoque do Hyprland atrás dos cartões e do vidro"; checked: Settings.desktopBlur; onToggled: on => Settings.desktopBlur = on }
    }

    // ---- comportamento ----
    SetSection {
        title: "Comportamento"; icon: "cursorMove"
        SetChoice {
            icon: "monitor"; label: "Mostrar widgets em"
            readonly property var sc: Quickshell.screens
            options: [["", "Principal"]].concat(sc.map(s => [s.name, s.name]))
            value: Settings.list(Settings.desktopScreens)[0] ?? ""
            onPicked: v => Settings.desktopScreens = v === "" ? [] : [v]
        }
        SetRow { icon: "cursorMove"; label: "Arrastar sem modo de edição"; description: "Mover direto na área de trabalho (travar desliga)"; checked: Settings.desktopAlwaysDrag; onToggled: on => Settings.desktopAlwaysDrag = on }
        SetRow { icon: "menu"; label: "Menu de clique direito"; description: "No fundo da área de trabalho"; checked: Settings.desktopMenu; onToggled: on => Settings.desktopMenu = on }
        SetExpander {
            icon: "grid"; label: "Grade e encaixe"; description: "Alinhamento ao arrastar"
            SetRow { sub: true; label: "Encaixar na grade ao arrastar"; description: "Grade de 24 px e guias no centro da tela"; checked: Settings.desktopSnap; onToggled: on => Settings.desktopSnap = on }
            SetRow { sub: true; label: "Mostrar a grade ao arrastar"; description: "Pontos só enquanto um widget é movido"; checked: Settings.desktopGrid; onToggled: on => Settings.desktopGrid = on }
            SetRow { sub: true; label: "Linhas de alinhamento ao soltar"; description: "As bordas piscam por 2 s"; checked: Settings.desktopSnapLines; onToggled: on => Settings.desktopSnapLines = on }
        }
        SetExpander {
            visible: Settings.desktopMenu
            icon: "plus"; label: "Widgets no menu"; description: "Os que aparecem em Adicionar widget"
            lazy: Component {
                SetBlock {
                    sub: true
                    Flow {
                        width: parent.width
                        spacing: 5
                        Repeater {
                            model: DeskState.catalog
                            delegate: Rectangle {
                                id: mc
                                required property var modelData
                                readonly property bool on: Settings.list(Settings.desktopMenuHidden).indexOf(modelData.type) < 0
                                height: 30; width: mr.implicitWidth + 22; radius: 10
                                color: on ? Theme.tint(0.16) : (mm.containsMouse ? Theme.cardHi : "transparent")
                                border.width: 1; border.color: on ? Theme.accent : Theme.border
                                opacity: on ? 1 : 0.6
                                Row {
                                    id: mr
                                    anchors.centerIn: parent
                                    spacing: 6
                                    UiIcon { name: mc.modelData.icon; size: 14; color: mc.on ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                                    UiText { text: mc.modelData.name; color: Theme.text; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; font.strikeout: !mc.on }
                                }
                                MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { const l = Settings.list(Settings.desktopMenuHidden), i = l.indexOf(mc.modelData.type); if (i >= 0) l.splice(i, 1); else l.push(mc.modelData.type); Settings.desktopMenuHidden = l } }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- layouts, clima, animacao ----
    SetSection {
        title: "Mais"; icon: "layers"
        SetExpander {
            icon: "layers"; label: "Layouts prontos"; description: "Trocam só os widgets; o visual inteiro fica em Visuais salvos"
            lazy: Component {
                SetBlock {
                    sub: true
                    Flow {
                        width: parent.width
                        spacing: SetK.md
                        Repeater {
                            model: DeskState.builtins
                            delegate: Rectangle {
                                id: pc
                                required property var modelData
                                readonly property bool cur: DeskState.lastApplied === modelData.name
                                width: 190; height: 152; radius: 14
                                color: ph.hovered ? Theme.cardHi : Theme.track
                                border.width: cur ? 2 : 1; border.color: cur ? Theme.accent : Theme.border
                                HoverHandler { id: ph }
                                LookPreview { id: lpv; x: 8; y: 8; width: parent.width - 16; look: pc.modelData.data }
                                Row {
                                    anchors { left: parent.left; leftMargin: 12; top: lpv.bottom; topMargin: 8 }
                                    spacing: 7
                                    UiIcon { name: pc.modelData.icon || "dashboard"; size: 15; color: pc.cur ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                                    UiText { text: pc.modelData.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                                }
                                UiText {
                                    anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 8 }
                                    text: pc.cur ? "Em uso" : (pc.modelData.data.desktopWidgets.length === 1 ? "1 widget" : pc.modelData.data.desktopWidgets.length + " widgets")
                                    color: pc.cur ? Theme.accent : Theme.muted; font.pixelSize: 11
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { DeskState.apply(pc.modelData.name); page.say("Layout: " + pc.modelData.name) } }
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        UiButton { icon: "restore"; text: "Desfazer"; kind: "ghost"; visible: !!Looks.undoData; onClicked: Looks.undo() }
                        UiButton { icon: "layers"; text: "Abrir Visuais salvos"; kind: "ghost"; onClicked: Settings.settingsPage = "looks" }
                    }
                }
            }
        }
        SetExpander {
            icon: "sun"; label: "Clima"; description: "Para o widget de clima (Open-Meteo, grátis e sem conta)"
            SetRow {
                sub: true; label: "Cidade"; description: "Vazio descobre pela internet"
                UiField { width: 200; text: Settings.weatherCity; placeholderText: "Cidade"; onEditingFinished: Settings.weatherCity = text.trim() }
                UiButton { icon: "refresh"; kind: "ghost"; onClicked: Weather.refresh() }
            }
            SetChoice { sub: true; label: "Unidades"; options: [["metric", "°C, km/h"], ["imperial", "°F, mph"]]; value: Settings.weatherUnits; onPicked: v => Settings.weatherUnits = v }
            SetSlider { sub: true; label: "Atualizar a cada"; from: 5; to: 120; step: 5; unit: " min"; def: 20; value: Settings.weatherInterval; onMoved: v => Settings.weatherInterval = Math.round(v / 5) * 5 }
            SetBlock {
                sub: true
                UiText {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: Weather.busy ? "Buscando…" : Weather.error !== "" ? Weather.error : Weather.ready ? Weather.place + ": " + Math.round(Weather.now.temp) + Weather.unit + ", " + Weather.describe(Weather.now.code).toLowerCase() + " (atualizado às " + Qt.formatTime(Weather.updated, "HH:mm") + ")" : "Ainda não consultado (adicione um widget de clima)."
                    color: Weather.error !== "" ? Theme.danger : Theme.muted; font.pixelSize: 12
                }
            }
        }
        SetExpander {
            icon: "animation"; label: "Animação dos widgets"; description: "Ao mudar de lugar ou tamanho, inclusive ao aplicar um layout"
            lazy: Component { SetBlock { sub: true; AnimPicker { width: parent.width; target: "desktop" } } }
        }
    }
}
