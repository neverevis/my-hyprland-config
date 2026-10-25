// Janela "Aplicativos" (gerenciador de apps, separada das Configuracoes): Apps, Pacotes, Instalar e Atualizacoes.
// Abra/feche com:  qs -c mine ipc call apps window   |   qs -c mine ipc call apps open pkgs
// Janela normal do Hyprland (FloatingWindow) que so existe aberta (LazyLoader); estado e comandos em Apps.qml.
// Cada aba vive num Loader ativo so quando visivel; listas sao ListView com delegates estaveis.
import Quickshell
import QtQuick

Scope {
    id: root

    LazyLoader {
        active: Apps.windowOpen

        FloatingWindow {
            id: fw
            title: "Aplicativos"
            implicitWidth: 1000
            implicitHeight: 700
            minimumSize: Qt.size(760, 520)
            color: "transparent"   // fundo desenhado no corpo: segue o Vidro (Aparencia), como as Configuracoes
            onClosed: Apps.windowOpen = false
            Component.onCompleted: { Apps.use(); Apps.loadStartup() }
            Component.onDestruction: Apps.release()
            Loader { anchors.fill: parent; sourceComponent: bodyC }
        }
    }

    function fmtSize(b) {
        if (!b) return ""
        const u = ["B", "kB", "MB", "GB"]
        let i = 0, v = b
        while (v >= 1000 && i < 3) { v /= 1000; i++ }
        return (i >= 2 ? v.toFixed(1).replace(".", ",") : Math.round(v)) + " " + u[i]
    }
    // inteiro com separador de milhar pt-BR (1.284); invalido vira "—"
    function num(n) { const v = Number(n); return isFinite(v) ? v.toLocaleString(Qt.locale("pt_BR"), "f", 0) : "—" }
    function plural(n, one, many) { return num(n) + " " + (Number(n) === 1 ? one : many) }
    // mensagem do AUR em pt-BR (o texto cru do script nao vai para a tela)
    function aurMsg(e) { return e ? "O AUR não respondeu. Confira a internet; repositório e Flatpak continuam valendo." : "" }
    function srcLabel(s) { return s === "pacman" ? "Pacman" : s === "aur" ? "AUR" : s === "flatpak" ? "Flatpak" : "Manual" }

    // frase de protecao do shell (a: item com .shell)
    function shellWhy(a) { return a.shell ? (a.shell.level === "required" ? "O shell precisa dele para: " : "Recurso do shell: ") + a.shell.why : "" }

    // selo da origem
    component Badge: Rectangle {
        id: bd
        property string src
        property string label: root.srcLabel(src)
        property string icon: ""
        width: bt.implicitWidth + 12 + (icon !== "" ? 14 : 0); height: 18; radius: 9
        color: src === "pacman" ? Theme.tint(0.16) : src === "aur" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.16) : Theme.track
        border.width: src === "local" ? 1 : 0; border.color: Theme.border
        UiIcon { visible: bd.icon !== ""; x: 6; anchors.verticalCenter: parent.verticalCenter; name: bd.icon; size: 12; color: Theme.accent }
        UiText { id: bt; anchors.centerIn: parent; anchors.horizontalCenterOffset: bd.icon !== "" ? 7 : 0; text: bd.label; font.pixelSize: 10; font.weight: Font.Bold
            color: bd.src === "pacman" ? Theme.accent : bd.src === "aur" ? Theme.danger : Theme.muted }
    }
    // caixa de confirmacao vermelha
    component Warn: Rectangle {
        default property alias content: wc.data
        radius: SetK.innerRadius
        height: wc.implicitHeight + SetK.lg
        color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.1)
        border.width: 1; border.color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.4)
        Column { id: wc; x: SetK.md; y: SetK.md - 2; width: parent.width - SetK.md * 2; spacing: SetK.sm }
    }
    // erro dentro do bloco: frase do problema + saida (Tentar de novo)
    component Fail: Row {
        id: fl
        property string msg
        signal retry()
        spacing: SetK.md
        UiIcon { anchors.verticalCenter: parent.verticalCenter; name: "info"; size: 18; color: Theme.danger }
        UiText { anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, fl.parent.width - 200); elide: Text.ElideRight; text: fl.msg; color: Theme.text; font.pixelSize: SetK.fDesc }
        UiButton { anchors.verticalCenter: parent.verticalCenter; icon: "refresh"; text: "Tentar de novo"; kind: "ghost"; onClicked: fl.retry() }
    }
    // linha de rotulo/valor dos detalhes
    component KV: Row {
        property string k
        property string v
        spacing: SetK.lg
        UiText { width: 110; text: parent.k; color: Theme.muted; font.pixelSize: SetK.fDesc }
        UiText { width: 560; text: parent.v; color: Theme.text; font.pixelSize: SetK.fDesc; wrapMode: Text.WordWrap }
    }

    Component {
        id: bodyC
        Rectangle {
            color: Theme.gl(Theme.bg, 1)
            // fechar (mesmo botao das Configuracoes); Esc tambem fecha
            focus: true
            Keys.onEscapePressed: Apps.windowOpen = false
            UiButton { z: 10; anchors { right: parent.right; top: parent.top; margins: 14 } icon: "close"; kind: "ghost"; onClicked: Apps.windowOpen = false }

            // ---- trilho de abas ----
            Rectangle {
                id: rail
                width: 200; height: parent.height
                color: Theme.gl(Theme.sidebar, 1)
                Column {
                    x: SetK.md; y: SetK.lg; width: parent.width - SetK.md * 2; spacing: 4
                    UiText { x: SetK.sm; text: "Aplicativos"; color: Theme.text; font.family: Theme.fontTitle; font.pixelSize: 20; font.weight: Font.Bold; bottomPadding: SetK.md }
                    Repeater {
                        model: [
                            { id: "apps", label: "Apps", icon: "apps" },
                            { id: "pkgs", label: "Pacotes", icon: "package" },
                            { id: "install", label: "Instalar", icon: "download" },
                            { id: "updates", label: "Atualizações", icon: "refresh" }
                        ]
                        delegate: Rectangle {
                            id: tb
                            required property var modelData
                            readonly property bool cur: Apps.tab === modelData.id
                            width: parent.width; height: 42; radius: SetK.innerRadius
                            color: cur ? Theme.cardHi : (th.hovered ? Theme.card : "transparent")
                            scale: tm.pressed ? 0.97 : 1
                            Behavior on scale { enabled: tb.visible; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            HoverHandler { id: th }
                            MouseArea { id: tm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Apps.tab = tb.modelData.id }
                            UiIcon { x: SetK.md; anchors.verticalCenter: parent.verticalCenter; name: tb.modelData.icon; size: 18; color: tb.cur ? Theme.accent : Theme.muted }
                            UiText { x: SetK.md + 28; anchors.verticalCenter: parent.verticalCenter; text: tb.modelData.label; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: tb.cur ? Font.DemiBold : Font.Medium }
                            Rectangle {
                                visible: tb.modelData.id === "updates" && SystemGuard.updates > 0
                                anchors { right: parent.right; rightMargin: SetK.md; verticalCenter: parent.verticalCenter }
                                width: Math.max(20, ub.implicitWidth + 10); height: 18; radius: 9
                                color: Theme.accent
                                UiText { id: ub; anchors.centerIn: parent; text: SystemGuard.updates; font.pixelSize: 10; font.weight: Font.Bold; color: Theme.accentText; font.features: { "tnum": 1 } }
                            }
                        }
                    }
                }
            }

            // ---- conteudo ----
            Item {
                anchors { left: rail.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: SetK.lg }

                // tarefa em andamento (compartilhada por todas as abas)
                Rectangle {
                    id: banner
                    visible: Apps.jobState !== ""
                    width: parent.width
                    height: visible ? bc.implicitHeight + SetK.md * 2 : 0
                    radius: SetK.innerRadius
                    color: Theme.card
                    border.width: 1; border.color: Apps.jobState === "err" ? Theme.danger : Theme.border
                    Column {
                        id: bc
                        x: SetK.md; y: SetK.md; width: parent.width - SetK.md * 2; spacing: SetK.xs
                        Row {
                            width: parent.width; spacing: SetK.sm
                            UiIcon { anchors.verticalCenter: parent.verticalCenter; size: 18; color: Apps.jobState === "err" ? Theme.danger : Theme.accent
                                name: Apps.jobState === "ok" ? "check" : Apps.jobState === "err" ? "info" : "refresh" }
                            UiText { anchors.verticalCenter: parent.verticalCenter; width: parent.width - (Apps.jobState === "err" ? 290 : 120); elide: Text.ElideRight; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium
                                text: Apps.jobTitle + (Apps.jobState === "run" ? "… (se pedir a senha, a janela aparece pelo shell)" : Apps.jobState === "ok" ? ": pronto" : ": não deu certo") }
                            UiButton { visible: Apps.jobState === "err" && Apps.retry !== null; icon: "refresh"; text: "Tentar de novo"; kind: "ghost"; onClicked: Apps.retryJob() }
                            UiButton { visible: Apps.jobState !== "run"; text: "Fechar"; kind: "ghost"; onClicked: Apps.closeJob() }
                        }
                        UiText { visible: Apps.jobState === "err" && Apps.jobFriendly !== ""; width: parent.width; wrapMode: Text.WordWrap; text: Apps.jobFriendly; color: Theme.danger; font.pixelSize: SetK.fDesc }
                        UiText { visible: Apps.jobLog !== ""; width: parent.width; wrapMode: Text.WrapAnywhere; text: Apps.jobLog; color: Apps.jobState === "err" && Apps.jobFriendly === "" ? Theme.danger : Theme.muted; font.pixelSize: 11; font.family: Settings.fontMono || "monospace" }
                    }
                }
                UiText {
                    id: dryNote
                    anchors { top: banner.visible ? banner.bottom : parent.top; topMargin: banner.visible ? SetK.sm : 0 }
                    visible: Apps.dry; height: visible ? implicitHeight : 0
                    text: "Modo de teste: nenhum comando é executado de verdade"; color: Theme.muted; font.pixelSize: SetK.fDesc
                }
                Item {
                    id: stage
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                        top: dryNote.visible ? dryNote.bottom : (banner.visible ? banner.bottom : parent.top); topMargin: banner.visible || dryNote.visible ? SetK.sm : 0 }
                    Loader { anchors.fill: parent; active: Apps.tab === "apps"; sourceComponent: appsC }
                    Loader { anchors.fill: parent; active: Apps.tab === "pkgs"; sourceComponent: pkgsC }
                    Loader { anchors.fill: parent; active: Apps.tab === "install"; sourceComponent: installC }
                    Loader { anchors.fill: parent; active: Apps.tab === "updates"; sourceComponent: updatesC }
                }
            }
        }
    }

    // cabecalho de aba: titulo + subtitulo
    component Head: Column {
        property string title
        property string sub
        width: parent.width; spacing: 2; bottomPadding: SetK.sm
        UiText { text: parent.title; color: Theme.text; font.family: Theme.fontTitle; font.pixelSize: 22; font.weight: Font.Bold }
        UiText { width: parent.width; elide: Text.ElideRight; text: parent.sub; color: Theme.muted; font.pixelSize: 13 }
    }

    // =============== Apps (instalados com atalho no launcher) ===============
    Component {
        id: appsC
        Item {
            id: ap
            property string q: ""
            readonly property var shown: {
                const s = q.toLowerCase()
                return !s ? Apps.apps : Apps.apps.filter(a => (a.name + " " + a.pkg + " " + a.id).toLowerCase().includes(s))
            }
            Head { id: hd; title: "Apps"; sub: Apps.loaded ? root.plural(Apps.apps.length, "app do launcher", "apps do launcher") + "; clique para ver os detalhes ou remover" : Apps.listErr ? "Não foi possível ler os apps" : "Lendo os aplicativos…" }
            UiField { id: fld; anchors.top: hd.bottom; width: parent.width; placeholderText: "Buscar entre os apps…"; onTextChanged: tm.restart() }
            Timer { id: tm; interval: 120; onTriggered: { ap.q = fld.text.trim(); Apps.selected = "" } }
            UiText { anchors.top: fld.bottom; anchors.topMargin: SetK.md; visible: Apps.loaded && ap.shown.length === 0; text: ap.q !== "" ? "Nada encontrado para “" + ap.q + "”. Tente outro nome." : "Nenhum app com atalho no launcher ainda."; color: Theme.muted; font.pixelSize: SetK.fDesc }
            Fail { visible: Apps.listErr && !Apps.loaded; anchors.top: fld.bottom; anchors.topMargin: SetK.md; msg: "Não consegui ler a lista de apps."; onRetry: Apps.load() }
            ListView {
                id: lv
                anchors { top: fld.bottom; topMargin: SetK.sm; left: parent.left; right: parent.right; bottom: parent.bottom }
                clip: true; boundsBehavior: Flickable.StopAtBounds; reuseItems: true; cacheBuffer: 200
                model: ap.shown
                delegate: Item {
                    id: d
                    required property var modelData
                    readonly property bool open: Apps.selected === modelData.id
                    width: lv.width
                    height: 52 + (open ? det.height : 0)
                    Rectangle {
                        width: parent.width; height: 52; radius: SetK.innerRadius
                        color: hv.hovered || d.open ? Theme.cardHi : "transparent"
                        HoverHandler { id: hv }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Apps.selected = d.open ? "" : d.modelData.id }
                        Image {
                            id: ic
                            x: 8; anchors.verticalCenter: parent.verticalCenter
                            width: 32; height: 32; sourceSize: Qt.size(64, 64)
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
                            UiText { visible: d.modelData.size > 0 || !!d.modelData.sizeText; anchors.verticalCenter: parent.verticalCenter; text: d.modelData.size > 0 ? root.fmtSize(d.modelData.size) : (d.modelData.sizeText || ""); color: Theme.muted; font.pixelSize: SetK.fDesc }
                            Badge { visible: !!d.modelData.shell; anchors.verticalCenter: parent.verticalCenter; src: "pacman"; icon: d.modelData.shell && d.modelData.shell.level === "required" ? "shieldCheck" : ""; label: d.modelData.shell && d.modelData.shell.level === "required" ? "Usado pelo shell" : "Recurso do shell" }
                            Badge { anchors.verticalCenter: parent.verticalCenter; src: d.modelData.src }
                            UiIcon { anchors.verticalCenter: parent.verticalCenter; name: "chevDown"; size: 18; color: Theme.muted; rotation: d.open ? 180 : 0 }
                        }
                    }
                    Loader {
                        id: det
                        y: 52; width: parent.width
                        active: d.open
                        sourceComponent: Column {
                            id: dc
                            property bool confirm: false
                            readonly property var a: d.modelData
                            width: det.width; spacing: SetK.sm; topPadding: SetK.xs; bottomPadding: SetK.sm
                            Column {
                                x: 8 + 32 + SetK.md; spacing: 2
                                KV { k: "Pacote"; v: dc.a.pkg || "não é de um pacote (instalado à mão)" }
                                KV { visible: dc.a.version !== ""; k: "Versão"; v: dc.a.version }
                                KV { visible: dc.a.size > 0 || !!dc.a.sizeText; k: "Tamanho"; v: dc.a.size > 0 ? root.fmtSize(dc.a.size) : (dc.a.sizeText || "") }
                                KV { visible: !!dc.a.shell; k: "Shell"; v: root.shellWhy(dc.a) }
                            }
                            Row {
                                x: 8 + 32 + SetK.md; spacing: SetK.sm
                                UiButton { icon: "play"; text: "Abrir"; kind: "accent"; onClicked: Quickshell.execDetached(["gtk-launch", dc.a.id.replace(/\.desktop$/, "")]) }
                                UiButton { visible: dc.a.pkg !== "" && !dc.confirm; icon: "trash"; text: "Remover app"; kind: "danger"; enabled: !Apps.busy && !(dc.a.shell && dc.a.shell.level === "required"); onClicked: dc.confirm = true }
                            }
                            Warn {
                                visible: dc.confirm
                                x: 8 + 32 + SetK.md; width: parent.width - x - SetK.sm
                                UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.text; font.pixelSize: SetK.fDesc
                                    text: "Remover " + dc.a.name + "? " + (dc.a.shell ? root.shellWhy(dc.a) + " deixa de funcionar. " : "") + (dc.a.src === "flatpak" ? "O Flatpak sai do computador." : "Sai o pacote " + dc.a.pkg + " e as dependências que mais ninguém usa. Se outro programa precisar dele, o pacman recusa e a mensagem aparece lá em cima.") }
                                Row { spacing: SetK.sm
                                    UiButton { text: "Cancelar"; kind: "ghost"; onClicked: dc.confirm = false }
                                    UiButton { icon: "trash"; text: "Remover app"; kind: "danger"; enabled: !Apps.busy; onClicked: { dc.confirm = false; Apps.selected = ""; Apps.uninstall(dc.a) } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =============== Pacotes (todos do pacman) ===============
    Component {
        id: pkgsC
        Item {
            id: pk
            property bool confirmOrph: false
            Component.onCompleted: if (!Apps.pkgLoaded) Apps.loadPkgs()
            Head { id: hd; title: "Pacotes"; sub: Apps.pkgLoaded ? root.plural(Apps.pkgList.length, "pacote instalado", "pacotes instalados") + " · " + root.num(Apps.pkgShown.length) + " na lista" : Apps.pkgErr ? "Não foi possível ler os pacotes" : "Lendo o banco do pacman…" }
            UiField { id: fld; anchors.top: hd.bottom; width: parent.width; text: Apps.pkgQuery; placeholderText: "Buscar por nome ou descrição (ex.: polkit)…"; onTextChanged: tm.restart() }
            Timer { id: tm; interval: 120; onTriggered: { Apps.pkgQuery = fld.text.trim(); Apps.selPkg = "" } }
            Item {
                id: bar
                anchors.top: fld.bottom; anchors.topMargin: SetK.sm
                width: parent.width; height: 36
                UiSeg {
                    id: segF
                    options: [["all", "Todos"], ["explicit", "Explícitos"], ["aur", "AUR"], ["orphan", "Órfãos"]]
                    value: Apps.pkgFilter
                    onPicked: v => { Apps.pkgFilter = v; Apps.selPkg = ""; pk.confirmOrph = false }
                }
                UiSeg {
                    anchors.right: parent.right
                    options: [["name", "Nome"], ["size", "Tamanho"]]
                    value: Apps.pkgSort
                    onPicked: v => Apps.pkgSort = v
                }
                UiButton {
                    visible: Apps.pkgFilter === "orphan" && Apps.orphans.length > 0 && !pk.confirmOrph
                    anchors { left: segF.right; leftMargin: SetK.md; verticalCenter: parent.verticalCenter }
                    icon: "trash"; text: "Remover órfãos (" + root.num(Apps.orphans.length) + ")"; kind: "danger"; enabled: !Apps.busy
                    onClicked: pk.confirmOrph = true
                }
            }
            Warn {
                id: orphW
                visible: pk.confirmOrph
                anchors { top: bar.bottom; topMargin: SetK.sm }
                width: parent.width
                UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.text; font.pixelSize: SetK.fDesc
                    text: "Remover " + root.plural(Apps.orphans.length, "pacote órfão", "pacotes órfãos") + " (dependências que nada mais usa)? " + Apps.orphans.map(p => p.name).join(", ") }
                Row { spacing: SetK.sm
                    UiButton { text: "Cancelar"; kind: "ghost"; onClicked: pk.confirmOrph = false }
                    UiButton { icon: "trash"; text: "Remover todos"; kind: "danger"; enabled: !Apps.busy; onClicked: { pk.confirmOrph = false; Apps.removeOrphans() } }
                }
            }
            UiText { anchors.top: pk.confirmOrph ? orphW.bottom : bar.bottom; anchors.topMargin: SetK.md; visible: Apps.pkgLoaded && Apps.pkgShown.length === 0; text: Apps.pkgQuery !== "" ? "Nada encontrado para “" + Apps.pkgQuery + "”. Tente outro nome ou limpe o filtro." : Apps.pkgFilter === "orphan" ? "Nenhum pacote órfão. Está tudo em uso." : "Nenhum pacote nesta lista."; color: Theme.muted; font.pixelSize: SetK.fDesc }
            Fail { visible: Apps.pkgErr && !Apps.pkgLoaded; anchors.top: pk.confirmOrph ? orphW.bottom : bar.bottom; anchors.topMargin: SetK.md; width: parent.width; msg: "Não consegui ler o banco do pacman."; onRetry: Apps.loadPkgs() }
            ListView {
                id: lv
                anchors { top: pk.confirmOrph ? orphW.bottom : bar.bottom; topMargin: SetK.sm; left: parent.left; right: parent.right; bottom: parent.bottom }
                clip: true; boundsBehavior: Flickable.StopAtBounds; reuseItems: true; cacheBuffer: 200
                model: Apps.pkgShown
                delegate: Item {
                    id: d
                    required property var modelData
                    readonly property bool open: Apps.selPkg === modelData.name
                    width: lv.width
                    height: 50 + (open ? det.height : 0)
                    Rectangle {
                        width: parent.width; height: 50; radius: SetK.innerRadius
                        color: hv.hovered || d.open ? Theme.cardHi : "transparent"
                        HoverHandler { id: hv }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Apps.selPkg = d.open ? "" : d.modelData.name }
                        Column {
                            anchors { left: parent.left; leftMargin: SetK.md; right: meta.left; rightMargin: SetK.md; verticalCenter: parent.verticalCenter }
                            spacing: 2
                            Row { spacing: SetK.sm; width: parent.width
                                UiText { width: Math.min(implicitWidth, parent.width - pv.implicitWidth - SetK.sm); elide: Text.ElideRight; text: d.modelData.name; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium }
                                UiText { id: pv; anchors.verticalCenter: parent.verticalCenter; text: d.modelData.version; color: Theme.muted; font.pixelSize: 11; font.features: { "tnum": 1 } }
                            }
                            UiText { width: parent.width; elide: Text.ElideRight; text: d.modelData.desc; color: Theme.muted; font.pixelSize: SetK.fDesc }
                        }
                        Row {
                            id: meta
                            anchors { right: parent.right; rightMargin: SetK.sm; verticalCenter: parent.verticalCenter }
                            spacing: SetK.sm
                            UiText { anchors.verticalCenter: parent.verticalCenter; text: root.fmtSize(d.modelData.size); color: Theme.muted; font.pixelSize: SetK.fDesc }
                            Badge { visible: d.modelData.orphan; anchors.verticalCenter: parent.verticalCenter; src: "local"; label: "Órfão" }
                            Badge { visible: !!d.modelData.shell; anchors.verticalCenter: parent.verticalCenter; src: "pacman"; icon: d.modelData.shell && d.modelData.shell.level === "required" ? "shieldCheck" : ""; label: d.modelData.shell && d.modelData.shell.level === "required" ? "Usado pelo shell" : "Recurso do shell" }
                            Badge { visible: d.modelData.foreign; anchors.verticalCenter: parent.verticalCenter; src: "aur" }
                            Badge { anchors.verticalCenter: parent.verticalCenter; src: d.modelData.explicit ? "pacman" : "local"; label: d.modelData.explicit ? "Explícito" : "Dependência" }
                            UiIcon { anchors.verticalCenter: parent.verticalCenter; name: "chevDown"; size: 18; color: Theme.muted; rotation: d.open ? 180 : 0 }
                        }
                    }
                    Loader {
                        id: det
                        y: 50; width: parent.width
                        active: d.open
                        sourceComponent: Column {
                            id: dc
                            property bool confirm: false
                            readonly property var a: d.modelData
                            width: det.width; spacing: SetK.sm; topPadding: SetK.xs; bottomPadding: SetK.sm
                            Column {
                                x: SetK.md; spacing: 2
                                KV { k: "Descrição"; v: dc.a.desc || "—" }
                                KV { k: "Versão"; v: dc.a.version }
                                KV { k: "Tamanho"; v: root.fmtSize(dc.a.size) }
                                KV { visible: !!dc.a.shell; k: "Shell"; v: root.shellWhy(dc.a) }
                                KV { k: "Necessário para"; v: dc.a.reqBy.length === 0 ? "nenhum pacote" : root.num(dc.a.reqBy.length) + ": " + dc.a.reqBy.join(", ") }
                            }
                            Row {
                                x: SetK.md; spacing: SetK.sm
                                UiButton { visible: !dc.confirm; icon: "trash"; text: "Remover pacote"; kind: "danger"; enabled: !Apps.busy && !(dc.a.shell && dc.a.shell.level === "required"); onClicked: dc.confirm = true }
                            }
                            Warn {
                                visible: dc.confirm
                                x: SetK.md; width: parent.width - SetK.md * 2
                                UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.text; font.pixelSize: SetK.fDesc
                                    text: "Remover " + dc.a.name + " e as dependências que mais ninguém usa (pacman -Rns)?" + (dc.a.shell ? " " + root.shellWhy(dc.a) + " deixa de funcionar." : "") + (dc.a.reqBy.length > 0 ? " Outros pacotes dependem dele (" + root.num(dc.a.reqBy.length) + "): o pacman vai recusar e a mensagem aparece lá em cima." : "") }
                                Row { spacing: SetK.sm
                                    UiButton { text: "Cancelar"; kind: "ghost"; onClicked: dc.confirm = false }
                                    UiButton { icon: "trash"; text: "Remover pacote"; kind: "danger"; enabled: !Apps.busy; onClicked: { dc.confirm = false; Apps.selPkg = ""; Apps.removePkg(dc.a) } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =============== Instalar (repositorio, AUR, Flatpak) ===============
    Component {
        id: installC
        Item {
            Head { id: hd; title: "Instalar"; sub: "Busca nos repositórios do Arch, no AUR" + (Apps.hasFlatpak ? " e no Flathub" : "") }
            UiField { id: fld; anchors.top: hd.bottom; width: parent.width; text: Apps.query; placeholderText: "Buscar um programa para instalar…"; onTextChanged: Apps.search(text) }
            UiText {
                id: hint
                anchors { top: fld.bottom; topMargin: SetK.sm }
                visible: Apps.query.length < 2 || Apps.searching || Apps.results.length === 0 || Apps.aurErr !== ""
                width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc
                text: Apps.query.length < 2
                    ? "Digite pelo menos 2 letras. Do repositório instala direto (pede a senha); do AUR abre um terminal para você revisar" + (Apps.helper === "" ? " (precisa do paru ou do yay, que não estão instalados)." : " com o " + Apps.helper + ".")
                    : (Apps.searching ? "Buscando…" : Apps.results.length === 0 ? "Nada encontrado para “" + Apps.query + "”. Tente outro nome ou parte dele." : "") + (Apps.aurErr !== "" ? " " + root.aurMsg(Apps.aurErr) : "")
            }
            ListView {
                id: rv
                anchors { top: hint.visible ? hint.bottom : fld.bottom; topMargin: SetK.sm; left: parent.left; right: parent.right; bottom: parent.bottom }
                visible: Apps.query.length >= 2 && Apps.results.length > 0
                clip: true; boundsBehavior: Flickable.StopAtBounds; reuseItems: true; cacheBuffer: 200
                model: Apps.results
                delegate: Item {
                    id: r
                    required property var modelData
                    readonly property bool needHelper: modelData.src === "aur" && Apps.helper === ""
                    width: rv.width; height: 62
                    Rectangle { width: parent.width - 16; x: 8; y: 0; height: 1; color: Theme.border; opacity: 0.45 }
                    Column {
                        anchors { left: parent.left; leftMargin: 8; right: act.left; rightMargin: SetK.md; verticalCenter: parent.verticalCenter }
                        spacing: 3
                        Row { spacing: SetK.sm; width: parent.width
                            UiText { width: Math.min(implicitWidth, parent.width - rb.width - rv2.implicitWidth - SetK.sm * 2); elide: Text.ElideRight; text: r.modelData.name; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium }
                            Badge { id: rb; anchors.verticalCenter: parent.verticalCenter; src: r.modelData.src }
                            UiText { id: rv2; anchors.verticalCenter: parent.verticalCenter; width: Math.min(implicitWidth, 120); elide: Text.ElideRight; text: r.modelData.version; color: Theme.muted; font.pixelSize: 11 }
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
        }
    }

    // =============== Atualizacoes ===============
    Component {
        id: updatesC
        Item {
            id: up
            Component.onCompleted: if (!Apps.updLoaded) Apps.loadUpdates()
            readonly property var rows: Apps.updRepo.map(u => Object.assign({ src: "pacman" }, u)).concat(Apps.updAur.map(u => Object.assign({ src: "aur" }, u)))
            Head { id: hd; title: "Atualizações"
                sub: Apps.updLoading ? "Verificando…" : Apps.updErr ? "Não foi possível verificar" : !Apps.updTool ? "Falta o checkupdates (pacote pacman-contrib); instale-o na aba Instalar" : up.rows.length === 0 ? "Tudo em dia" : root.plural(up.rows.length, "atualização pendente", "atualizações pendentes") + (Apps.helper === "" ? "" : " (repositórios e AUR)") }
            Row {
                id: bt
                anchors.top: hd.bottom; spacing: SetK.sm
                UiButton { text: "Verificar"; icon: "refresh"; kind: "ghost"; enabled: !Apps.updLoading; onClicked: { Apps.loadUpdates(); SystemGuard.checkUpdates() } }
                UiButton { icon: "download"; text: "Atualizar tudo"; kind: "accent"; enabled: !Apps.busy; onClicked: Apps.updateAll() }
            }
            Fail { visible: Apps.updErr && !Apps.updLoading; anchors.top: bt.bottom; anchors.topMargin: SetK.md; width: parent.width; msg: "A verificação de atualizações falhou."; onRetry: Apps.loadUpdates() }
            ListView {
                id: lv
                anchors { top: bt.bottom; topMargin: SetK.md; left: parent.left; right: parent.right; bottom: parent.bottom }
                clip: true; boundsBehavior: Flickable.StopAtBounds; reuseItems: true; cacheBuffer: 200
                model: up.rows
                delegate: Item {
                    id: d
                    required property var modelData
                    width: lv.width; height: 40
                    Rectangle { width: parent.width - 16; x: 8; y: 0; height: 1; color: Theme.border; opacity: 0.4 }
                    Row {
                        x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: SetK.sm
                        UiText { width: Math.min(implicitWidth, lv.width * 0.4); elide: Text.ElideRight; text: d.modelData.name; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium }
                        Badge { visible: d.modelData.src === "aur"; anchors.verticalCenter: parent.verticalCenter; src: "aur" }
                    }
                    UiText { anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: Math.min(implicitWidth, lv.width * 0.5); elide: Text.ElideLeft; text: d.modelData.old + "  →  " + d.modelData.new; color: Theme.muted; font.pixelSize: SetK.fDesc; font.family: Settings.fontMono || "monospace" }
                }
            }
        }
    }
}
