// Widget do usuario: foto (circulo, flor ou arredondada), saudacao, nome e uma linha de informacao (tempo ligado,
// usuario@maquina ou sistema e kernel). 1x1: foto e saudacao; 3x1: tambem a hora e a data; 2x2: tudo empilhado.
// Composicoes (opcao "look"): coluna (a de sempre), caixa (a 2x2 do end4: caixa interna com a foto montada na borda), capa
// (banner em cima com degrade), so a foto e faixa. Cada uma e um Component num Loader: so a ativa existe.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

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
    property var comp: ({})                       // composicao vinda do cartao (caixas internas, selos, destaque, raio)
    property rect deskRect: Qt.rect(0, 0, 0, 0)   // lugar do cartao na area (para a capa mostrar o pedaco do wallpaper de tras)
    function o(k) { return DeskState.opt({ type: "user", opts: w.opts }, k) }
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property string greet: { const h = clk.date.getHours(); return h < 5 ? "Boa noite" : h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite" }
    property string up: ""
    property int upD: 0
    property int upH: 0
    property int upM: 0
    Component.onCompleted: Weather.use()
    // frase do tempo (pt-BR) a partir do codigo WMO
    readonly property string quip: {
        if (!Weather.ready || Weather.now.code === undefined) return ""
        const c = Number(Weather.now.code)
        return c === 0 ? "dia bom para sair" : c <= 3 ? "um pouco nublado" : c <= 48 ? "neblina por aí" : c <= 67 || (c >= 80 && c <= 82) ? "chovendo, hora do café"
            : c <= 77 || c <= 86 ? "nevando por aí" : "tempestade, melhor ficar em casa"
    }
    property string kernel: ""
    property string host: ""
    FileView { id: upf; path: "/proc/uptime"; onLoaded: {
        const s = parseFloat(text().split(" ")[0]) || 0, h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        w.upD = Math.floor(h / 24); w.upH = h % 24; w.upM = m
        w.up = h > 0 ? h + " h " + m + " min" : m + " min" } }
    property string distro: "Linux"
    FileView { path: "/etc/os-release"; onLoaded: { const m = text().match(/^PRETTY_NAME="?([^"\n]*)"?/m); if (m) w.distro = m[1] } }
    FileView { path: "/proc/sys/kernel/osrelease"; onLoaded: w.kernel = text().trim() }
    FileView { path: "/proc/sys/kernel/hostname"; onLoaded: w.host = text().trim() }
    Timer { interval: 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: upf.reload() }
    readonly property string infoText: ({ uptime: "Ligado há " + up, host: Profile.user + "@" + host, kernel: distro + " · " + kernel, none: "" })[o("info")] ?? ""
    readonly property string infoIcon: ({ uptime: "clock", host: "account", kernel: "arch", none: "" })[o("info")] ?? ""

    readonly property bool statsOn: rows > 2 && o("info") === "uptime"
    readonly property bool btnOn: cols > 1 && rows > 1 && o("buttons")
    component Face: Item {
        property real s: 74
        width: s; height: s
        ShapedImage {
            anchors.fill: parent
            shape: w.o("avatarShape"); sides: 10
            source: Profile.face
            sourceSize: Qt.size(256, 256)
        }
        Flower { anchors.fill: parent; shape: w.o("avatarShape"); sides: 10; color: "transparent"; border: w.ac; borderWidth: 2.5 }
    }

    // ---- composicao ----
    readonly property string lk: {
        const l = o("look")
        if (l === "auto") return "column"
        if (l !== "end4") return l
        return cols === 1 && rows === 1 ? "photo" : rows === 1 ? "strip" : cols === 1 ? "photo" : (cols >= 3 || rows >= 3) ? "hero" : "box"
    }
    readonly property real pad: lk === "column" ? -1 : 0       // o DeskView usa como margem do conteudo (-1 = a padrao)
    readonly property real cardR: comp.radius !== undefined ? comp.radius : 20
    readonly property color cardCol: comp.cardBase !== undefined ? comp.cardBase : Theme.bg
    function innerRole(def) { return comp.innerRole && comp.innerRole !== "auto" ? comp.innerRole : def }
    function innerAlpha(def) { return comp.innerAlpha > 0 ? comp.innerAlpha : def }
    function innerRad(def) { return comp.innerRadius > 0 ? comp.innerRadius : def }
    readonly property string hostLine: { const t = Profile.user + "@" + host; return t.length > 22 ? Profile.name : t }
    // frase: do tempo, esperta (avisos nao lidos primeiro), minha ou nenhuma
    readonly property int unread: NotifHistory.unread
    readonly property string quipNow: {
        const q = o("quipSource")
        if (q === "none") return ""
        if (q === "custom") return o("quipText")
        if (q === "smart" && unread > 0) return unread === 1 ? "1 aviso não lido" : unread + " avisos não lidos"
        return quip
    }
    readonly property string quipIcon: { const q = o("quipSource"); return q === "custom" ? "quoteClose" : q === "smart" && unread > 0 ? "bell" : Weather.ready ? Weather.icon(Weather.now.code, Weather.now.day) : "" }
    readonly property string dateText: "Hoje • " + clk.date.toLocaleDateString(Qt.locale("pt_BR"), "ddd d MMM")
    Component.onDestruction: Weather.release()

    // foto com aro na cor do cartao (a foto "monta" na borda da caixa)
    component Ring: Item {
        property real s: 74
        property real ringW: 3
        width: s; height: s
        Flower { anchors.fill: parent; shape: w.o("avatarShape"); sides: 10; color: w.cardCol; animated: false }
        ShapedImage {
            x: parent.ringW; y: parent.ringW; width: parent.width - parent.ringW * 2; height: parent.height - parent.ringW * 2
            shape: w.o("avatarShape"); sides: 10; animated: false
            source: Profile.face; sourceSize: Qt.size(256, 256)
        }
    }
    function lockIt() { Power.lock() }
    function cogIt() { Settings.settingsOpen = true }
    function powerIt() { Power.menuOpen = true }

    // capa: wallpaper de tras do cartao, minha foto ou uma imagem; some no fim (mascara com degrade, estatica)
    component Banner: Item {
        id: bn
        readonly property string kind: w.o("banner")
        readonly property bool slice: kind === "wallpaper" && w.deskRect.width > 0
        Item {
            id: bsrc
            width: bn.width; height: bn.height
            Image {
                visible: bn.kind === "wallpaper"
                x: bn.slice ? -w.deskRect.x : 0; y: bn.slice ? -w.deskRect.y : 0
                width: bn.slice ? w.deskRect.width : bn.width; height: bn.slice ? w.deskRect.height : bn.height
                source: bn.kind === "wallpaper" && Wallpaper.still !== "" ? "file://" + Wallpaper.still : ""
                sourceSize: Qt.size(960, 540); fillMode: Image.PreserveAspectCrop; asynchronous: true
            }
            Image {
                visible: bn.kind !== "wallpaper"
                anchors.fill: parent
                source: bn.kind === "profile" ? Profile.face : (w.o("bannerPath") !== "" ? "file://" + w.o("bannerPath") : "")
                sourceSize: Qt.size(640, 640); fillMode: Image.PreserveAspectCrop; asynchronous: true
            }
        }
        Rectangle {
            id: bmask
            width: bn.width; height: bn.height; topLeftRadius: w.cardR; topRightRadius: w.cardR
            gradient: Gradient {
                GradientStop { position: 0; color: "white" }
                GradientStop { position: 0.55; color: "white" }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
        ShaderEffectSource { id: bsTex; sourceItem: bsrc; hideSource: true; live: true }
        ShaderEffectSource { id: bmTex; sourceItem: bmask; hideSource: true; live: true }
        MultiEffect { anchors.fill: parent; source: bsTex; maskEnabled: true; maskSource: bmTex }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: ({ column: colC, box: boxC, hero: heroC, photo: photoC, strip: stripC })[w.lk] ?? colC
    }

    // ---- caixa (end4 2x2) ----
    Component {
        id: boxC
        Item {
            id: bx
            readonly property real u: Math.max(0.3, Math.min(width / 276, height / 252))
            readonly property real boxY: Math.min(80 * u + (height - 252 * u) / 2, height - panel.height - 12 * u)
            Rectangle { visible: !w.bare; anchors.fill: parent; radius: w.cardR; color: Qt.rgba(0, 0, 0, 0.1) }
            DwParts.Panel {
                id: panel
                x: 18 * bx.u; y: bx.boxY
                width: Math.min(240 * bx.u, bx.width - 36 * bx.u)
                height: pc.implicitHeight + 32 * bx.u
                role: w.innerRole("primaryContainer"); alpha: w.innerAlpha(1); radius: w.innerRad(23) * bx.u
                Column {
                    id: pc
                    x: 16 * bx.u; y: 16 * bx.u
                    width: parent.width - 32 * bx.u
                    spacing: 10 * bx.u
                    Item { width: 1; height: 32 * bx.u }
                    Item {
                        visible: w.quipNow !== ""
                        width: parent.width; height: qt.implicitHeight
                        UiIcon { visible: w.quipIcon !== ""; y: 2 * bx.u; name: w.quipIcon; size: Math.round(16 * bx.u); color: panel.ink }
                        UiText { id: qt; x: 22 * bx.u; width: parent.width - 22 * bx.u; text: "• " + w.quipNow; color: Qt.rgba(panel.ink.r, panel.ink.g, panel.ink.b, 0.85); font.pixelSize: Math.round(15 * bx.u); wrapMode: Text.WordWrap }
                    }
                    Row {
                        visible: w.o("buttons")
                        spacing: 8 * bx.u
                        readonly property string st: w.o("buttonStyle")
                        DwParts.Pill { visible: parent.st === "pill"; height: 40 * bx.u; width: pc.width - 96 * bx.u; fs: Math.round(15 * bx.u); text: "Bloquear"; icon: "lock"; fill: panel.ink; ink: panel.base; onClicked: w.lockIt() }
                        DwParts.RoundBtn { visible: parent.st !== "pill"; width: 40 * bx.u; height: width; icon: "lock"; tone: panel.ink; kind: parent.st === "icon" ? "tonal" : "outlined"; onClicked: w.lockIt() }
                        DwParts.RoundBtn { width: 40 * bx.u; height: width; icon: "cog"; tone: panel.ink; kind: parent.st === "icon" ? "tonal" : "outlined"; onClicked: w.cogIt() }
                        DwParts.RoundBtn { width: 40 * bx.u; height: width; icon: "power"; tone: panel.ink; kind: parent.st === "icon" ? "tonal" : "outlined"; onClicked: w.powerIt() }
                    }
                }
            }
            Ring { x: 34 * bx.u; y: bx.boxY - 32 * bx.u; s: 74 * bx.u; ringW: 3 * bx.u; z: 2 }
            Column {
                x: 121 * bx.u; width: bx.width - 121 * bx.u - 14 * bx.u
                y: bx.boxY - 8 * bx.u - height
                UiText { width: parent.width; elide: Text.ElideRight; text: w.hostLine; color: w.fg; font.pixelSize: Math.round(15 * bx.u); font.weight: Font.DemiBold }
                UiText { visible: w.infoText !== ""; width: parent.width; elide: Text.ElideRight; text: w.infoText; color: w.dim; font.pixelSize: Math.round(12 * bx.u) }
            }
        }
    }

    // ---- capa (end4 2x3) ----
    Component {
        id: heroC
        Item {
            id: hr
            readonly property real u: Math.max(0.3, Math.min(width / 420, height / 252))
            readonly property real heroH: height * 0.62
            Banner { width: parent.width; height: hr.heroH }
            DwParts.RoundBtn { x: hr.width - 48 * hr.u; y: 14 * hr.u; width: 34 * hr.u; height: width; kind: "filled"; tone: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.85); icon: "cog"; onClicked: w.cogIt() }
            Ring { id: hav; x: 16 * hr.u; y: hr.heroH - 70 * hr.u; s: 74 * hr.u; ringW: 3 * hr.u; z: 2 }
            UiText { x: 16 * hr.u; y: hav.y + hav.height + 4 * hr.u; width: hr.width - 32 * hr.u; elide: Text.ElideRight; text: w.hostLine; color: w.fg; font.pixelSize: Math.round(16 * hr.u); font.weight: Font.Bold }
            Item {
                x: 16 * hr.u; y: hr.height - 14 * hr.u - height
                width: hr.width - 32 * hr.u; height: Math.max(sts.height, bt.height)
                Row {
                    id: sts
                    visible: w.o("info") === "uptime"
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12 * hr.u
                    Repeater {
                        model: [[w.upD, "dias"], [w.upH, "horas"], [w.upM, "min"]]
                        delegate: Row {
                            required property var modelData
                            required property int index
                            spacing: 12 * hr.u
                            Rectangle { visible: index > 0; width: 1; height: 28 * hr.u; anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.15) }
                            DwParts.Stat { value: String(modelData[0]); label: modelData[1]; ink: w.fg; fs: Math.round(16 * hr.u) }
                        }
                    }
                }
                UiText { visible: w.o("info") !== "uptime" && w.infoText !== ""; anchors.verticalCenter: parent.verticalCenter; text: w.infoText; color: w.dim; font.pixelSize: Math.round(12 * hr.u) }
                Row {
                    id: bt
                    visible: w.o("buttons")
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 8 * hr.u
                    readonly property string st: w.o("buttonStyle")
                    DwParts.Pill { visible: bt.st === "pill"; height: 36 * hr.u; fs: Math.round(14 * hr.u); text: "Bloquear"; icon: "lock"; fill: w.fg; ink: w.cardCol; onClicked: w.lockIt() }
                    DwParts.RoundBtn { visible: bt.st !== "pill"; width: 36 * hr.u; height: width; icon: "lock"; tone: w.fg; kind: bt.st === "icon" ? "tonal" : "outlined"; onClicked: w.lockIt() }
                    DwParts.RoundBtn { width: 36 * hr.u; height: width; icon: "power"; tone: w.fg; kind: bt.st === "icon" ? "tonal" : "outlined"; onClicked: w.powerIt() }
                }
            }
        }
    }

    // ---- so a foto (end4 1x1) ----
    Component {
        id: photoC
        ShapedImage {
            shape: "rounded"; radius: w.cardR; animated: false
            source: Profile.face; sourceSize: Qt.size(512, 512)
        }
    }

    // ---- faixa (end4 1x2): foto quadrada e tres linhas ----
    Component {
        id: stripC
        Item {
            id: sp
            readonly property real u: Math.max(0.3, Math.min(width / 276, height / 120))
            readonly property real sq: height - 20 * u
            DwParts.Panel {
                id: sq
                x: 10 * sp.u; y: 10 * sp.u; width: sp.sq; height: sp.sq
                role: "bg"; alpha: 0.25; radius: 24 * sp.u
                ShapedImage { anchors.fill: parent; shape: "rounded"; radius: sq.radius; animated: false; source: Profile.face; sourceSize: Qt.size(256, 256) }
            }
            Column {
                x: sq.x + sq.width + 12 * sp.u; width: sp.width - x - 10 * sp.u
                y: sp.height - 10 * sp.u - height
                UiText { width: parent.width; elide: Text.ElideRight; text: "Olá, " + Profile.name + "!"; color: w.fg; font.pixelSize: Math.round(16 * sp.u); font.weight: Font.Bold }
                UiText { visible: w.o("greeting"); width: parent.width; elide: Text.ElideRight; text: w.greet; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.8); font.pixelSize: Math.round(13 * sp.u) }
                UiText { width: parent.width; elide: Text.ElideRight; text: w.dateText; color: w.dim; font.pixelSize: Math.round(12 * sp.u) }
            }
        }
    }

    // ---- coluna (a de sempre) ----
    Component {
        id: colC
        Item {
            Column {
                visible: w.cols === 1 || w.rows > 1
                anchors.centerIn: parent
                spacing: 8
                Face { anchors.horizontalCenter: parent.horizontalCenter; s: Math.min(w.width * 0.7, w.height * (w.rows > 2 ? 0.3 : w.btnOn ? 0.32 : w.rows > 1 ? 0.45 : 0.6)) }
                UiText { visible: w.o("greeting"); anchors.horizontalCenter: parent.horizontalCenter; text: w.greet + (w.rows > 1 ? "," : ""); color: w.rows > 1 ? w.dim : w.fg; font.pixelSize: 14; font.weight: Font.Bold }
                UiText { visible: w.rows > 1; anchors.horizontalCenter: parent.horizontalCenter; text: Profile.name; color: w.fg; font.pixelSize: 22; font.weight: Font.Bold }
                UiText { visible: w.cols === 1 && w.rows > 1; anchors.horizontalCenter: parent.horizontalCenter; text: "Hoje • " + clk.date.toLocaleDateString(Qt.locale("pt_BR"), "ddd d MMM"); color: w.dim; font.pixelSize: 12 }
                Row {
                    visible: w.rows > 1 && w.infoText !== "" && !w.statsOn
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    UiIcon { name: w.infoIcon; size: 13; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: w.infoText; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    visible: w.rows > 1 && w.quip !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    UiIcon { name: Weather.icon(Weather.now.code, Weather.now.day); size: 13; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: "• " + w.quip; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
                // tempo ligado em dias / horas / minutos
                Row {
                    visible: w.statsOn
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    Repeater {
                        model: [[w.upD, "dias"], [w.upH, "horas"], [w.upM, "min"]]
                        delegate: Row {
                            required property var modelData
                            required property int index
                            spacing: 12
                            Rectangle { visible: index > 0; width: 1; height: 28; anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.18) }
                            Column {
                                UiText { anchors.horizontalCenter: parent.horizontalCenter; text: String(modelData[0]); color: w.fg; font.pixelSize: 20; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                                UiText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: w.dim; font.pixelSize: 11 }
                            }
                        }
                    }
                }
                // atalhos: bloquear, configuracoes e energia
                Row {
                    visible: w.btnOn
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    UiButton { text: "Bloquear"; icon: "lock"; kind: "accent"; onClicked: Power.lock() }
                    UiButton { icon: "cog"; onClicked: Settings.settingsOpen = true }
                    UiButton { icon: "power"; onClicked: Power.menuOpen = true }
                }
            }
            Row {
                visible: w.cols > 1 && w.rows === 1
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16
                Face { anchors.verticalCenter: parent.verticalCenter; s: Math.min(w.height - 8, 96) }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    UiText { visible: w.o("greeting"); text: w.greet + ","; color: w.dim; font.pixelSize: 14 }
                    UiText { text: Profile.name; color: w.fg; font.pixelSize: 24; font.weight: Font.Bold }
                    Row {
                        visible: w.infoText !== ""
                        spacing: 6
                        UiIcon { name: w.infoIcon; size: 13; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: w.infoText; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
            Column {
                visible: w.cols >= 3 && w.rows === 1
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                UiText { anchors.right: parent.right; text: Qt.formatDateTime(clk.date, "HH:mm"); color: w.fg; font.pixelSize: 34; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                UiText { anchors.right: parent.right; text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "ddd, d MMM"); return s.charAt(0).toUpperCase() + s.slice(1) } color: w.ac; font.pixelSize: 13; font.features: { "tnum": 1 } }
            }
        }
    }
}
