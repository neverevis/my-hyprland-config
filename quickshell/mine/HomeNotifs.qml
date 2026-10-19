// Aba "Notificacoes" do Inicio: historico (NotifHistory), nao perturbe e limpar. Clique numa remove do historico.
import Quickshell
import QtQuick

Item {
    id: pg
    property var home
    Component.onCompleted: NotifHistory.unread = 0

    Row {
        id: top
        width: parent.width
        spacing: 8
        UiButton { icon: Settings.notifDnd ? "bellSleep" : "bell"; text: Settings.notifDnd ? "Não perturbe ligado" : "Não perturbe"; checked: Settings.notifDnd; onClicked: Settings.notifDnd = !Settings.notifDnd }
        UiButton { icon: "broom"; text: "Limpar tudo"; kind: "ghost"; onClicked: { NotifHistory.clear(); Actions.run("notifClear") } }
    }
    HomeScroll {
        anchors { top: top.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom }
        spacing: 6
        UiText { visible: NotifHistory.items.length === 0; text: "Nenhuma notificação por enquanto."; color: Theme.muted; font.pixelSize: 13; topPadding: 20 }
        Repeater {
            model: NotifHistory.items
            delegate: Rectangle {
                required property var modelData
                width: parent.width; height: Math.max(62, col.implicitHeight + 20); radius: 12
                color: nm.containsMouse ? Theme.cardHi : Theme.gl(Theme.card, 1.15)
                border.width: 1; border.color: Theme.border
                Rectangle {
                    id: ib
                    x: 12; anchors.verticalCenter: parent.verticalCenter
                    width: 38; height: 38; radius: 10; clip: true
                    color: Theme.tint(0.16)
                    Image {
                        anchors.fill: parent; anchors.margins: modelData.image ? 0 : 6
                        source: modelData.image ? modelData.image : Icons.path(modelData.icon, "dialog-information")
                        fillMode: modelData.image ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                        sourceSize: Qt.size(76, 76); asynchronous: true
                    }
                }
                Column {
                    id: col
                    anchors { left: ib.right; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 2
                    Row {
                        width: parent.width
                        UiText { width: parent.width - when.width; text: modelData.app; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
                        UiText { id: when; text: NotifHistory.ago(modelData.time); color: Theme.muted; font.pixelSize: 11 }
                    }
                    UiText { width: parent.width; text: modelData.summary; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    UiText { visible: text !== ""; width: parent.width; text: modelData.body; textFormat: Text.StyledText; color: Theme.muted; font.pixelSize: 12; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight }
                }
                MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: NotifHistory.remove(modelData.id) }
            }
        }
    }
}
