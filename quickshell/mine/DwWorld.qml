// Relogio mundial: varias cidades (fusos do sistema, ex.: Europe/London) em digital ou ponteiros.
// A hora de cada fuso vem do "date" do sistema (respeita horario de verao); atualiza a cada 20 s.
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "world", opts: w.opts }, k) }

    readonly property var zones: (o("zones") || []).slice(0, 8)
    property var rows_: []    // [{ zone, city, hh, mm, day, diff }]
    function city(z) { return z.split("/").pop().replace(/_/g, " ") }
    Process {
        id: q
        command: ["sh", "-c", 'base=$(date +%z); for z in "$@"; do printf "%s|%s|%s\\n" "$z" "$(TZ=$z date +%H:%M:%a:%z)" "$base"; done', "sh"].concat(w.zones)
        stdout: StdioCollector { onStreamFinished: {
            const toMin = z => (z[0] === "-" ? -1 : 1) * (parseInt(z.substr(1, 2)) * 60 + parseInt(z.substr(3, 2)))
            w.rows_ = text.trim().split("\n").filter(l => l).map(l => {
                const [zone, t, base] = l.split("|"), p = t.split(":")
                const diff = (toMin(p[3]) - toMin(base)) / 60
                return { zone: zone, city: w.city(zone), hh: parseInt(p[0]), mm: parseInt(p[1]), day: p[2], diff: diff }
            })
        } }
    }
    Timer { interval: 20000; repeat: true; running: true; triggeredOnStart: true; onTriggered: { q.running = false; q.running = true } }
    onZonesChanged: { q.running = false; q.running = true }

    readonly property bool vert: o("vertical") || rows > cols
    readonly property bool analog: o("faces") === "analog"
    Grid {
        anchors.fill: parent
        columns: w.vert ? 1 : Math.max(1, Math.min(w.rows_.length, w.rows > 1 ? Math.ceil(w.rows_.length / 2) : w.rows_.length))
        readonly property int nrows: Math.ceil(w.rows_.length / columns)
        Repeater {
            model: w.rows_
            delegate: Item {
                required property var modelData
                width: w.width / parent.columns; height: w.height / parent.nrows
                readonly property bool night: modelData.hh < 6 || modelData.hh >= 19
                // ponteiros
                Item {
                    visible: w.analog
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 2
                    width: Math.min(parent.width - 8, parent.height - 34); height: width
                    Rectangle { anchors.fill: parent; radius: width / 2; color: parent.parent.night ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.18); border.width: 1; border.color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.2) }
                    Rectangle { width: 3; height: parent.height * 0.26; radius: 1.5; color: w.fg; x: parent.width / 2 - 1.5; y: parent.height / 2 - height; transformOrigin: Item.Bottom; rotation: (modelData.hh % 12 + modelData.mm / 60) * 30 }
                    Rectangle { width: 2; height: parent.height * 0.38; radius: 1; color: w.ac; x: parent.width / 2 - 1; y: parent.height / 2 - height; transformOrigin: Item.Bottom; rotation: modelData.mm * 6 }
                }
                Column {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: w.analog ? parent.bottom : undefined; verticalCenter: w.analog ? undefined : parent.verticalCenter }
                    spacing: 0
                    Text { visible: !w.analog; anchors.horizontalCenter: parent.horizontalCenter
                        text: String(modelData.hh).padStart(2, "0") + ":" + String(modelData.mm).padStart(2, "0")
                        color: w.fg; font.pixelSize: Math.min(parent.parent.height * 0.42, parent.parent.width * 0.3); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4
                        readonly property bool narrow: parent.parent.width < 100
                        UiIcon { visible: !parent.narrow; name: parent.parent.parent.night ? "wNight" : "wSun"; size: 11; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: modelData.city; color: w.fg; font.pixelSize: parent.narrow ? 10 : 12; font.weight: Font.DemiBold; elide: Text.ElideRight; width: Math.min(implicitWidth, parent.parent.parent.width - (parent.narrow ? 4 : 22)) }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.diff === 0 ? "aqui" : (modelData.diff > 0 ? "+" : "") + modelData.diff + " h"; color: w.dim; font.pixelSize: 10 }
                }
            }
        }
    }
}
