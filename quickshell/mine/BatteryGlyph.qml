// Desenho da bateria em 7 estilos: bar (Android), ios, macos, windows, ring, icon, number.
// pct = 0..1; col = cor do texto; showPct = numero junto/dentro; showBolt = raio ao carregar.
import QtQuick

Item {
    id: g
    property string style: "bar"
    property real pct: 1
    property bool charging: false
    property bool low: false
    property bool critical: false
    property bool showPct: true
    property bool showBolt: true
    property color col: Settings.textColor
    property real s: 16                       // altura base
    // cor do preenchimento: vermelho critico, ambar baixo, verde carregando, senao a cor do texto
    readonly property color fillCol: critical ? Theme.danger : low ? "#e6a23c" : charging ? "#5fbf6a" : col
    readonly property string txt: Math.round(pct * 100) + (style === "number" ? "%" : "")

    implicitWidth: style === "icon" ? ic.implicitWidth : style === "number" ? nt.implicitWidth
        : style === "ring" ? s * 1.3 : body.width + nub.width + (style === "macos" && showPct ? mt.implicitWidth + 4 : 0)
    implicitHeight: style === "icon" ? ic.implicitHeight : style === "number" ? nt.implicitHeight : style === "ring" ? s * 1.3 : s * 0.85

    UiIcon { id: ic; visible: g.style === "icon"; name: g.critical ? "batteryAlert" : g.charging ? "batteryCharging" : "battery"; size: g.s * 1.15; color: g.fillCol }
    UiText { id: nt; visible: g.style === "number"; text: g.txt; color: g.fillCol; font.pixelSize: g.s * 0.85; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }

    // pilha horizontal (bar / ios / macos / windows)
    readonly property bool horiz: style === "bar" || style === "ios" || style === "macos" || style === "windows"
    UiText {   // macos: numero ao lado
        id: mt
        visible: g.style === "macos" && g.showPct
        text: g.txt + "%"; color: g.col; font.pixelSize: g.s * 0.72; font.features: { "tnum": 1 }
        anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
        id: body
        visible: g.horiz
        x: g.style === "macos" && g.showPct ? mt.implicitWidth + 4 : 0
        anchors.verticalCenter: parent.verticalCenter
        width: g.s * (g.style === "windows" ? 1.7 : 1.9); height: g.implicitHeight
        radius: g.style === "bar" ? height * 0.3 : g.style === "windows" ? 2 : height * 0.32
        color: g.style === "bar" ? Qt.rgba(g.col.r, g.col.g, g.col.b, 0.28) : "transparent"
        border.width: g.style === "bar" ? 0 : 1.5; border.color: Qt.rgba(g.col.r, g.col.g, g.col.b, 0.6)
        clip: true
        Rectangle {   // preenchimento (bar / ios / macos)
            visible: g.style !== "windows"
            x: g.style === "bar" ? 0 : 2; y: g.style === "bar" ? 0 : 2
            width: Math.max(g.style === "bar" ? 0 : 0, (parent.width - (g.style === "bar" ? 0 : 4)) * g.pct)
            height: parent.height - (g.style === "bar" ? 0 : 4)
            radius: g.style === "bar" ? parent.radius : Math.max(1, parent.radius - 2)
            color: g.fillCol
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
        Row {   // windows: 4 blocos
            visible: g.style === "windows"
            anchors { fill: parent; margins: 2 }
            spacing: 2
            Repeater {
                model: 4
                Rectangle { required property int index; width: (parent.width - 6) / 4; height: parent.height; radius: 1; color: g.pct > index / 4 + 0.01 ? g.fillCol : "transparent" }
            }
        }
        UiText {   // numero dentro (bar / ios) com contraste simples
            visible: (g.style === "bar" || g.style === "ios") && g.showPct && !(g.showBolt && g.charging)
            anchors.centerIn: parent
            text: g.txt; font.pixelSize: g.s * 0.6; font.weight: Font.Bold; font.features: { "tnum": 1 }
            color: g.style === "bar" ? Settings.barColor : Settings.barColor
            style: Text.Outline; styleColor: Qt.rgba(g.col.r, g.col.g, g.col.b, 0.35)
        }
        UiIcon {
            visible: g.showBolt && g.charging && g.horiz
            anchors.centerIn: parent
            name: "lightning"; size: g.s * 0.8; color: g.style === "windows" ? g.col : Settings.barColor
        }
    }
    Rectangle {   // ponta
        id: nub
        visible: g.horiz
        x: body.x + body.width + 1; anchors.verticalCenter: parent.verticalCenter
        width: 2; height: g.implicitHeight * 0.4; radius: 1
        color: Qt.rgba(g.col.r, g.col.g, g.col.b, 0.6)
    }

    // anel
    Canvas {
        id: cv
        visible: g.style === "ring"
        anchors.fill: parent
        property real v: g.pct
        property color c: g.fillCol
        property color t: Qt.rgba(g.col.r, g.col.g, g.col.b, 0.25)
        onVChanged: requestPaint(); onCChanged: requestPaint(); onTChanged: requestPaint(); onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            const r = Math.min(width, height) / 2 - 2
            ctx.lineWidth = 2.5; ctx.lineCap = "round"
            ctx.strokeStyle = t; ctx.beginPath(); ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2); ctx.stroke()
            ctx.strokeStyle = c; ctx.beginPath(); ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * v); ctx.stroke()
        }
    }
    UiText {
        visible: g.style === "ring" && !(g.showBolt && g.charging)
        anchors.centerIn: parent
        text: g.showPct ? g.txt : ""; color: g.col; font.pixelSize: g.s * 0.45; font.weight: Font.Bold
    }
    UiIcon { visible: g.style === "ring" && g.showBolt && g.charging; anchors.centerIn: parent; name: "lightning"; size: g.s * 0.7; color: g.fillCol }
}
