// Comandos dos aplicativos padrao (Sistema > Aplicativos padrao): o que abre "configurar rede", "mixer de volume" etc.
// Settings.appCmds guarda so o que voce trocou; vazio = o padrao daqui. Use AppCmds.run("network") nos botoes do shell.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property var items: [
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth", def: "blueman-manager" },
        { id: "network", label: "Rede (Wi-Fi)", icon: "wifi", def: "nm-connection-editor" },
        { id: "ethernet", label: "Rede (cabo)", icon: "link", def: "nm-connection-editor" },
        { id: "mixer", label: "Mixer de volume", icon: "speaker", def: "pavucontrol" },
        { id: "taskManager", label: "Monitor de tarefas", icon: "chart", def: "kitty -e btop" },
        { id: "browser", label: "Navegador dos webapps (Chromium)", icon: "web", def: "brave" },
        { id: "terminal", label: "Terminal", icon: "desktop", def: "kitty" },
        { id: "update", label: "Atualizar o sistema", icon: "download", def: "kitty -e sh -c 'sudo pacman -Syu; echo; read -rp \"[Enter fecha] \" _'" },
        { id: "password", label: "Trocar a senha", icon: "lock", def: "kitty -e passwd" },
        { id: "users", label: "Gerenciar usuários", icon: "account", def: "kcmshell6 kcm_users" }
    ]
    function cmd(id: string): string {
        const m = Settings.appCmds || ({})
        const v = m[id]
        if (v !== undefined && String(v).trim() !== "") return String(v).trim()
        return (items.find(i => i.id === id) ?? { def: "" }).def
    }
    function run(id: string): void { const c = cmd(id); if (c !== "") Quickshell.execDetached(["sh", "-c", c]) }
    function set(id: string, v: string): void { const m = Object.assign({}, Settings.appCmds || ({})); if (v.trim() === "") delete m[id]; else m[id] = v.trim(); Settings.appCmds = m }
}
