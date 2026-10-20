// Relogio mundial: varias cidades (fusos do sistema, ex.: Europe/London) em digital ou ponteiros.
// A hora de cada fuso vem do "date" do sistema (respeita horario de verao); atualiza a cada 20 s.
// 2x2 ou maior: cabecalho com a cidade e a hora local; cartoes de dia (cor de destaque) e noite (translucidos);
// a engrenagem vira o cartao para escolher os fusos (regiao + lista, sem digitar).
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
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    property string wid: ""
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
                return { zone: zone, city: w.city(zone), hh: parseInt(p[0]), mm: parseInt(p[1]), day: p[2], diff: diff, off: toMin(p[3]) }
            })
        } }
    }
    Timer { interval: 20000; repeat: true; running: w.visible; triggeredOnStart: true; onTriggered: { q.running = false; q.running = true } }
    onZonesChanged: { q.running = false; q.running = true }

    Component.onCompleted: Weather.use()
    SystemClock { id: clk; precision: SystemClock.Minutes }
    function two(n) { return String(n).padStart(2, "0") }
    // hora no formato do shell (24 h ou 12 h com AM/PM)
    function fmt(hh, mm) { return (o("hours") === "auto" ? Settings.clock24 : o("hours") === "24") ? two(hh) + ":" + two(mm) : (hh % 12 === 0 ? 12 : hh % 12) + ":" + two(mm) + (hh < 12 ? " AM" : " PM") }
    function utc(off) { const a = Math.abs(off), m = a % 60; return "UTC" + (off < 0 ? "-" : "+") + Math.floor(a / 60) + (m ? ":" + two(m) : "") }

    readonly property bool vert: o("vertical") || rows > cols
    readonly property bool analog: o("faces") === "analog"
    readonly property bool hdr: cols >= 2 && rows >= 2
    property bool back: false
    property real sx: 1
    function flip() {
        if (flipAnim.running) return
        flipAnim.start()
        if (!back && tzAll.length === 0) tzp.running = true
    }
    SequentialAnimation {
        id: flipAnim
        NumberAnimation { target: w; property: "sx"; to: 0; duration: 150; easing.type: Easing.InQuad }
        ScriptAction { script: w.back = !w.back }
        NumberAnimation { target: w; property: "sx"; to: 1; duration: 150; easing.type: Easing.OutQuad }
    }
    // lista de fusos do sistema (so quando o cartao vira)
    property var tzAll: []
    property string region: ""
    property string tzq: ""     // busca no seletor de fusos
    function norm(t) { return String(t).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase() }
    onBackChanged: if (!back) { tzq = ""; tzs.text = "" }
    Process {
        id: tzp
        command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector { onStreamFinished: w.tzAll = text.trim().split("\n").filter(z => z.indexOf("/") > 0) }
    }
    function toggleZone(z) {
        if (w.wid === "") return
        const cur = Array.from(Settings.list(o("zones")))
        const i = cur.indexOf(z)
        if (i >= 0) { if (cur.length > 1) cur.splice(i, 1) } else if (cur.length < 8) cur.push(z)
        DeskState.setOpt(w.wid, "zones", cur)
    }

    Item {
        id: face
        anchors.fill: parent
        transform: Scale { origin.x: face.width / 2; xScale: Math.max(0.001, w.sx) }

        // ---------- frente ----------
        Item {
            id: front
            anchors.fill: parent
            visible: !w.back
            readonly property real hh: w.hdr ? Math.min(parent.height * 0.42, 96) : 0
            // cabecalho: cidade local e hora local grande
            Item {
                visible: w.hdr
                width: parent.width; height: front.hh
                Row {
                    spacing: 5
                    UiIcon { name: "mapMarker"; size: 14; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: Weather.place !== "" ? Weather.place.split(",")[0] : "Aqui"; color: w.fg; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, front.width * 0.5); elide: Text.ElideRight }
                }
                Column {
                    anchors { right: parent.right; bottom: parent.bottom }
                    UiText { anchors.right: parent.right; text: w.fmt(clk.date.getHours(), clk.date.getMinutes()); color: w.fg; font.pixelSize: Math.min(42, front.hh * 0.5); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    UiText { anchors.right: parent.right; text: DateTime.long(clk.date, "dddd, d MMM yyyy"); color: w.dim; font.pixelSize: 11 }
                }
            }
            Grid {
                y: front.hh + (w.hdr ? 6 : 0)
                width: parent.width; height: parent.height - y
                columns: w.vert ? 1 : Math.max(1, Math.min(w.rows_.length, w.rows > 1 ? Math.ceil(w.rows_.length / 2) : w.rows_.length))
                readonly property int nrows: Math.ceil(w.rows_.length / columns)
                spacing: 6
                Repeater {
                    model: w.rows_
                    delegate: Rectangle {
                        required property var modelData
                        width: (parent.width - (parent.columns - 1) * parent.spacing) / parent.columns
                        height: (parent.height - (parent.nrows - 1) * parent.spacing) / parent.nrows
                        readonly property bool day: modelData.hh >= 6 && modelData.hh < 18
                        readonly property bool narrow: width < 100
                        radius: Math.min(18, Math.min(width, height) * 0.28)
                        color: day ? w.ac : (w.analog ? w.cont : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.1))
                        readonly property color ink: day ? Theme.accentText : (w.analog ? w.contInk : w.fg)
                        // ponteiros (estilo AndroidClock: tile cheio, ponteiros claros, miolo)
                        Item {
                            visible: w.analog
                            anchors.fill: parent
                            readonly property real r: Math.min(width, height - 14) / 2
                            Rectangle { width: 4; height: parent.r * 0.55; radius: 2; color: parent.parent.ink; x: parent.width / 2 - 2; y: (parent.height - 12) / 2 - height; transformOrigin: Item.Bottom; rotation: (modelData.hh % 12 + modelData.mm / 60) * 30 }
                            Rectangle { width: 3; height: parent.r * 0.82; radius: 1.5; color: parent.parent.ink; x: parent.width / 2 - 1.5; y: (parent.height - 12) / 2 - height; transformOrigin: Item.Bottom; rotation: modelData.mm * 6 }
                            Rectangle { width: 8; height: 8; radius: 4; color: parent.parent.ink; x: parent.width / 2 - 4; y: (parent.height - 12) / 2 - 4 }
                            UiText { anchors { bottom: parent.bottom; bottomMargin: 3; horizontalCenter: parent.horizontalCenter } text: modelData.city; color: parent.parent.ink; font.pixelSize: 10; font.weight: Font.DemiBold; width: Math.min(implicitWidth, parent.width - 6); elide: Text.ElideRight }
                        }
                        // digital
                        Item {
                            visible: !w.analog
                            anchors { fill: parent; margins: 8 }
                            UiText { id: cn; text: modelData.city; color: parent.parent.ink; font.pixelSize: parent.parent.narrow ? 10 : 12; font.weight: Font.DemiBold; width: parent.width - 18; elide: Text.ElideRight }
                            UiIcon { anchors { top: parent.top; right: parent.right } name: parent.parent.day ? "wSun" : "wNight"; size: 12; color: parent.parent.ink }
                            UiText { anchors.top: cn.bottom; visible: parent.height > 40; text: w.utc(modelData.off); color: parent.parent.ink; opacity: 0.65; font.pixelSize: 10 }
                            UiText { anchors { left: parent.left; bottom: parent.bottom } text: w.fmt(modelData.hh, modelData.mm); color: parent.parent.ink; font.weight: Font.Bold; font.features: { "tnum": 1 }
                                font.pixelSize: Math.max(12, Math.min(parent.height * 0.42, parent.width * (Settings.clock24 ? 0.3 : 0.22))) }
                        }
                    }
                }
            }
            // engrenagem (sem cabecalho: so ao passar o mouse)
            Rectangle {
                id: gear
                anchors { top: parent.top; right: parent.right; topMargin: w.hdr ? 0 : -4; rightMargin: w.hdr ? 0 : -4 }
                width: 26; height: 26; radius: 13
                visible: w.wid !== "" && opacity > 0
                opacity: w.hdr ? 1 : (hov.hovered || gm.containsMouse ? 1 : 0)
                z: 3
                Behavior on opacity { NumberAnimation { duration: 150 } }
                color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, gm.containsMouse ? 0.22 : 0.12)
                UiIcon { anchors.centerIn: parent; name: "cog"; size: 14; color: w.fg }
                MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.flip() }
            }
            HoverHandler { id: hov }
        }

        // ---------- verso: escolher os fusos ----------
        Item {
            visible: w.back
            anchors.fill: parent
            readonly property var regions: {
                const r = []
                for (const z of w.tzAll) { const a = z.split("/")[0]; if (r.indexOf(a) < 0) r.push(a) }
                return r
            }
            readonly property var sel: Array.from(Settings.list(w.o("zones")))
            readonly property string reg: w.region !== "" ? w.region : (regions.indexOf("America") >= 0 ? "America" : (regions[0] ?? ""))
            Row {
                id: bh
                width: parent.width; height: 26; spacing: 6
                UiText { text: "Fusos (" + parent.parent.sel.length + "/8)"; color: w.fg; font.pixelSize: 13; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                Item { width: Math.max(0, bh.width - 26 - 12 - 90); height: 1 }
                Rectangle { width: 26; height: 26; radius: 13; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12)
                    UiIcon { anchors.centerIn: parent; name: "check"; size: 14; color: w.fg }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: w.flip() } }
            }
            // busca por cidade/pais em todas as regioes (com texto, os chips de regiao somem)
            UiField {
                id: tzs
                anchors { top: bh.bottom; topMargin: 4 }
                width: parent.width; implicitHeight: 28; font.pixelSize: 12
                placeholderText: "Buscar cidade…"
                onTextEdited: w.tzq = text
                onActiveFocusChanged: DeskState.wantKeys("world-f-" + w.wid, activeFocus)
                Keys.onEscapePressed: { text = ""; w.tzq = ""; focus = false }
                HoverHandler { onHoveredChanged: DeskState.wantKeys("world-h-" + w.wid, hovered) }
                Component.onDestruction: { DeskState.wantKeys("world-h-" + w.wid, false); DeskState.wantKeys("world-f-" + w.wid, false) }
            }
            ListView {
                id: regs
                visible: w.tzq === ""
                anchors { top: tzs.bottom; topMargin: 4 }
                width: parent.width; height: w.tzq === "" ? 26 : 0
                orientation: ListView.Horizontal; spacing: 4; clip: true
                model: parent.regions
                delegate: Rectangle {
                    required property string modelData
                    width: rt.implicitWidth + 16; height: 24; radius: 12
                    color: modelData === regs.parent.reg ? w.ac : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.1)
                    UiText { id: rt; anchors.centerIn: parent; text: modelData; font.pixelSize: 11; color: modelData === regs.parent.reg ? Theme.accentText : w.fg }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: w.region = modelData }
                }
            }
            ListView {
                id: zl
                anchors { top: regs.bottom; topMargin: 4; bottom: parent.bottom }
                width: parent.width; clip: true; spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: w.tzq !== "" ? w.tzAll.filter(z => w.norm(z.replace(/_/g, " ")).includes(w.norm(w.tzq))) : w.tzAll.filter(z => z.split("/")[0] === regs.parent.reg)
                delegate: Rectangle {
                    required property string modelData
                    readonly property bool on: zl.parent.sel.indexOf(modelData) >= 0
                    width: zl.width; height: 26; radius: 8
                    color: on ? Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.25) : (zm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.1) : "transparent")
                    UiText { anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter; right: ck.left } text: modelData.split("/").slice(w.tzq !== "" ? 0 : 1).join(" / ").replace(/_/g, " "); color: w.fg; font.pixelSize: 12; elide: Text.ElideRight }
                    UiIcon { id: ck; visible: parent.on; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } name: "check"; size: 13; color: w.ac }
                    MouseArea { id: zm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.toggleZone(modelData) }
                }
            }
        }
    }
}
