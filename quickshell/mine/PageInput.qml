// Pagina "Mouse e teclado" (kit Set*): mouse, teclado, cursor e icones (cartoes com previa), fontes do sistema com download. Os temas vem de SysTheme.qml; o mouse e o teclado sao opcoes do Hyprland (HyprConf.qml).
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Mouse e teclado"
    subtitle: "Mouse, teclado, cursor, ícones e fontes"
    Component.onCompleted: { SysTheme.load(); HyprConf.refresh() }   // mostra os valores atuais do Hyprland

    // lista do que da para instalar (o que ja esta instalado aparece marcado)
    component Downloads: SetBlock {
        id: dl
        property var list: []
        sub: true
        Flow {
            width: parent.width
            spacing: SetK.sm
            Repeater {
                model: dl.list.filter(p => !p.aur || SysTheme.hasYay)
                delegate: Rectangle {
                    id: pr
                    required property var modelData
                    readonly property bool have: SysTheme.installed.indexOf(modelData.pkg) >= 0
                    width: (dl.width - SetK.textX - SetK.pad - SetK.sm) / 2; height: 54; radius: 12
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
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 11
            text: "Abre um terminal com o comando (o pacman pede a sua senha lá" + (SysTheme.hasYay ? "; os do AUR usam o yay" : "") + "). Ao fechar, a lista atualiza." }
    }

    // aviso do que esta rodando
    SetSection {
        visible: SysTheme.busy !== "" || SysTheme.msg !== ""
        title: ""
        SetRow { icon: SysTheme.busy !== "" ? "refresh" : "info"; label: SysTheme.busy || SysTheme.msg }
    }

    // ---- mouse ----
    SetSection {
        title: "Mouse"; icon: "mouse"
        subtitle: "Velocidade, aceleração e rolagem (opções do Hyprland)"
        SetHypr { keys: ["input:sensitivity", "input:accel_profile", "input:follow_mouse", "input:natural_scroll"] }
        SetExpander {
            icon: "tune"; label: "Mais ajustes"; description: "Canhoto, colar com o botão do meio, esconder o cursor parado"
            SetHypr { sub: true; keys: ["input:force_no_accel", "input:left_handed", "misc:middle_click_paste", "cursor:inactive_timeout"] }
        }
    }

    // ---- teclado ----
    SetSection {
        title: "Teclado"; icon: "keyboard"
        subtitle: "Layout, troca de layout e repetição das teclas (opções do Hyprland)"
        SetHypr { keys: ["input:kb_layout", "input:kb_options", "input:repeat_delay", "input:repeat_rate", "input:numlock_by_default"] }
        SetExpander {
            icon: "tune"; label: "Variantes"; description: "Por exemplo: ,intl para acentos"
            SetHypr { sub: true; keys: ["input:kb_variant"] }
        }
    }

    // ---- cursor ----
    SetSection {
        title: "Cursor"; icon: "cursorMove"
        subtitle: "Tema e tamanho do ponteiro; vale na hora e continua ao reiniciar"
        SetChoice {
            label: ""
            style: "tiles"; columns: 4; thumbHeight: 52
            options: SysTheme.cursors.map(c => [c.name, c.label, "", c.previews])
            value: SysTheme.cur.cursor
            onPicked: v => SysTheme.setCursor(v, SysTheme.cur.cursorSize || 24)
            thumb: Item {
                id: ct
                property var opt
                property bool on
                property bool hovered
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater {
                        model: ct.opt ? Array.from(ct.opt[3] ?? []).slice(0, 4) : []
                        delegate: Image { required property var modelData; width: 26; height: 26; sourceSize: Qt.size(52, 52); source: "file://" + modelData; fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true }
                    }
                }
            }
        }
        SetChoice {
            icon: "resize"; label: "Tamanho"
            options: [[16, "16"], [20, "20"], [24, "24"], [32, "32"], [40, "40"], [48, "48"], [64, "64"]]
            value: SysTheme.cur.cursorSize ?? 24
            onPicked: v => SysTheme.setCursor(SysTheme.cur.cursor || "Adwaita", v)
        }
        SetRow {
            visible: Settings.sysCursor !== ""
            icon: "cog"; label: "O shell cuida do cursor"; description: "Desligue para voltar ao que o seu Hyprland define (vale ao reiniciar a sessão)"
            checked: Settings.sysCursor !== ""
            onToggled: on => { if (!on) Settings.sysCursor = "" }
        }
        SetExpander {
            icon: "download"; label: "Baixar mais temas"
            lazy: Component { Downloads { list: SysTheme.cursorPkgs } }
        }
    }

    // ---- icones ----
    SetSection {
        title: "Ícones dos aplicativos"; icon: "apps"
        subtitle: "Apps GTK e Qt, launcher, dock e bandeja"
        SetChoice {
            label: ""
            style: "tiles"; columns: 4; thumbHeight: 64
            options: SysTheme.icons.map(i => [i.name, i.label, "", i.samples])
            value: SysTheme.cur.icons
            onPicked: v => SysTheme.setIcons(v)
            thumb: Item {
                id: it
                property var opt
                property bool on
                property bool hovered
                Grid {
                    anchors.centerIn: parent
                    columns: 5; spacing: 4
                    Repeater {
                        model: it.opt ? Array.from(it.opt[3] ?? []).slice(0, 10) : []
                        delegate: Image { required property var modelData; width: 24; height: 24; sourceSize: Qt.size(48, 48); source: "file://" + modelData; asynchronous: true; smooth: true }
                    }
                }
            }
        }
        SetRow { visible: !SysTheme.loaded; icon: "search"; label: "Procurando os temas instalados…" }
        SetExpander {
            icon: "download"; label: "Baixar mais temas"
            lazy: Component { Downloads { list: SysTheme.iconPkgs } }
        }
    }

    // ---- fontes ----
    SetSection {
        title: "Fontes do sistema"; icon: "font"
        subtitle: "A dos aplicativos (GTK e Qt) e a monoespaçada (terminal, código)"
        SetRow {
            icon: "font"; label: "Usar também no shell"; description: "Shell agora: " + (Settings.fontUi || "padrão") + " · " + (Settings.fontMono || "padrão")
            UiButton { text: "Usar"; kind: "ghost"; onClicked: { Settings.fontUi = SysTheme.cur.font || ""; Settings.fontMono = SysTheme.cur.mono || "" } }
        }
        SetExpander {
            icon: "textBox"; label: "Escolher as fontes"; description: (SysTheme.cur.font || "Adwaita Sans") + " · " + (SysTheme.cur.mono || "Adwaita Mono")
            lazy: Component {
                SetBlock {
                    sub: true
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
                }
            }
        }
        SetExpander {
            icon: "download"; label: "Baixar fontes"; description: "Do Google Fonts, gratuitas, para ~/.local/share/fonts"
            lazy: Component {
                SetBlock {
                    sub: true
                    Flow {
                        width: parent.width
                        spacing: SetK.sm
                        Repeater {
                            model: SysTheme.fontSuggestions
                            delegate: Rectangle {
                                id: ft
                                required property var modelData
                                property bool have: SysTheme.hasFont(modelData.family)
                                width: (parent.width - SetK.sm) / 2; height: 60; radius: 12
                                color: fm.containsMouse && !have ? Theme.cardHi : Theme.track
                                border.width: 1; border.color: have ? Theme.tint(0.5) : Theme.border
                                Column {
                                    anchors { left: parent.left; leftMargin: 12; right: act.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    spacing: 2
                                    // instalada: o nome ja aparece na propria fonte
                                    UiText { width: parent.width; elide: Text.ElideRight; text: ft.modelData.family; color: Theme.text; font.pixelSize: 15; font.family: ft.have ? ft.modelData.family : Theme.font; font.weight: Font.DemiBold }
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
                        spacing: SetK.sm
                        UiField { id: gf; width: 280; placeholderText: "Outra do Google Fonts (ex.: Quicksand)"; onAccepted: if (text.trim() !== "") SysTheme.download(text.trim()) }
                        UiButton { icon: "download"; text: "Baixar"; kind: "accent"; enabled: gf.text.trim() !== "" && SysTheme.busy === ""; onClicked: SysTheme.download(gf.text.trim()) }
                    }
                }
            }
        }
    }

    // ---- apps padrao e webapps moram em Aplicativos ----
    SetSection {
        title: "Aplicativos"; icon: "apps"
        SetRow { icon: "apps"; label: "Aplicativos padrão e webapps"; description: "Mudaram para a página Aplicativos"; link: true; onClicked: Settings.settingsPage = "apps" }
    }
}
