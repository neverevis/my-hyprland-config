// Pagina "Widgets": padroes da area de trabalho, catalogo por grupo, os widgets na tela com todas as opcoes
// (mesmo formulario do inspetor), a cor padrao dos widgets, clima, layouts prontos e a animacao dos widgets (visuais completos: PageLooks).
import Quickshell
import QtQuick

Column {
    id: page
    spacing: 14
    property string toast: ""
    property string openId: DeskState.selected
    Timer { id: toastT; interval: 2200; onTriggered: page.toast = "" }
    function say(s) { toast = s; toastT.restart() }

    Card {
        icon: "dashboard"
        title: "Área de trabalho"
        subtitle: "Widgets por cima do wallpaper e por baixo das janelas. Clique direito no fundo da área de trabalho abre o menu (adicionar no ponto clicado, editar, wallpaper, presets)."
        UiSwitch { label: "Mostrar os widgets"; icon: "eye"; checked: Settings.desktopOn; onToggled: on => Settings.desktopOn = on }
        Row {
            spacing: 8
            UiButton { icon: DeskState.editing ? "check" : "pencil"; text: DeskState.editing ? "Terminar edição" : "Editar na tela"; kind: "accent"; onClicked: { DeskState.editing = !DeskState.editing; if (DeskState.editing) Settings.settingsOpen = false } }
            UiButton { icon: DeskState.locked ? "lockOpen" : "lock"; text: DeskState.locked ? "Destravar posições" : "Travar posições"; kind: "ghost"; onClicked: Settings.desktopLocked = !Settings.desktopLocked }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: (Settings.desktopWidgets || []).length + " widget(s) na tela"; color: Theme.muted; font.pixelSize: 12 }
        }
        UiLabel { text: "Fundo padrão dos widgets" }
        UiSeg { options: [["card", "Cartão", "cards"], ["glass", "Vidro", "glass"], ["none", "Sem fundo", "image"]]; value: Settings.desktopCardStyle; onPicked: v => Settings.desktopCardStyle = v }
        UiSlider { label: "Opacidade do cartão"; icon: "glass"; from: 0; to: 100; value: Settings.desktopCard; suffix: " %"; onMoved: v => Settings.desktopCard = v }
        ToneSwatches {
            width: parent.width
            label: "Cor dos widgets"
            value: Settings.desktopTone
            custom: Settings.desktopToneColor
            onPicked: v => Settings.desktopTone = v
        }
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: Settings.desktopTone === "auto" ? "Automática: texto claro ou escuro conforme o wallpaper embaixo de cada widget, destaques na cor do tema."
                : Settings.desktopTone === "neutral" ? "Neutra: só o texto do tema, sem cor de destaque."
                : Settings.desktopTone === "custom" ? "Uma cor só para todos os widgets." : Settings.desktopTone.indexOf("wall") === 0 ? "Uma cor que existe no wallpaper: muda junto quando o wallpaper muda." : "Cartões no tom suave dessa cor da paleta, texto e destaques nela. Muda junto com o tema." }
        ColorField { visible: Settings.desktopTone === "custom"; label: "Minha cor"; value: Settings.desktopToneColor; onPicked: c => Settings.desktopToneColor = c.toString() }
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: "Cada widget pode ter a própria cor nas opções dele (ou seguir esta, em \"Padrão\")." }
        UiSwitch { label: "Sombra nos widgets"; icon: "layers"; description: "Deixa o texto legível em cima de qualquer wallpaper. Estilo, intensidade e tamanho: Aparência › Sombras e brilhos."; checked: Settings.desktopShadow; onToggled: on => Settings.desktopShadow = on }
        UiSwitch { label: "Encaixar na grade ao arrastar"; description: "Grade de 24 px e guias no centro da tela."; checked: Settings.desktopSnap; onToggled: on => Settings.desktopSnap = on }
        UiSwitch { label: "Arrastar sem modo de edição"; icon: "cursorMove"; description: "Mover os widgets direto na área de trabalho (clique direito abre o menu). Travar posições desliga."; checked: Settings.desktopAlwaysDrag; onToggled: on => Settings.desktopAlwaysDrag = on }
        UiSwitch { label: "Grade ao arrastar"; icon: "grid"; description: "Mostra a grade de pontos só enquanto um widget é movido."; checked: Settings.desktopGrid; onToggled: on => Settings.desktopGrid = on }
        UiSwitch { label: "Linhas de alinhamento ao soltar"; icon: "alignCenter"; description: "As bordas do widget piscam por 2 s depois de soltar."; checked: Settings.desktopSnapLines; onToggled: on => Settings.desktopSnapLines = on }
        UiSwitch { label: "Desfoque atrás dos widgets"; icon: "blur"; description: "O desfoque do Hyprland por trás dos cartões e do vidro. A intensidade é a da página Blur."; checked: Settings.desktopBlur; onToggled: on => Settings.desktopBlur = on }
        UiLabel { text: "Mostrar widgets em" }
        UiSeg {
            readonly property var sc: Quickshell.screens
            options: [["", "Principal"]].concat(sc.map(s => [s.name, s.name]))
            value: Settings.list(Settings.desktopScreens)[0] ?? ""
            onPicked: v => Settings.desktopScreens = v === "" ? [] : [v]
        }
        UiSwitch { label: "Menu de clique direito na área de trabalho"; icon: "menu"; checked: Settings.desktopMenu; onToggled: on => Settings.desktopMenu = on }
        Column {
            visible: Settings.desktopMenu
            width: parent.width
            spacing: 8
            UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: "Widgets que aparecem em \"Adicionar widget\" no menu (clique para tirar ou pôr de volta):" }
            Flow {
                width: parent.width
                spacing: 5
                Repeater {
                    model: DeskState.catalog
                    delegate: Rectangle {
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
                            UiIcon { name: modelData.icon; size: 14; color: parent.parent.on ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                            UiText { text: modelData.name; color: Theme.text; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; font.strikeout: !parent.parent.on }
                        }
                        MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { const l = Settings.list(Settings.desktopMenuHidden), i = l.indexOf(modelData.type); if (i >= 0) l.splice(i, 1); else l.push(modelData.type); Settings.desktopMenuHidden = l } }
                    }
                }
            }
        }
    }

    Card {
        icon: "plus"
        title: "Adicionar"
        subtitle: "O widget entra no canto de cima e já fica selecionado para arrastar e ajustar."
        Repeater {
            model: DeskState.groups
            delegate: Column {
                id: grp
                required property var modelData
                width: parent.width
                spacing: 6
                UiLabel { text: grp.modelData.label }
                Flow {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: DeskState.catalog.filter(c => c.group === grp.modelData.id)
                        delegate: Rectangle {
                            required property var modelData
                            width: 212; height: 66; radius: 14
                            color: cm.containsMouse ? Theme.cardHi : Theme.track
                            border.width: 1; border.color: cm.containsMouse ? Theme.accent : Theme.border
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Rectangle {
                                id: ic
                                x: 12; anchors.verticalCenter: parent.verticalCenter
                                width: 40; height: 40; radius: 12
                                color: Theme.tint(0.16)
                                UiIcon { anchors.centerIn: parent; name: modelData.icon; size: 20; color: Theme.accent }
                            }
                            Column {
                                anchors { left: ic.right; leftMargin: 10; right: plus.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                                spacing: 2
                                UiText { text: modelData.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                UiText { width: parent.width; elide: Text.ElideRight; text: modelData.desc; color: Theme.muted; font.pixelSize: 11 }
                            }
                            UiIcon { id: plus; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } name: "plus"; size: 18; color: cm.containsMouse ? Theme.accent : Theme.muted }
                            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { Settings.desktopOn = true; const id = DeskState.add(modelData.type); page.openId = id; page.say(modelData.name + " adicionado") } }
                        }
                    }
                }
            }
        }
        UiText { visible: page.toast !== ""; text: page.toast; color: Theme.accent; font.pixelSize: 12 }
    }

    Card {
        icon: "tune"
        title: "Na tela"
        subtitle: "Clique num widget para ver todas as opções dele (as mesmas do inspetor na área de trabalho)."
        UiText { visible: !(Settings.desktopWidgets || []).length; text: "Nenhum widget ainda."; color: Theme.muted; font.pixelSize: 13 }
        Repeater {
            model: (Settings.desktopWidgets || []).map(w => w.id)
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var w: { Settings.desktopWidgets; return DeskState.find(modelData) }
                readonly property var info: w ? DeskState.info(w.type) : null
                readonly property bool open: page.openId === modelData
                width: parent.width
                height: head.height + (open ? body.implicitHeight + 16 : 0)
                radius: 12
                clip: true
                color: open ? Theme.cardHi : (hm.containsMouse ? Qt.rgba(Theme.cardHi.r, Theme.cardHi.g, Theme.cardHi.b, 0.6) : "transparent")
                border.width: open ? 1 : 0; border.color: Theme.border
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Item {
                    id: head
                    width: parent.width; height: 52
                    MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.openId = row.open ? "" : row.modelData }
                    Rectangle { id: hic; x: 12; anchors.verticalCenter: parent.verticalCenter; width: 32; height: 32; radius: 10; color: Theme.tint(0.16)
                        UiIcon { anchors.centerIn: parent; name: row.info ? row.info.icon : "dashboard"; size: 16; color: Theme.accent } }
                    Column {
                        anchors { left: hic.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        UiText { text: row.info ? row.info.name : ""; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        UiText { text: row.w ? row.w.cols + "×" + row.w.rows + "  ·  " + ({ auto: "fundo padrão", card: "cartão", glass: "vidro", none: "sem fundo" })[DeskState.opt(row.w, "card")] + (DeskState.opt(row.w, "lock") ? "  ·  na tela de bloqueio" : "") + (DeskState.opt(row.w, "place") !== "free" ? "  ·  posição automática" : "") : ""
                            color: Theme.muted; font.pixelSize: 11 }
                    }
                    Row {
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 4
                        UiButton { icon: "cards"; kind: "ghost"; onClicked: DeskState.duplicate(row.modelData) }
                        UiButton { icon: "trash"; kind: "ghost"; onClicked: { if (page.openId === row.modelData) page.openId = ""; DeskState.remove(row.modelData) } }
                        UiIcon { anchors.verticalCenter: parent.verticalCenter; name: row.open ? "chevUp" : "chevDown"; size: 16; color: Theme.muted }
                    }
                }
                Column {
                    id: body
                    visible: row.open
                    x: 16; y: head.height
                    width: row.width - 32
                    spacing: 12
                    WidgetPreview {
                        width: parent.width
                        height: Math.min(260, Math.max(150, width * 0.36))
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

    Card {
        icon: "sun"
        title: "Clima"
        subtitle: "Para o widget de clima. Os dados vêm do Open-Meteo (gratuito, sem conta)."
        Row {
            spacing: 10
            UiText { text: "Cidade"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: 90 }
            UiField { width: 280; text: Settings.weatherCity; placeholderText: "Vazio = descobrir pela internet"; onEditingFinished: Settings.weatherCity = text.trim() }
            UiButton { icon: "refresh"; text: "Atualizar"; kind: "ghost"; onClicked: Weather.refresh() }
        }
        UiText {
            text: Weather.busy ? "Buscando…" : Weather.error !== "" ? Weather.error : Weather.ready ? Weather.place + ": " + Math.round(Weather.now.temp) + Weather.unit + ", " + Weather.describe(Weather.now.code).toLowerCase() + " (atualizado às " + Qt.formatTime(Weather.updated, "HH:mm") + ")" : "Ainda não consultado (adicione um widget de clima)."
            color: Weather.error !== "" ? Theme.danger : Theme.muted; font.pixelSize: 12
        }
        Row {
            spacing: 10
            UiText { text: "Unidades"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: 90 }
            UiSeg { options: [["metric", "°C, km/h"], ["imperial", "°F, mph"]]; value: Settings.weatherUnits; onPicked: v => Settings.weatherUnits = v }
        }
        UiSlider { label: "Atualizar a cada"; icon: "timer"; from: 5; to: 120; value: Settings.weatherInterval; suffix: " min"; onMoved: v => Settings.weatherInterval = Math.round(v / 5) * 5 }
    }

    Card {
        icon: "layers"
        title: "Layouts prontos"
        subtitle: "Trocam só os widgets (o resto fica como está). Para guardar o visual inteiro — wallpaper, barras, cores, animações — use a página Visuais."
        Flow {
            width: parent.width
            spacing: 12
            Repeater {
                model: DeskState.builtins
                delegate: Rectangle {
                    id: pc
                    required property var modelData
                    readonly property bool cur: DeskState.lastApplied === modelData.name
                    width: 214; height: 168; radius: 16
                    color: ph.hovered ? Theme.cardHi : Theme.track
                    border.width: cur ? 2 : 1; border.color: cur ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: 120 } }
                    HoverHandler { id: ph }
                    LookPreview { id: lpv; x: 10; y: 10; width: parent.width - 20; look: pc.modelData.data }
                    Row {
                        anchors { left: parent.left; leftMargin: 12; top: lpv.bottom; topMargin: 10 }
                        spacing: 7
                        UiIcon { name: pc.modelData.icon || "dashboard"; size: 15; color: pc.cur ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: pc.modelData.name; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    UiText {
                        anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 10 }
                        text: pc.cur ? "Em uso" : pc.modelData.data.desktopWidgets.length + " widget(s)"
                        color: pc.cur ? Theme.accent : Theme.muted; font.pixelSize: 11
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { DeskState.apply(pc.modelData.name); page.say("Layout: " + pc.modelData.name) } }
                }
            }
        }
        Row {
            spacing: 8
            UiButton { icon: "restore"; text: "Desfazer"; kind: "ghost"; visible: !!Looks.undoData; onClicked: Looks.undo() }
            UiButton { icon: "layers"; text: "Abrir Visuais"; kind: "ghost"; onClicked: Settings.settingsPage = "looks" }
        }
    }

    Card {
        icon: "animation"
        title: "Animação dos widgets"
        subtitle: "Usada quando eles mudam de lugar ou de tamanho (inclusive ao aplicar um preset)."
        AnimPicker { target: "desktop" }
    }
}
