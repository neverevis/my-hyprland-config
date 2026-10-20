// VPN pelo NetworkManager (nmcli): lista os perfis (vpn / wireguard), liga, troca, apaga e importa (.conf / .ovpn).
// Quem usa chama Vpn.refresh() enquanto mostra algo (a aba VPN do Inicio atualiza a cada 4 s; o botao rapido a cada 15 s).
// Importar abre o zenity para escolher o arquivo. Precisa do nmcli (NetworkManager); sem ele, tudo fica vazio.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var profiles: []            // [{ name, uuid, type }]
    property var activeUuids: []
    property string pendingUuid: ""      // trocar de VPN: desliga a atual e liga esta
    property string lastError: ""
    readonly property bool busy: upProc.running || downProc.running || actProc.running
    readonly property var activeProfile: profiles.find(p => activeUuids.indexOf(p.uuid) >= 0) ?? null
    readonly property var selectedProfile: activeProfile ?? profiles.find(p => p.uuid === Settings.vpnProfile) ?? profiles[0] ?? null
    readonly property bool connected: activeProfile !== null
    readonly property bool has: profiles.length > 0

    function fields(line) {   // campos do "nmcli -t" (: separa, \\ escapa)
        const out = []; let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) cur += line[++i]
            else if (c === ":") { out.push(cur); cur = "" }
            else cur += c
        }
        out.push(cur)
        return out
    }
    function refresh() { if (!listProc.running) listProc.running = true }
    function fail(msg) {
        root.lastError = msg
        Quickshell.execDetached(["notify-send", "-a", "Shell", "VPN", msg])
    }

    function toggle() {
        const p = root.selectedProfile
        if (!p || busy) return false
        if (root.connected) downProc.exec(["nmcli", "connection", "down", "uuid", root.activeProfile.uuid])
        else upProc.exec(["nmcli", "connection", "up", "uuid", p.uuid])
        return true
    }
    function connectTo(uuid) {
        if (busy) return
        if (root.connected && root.activeProfile.uuid === uuid) { downProc.exec(["nmcli", "connection", "down", "uuid", uuid]); return }
        Settings.vpnProfile = uuid
        if (root.connected) { root.pendingUuid = uuid; downProc.exec(["nmcli", "connection", "down", "uuid", root.activeProfile.uuid]) }
        else upProc.exec(["nmcli", "connection", "up", "uuid", uuid])
    }
    function remove(uuid) { actProc.exec(["nmcli", "connection", "delete", "uuid", uuid]) }
    function importFile(path) {
        const f = String(path || "").trim()
        if (f === "") return
        const type = f.toLowerCase().endsWith(".ovpn") ? "openvpn" : "wireguard"
        actProc.exec(["nmcli", "connection", "import", "type", type, "file", f])
    }
    function pickAndImport() { if (!pickProc.running) pickProc.running = true }

    Process {
        id: listProc
        command: ["sh", "-c", "nmcli -t -f NAME,UUID,TYPE connection show 2>/dev/null; echo :::ATIVOS; nmcli -t -f UUID connection show --active 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split(":::ATIVOS")
                const found = []
                for (const line of parts[0].split("\n")) {
                    const f = root.fields(line)
                    if (f.length >= 3 && (f[2] === "vpn" || f[2] === "wireguard")) found.push({ name: f[0], uuid: f[1], type: f[2] })
                }
                root.profiles = found
                root.activeUuids = (parts[1] ?? "").split("\n").map(s => s.trim()).filter(s => s !== "")
            }
        }
    }
    Process {
        id: upProc
        stderr: StdioCollector { id: upErr }
        onExited: code => { if (code !== 0) root.fail(upErr.text.trim() || "Não consegui conectar."); root.refresh() }
    }
    Process {
        id: downProc
        onExited: {
            if (root.pendingUuid !== "") { const u = root.pendingUuid; root.pendingUuid = ""; upProc.exec(["nmcli", "connection", "up", "uuid", u]); return }
            root.refresh()
        }
    }
    Process {
        id: actProc
        stderr: StdioCollector { id: actErr }
        onExited: code => { if (code !== 0) root.fail(actErr.text.trim() || "Não consegui concluir."); root.refresh() }
    }
    Process {
        id: pickProc
        command: ["sh", "-c", "zenity --file-selection --title='Importar VPN' --file-filter='Configuração de VPN | *.conf *.ovpn' --file-filter='Todos | *' 2>/dev/null"]
        stdout: StdioCollector { id: pickOut; onStreamFinished: root.importFile(pickOut.text) }
    }
    // atualiza de vez em quando mesmo sem a aba aberta: o botao rapido mostra o estado
    Timer { interval: 15000; repeat: true; running: Settings.homeOpen; triggeredOnStart: true; onTriggered: root.refresh() }
}
