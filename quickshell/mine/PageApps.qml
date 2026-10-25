// Pagina "Aplicativos" (kit Set*): resumo e atualizar tudo, instalados (busca, detalhes, remover), instalar (repositorio, AUR,
// Flatpak), programas ao iniciar, aplicativos padrao e webapps. Estado e comandos em Apps.qml; so roda com a pagina aberta.
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Aplicativos"
    subtitle: "Instalar, remover, atualizar e escolher o que abre ao iniciar"
    Component.onCompleted: { Apps.use(); Apps.loadStartup(); Webapps.refresh() }
    Component.onDestruction: Apps.release()

    function fmtSize(b) {
        if (!b) return ""
        const u = ["B", "kB", "MB", "GB"]
        let i = 0, v = b
        while (v >= 1000 && i < 3) { v /= 1000; i++ }
        return (i >= 2 ? v.toFixed(1) : Math.round(v)) + " " + u[i]
    }
    function srcLabel(s) { return s === "pacman" ? "Pacman" : s === "aur" ? "AUR" : s === "flatpak" ? "Flatpak" : "Manual" }

    // selo da origem (Pacman / AUR / Flatpak / Manual)
    component Badge: Rectangle {
        id: bd
        property string src
        width: bt.implicitWidth + 12; height: 18; radius: 9
        color: src === "pacman" ? Theme.tint(0.16) : src === "aur" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.16) : Theme.track
        border.width: src === "local" ? 1 : 0; border.color: Theme.border
        UiText { id: bt; anchors.centerIn: parent; text: page.srcLabel(bd.src); font.pixelSize: 10; font.weight: Font.Bold
            color: bd.src === "pacman" ? Theme.accent : bd.src === "aur" ? Theme.danger : Theme.muted }
    }

    // ---- resumo ----
    SetSection {
        title: "Resumo"; icon: "apps"
        SetRow {
            icon: "package"
            label: Apps.loaded ? Apps.apps.length + " aplicativos instalados" : "Lendo os aplicativos…"
            description: {
                const u = SystemGuard.updates
                const p = Apps.pkgs > 0 ? Apps.pkgs + " pacotes · " : ""
                return p + (SystemGuard.checking ? "verificando atualizações…" : u < 0 ? "atualizações: sem checkupdates" : u === 0 ? "tudo em dia" : u + (u === 1 ? " atualização pendente" : " atualizações pendentes"))
            }
            UiButton { text: "Verificar"; kind: "ghost"; enabled: !SystemGuard.checking; onClicked: SystemGuard.checkUpdates() }
            UiButton { icon: "download"; text: "Atualizar tudo"; kind: "accent"; onClicked: Apps.updateAll() }
        }
        SetRow { visible: Apps.dry; icon: "info"; label: "Modo de teste"; description: "Nenhum comando é executado de verdade; só aparece o que rodaria" }
    }

    // ---- tarefa em andamento ----
    SetSection {
        visible: Apps.jobState !== ""
        title: ""
        SetRow {
            icon: Apps.jobState === "ok" ? "check" : Apps.jobState === "err" ? "info" : "refresh"
            label: Apps.jobTitle + (Apps.jobState === "run" ? "…" : Apps.jobState === "ok" ? ": pronto" : ": não deu")
            description: Apps.jobState === "run" ? "Se pedir a senha, a janela aparece pelo shell" : Apps.jobState === "ok" ? "A lista foi atualizada" : "Veja a mensagem abaixo"
            UiButton { visible: Apps.jobState !== "run"; text: "Fechar"; kind: "ghost"; onClicked: Apps.closeJob() }
        }
        SetBlock {
            visible: Apps.jobLog !== ""
            UiText { width: parent.width; wrapMode: Text.WrapAnywhere; text: Apps.jobLog; color: Apps.jobState === "err" ? Theme.danger : Theme.muted; font.pixelSize: 11; font.family: Settings.fontMono || "monospace" }
        }
    }

    // ---- instalados ----
    SetSection {
        title: "Instalados"; icon: "package"
        subtitle: "Os aplicativos do launcher; clique para ver os detalhes ou remover"
        SetBlock {
            id: instBlk
            property string q: ""
            readonly property var shown: {
                const s = q.toLowerCase()
                return !s ? Apps.apps : Apps.apps.filter(a => (a.name + " " + a.pkg + " " + a.id).toLowerCase().includes(s))
            }
            UiField { id: instF; width: parent.width; placeholderText: "Buscar entre os instalados…"; onTextChanged: instT.restart() }
            Timer { id: instT; interval: 120; onTriggered: { instBlk.q = instF.text.trim(); Apps.selected = "" } }
            UiText { visible: !Apps.loaded; text: "Lendo os aplicativos…"; color: Theme.muted; font.pixelSize: SetK.fDesc }
            UiText { visible: Apps.loaded && instBlk.shown.length === 0; text: "Nenhum aplicativo encontrado."; color: Theme.muted; font.pixelSize: SetK.fDesc }
            ListView {
                id: lv
                width: parent.width
                height: Math.min(contentHeight, 440)
                visible: instBlk.shown.length > 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                cacheBuffer: 200
                model: instBlk.shown
                delegate: Item {
                    id: d
                    required property var modelData
                    readonly property bool open: Apps.selected === modelData.id
                    width: lv.width
                    height: 52 + (open ? det.height : 0)
                    Rectangle {
                        width: parent.width; height: 52; radius: SetK.innerRadius
                        color: hv.hovered || d.open ? Theme.cardHi : "transparent"
                        opacity: 1
                        HoverHandler { id: hv }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Apps.selected = d.open ? "" : d.modelData.id }
                        Image {
                            id: ic
                            x: 8; anchors.verticalCenter: parent.verticalCenter
                            width: 32; height: 32
                            sourceSize: Qt.size(64, 64)
                            asynchronous: true; smooth: true; fillMode: Image.PreserveAspectFit
                            source: Icons.path(d.modelData.icon, "application-x-executable")
                        }
                        Column {
                            anchors { left: ic.right; leftMargin: SetK.md; right: meta.left; rightMargin: SetK.md; verticalCenter: parent.verticalCenter }
                            spacing: 2
                            UiText { width: parent.width; elide: Text.ElideRight; text: d.modelData.name; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium }
                            UiText { width: parent.width; elide: Text.ElideRight; text: d.modelData.desc || d.modelData.pkg; color: Theme.muted; font.pixelSize: SetK.fDesc }
                        }
                        Row {
                            id: meta
                            anchors { right: parent.right; rightMargin: SetK.sm; verticalCenter: parent.verticalCenter }
                            spacing: SetK.sm
                            UiText { visible: d.modelData.size > 0 || !!d.modelData.sizeText; anchors.verticalCenter: parent.verticalCenter; text: d.modelData.size > 0 ? page.fmtSize(d.modelData.size) : (d.modelData.sizeText || ""); color: Theme.muted; font.pixelSize: SetK.fDesc }
                            Badge { anchors.verticalCenter: parent.verticalCenter; src: d.modelData.src }
                            UiIcon { anchors.verticalCenter: parent.verticalCenter; name: "chevDown"; size: 18; color: Theme.muted; rotation: d.open ? 180 : 0 }
                        }
                    }
                    // detalhes: so existem com a linha aberta
                    Loader {
                        id: det
                        y: 52
                        width: parent.width
                        active: d.open
                        sourceComponent: Column {
                            id: dc
                            property bool confirm: false
                            readonly property var a: d.modelData
                            width: det.width
                            spacing: SetK.sm
                            topPadding: SetK.xs; bottomPadding: SetK.sm
                            Grid {
                                x: 8 + 32 + SetK.md
                                columns: 2; columnSpacing: SetK.lg; rowSpacing: 2
                                UiText { text: "Pacote"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                                UiText { text: dc.a.pkg || "não é de um pacote (instalado à mão)"; color: Theme.text; font.pixelSize: SetK.fDesc }
                                UiText { visible: dc.a.version !== ""; text: "Versão"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                                UiText { visible: dc.a.version !== ""; text: dc.a.version; color: Theme.text; font.pixelSize: SetK.fDesc }
                                UiText { visible: dc.a.size > 0 || !!dc.a.sizeText; text: "Tamanho"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                                UiText { visible: dc.a.size > 0 || !!dc.a.sizeText; text: dc.a.size > 0 ? page.fmtSize(dc.a.size) : (dc.a.sizeText || ""); color: Theme.text; font.pixelSize: SetK.fDesc }
                            }
                            Row {
                                x: 8 + 32 + SetK.md
                                spacing: SetK.sm
                                UiButton { icon: "play"; text: "Abrir"; kind: "accent"; onClicked: Quickshell.execDetached(["gtk-launch", dc.a.id.replace(/\.desktop$/, "")]) }
                                UiButton { visible: dc.a.pkg !== "" && !dc.confirm; icon: "trash"; text: "Desinstalar"; kind: "danger"; enabled: !Apps.busy; onClicked: dc.confirm = true }
                            }
                            Rectangle {
                                visible: dc.confirm
                                x: 8 + 32 + SetK.md
                                width: parent.width - x - SetK.sm
                                height: cf.implicitHeight + SetK.lg
                                radius: SetK.innerRadius
                                color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.1)
                                border.width: 1; border.color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.4)
                                Column {
                                    id: cf
                                    x: SetK.md; y: SetK.md - 2
                                    width: parent.width - SetK.md * 2
                                    spacing: SetK.sm
                                    UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.text; font.pixelSize: SetK.fDesc
                                        text: "Remover " + dc.a.name + "? " + (dc.a.src === "flatpak" ? "O Flatpak sai do computador." : "Sai o pacote " + dc.a.pkg + " e as dependências que mais ninguém usa. Se outro programa precisar dele, o pacman recusa e a mensagem aparece aqui em cima.") }
                                    Row {
                                        spacing: SetK.sm
                                        UiButton { text: "Cancelar"; kind: "ghost"; onClicked: dc.confirm = false }
                                        UiButton { icon: "trash"; text: "Remover"; kind: "danger"; enabled: !Apps.busy; onClicked: { dc.confirm = false; Apps.selected = ""; Apps.uninstall(dc.a) } }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- instalar ----
    SetSection {
        title: "Instalar"; icon: "download"
        subtitle: "Busca nos repositórios do Arch, no AUR" + (Apps.hasFlatpak ? " e no Flathub" : "")
        SetBlock {
            id: insBlk
            UiField { id: insF; width: parent.width; placeholderText: "Buscar um programa para instalar…"; onTextChanged: Apps.search(text) }
            UiText {
                visible: Apps.query.length < 2
                width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc
                text: "Digite pelo menos 2 letras. Do repositório instala direto (pede a senha); do AUR abre um terminal para você revisar" + (Apps.helper === "" ? " (precisa do paru ou do yay, que não estão instalados)." : " com o " + Apps.helper + ".")
            }
            UiText {
                visible: Apps.query.length >= 2 && (Apps.searching || Apps.results.length === 0 || Apps.aurErr !== "")
                width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc
                text: (Apps.searching ? "Buscando…" : Apps.results.length === 0 ? "Nada encontrado." : "") + (Apps.aurErr !== "" ? " " + Apps.aurErr + "." : "")
            }
            ListView {
                id: rv
                width: parent.width
                height: Math.min(contentHeight, 420)
                visible: Apps.query.length >= 2 && Apps.results.length > 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                cacheBuffer: 200
                model: Apps.results
                delegate: Item {
                    id: r
                    required property var modelData
                    readonly property bool needHelper: modelData.src === "aur" && Apps.helper === ""
                    width: rv.width; height: 62
                    Rectangle { visible: r.modelData && rv.contentY >= 0; width: parent.width - 16; x: 8; y: 0; height: 1; color: Theme.border; opacity: 0.45 }
                    Column {
                        anchors { left: parent.left; leftMargin: 8; right: act.left; rightMargin: SetK.md; verticalCenter: parent.verticalCenter }
                        spacing: 3
                        Row {
                            spacing: SetK.sm
                            UiText { text: r.modelData.name; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium }
                            Badge { anchors.verticalCenter: parent.verticalCenter; src: r.modelData.src }
                            UiText { anchors.verticalCenter: parent.verticalCenter; text: r.modelData.version; color: Theme.muted; font.pixelSize: 11 }
                        }
                        UiText { width: parent.width; elide: Text.ElideRight; text: r.modelData.desc; color: Theme.muted; font.pixelSize: SetK.fDesc }
                    }
                    Item {
                        id: act
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 104; height: 34
                        UiButton { visible: !r.modelData.installed; anchors.right: parent.right; icon: "download"; text: "Instalar"; kind: "accent"
                            enabled: !Apps.busy && !r.needHelper; onClicked: Apps.install(r.modelData) }
                        Row { visible: r.modelData.installed; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                            UiIcon { name: "check"; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            UiText { text: "Instalado"; color: Theme.accent; font.pixelSize: SetK.fDesc; anchors.verticalCenter: parent.verticalCenter } }
                    }
                }
            }
            UiText {
                visible: Apps.query.length >= 2 && Apps.aur.length > 0 && Apps.helper === ""
                width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc
                text: "Para instalar do AUR é preciso o paru ou o yay. Instale um deles pelo repositório ou pelo AUR (git clone + makepkg -si) e volte aqui."
            }
        }
    }

    // ---- ao iniciar ----
    SetSection {
        title: "Ao iniciar"; icon: "rocket"
        subtitle: "Comandos do Hyprland e programas da pasta autostart que abrem ao entrar na sessão"
        Repeater {
            model: Settings.list(Settings.hyprAutostart)
            delegate: SetRow {
                required property string modelData
                required property int index
                icon: "play"; label: modelData
                UiButton { icon: "trash"; kind: "danger"; onClicked: { const l = Settings.list(Settings.hyprAutostart); l.splice(index, 1); Settings.hyprAutostart = l } }
            }
        }
        SetRow {
            icon: "plus"; label: "Novo comando"
            UiField { id: asF; width: 260; placeholderText: "ex.: discord --start-minimized"; onAccepted: asB.clicked() }
            UiButton { id: asB; icon: "plus"; text: "Adicionar"; kind: "accent"; onClicked: { const c = asF.text.trim(); if (!c) return; Settings.hyprAutostart = (Settings.list(Settings.hyprAutostart)).concat([c]); asF.text = "" } }
        }
        Repeater {
            model: Apps.startup.filter(s => !s.system)
            delegate: SetRow {
                required property var modelData
                icon: "rocket"; label: modelData.name; description: modelData.comment || modelData.exec
                checked: modelData.enabled
                onToggled: on => Apps.setStartup(modelData.file, on)
            }
        }
        SetExpander {
            icon: "cog"; label: "Do sistema"; description: "Só leitura: vêm de /etc/xdg/autostart, são de pacotes"
            lazy: Component {
                SetBlock {
                    sub: true
                    Repeater {
                        model: Apps.startup.filter(s => s.system)
                        delegate: Column {
                            required property var modelData
                            width: parent.width
                            spacing: 1
                            UiText { width: parent.width; elide: Text.ElideRight; text: modelData.name; color: Theme.text; font.pixelSize: 13 }
                            UiText { width: parent.width; elide: Text.ElideRight; text: modelData.exec; color: Theme.muted; font.pixelSize: 11 }
                        }
                    }
                }
            }
        }
    }

    // ---- apps padrao ----
    SetSection {
        title: "Aplicativos padrão"; icon: "apps"
        subtitle: "O que abre ao configurar rede, Bluetooth, volume etc.; vazio usa o padrão mostrado"
        Repeater {
            model: AppCmds.items
            delegate: SetRow {
                id: ar
                required property var modelData
                icon: modelData.icon; label: modelData.label
                UiField {
                    width: 240
                    text: (Settings.appCmds || ({}))[ar.modelData.id] || ""
                    placeholderText: ar.modelData.def
                    onAccepted: AppCmds.set(ar.modelData.id, text)
                    onEditingFinished: AppCmds.set(ar.modelData.id, text)
                }
            }
        }
    }

    // ---- webapps ----
    SetSection {
        title: "Webapps"; icon: "web"
        subtitle: "Cada site vira um aplicativo sem abas, também no launcher"
        Repeater {
            model: Webapps.apps
            delegate: SetRow {
                id: wr
                required property var modelData
                icon: "web"; label: modelData.name; description: modelData.url
                UiButton { icon: "play"; kind: "ghost"; onClicked: Quickshell.execDetached(["gtk-launch", "shell-webapp-" + wr.modelData.id]) }
                UiButton { icon: "trash"; kind: "danger"; onClicked: Webapps.remove(wr.modelData.id) }
            }
        }
        SetRow {
            icon: "plus"; label: "Novo webapp"; description: Webapps.msg !== "" ? Webapps.msg : (Webapps.apps.length === 0 ? "Nenhum ainda; separe vários endereços por espaço" : "Separe vários endereços por espaço")
            UiField { id: waF; width: 220; placeholderText: "web.whatsapp.com"; onAccepted: waB.clicked() }
            UiButton { id: waB; icon: "plus"; text: Webapps.busy ? "Criando…" : "Criar"; kind: "accent"; enabled: !Webapps.busy; onClicked: { Webapps.add(waF.text); waF.text = "" } }
        }
    }
}
