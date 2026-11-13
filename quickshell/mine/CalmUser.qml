// Usuario, composicao "Sereno" (a padrao): foto, saudacao e nome alinhados a esquerda; a hora ao lado nos largos e
// os atalhos (bloquear, configuracoes, energia) como botoes discretos nos altos. Sem aro colorido nem botao cheio.
// host = o DwUser (textos, cores e opcoes vem dele).
import Quickshell
import QtQuick

Item {
    id: c
    property Item host
    readonly property bool tall: host.rows > 1
    readonly property bool tiny: host.cols === 1 && host.rows === 1
    readonly property real u: Math.max(0.72, Math.min(1.25, height / (tall ? 278 : 114)))
    SystemClock { id: clk; precision: SystemClock.Minutes }

    component Face: ShapedImage {
        shape: host.o("avatarShape"); sides: 10
        source: Profile.face; sourceSize: Qt.size(256, 256)
    }
    component Line: Row {
        property string icon: ""
        property string text: ""
        visible: text !== ""
        spacing: 6 * c.u
        UiIcon { visible: parent.icon !== ""; anchors.verticalCenter: parent.verticalCenter; name: parent.icon; size: Math.round(13 * c.u); color: host.dim }
        UiText { anchors.verticalCenter: parent.verticalCenter; text: parent.text; color: host.dim; font.pixelSize: Math.round(12 * c.u); font.features: { "tnum": 1 } }
    }
    component Who: Column {
        spacing: 2 * c.u
        UiText { visible: host.o("greeting"); text: host.greet + ","; color: host.dim; font.pixelSize: Math.round(13 * c.u) }
        UiText { width: parent.width; elide: Text.ElideRight; text: Profile.name; color: host.fg; font.family: Theme.fontTitle; font.pixelSize: Math.round((c.tall ? 26 : 22) * c.u); font.weight: Font.DemiBold }
        Item { width: 1; height: 2 * c.u }
        Line { icon: host.infoIcon; text: host.statsOn ? "" : host.infoText }
    }

    // so a foto
    Face { visible: c.tiny; anchors.centerIn: parent; width: Math.min(parent.width, parent.height); height: width }

    // deitado: foto, nome e (nos largos) a hora
    Item {
        visible: !c.tall && !c.tiny
        anchors.fill: parent
        Face { id: f1; anchors.verticalCenter: parent.verticalCenter; width: Math.min(parent.height, 96 * c.u); height: width }
        Who { anchors { left: f1.right; leftMargin: 16 * c.u; right: clock.visible ? clock.left : parent.right; rightMargin: 8 * c.u; verticalCenter: parent.verticalCenter } }
        Column {
            id: clock
            visible: host.cols >= 3
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            UiText { anchors.right: parent.right; text: Qt.formatDateTime(clk.date, "HH:mm"); color: host.fg; font.family: Theme.fontTitle; font.pixelSize: Math.round(34 * c.u); font.weight: Font.Medium; font.features: { "tnum": 1 } }
            UiText { anchors.right: parent.right; text: host.dateText.replace("Hoje • ", ""); color: host.dim; font.pixelSize: Math.round(12 * c.u) }
        }
    }

    // em pe: foto em cima, textos e atalhos embaixo
    Item {
        visible: c.tall
        anchors.fill: parent
        Face { id: f2; width: Math.min(parent.width, Math.round((host.rows > 2 ? 96 : 72) * c.u)); height: width }
        Column {
            anchors { left: parent.left; right: parent.right; top: f2.bottom; topMargin: 14 * c.u }
            spacing: 6 * c.u
            Who { width: parent.width }
            Line { visible: host.quip !== ""; icon: host.quipIcon; text: host.quipNow || host.quip }
            // tempo ligado em dias / horas / minutos (so nos mais altos)
            Row {
                visible: host.statsOn
                topPadding: 6 * c.u
                spacing: 18 * c.u
                Repeater {
                    model: [[host.upD, "dias"], [host.upH, "horas"], [host.upM, "min"]]
                    delegate: Column {
                        required property var modelData
                        UiText { text: String(modelData[0]); color: host.fg; font.family: Theme.fontTitle; font.pixelSize: Math.round(24 * c.u); font.weight: Font.Medium; font.features: { "tnum": 1 } }
                        UiText { text: modelData[1]; color: host.dim; font.pixelSize: Math.round(11 * c.u) }
                    }
                }
            }
        }
        Row {
            visible: host.btnOn
            anchors { left: parent.left; leftMargin: -2 * c.u; bottom: parent.bottom }
            spacing: 6 * c.u
            Repeater {
                model: [["lock", "Bloquear"], ["cog", ""], ["power", ""]]
                delegate: Rectangle {
                    id: b
                    required property var modelData
                    required property int index
                    height: Math.round(32 * c.u); width: modelData[1] !== "" ? br.implicitWidth + 24 * c.u : height; radius: height / 2
                    color: Qt.rgba(host.fg.r, host.fg.g, host.fg.b, bm.containsMouse ? 0.18 : 0.09)
                    scale: bm.pressed ? 0.96 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        id: br
                        anchors.centerIn: parent
                        spacing: 6 * c.u
                        UiIcon { anchors.verticalCenter: parent.verticalCenter; name: b.modelData[0]; size: Math.round(15 * c.u); color: host.fg }
                        UiText { visible: b.modelData[1] !== ""; anchors.verticalCenter: parent.verticalCenter; text: b.modelData[1]; color: host.fg; font.pixelSize: Math.round(13 * c.u); font.weight: Font.Medium }
                    }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.index === 0 ? host.lockIt() : b.index === 1 ? host.cogIt() : host.powerIt() }
                }
            }
        }
    }
}
