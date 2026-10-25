// Pastas do usuario (XDG: ~/.config/user-dirs.dirs), para nao depender de nomes em portugues ou ingles.
// resolve() troca ~, $PICTURES, $VIDEOS e $DOWNLOAD nos caminhos das configuracoes pelo caminho real.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    FileView { id: f; path: root.home + "/.config/user-dirs.dirs"; blockLoading: true; printErrors: false }
    function dirOf(key: string, fb: string): string {
        const m = (f.text() || "").match(new RegExp("^XDG_" + key + "_DIR=\"(.*)\"$", "m"))
        const p = m ? m[1].replace("$HOME", root.home) : ""
        return p !== "" && p !== root.home ? p : root.home + "/" + fb
    }
    readonly property string pictures: dirOf("PICTURES", "Pictures")
    readonly property string videos: dirOf("VIDEOS", "Videos")
    readonly property string download: dirOf("DOWNLOAD", "Downloads")
    readonly property string desktop: dirOf("DESKTOP", "Desktop")
    function resolve(p: string): string {
        return (p || "").replace(/^\$PICTURES/, pictures).replace(/^\$VIDEOS/, videos).replace(/^\$DOWNLOAD/, download).replace(/^~/, home)
    }
}
