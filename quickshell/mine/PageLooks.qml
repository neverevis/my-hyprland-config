// Pagina "Visuais" (kit Set*): grade de visuais salvos com miniatura (clique aplica, desfazer por um minuto), salvar o visual
// de agora escolhendo o que entra, renomear, atualizar, exportar em .zip (com wallpaper e imagens) e importar.
// Os layouts prontos (so widgets) ficam na pagina Area de trabalho.
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Visuais"
    subtitle: "Salve, aplique e troque o visual inteiro do shell"
    property string toast: ""
    Timer { id: toastT; interval: 2600; onTriggered: page.toast = "" }
    function say(s) { toast = s; toastT.restart() }
    property var pick: Looks.defaultGroups()
    Connections { target: Looks; function onDone(msg) { page.say(msg.indexOf("Falhou:") === 0 ? "Não deu para concluir. Tente de novo ou veja o arquivo." : msg) } }
    Component.onCompleted: Looks.scan()

    // previa: o visual de agora (desenhado, parado)
    preview: SetPreview {
        height: 210
        LookPreview { anchors.centerIn: parent; width: 340; look: ({}) }
        Rectangle {
            visible: page.toast !== ""
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: SetK.md }
            width: tt.implicitWidth + 28; height: 32; radius: 16
            color: Theme.accent
            UiText { id: tt; anchors.centerIn: parent; text: page.toast; color: Theme.accentText; font.pixelSize: 13; font.weight: Font.DemiBold }
        }
    }

    // desfazer (vale por um minuto depois de aplicar)
    SetSection {
        visible: !!Looks.undoData
        title: ""
        SetRow {
            icon: "history"; label: "Aplicado: " + Looks.undoName; description: "Não gostou?"
            UiButton { icon: "restore"; text: "Desfazer"; kind: "accent"; onClicked: { Looks.undo(); page.say("Voltou ao visual de antes") } }
        }
    }

    // ---- visuais salvos ----
    SetSection {
        title: "Seus visuais"; icon: "palette"
        subtitle: Looks.list.length ? "Clique para aplicar; o wallpaper troca com a transição dele" : "Nenhum ainda: salve o visual de agora ou importe um .zip"
        SetBlock {
            visible: Looks.list.length > 0
            Flow {
                id: grid
                width: parent.width
                spacing: SetK.md
                readonly property int cols: width >= 640 ? 3 : 2
                readonly property real cw: (width - spacing * (cols - 1)) / cols
                Repeater {
                    model: Looks.list
                    delegate: Rectangle {
                        id: lc
                        required property var modelData
                        readonly property bool cur: Looks.current === modelData.name
                        property bool renaming: false
                        width: grid.cw; height: pv.height + 98; radius: SetK.innerRadius + 4
                        color: hh.hovered ? Theme.cardHi : Theme.track
                        HoverHandler { id: hh }
                        border.width: lc.cur ? 2 : 1; border.color: lc.cur ? Theme.accent : Theme.border
                        LookPreview { id: pv; x: 8; y: 8; width: parent.width - 16; look: lc.modelData.data }
                        MouseArea {
                            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: bar.top }
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { Looks.apply(lc.modelData.name); page.say("Aplicado: " + lc.modelData.name) }
                            onDoubleClicked: lc.renaming = true
                        }
                        Rectangle {
                            visible: !!lc.modelData.imported
                            anchors { left: pv.left; top: pv.top; margins: 6 }
                            width: ib.implicitWidth + 12; height: 18; radius: 9; color: Qt.rgba(0, 0, 0, 0.55)
                            UiText { id: ib; anchors.centerIn: parent; text: "Importado"; color: "white"; font.pixelSize: 9; font.weight: Font.DemiBold }
                        }
                        Rectangle {
                            visible: lc.cur
                            anchors { right: pv.right; top: pv.top; margins: 6 }
                            width: 22; height: 22; radius: 11; color: Theme.accent
                            UiIcon { anchors.centerIn: parent; name: "check"; size: 14; color: Theme.accentText }
                        }
                        UiText {
                            visible: !lc.renaming
                            anchors { left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12; top: pv.bottom; topMargin: 8 }
                            elide: Text.ElideRight
                            text: lc.modelData.name; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold
                        }
                        UiField {
                            visible: lc.renaming
                            anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; top: pv.bottom; topMargin: 4 }
                            text: lc.modelData.name
                            onVisibleChanged: if (visible) { forceActiveFocus(); selectAll() }
                            onEditingFinished: { Looks.rename(lc.modelData.name, text); lc.renaming = false }
                        }
                        UiText {
                            visible: !lc.renaming
                            anchors { left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12; top: pv.bottom; topMargin: 30 }
                            elide: Text.ElideRight; font.pixelSize: 11
                            text: lc.cur ? "Em uso" : (lc.modelData.desc || new Date(lc.modelData.created).toLocaleDateString(Qt.locale("pt_BR"), "d MMM yyyy"))
                            color: lc.cur ? Theme.accent : Theme.muted; font.weight: lc.cur ? Font.DemiBold : Font.Normal
                        }
                        Item {
                            id: bar
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 36
                            // grupos guardados
                            Row {
                                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                spacing: 5
                                Repeater {
                                    model: lc.modelData.groups
                                    delegate: UiIcon { required property string modelData; name: Looks.group(modelData).icon; size: 13; color: Theme.muted }
                                }
                            }
                            Row {
                                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                                spacing: 0
                                opacity: hh.hovered ? 1 : 0.5
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
            }
            UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc
                text: "Duplo clique ou lápis renomeia, setas atualizam e exportam um .zip para Downloads, a lixeira exclui." }
        }
    }

    // ---- salvar ----
    SetSection {
        title: "Salvar o visual de agora"; icon: "plus"
        subtitle: "Coisas pessoais nunca entram: clima, apps fixados, tarefas, notas e inatividade"
        SetRow {
            icon: "layers"; label: "Nome do novo visual"; description: page.pick.length + " de " + Looks.groups.length + " grupos entram" + (page.pick.length === 0 ? "; escolha ao menos um para salvar" : "")
            UiField { id: nameF; width: 180; placeholderText: "Ex.: Noite, Foco…"; onAccepted: saveB.clicked() }
            UiButton { id: saveB; icon: "plus"; text: "Salvar visual"; kind: "accent"; enabled: page.pick.length > 0
                onClicked: { const n = Looks.save(nameF.text, page.pick, descF.text); nameF.text = ""; descF.text = ""; page.say("Salvo como “" + n + "”") } }
        }
        SetExpander {
            icon: "tune"; label: "O que entra e descrição"; description: "Escolha os grupos que o visual guarda"
            SetRow {
                sub: true; label: "Descrição"
                UiField { id: descF; width: 240; placeholderText: "Opcional"; onAccepted: saveB.clicked() }
            }
            SetBlock {
                sub: true
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
        }
    }

    // ---- importar ----
    SetSection {
        title: "Importar"; icon: "download"
        subtitle: "Visuais exportados por este shell (.visual.zip), em Downloads, na pasta pessoal e nos wallpapers"
        SetRow {
            icon: "refresh"; label: Looks.busy === "scan" ? "Procurando…" : "Procurar de novo"; description: Looks.busy === "scan" ? "" : Looks.found.length === 0 ? "Nenhum visual encontrado; exporte um em outro computador e copie o .visual.zip para Downloads" : Looks.found.length === 1 ? "1 encontrado" : Looks.found.length + " encontrados"
            UiButton { text: "Procurar"; kind: "ghost"; enabled: Looks.busy !== "scan"; onClicked: Looks.scan() }
        }
        Repeater {
            model: Looks.found
            delegate: SetRow {
                required property var modelData
                icon: "layers"; label: modelData.name; description: modelData.path
                UiButton { icon: "download"; text: "Importar visual"; onClicked: Looks.importZip(modelData.path) }
            }
        }
    }
}
