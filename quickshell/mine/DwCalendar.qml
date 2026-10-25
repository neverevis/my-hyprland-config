// Widget de calendario. 2x2/3x2: o mes inteiro (setas trocam o mes; clique no titulo volta para hoje);
// 2x1: a semana atual; 1x1: o dia de hoje bem grande. Opcoes: semana comeca no domingo ou segunda,
// fins de semana destacados, numero da semana (ISO).
// Composicoes (opcao "look"): atual (acima), folha (1x1 com faixa colorida), pilula (mes + semana), mes em caixa e data ao lado
// (as do end4). Cada uma e um Component num Loader: so a ativa existe.
import Quickshell
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 2
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    property var comp: ({})                       // composicao vinda do cartao (caixas internas, selos, destaque, raio)
    function o(k) { return DeskState.opt({ type: "calendar", opts: w.opts }, k) }
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property date today: clk.date
    property int shift: 0
    WheelHandler { acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad; onWheel: e => w.shift += e.angleDelta.y > 0 ? -1 : 1 }   // roda: troca de mes
    readonly property date month: new Date(today.getFullYear(), today.getMonth() + shift, 1)
    readonly property var loc: Qt.locale("pt_BR")
    function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1) }
    readonly property int ws: o("weekStart")
    readonly property var wd: { const n = ["D", "S", "T", "Q", "Q", "S", "S"]; return n.slice(ws).concat(n.slice(0, ws)) }
    function weekend(d) { return d.getDay() === 0 || d.getDay() === 6 }
    function isoWeek(d) { const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate())); const day = t.getUTCDay() || 7; t.setUTCDate(t.getUTCDate() + 4 - day); const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1)); return Math.ceil(((t - y0) / 86400000 + 1) / 7) }
    function dayCol(d, inMonth) { const base = w.o("weekends") && weekend(d) ? Qt.tint(w.fg, Qt.rgba(w.ac2.r, w.ac2.g, w.ac2.b, 0.7)) : w.fg; return inMonth ? base : Qt.rgba(base.r, base.g, base.b, 0.35) }

    // ---- composicao ----
    readonly property string lk: {
        let l = o("look")
        if (l === "auto") return "plain"
        if (l === "end4") l = cols === 1 ? "tearoff" : rows === 1 ? "pill" : (cols >= 3 && rows >= 2) ? "side" : "panel"
        if ((l === "panel" || l === "side") && (rows === 1 || cols === 1)) l = cols === 1 ? "tearoff" : "pill"
        if (l === "side" && cols < 3) l = "panel"
        return l
    }
    readonly property real pad: lk === "plain" ? -1 : lk === "tearoff" ? 0 : lk === "pill" ? 14 : 16
    readonly property real cardR: comp.radius !== undefined ? comp.radius : 20
    readonly property color acc: comp.accent !== undefined ? comp.accent : ac
    readonly property color accInk: (0.299 * acc.r + 0.587 * acc.g + 0.114 * acc.b) > 0.56 ? "#15131a" : "#f6f3fa"
    function innerRole(def) { return comp.innerRole && comp.innerRole !== "auto" ? comp.innerRole : def }
    function innerAlpha(def) { return comp.innerAlpha > 0 ? comp.innerAlpha : def }
    function innerRad(def) { return comp.innerRadius > 0 ? comp.innerRadius : def }
    readonly property string badgeShape: comp.badgeShape && comp.badgeShape !== "auto" ? comp.badgeShape : "gem"

    // mes em caixa: titulo com setas (botoes redondos), dias da semana e a grade dentro de uma caixa interna
    component MonthView: Item {
        id: mv
        property real u: 1
        property bool head: true
        readonly property string nav: w.o("navStyle")
        readonly property string tshape: w.o("todayShape")
        Item {
            id: mh
            visible: mv.head
            width: parent.width; height: mv.head ? 28 * mv.u : 0
            UiText { anchors.verticalCenter: parent.verticalCenter; text: w.cap(w.month.toLocaleDateString(w.loc, "MMMM")) + (w.month.getFullYear() !== w.today.getFullYear() ? " " + w.month.getFullYear() : ""); color: w.fg; font.pixelSize: Math.round(16 * mv.u); font.weight: Font.Bold; font.features: { "tnum": 1 } }
            Row {
                visible: mv.nav !== "hidden"
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4 * mv.u
                Repeater {
                    model: [["chevLeft", -1], ["chevRight", 1]]
                    delegate: DwParts.RoundBtn {
                        required property var modelData
                        width: 26 * mv.u; height: width; icon: modelData[0]; tone: w.acc; ink: w.fg; kind: mv.nav === "tonal" ? "tonal" : "outlined"
                        onClicked: w.shift += modelData[1]
                    }
                }
            }
            MouseArea { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 120 * mv.u; onClicked: w.shift = 0 }
        }
        Row {
            id: wr
            y: mh.height + 2 * mv.u
            x: 4 * mv.u; width: parent.width - 8 * mv.u; height: 18 * mv.u
            readonly property bool wn: w.o("weekNumbers")
            readonly property real cw: width / (wn ? 8 : 7)
            Repeater {
                model: wr.wn ? ["#"].concat(w.wd) : w.wd
                delegate: Item { required property string modelData; width: wr.cw; height: wr.height
                    UiText { anchors.centerIn: parent; text: modelData; color: w.dim; font.pixelSize: Math.round(11 * mv.u); font.weight: Font.DemiBold } }
            }
        }
        DwParts.Panel {
            id: gp
            y: wr.y + wr.height + 2 * mv.u
            width: parent.width; height: parent.height - y
            role: w.innerRole("bg"); alpha: w.innerAlpha(0.2); radius: w.innerRad(22) * mv.u
            Grid {
                id: g
                anchors { fill: parent; margins: 4 * mv.u }
                readonly property bool wn: w.o("weekNumbers")
                columns: wn ? 8 : 7
                readonly property real cw: width / columns
                readonly property real ch: height / 6
                readonly property int lead: (w.month.getDay() - w.ws + 7) % 7
                Repeater {
                    model: 6 * g.columns
                    delegate: Item {
                        required property int index
                        readonly property int col: index % g.columns
                        readonly property int row: Math.floor(index / g.columns)
                        readonly property bool isWn: g.wn && col === 0
                        readonly property int di: row * 7 + (g.wn ? col - 1 : col)
                        readonly property date d: new Date(w.month.getFullYear(), w.month.getMonth(), di - g.lead + 1)
                        readonly property bool inMonth: d.getMonth() === w.month.getMonth()
                        readonly property bool isToday: d.toDateString() === w.today.toDateString()
                        width: g.cw; height: g.ch
                        Flower {
                            visible: !parent.isWn && parent.isToday
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 2 * mv.u; height: width
                            shape: mv.tshape; sides: 12; radius: width * 0.38; color: w.acc; animated: false
                        }
                        UiText {
                            anchors.centerIn: parent
                            text: parent.isWn ? w.isoWeek(new Date(w.month.getFullYear(), w.month.getMonth(), parent.row * 7 - g.lead + 4)) : parent.d.getDate()
                            font.pixelSize: Math.round((parent.isWn ? 10 : 13) * mv.u); font.weight: parent.isToday ? Font.Bold : Font.Normal
                            color: parent.isWn ? w.dim : parent.isToday ? w.accInk : w.dayCol(parent.d, parent.inMonth)
                        }
                    }
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: ({ plain: plainC, tearoff: tearC, pill: pillC, panel: panelC, side: sideC })[w.lk] ?? plainC
    }

    // folha: faixa colorida em cima (cantos do cartao), mes e dia da semana, e o dia grande
    Component {
        id: tearC
        Item {
            id: tr
            readonly property real u: Math.max(0.3, Math.min(width / 132, height / 120))
            Rectangle {
                id: tband
                width: parent.width; height: parent.height * 0.35
                color: w.acc
                topLeftRadius: w.bare ? w.cardR : w.cardR; topRightRadius: topLeftRadius
                Row {
                    anchors.centerIn: parent
                    spacing: 6 * tr.u
                    UiText { text: w.today.toLocaleDateString(w.loc, "MMM").replace(".", ""); color: w.accInk; font.pixelSize: Math.round(16 * tr.u); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    UiText { text: w.today.toLocaleDateString(w.loc, "ddd").replace(".", ""); color: Qt.rgba(w.accInk.r, w.accInk.g, w.accInk.b, 0.7); font.pixelSize: Math.round(16 * tr.u); font.features: { "tnum": 1 } }
                }
            }
            UiText {
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: tband.height / 2 }
                text: w.today.getDate(); color: w.fg; font.pixelSize: Math.round(Math.min(60 * tr.u, (parent.height - tband.height) * 0.9)); font.weight: Font.Bold
            }
        }
    }

    // pilula do mes e a semana de hoje
    Component {
        id: pillC
        Item {
            id: pl
            readonly property real u: Math.max(0.3, Math.min(width / 248, height / 92))
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 8 * pl.u
                DwParts.Chip { text: w.cap(w.today.toLocaleDateString(w.loc, "MMMM yyyy")); fill: w.acc; ink: w.accInk; fs: 13 * pl.u }
                Row {
                    width: parent.width
                    readonly property real cw: width / 7
                    Repeater {
                        model: 7
                        delegate: Column {
                            required property int index
                            readonly property date d: new Date(w.today.getFullYear(), w.today.getMonth(), w.today.getDate() - ((w.today.getDay() - w.ws + 7) % 7) + index)
                            readonly property bool isToday: d.toDateString() === w.today.toDateString()
                            width: parent.cw
                            spacing: 4 * pl.u
                            UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.wd[index]; color: w.dim; font.pixelSize: Math.round(11 * pl.u); font.weight: Font.DemiBold }
                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 28 * pl.u; height: width
                                Rectangle { anchors.fill: parent; radius: width / 2; color: parent.parent.isToday ? w.acc : "transparent" }
                                UiText { anchors.centerIn: parent; text: parent.parent.d.getDate(); color: parent.parent.isToday ? w.accInk : w.dayCol(parent.parent.d, true); font.pixelSize: Math.round(13 * pl.u); font.weight: parent.parent.isToday ? Font.Bold : Font.Medium }
                            }
                        }
                    }
                }
            }
        }
    }

    // mes em caixa (2x2)
    Component {
        id: panelC
        MonthView { u: Math.max(0.3, Math.min(width / 244, height / 220)) }
    }

    // data ao lado (3x2): coluna com selo, mes, dia da semana e o dia grande; o mes na caixa
    Component {
        id: sideC
        Item {
            id: sd
            readonly property real u: Math.max(0.3, Math.min(width / 388, height / 220))
            Column {
                id: dc
                width: 110 * sd.u
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2 * sd.u
                DwParts.Badge { shape: w.badgeShape; icon: "calendar"; bg: w.acc; size: 40 * sd.u }
                Item { width: 1; height: 8 * sd.u }
                UiText { text: w.today.toLocaleDateString(w.loc, "MMMM").toUpperCase(); color: w.fg; font.pixelSize: Math.round(14 * sd.u); font.weight: Font.Bold; font.letterSpacing: 1; font.features: { "tnum": 1 } }
                UiText { text: w.cap(w.today.toLocaleDateString(w.loc, "dddd")); color: w.dim; font.pixelSize: Math.round(17 * sd.u); font.features: { "tnum": 1 } }
                UiText { text: w.today.getDate(); color: w.acc; font.pixelSize: Math.round(66 * sd.u); font.weight: Font.Bold; lineHeight: 0.9 }
            }
            MonthView { x: dc.width + 16 * sd.u; width: parent.width - x; height: parent.height; u: sd.u }
        }
    }

    // ---- atual ----
    Component {
        id: plainC
        Item {
            // 1x1: cracha com a faixa colorida (MES + dia da semana) e o dia grande
            Item {
                visible: w.cols === 1
                anchors.fill: parent
                Rectangle {
                    id: band
                    width: parent.width; height: parent.height * 0.36
                    color: w.ac
                    topLeftRadius: w.bare ? 18 : 0; topRightRadius: w.bare ? 18 : 0
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        UiText { text: w.today.toLocaleDateString(w.loc, "MMM").replace(".", "").toUpperCase(); color: Theme.accentText; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 1; font.features: { "tnum": 1 } }
                        UiText { text: w.today.toLocaleDateString(w.loc, "ddd").replace(".", "").toUpperCase(); color: Qt.rgba(Theme.accentText.r, Theme.accentText.g, Theme.accentText.b, 0.7); font.pixelSize: 15; font.weight: Font.DemiBold; font.letterSpacing: 1; font.features: { "tnum": 1 } }
                    }
                }
                UiText {
                    anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: band.height / 2 }
                    text: w.today.getDate(); color: w.fg; font.pixelSize: Math.min(60, (parent.height - band.height) * 0.9); font.weight: Font.Bold
                }
            }

            // 2x1: semana
            Column {
                visible: w.cols > 1 && w.rows === 1
                anchors.fill: parent
                spacing: 10
                Rectangle {
                    height: 28; width: ptxt.implicitWidth + 28; radius: 14
                    color: w.ac
                    UiText { id: ptxt; anchors.centerIn: parent; text: w.cap(w.today.toLocaleDateString(w.loc, "MMMM yyyy")) + (w.o("weekNumbers") ? "  ·  semana " + w.isoWeek(w.today) : ""); color: Theme.accentText; font.pixelSize: 14; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                }
                Row {
                    width: parent.width
                    readonly property real cw: width / 7
                    Repeater {
                        model: 7
                        delegate: Column {
                            required property int index
                            readonly property date d: new Date(w.today.getFullYear(), w.today.getMonth(), w.today.getDate() - ((w.today.getDay() - w.ws + 7) % 7) + index)
                            readonly property bool isToday: d.toDateString() === w.today.toDateString()
                            width: parent.cw
                            spacing: 6
                            UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.wd[index]; color: w.dim; font.pixelSize: 11; font.weight: Font.DemiBold }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 32; height: 32; radius: 16
                                color: parent.isToday ? w.ac : "transparent"
                                UiText { anchors.centerIn: parent; text: parent.parent.d.getDate(); color: parent.parent.isToday ? Theme.accentText : w.dayCol(parent.parent.d, true); font.pixelSize: 14; font.weight: parent.parent.isToday ? Font.Bold : Font.Medium }
                            }
                        }
                    }
                }
            }

            // painel lateral (3x2 ou maior): icone em gema, mes, dia da semana e o dia grande
            Column {
                id: side
                readonly property bool on: w.cols >= 3 && w.rows >= 2
                visible: on
                width: 104
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 2
                ShapeIcon { shape: "gem"; icon: "calendar"; size: 46; padding: 11; color: w.ac; iconColor: Theme.accentText }
                Item { width: 1; height: 6 }
                UiText { text: w.today.toLocaleDateString(w.loc, "MMMM").toUpperCase(); color: w.dim; font.pixelSize: 12; font.weight: Font.DemiBold; font.letterSpacing: 1; font.features: { "tnum": 1 } }
                UiText { text: w.cap(w.today.toLocaleDateString(w.loc, "dddd")); color: w.fg; font.pixelSize: 17; font.weight: Font.Medium; font.features: { "tnum": 1 } }
                UiText { text: w.today.getDate(); color: w.ac; font.pixelSize: 58; font.weight: Font.Bold; lineHeight: 0.9 }
            }

            // mes
            Item {
                visible: w.rows > 1
                anchors { fill: parent; leftMargin: side.on ? side.width + 12 : 0 }
                Item {
                    id: head
                    width: parent.width; height: 30
                    UiText { anchors.verticalCenter: parent.verticalCenter; text: w.cap(w.month.toLocaleDateString(w.loc, "MMMM")) + (w.month.getFullYear() !== w.today.getFullYear() ? " " + w.month.getFullYear() : ""); color: w.fg; font.pixelSize: 17; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 2
                        Repeater {
                            model: [["chevLeft", -1], ["chevRight", 1]]
                            delegate: Rectangle {
                                required property var modelData
                                width: 26; height: 26; radius: 13
                                color: nm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12) : "transparent"
                                UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 16; color: w.dim }
                                MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.shift += modelData[1] }
                            }
                        }
                    }
                    MouseArea { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 140; onClicked: w.shift = 0 }
                }
                Grid {
                    id: grid
                    anchors { top: head.bottom; topMargin: 6; left: parent.left; right: parent.right; bottom: parent.bottom }
                    readonly property bool wn: w.o("weekNumbers")
                    columns: wn ? 8 : 7
                    readonly property real cw: width / columns
                    readonly property real ch: height / 7
                    readonly property int lead: (w.month.getDay() - w.ws + 7) % 7
                    Repeater {
                        model: grid.columns
                        delegate: Item { required property int index; width: grid.cw; height: grid.ch
                            UiText { anchors.centerIn: parent; text: grid.wn ? (index === 0 ? "#" : w.wd[index - 1]) : w.wd[index]; color: w.dim; font.pixelSize: 11; font.weight: Font.DemiBold } }
                    }
                    Repeater {
                        model: 6 * grid.columns
                        delegate: Item {
                            required property int index
                            readonly property int col: index % grid.columns
                            readonly property int row: Math.floor(index / grid.columns)
                            readonly property bool isWn: grid.wn && col === 0
                            readonly property int di: row * 7 + (grid.wn ? col - 1 : col)
                            readonly property date d: new Date(w.month.getFullYear(), w.month.getMonth(), di - grid.lead + 1)
                            readonly property bool inMonth: d.getMonth() === w.month.getMonth()
                            readonly property bool isToday: d.toDateString() === w.today.toDateString()
                            width: grid.cw; height: grid.ch
                            Rectangle {
                                visible: !parent.isWn
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 4; height: width; radius: width / 2
                                color: parent.isToday ? w.ac : "transparent"
                            }
                            UiText {
                                anchors.centerIn: parent
                                text: parent.isWn ? w.isoWeek(new Date(w.month.getFullYear(), w.month.getMonth(), parent.row * 7 - grid.lead + 4)) : parent.d.getDate()
                                font.pixelSize: parent.isWn ? 10 : 12; font.weight: parent.isToday ? Font.Bold : Font.Normal
                                color: parent.isWn ? w.dim : parent.isToday ? Theme.accentText : w.dayCol(parent.d, parent.inMonth)
                            }
                        }
                    }
                }
            }
        }
    }
}
