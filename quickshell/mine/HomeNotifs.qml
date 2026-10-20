// Aba "Notificacoes" do Inicio: historico (NotifHistory) agrupado por app, com contador, botoes de acao dos avisos ainda vivos,
// copiar, links clicaveis e nao perturbar. Clique no aviso remove; botao do meio tambem; clique direito (ou a seta) abre o grupo.
import Quickshell
import QtQuick

Item {
    id: pg
    property var home
    property var open: ({})   // apps com o grupo aberto
    Component.onCompleted: NotifHistory.unread = 0

    // grupos por app, na ordem do aviso mais novo
    readonly property var groups: {
        const m = {}, out = []
        for (const it of NotifHistory.items) {
            if (!m[it.app]) { m[it.app] = { app: it.app, items: [] }; out.push(m[it.app]) }
            m[it.app].items.push(it)
        }
        return out
    }
    function toggle(app) { const o = Object.assign({}, open); o[app] = !o[app]; open = o }

    Row {
        id: top
        width: parent.width
        spacing: 8
        UiButton { icon: Settings.notifDnd ? "bellSleep" : "bell"; text: Settings.notifDnd ? "Não perturbe ligado" : "Não perturbe"; checked: Settings.notifDnd; onClicked: Settings.notifDnd = !Settings.notifDnd }
        UiButton { icon: "broom"; text: "Limpar tudo"; kind: "ghost"; onClicked: { NotifHistory.clear(); Actions.run("notifClear") } }
        UiText { anchors.verticalCenter: parent.verticalCenter; visible: NotifHistory.items.length > 0; text: NotifHistory.items.length + (NotifHistory.items.length === 1 ? " notificação" : " notificações"); color: Theme.muted; font.pixelSize: 12 }
    }
    HomeScroll {
        anchors { top: top.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom }
        spacing: 8
        UiText { visible: NotifHistory.items.length === 0; text: "Nenhuma notificação por enquanto."; color: Theme.muted; font.pixelSize: 13; topPadding: 20 }
        Repeater {
            model: pg.groups
            delegate: Column {
                id: grp
                required property var modelData
                readonly property bool opened: !!pg.open[modelData.app]
                readonly property var shownItems: opened ? modelData.items : modelData.items.slice(0, 1)
                width: parent.width
                spacing: 6
                Row {
                    visible: grp.modelData.items.length > 1
                    width: parent.width
                    spacing: 6
                    UiText { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60; text: (grp.modelData.app || "Aviso") + "  ·  " + grp.modelData.items.length; color: Theme.muted; font.pixelSize: 12; font.weight: Font.Medium; elide: Text.ElideRight }
                    UiButton { icon: grp.opened ? "chevUp" : "chevDown"; kind: "ghost"; onClicked: pg.toggle(grp.modelData.app) }
                    UiButton { icon: "close"; kind: "ghost"; onClicked: NotifHistory.removeApp(grp.modelData.app) }
                }
                Repeater {
                    model: grp.shownItems
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property var acts: modelData.ref ? Array.from(modelData.ref.actions).filter(a => a.identifier !== "default") : []
                        width: grp.width; height: Math.max(62, col.implicitHeight + 20 + (acts.length > 0 ? 36 : 0)); radius: 12
                        color: nm.containsMouse ? Theme.cardHi : Theme.glc(Theme.card, 1.15)
                        border.width: 1; border.color: Theme.border
                        MouseArea {
                            id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: m => {
                                if (m.button === Qt.RightButton) { if (grp.modelData.items.length > 1) pg.toggle(grp.modelData.app) }
                                else NotifHistory.remove(card.modelData.id)
                            }
                        }
                        Rectangle {
                            id: ib
                            x: 12; y: 12
                            width: 38; height: 38; radius: 10; clip: true
                            color: Theme.tint(0.16)
                            Image {
                                anchors.fill: parent; anchors.margins: card.modelData.image ? 0 : 6
                                source: card.modelData.image ? card.modelData.image : Icons.path(card.modelData.icon, "dialog-information")
                                fillMode: card.modelData.image ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                sourceSize: Qt.size(76, 76); asynchronous: true
                            }
                        }
                        Column {
                            id: col
                            anchors { left: ib.right; leftMargin: 12; right: parent.right; rightMargin: 12; top: parent.top; topMargin: 10 }
                            spacing: 2
                            Row {
                                width: parent.width
                                UiText { width: parent.width - when.width; text: card.modelData.app; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
                                UiText { id: when; text: NotifHistory.ago(card.modelData.time); color: Theme.muted; font.pixelSize: 11 }
                            }
                            UiText { width: parent.width; text: card.modelData.summary; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            UiText {
                                visible: text !== ""; width: parent.width
                                text: NotifHistory.body(card.modelData.body, card.modelData.app, false)
                                textFormat: Text.RichText; linkColor: Theme.accent
                                color: Theme.muted; font.pixelSize: 12; wrapMode: Text.Wrap
                                maximumLineCount: grp.opened ? 12 : 4; elide: Text.ElideRight
                                onLinkActivated: link => Qt.openUrlExternally(link)
                            }
                        }
                        Row {
                            visible: card.acts.length > 0
                            anchors { left: ib.right; leftMargin: 12; bottom: parent.bottom; bottomMargin: 8 }
                            spacing: 6
                            Repeater {
                                model: card.acts
                                delegate: UiButton {
                                    required property var modelData
                                    text: modelData.text; kind: "ghost"
                                    onClicked: { modelData.invoke(); card.modelData.ref.dismiss() }
                                }
                            }
                            UiButton { icon: "copy"; kind: "ghost"; onClicked: Quickshell.clipboardText = String(card.modelData.body).replace(/<[^>]*>/g, "") }
                        }
                    }
                }
            }
        }
    }
}
