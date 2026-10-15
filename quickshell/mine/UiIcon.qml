// Icone da fonte (veja Ico.qml para os nomes).
import QtQuick

Text {
    property string name
    property int size: 18
    text: Ico.g(name)
    color: Theme.text
    font.family: Ico.family
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
