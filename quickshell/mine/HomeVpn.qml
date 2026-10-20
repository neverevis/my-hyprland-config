// Aba "VPN": perfis do NetworkManager (vpn e wireguard): conectar, trocar, apagar (com confirmacao) e importar .conf / .ovpn.
import QtQuick

HomeScroll {
    id: pg
    property var home
    property string confirmDel: ""   // uuid esperando a confirmacao

    Component.onCompleted: Vpn.refresh()
    Timer { interval: 4000; repeat: true; running: true; onTriggered: Vpn.refresh() }

    HomeCard {
        width: pg.width
        height: 96
        title: "VPN"; icon: "shieldLock"
        Row {
            spacing: 12
            Rectangle {
                id: bi
                width: 40; height: 40; radius: 12
                color: Vpn.connected ? Theme.accent : Theme.track
                UiIcon { anchors.centerIn: parent; name: Vpn.connected ? "shieldLock" : "shield"; size: 20; color: Vpn.connected ? Theme.accentText : Theme.muted }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                UiText { text: Vpn.connected ? "Conectado" : (Vpn.has ? "Desconectado" : "Nenhum perfil"); color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                UiText { text: Vpn.connected ? Vpn.activeProfile.name : (Vpn.has ? "Escolha um perfil abaixo" : "Importe um arquivo .conf (WireGuard) ou .ovpn (OpenVPN)"); color: Theme.muted; font.pixelSize: 12 }
            }
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 6
            UiButton { visible: Vpn.has; icon: Vpn.connected ? "close" : "play"; text: Vpn.connected ? "Desligar" : "Ligar"; kind: Vpn.connected ? "ghost" : "accent"; enabled: !Vpn.busy; onClicked: Vpn.toggle() }
        }
    }

    HomeCard {
        width: pg.width
        height: list.implicitHeight + 94
        title: "Perfis"; icon: "vpn"
        headerRight: [UiButton { icon: "download"; text: "Importar"; kind: "ghost"; onClicked: Vpn.pickAndImport() }]
        Column {
            id: list
            width: parent.width
            spacing: 6
            UiText { visible: !Vpn.has; text: "Nenhum perfil de VPN no NetworkManager."; color: Theme.muted; font.pixelSize: 13; height: 24; verticalAlignment: Text.AlignVCenter }
            Rectangle {   // barra de ocupado
                visible: Vpn.busy
                width: parent.width; height: 3; radius: 2; color: Theme.track
                Rectangle { id: bar; width: parent.width * 0.3; height: 3; radius: 2; color: Theme.accent
                    SequentialAnimation on x { running: Vpn.busy; loops: Animation.Infinite
                        NumberAnimation { from: 0; to: list.width * 0.7; duration: 700; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: list.width * 0.7; to: 0; duration: 700; easing.type: Easing.InOutQuad } } }
            }
            Repeater {
                model: Vpn.profiles
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    readonly property bool on: Vpn.activeUuids.indexOf(modelData.uuid) >= 0
                    readonly property bool asking: pg.confirmDel === modelData.uuid
                    width: list.width; height: 46; radius: 12
                    color: on ? Theme.tint(0.16) : (rm.containsMouse ? Theme.cardHi : "transparent")
                    UiIcon { id: ri; anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } name: row.on ? "shieldLock" : "shield"; size: 18; color: row.on ? Theme.accent : Theme.muted }
                    Column {
                        anchors { left: ri.right; leftMargin: 12; right: acts.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        UiText { width: parent.width; text: row.modelData.name; color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight }
                        UiText { text: (row.modelData.type === "wireguard" ? "WireGuard" : "OpenVPN") + (row.on ? " · conectado" : ""); color: Theme.muted; font.pixelSize: 11 }
                    }
                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !row.asking; onClicked: Vpn.connectTo(row.modelData.uuid) }
                    Row {
                        id: acts
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        spacing: 4
                        UiText { visible: row.asking; anchors.verticalCenter: parent.verticalCenter; text: "Apagar?"; color: Theme.danger; font.pixelSize: 12 }
                        UiButton { visible: row.asking; icon: "check"; kind: "danger"; onClicked: { pg.confirmDel = ""; Vpn.remove(row.modelData.uuid) } }
                        UiButton { visible: row.asking; icon: "close"; kind: "ghost"; onClicked: pg.confirmDel = "" }
                        UiButton { visible: !row.asking; icon: "trash"; kind: "ghost"; onClicked: pg.confirmDel = row.modelData.uuid }
                    }
                }
            }
        }
    }
}
