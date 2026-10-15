// Tela de bloqueio (protocolo de bloqueio de sessao do Wayland: o Hyprland so libera depois da senha certa).
// Wallpaper desfocado, relogio grande, foto de perfil e o campo de senha (verificada pelo PAM, servico "login").
// Se o shell travar com a tela bloqueada: Ctrl+Alt+F3, entre no terminal e rode
//   shell-switch restart && qs -c mine ipc call session lock      (depois volte com Ctrl+Alt+F1 e digite a senha)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

Scope {
    id: root

    property string pw: ""
    property bool checking: false
    property string error: ""
    property int fails: 0
    property bool leaving: false        // senha certa: animacao de saida antes de soltar a tela
    property bool caps: false

    // o bloqueio de verdade: so termina quando "locked" volta a falso
    WlSessionLock {
        id: lock
        locked: Power.locked
        onLockedChanged: if (locked) { root.pw = ""; root.error = ""; root.leaving = false; root.checking = false }

        WlSessionLockSurface {
            id: surf
            color: "black"
            LockView { anchors.fill: parent; screenName: surf.screen ? surf.screen.name : "" }
        }
    }

    PamContext {
        id: pam
        config: "login"
        onPamMessage: { if (responseRequired) respond(root.pw) }
        onCompleted: result => {
            root.checking = false
            if (result === PamResult.Success) {
                root.fails = 0
                root.leaving = true
                unlockTimer.restart()
            } else {
                root.fails++
                root.pw = ""
                root.error = result === PamResult.MaxTries ? "Muitas tentativas. Aguarde um pouco e tente de novo."
                    : (root.fails >= 3 ? "Senha incorreta. Depois de várias tentativas o sistema pode esperar alguns minutos." : "Senha incorreta")
            }
        }
        onError: err => { root.checking = false; root.pw = ""; root.error = "Não foi possível verificar a senha (" + PamError.toString(err) + ")" }
    }
    Timer { id: unlockTimer; interval: 420; onTriggered: { Power.locked = false; root.preview = false } }

    // previa (sem bloquear de verdade): qs -c mine ipc call session preview  (Esc fecha)
    property bool preview: false
    IpcHandler {
        target: "lockpreview"
        function toggle(): void { root.preview = !root.preview; root.pw = ""; root.error = ""; root.leaving = false }
    }
    LazyLoader {
        active: root.preview && !Power.locked
        PanelWindow {
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "mine-lock-preview"
            LockView { anchors.fill: parent; isPreview: true }
        }
    }
    function submit() {
        if (checking || leaving || pw === "") return
        error = ""
        checking = true
        pam.start()
    }

    // caps lock (le o LED do teclado enquanto bloqueado)
    Process {
        id: capsProc
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | sort -r | head -1"]
        stdout: StdioCollector { onStreamFinished: root.caps = text.trim() !== "" && text.trim() !== "0" }
    }
    Timer { interval: 500; repeat: true; running: Power.locked; triggeredOnStart: true; onTriggered: capsProc.running = true }

    // ---------- o que aparece em cada tela ----------
    component LockView: Item {
        id: v
        property string screenName
        property bool isPreview: false
        readonly property var anim: Settings.animOf("lock")

        // entrada: 0 -> 1 com a curva escolhida; saida (senha certa): volta a 0 rapido
        property real p: 0
        Component.onCompleted: p = Qt.binding(() => root.leaving ? 0 : 1)
        Behavior on p { NumberAnimation { duration: root.leaving ? 380 : v.anim.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.leaving ? [0.3, 0, 0.8, 0.15, 1, 1] : v.anim.curve } }

        // wallpaper desfocado e escurecido
        Image {
            id: wp
            anchors.fill: parent
            source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
            sourceSize: Qt.size(Math.round(width / 4), Math.round(height / 4))   // menor = desfoque mais forte e mais barato
            fillMode: Image.PreserveAspectCrop
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wp
            autoPaddingEnabled: false
            blurEnabled: Settings.lockBlur > 0
            blurMax: 64
            blur: Settings.lockBlur / 100 * (0.35 + 0.65 * Math.min(1, v.p))
            saturation: 0
            brightness: -0.06 * Math.min(1, v.p)
            scale: 1.08 - 0.08 * v.p
            opacity: Math.max(0, Math.min(1, v.p * 2))
        }
        Rectangle { anchors.fill: parent; color: "black"; opacity: Settings.lockDim / 100 * Math.min(1, v.p) }
        Rectangle {   // vinheta embaixo (o campo de senha fica legivel em qualquer wallpaper)
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: parent.height * 0.55
            opacity: Math.min(1, v.p)
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.45) }
            }
        }

        // ---- relogio ----
        SystemClock { id: clk; precision: Settings.lockSeconds ? SystemClock.Seconds : SystemClock.Minutes }
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.13 - (1 - v.p) * 60 }
            opacity: Math.max(0, Math.min(1, v.p * 1.4))
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clk.date, Settings.lockSeconds ? "HH:mm:ss" : "HH:mm")
                font.features: { "tnum": 1 }   // digitos de largura fixa: o relogio nao "pula" quando os numeros mudam
                color: "white"; font.pixelSize: 128; font.weight: Font.Bold
                style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.15)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
                color: Qt.rgba(1, 1, 1, 0.85); font.pixelSize: 22; font.weight: Font.Medium
            }
        }

        // ---- usuario + senha ----
        Column {
            id: box
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: parent.height * 0.12 + (1 - v.p) * 80 }
            opacity: Math.max(0, Math.min(1, v.p * 1.4))
            spacing: 16

            Avatar {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 112; ring: 3
                ringColor: root.error !== "" ? Theme.danger : Theme.accent
                Behavior on ringColor { ColorAnimation { duration: 200 } }
                scale: 0.8 + 0.2 * v.p
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Profile.name
                color: "white"; font.pixelSize: 24; font.weight: Font.Bold
            }

            // campo de senha
            Item {
                id: fieldWrap
                anchors.horizontalCenter: parent.horizontalCenter
                width: 340; height: 52
                // tremida quando a senha esta errada
                property real shake: 0
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: fieldWrap; property: "shake"; to: -12; duration: 50 }
                    NumberAnimation { target: fieldWrap; property: "shake"; to: 10; duration: 70 }
                    NumberAnimation { target: fieldWrap; property: "shake"; to: -6; duration: 60 }
                    NumberAnimation { target: fieldWrap; property: "shake"; to: 3; duration: 50 }
                    NumberAnimation { target: fieldWrap; property: "shake"; to: 0; duration: 40 }
                }
                Connections { target: root; function onErrorChanged() { if (root.error !== "") shakeAnim.restart() } }

                Rectangle {
                    id: field
                    x: fieldWrap.shake
                    width: parent.width; height: parent.height; radius: height / 2
                    color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.16 : 0.1)
                    border.width: input.activeFocus || root.error !== "" ? 2 : 1
                    border.color: root.error !== "" ? Theme.danger : (input.activeFocus ? Theme.accent : Qt.rgba(1, 1, 1, 0.18))
                    Behavior on border.color { ColorAnimation { duration: 160 } }
                    Behavior on color { ColorAnimation { duration: 160 } }

                    UiIcon {
                        id: lockIco
                        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                        name: root.leaving ? "unlock" : "lock"; size: 20
                        color: Qt.rgba(1, 1, 1, 0.75)
                    }

                    // a senha nunca aparece: so bolinhas (uma por caractere, entrando com um "pop")
                    TextInput {
                        id: input
                        anchors { left: lockIco.right; leftMargin: 12; right: go.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        height: parent.height
                        opacity: 0          // invisivel: so captura o teclado
                        echoMode: TextInput.Password
                        text: root.pw
                        onTextEdited: { root.pw = text; if (root.error !== "") root.error = "" }
                        onAccepted: root.submit()
                        focus: true
                        enabled: !root.checking && !root.leaving
                        Component.onCompleted: forceActiveFocus()
                        Keys.onEscapePressed: { if (v.isPreview) root.preview = false; root.pw = ""; text = "" }
                    }
                    Connections { target: root; function onPwChanged() { if (input.text !== root.pw) input.text = root.pw } }
                    Text {
                        anchors { left: input.left; verticalCenter: parent.verticalCenter }
                        visible: root.pw === ""
                        text: root.checking ? "Verificando…" : "Digite sua senha"
                        color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 15
                    }
                    Row {
                        anchors { left: input.left; verticalCenter: parent.verticalCenter }
                        width: input.width
                        clip: true
                        spacing: 7
                        layoutDirection: root.pw.length * 17 > input.width ? Qt.RightToLeft : Qt.LeftToRight
                        // bolinhas fixas (nao recriadas a cada tecla): cada uma so anima quando entra ou sai
                        Repeater {
                            model: 64
                            delegate: Rectangle {
                                required property int index
                                readonly property bool on: index < root.pw.length
                                visible: on || scale > 0.02
                                width: 10; height: 10; radius: 5
                                color: "white"
                                opacity: root.checking ? 0.5 : 1
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                scale: on ? 1 : 0
                                Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
                            }
                        }
                    }

                    // botao de enviar (gira enquanto verifica)
                    Rectangle {
                        id: go
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        width: 40; height: 40; radius: 20
                        color: root.pw !== "" || root.checking ? Theme.accent : Qt.rgba(1, 1, 1, 0.1)
                        Behavior on color { ColorAnimation { duration: 140 } }
                        UiIcon {
                            anchors.centerIn: parent
                            name: root.checking ? "refresh" : (root.leaving ? "check" : "arrowRight"); size: 20
                            color: root.pw !== "" || root.checking ? Theme.accentText : Qt.rgba(1, 1, 1, 0.6)
                            RotationAnimation on rotation { running: root.checking; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.submit() }
                    }
                }
            }

            // mensagens: erro ou caps lock
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 420; height: 20
                Text {
                    anchors.centerIn: parent
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root.error !== "" ? root.error : (root.caps ? "Caps Lock está ativado" : "")
                    color: root.error !== "" ? Qt.lighter(Theme.danger, 1.15) : Qt.rgba(1, 1, 1, 0.75)
                    font.pixelSize: 13; font.weight: Font.Medium
                }
            }
        }

        // ---- midia tocando (se houver) ----
        readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
        Rectangle {
            visible: !!v.player && Settings.lockMedia
            anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
            width: 300; height: 72; radius: 20
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)
            opacity: Math.max(0, Math.min(1, v.p * 1.4))
            RoundImage {
                id: art
                x: 12; anchors.verticalCenter: parent.verticalCenter
                width: 48; height: 48; radius: 12
                source: v.player ? (v.player.trackArtUrl ?? "") : ""
                sourceSize: Qt.size(96, 96)
            }
            Column {
                anchors { left: art.right; leftMargin: 12; right: ctl.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 2
                Text { width: parent.width; elide: Text.ElideRight; text: v.player ? (v.player.trackTitle || "Tocando") : ""; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { width: parent.width; elide: Text.ElideRight; text: v.player ? (v.player.trackArtist || v.player.identity) : ""; color: Qt.rgba(1, 1, 1, 0.65); font.pixelSize: 12 }
            }
            Row {
                id: ctl
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 2
                Repeater {
                    model: [["prev", () => v.player.previous()], ["pause", () => v.player.togglePlaying()], ["next", () => v.player.next()]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 30; height: 30; radius: 15
                        color: bm.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 18; color: "white" }
                        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (v.player) modelData[1]() }
                    }
                }
            }
        }

        // ---- energia (canto) ----
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
            spacing: 10
            opacity: Math.max(0, Math.min(1, v.p * 1.4))
            Repeater {
                model: [["sleep", "suspend", "Suspender"], ["restart", "reboot", "Reiniciar"], ["power", "poweroff", "Desligar"]]
                delegate: Rectangle {
                    id: pb
                    required property var modelData
                    property bool armed: false   // reiniciar/desligar: segundo clique confirma
                    width: armed ? 132 : 48; height: 48; radius: 24
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    color: armed ? Theme.danger : (pm.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        UiIcon { name: pb.modelData[0]; size: 20; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                        Text { visible: pb.armed; text: pb.modelData[2] + "?"; color: "white"; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Timer { id: disarm; interval: 3500; onTriggered: pb.armed = false }
                    MouseArea {
                        id: pm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const id = pb.modelData[1]
                            if (id === "suspend") { Quickshell.execDetached(["systemctl", "suspend"]); return }
                            if (!pb.armed) { pb.armed = true; disarm.restart(); return }
                            Quickshell.execDetached(["systemctl", id])
                        }
                    }
                }
            }
        }
    }
}
