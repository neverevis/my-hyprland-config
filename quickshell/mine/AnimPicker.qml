// Escolhe qual animacao nomeada usar num lugar (target: bars | picker | wallpaper | workspaces).
import QtQuick

Flow {
    id: root
    property string target
    width: parent ? parent.width : 300
    spacing: 6

    Repeater {
        model: Settings.allAnims()
        delegate: UiButton {
            required property var modelData
            text: modelData.name
            checked: (Settings.animUse[root.target] ?? Settings.animDefaults[root.target]) === modelData.name
            onClicked: Settings.setUse(root.target, modelData.name)
        }
    }
}
