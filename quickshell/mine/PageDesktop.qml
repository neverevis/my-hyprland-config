// Pagina "Widgets": padroes da area de trabalho, catalogo por grupo, os widgets na tela com todas as opcoes
// (mesmo formulario do inspetor), clima, presets (o visual inteiro) e a animacao dos widgets.
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
            UiButton { icon: DeskState.locked ? "lockOpen" : "lock"; text: DeskState.locked ? "Destravar posições" : "Travar posições"; kind: "ghost"; onClicked: DeskState.locked = !DeskState.locked }
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
                : Settings.desktopTone === "custom" ? "Uma cor só para todos os widgets." : "Cartões no tom suave dessa cor da paleta, texto e destaques nela. Muda junto com o tema." }
        ColorField { visible: Settings.desktopTone === "custom"; label: "Minha cor"; value: Settings.desktopToneColor; onPicked: c => Settings.desktopToneColor = c.toString() }
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: "Cada widget pode ter a própria cor nas opções dele (ou seguir esta, em \"Padrão\")." }
        UiSwitch { label: "Sombra nos widgets sem fundo"; description: "Deixa o texto legível em cima de qualquer wallpaper."; checked: Settings.desktopShadow; onToggled: on => Settings.desktopShadow = on }
        UiSwitch { label: "Encaixar na grade ao arrastar"; description: "Grade de 24 px e guias no centro da tela."; checked: Settings.desktopSnap; onToggled: on => Settings.desktopSnap = on }
        UiSwitch { label: "Menu de clique direito na área de trabalho"; checked: Settings.desktopMenu; onToggled: on => Settings.desktopMenu = on }
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
                    Flow {
                        width: parent.width
                        spacing: 4
                        UiText { text: "Tamanho  "; color: Theme.text; font.pixelSize: 13; height: 28; verticalAlignment: Text.AlignVCenter }
                        Repeater {
                            model: row.info ? row.info.sizes : []
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool on: row.w && row.w.cols === modelData[0] && row.w.rows === modelData[1]
                                height: 28; width: 46; radius: 8
                                color: on ? Theme.accent : (szm.containsMouse ? Theme.cardHi : Theme.track)
                                border.width: 1; border.color: on ? Theme.accent : Theme.border
                                UiText { anchors.centerIn: parent; text: modelData[0] + "×" + modelData[1]; color: parent.on ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                                MouseArea { id: szm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DeskState.setSize(row.modelData, modelData[0], modelData[1]) }
                            }
                        }
                    }
                    OptionsForm {
                        width: parent.width
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
        title: "Presets"
        subtitle: "Um preset guarda o visual inteiro: widgets, barras, moldura, vidro, tema e wallpaper. Ao aplicar, os widgets deslizam e mudam de forma até o novo lugar."
        Row {
            width: parent.width
            spacing: 8
            UiField { id: nameF; width: Math.min(300, parent.width - 190); placeholderText: "Nome do preset (ex.: Noite, Foco…)"; onAccepted: saveBtn.clicked() }
            UiButton { id: saveBtn; icon: "plus"; text: "Salvar o visual atual"; kind: "accent"; onClicked: { const n = DeskState.save(nameF.text); nameF.text = ""; page.say("Salvo como “" + n + "”") } }
        }
        Flow {
            width: parent.width
            spacing: 12
            Repeater {
                model: DeskState.all
                delegate: Rectangle {
                    id: pc
                    required property var modelData
                    readonly property bool cur: DeskState.lastApplied === modelData.name
                    property bool renaming: false
                    width: 232; height: 198; radius: 16
                    color: pm.containsMouse ? Theme.cardHi : Theme.track
                    border.width: cur ? 2 : 1; border.color: cur ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: 120 } }
                    // miniatura: wallpaper do preset + os widgets nos lugares deles
                    Item {
                        id: thumb
                        x: 10; y: 10; width: parent.width - 20; height: width * 9 / 16
                        readonly property real k: width / 1920
                        Rectangle { anchors.fill: parent; radius: 10; color: Theme.bg }
                        RoundImage {
                            anchors.fill: parent; radius: 10
                            source: { const p = pc.modelData.data && pc.modelData.data.wallpaper ? pc.modelData.data.wallpaper : Wallpaper.current; return p ? "file://" + p : "" }
                            sourceSize: Qt.size(320, 180)
                            dim: 0.25
                        }
                        Repeater {
                            model: pc.modelData.data && pc.modelData.data.desktopWidgets ? pc.modelData.data.desktopWidgets : []
                            delegate: Rectangle {
                                required property var modelData
                                readonly property real aw: (1920 - 44) * thumb.k
                                readonly property real ah: (1080 - 80) * thumb.k
                                width: DeskState.px(modelData.cols) * thumb.k; height: DeskState.px(modelData.rows) * thumb.k
                                x: 22 * thumb.k + modelData.fx * (aw - width)
                                y: 40 * thumb.k + modelData.fy * (ah - height)
                                radius: Math.min(width, height) * 0.2
                                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.85)
                                border.width: 1; border.color: Theme.tint(0.6)
                                UiIcon { anchors.centerIn: parent; name: DeskState.info(modelData.type).icon; size: Math.max(7, Math.min(parent.width, parent.height) * 0.45); color: Theme.accent }
                            }
                        }
                        Rectangle {
                            visible: !!pc.modelData.builtin
                            anchors { left: parent.left; top: parent.top; margins: 6 }
                            width: bt.implicitWidth + 12; height: 18; radius: 9
                            color: Qt.rgba(0, 0, 0, 0.55)
                            UiText { id: bt; anchors.centerIn: parent; text: "Layout pronto"; color: "white"; font.pixelSize: 9; font.weight: Font.DemiBold }
                        }
                    }
                    // nome (renomear com duplo clique nos seus)
                    UiText {
                        visible: !pc.renaming
                        anchors { left: parent.left; leftMargin: 12; right: acts.left; rightMargin: 6; top: thumb.bottom; topMargin: 10 }
                        elide: Text.ElideRight
                        text: pc.modelData.name; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold
                    }
                    UiField {
                        visible: pc.renaming
                        anchors { left: parent.left; leftMargin: 8; right: acts.left; rightMargin: 6; top: thumb.bottom; topMargin: 4 }
                        text: pc.modelData.name
                        onVisibleChanged: if (visible) { forceActiveFocus(); selectAll() }
                        onEditingFinished: { DeskState.rename(pc.modelData.name, text); pc.renaming = false }
                    }
                    UiText {
                        anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 10 }
                        text: pc.cur ? "Em uso" : (pc.modelData.builtin ? "Só os widgets" : new Date(pc.modelData.created).toLocaleDateString(Qt.locale("pt_BR"), "d MMM yyyy"))
                        color: pc.cur ? Theme.accent : Theme.muted; font.pixelSize: 11; font.weight: pc.cur ? Font.DemiBold : Font.Normal
                    }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { DeskState.apply(pc.modelData.name); page.say("Aplicado: " + pc.modelData.name) }
                        onDoubleClicked: if (!pc.modelData.builtin) pc.renaming = true }
                    Row {
                        id: acts
                        anchors { right: parent.right; rightMargin: 8; bottom: parent.bottom; bottomMargin: 6 }
                        spacing: 2
                        visible: !pc.modelData.builtin
                        opacity: pm.containsMouse || hov1.containsMouse || hov2.containsMouse || hov3.containsMouse ? 1 : 0.4
                        Rectangle { width: 26; height: 26; radius: 13; color: hov1.containsMouse ? Theme.cardHi : "transparent"
                            UiIcon { anchors.centerIn: parent; name: "pencil"; size: 14; color: Theme.muted }
                            MouseArea { id: hov1; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pc.renaming = true } }
                        Rectangle { width: 26; height: 26; radius: 13; color: hov2.containsMouse ? Theme.cardHi : "transparent"
                            UiIcon { anchors.centerIn: parent; name: "refresh"; size: 14; color: Theme.muted }
                            MouseArea { id: hov2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { DeskState.overwrite(pc.modelData.name); page.say("“" + pc.modelData.name + "” atualizado com o visual atual") } } }
                        Rectangle { width: 26; height: 26; radius: 13; color: hov3.containsMouse ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.2) : "transparent"
                            property bool armed: false
                            Timer { id: dis; interval: 3000; onTriggered: parent.armed = false }
                            UiIcon { anchors.centerIn: parent; name: parent.armed ? "check" : "trash"; size: 14; color: parent.armed ? Theme.danger : Theme.muted }
                            MouseArea { id: hov3; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (!parent.armed) { parent.armed = true; dis.restart(); page.say("Clique de novo para excluir") } else DeskState.removePreset(pc.modelData.name) } } }
                    }
                }
            }
        }
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: "Clique num preset para aplicar. Nos seus: duplo clique (ou o lápis) renomeia, a seta atualiza com o visual de agora e a lixeira exclui." }
    }

    Card {
        icon: "animation"
        title: "Animação dos widgets"
        subtitle: "Usada quando eles mudam de lugar ou de tamanho (inclusive ao aplicar um preset)."
        AnimPicker { target: "desktop" }
    }
}
