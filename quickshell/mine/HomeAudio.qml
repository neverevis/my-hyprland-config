// Aba "Audio": volume de saida e entrada, escolha dos dispositivos e volume de cada aplicativo.
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

HomeScroll {
    id: pg
    property var home

    component DevRow: Rectangle {
        id: dr
        property var node
        property bool current: false
        property string icon: "speaker"
        width: parent ? parent.width : 100; height: 38; radius: 10
        color: current ? Theme.tint(0.16) : (drm.containsMouse ? Theme.cardHi : "transparent")
        UiIcon { id: di; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } name: dr.icon; size: 17; color: dr.current ? Theme.accent : Theme.muted }
        UiText { anchors { left: di.right; leftMargin: 10; right: ck.left; rightMargin: 8; verticalCenter: parent.verticalCenter } text: pg.home.nodeName(dr.node); color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight }
        UiIcon { id: ck; visible: dr.current; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } name: "check"; size: 16; color: Theme.accent }
        MouseArea { id: drm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dr.clicked() }
        signal clicked()
    }

    // volume de um aplicativo (stream do PipeWire): icone do app, "app • midia", mudo no clique do icone
    component AppRow: HomeSlider {
        required property var modelData
        readonly property var a: modelData.audio
        label: pg.home.appLabel(modelData)
        iconSource: pg.home.appIcon(modelData)
        icon: pg.home.volIcon(a)
        value: a ? a.volume : 0
        muted: !!a && a.muted
        onMoved: v => { if (a) { a.volume = v; if (a.muted && v > 0) a.muted = false } }
        onIconClicked: if (a) a.muted = !a.muted
    }

    // ---- saida ----
    HomeCard {
        width: pg.width
        height: outCol.implicitHeight + 52
        title: "Saída"; icon: "speaker"
        Column {
            id: outCol
            width: parent.width
            spacing: 6
            HomeSlider {
                readonly property var a: pg.home.sink ? pg.home.sink.audio : null
                icon: pg.home.volIcon(a)
                value: a ? a.volume : 0
                muted: !!a && a.muted
                onMoved: v => { if (a) { a.volume = v; if (a.muted && v > 0) a.muted = false } }
                onIconClicked: if (a) a.muted = !a.muted
            }
            Repeater {
                model: pg.home.sinks
                delegate: DevRow {
                    required property var modelData
                    node: modelData
                    icon: (modelData.name || "").indexOf("hdmi") >= 0 ? "monitor" : ((modelData.name || "").indexOf("bluez") >= 0 ? "headphones" : "speaker")
                    current: pg.home.sink === modelData
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }
    }

    // ---- entrada ----
    HomeCard {
        width: pg.width
        height: inCol.implicitHeight + 52
        title: "Entrada"; icon: "mic"
        Column {
            id: inCol
            width: parent.width
            spacing: 6
            HomeSlider {
                readonly property var a: pg.home.source ? pg.home.source.audio : null
                icon: a && a.muted ? "micOff" : "mic"
                value: a ? a.volume : 0
                muted: !!a && a.muted
                onMoved: v => { if (a) { a.volume = v; if (a.muted && v > 0) a.muted = false } }
                onIconClicked: if (a) a.muted = !a.muted
            }
            Repeater {
                model: pg.home.sources
                delegate: DevRow {
                    required property var modelData
                    node: modelData
                    icon: "mic"
                    current: pg.home.source === modelData
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }
            UiText { visible: pg.home.inStreams.length > 0; text: "Aplicativos usando o microfone"; color: Theme.muted; font.pixelSize: 12; topPadding: 4 }
            Repeater {
                model: ScriptModel { values: pg.home.inStreams; objectProp: "id" }
                delegate: AppRow {}
            }
        }
    }

    // ---- aplicativos ----
    HomeCard {
        width: pg.width
        height: appCol.implicitHeight + 52
        title: "Aplicativos"; icon: "apps"
        Column {
            id: appCol
            width: parent.width
            spacing: 8
            UiText { visible: pg.home.streams.length === 0; text: "Nenhum app tocando som agora."; color: Theme.muted; font.pixelSize: 13; height: 24; verticalAlignment: Text.AlignVCenter }
            Repeater {
                model: ScriptModel { values: pg.home.streams; objectProp: "id" }
                delegate: AppRow {}
            }
        }
    }
}
