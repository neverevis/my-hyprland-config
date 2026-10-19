// Aba "Conexao": conexao atual (cabo ou Wi-Fi) e redes Wi-Fi ao alcance (conectar, senha, desconectar).
import Quickshell.Networking
import QtQuick

HomeScroll {
    id: pg
    property var home
    property var askFor: null      // rede protegida esperando a senha
    readonly property var wired: home.wiredDev
    readonly property var wifi: home.wifiDev
    readonly property var nets: home.wifiNets.slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    Component.onCompleted: if (wifi && Networking.wifiEnabled) wifi.scannerEnabled = true
    Component.onDestruction: if (wifi) wifi.scannerEnabled = false

    function sigIcon(s) { return s > 0.75 ? "wifi4" : (s > 0.5 ? "wifi3" : (s > 0.25 ? "wifi2" : "wifi1")) }

    // ---- conexao atual ----
    HomeCard {
        id: cur
        width: pg.width; height: 104
        title: "Conexão atual"; icon: "link"
        readonly property bool viaWired: !!pg.wired && pg.wired.connected
        readonly property var dev: viaWired ? pg.wired : (pg.home.wifiCur ? pg.wifi : null)
        Rectangle {
            id: ci
            width: 40; height: 40; radius: 12
            color: cur.dev ? Theme.accent : Theme.track
            UiIcon { anchors.centerIn: parent; name: cur.viaWired ? "ethernet" : (cur.dev ? "wifi" : "wifiOff"); size: 20; color: cur.dev ? Theme.accentText : Theme.muted }
        }
        Column {
            anchors { left: ci.right; leftMargin: 12; verticalCenter: ci.verticalCenter }
            spacing: 2
            UiText {
                text: !cur.dev ? "Sem conexão" : (cur.viaWired ? "Cabo · " + cur.dev.name : pg.home.wifiCur.name)
                color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold
            }
            UiText {
                text: !cur.dev ? "Conecte um cabo ou escolha uma rede abaixo" : ((pg.home.ips[cur.dev.name] ?? "sem IP") + (cur.viaWired && cur.dev.linkSpeed ? " · " + cur.dev.linkSpeed + " Mb/s" : "") + (!cur.viaWired && pg.home.wifiCur ? " · sinal " + Math.round(pg.home.wifiCur.signalStrength * 100) + "%" : ""))
                color: Theme.muted; font.pixelSize: 12
            }
        }
    }

    // ---- Wi-Fi ----
    HomeCard {
        width: pg.width
        height: wcol.implicitHeight + 52
        title: "Wi-Fi"; icon: "wifi"
        headerRight: [
            UiButton {
                visible: !!pg.wifi && Networking.wifiEnabled
                icon: "refresh"; kind: "ghost"
                onClicked: { pg.wifi.scannerEnabled = false; pg.wifi.scannerEnabled = true }
            },
            UiSwitch {
                width: 50
                visible: !!pg.wifi
                checked: Networking.wifiEnabled
                onToggled: on => Networking.wifiEnabled = on
            }
        ]
        Column {
            id: wcol
            width: parent.width
            spacing: 4
            UiText {
                visible: !pg.wifi || !Networking.wifiEnabled || pg.nets.length === 0
                height: 30; verticalAlignment: Text.AlignVCenter
                text: !pg.wifi ? "Nenhuma placa Wi-Fi neste computador." : (!Networking.wifiEnabled ? "O Wi-Fi está desligado." : "Procurando redes…")
                color: Theme.muted; font.pixelSize: 13
            }
            Repeater {
                model: pg.wifi && Networking.wifiEnabled ? pg.nets : []
                delegate: Column {
                    id: nr
                    required property var modelData
                    readonly property bool secure: modelData.security !== WifiSecurityType.Open
                    readonly property bool asking: pg.askFor === modelData
                    width: wcol.width
                    spacing: 6
                    Rectangle {
                        width: parent.width; height: 42; radius: 10
                        color: nr.modelData.connected ? Theme.tint(0.16) : (nm.containsMouse ? Theme.cardHi : "transparent")
                        UiIcon { id: si; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } name: pg.sigIcon(nr.modelData.signalStrength); size: 18; color: nr.modelData.connected ? Theme.accent : Theme.text }
                        Column {
                            anchors { left: si.right; leftMargin: 10; right: act.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            UiText { width: parent.width; text: nr.modelData.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight }
                            UiText {
                                width: parent.width
                                text: (nr.modelData.connected ? "Conectado" : (nr.modelData.stateChanging ? "Conectando…" : (nr.modelData.known ? "Salva" : (nr.secure ? "Protegida" : "Aberta")))) + " · " + Math.round(nr.modelData.signalStrength * 100) + "%"
                                color: Theme.muted; font.pixelSize: 11
                            }
                        }
                        UiIcon { visible: nr.secure; anchors { right: act.left; rightMargin: 8; verticalCenter: parent.verticalCenter } name: "lock"; size: 13; color: Theme.muted }
                        MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true }
                        UiButton {
                            id: act
                            anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter }
                            text: nr.modelData.connected ? "Desconectar" : "Conectar"
                            kind: nr.modelData.connected ? "normal" : "accent"
                            onClicked: {
                                if (nr.modelData.connected) nr.modelData.disconnect()
                                else if (nr.modelData.known || !nr.secure) nr.modelData.connect()
                                else pg.askFor = nr.asking ? null : nr.modelData
                            }
                        }
                    }
                    Row {
                        visible: nr.asking
                        spacing: 6
                        leftPadding: 38
                        UiField {
                            id: pw
                            width: wcol.width - 38 - 6 - okBtn.width
                            echoMode: TextInput.Password
                            placeholderText: "Senha de " + nr.modelData.name
                            onVisibleChanged: if (visible) forceActiveFocus()
                            onAccepted: okBtn.clicked()
                        }
                        UiButton { id: okBtn; icon: "check"; kind: "accent"; onClicked: { nr.modelData.connectWithPsk(pw.text); pw.text = ""; pg.askFor = null } }
                    }
                }
            }
        }
    }
}
