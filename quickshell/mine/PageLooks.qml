// Pagina "Visuais": salvar o visual do shell escolhendo o que entra (grupos), aplicar com desfazer, renomear, atualizar,
// exportar em .zip (com o wallpaper e as imagens) e importar. Os layouts prontos (so widgets) ficam na pagina Widgets.
import Quickshell
import QtQuick

Column {
    id: page
    spacing: 14
    property string toast: ""
    Timer { id: toastT; interval: 2600; onTriggered: page.toast = "" }
    function say(s) { toast = s; toastT.restart() }
    property var pick: Looks.defaultGroups()
    Connections { target: Looks; function onDone(msg) { page.say(msg) } }
    Component.onCompleted: Looks.scan()

    // aviso flutuante (salvo, aplicado, exportado...)
    Rectangle {
        visible: page.toast !== ""
        width: tt.implicitWidth + 28; height: 34; radius: 17
        color: Theme.accent
        UiText { id: tt; anchors.centerIn: parent; text: page.toast; color: Theme.accentText; font.pixelSize: 13; font.weight: Font.DemiBold }
    }
    // desfazer (vale por um minuto depois de aplicar)
    Rectangle {
        visible: !!Looks.undoData
        width: parent.width; height: 52; radius: 14
        color: Theme.tint(0.14); border.width: 1; border.color: Theme.tint(0.5)
        UiIcon { id: ui; x: 16; anchors.verticalCenter: parent.verticalCenter; name: "history"; size: 18; color: Theme.accent }
        UiText { anchors { left: ui.right; leftMargin: 10; verticalCenter: parent.verticalCenter } text: "Aplicado: " + Looks.undoName + ". Não gostou?"; color: Theme.text; font.pixelSize: 13 }
        UiButton { anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } icon: "restore"; text: "Desfazer"; kind: "accent"; onClicked: { Looks.undo(); page.say("Voltou ao visual de antes") } }
    }

    Card {
        icon: "layers"
        title: "Salvar o visual atual"
        subtitle: "Um visual guarda o que você escolher abaixo. Coisas pessoais nunca entram: cidade do clima, apps fixados, tarefas, notas, histórico do launcher e inatividade."
        Row {
            width: parent.width
            spacing: 8
            UiField { id: nameF; width: Math.min(320, parent.width - 140); placeholderText: "Nome (ex.: Noite, Foco, Rosa…)"; onAccepted: saveB.clicked() }
            UiButton { id: saveB; icon: "plus"; text: "Salvar"; kind: "accent"; enabled: page.pick.length > 0
                onClicked: { const n = Looks.save(nameF.text, page.pick); nameF.text = ""; page.say("Salvo como “" + n + "”") } }
        }
        UiLabel { text: "O que entra" }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: Looks.groups
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: page.pick.indexOf(modelData.id) >= 0
                    height: 32; width: gr.implicitWidth + 22; radius: 16
                    color: on ? Theme.tint(0.2) : (gm.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: 1; border.color: on ? Theme.accent : Theme.border
                    Row {
                        id: gr
                        anchors.centerIn: parent
                        spacing: 6
                        UiIcon { name: parent.parent.on ? "check" : parent.parent.modelData.icon; size: 14; color: parent.parent.on ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: parent.parent.modelData.label; color: Theme.text; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { const l = page.pick.slice(), i = l.indexOf(parent.modelData.id); if (i >= 0) l.splice(i, 1); else l.push(parent.modelData.id); page.pick = l } }
                }
            }
        }
    }

    Card {
        icon: "palette"
        title: "Seus visuais"
        subtitle: Looks.list.length ? "Clique para aplicar. O wallpaper troca com a transição dele e os widgets deslizam até o novo lugar." : "Nenhum ainda: salve o visual de agora acima, ou importe um .zip."
        Flow {
            width: parent.width
            spacing: 12
            Repeater {
                model: Looks.list
                delegate: Rectangle {
                    id: lc
                    required property var modelData
                    readonly property bool cur: Looks.current === modelData.name
                    property bool renaming: false
                    width: 300; height: 272; radius: 16
                    color: hh.hovered ? Theme.cardHi : Theme.track
                    HoverHandler { id: hh }
                    border.width: lc.cur ? 2 : 1; border.color: lc.cur ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: 120 } }
                    LookPreview { id: pv; x: 10; y: 10; width: parent.width - 20; look: lc.modelData.data }
                    Rectangle {
                        visible: !!lc.modelData.imported
                        anchors { left: pv.left; top: pv.top; margins: 6 }
                        width: ib.implicitWidth + 12; height: 18; radius: 9; color: Qt.rgba(0, 0, 0, 0.55)
                        UiText { id: ib; anchors.centerIn: parent; text: "Importado"; color: "white"; font.pixelSize: 9; font.weight: Font.DemiBold }
                    }
                    UiText {
                        visible: !lc.renaming
                        anchors { left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12; top: pv.bottom; topMargin: 10 }
                        elide: Text.ElideRight
                        text: lc.modelData.name; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold
                    }
                    UiField {
                        visible: lc.renaming
                        anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; top: pv.bottom; topMargin: 4 }
                        text: lc.modelData.name
                        onVisibleChanged: if (visible) { forceActiveFocus(); selectAll() }
                        onEditingFinished: { Looks.rename(lc.modelData.name, text); lc.renaming = false }
                    }
                    // grupos guardados
                    Row {
                        anchors { left: parent.left; leftMargin: 12; top: pv.bottom; topMargin: 36 }
                        spacing: 6
                        Repeater {
                            model: lc.modelData.groups
                            delegate: UiIcon { required property string modelData; name: Looks.group(modelData).icon; size: 14; color: Theme.muted }
                        }
                    }
                    UiText {
                        anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 12 }
                        text: lc.cur ? "Em uso" : new Date(lc.modelData.created).toLocaleDateString(Qt.locale("pt_BR"), "d MMM yyyy")
                        color: lc.cur ? Theme.accent : Theme.muted; font.pixelSize: 11; font.weight: lc.cur ? Font.DemiBold : Font.Normal
                    }
                    MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { Looks.apply(lc.modelData.name); page.say("Aplicado: " + lc.modelData.name) }
                        onDoubleClicked: lc.renaming = true }
                    Row {
                        anchors { right: parent.right; rightMargin: 8; bottom: parent.bottom; bottomMargin: 6 }
                        spacing: 2
                        opacity: hh.hovered ? 1 : 0.45
                        component Act: Rectangle {
                            property string ico
                            property bool danger: false
                            signal hit()
                            width: 28; height: 28; radius: 14
                            color: am.containsMouse ? (danger ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.2) : Theme.cardHi) : "transparent"
                            UiIcon { anchors.centerIn: parent; name: parent.ico; size: 15; color: parent.danger && am.containsMouse ? Theme.danger : Theme.muted }
                            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
                        }
                        Act { ico: "pencil"; onHit: lc.renaming = true }
                        Act { ico: "refresh"; onHit: { Looks.overwrite(lc.modelData.name); page.say("“" + lc.modelData.name + "” atualizado com o visual de agora") } }
                        Act { ico: "download"; onHit: { Looks.exportZip(lc.modelData.name); page.say("Exportando…") } }
                        Act {
                            id: del
                            property bool armed: false
                            ico: armed ? "check" : "trash"; danger: true
                            Timer { id: dis; interval: 3000; onTriggered: del.armed = false }
                            onHit: { if (!armed) { armed = true; dis.restart(); page.say("Clique de novo para excluir") } else Looks.remove(lc.modelData.name) }
                        }
                    }
                }
            }
        }
        UiText { visible: Looks.list.length > 0; width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: "Duplo clique (ou o lápis) renomeia; a seta atualiza com o visual de agora; a seta para baixo exporta um .zip para Downloads; a lixeira exclui." }
    }

    Card {
        icon: "download"
        title: "Importar"
        subtitle: "Visuais exportados por este shell (.visual.zip). Procuro em Downloads, na pasta pessoal e na pasta de wallpapers. O wallpaper do visual vai para a sua pasta de wallpapers."
        Row {
            spacing: 8
            UiButton { icon: "refresh"; text: Looks.busy === "scan" ? "Procurando…" : "Procurar de novo"; kind: "ghost"; onClicked: Looks.scan() }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: Looks.found.length + " encontrado(s)"; color: Theme.muted; font.pixelSize: 12 }
        }
        Repeater {
            model: Looks.found
            delegate: Rectangle {
                required property var modelData
                width: parent.width; height: 56; radius: 12; color: Theme.track
                UiIcon { id: zi; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "layers"; size: 18; color: Theme.accent }
                Column {
                    anchors { left: zi.right; leftMargin: 12; right: ib2.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    UiText { width: parent.width; elide: Text.ElideRight; text: modelData.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                    UiText { width: parent.width; elide: Text.ElideMiddle; text: modelData.path; color: Theme.muted; font.pixelSize: 11 }
                }
                UiButton { id: ib2; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } icon: "download"; text: "Importar"; onClicked: Looks.importZip(modelData.path) }
            }
        }
    }
}
