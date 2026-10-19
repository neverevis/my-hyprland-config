// Aba "Bluetooth": ligar/desligar, dispositivos pareados (conectar/desconectar) e busca de novos (parear).
import QtQuick

HomeScroll {
    id: pg
    property var home
    readonly property var bt: home.bt
    readonly property var paired: home.btDevs.filter(d => d.paired || d.bonded).sort((a, b) => b.connected - a.connected)
    readonly property var found: home.btDevs.filter(d => !d.paired && !d.bonded && d.name)

    Component.onDestruction: if (bt && bt.discovering) bt.discovering = false

    function devIcon(i) {
        i = i || ""
        return i.indexOf("audio") >= 0 || i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0 ? "headphones"
            : i.indexOf("input-mouse") >= 0 ? "mouse" : i.indexOf("input-keyboard") >= 0 ? "keyboard"
            : i.indexOf("phone") >= 0 ? "cellphone" : i.indexOf("gaming") >= 0 ? "gamepad" : "bluetooth"
    }

    component DevRow: Rectangle {
        id: dr
        property var dev
        property string action
        signal act()
        width: parent ? parent.width : 100; height: 44; radius: 10
        color: dev && dev.connected ? Theme.tint(0.16) : (dm.containsMouse ? Theme.cardHi : "transparent")
        UiIcon { id: di; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } name: pg.devIcon(dr.dev ? dr.dev.icon : ""); size: 18; color: dr.dev && dr.dev.connected ? Theme.accent : Theme.text }
        Column {
            anchors { left: di.right; leftMargin: 10; right: ab.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            UiText { width: parent.width; text: dr.dev ? (dr.dev.name || dr.dev.address) : ""; color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight }
            UiText {
                width: parent.width
                text: !dr.dev ? "" : (dr.dev.pairing ? "Pareando…" : (dr.dev.connected ? "Conectado" : (dr.dev.paired ? "Pareado" : dr.dev.address)))
                    + (dr.dev && dr.dev.batteryAvailable ? " · bateria " + Math.round(dr.dev.battery * 100) + "%" : "")
                color: Theme.muted; font.pixelSize: 11
            }
        }
        MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true }
        UiButton { id: ab; anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter } text: dr.action; kind: dr.dev && dr.dev.connected ? "normal" : "accent"; onClicked: dr.act() }
    }

    HomeCard {
        width: pg.width
        height: pcol.implicitHeight + 52
        title: "Dispositivos"; icon: "bluetooth"
        headerRight: [
            UiSwitch {
                width: 50
                visible: !!pg.bt
                checked: !!pg.bt && pg.bt.enabled
                onToggled: on => pg.bt.enabled = on
            }
        ]
        Column {
            id: pcol
            width: parent.width
            spacing: 4
            UiText {
                visible: !pg.bt || !pg.bt.enabled || pg.paired.length === 0
                width: parent.width; wrapMode: Text.WordWrap
                topPadding: 6; bottomPadding: 6
                text: !pg.bt ? "Nenhum adaptador Bluetooth disponível. Se o computador tiver um, ative o serviço: systemctl enable --now bluetooth" : (!pg.bt.enabled ? "O Bluetooth está desligado." : "Nenhum dispositivo pareado.")
                color: Theme.muted; font.pixelSize: 13
            }
            Repeater {
                model: pg.bt && pg.bt.enabled ? pg.paired : []
                delegate: DevRow {
                    required property var modelData
                    dev: modelData
                    action: modelData.connected ? "Desconectar" : "Conectar"
                    onAct: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
        }
    }

    HomeCard {
        visible: !!pg.bt && pg.bt.enabled
        width: pg.width
        height: fcol.implicitHeight + 52
        title: "Procurar novos"; icon: "devices"
        headerRight: [
            UiButton {
                icon: pg.bt && pg.bt.discovering ? "close" : "magic"
                text: pg.bt && pg.bt.discovering ? "Parar" : "Procurar"
                kind: pg.bt && pg.bt.discovering ? "normal" : "accent"
                onClicked: pg.bt.discovering = !pg.bt.discovering
            }
        ]
        Column {
            id: fcol
            width: parent.width
            spacing: 4
            UiText {
                visible: pg.found.length === 0
                height: 30; verticalAlignment: Text.AlignVCenter
                text: pg.bt && pg.bt.discovering ? "Procurando dispositivos por perto…" : "Clique em Procurar para achar dispositivos novos."
                color: Theme.muted; font.pixelSize: 13
            }
            Repeater {
                model: pg.found
                delegate: DevRow {
                    required property var modelData
                    dev: modelData
                    action: "Parear"
                    onAct: { modelData.trusted = true; modelData.pair() }
                }
            }
        }
    }
}
