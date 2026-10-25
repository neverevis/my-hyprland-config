// Pagina "Data, hora e idioma" (kit Set*): hora e data de agora, formato da hora e da data (veio de Energia e sessao, mesmas
// chaves), fuso horario (lista de timedatectl com busca; aplicar pede confirmacao e a senha de administrador por pkexec),
// sincronizacao automatica (NTP), teclado (link para Mouse e teclado) e idioma do sistema (so leitura, localectl).
// Leituras so com a pagina visivel. Modo de teste (SysAct.dry): fuso e NTP rodam como echo, nunca mudam o sistema.
import Quickshell
import Quickshell.Io
import QtQuick

SetPage {
    id: page
    title: "Data, hora e idioma"
    subtitle: "Formato do relógio, fuso horário, sincronização e idioma do sistema"
    readonly property bool live: visible && Settings.settingsOpen
    onLiveChanged: if (live) { SysAct.check(); readStatus(); if (zones.length === 0 && !zoneP.running) zoneP.running = true; if (!locP.running) locP.running = true }

    property string tz: ""
    property bool ntp: false
    property bool ntpSync: false
    property bool canNtp: true
    property var zones: []
    property string pendingZone: ""      // fuso esperando a confirmacao
    property var loc: ({})               // chaves do localectl
    property bool zonesDone: false
    function readStatus() { if (!statP.running) statP.running = true }
    Process {
        id: statP
        command: ["timedatectl", "show"]
        stdout: StdioCollector { onStreamFinished: {
            const m = {}
            text.trim().split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) m[l.slice(0, i)] = l.slice(i + 1) })
            page.tz = m.Timezone || ""; page.ntp = m.NTP === "yes"; page.ntpSync = m.NTPSynchronized === "yes"; page.canNtp = m.CanNTP !== "no"
        } }
    }
    Process {
        id: zoneP
        command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector { onStreamFinished: { page.zones = text.trim().split("\n").filter(z => z !== ""); page.zonesDone = true } }
    }
    Process {
        id: locP
        command: ["localectl", "status"]
        stdout: StdioCollector { onStreamFinished: {
            const m = {}
            text.trim().split("\n").forEach(l => { const i = l.indexOf(":"); if (i > 0) m[l.slice(0, i).trim()] = l.slice(i + 1).trim() })
            page.loc = m
        } }
    }
    function validZone(z) { return /^[A-Za-z0-9_+\/-]+$/.test(z) }
    function applyZone(z) {
        if (!validZone(z)) return
        SysAct.runJob("Fuso horário", ["pkexec", "timedatectl", "set-timezone", z], ok => { if (ok) page.readStatus() })
    }
    function setNtp(on) { SysAct.runJob("Sincronização automática", ["pkexec", "timedatectl", "set-ntp", on ? "true" : "false"], ok => page.readStatus()) }

    // ---- previa: hora e data de agora ----
    preview: SetPreview {
        height: 110
        SystemClock { id: clk; enabled: page.live; precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }
        Row {
            anchors.centerIn: parent
            spacing: SetK.lg
            UiText { anchors.verticalCenter: parent.verticalCenter; text: DateTime.time(clk.date); color: Theme.text; font.pixelSize: 40; font.weight: Font.Bold; font.features: { "tnum": 1 } }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                UiText { text: DateTime.date(clk.date); color: Theme.text; font.pixelSize: 15 }
                UiText { text: DateTime.dateYear(clk.date); color: Theme.muted; font.pixelSize: 12 }
                UiText { text: page.tz; color: Theme.muted; font.pixelSize: 12 }
            }
        }
    }

    // ---- tarefa com senha em andamento ----
    SetSection {
        visible: SysAct.jobState !== ""
        title: ""
        SetRow {
            icon: SysAct.jobState === "ok" ? "check" : SysAct.jobState === "err" ? "info" : "refresh"
            label: SysAct.jobTitle + (SysAct.jobState === "run" ? "…" : SysAct.jobState === "ok" ? ": pronto" : ": não deu")
            description: SysAct.jobState === "run" ? "Se pedir a senha, a janela aparece pelo shell" : SysAct.jobState === "ok" ? "Já vale para o sistema" : SysAct.jobFriendly !== "" ? SysAct.jobFriendly : "Veja a mensagem abaixo"
            UiButton { visible: SysAct.jobState === "err" && SysAct.retry !== null; icon: "refresh"; text: "Tentar de novo"; kind: "ghost"; onClicked: SysAct.retryJob() }
            UiButton { visible: SysAct.jobState !== "run"; text: "Fechar"; kind: "ghost"; onClicked: SysAct.closeJob() }
        }
        SetBlock {
            visible: SysAct.jobLog !== ""
            UiText { width: parent.width; wrapMode: Text.WrapAnywhere; text: SysAct.jobLog; color: Theme.muted; font.pixelSize: 11; font.family: Settings.fontMono || "monospace" }
        }
    }

    // ---- hora e data (veio de Energia e sessao; mesmas chaves) ----
    SetSection {
        title: "Hora e data"; icon: "clock"
        subtitle: "Relógio da barra, da ilha, do bloqueio e dos detalhes (os widgets têm opção própria)"
        SetChoice {
            icon: "clockOutline"; label: "Formato"
            options: [["24", "24 horas", "clock"], ["ap", "12 h (am/pm)", "clockOutline"], ["AP", "12 h (AM/PM)", "clockOutline"]]
            value: Settings.clock24 ? "24" : Settings.clockAmPm
            onPicked: v => { if (v === "24") Settings.clock24 = true; else { Settings.clock24 = false; Settings.clockAmPm = v } }
        }
        SetRow { icon: "timer"; label: "Mostrar segundos"; description: "Na barra e na ilha (o bloqueio tem a sua opção)"; checked: Settings.clockSeconds; onToggled: on => Settings.clockSeconds = on }
        SetExpander {
            icon: "calendar"; label: "Formatos de data"; description: "Letras do Qt: d dd ddd dddd, M MM MMM MMMM, yy yyyy"
            SetRow { sub: true; label: "Data curta"; UiField { width: 220; placeholderText: "ddd, dd/MM"; text: Settings.dateFormat; onEditingFinished: Settings.dateFormat = text } }
            SetRow { sub: true; label: "Data longa"; description: "Vazio = padrão"; UiField { width: 220; placeholderText: "dddd, d 'de' MMMM"; text: Settings.dateLongFormat; onEditingFinished: Settings.dateLongFormat = text } }
            SetRow { sub: true; label: "Data com ano"; UiField { width: 220; placeholderText: "dd/MM/yyyy"; text: Settings.dateYearFormat; onEditingFinished: Settings.dateYearFormat = text } }
        }
    }

    // ---- fuso e sincronizacao ----
    SetSection {
        title: "Fuso horário e sincronização"; icon: "web"
        subtitle: page.tz !== "" ? "Fuso atual: " + page.tz : "Lendo o fuso…"
        SetRow {
            icon: "refresh"; label: "Acertar o relógio pela internet"
            description: !page.canNtp ? "Sem serviço de hora (systemd-timesyncd ou chrony)" : page.ntp ? (page.ntpSync ? "Ligado e sincronizado" : "Ligado, ainda sincronizando") : "Desligado: a hora fica como está"
            checked: page.ntp
            enabled: page.canNtp && !SysAct.busy
            onToggled: on => page.setNtp(on)
        }
        SetRow {
            visible: page.pendingZone !== ""
            icon: "shield"; label: "Mudar o fuso para " + page.pendingZone + "?"
            description: "Muda para o computador inteiro e pede a senha de administrador"
            UiButton { text: "Cancelar"; kind: "ghost"; onClicked: page.pendingZone = "" }
            UiButton { icon: "check"; text: "Mudar fuso"; kind: "accent"; enabled: !SysAct.busy; onClicked: { const z = page.pendingZone; page.pendingZone = ""; page.applyZone(z) } }
        }
        SetBlock {
            id: zb
            property string q: ""
            readonly property var shown: {
                const s = q.toLowerCase().replace(/ /g, "_")
                return !s ? page.zones : page.zones.filter(z => z.toLowerCase().includes(s))
            }
            UiField { id: zf; width: parent.width; placeholderText: "Buscar um fuso (ex.: Sao_Paulo, Lisbon, Tokyo)…"; onTextChanged: zt.restart() }
            Timer { id: zt; interval: 120; onTriggered: zb.q = zf.text.trim() }
            UiText { visible: page.zones.length === 0; text: page.zonesDone ? "Não consegui listar os fusos (falta o timedatectl, do systemd)." : "Lendo os fusos…"; color: Theme.muted; font.pixelSize: SetK.fDesc }
            UiButton { visible: page.zones.length === 0 && page.zonesDone; text: "Tentar de novo"; kind: "ghost"; onClicked: { page.zonesDone = false; zoneP.running = true } }
            UiText { visible: page.zones.length > 0 && zb.shown.length === 0; text: "Nada encontrado para “" + zb.q + "”. Tente a cidade em inglês, como Sao_Paulo."; color: Theme.muted; font.pixelSize: SetK.fDesc }
            ListView {
                id: zl
                width: parent.width
                height: Math.min(contentHeight, 280)
                visible: zb.shown.length > 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                cacheBuffer: 200
                model: zb.shown
                delegate: Rectangle {
                    id: zr
                    required property string modelData
                    readonly property bool cur: modelData === page.tz
                    width: zl.width; height: 38; radius: SetK.innerRadius
                    color: cur ? Theme.tint(0.16) : (zh.hovered ? Theme.cardHi : "transparent")
                    HoverHandler { id: zh }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !zr.cur; onClicked: page.pendingZone = zr.modelData }
                    UiText { anchors { left: parent.left; leftMargin: SetK.md; right: ck.left; rightMargin: SetK.sm; verticalCenter: parent.verticalCenter } elide: Text.ElideRight; text: zr.modelData.replace(/_/g, " "); color: zr.cur ? Theme.accent : Theme.text; font.pixelSize: SetK.fRow }
                    UiIcon { id: ck; visible: zr.cur; anchors { right: parent.right; rightMargin: SetK.md; verticalCenter: parent.verticalCenter } name: "check"; size: 16; color: Theme.accent }
                }
            }
        }
    }

    // ---- teclado e idioma ----
    SetSection {
        title: "Teclado e idioma"; icon: "keyboard"
        subtitle: "O layout do teclado fica em Mouse e teclado; o idioma do sistema é só leitura"
        SetRow { icon: "keyboard"; label: "Layouts do teclado"; description: "Layout, variante e troca de layout"; link: true; onClicked: { Settings.settingsReveal = "Teclado"; Settings.settingsPage = "input" } }
        SetRow { icon: "web"; label: "Idioma do sistema"; description: page.loc["System Locale"] || "—" }
        SetRow { icon: "keyboard"; label: "Teclado do console"; description: page.loc["VC Keymap"] || "—" }
        SetRow {
            icon: "keyboard"; label: "Teclado gráfico (X11 / Wayland)"
            description: page.loc["X11 Layout"] ? page.loc["X11 Layout"] + (page.loc["X11 Variant"] ? " · " + page.loc["X11 Variant"] : "") + (page.loc["X11 Model"] ? " · modelo " + page.loc["X11 Model"] : "") : "—"
        }
    }
}
