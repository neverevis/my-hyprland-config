// Agente de polkit do shell (pedidos de senha de administrador: instalar, montar disco, mudar configuracoes do sistema).
// Desligado por padrao (Settings.polkitOn): so um agente pode estar registrado por sessao e o polkit-gnome costuma
// ser iniciado pelo Hyprland; para usar este, tire o polkit-gnome do autostart. Visual do cartao da tela de bloqueio.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import QtQuick

LazyLoader {
    active: Settings.polkitOn   // o agente so existe (e se registra) quando ligado

    Scope {
    id: root
    PolkitAgent { id: agent }
    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive && !!flow
    Binding { target: Settings; property: "polkitRegistered"; value: agent.isRegistered }
    Component.onDestruction: Settings.polkitRegistered = false

    // texto digitado e estado de "pode enviar" compartilhados entre as janelas (uma por monitor)
    property string passText: ""
    property bool ready: true
    function send() { if (flow && ready && passText !== "") { ready = false; flow.submit(passText) } }
    onFlowChanged: { passText = ""; ready = true }
    Connections {
        target: root.flow
        function onAuthenticationRequestStarted() { root.ready = true }
        function onAuthenticationFailed() { root.passText = ""; root.ready = true }
    }
    readonly property string focusedName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""

    LazyLoader {
        active: root.active

        Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            // so a copia do monitor focado toma o teclado; as outras so espelham o texto
            WlrLayershell.keyboardFocus: (root.focusedName === "" || modelData.name === root.focusedName) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "mine-polkit"
            readonly property var f: root.flow
            property real k: 0
            Component.onCompleted: k = 1
            Behavior on k { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.5 * win.k) }
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 440; height: col.implicitHeight + 48
                radius: 26
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.97)
                border.width: 1; border.color: Theme.border
                scale: 0.94 + 0.06 * win.k; opacity: win.k
                property real shake: 0
                transform: Translate { x: card.shake }
                SequentialAnimation {
                    id: shakeA
                    NumberAnimation { target: card; property: "shake"; to: -12; duration: 50 }
                    NumberAnimation { target: card; property: "shake"; to: 10; duration: 70 }
                    NumberAnimation { target: card; property: "shake"; to: -5; duration: 60 }
                    NumberAnimation { target: card; property: "shake"; to: 0; duration: 50 }
                }
                Connections { target: win.f; function onAuthenticationFailed() { shakeA.restart() } }
                Column {
                    id: col
                    x: 24; y: 24; width: parent.width - 48
                    spacing: 14
                    Row {
                        spacing: 14
                        Avatar { size: 56; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            UiText { text: "Autenticação necessária"; color: Theme.text; font.pixelSize: 17; font.weight: Font.Bold }
                            UiText { text: win.f && win.f.selectedIdentity ? "Como " + (win.f.selectedIdentity.displayName || Profile.user) : Profile.user; color: Theme.muted; font.pixelSize: 12 }
                        }
                    }
                    UiText { width: parent.width; wrapMode: Text.WordWrap; text: win.f ? win.f.message.replace(/\.\s*$/, "") : ""; color: Theme.text; font.pixelSize: 13 }
                    UiText { visible: text !== ""; width: parent.width; wrapMode: Text.WordWrap; text: win.f ? win.f.supplementaryMessage : ""; color: win.f && win.f.supplementaryIsError ? Theme.danger : Theme.muted; font.pixelSize: 12 }
                    Rectangle {
                        width: parent.width; height: 44; radius: 14
                        color: Theme.track; border.width: 1; border.color: pass.activeFocus ? Theme.accent : Theme.border
                        UiIcon { id: li; x: 14; anchors.verticalCenter: parent.verticalCenter; name: "lock"; size: 16; color: Theme.muted }
                        TextInput {
                            font.family: Theme.font
                            id: pass
                            anchors { left: li.right; leftMargin: 10; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            echoMode: win.f && win.f.responseVisible ? TextInput.Normal : TextInput.Password
                            color: Theme.text; font.pixelSize: 15
                            focus: true
                            enabled: root.ready
                            text: root.passText
                            onTextEdited: root.passText = text
                            Component.onCompleted: forceActiveFocus()
                            onEnabledChanged: if (enabled) forceActiveFocus()
                            onAccepted: root.send()
                            Keys.onEscapePressed: if (win.f) win.f.cancelAuthenticationRequest()
                            UiText { visible: !pass.text; anchors.verticalCenter: parent.verticalCenter; text: win.f && win.f.inputPrompt ? win.f.inputPrompt.replace(/:\s*$/, "") : "Senha"; color: Theme.muted; font.pixelSize: 15 }
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        spacing: 8
                        UiButton { text: "Cancelar"; kind: "ghost"; onClicked: if (win.f) win.f.cancelAuthenticationRequest() }
                        UiButton { icon: "check"; text: "Autorizar"; kind: "accent"; enabled: root.ready; onClicked: root.send() }
                    }
                }
            }
        }
        }
    }
}
}
