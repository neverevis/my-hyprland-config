// Pagina "Wallpaper" (kit Set*): previa grande do wallpaper atual com os botoes de troca, estilo (normal, numa forma,
// mosaico), transicao em cartoes (a miniatura so anima com o mouse em cima), efeitos, troca automatica, videos,
// tela de bloqueio, o seletor (Super + W) e a busca no Wallhaven. O avancado fica nos expansores.
import Quickshell
import QtQuick
import QtQuick.Effects

SetPage {
    id: page
    title: "Wallpaper"
    subtitle: (Wallpaper.files.length === 0 ? "Nenhuma imagem" : Wallpaper.files.length === 1 ? "1 imagem" : Wallpaper.files.length.toLocaleString(Qt.locale("pt_BR"), "f", 0) + " imagens") + " em " + Wallpaper.dir

    // ---- previa grande + troca rapida ----
    preview: SetPreview {
        height: 260
        RoundImage {
            anchors.fill: parent
            radius: SetK.boxRadius + 3
            source: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
            sourceSize: Qt.size(960, 540)
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
            height: 52; radius: 16
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.86)
            Column {
                anchors { left: parent.left; leftMargin: 16; right: btns.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                UiText { width: parent.width; elide: Text.ElideMiddle; text: Wallpaper.current.split("/").pop() || "Nenhum"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                UiText { text: ({ fill: "Normal", centered: "Centralizado", collage: "Mosaico" })[Settings.wpMode] ?? ""; color: Theme.muted; font.pixelSize: 11 }
            }
            Row {
                id: btns
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 4
                UiButton { icon: "prev"; kind: "ghost"; onClicked: Wallpaper.step(-1) }
                UiButton { icon: "next"; kind: "ghost"; onClicked: Wallpaper.step(1) }
                UiButton { icon: "dice"; kind: "ghost"; onClicked: Wallpaper.random() }
                UiButton { icon: "images"; text: "Escolher imagem"; kind: "accent"; onClicked: Settings.wpPickerOpen = true }
            }
        }
    }

    // ---- estilo ----
    SetSection {
        title: "Estilo"
        icon: "image"
        SetChoice {
            label: ""
            style: "tiles"; columns: 3; thumbHeight: 70
            options: [["fill", "Normal", "fullscreen"], ["centered", "Numa forma", "flower"], ["collage", "Mosaico", "view_grid"]]
            value: Settings.wpMode
            onPicked: v => Settings.wpMode = v
            thumb: Item {
                id: st
                property var opt
                property bool on
                property bool hovered
                readonly property string m: opt ? opt[0] : "fill"
                Rectangle {
                    anchors.fill: parent; radius: 10
                    color: st.m === "fill" ? "transparent" : Theme.role(Settings.wpBgRole)
                    gradient: st.m === "fill" ? fillG : null
                    Gradient { id: fillG; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.primaryContainer } GradientStop { position: 1; color: Theme.tertiaryContainer } }
                }
                Flower {
                    visible: st.m === "centered"
                    anchors.centerIn: parent
                    width: parent.height * 0.72; height: width
                    shape: Settings.wpCenterShape; sides: Settings.wpCenterSides; animated: false
                    color: Theme.primary
                }
                Grid {
                    visible: st.m === "collage"
                    anchors.fill: parent; anchors.margins: 6
                    columns: 2; spacing: 4
                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            required property int index
                            width: (parent.width - 4) / 2; height: (parent.height - 4) / 2; radius: 5
                            color: [Theme.primary, Theme.secondary, Theme.tertiary, Theme.surfaceHighest][index]
                        }
                    }
                }
            }
        }
        SetColor {
            visible: Settings.wpMode !== "fill"
            icon: "swatch"; label: "Cor do fundo"
            roles: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "primary", "secondary", "tertiary", "surfaceHigh", "surfaceLow", "bg"]
            value: Settings.wpBgRole; onPicked: v => Settings.wpBgRole = v
        }
        // numa forma
        SetRow {
            visible: Settings.wpMode === "centered"
            icon: "shape"; label: "Forma"
            below: ShapePicker { width: parent ? parent.width : 300; value: Settings.wpCenterShape; sides: Settings.wpCenterSides; onPicked: v => Settings.wpCenterShape = v }
        }
        SetSlider {
            visible: Settings.wpMode === "centered"
            icon: "resize"; label: "Tamanho"; from: 20; to: 95; unit: " %"; def: 55
            value: Settings.wpCenterSize; onMoved: v => Settings.wpCenterSize = Math.round(v)
        }
        SetExpander {
            visible: Settings.wpMode === "centered"
            icon: "tune"; label: "Mais da forma"; description: "Pétalas, giro e bloqueio"
            SetSlider { visible: Settings.wpCenterShape === "flower"; sub: true; label: "Pétalas"; from: 4; to: 20; ticks: true; def: 12; value: Settings.wpCenterSides; onMoved: v => Settings.wpCenterSides = Math.round(v) }
            SetRow { sub: true; label: "Girar devagar"; checked: Settings.wpCenterSpin; onToggled: on => Settings.wpCenterSpin = on }
            SetRow { sub: true; label: "Só na tela de bloqueio"; description: "Ao desbloquear, a forma cresce e cobre a tela"; checked: Settings.wpCenterLocked; onToggled: on => Settings.wpCenterLocked = on }
        }
        // mosaico
        SetChoice {
            visible: Settings.wpMode === "collage"
            icon: "view_grid"; label: "Arranjo"; description: Collage.custom ? "Personalizado no editor" : ""
            style: "tiles"; minTile: 84; thumbHeight: 40
            options: Collage.presetNames.map(n => [n[0], n[1], "view_grid"])
            value: ""
            canReset: Collage.custom
            onReset: Collage.reset()
            onPicked: v => Collage.setPreset(v)
        }
        SetExpander {
            visible: Settings.wpMode === "collage"
            icon: "imageEdit"; label: "Editor do mosaico"; description: "Divisões, imagens e espaços"
            SetSlider { sub: true; label: "Espaço entre imagens"; from: 0; to: 80; unit: " px"; def: 24; value: Settings.wpCollageGap; onMoved: v => Settings.wpCollageGap = Math.round(v) }
            SetSlider { sub: true; label: "Margem da tela"; from: 0; to: 200; step: 5; unit: " px"; def: 60; value: Settings.wpCollageMargin; onMoved: v => Settings.wpCollageMargin = Math.round(v) }
            SetSlider { sub: true; label: "Arredondamento"; from: 0; to: 60; unit: " px"; def: 24; value: Settings.wpCollageRadius; onMoved: v => Settings.wpCollageRadius = Math.round(v) }
            SetRow { sub: true; label: "Imagens entram voando"; checked: Settings.wpCollageEntrance; onToggled: on => Settings.wpCollageEntrance = on }
            lazy: Component {
                SetBlock {
                    sub: true
                    UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: "Arraste as divisões. Em cada imagem: estrela (fundo desfocado), trocar, dividir e remover. Até 6." }
                    Item {
                        id: ed
                        width: parent.width; height: Math.min(240, width * 9 / 16)
                        Rectangle { anchors.fill: parent; radius: 10; color: Theme.track; border.width: 1; border.color: Theme.border }
                        Repeater {
                            model: Collage.leafRects
                            delegate: Rectangle {
                                id: et
                                required property var modelData
                                required property int index
                                x: modelData.x * ed.width + 3; y: modelData.y * ed.height + 3
                                width: modelData.w * ed.width - 6; height: modelData.h * ed.height - 6
                                radius: 8; clip: true; color: Theme.card
                                Image { anchors.fill: parent; visible: et.modelData.img !== ""; source: et.modelData.img ? Wallpaper.stillUrl(et.modelData.img) : ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(320, 200); asynchronous: true }
                                UiText { visible: et.modelData.img === ""; anchors.centerIn: parent; text: et.index === 0 ? "Wallpaper atual" : "Da pasta"; color: Theme.muted; font.pixelSize: 11 }
                                Row {
                                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 4; spacing: 3
                                    Repeater {
                                        model: [
                                            { ic: Collage.primary === et.modelData.id ? "star" : "starOutline", tip: "primary", on: true },
                                            { ic: "image", tip: "img", on: true },
                                            { ic: "view_column", tip: "h", on: Collage.count < Collage.maxLeaves },
                                            { ic: "view_column", tip: "v", on: Collage.count < Collage.maxLeaves, rot: 90 },
                                            { ic: "close", tip: "rm", on: Collage.count > 1 }
                                        ]
                                        delegate: Rectangle {
                                            id: eb
                                            required property var modelData
                                            visible: modelData.on
                                            width: 22; height: 22; radius: 11
                                            color: bm.containsMouse ? Theme.accent : Theme.card
                                            UiIcon { anchors.centerIn: parent; name: eb.modelData.ic; size: 13; rotation: eb.modelData.rot ?? 0; color: bm.containsMouse ? Theme.accentText : Theme.text }
                                            MouseArea {
                                                id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    const id = et.modelData.id, t = eb.modelData.tip
                                                    if (t === "primary") Collage.setPrimary(id)
                                                    else if (t === "img") Pick.image("Imagem do mosaico", p => Collage.setImage(id, p))
                                                    else if (t === "rm") Collage.remove(id)
                                                    else Collage.split(id, t)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        // divisoes arrastaveis
                        Repeater {
                            model: Collage.cuts
                            delegate: Item {
                                id: gt
                                required property var modelData
                                readonly property bool horiz: modelData.dir === "h"
                                x: horiz ? (modelData.x + modelData.w * modelData.r) * ed.width - 6 : modelData.x * ed.width
                                y: horiz ? modelData.y * ed.height : (modelData.y + modelData.h * modelData.r) * ed.height - 6
                                width: horiz ? 12 : modelData.w * ed.width
                                height: horiz ? modelData.h * ed.height : 12
                                Rectangle { anchors.centerIn: parent; width: gt.horiz ? 4 : parent.width * 0.3; height: gt.horiz ? parent.height * 0.3 : 4; radius: 2; color: gm.containsMouse || gm.pressed ? Theme.accent : Theme.tint(0.7) }
                                MouseArea {
                                    id: gm; anchors.fill: parent; hoverEnabled: true; preventStealing: true
                                    cursorShape: gt.horiz ? Qt.SizeHorCursor : Qt.SizeVerCursor
                                    onPositionChanged: m => {
                                        if (!pressed) return
                                        const p = mapToItem(ed, m.x, m.y)
                                        const c = gt.modelData
                                        Collage.setRatio(c.path, gt.horiz ? (p.x / ed.width - c.x) / c.w : (p.y / ed.height - c.y) / c.h)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- transicao ----
    property string hov: ""   // transicao sob o mouse nos cartoes (vazio = a escolhida)
    readonly property var trOpts: [["fade", "Fade", "opacity"], ["slide", "Deslizar", "arrow_right"], ["wipe", "Cortina", "view_column"], ["circle", "Círculo", "circleOutline"], ["zoom", "Zoom", "fullscreen"], ["dissolve", "Dissolver", "grain"], ["pixelate", "Pixelar", "grid"], ["ripple", "Ondas", "wave"], ["blinds", "Persianas", "menu"], ["swirl", "Redemoinho", "rotate"], ["circlepit", "Poço", "target"], ["circleselect", "Círculos", "dotsCircle"], ["magic", "Mágica", "magic"], ["doom", "Derreter", "fire"], ["peel", "Folha", "noteText"], ["transition", "Diagonal", "arrow_bottom_right"], ["stripes", "Listras", "bars"], ["crt", "TV antiga", "monitor"], ["glitch", "Glitch", "lightning"], ["shatter", "Estilhaçar", "cardsDiamond"], ["random", "Aleatória", "dice"], ["none", "Nenhuma", "close"]]
    // miniaturas das transicoes: o wallpaper atual e o proximo da lista (como no palco)
    readonly property int thI: Wallpaper.files.findIndex(f => f.path === Wallpaper.current)
    readonly property string thA: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
    readonly property string thB: Wallpaper.files.length > 1 ? Wallpaper.stillUrl(Wallpaper.files[(Math.max(0, thI) + 1) % Wallpaper.files.length].path) : thA
    function trName(id) { const o = trOpts.find(x => x[0] === id); return o ? o[1] : id }
    SetSection {
        title: "Transição"
        icon: "transition"
        SetBlock {
            Item {
                width: parent.width
                height: (stgL.item ? stgL.item.height : 236) + 30
                Loader {
                    id: stgL
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: Settings.settingsOpen
                    sourceComponent: WpStage {
                        width: Math.min(420, page.width - SetK.pad * 4)
                        sel: page.hov !== "" ? page.hov : Settings.wpTransition
                        active: Settings.settingsOpen && page.visible
                    }
                }
                UiText {
                    anchors { top: parent.top; topMargin: (stgL.item ? stgL.item.height : 0) + 8; horizontalCenter: parent.horizontalCenter }
                    color: Theme.muted; font.pixelSize: SetK.fDesc
                    text: page.trName(stgL.item ? (stgL.item.sel) : "") + (stgL.item && stgL.item.sel === "random" ? " (" + page.trName(stgL.item.trans) + ")" : "") + "  ·  " + Wallpaper.duration + " ms"
                }
            }
        }
        SetChoice {
            label: ""
            style: "tiles"; minTile: 80; thumbHeight: 50
            options: page.trOpts
            value: Settings.wpTransition
            onPicked: v => Settings.wpTransition = v
            // miniatura parada (quadro do meio da troca); com o mouse em cima, um ensaio da transicao em loop
            thumb: Item {
                id: tt
                property var opt
                property bool on
                property bool hovered
                readonly property string id0: opt ? opt[0] : "fade"
                readonly property string kind: ({ fade: "fade", random: "fade", slide: "slide", peel: "slide", wipe: "wipe", circle: "circle", ripple: "circle", circlepit: "circle", circleselect: "circle",
                    zoom: "zoom", swirl: "zoom", dissolve: "cells", pixelate: "cells", magic: "cells", glitch: "cells", shatter: "cells", blinds: "blinds", stripes: "blinds",
                    transition: "diag", doom: "drip", crt: "crt", none: "none" })[id0] ?? "fade"
                onHoveredChanged: { if (!page) return; if (hovered) page.hov = id0; else if (page.hov === id0) page.hov = "" }
                // quadro do meio da troca com os seus wallpapers de verdade: o atual por baixo, o proximo recortado pela forma
                // da transicao (mascara). Imagens pequenas e compartilhadas entre os cartoes (mesmo endereco e tamanho = um cache so)
                Item {
                    id: demo
                    anchors.fill: parent
                    property real p: 0.5   // parado no meio da troca; com o mouse em cima, ensaia em loop
                    NumberAnimation on p { running: tt.hovered && tt.kind !== "none"; from: 0; to: 1; duration: 1100; loops: Animation.Infinite; easing.type: Easing.InOutCubic; onRunningChanged: if (!running) demo.p = 0.5 }
                    readonly property bool masked: tt.kind !== "fade" && tt.kind !== "zoom" && tt.kind !== "none"
                    readonly property color cb: "white"
                    layer.enabled: true
                    layer.effect: MultiEffect { maskEnabled: true; maskSource: round; maskThresholdMin: 0.5; maskSpreadAtMin: 0.2 }
                    Rectangle { id: round; anchors.fill: parent; radius: 10; visible: false; layer.enabled: true }
                    Image {
                        anchors.fill: parent
                        source: page.thA; sourceSize: Qt.size(192, 108)
                        fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
                    }
                    // escurece o que sai, para a forma do que entra aparecer
                    Rectangle { anchors.fill: parent; color: "black"; opacity: tt.kind === "none" ? 0 : 0.35 }
                    Image {
                        id: ib
                        anchors.fill: parent
                        source: page.thB; sourceSize: Qt.size(192, 108)
                        fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
                        visible: tt.kind === "fade" || tt.kind === "zoom"
                        opacity: demo.p
                        scale: tt.kind === "zoom" ? 1.6 - 0.6 * demo.p : 1
                    }
                    MultiEffect {
                        visible: demo.masked
                        anchors.fill: parent
                        source: ib
                        maskEnabled: true; maskSource: mk
                        maskThresholdMin: 0.5; maskSpreadAtMin: 0.1
                    }
                    // fio branco na borda da forma (onde e barato desenhar)
                    Rectangle { visible: tt.kind === "wipe"; x: demo.p * parent.width - 1; width: 1; height: parent.height; color: "white"; opacity: 0.6 }
                    Rectangle { visible: tt.kind === "slide"; x: (1 - demo.p) * parent.width; width: 1; height: parent.height; color: "white"; opacity: 0.6 }
                    Rectangle {
                        visible: tt.kind === "circle"
                        readonly property real d: demo.p * Math.hypot(parent.width, parent.height)
                        anchors.centerIn: parent; width: d; height: d; radius: d / 2
                        color: "transparent"; border.width: 1; border.color: "white"; opacity: 0.6
                    }
                    // a forma da transicao (so a mascara; nunca aparece)
                    Item {
                        id: mk
                        anchors.fill: parent
                        visible: false
                        layer.enabled: demo.masked
                        Rectangle {
                            visible: tt.kind === "crt"
                            anchors.centerIn: parent
                            width: parent.width; height: Math.max(2, parent.height * Math.min(1, demo.p * 1.6))
                            color: demo.cb
                        }
                        Rectangle { visible: tt.kind === "slide"; x: (1 - demo.p) * parent.width; width: parent.width; height: parent.height; color: demo.cb }
                        Rectangle { visible: tt.kind === "wipe"; width: demo.p * parent.width; height: parent.height; color: demo.cb }
                        Rectangle {
                            visible: tt.kind === "circle"
                            readonly property real d: demo.p * Math.hypot(parent.width, parent.height)
                            anchors.centerIn: parent; width: d; height: d; radius: d / 2; color: demo.cb
                        }
                        Rectangle {
                            visible: tt.kind === "diag"
                            width: parent.width * 2; height: parent.height * 3; rotation: 45; color: demo.cb
                            x: -parent.width * 2.4 + demo.p * parent.width * 2.6; y: -parent.height
                        }
                        Repeater {
                            model: tt.kind === "blinds" ? 5 : 0
                            delegate: Rectangle { required property int index; y: index * mk.height / 5; width: mk.width; height: demo.p * mk.height / 5; color: demo.cb }
                        }
                        Repeater {
                            model: tt.kind === "drip" ? 8 : 0
                            delegate: Rectangle { required property int index; x: index * mk.width / 8; width: mk.width / 8 + 1; height: Math.min(mk.height, demo.p * mk.height * (0.7 + ((index * 37) % 10) / 12)); color: demo.cb }
                        }
                        Grid {
                            visible: tt.kind === "cells"
                            anchors.fill: parent
                            columns: 6
                            Repeater {
                                model: tt.kind === "cells" ? 24 : 0
                                delegate: Rectangle { required property int index; width: mk.width / 6; height: mk.height / 4; color: demo.cb; opacity: ((index * 7919) % 24) / 24 < demo.p ? 1 : 0 }
                            }
                        }
                    }
                    // "Nenhuma" e "Aleatória": o icone num selo discreto por cima da imagem
                    Rectangle {
                        visible: tt.kind === "none" || tt.id0 === "random"
                        anchors.centerIn: parent; width: 30; height: 30; radius: 15
                        color: Qt.rgba(0, 0, 0, 0.45)
                        UiIcon { anchors.centerIn: parent; name: tt.opt ? tt.opt[2] : ""; size: 16; color: "white" }
                    }
                }
            }
        }
        SetChoice {
            visible: Settings.wpTransition === "wipe" || Settings.wpTransition === "random"
            icon: "compass"; label: "Direção"
            iconsOnly: true
            options: [[0, "", "arrow_right"], [45, "", "arrow_bottom_right"], [90, "", "arrowDown"], [135, "", "arrow_bottom_left"], [180, "", "arrow_left"], [225, "", "arrow_top_left"], [270, "", "arrowUp"], [315, "", "arrow_top_right"]]
            value: Settings.wpWipeAngle
            onPicked: v => Settings.wpWipeAngle = v
        }
        SetSlider {
            enabled: Settings.wpTransition !== "none"
            icon: "timer"; label: "Duração"; description: Settings.wpTransMs > 0 ? "" : "A da animação escolhida (" + Settings.animOf("wallpaper").duration + " ms)"
            from: 0; to: 3000; step: 50; unit: " ms"; zeroLabel: "Auto"; def: 0
            value: Settings.wpTransMs; onMoved: v => Settings.wpTransMs = Math.round(v)
        }
        SetExpander {
            icon: "tune"; label: "Avançado"; description: "Ângulo, movimento e curva"
            SetSlider { visible: Settings.wpTransition === "wipe" || Settings.wpTransition === "random"; sub: true; label: "Ângulo exato"; from: 0; to: 359; unit: "°"; def: 0; value: Settings.wpWipeAngle; onMoved: v => Settings.wpWipeAngle = Math.round(v) }
            SetSlider { sub: true; label: "Movimento"; description: "Cortina: posição · círculo: escala"; from: 0; to: 50; unit: " %"; def: 20; value: Settings.wpParallax; onMoved: v => Settings.wpParallax = Math.round(v) }
            lazy: Component { SetBlock { sub: true; UiLabel { text: "Curva" } AnimPicker { width: parent.width; target: "wallpaper" } } }
        }
    }

    // ---- efeitos ----
    SetSection {
        title: "Efeitos"
        icon: "blur"
        SetSlider {
            icon: "blur"; label: "Desfoque"; from: 0; to: 100; step: 5; unit: " %"; zeroLabel: "Desligado"; def: 0
            value: Settings.wpBlur; onMoved: v => Settings.wpBlur = Math.round(v)
        }
        SetExpander {
            visible: Settings.wpBlur > 0
            icon: "tune"; label: "Opções do desfoque"; description: "Largura, lado e quando"
            SetChoice { sub: true; label: "Largura"; options: [["100", "Tela toda"], ["50", "Metade"], ["25", "Um quarto"]]; value: Settings.wpBlurSplit; onPicked: v => Settings.wpBlurSplit = v }
            SetChoice { visible: Settings.wpBlurSplit !== "100"; sub: true; label: "Lado"; options: [["left", "Esquerda", "alignLeft"], ["right", "Direita", "alignRight"]]; value: Settings.wpBlurSide; onPicked: v => Settings.wpBlurSide = v }
            SetChoice { sub: true; label: "Quando"; options: [["windows", "Com janelas"], ["always", "Sempre"], ["never", "Nunca"]]; value: Settings.wpBlurWhen; onPicked: v => Settings.wpBlurWhen = v }
        }
        SetSlider {
            icon: "night"; label: "Escurecer"; from: 0; to: 80; step: 5; unit: " %"; zeroLabel: "Desligado"; def: 0
            value: Settings.wpDim; onMoved: v => Settings.wpDim = Math.round(v)
        }
        SetChoice {
            visible: Settings.wpDim > 0
            sub: true; label: "Escurecer quando"
            options: [["windows", "Com janelas"], ["always", "Sempre"], ["never", "Nunca"]]
            value: Settings.wpDimWhen; onPicked: v => Settings.wpDimWhen = v
        }
        SetSlider {
            icon: "swap_horizontal"; label: "Paralaxe"; description: "Ao trocar de workspace"
            from: 0; to: 20; unit: " %"; zeroLabel: "Desligada"; def: 0
            value: Settings.wpWsParallax; onMoved: v => Settings.wpWsParallax = Math.round(v)
        }
        SetRow { visible: Settings.wpWsParallax > 0; sub: true; label: "Deslizar na vertical"; checked: Settings.wpWsVertical; onToggled: on => Settings.wpWsVertical = on }
    }

    // ---- troca automatica e videos ----
    SetSection {
        title: "Troca e vídeos"
        icon: "timer"
        SetSlider {
            icon: "timer"; label: "Trocar a cada"; from: 0; to: 120; step: 5; unit: " min"; zeroLabel: "Nunca"; def: 0
            value: Settings.wpInterval; onMoved: v => Settings.wpInterval = Math.round(v)
        }
        SetRow { icon: "shuffle"; label: "Ordem aleatória"; checked: Settings.wpShuffle; onToggled: on => Settings.wpShuffle = on }
        SetRow { icon: "play"; label: "Vídeos da pasta"; description: "MP4, WebM, MKV e MOV, em loop e sem som"; checked: Settings.wpVideos; onToggled: on => Settings.wpVideos = on }
        SetRow { visible: Settings.wpVideos; sub: true; label: "Pausar com tela cheia"; checked: Settings.wpVideoPause; onToggled: on => Settings.wpVideoPause = on }
    }

    // ---- tela de bloqueio ----
    SetSection {
        title: "Tela de bloqueio"
        icon: "lock"
        SetRow {
            icon: "lock"; label: "Wallpaper do bloqueio"
            description: Settings.lockWallpaper ? Settings.lockWallpaper.split("/").pop() : "O mesmo da área de trabalho"
            canReset: Settings.lockWallpaper !== ""
            onReset: Settings.lockWallpaper = ""
            UiButton { icon: "eye"; kind: "ghost"; onClicked: Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "lockpreview", "toggle"]) }
            UiButton { icon: "folderOpen"; text: "Escolher imagem"; onClicked: Pick.image("Wallpaper da tela de bloqueio", p => Settings.lockWallpaper = p) }
        }
    }

    // ---- seletor ----
    SetSection {
        title: "Seletor (Super + W)"
        icon: "carousel"
        SetRow {
            icon: "folder"; label: "Pasta"
            UiField { width: 240; text: Settings.wpDir; placeholderText: "$PICTURES/Wallpapers"; onEditingFinished: Settings.wpDir = text }
        }
        SetChoice { icon: "carousel"; label: "Disposição"; options: [["carousel", "Carrossel", "carousel"], ["grid", "Grade", "view_grid"]]; value: Settings.wpLayout; onPicked: v => Settings.wpLayout = v }
        SetChoice {
            icon: "sortName"; label: "Ordem"
            description: Settings.wpSort === "manual" ? "Mova com Alt + setas no seletor" : ""
            iconsOnly: true
            options: [["name", "Nome", "sortName"], ["time", "Data", "sortTime"], ["size", "Tamanho", "disk"], ["manual", "Manual", "swap_horizontal"]]
            value: Settings.wpSort; onPicked: v => Settings.wpSort = v
        }
        SetRow { icon: "swap_vertical"; label: "Ordem invertida"; checked: Settings.wpSortRev; onToggled: on => Settings.wpSortRev = on }
        SetRow { icon: "eye"; label: "Prévia ao navegar"; description: "Volta ao anterior se fechar sem escolher"; checked: Settings.wpPreview; onToggled: on => Settings.wpPreview = on }
        SetRow { icon: "check"; label: "Fechar ao escolher"; checked: Settings.wpCloseAfter; onToggled: on => Settings.wpCloseAfter = on }
        SetExpander {
            icon: "tune"; label: "Posição e forma"; description: "Lado, tamanho e cantos do painel"
            SetRow { sub: true; label: "Acoplado à moldura"; description: "Desligado, flutua perto da borda"; checked: Settings.wpPickerDocked; onToggled: on => Settings.wpPickerDocked = on }
            SetRow { sub: true; label: "Lado"; SidePick { value: Settings.wpPickerSide; onPicked: v => Settings.wpPickerSide = v } }
            SetChoice { sub: true; label: "Wallpapers visíveis"; options: [[1, "1"], [3, "3"], [5, "5"]]; value: Settings.wpPickerCount; onPicked: v => Settings.wpPickerCount = v }
            SetSlider { sub: true; label: "Deslocamento"; from: -1000; to: 1000; step: 10; unit: " px"; def: 0; value: Settings.wpPickerOffset; onMoved: v => Settings.wpPickerOffset = Math.round(v) }
            SetSlider { visible: !Settings.wpPickerDocked; sub: true; label: "Distância da borda"; from: 0; to: 80; unit: " px"; def: 14; value: Settings.wpPickerGap; onMoved: v => Settings.wpPickerGap = Math.round(v) }
            SetSlider { sub: true; label: "Cantos do painel"; from: 0; to: 40; unit: " px"; def: 11; value: Settings.wpPickerRadius; onMoved: v => Settings.wpPickerRadius = Math.round(v) }
            SetSlider { visible: Settings.wpPickerDocked; sub: true; label: "Curva na moldura"; from: 0; to: 40; unit: " px"; def: 13; value: Settings.wpPickerFillet; onMoved: v => Settings.wpPickerFillet = Math.round(v) }
            SetSlider { sub: true; label: "Cantos das miniaturas"; from: 0; to: 40; unit: " px"; def: 14; value: Settings.wpCardRadius; onMoved: v => Settings.wpCardRadius = Math.round(v) }
            SetRow { sub: true; label: "Usar o navegador de arquivos"; description: "Em vez do carrossel"; checked: Settings.wpSystemDialog; onToggled: on => Settings.wpSystemDialog = on }
            lazy: Component { SetBlock { sub: true; UiLabel { text: "Animação do seletor" } AnimPicker { width: parent.width; target: "picker" } } }
        }
        SetExpander {
            icon: "web"; label: "Buscar no Wallhaven"; description: "Baixar e aplicar de wallhaven.cc"
            lazy: Component { WallhavenCard { title: ""; color: "transparent"; border.width: 0 } }
        }
    }
}
