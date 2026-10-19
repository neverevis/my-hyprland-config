// Controle do wallpaper: lista de imagens da pasta, wallpaper atual, proximo/aleatorio e troca automatica.
// O desenho (e as transicoes) fica em WallpaperWindow.qml; o seletor, em WallpaperPicker.qml.
pragma Singleton

import Quickshell
import Qt.labs.folderlistmodel
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: Settings.wpDir.replace(/^~/, home)
    property var files: []   // [{ path, name }]

    readonly property string current: Settings.wallpaper !== "" ? Settings.wallpaper : (files.length ? files[0].path : "")
    readonly property var curves: ({
        smooth: [0.4, 0, 0.2, 1, 1, 1],
        decel: [0.05, 0.7, 0.1, 1, 1, 1],
        snappy: [0.2, 0.8, 0.2, 1, 1, 1],
        linear: [0, 0, 1, 1, 1, 1]
    })
    readonly property var curve: Settings.animOf("wallpaper").curve
    readonly property int duration: Settings.animOf("wallpaper").duration
    readonly property var shaderTransitions: ["dissolve", "pixelate", "ripple", "blinds", "swirl"]
    readonly property var transitions: ["fade", "slide", "wipe", "circle", "zoom"].concat(shaderTransitions)

    // tipo de transicao a usar agora (resolve "random")
    function pickTransition(): string {
        const t = Settings.wpTransition
        return t === "random" ? transitions[Math.floor(Math.random() * transitions.length)] : t
    }

    // pre-carrega (decodifica) a proxima imagem provavel, para a transicao comecar sem atraso
    property bool busy: false          // transicao de wallpaper em andamento (exportacoes do tema esperam ela acabar)
    property string pickerFocus: ""    // item destacado no seletor (se aberto)
    property string upcoming: ""
    readonly property string preload: pickerFocus !== "" ? pickerFocus : upcoming
    function planNext(): void {
        if (files.length < 2) { upcoming = ""; return }
        if (Settings.wpShuffle) {
            let i
            do { i = Math.floor(Math.random() * files.length) } while (files[i].path === current)
            upcoming = files[i].path
        } else {
            upcoming = files[(indexOfCurrent() + 1) % files.length].path
        }
    }
    onCurrentChanged: planNext()
    onFilesChanged: planNext()

    function set(path: string): void { if (path) Settings.wallpaper = path }
    function indexOfCurrent(): int {
        const i = files.findIndex(f => f.path === current)
        return i < 0 ? 0 : i
    }
    function step(d: int): void {
        if (!files.length) return
        set(files[(indexOfCurrent() + d + files.length) % files.length].path)
    }
    function random(): void {
        if (files.length < 2) return
        if (upcoming !== "" && upcoming !== current) { set(upcoming); return }
        let i
        do { i = Math.floor(Math.random() * files.length) } while (files[i].path === current)
        set(files[i].path)
    }

    function refresh(): void {
        const out = []
        for (let i = 0; i < model.count; i++)
            out.push({ path: model.get(i, "filePath"), name: model.get(i, "fileBaseName") })
        files = out
    }

    FolderListModel {
        id: model
        folder: "file://" + root.dir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: root.refresh()
        onStatusChanged: if (status === FolderListModel.Ready) root.refresh()
    }

    // troca automatica
    Timer {
        interval: Math.max(1, Settings.wpInterval) * 60000
        running: Settings.wpInterval > 0 && root.files.length > 1
        repeat: true
        onTriggered: Settings.wpShuffle ? root.random() : root.step(1)   // random() usa o item ja pre-carregado
    }
}
