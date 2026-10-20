// Controle do wallpaper: lista de imagens da pasta, wallpaper atual, proximo/aleatorio e troca automatica.
// O desenho (e as transicoes) fica em WallpaperWindow.qml; o seletor, em WallpaperPicker.qml.
pragma Singleton

import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: Settings.wpDir.replace(/^~/, home)
    property var files: []   // [{ path, name }] imagens (e videos) da pasta que esta sendo vista
    property var dirs: []    // subpastas da pasta vista (so o seletor mostra)
    property string browse: ""   // pasta vista no seletor ("" = a pasta de wallpapers das configuracoes); volta ao fechar o seletor
    property string filter: ""   // filtro por nome no seletor
    readonly property string viewDir: browse !== "" ? browse : dir
    readonly property var entries: {
        const w = norm(filter).trim().split(/\s+/).filter(x => x)
        if (!w.length) return dirs.concat(files)
        return files.filter(f => { const n = norm(f.name); return w.every(x => n.includes(x)) })
    }
    function norm(t) { return String(t).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase() }
    function enter(p) { filter = ""; browse = p }
    function up() { if (viewDir.length > 1) { filter = ""; browse = viewDir.replace(/\/[^/]*\/?$/, "") || "/" } }
    function reset() { filter = ""; browse = "" }
    Connections { target: Settings; function onWpPickerOpenChanged() { if (!Settings.wpPickerOpen) root.reset() } }

    readonly property string current: Settings.wallpaper !== "" ? Settings.wallpaper : (files.length ? files[0].path : "")
    // ---- videos (mp4, webm, mkv, mov): o primeiro quadro vira um jpg em ~/.cache/quickshell-mine/vidframe (transicoes,
    // paleta de cores, miniaturas e tudo o que precisa de imagem usam esse quadro) ----
    readonly property var videoExt: ["mp4", "webm", "mkv", "mov", "m4v"]
    function isVideo(p) { return !!p && videoExt.indexOf(String(p).split(".").pop().toLowerCase()) >= 0 }
    property bool videoPaused: false   // pausado na mao (botao rapido "Wallpaper animado"; nao e salvo)
    readonly property string frameDir: home + "/.cache/quickshell-mine/vidframe"
    function hash(s) { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) } return (h >>> 0).toString(16) }
    function framePath(p) { return frameDir + "/" + hash(p) + ".jpg" }
    property var frames: ({})        // video -> true quando o quadro existe
    property var frameQueue: []
    function stillOf(p) {
        if (!isVideo(p)) return p
        if (frames[p]) return framePath(p)
        if (frameQueue.indexOf(p) < 0) Qt.callLater(() => root.enqueue(p))   // fora do binding que perguntou
        return ""
    }
    function stillUrl(p) { const s = stillOf(p); return s ? "file://" + s : "" }
    function enqueue(p) { if (frameQueue.indexOf(p) < 0 && !frames[p]) { frameQueue = frameQueue.concat([p]); nextFrame() } }
    readonly property string still: stillOf(current)
    function nextFrame() {
        if (frameProc.running || !frameQueue.length) return
        const p = frameQueue[0]
        frameProc.target = p
        frameProc.command = ["sh", "-c", 'mkdir -p "$1" && { [ -s "$2" ] || ffmpeg -y -loglevel error -ss 0.3 -i "$3" -frames:v 1 -vf "scale=1920:-2" "$2"; }', "sh", frameDir, framePath(p), p]
        frameProc.running = true
    }
    Process {
        id: frameProc
        property string target: ""
        onExited: {
            const f = Object.assign({}, root.frames); f[target] = true; root.frames = f
            root.frameQueue = root.frameQueue.filter(x => x !== target)
            Qt.callLater(root.nextFrame)
        }
    }
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
    property bool peek: false          // wallpaper na frente de tudo (so para conferir; nao e salvo)
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
        const out = [], d = []
        for (let i = 0; i < model.count; i++) {
            if (model.get(i, "fileIsDir")) d.push({ path: model.get(i, "filePath"), name: model.get(i, "fileName"), dir: true })
            else out.push({ path: model.get(i, "filePath"), name: model.get(i, "fileBaseName") })
        }
        dirs = d
        files = out
    }

    FolderListModel {
        id: model
        folder: "file://" + root.viewDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"].concat(Settings.wpVideos ? ["*.mp4", "*.webm", "*.mkv", "*.mov", "*.m4v", "*.MP4", "*.WEBM"] : [])
        showDirs: true
        showDirsFirst: true
        showDotAndDotDot: false
        sortField: Settings.wpSort === "time" ? FolderListModel.Time : (Settings.wpSort === "size" ? FolderListModel.Size : FolderListModel.Name)
        sortReversed: Settings.wpSortRev
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
