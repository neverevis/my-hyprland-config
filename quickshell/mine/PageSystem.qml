// Pagina "Sistema": ícones dos aplicativos, cursor, mouse e fontes do sistema, tudo com previa e com opcao de baixar
// mais (temas pelo pacman/yay num terminal; fontes do Google Fonts direto). Servico: SysTheme.qml.
import Quickshell
import QtQuick

Column {
    id: page
    spacing: 14
    Component.onCompleted: { SysTheme.load(); HyprConf.refresh() }   // o mouse mostra os valores atuais do Hyprland

    // aviso do que esta rodando
    Rectangle {
        visible: SysTheme.busy !== "" || SysTheme.msg !== ""
        width: parent.width; height: 40; radius: 12
        color: Theme.tint(0.12); border.width: 1; border.color: Theme.tint(0.4)
        Row {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 10
            UiIcon { name: SysTheme.busy !== "" ? "refresh" : "info"; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter
                RotationAnimation on rotation { running: SysTheme.busy !== ""; from: 0; to: 360; duration: 1000; loops: Animation.Infinite } }
            UiText { text: SysTheme.busy || SysTheme.msg; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // ---------------- icones ----------------
    Card {
        icon: "apps"
        title: "Ícones dos aplicativos"
        subtitle: "O tema de ícones dos apps GTK e Qt, do launcher, do dock e da bandeja. Clique para usar."
        Flow {
            width: parent.width
            spacing: 10
            Repeater {
                model: SysTheme.icons
                delegate: Rectangle {
                    id: it
                    required property var modelData
                    readonly property bool on: SysTheme.cur.icons === modelData.name
                    width: 196; height: 104; radius: 14
                    color: on ? Theme.tint(0.14) : (im.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: on ? 2 : 1; border.color: on ? Theme.accent : Theme.border
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Grid {
                        x: 12; y: 12
                        columns: 6; spacing: 4
                        Repeater {
                            model: it.modelData.samples
                            Image { required property var modelData; width: 25; height: 25; sourceSize: Qt.size(50, 50); source: "file://" + modelData; asynchronous: true; smooth: true }
                        }
                    }
                    Row {
                        anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 12 }
                        spacing: 6
                        UiIcon { visible: it.on; name: "check"; size: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: it.modelData.label; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysTheme.setIcons(it.modelData.name) }
                }
            }
        }
        UiText { visible: !SysTheme.loaded; text: "Procurando os temas instalados…"; color: Theme.muted; font.pixelSize: 12 }
        Downloads { list: SysTheme.iconPkgs }
    }

    // ---------------- cursor ----------------
    Card {
        icon: "mouse"
        title: "Cursor"
        subtitle: "Tema e tamanho do ponteiro. Vale na hora e continua ao reiniciar (o shell grava no Hyprland)."
        Flow {
            width: parent.width
            spacing: 10
            Repeater {
                model: SysTheme.cursors
                delegate: Rectangle {
                    id: ct
                    required property var modelData
                    readonly property bool on: SysTheme.cur.cursor === modelData.name
                    width: 196; height: 92; radius: 14
                    color: on ? Theme.tint(0.14) : (cm.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: on ? 2 : 1; border.color: on ? Theme.accent : Theme.border
                    // previa num fundo claro (a maioria dos cursores e escura com borda clara ou o contrario)
                    Rectangle {
                        x: 10; y: 10; width: parent.width - 20; height: 44; radius: 10
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                        Row {
                            anchors.centerIn: parent
                            spacing: 12
                            Repeater {
                                model: ct.modelData.previews
                                Image { required property var modelData; width: 28; height: 28; source: "file://" + modelData; fillMode: Image.PreserveAspectFit; smooth: true }
                            }
                        }
                    }
                    Row {
                        anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 10 }
                        spacing: 6
                        UiIcon { visible: ct.on; name: "check"; size: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        UiText { width: 160; elide: Text.ElideRight; text: ct.modelData.label; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SysTheme.setCursor(ct.modelData.name, SysTheme.cur.cursorSize || 24) }
                }
            }
        }
        UiLabel { text: "Tamanho" }
        UiSeg {
            options: [[16, "16"], [20, "20"], [24, "24"], [32, "32"], [40, "40"], [48, "48"], [64, "64"]]
            value: SysTheme.cur.cursorSize ?? 24
            onPicked: v => SysTheme.setCursor(SysTheme.cur.cursor || "Adwaita", v)
        }
        UiSwitch {
            visible: Settings.sysCursor !== ""
            label: "O shell cuida do cursor"
            description: "Desligue para voltar ao que a sua configuração do Hyprland define (vale depois de reiniciar a sessão)."
            checked: Settings.sysCursor !== ""
            onToggled: on => { if (!on) Settings.sysCursor = "" }
        }
        Downloads { list: SysTheme.cursorPkgs }
    }

    // ---------------- mouse ----------------
    Card {
        icon: "cursorMove"
        title: "Mouse"
        subtitle: "Velocidade, aceleração e rolagem (opções do Hyprland, também na página Hyprland)."
        OptionsForm {
            width: parent.width
            schema: HyprConf.options.filter(o => o.group === "mouse" || o.key === "cursor:inactive_timeout").map(o => {
                const d = Object.assign({}, o)
                if (o.pct || o.float) { d.from = o.from * 100; d.to = o.to * 100; d.step = o.float ? Math.max(1, (o.step ?? 0.01) * 100) : 1; d.suffix = " %" }
                d.icon = ({ "input:sensitivity": "speed", "input:accel_profile": "gauge", "input:follow_mouse": "tap", "input:natural_scroll": "swap_vertical", "cursor:inactive_timeout": "eyeOff" })[o.key] ?? ""
                return d
            })
            get: k => { const o = HyprConf.opt(k), v = HyprConf.value(k); return o && (o.pct || o.float) && v !== undefined ? Math.round(v * 100) : v }
            set: (k, v) => { const o = HyprConf.opt(k); HyprConf.set(k, o && (o.pct || o.float) ? v / 100 : v) }
        }
    }

    // ---------------- fontes ----------------
    Card {
        icon: "font"
        title: "Fontes do sistema"
        subtitle: "A fonte dos aplicativos (GTK e Qt) e a monoespaçada (terminal, código)."
        OptionsForm {
            width: parent.width
            schema: [
                { key: "font", label: "Fonte dos aplicativos", icon: "font", type: "font" },
                { key: "fontSize", label: "Tamanho", icon: "textSize", type: "slider", from: 8, to: 18, suffix: " pt" },
                { key: "mono", label: "Fonte monoespaçada", icon: "keyboard", type: "font" },
                { key: "monoSize", label: "Tamanho da monoespaçada", icon: "textSize", type: "slider", from: 8, to: 18, suffix: " pt" }
            ]
            get: k => SysTheme.cur[k]
            set: (k, v) => {
                if (k === "font" || k === "fontSize") SysTheme.setFont(k === "font" ? (v || "Adwaita Sans") : SysTheme.cur.font, k === "fontSize" ? v : SysTheme.cur.fontSize)
                else SysTheme.setMono(k === "mono" ? (v || "Adwaita Mono") : SysTheme.cur.mono, k === "monoSize" ? v : SysTheme.cur.monoSize)
            }
        }
        Row {
            spacing: 8
            UiButton { icon: "font"; text: "Usar também no shell"; kind: "ghost"; onClicked: { Settings.fontUi = SysTheme.cur.font || ""; Settings.fontMono = SysTheme.cur.mono || "" } }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: "Shell agora: " + (Settings.fontUi || "padrão") + " · " + (Settings.fontMono || "padrão"); color: Theme.muted; font.pixelSize: 12 }
        }
    }

    Card {
        icon: "download"
        title: "Baixar fontes"
        subtitle: "Direto do Google Fonts (gratuitas, licença aberta), para ~/.local/share/fonts. Sem senha."
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: SysTheme.fontSuggestions
                delegate: Rectangle {
                    id: ft
                    required property var modelData
                    property bool have: SysTheme.hasFont(modelData.family)
                    width: 210; height: 70; radius: 12
                    color: fm.containsMouse && !have ? Theme.cardHi : Theme.track
                    border.width: 1; border.color: have ? Theme.tint(0.5) : Theme.border
                    Column {
                        anchors { left: parent.left; leftMargin: 12; right: act.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        spacing: 2
                        // instalada: o nome ja aparece na propria fonte
                        UiText { width: parent.width; elide: Text.ElideRight; text: ft.modelData.family; color: Theme.text; font.pixelSize: 16; font.family: ft.have ? ft.modelData.family : Theme.font; font.weight: Font.DemiBold }
                        UiText { width: parent.width; elide: Text.ElideRight; text: ft.modelData.tag; color: Theme.muted; font.pixelSize: 11 }
                    }
                    Rectangle {
                        id: act
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        width: 30; height: 30; radius: 15
                        color: ft.have ? Theme.tint(0.18) : (fm.containsMouse ? Theme.accent : Theme.cardHi)
                        UiIcon { anchors.centerIn: parent; name: ft.have ? "check" : "download"; size: 15; color: ft.have ? Theme.accent : (fm.containsMouse ? Theme.accentText : Theme.text) }
                    }
                    MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; enabled: !ft.have && SysTheme.busy === ""; cursorShape: Qt.PointingHandCursor
                        onClicked: SysTheme.download(ft.modelData.family, () => ft.have = SysTheme.hasFont(ft.modelData.family)) }
                }
            }
        }
        Row {
            spacing: 8
            UiField { id: gf; width: 300; placeholderText: "Outra fonte do Google Fonts (ex.: Quicksand)"; onAccepted: if (text.trim() !== "") SysTheme.download(text.trim()) }
            UiButton { icon: "download"; text: "Baixar"; kind: "accent"; enabled: gf.text.trim() !== "" && SysTheme.busy === ""; onClicked: SysTheme.download(gf.text.trim()) }
        }
    }

    // lista do que da para instalar (o que ja esta instalado aparece marcado)
    component Downloads: Column {
        id: dl
        property var list: []
        width: parent ? parent.width : 300
        spacing: 6
        UiLabel { text: "Baixar mais" }
        Flow {
            width: dl.width
            spacing: 6
            Repeater {
                model: dl.list.filter(p => !p.aur || SysTheme.hasYay)
                delegate: Rectangle {
                    id: pr
                    required property var modelData
                    readonly property bool have: SysTheme.installed.indexOf(modelData.pkg) >= 0
                    width: 250; height: 54; radius: 12
                    color: pm.containsMouse && !have ? Theme.cardHi : "transparent"
                    border.width: 1; border.color: Theme.border
                    Column {
                        anchors { left: parent.left; leftMargin: 12; right: pb.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        spacing: 2
                        Row {
                            spacing: 6
                            UiText { text: pr.modelData.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Rectangle { visible: !!pr.modelData.aur; width: at.implicitWidth + 10; height: 16; radius: 8; color: Theme.tint(0.16); anchors.verticalCenter: parent.verticalCenter
                                UiText { id: at; anchors.centerIn: parent; text: "AUR"; color: Theme.accent; font.pixelSize: 9; font.weight: Font.Bold } }
                        }
                        UiText { width: parent.width; elide: Text.ElideRight; text: pr.modelData.desc; color: Theme.muted; font.pixelSize: 11 }
                    }
                    Rectangle {
                        id: pb
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        width: 30; height: 30; radius: 15
                        color: pr.have ? Theme.tint(0.18) : (pm.containsMouse ? Theme.accent : Theme.cardHi)
                        UiIcon { anchors.centerIn: parent; name: pr.have ? "check" : "download"; size: 15; color: pr.have ? Theme.accent : (pm.containsMouse ? Theme.accentText : Theme.text) }
                    }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; enabled: !pr.have && SysTheme.busy === ""; cursorShape: Qt.PointingHandCursor; onClicked: SysTheme.install(pr.modelData) }
                }
            }
        }
        UiText { width: dl.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 11
            text: "Abre um terminal com o comando (pacman pede a sua senha lá" + (SysTheme.hasYay ? "; os do AUR usam o yay" : "") + "). Ao fechar, a lista acima atualiza." }
    }

    // ---- comandos dos apps padrao ----
    Card {
        icon: "apps"
        title: "Aplicativos padrão"
        subtitle: "O que abre quando você clica em configurar a rede, o Bluetooth, o volume etc. (botões do painel Início e ações do launcher). Vazio usa o padrão mostrado."
        Repeater {
            model: AppCmds.items
            delegate: Row {
                id: ar
                required property var modelData
                spacing: 10
                UiIcon { name: ar.modelData.icon; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                UiText { width: 170; anchors.verticalCenter: parent.verticalCenter; text: ar.modelData.label; color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight }
                UiField {
                    width: Math.max(200, page.width - 330)
                    text: (Settings.appCmds || ({}))[ar.modelData.id] || ""
                    placeholderText: ar.modelData.def
                    onAccepted: AppCmds.set(ar.modelData.id, text)
                    onEditingFinished: AppCmds.set(ar.modelData.id, text)
                }
            }
        }
    }

    // ---- webapps ----
    Card {
        id: wa
        icon: "web"
        title: "Webapps"
        subtitle: "Transforme sites em aplicativos: cada endereço vira um atalho (abre numa janela sem abas) que também aparece no launcher."
        Component.onCompleted: Webapps.refresh()
        Repeater {
            model: Webapps.apps
            delegate: Rectangle {
                id: wr
                required property var modelData
                width: parent.width; height: 44; radius: 10; color: Theme.track
                UiText { x: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 150; elide: Text.ElideRight; text: wr.modelData.name + "  ·  " + wr.modelData.url; color: Theme.text; font.pixelSize: 13 }
                Row {
                    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    UiButton { icon: "play"; kind: "ghost"; onClicked: Quickshell.execDetached(["gtk-launch", "shell-webapp-" + wr.modelData.id]) }
                    UiButton { icon: "trash"; kind: "danger"; onClicked: Webapps.remove(wr.modelData.id) }
                }
            }
        }
        UiText { visible: Webapps.apps.length === 0; text: "Nenhum webapp ainda."; color: Theme.muted; font.pixelSize: 12 }
        Row {
            spacing: 8
            UiField { id: waF; width: 420; placeholderText: "Endereços (separe por espaço), ex.: web.whatsapp.com"; onAccepted: waB.clicked() }
            UiButton { id: waB; icon: "plus"; text: Webapps.busy ? "Criando…" : "Criar"; enabled: !Webapps.busy; onClicked: { Webapps.add(waF.text); waF.text = "" } }
        }
        UiText { visible: Webapps.msg !== ""; text: Webapps.msg; color: Theme.muted; font.pixelSize: 12 }
    }

    Card {
        visible: Battery.present
        icon: "battery"
        title: "Bateria"
        subtitle: "Avisos e ações quando a carga fica baixa. Só aparece em computadores com bateria."
        UiSwitch { label: "Avisar com notificação"; checked: Settings.batNotify; onToggled: on => Settings.batNotify = on }
        UiSlider { label: "Bateria baixa"; from: 5; to: 50; value: Settings.batLow; suffix: " %"; onMoved: v => Settings.batLow = Math.round(v) }
        UiSlider { label: "Bateria crítica"; from: 1; to: 20; value: Settings.batCritical; suffix: " %"; onMoved: v => Settings.batCritical = Math.round(v) }
        UiSwitch { label: "Avisar quando carregar por completo"; checked: Settings.batFullNotify; onToggled: on => Settings.batFullNotify = on }
        UiSwitch { label: "Suspender sozinho na carga crítica"; description: "Espera 30 segundos depois do aviso."; checked: Settings.batAutoSuspend; onToggled: on => Settings.batAutoSuspend = on }
        UiSlider { label: "Aviso de mouse, teclado e fones abaixo de"; from: 5; to: 50; value: Settings.batPeripheralLow; suffix: " %"; onMoved: v => Settings.batPeripheralLow = Math.round(v) }
    }
}
