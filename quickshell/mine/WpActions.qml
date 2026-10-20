// Acoes sobre o wallpaper em foco no seletor: mover para a lixeira (com confirmacao) e, na ordem manual, mover para tras/frente.
// Coloque dentro do cartao (anchors.fill); "shown" liga os botoes (cartao em foco ou com o mouse em cima).
import QtQuick

Item {
    id: a
    property string path: ""
    property bool shown: false
    property real radius: 14
    readonly property bool asking: Wallpaper.delPath === a.path && a.path !== ""
    readonly property bool manual: Settings.wpSort === "manual"

    Row {
        visible: a.shown && !a.asking
        anchors { left: parent.left; top: parent.top; margins: 6 }
        spacing: 4
        Repeater {
            model: a.manual ? [["arrowLeft", -1], ["arrowRight", 1], ["trash", 0]] : [["trash", 0]]
            delegate: Rectangle {
                required property var modelData
                width: 24; height: 24; radius: 12
                color: ma.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.55)
                UiIcon { anchors.centerIn: parent; name: parent.modelData[0]; size: 14; color: parent.modelData[1] === 0 && ma.containsMouse ? Theme.danger : "white" }
                MouseArea {
                    id: ma
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (parent.modelData[1] === 0) Wallpaper.delPath = a.path; else Wallpaper.moveFile(a.path, parent.modelData[1]) }
                }
            }
        }
    }
    Rectangle {
        visible: a.asking
        anchors.fill: parent; radius: a.radius
        color: Qt.rgba(0, 0, 0, 0.82)
        MouseArea { anchors.fill: parent }
        Column {
            anchors.centerIn: parent
            spacing: 8
            UiText { anchors.horizontalCenter: parent.horizontalCenter; text: Wallpaper.trashErr !== "" ? Wallpaper.trashErr : "Mover para a lixeira?"; color: "white"; font.pixelSize: 12; font.weight: Font.DemiBold }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                UiButton { text: "Cancelar"; onClicked: Wallpaper.delPath = "" }
                UiButton { text: "Excluir"; kind: "danger"; onClicked: { const p = Wallpaper.delPath; Wallpaper.delPath = ""; Wallpaper.trash(p) } }
            }
        }
    }
}
