// SetSoon: pagina de um recurso que ainda vai chegar ("em breve"): icone numa flor, o que vai ter e atalhos para
// o que ja existe em outras paginas (links = [[rotulo, icone, pagina, secao], ...]; a secao rola ate o cartao).
import QtQuick

SetPage {
    id: sp
    property string icon: "progressClock"
    property var plans: []
    property var links: []

    SetSection {
        boxed: false
        Item {
            width: parent.width
            height: col.implicitHeight + SetK.xxl * 2
            Column {
                id: col
                anchors.centerIn: parent
                width: Math.min(parent.width, 420)
                spacing: SetK.md
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 96; height: 96
                    Flower { anchors.fill: parent; shape: "flower"; sides: 9; depth: 0.12; color: Theme.tint(0.16); animated: false }
                    UiIcon { anchors.centerIn: parent; name: sp.icon; size: 38; color: Theme.accent }
                }
                UiText { anchors.horizontalCenter: parent.horizontalCenter; text: "Em breve"; color: Theme.text; font.pixelSize: 18; font.weight: Font.Bold; topPadding: SetK.sm }
                UiText {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    text: sp.plans.join("  ·  "); color: Theme.muted; font.pixelSize: 13
                }
            }
        }
    }
    SetSection {
        visible: sp.links.length > 0
        title: "Por enquanto"
        icon: "link"
        Repeater {
            model: sp.links
            delegate: SetRow {
                required property var modelData
                icon: modelData[1]
                label: modelData[0]
                link: true
                onClicked: { Settings.settingsReveal = modelData[3] ?? ""; Settings.settingsPage = modelData[2] }
            }
        }
    }
}
