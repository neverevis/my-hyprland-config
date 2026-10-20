// Aba "Inicio" do painel: usuario e relogio, atalhos, midia, resumo do sistema e volumes.
import Quickshell
import Quickshell.Networking
import QtQuick

HomeScroll {
    id: pg
    property var home
    spacing: 10
    readonly property bool editing: !!home && home.editMode

    // ---------- usuario + relogio ----------
    Rectangle {
        id: userCard
        width: pg.width; height: 108; radius: 16
        color: Theme.glc(Theme.card, 1.15)
        border.width: 1; border.color: Theme.border
        RoundImage {
            x: 1; y: 1; width: parent.width - 2; height: parent.height - 2
            radius: 15
            source: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
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
            UiText { text: Quickshell.env("USER"); color: "white"; font.pixelSize: 19; font.weight: Font.Bold }
            UiText { text: Quickshell.env("USER") + "@" + (pg.home.st.host || "linux"); color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12 }
            Row {
                spacing: 5
                visible: !!pg.home.sys.uptime
                UiIcon { name: "clock"; size: 13; color: Qt.rgba(1, 1, 1, 0.75); anchors.verticalCenter: parent.verticalCenter }
                UiText { text: "Ativo há " + pg.home.dur(pg.home.sys.uptime); color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12 }
            }
        }
        SystemClock { id: clk; precision: SystemClock.Minutes }
        Column {
            anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
            spacing: 0
            UiText { anchors.right: parent.right; text: Qt.formatDateTime(clk.date, "HH:mm"); color: "white"; font.pixelSize: 36; font.weight: Font.Bold }
            UiText {
                anchors.right: parent.right
                text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
                color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12
            }
        }
        Rectangle {   // editar os botoes rapidos
            anchors { right: parent.right; top: parent.top; rightMargin: 8; topMargin: 8 }
            width: 28; height: 28; radius: 14
            color: pg.editing ? Theme.accent : (edm.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.28))
            UiIcon { anchors.centerIn: parent; name: pg.editing ? "check" : "pencil"; size: 15; color: pg.editing ? Theme.accentText : "white" }
            MouseArea { id: edm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pg.home.editMode = !pg.home.editMode }
        }
    }

    // ---------- botoes rapidos (Settings.homeToggles; os de Wi-Fi, Bluetooth e energia sao daqui, os outros do Toggles.qml) ----------
    // cada botao ocupa 1 a 3 das "colunas" (Settings.homeColumns); o clique direito (ou a seta) abre o menu do botao
    function act(a) {
        if (!a) return
        if (typeof a === "function") a()
        else if (a.indexOf("tab:") === 0) pg.home.tab = a.slice(4)
        else if (a.indexOf("dialog:") === 0) pg.home.dialog = a.slice(7)
    }
    function save(l) { Settings.homeToggles = l }
    function cur() { return Toggles.norm(Settings.homeToggles) }
    function setSize(i, v) { const l = cur(); if (l[i]) { l[i].size = v; save(l) } }
    function move(i, d) { const l = cur(), j = i + d; if (j < 0 || j >= l.length) return; const t = l[i]; l[i] = l[j]; l[j] = t; save(l) }
    function drop(i) { const l = cur(); l.splice(i, 1); save(l) }
    function add(id) { const l = cur(); l.push({ id: id, size: 2 }); save(l) }

    Column {
        id: tiles
        z: 5
        width: pg.width
        spacing: 8
        readonly property int cols: Math.max(1, Math.min(8, Settings.homeColumns))
        readonly property real unit: (width - (cols - 1) * 8) / cols
        Repeater {
            model: Toggles.rows(Settings.homeToggles, tiles.cols)
            delegate: Row {
                id: trow
                required property var modelData
                spacing: 8
                z: 10 - trow.modelData[0].idx / 100   // dicas de cima passam por cima da linha de baixo
                Repeater {
                    model: trow.modelData
                    delegate: Item {
                        id: cell
                        required property var modelData
                        width: modelData.w * tiles.unit + (modelData.w - 1) * 8
                        height: 58
                        Loader {
                            id: ld
                            anchors.fill: parent
                            sourceComponent: cell.modelData.id === "wifi" ? wifiT : cell.modelData.id === "bt" ? btT : cell.modelData.id === "profile" ? profT : genT
                            property string tid: cell.modelData.id
                            property int tsize: cell.modelData.size
                        }
                        // modo de edicao: tirar, mudar de lugar e de tamanho
                        Rectangle {
                            visible: pg.editing
                            anchors.fill: parent
                            radius: 14
                            color: Qt.rgba(0, 0, 0, 0.72)
                            border.width: 1.5; border.color: Theme.accent
                            MouseArea { anchors.fill: parent }
                            Row {
                                anchors.centerIn: parent
                                spacing: 2
                                Repeater {
                                    model: [["chevLeft", -1], ["resize", 0], ["chevRight", 1]]
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 26; height: 26; radius: 8
                                        color: em.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.1)
                                        UiIcon { anchors.centerIn: parent; name: parent.modelData[0]; size: 15; color: "white" }
                                        MouseArea {
                                            id: em; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { if (parent.modelData[1] === 0) pg.setSize(cell.modelData.idx, cell.modelData.size % 3 + 1); else pg.move(cell.modelData.idx, parent.modelData[1]) }
                                        }
                                    }
                                }
                            }
                            UiText { anchors { left: parent.left; bottom: parent.bottom; leftMargin: 8; bottomMargin: 3 }
                                text: cell.modelData.size; color: "white"; font.pixelSize: 10; opacity: 0.8 }
                            Rectangle {
                                anchors { right: parent.right; top: parent.top; rightMargin: 3; topMargin: 3 }
                                width: 20; height: 20; radius: 10
                                color: xm.containsMouse ? Theme.danger : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.85)
                                UiIcon { anchors.centerIn: parent; name: "close"; size: 12; color: "white" }
                                MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pg.drop(cell.modelData.idx) }
                            }
                        }
                    }
                }
            }
        }
    }
    // edicao: o que ainda nao esta na lista
    Column {
        visible: pg.editing
        width: pg.width
        spacing: 6
        UiText { text: "Toque para adicionar"; color: Theme.muted; font.pixelSize: 12 }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: Toggles.all.filter(t => Toggles.norm(Settings.homeToggles).findIndex(e => e.id === t.id) < 0)
                delegate: UiButton { required property var modelData; icon: modelData.icon; text: modelData.label; kind: "ghost"; onClicked: pg.add(modelData.id) }
            }
        }
    }
    Component {
        id: wifiT
        HomeTile {
            readonly property bool hasWifi: !!pg.home.wifiDev
            readonly property bool wired: !!pg.home.wiredDev && pg.home.wiredDev.connected
            size: parent.tsize; editing: pg.editing; tip: label + ": " + sub
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
            size: parent.tsize; editing: pg.editing; tip: label + ": " + sub
            icon: pg.home.bt && pg.home.bt.enabled ? "bluetooth" : "btOff"
            label: "Bluetooth"
            sub: !pg.home.bt ? "Sem adaptador" : (!pg.home.bt.enabled ? "Desligado" : (pg.home.btConnected.length > 0 ? pg.home.btConnected[0].name + (pg.home.btConnected.length > 1 ? " +" + (pg.home.btConnected.length - 1) : "") : "Ligado"))
            on: !!pg.home.bt && pg.home.bt.enabled
            avail: !!pg.home.bt
            more: true
            onClicked: if (pg.home.bt) pg.home.bt.enabled = !pg.home.bt.enabled
            onMoreClicked: pg.home.tab = "bt"
        }
    }
    Component {
        id: profT
        HomeTile {
            size: parent.tsize; editing: pg.editing; tip: label + ": " + sub
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
            size: parent.tsize; editing: pg.editing
            icon: t ? (Toggles.deps(), t.iconNow ? t.iconNow() : t.icon) : "cog"
            label: t ? t.label : ""
            sub: t ? (Toggles.deps(), t.sub()) : ""
            on: t ? (Toggles.deps(), t.on()) : false
            avail: t ? (Toggles.deps(), t.avail ? t.avail() : true) : true
            tip: t ? label + (sub !== "" ? ": " + sub : "") : ""
            more: !!(t && t.alt)
            onClicked: if (t && avail) t.click()
            onMoreClicked: if (t) pg.act(t.alt)
        }
    }

    // ---------- midia (resumo) ----------
    Row {
    spacing: 10
    HomeCard {
        id: media
        width: Math.round((pg.width - 10) * 0.56); height: 116
        readonly property var pl: pg.home.player
        RoundImage {   // capa desfocada de fundo
            parent: media
            x: 1; y: 1; width: media.width - 2; height: media.height - 2; radius: 13
            visible: !!media.pl
            source: media.pl ? media.pl.trackArtUrl : ""
            sourceSize: Qt.size(200, 200)
            blur: 1; dim: 0.55
        }
        UiText { visible: !media.pl; anchors.centerIn: parent; text: "Nada tocando"; color: Theme.muted; font.pixelSize: 13 }
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
                UiText { width: parent.width; text: media.pl ? media.pl.trackTitle : ""; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                UiText { width: parent.width; text: media.pl ? (media.pl.trackArtist || media.pl.identity) : ""; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 12; elide: Text.ElideRight }
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
        width: pg.width - media.width - 10
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
                UiText { id: ml; anchors { left: mi.right; leftMargin: 6; verticalCenter: parent.verticalCenter } text: me.label; color: Theme.text; font.pixelSize: 12; width: 44 }
                Rectangle {
                    anchors { left: ml.right; right: mv.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    height: 6; radius: 3; color: Theme.cardHi
                    Rectangle { width: parent.width * Math.max(0, Math.min(1, me.ratio)); height: parent.height; radius: 3; color: me.ratio > 0.85 ? Theme.danger : Theme.accent; Behavior on width { NumberAnimation { duration: 400 } } }
                }
                UiText { id: mv; anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: me.value; color: Theme.muted; font.pixelSize: 12; width: 42; horizontalAlignment: Text.AlignRight }
            }
            Meter { icon: "chip"; label: "CPU"; ratio: (sysCard.s.cpu ?? 0) / 100; value: Math.round(sysCard.s.cpu ?? 0) + "%" }
            Meter { icon: "memory"; label: "RAM"; ratio: sysCard.s.memTotal ? sysCard.s.memUsed / sysCard.s.memTotal : 0; value: sysCard.s.memTotal ? Math.round(sysCard.s.memUsed / sysCard.s.memTotal * 100) + "%" : "–" }
            Meter { icon: "gpu"; label: "GPU"; ratio: sysCard.s.gpu ? sysCard.s.gpu.usage / 100 : 0; value: sysCard.s.gpu ? sysCard.s.gpu.usage + "%" : "–" }
            Meter { icon: "thermo"; label: "Temp."; ratio: (sysCard.s.cpuTemp ?? 0) / 100; value: sysCard.s.cpuTemp ? sysCard.s.cpuTemp + "°C" : "–" }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pg.home.tab = "system" }
    }
    }

    // ---------- volumes ----------
    HomeCard {
        width: pg.width
        height: 2 * 36 + 4 + 2 * 14 - 2
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
