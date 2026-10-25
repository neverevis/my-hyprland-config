// Parte de baixo de uma SetRow com CmdField: aviso de programa nao encontrado e a lista de apps instalados (busca + clique).
import Quickshell
import QtQuick

Column {
    id: root
    required property var f              // o CmdField da mesma linha
    width: parent ? parent.width : 400
    spacing: SetK.sm
    bottomPadding: root.f.missing !== "" || root.f.picking ? SetK.sm : 0
    UiText {
        visible: root.f.missing !== ""
        width: parent.width; wrapMode: Text.WordWrap
        text: "Programa não encontrado: " + root.f.missing
        color: Theme.danger; font.pixelSize: SetK.fDesc
    }
    Column {
        id: pick
        visible: root.f.picking
        width: parent.width
        spacing: SetK.sm
        UiField { id: q; width: parent.width; placeholderText: "Buscar entre os apps instalados…"; onVisibleChanged: if (!visible) text = "" }
        Rectangle {
            width: parent.width; height: 208; radius: SetK.innerRadius; color: Theme.track; clip: true
            ListView {
                id: lv
                anchors.fill: parent; anchors.margins: SetK.xs
                clip: true; boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                model: pick.visible ? root.list(q.text) : []
                delegate: Rectangle {
                    required property var modelData
                    width: lv.width; height: 36; radius: 8
                    color: ma.containsMouse ? Theme.cardHi : "transparent"
                    Row {
                        anchors { left: parent.left; leftMargin: SetK.sm; right: parent.right; rightMargin: SetK.sm; verticalCenter: parent.verticalCenter }
                        spacing: SetK.sm
                        Image { width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter; source: modelData.icon; sourceSize: Qt.size(44, 44); asynchronous: true; fillMode: Image.PreserveAspectFit }
                        UiText { width: parent.width - 30; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: modelData.name; color: Theme.text; font.pixelSize: 13 }
                    }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.f.setCommand(modelData.cmd) }
                }
                UiText { visible: lv.count === 0; anchors.centerIn: parent; text: "Nenhum app encontrado"; color: Theme.muted; font.pixelSize: SetK.fDesc }
            }
        }
    }
    // apps instalados (mesma fonte do launcher); exec sem codigos de campo (%u %U %f %F...)
    function list(term) {
        const t = term.trim().toLowerCase(), out = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            const n = e.name ?? ""
            if (t !== "" && n.toLowerCase().indexOf(t) < 0 && (e.genericName ?? "").toLowerCase().indexOf(t) < 0) continue
            const cmd = Array.from(e.command ?? []).map(a => /[\s"'\\$]/.test(a) ? "'" + a.replace(/'/g, "'\\''") + "'" : a).join(" ").replace(/%[A-Za-z%]/g, "").replace(/\s+/g, " ").trim()
            if (cmd === "") continue
            out.push({ name: n, cmd: (e.runInTerminal ? "kitty -e " : "") + cmd, icon: Icons.path(e.icon, "application-x-executable") })
        }
        out.sort((a, b) => a.name.localeCompare(b.name))
        return out
    }
}
