// Bateria (UPower). Sem bateria de notebook (PC de mesa) fica "present: false" e tudo some.
// Avisa quando fica baixa / critica / cheia (notify-send), suspende sozinho se ligado, e lista aparelhos sem fio com pouca carga.
pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property bool present: !!dev && dev.ready && dev.isLaptopBattery && dev.isPresent
    readonly property real pct: present ? Math.max(0, Math.min(1, dev.percentage)) : 0      // 0..1
    readonly property bool charging: present && dev.state === UPowerDeviceState.Charging
    readonly property bool full: present && (dev.state === UPowerDeviceState.FullyCharged || pct >= 0.995)
    readonly property bool plugged: present && !(dev.state === UPowerDeviceState.Discharging)
    readonly property bool low: present && !plugged && pct * 100 <= Settings.batLow
    readonly property bool critical: present && !plugged && pct * 100 <= Settings.batCritical
    // segundos ate esvaziar / encher (0 = desconhecido)
    readonly property int eta: !present ? 0 : (plugged ? Math.round(dev.timeToFull) : Math.round(dev.timeToEmpty))
    function etaText(s) {
        if (s <= 0) return ""
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return h > 0 ? h + " h " + (m < 10 ? "0" : "") + m + " min" : m + " min"
    }
    readonly property string stateText: !present ? "" : (full ? "Carregada" : charging ? "Carregando" : plugged ? "Na tomada" : "Usando a bateria")

    // aparelhos sem fio (mouse, teclado, fone...) com pouca carga
    readonly property var lowDevices: UPower.devices.values.filter(d => d.ready && !d.isLaptopBattery && d.isPresent && d.type !== UPowerDeviceType.LinePower
        && d.percentage <= Settings.batPeripheralLow / 100)

    property bool _lowSent: false
    property bool _critSent: false
    property bool _fullSent: false
    function notify(title, body, urgency) {
        if (Settings.batNotify) Quickshell.execDetached(["notify-send", "-a", "Bateria", "-u", urgency, "-i", "battery", title, body])
    }
    onLowChanged: {
        if (low && !_lowSent) { _lowSent = true; notify("Bateria baixa", Math.round(pct * 100) + "% restante. Ligue o carregador.", "normal") }
        if (!low) _lowSent = false
    }
    onCriticalChanged: {
        if (critical && !_critSent) {
            _critSent = true
            notify("Bateria crítica", Math.round(pct * 100) + "%. O computador pode desligar a qualquer momento.", "critical")
            if (Settings.batAutoSuspend) suspendT.restart()
        }
        if (!critical) { _critSent = false; suspendT.stop() }
    }
    onFullChanged: {
        if (full && !_fullSent && Settings.batFullNotify) { _fullSent = true; notify("Bateria carregada", "Pode tirar o carregador.", "low") }
        if (!full) _fullSent = false
    }
    Timer { id: suspendT; interval: 30000; onTriggered: if (root.critical) Quickshell.execDetached(["systemctl", "suspend"]) }
}
