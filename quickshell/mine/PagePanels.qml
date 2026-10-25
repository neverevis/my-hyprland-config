// Pagina "Paineis": escolhe qual painel ajustar (Inicio, Launcher, Notificacoes, Visao geral, Barra lateral) e mostra
// a pagina dele logo abaixo (so a escolhida existe). Visao geral e Barra lateral ainda moram nas paginas do launcher e
// do Inicio: a escolha abre a pagina e rola ate o cartao delas.
import QtQuick

Column {
    id: page
    spacing: SetK.xl
    readonly property var subs: [
        ["home", "Início", "dashboard"], ["launcher", "Launcher", "apps"], ["notifications", "Notificações", "bell"],
        ["overview", "Visão geral", "view_grid"], ["left", "Barra lateral", "dock"]
    ]
    // sub-pagina -> [pagina real, cartao para rolar]
    readonly property var host: ({ home: ["home", ""], launcher: ["launcher", ""], notifications: ["notifications", ""], overview: ["launcher", "Visão geral"], left: ["home", "Início e mídia"] })
    readonly property string sub: host[Settings.settingsSub] ? Settings.settingsSub : "home"
    readonly property string real: host[sub][0]

    SetSection {
        SetChoice {
            style: "tiles"
            minTile: 100
            thumbHeight: 52
            options: page.subs
            value: page.sub
            onPicked: v => { Settings.settingsSub = v; if (page.host[v][1] !== "") Settings.settingsReveal = page.host[v][1] }
        }
    }
    Loader {
        width: parent.width
        sourceComponent: page.real === "launcher" ? launcherC : page.real === "notifications" ? notifC : homeC
    }
    Component { id: homeC; PageHome {} }
    Component { id: launcherC; PageLauncher {} }
    Component { id: notifC; PageNotifications {} }
}
