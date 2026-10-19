// Aba "Inicio" do painel: usuario e relogio, atalhos, midia, resumo do sistema e volumes.
import Quickshell
import Quickshell.Networking
import QtQuick

Item {
    id: pg
    property var home

    // ---------- usuario + relogio ----------
    Rectangle {
        id: userCard
        width: parent.width; height: 108; radius: 16
        color: Theme.gl(Theme.card, 1.15)
        border.width: 1; border.color: Theme.border
        RoundImage {
            x: 1; y: 1; width: parent.width - 2; height: parent.height - 2
            radius: 15
            source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
            sourceSize: Qt.size(640, 200)
            blur: 0.7
            dim: 0.48
        }
        Avatar {   // clique: trocar a foto de perfil
            id: avatar
            x: 17; anchors.verticalCenter: parent.verticalCenter
            size: 68
            editable: true
        }
        Column {
            anchors { left: avatar.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
            spacing: 3
            Text { text: Quickshell.env("USER"); color: "white"; font.pixelSize: 19; font.weight: Font.Bold }
            Text { text: Quickshell.env("USER") + "@" + (pg.home.st.host || "linux"); color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12 }
            Row {
                spacing: 5
                visible: !!pg.home.sys.uptime
                UiIcon { name: "clock"; size: 13; color: Qt.rgba(1, 1, 1, 0.75); anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Ativo há " + pg.home.dur(pg.home.sys.uptime); color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12 }
            }
        }
        SystemClock { id: clk; precision: SystemClock.Minutes }
        Column {
            anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
            spacing: 0
            Text { anchors.right: parent.right; text: Qt.formatDateTime(clk.date, "HH:mm"); color: "white"; font.pixelSize: 36; font.weight: Font.Bold }
            Text {
                anchors.right: parent.right
                text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
                color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12
            }
        }
    }

    // ---------- botoes rapidos (Settings.homeToggles; os de Wi-Fi, Bluetooth e energia sao daqui, os outros do Toggles.qml) ----------
    Grid {
        id: tiles
        anchors { top: userCard.bottom; topMargin: 10 }
        width: parent.width
        columns: 3; spacing: 8
        readonly property real tw: (width - 16) / 3
        Repeater {
            model: (Settings.homeToggles || []).filter(id => Toggles.find(id)).slice(0, 9)
            delegate: Loader {
                required property var modelData
                width: tiles.tw; height: 58
                sourceComponent: modelData === "wifi" ? wifiT : modelData === "bt" ? btT : modelData === "profile" ? profT : genT
                property string tid: modelData
            }
        }
    }
    Component {
        id: wifiT
        HomeTile {
            readonly property bool hasWifi: !!pg.home.wifiDev
            readonly property bool wired: !!pg.home.wiredDev && pg.home.wiredDev.connected
            icon: hasWifi ? (Networking.wifiEnabled ? "wifi" : "wifiOff") : (wired ? "ethernet" : "wifiOff")
            label: hasWifi ? "Wi-Fi" : "Rede"
            sub: hasWifi ? (!Networking.wifiEnabled ? "Desligado" : (pg.home.wifiCur ? pg.home.wifiCur.name : (wired ? "Cabo conectado" : "Ligado"))) : (wired ? "Cabo · " + pg.home.wiredDev.name : "Sem conexão")
            on: hasWifi ? Networking.wifiEnabled : wired
            more: true
            onClicked: { if (hasWifi) Networking.wifiEnabled = !Networking.wifiEnabled; else pg.home.tab = "net" }
            onMoreClicked: pg.home.tab = "net"
        }
    }
    Component {
        id: btT
        HomeTile {
            icon: pg.home.bt && pg.home.bt.enabled ? "bluetooth" : "btOff"
            label: "Bluetooth"
            sub: !pg.home.bt ? "Sem adaptador" : (!pg.home.bt.enabled ? "Desligado" : (pg.home.btConnected.length > 0 ? pg.home.btConnected[0].name : "Ligado"))
            on: !!pg.home.bt && pg.home.bt.enabled
            more: true
            onClicked: if (pg.home.bt) pg.home.bt.enabled = !pg.home.bt.enabled
            onMoreClicked: pg.home.tab = "bt"
        }
    }
    Component {
        id: profT
        HomeTile {
            icon: pg.home.profile === "performance" ? "rocket" : (pg.home.profile === "power-saver" ? "leaf" : "balance")
            label: "Energia"
            sub: pg.home.profileNames[pg.home.profile] ?? pg.home.profile
            on: pg.home.profile !== "balanced"
            onClicked: pg.home.cycleProfile()
        }
    }
    Component {
        id: genT
        HomeTile {
            readonly property var t: Toggles.find(parent.tid)
            icon: t ? t.icon : "cog"
            label: t ? t.label : ""
            sub: t ? (Recorder.elapsed, Idle.paused, Settings.notifDnd, Toggles.gameMode, t.sub()) : ""
            on: t ? (Recorder.active, Idle.paused, Settings.notifDnd, Settings.desktopOn, Toggles.gameMode, Osd.micMuted, t.on()) : false
            onClicked: if (t) t.click()
        }
    }

    // ---------- midia (resumo) ----------
    HomeCard {
        id: media
        anchors { top: tiles.bottom; topMargin: 10 }
        width: parent.width * 0.56; height: 116
        readonly property var pl: pg.home.player
        RoundImage {   // capa desfocada de fundo
            parent: media
            x: 1; y: 1; width: media.width - 2; height: media.height - 2; radius: 13
            visible: !!media.pl
            source: media.pl ? media.pl.trackArtUrl : ""
            sourceSize: Qt.size(200, 200)
            blur: 1; dim: 0.55
        }
        Text { visible: !media.pl; anchors.centerIn: parent; text: "Nada tocando"; color: Theme.muted; font.pixelSize: 13 }
        Item {
            visible: !!media.pl
            anchors.fill: parent
            RoundImage {
                id: art
                width: 88; height: 88; radius: 12
                source: media.pl ? media.pl.trackArtUrl : ""
                sourceSize: Qt.size(176, 176)
            }
            Rectangle { visible: !art.ready; width: 88; height: 88; radius: 12; color: Theme.track; UiIcon { anchors.centerIn: parent; name: "music"; size: 30; color: Theme.muted } }
            Column {
                anchors { left: art.right; leftMargin: 12; right: parent.right; top: parent.top; topMargin: 2 }
                spacing: 2
                Text { width: parent.width; text: media.pl ? media.pl.trackTitle : ""; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                Text { width: parent.width; text: media.pl ? (media.pl.trackArtist || media.pl.identity) : ""; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 12; elide: Text.ElideRight }
            }
            Row {
                anchors { left: art.right; leftMargin: 6; bottom: parent.bottom; bottomMargin: 0 }
                spacing: 4
                component MBtn: Rectangle {
                    id: mb
                    property string icon
                    property bool main: false
                    signal clicked()
                    width: main ? 40 : 34; height: width; radius: width / 2
                    color: main ? Theme.accent : (mbm.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent")
                    UiIcon { anchors.centerIn: parent; name: mb.icon; size: mb.main ? 20 : 18; color: mb.main ? Theme.accentText : "white" }
                    MouseArea { id: mbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mb.clicked() }
                }
                MBtn { icon: "prev"; anchors.verticalCenter: parent.verticalCenter; onClicked: if (media.pl && media.pl.canGoPrevious) media.pl.previous() }
                MBtn { main: true; icon: media.pl && media.pl.isPlaying ? "pause" : "play"; onClicked: if (media.pl && media.pl.canTogglePlaying) media.pl.togglePlaying() }
                MBtn { icon: "next"; anchors.verticalCenter: parent.verticalCenter; onClicked: if (media.pl && media.pl.canGoNext) media.pl.next() }
            }
            MouseArea { anchors { right: parent.right; top: parent.top } width: 30; height: 30; cursorShape: Qt.PointingHandCursor; onClicked: pg.home.tab = "media"
                UiIcon { anchors.centerIn: parent; name: "chevRight"; size: 16; color: Qt.rgba(1, 1, 1, 0.7) } }
        }
    }

    // ---------- sistema (resumo) ----------
    HomeCard {
        id: sysCard
        anchors { top: tiles.bottom; topMargin: 10; left: media.right; leftMargin: 10; right: parent.right }
        height: 116
        readonly property var s: pg.home.sys
        Column {
            anchors.fill: parent
            spacing: 9
            component Meter: Item {
                id: me
                property string icon
                property string label
                property real ratio: 0
                property string value
                width: parent.width; height: 16
                UiIcon { id: mi; name: me.icon; size: 14; color: Theme.muted; width: 18; anchors.verticalCenter: parent.verticalCenter }
                Text { id: ml; anchors { left: mi.right; leftMargin: 6; verticalCenter: parent.verticalCenter } text: me.label; color: Theme.text; font.pixelSize: 12; width: 44 }
                Rectangle {
                    anchors { left: ml.right; right: mv.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    height: 6; radius: 3; color: Theme.cardHi
                    Rectangle { width: parent.width * Math.max(0, Math.min(1, me.ratio)); height: parent.height; radius: 3; color: me.ratio > 0.85 ? Theme.danger : Theme.accent; Behavior on width { NumberAnimation { duration: 400 } } }
                }
                Text { id: mv; anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: me.value; color: Theme.muted; font.pixelSize: 12; width: 42; horizontalAlignment: Text.AlignRight }
            }
            Meter { icon: "chip"; label: "CPU"; ratio: (sysCard.s.cpu ?? 0) / 100; value: Math.round(sysCard.s.cpu ?? 0) + "%" }
            Meter { icon: "memory"; label: "RAM"; ratio: sysCard.s.memTotal ? sysCard.s.memUsed / sysCard.s.memTotal : 0; value: sysCard.s.memTotal ? Math.round(sysCard.s.memUsed / sysCard.s.memTotal * 100) + "%" : "–" }
            Meter { icon: "gpu"; label: "GPU"; ratio: sysCard.s.gpu ? sysCard.s.gpu.usage / 100 : 0; value: sysCard.s.gpu ? sysCard.s.gpu.usage + "%" : "–" }
            Meter { icon: "thermo"; label: "Temp."; ratio: (sysCard.s.cpuTemp ?? 0) / 100; value: sysCard.s.cpuTemp ? sysCard.s.cpuTemp + "°C" : "–" }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pg.home.tab = "system" }
    }

    // ---------- volumes ----------
    HomeCard {
        anchors { top: media.bottom; topMargin: 10; bottom: parent.bottom }
        width: parent.width
        Column {
            anchors.fill: parent
            anchors.topMargin: -2
            spacing: 4
            HomeSlider {
                readonly property var a: pg.home.sink ? pg.home.sink.audio : null
                icon: pg.home.volIcon(a)
                value: a ? a.volume : 0
                muted: !!a && a.muted
                onMoved: v => { if (a) { a.volume = v; if (a.muted && v > 0) a.muted = false } }
                onIconClicked: if (a) a.muted = !a.muted
            }
            HomeSlider {
                readonly property var a: pg.home.source ? pg.home.source.audio : null
                icon: a && a.muted ? "micOff" : "mic"
                value: a ? a.volume : 0
                muted: !!a && a.muted
                onMoved: v => { if (a) { a.volume = v; if (a.muted && v > 0) a.muted = false } }
                onIconClicked: if (a) a.muted = !a.muted
            }
        }
    }
}
