// SetColor: linha com uma fileira de amostras de cor no fim.
// - mode "role" (padrao): value = id de um papel do tema (ThemeColors.roles); roles escolhe quais; allowNone poe "nenhuma" ("").
// - mode "hex": value = cor; as amostras sao as cores atuais do tema (atalho) e a ultima abre o seletor livre abaixo.
// A descricao mostra o nome da amostra sob o mouse ou a escolhida (note: texto fixo no lugar do nome). picked(v).
// Exemplo:  SetColor { icon: "swatch"; label: "Cor do fundo"; value: Settings.wpBgRole; onPicked: v => Settings.wpBgRole = v }
import QtQuick

SetRow {
    id: sc
    property string mode: "role"
    property var value
    property var roles: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "surfaceHigh", "outline", "text"]
    property bool allowNone: false
    property string note: ""
    property bool picking: false
    property string hoverName: ""
    signal picked(var v)

    function roleName(id) { if (id === "") return "Nenhuma"; const r = ThemeColors.roles.find(x => x.id === id || (id === "bg" && x.id === "background")); return r ? r.label : id }
    readonly property string valueName: mode === "role" ? roleName(String(value ?? "")) : String(value ?? "")
    description: hoverName !== "" ? hoverName : (note !== "" ? note : valueName)

    Row {
        spacing: 6
        Repeater {
            model: (sc.mode === "role" && sc.allowNone ? [""] : []).concat(sc.roles)
            delegate: Item {
                id: sw
                required property string modelData
                readonly property color col: modelData === "" ? "transparent" : ThemeColors.of(modelData)
                readonly property bool sel: sc.mode === "role" ? String(sc.value) === modelData : (Qt.colorEqual(sc.value, col) && !sc.picking)
                width: 28; height: 28
                Rectangle { anchors.fill: parent; radius: 14; color: "transparent"; border.width: 2; border.color: Theme.accent; visible: sw.sel }
                Rectangle {
                    anchors.centerIn: parent
                    width: sw.sel ? 20 : 22; height: width; radius: width / 2
                    color: sw.col
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.18)
                    Behavior on width { NumberAnimation { duration: SetK.fast } }
                    // "nenhuma": um risco
                    Rectangle { visible: sw.modelData === ""; anchors.centerIn: parent; width: parent.width - 4; height: 2; rotation: -45; color: Theme.muted }
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: sc.hoverName = sc.roleName(sw.modelData)
                    onExited: if (sc.hoverName === sc.roleName(sw.modelData)) sc.hoverName = ""
                    onClicked: { sc.picking = false; sc.picked(sc.mode === "role" ? sw.modelData : sw.col.toString()) }
                }
            }
        }
        // cor livre (so no modo hex): mostra a cor atual; abre o seletor
        Item {
            visible: sc.mode === "hex"
            width: 28; height: 28
            Rectangle { anchors.fill: parent; radius: 9; color: "transparent"; border.width: 2; border.color: Theme.accent; visible: sc.picking }
            Rectangle {
                anchors.centerIn: parent; width: 22; height: 22; radius: 7
                color: sc.mode === "hex" ? sc.value : "transparent"
                border.width: 1; border.color: Theme.border
                UiIcon { anchors.centerIn: parent; name: "eyedropper"; size: 12; color: Theme.accentText; style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.4) }
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onEntered: sc.hoverName = "Cor livre"
                onExited: if (sc.hoverName === "Cor livre") sc.hoverName = ""
                onClicked: sc.picking = !sc.picking
            }
        }
    }

    below: Loader {
        width: parent ? parent.width : 300
        active: sc.picking
        visible: active
        sourceComponent: ColorPicker { value: sc.value; onPicked: col => sc.picked(col.toString()) }
    }
}
