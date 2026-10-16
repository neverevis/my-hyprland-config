// Pagina "Area de trabalho": widgets (catalogo, edicao) e presets (salvar o visual inteiro e trocar com um clique).
import Quickshell
import QtQuick

Column {
    id: page
    spacing: 14
    property string toast: ""
    Timer { id: toastT; interval: 2200; onTriggered: page.toast = "" }
    function say(s) { toast = s; toastT.restart() }

    Card {
        icon: "dashboard"
        title: "Widgets"
        subtitle: "Cartões na área de trabalho, por cima do wallpaper e por baixo das janelas. Clique direito num widget para editar o layout."
        UiSwitch { label: "Mostrar os widgets"; icon: "eye"; checked: Settings.desktopOn; onToggled: on => Settings.desktopOn = on }
        Row {
            spacing: 8
            UiButton { icon: DeskState.editing ? "check" : "pencil"; text: DeskState.editing ? "Terminar edição" : "Editar layout"; kind: "accent"; onClicked: { DeskState.editing = !DeskState.editing; if (DeskState.editing) Settings.settingsOpen = false } }
            Text { anchors.verticalCenter: parent.verticalCenter; text: (Settings.desktopWidgets || []).length + " widget(s) na tela"; color: Theme.muted; font.pixelSize: 12 }
        }
        UiSlider { label: "Fundo dos cartões"; icon: "glass"; from: 0; to: 100; value: Settings.desktopCard; suffix: " %"; onMoved: v => Settings.desktopCard = v }
        UiLabel { text: "Adicionar" }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: DeskState.catalog
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
                        Text { text: modelData.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text { width: parent.width; elide: Text.ElideRight; text: modelData.desc; color: Theme.muted; font.pixelSize: 11 }
                    }
                    UiIcon { id: plus; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } name: "plus"; size: 18; color: cm.containsMouse ? Theme.accent : Theme.muted }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { Settings.desktopOn = true; DeskState.add(modelData.type); page.say(modelData.name + " adicionado: arraste para o lugar e clique fora para terminar") } }
                }
            }
        }
        Text { visible: page.toast !== ""; text: page.toast; color: Theme.accent; font.pixelSize: 12 }
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
                            Text { id: bt; anchors.centerIn: parent; text: "Layout pronto"; color: "white"; font.pixelSize: 9; font.weight: Font.DemiBold }
                        }
                    }
                    // nome (renomear com duplo clique nos seus)
                    Text {
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
                    Text {
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
        Text { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: "Clique num preset para aplicar. Nos seus: duplo clique (ou o lápis) renomeia, a seta atualiza com o visual de agora e a lixeira exclui." }
    }

    Card {
        icon: "animation"
        title: "Animação dos widgets"
        subtitle: "Usada quando eles mudam de lugar ou de tamanho (inclusive ao aplicar um preset)."
        AnimPicker { target: "desktop" }
    }
}
