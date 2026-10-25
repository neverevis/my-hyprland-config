// Pagina "Rede e Bluetooth" (kit Set*): Wi-Fi (ligar, conexao atual, lista com senha e esquecer), cabo, VPN (perfis do
// NetworkManager, mesma logica da aba VPN do Inicio) e Bluetooth (ligar, pareados, procurar novos). Usa as APIs do Quickshell
// (Networking / Bluetooth), como o painel Inicio; a senha vai direto ao NetworkManager e nunca e logada.
// Busca de redes e de dispositivos so enquanto a pagina esta visivel (a busca Bluetooth para sozinha em 30 s).
// Modo de teste (SysAct.dry): ligar/desligar, conectar, esquecer, parear e VPN so sao logados.
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick

SetPage {
    id: page
    title: "Rede e Bluetooth"
    subtitle: "Wi-Fi, cabo, VPN e dispositivos Bluetooth"
    readonly property bool live: visible && Settings.settingsOpen
    onLiveChanged: {
        if (live) { SysAct.check(); Vpn.refresh(); ipT.restart() }
        else { askName = ""; confirmVpn = ""; if (bt && bt.discovering) bt.discovering = false }
    }
    Component.onDestruction: if (bt && bt.discovering) bt.discovering = false

    // ---- Wi-Fi e cabo ----
    readonly property var devs: Networking.devices.values
    readonly property var wifi: devs.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devs.find(d => d.type === DeviceType.Wired && d.connected) ?? devs.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var nets: wifi ? wifi.networks.values : []
    readonly property var cur: nets.find(n => n.connected) ?? null
    readonly property var sorted: nets.slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
    property string askName: ""      // rede protegida esperando a senha
    property string confirmVpn: ""   // uuid esperando confirmar a exclusao
    Binding { target: page.wifi; property: "scannerEnabled"; value: page.live && Networking.wifiEnabled; when: !!page.wifi }
    function sigIcon(s) { return s > 0.75 ? "wifi4" : (s > 0.5 ? "wifi3" : (s > 0.25 ? "wifi2" : "wifi1")) }

    // enderecos IP e gateway (uma consulta ao abrir e quando a conexao muda)
    property var ips: ({})
    property string gateway: ""
    Timer { id: ipT; interval: 700; onTriggered: if (page.live && !ipP.running) ipP.running = true }
    readonly property string connSig: (cur ? cur.name : "") + "|" + (wired ? wired.connected : "")
    onConnSigChanged: ipT.restart()
    Process {
        id: ipP
        command: ["sh", "-c", "ip -4 -o addr show scope global | awk '{print $2\" \"$4}'; echo '--'; ip route show default | awk '{print $3; exit}'"]
        stdout: StdioCollector { onStreamFinished: {
            const parts = text.split("--"), m = {}
            parts[0].trim().split("\n").forEach(l => { const p = l.split(" "); if (p.length > 1) m[p[0]] = p[1].split("/")[0] })
            page.ips = m; page.gateway = (parts[1] || "").trim()
        } }
    }

    // acoes (em teste so logam)
    function wifiConnect(n) { if (SysAct.real("wifi: conectar " + n.name)) n.connect() }
    function wifiPsk(n, pw) { if (SysAct.real("wifi: conectar com senha " + n.name)) n.connectWithPsk(pw) }   // a senha nunca entra no log
    function wifiDisconnect(n) { if (SysAct.real("wifi: desconectar " + n.name)) n.disconnect() }
    function wifiForget(n) { if (SysAct.real("wifi: esquecer " + n.name)) n.forget() }

    // linha de lista (Wi-Fi e Bluetooth): icone, nome, estado e botoes no fim
    component ListRow: Item {
        id: lr
        property string icon
        property string title
        property string desc
        property bool active: false
        property int extra: 0           // altura a mais embaixo (campo de senha)
        default property alias trailing: tr.data
        property alias below: bl.data
        width: parent ? parent.width : 300
        height: SetK.rowH - 4 + extra
        Rectangle {
            width: parent.width; height: SetK.rowH - 8; radius: SetK.innerRadius
            color: lr.active ? Theme.tint(0.14) : (hv.hovered ? Theme.cardHi : "transparent")
            HoverHandler { id: hv }
            UiIcon { id: ic; anchors { left: parent.left; leftMargin: SetK.md; verticalCenter: parent.verticalCenter } name: lr.icon; size: 20; color: lr.active ? Theme.accent : Theme.text }
            Column {
                anchors { left: ic.right; leftMargin: SetK.md; right: tr.left; rightMargin: SetK.sm; verticalCenter: parent.verticalCenter }
                spacing: 2
                UiText { width: parent.width; elide: Text.ElideRight; text: lr.title; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium }
                UiText { width: parent.width; elide: Text.ElideRight; text: lr.desc; color: Theme.muted; font.pixelSize: SetK.fDesc }
            }
            Row { id: tr; anchors { right: parent.right; rightMargin: SetK.sm; verticalCenter: parent.verticalCenter } spacing: SetK.xs }
        }
        Item { id: bl; y: SetK.rowH - 8; width: parent.width; height: lr.extra }
    }

    // ================= Wi-Fi =================
    SetSection {
        title: "Wi-Fi"; icon: "wifi"
        subtitle: !page.wifi ? "Nenhuma placa Wi-Fi neste computador" : !Networking.wifiEnabled ? "Desligado" : page.cur ? "Conectado a " + page.cur.name : "Sem conexão"
        SetRow { visible: !page.wifi; icon: "wifiOff"; label: "Sem Wi-Fi"; description: "Este computador não tem placa de rede sem fio" }
        SetRow {
            visible: !!page.wifi
            icon: Networking.wifiEnabled ? "wifi" : "wifiOff"; label: "Wi-Fi"; description: "Ligar ou desligar a placa de rede sem fio"
            checked: Networking.wifiEnabled
            onToggled: on => { if (SysAct.real("wifi: " + (on ? "ligar" : "desligar"))) Networking.wifiEnabled = on }
        }
        SetBlock {
            visible: !!page.wifi && Networking.wifiEnabled && !!page.cur
            Row {
                width: parent.width; spacing: SetK.md
                Rectangle {
                    id: ci
                    width: 44; height: 44; radius: 13; color: Theme.accent
                    UiIcon { anchors.centerIn: parent; name: page.cur ? page.sigIcon(page.cur.signalStrength) : "wifi"; size: 22; color: Theme.accentText }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - ci.width - SetK.md
                    spacing: 2
                    UiText { width: parent.width; elide: Text.ElideRight; text: page.cur ? page.cur.name : ""; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                    UiText { width: parent.width; elide: Text.ElideRight; color: Theme.muted; font.pixelSize: SetK.fDesc
                        text: page.cur ? "Sinal " + Math.round(page.cur.signalStrength * 100) + "% · " + (page.wifi && page.ips[page.wifi.name] ? "IP " + page.ips[page.wifi.name] : "sem IP") + (page.gateway !== "" ? " · gateway " + page.gateway : "") : "" }
                }
            }
        }
        SetBlock {
            visible: !!page.wifi && Networking.wifiEnabled
            UiText { visible: page.sorted.length === 0; width: parent.width; text: "Procurando redes…"; color: Theme.muted; font.pixelSize: SetK.fDesc }
            ListView {
                id: wl
                width: parent.width
                height: Math.min(contentHeight, 380)
                visible: page.sorted.length > 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                cacheBuffer: 200
                model: ScriptModel { values: page.sorted; objectProp: "name" }
                delegate: ListRow {
                    id: nr
                    required property var modelData
                    readonly property bool secure: modelData.security !== WifiSecurityType.Open
                    readonly property bool asking: page.askName === modelData.name
                    width: wl.width
                    icon: page.sigIcon(modelData.signalStrength)
                    title: modelData.name
                    active: modelData.connected
                    desc: (modelData.connected ? "Conectado" : (modelData.stateChanging ? "Conectando…" : (modelData.known ? "Salva" : (secure ? "Protegida" : "Aberta")))) + " · " + Math.round(modelData.signalStrength * 100) + "%"
                    extra: asking ? 52 : 0
                    UiIcon { visible: nr.secure && !nr.modelData.known; anchors.verticalCenter: parent.verticalCenter; name: "lock"; size: 14; color: Theme.muted }
                    UiButton { visible: nr.modelData.known && !nr.modelData.connected; icon: "trash"; kind: "ghost"; onClicked: page.wifiForget(nr.modelData) }
                    UiButton {
                        text: nr.modelData.connected ? "Desconectar" : "Conectar"
                        kind: nr.modelData.connected ? "normal" : "accent"
                        onClicked: {
                            if (nr.modelData.connected) page.wifiDisconnect(nr.modelData)
                            else if (nr.modelData.known || !nr.secure) page.wifiConnect(nr.modelData)
                            else page.askName = nr.asking ? "" : nr.modelData.name
                        }
                    }
                    below: Row {
                        visible: nr.asking
                        x: SetK.md + 20 + SetK.md; spacing: SetK.sm
                        UiField {
                            id: pw
                            width: nr.width - x - SetK.sm - okBtn.width - SetK.sm
                            echoMode: TextInput.Password
                            placeholderText: "Senha de " + nr.modelData.name
                            onVisibleChanged: if (visible) forceActiveFocus()
                            onAccepted: okBtn.clicked()
                        }
                        UiButton { id: okBtn; icon: "check"; text: "Conectar"; kind: "accent"; enabled: pw.text.length >= 8 || nr.modelData.security === WifiSecurityType.Wep; onClicked: { page.wifiPsk(nr.modelData, pw.text); pw.text = ""; page.askName = "" } }
                    }
                }
            }
        }
    }

    // ================= cabo =================
    SetSection {
        visible: !!page.wired
        title: "Cabo"; icon: "ethernet"
        SetRow {
            icon: "ethernet"
            label: page.wired ? page.wired.name : ""
            description: !page.wired ? "" : page.wired.connected
                ? "Conectado · " + (page.ips[page.wired.name] ? "IP " + page.ips[page.wired.name] : "sem IP") + (page.wired.linkSpeed ? " · " + page.wired.linkSpeed + " Mb/s" : "") + (!page.cur && page.gateway !== "" ? " · gateway " + page.gateway : "")
                : "Cabo desconectado"
        }
    }

    // ================= VPN =================
    SetSection {
        title: "VPN"; icon: "shieldLock"
        subtitle: Vpn.connected ? "Conectada: " + Vpn.activeProfile.name : (Vpn.has ? "Desconectada" : "Nenhum perfil; importe um .conf (WireGuard) ou .ovpn (OpenVPN)")
        Timer { interval: 8000; repeat: true; running: page.live; onTriggered: Vpn.refresh() }
        Repeater {
            model: Vpn.profiles
            delegate: SetRow {
                id: vr
                required property var modelData
                readonly property bool on: Vpn.activeUuids.indexOf(modelData.uuid) >= 0
                icon: on ? "shieldLock" : "shield"; label: modelData.name
                description: (on ? "Conectada · " : "") + (modelData.type === "wireguard" ? "WireGuard" : "OpenVPN")
                UiButton { visible: page.confirmVpn !== vr.modelData.uuid; icon: "trash"; kind: "ghost"; onClicked: page.confirmVpn = vr.modelData.uuid }
                UiButton { visible: page.confirmVpn === vr.modelData.uuid; text: "Cancelar"; kind: "ghost"; onClicked: page.confirmVpn = "" }
                UiButton { visible: page.confirmVpn === vr.modelData.uuid; text: "Apagar"; kind: "danger"; onClicked: { page.confirmVpn = ""; if (SysAct.real("vpn: apagar " + vr.modelData.name)) Vpn.remove(vr.modelData.uuid) } }
                UiButton {
                    visible: page.confirmVpn !== vr.modelData.uuid
                    text: vr.on ? "Desligar" : "Ligar"; kind: vr.on ? "normal" : "accent"; enabled: !Vpn.busy
                    onClicked: { if (SysAct.real("vpn: " + (vr.on ? "desligar " : "ligar ") + vr.modelData.name)) Vpn.connectTo(vr.modelData.uuid) }
                }
            }
        }
        SetRow {
            icon: "plus"; label: "Importar perfil"; description: Vpn.lastError !== "" ? Vpn.lastError : "Escolhe o arquivo .conf ou .ovpn numa janela do sistema (precisa do zenity)"
            UiButton { icon: "download"; text: "Importar"; kind: "accent"; enabled: !Vpn.busy; onClicked: { if (SysAct.real("vpn: importar")) Vpn.pickAndImport() } }
        }
    }

    // ================= Bluetooth =================
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btDevs: bt ? bt.devices.values : []
    readonly property var paired: btDevs.filter(d => d.paired || d.bonded).sort((a, b) => (b.connected - a.connected) || (b.batteryAvailable - a.batteryAvailable))
    readonly property var found: btDevs.filter(d => !d.paired && !d.bonded && d.name)
    function devIcon(i) {
        i = i || ""
        return i.indexOf("audio") >= 0 || i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0 ? "headphones"
            : i.indexOf("input-mouse") >= 0 ? "mouse" : i.indexOf("input-keyboard") >= 0 ? "keyboard"
            : i.indexOf("phone") >= 0 ? "cellphone" : i.indexOf("gaming") >= 0 ? "gamepad" : "bluetooth"
    }
    function devDesc(d) {
        return (d.pairing ? "Pareando…" : d.connected ? "Conectado" : d.paired ? "Pareado" : d.address) + (d.batteryAvailable ? " · bateria " + Math.round(d.battery * 100) + "%" : "")
    }
    // procurar: so com a pagina visivel; para sozinho em 30 s
    function scanToggle() { if (bt) bt.discovering = !bt.discovering }
    Timer { id: scanT; interval: 30000; running: page.live && !!page.bt && page.bt.discovering; onTriggered: if (page.bt) page.bt.discovering = false }

    SetSection {
        title: "Bluetooth"; icon: "bluetooth"
        subtitle: !page.bt ? "Nenhum adaptador Bluetooth" : !page.bt.enabled ? "Desligado" : page.paired.filter(d => d.connected).length + " conectado(s), " + page.paired.length + " pareado(s)"
        SetRow {
            visible: !!page.bt
            icon: "bluetooth"; label: "Bluetooth"; description: "Ligar ou desligar o adaptador"
            checked: !!page.bt && page.bt.enabled
            onToggled: on => { if (page.bt && SysAct.real("bluetooth: " + (on ? "ligar" : "desligar"))) page.bt.enabled = on }
        }
        SetRow { visible: !page.bt; icon: "info"; label: "Sem adaptador"; description: "Se o computador tiver um, ative o serviço: systemctl enable --now bluetooth" }
        SetBlock {
            visible: !!page.bt && page.bt.enabled
            UiText { visible: page.paired.length === 0; width: parent.width; text: "Nenhum dispositivo pareado."; color: Theme.muted; font.pixelSize: SetK.fDesc }
            ListView {
                id: pl
                width: parent.width
                height: Math.min(contentHeight, 300)
                visible: page.paired.length > 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                model: ScriptModel { values: page.paired; objectProp: "address" }
                delegate: ListRow {
                    id: pr
                    required property var modelData
                    width: pl.width
                    icon: page.devIcon(modelData.icon); title: modelData.name || modelData.address
                    desc: page.devDesc(modelData); active: modelData.connected
                    UiButton { icon: "trash"; kind: "ghost"; onClicked: { if (SysAct.real("bluetooth: remover " + pr.modelData.address)) pr.modelData.forget() } }
                    UiButton {
                        text: pr.modelData.connected ? "Desconectar" : "Conectar"; kind: pr.modelData.connected ? "normal" : "accent"
                        onClicked: { if (SysAct.real("bluetooth: " + (pr.modelData.connected ? "desconectar " : "conectar ") + pr.modelData.address)) { if (pr.modelData.connected) pr.modelData.disconnect(); else pr.modelData.connect() } }
                    }
                }
            }
        }
    }
    SetSection {
        visible: !!page.bt && page.bt.enabled
        title: "Novos dispositivos"; icon: "devices"
        subtitle: page.bt && page.bt.discovering ? "Procurando por perto; para sozinho em 30 segundos" : "A busca só roda enquanto você pede"
        SetRow {
            icon: page.bt && page.bt.discovering ? "refresh" : "magic"; label: "Procurar dispositivos"
            description: page.bt && page.bt.discovering ? "Deixe o aparelho em modo de pareamento" : "Gasta o rádio do Bluetooth; use só para parear"
            UiButton { icon: page.bt && page.bt.discovering ? "close" : "magic"; text: page.bt && page.bt.discovering ? "Parar" : "Procurar"; kind: page.bt && page.bt.discovering ? "normal" : "accent"; onClicked: page.scanToggle() }
        }
        SetBlock {
            visible: page.found.length > 0
            ListView {
                id: fl
                width: parent.width
                height: Math.min(contentHeight, 260)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                model: ScriptModel { values: page.found; objectProp: "address" }
                delegate: ListRow {
                    id: fr
                    required property var modelData
                    width: fl.width
                    icon: page.devIcon(modelData.icon); title: modelData.name; desc: page.devDesc(modelData)
                    UiButton { text: "Parear"; kind: "accent"; onClicked: { if (SysAct.real("bluetooth: parear " + fr.modelData.address)) { fr.modelData.trusted = true; fr.modelData.pair() } } }
                }
            }
        }
    }
}
