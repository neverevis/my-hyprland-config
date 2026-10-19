// Escolha do tom de cor (widgets e outras partes): bolinhas com as cores reais do tema agora.
// Valores: global (segue o padrao da pagina Widgets), auto (pelo brilho do wallpaper), primary / secondary / tertiary
// (familias da paleta: cor, versao suave e texto sobre ela), neutral (so o texto do tema), custom (cor escolhida).
import QtQuick

Column {
    id: ts
    property string label: "Cor"
    property string value: "auto"
    property bool allowGlobal: false
    property color custom: "#ffffff"
    signal picked(string v)
    spacing: 6

    readonly property var opts: (allowGlobal ? [["global", "Padrão"]] : []).concat([
        ["auto", "Automática"], ["primary", "Destaque"], ["secondary", "Secundária"], ["tertiary", "Terciária"], ["neutral", "Neutra"], ["custom", "Minha cor"]])

    UiText { visible: ts.label !== ""; text: ts.label; color: Theme.text; font.pixelSize: 13 }
    Flow {
        width: ts.width
        spacing: 6
        Repeater {
            model: ts.opts
            delegate: Item {
                id: sw
                required property var modelData
                readonly property string v: modelData[0]
                readonly property bool on: ts.value === v
                readonly property var fam: Theme.family(v)
                width: 62; height: 58
                // bolinha: metade com a cor principal, metade com a versao suave (o fundo do cartao nesse tom)
                Item {
                    id: dot
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 2
                    width: 32; height: 32
                    Rectangle { anchors.fill: parent; anchors.margins: -3; radius: width / 2; color: "transparent"; border.width: 2; border.color: sw.on ? Theme.accent : (sm.containsMouse ? Theme.border : "transparent") }
                    Rectangle {
                        anchors.fill: parent; radius: width / 2; clip: true
                        color: sw.v === "auto" ? "#f4f0f7" : sw.v === "neutral" ? Theme.card : sw.v === "custom" ? ts.custom : sw.v === "global" ? Theme.card : sw.fam.cont
                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)
                        Rectangle {
                            visible: sw.v !== "custom"
                            width: parent.width / 2; height: parent.height; x: parent.width / 2
                            color: sw.v === "auto" ? "#1b1a21" : sw.v === "neutral" ? Theme.text : sw.v === "global" ? Theme.card : sw.fam.main
                        }
                        UiIcon { visible: sw.v === "global"; anchors.centerIn: parent; name: "link"; size: 15; color: Theme.muted }
                    }
                }
                UiText {
                    anchors { horizontalCenter: parent.horizontalCenter; top: dot.bottom; topMargin: 5 }
                    text: sw.modelData[1]; color: sw.on ? Theme.text : Theme.muted
                    font.pixelSize: 11; font.weight: sw.on ? Font.DemiBold : Font.Normal
                }
                MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ts.picked(sw.v) }
            }
        }
    }
}
