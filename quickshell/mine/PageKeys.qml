// Pagina "Atalhos de teclado" (kit Set*): atalhos do shell por grupo (teclas desenhadas, mudar gravando a combinacao ou
// digitando, voltar ao padrao, desligar), conflitos com os atalhos do usuario e lista (so leitura) de todos os outros.
// Dados: scripts/keys.py (state = tabela de quickshell.lua + quickshell-keys.lua + hyprctl binds -j; write = grava o arquivo
// de escolhas de forma atomica com .bak unico e luac -p). Gravou: hyprctl reload e le os binds de novo para confirmar.
// Gravacao: Keys.onPressed da janela. O Hyprland come as combinacoes que ja tem; por isso, se o submap "mine-rec" existe
// (quickshell.lua), ele entra nele so enquanto grava (volta ao apertar Esc, ao capturar, ao cancelar, depois de 10 s e ao fechar).
// Modo de teste (SysAct.dry): grava em ~/.cache/quickshell-mine/keys-test/, nao recarrega o Hyprland e nao entra no submap.
// Leituras so com a pagina visivel; nada roda parado.
import Quickshell
import Quickshell.Io
import QtQuick

SetPage {
    id: page
    title: "Atalhos de teclado"
    subtitle: "Ver, mudar e desligar os atalhos do shell, e conferir o que mais usa teclas"
    readonly property bool live: visible && Settings.settingsOpen
    onLiveChanged: { if (live) { SysAct.check(); load() } else { cancelEdit(); confirmAll = false } }
    Component.onDestruction: exitRec()
    Connections { target: SysAct; function onDryFileChanged() { if (page.live) page.load() } }

    // ---- dados ----
    property var entries: []
    property var conflicts: ({})
    property var override: ({})
    property var binds: []
    property bool hasSubmap: false
    property string editor: ""
    property string userFile: ""
    property int rev: 0
    property bool loadErr: false
    property var byId: ({})
    property var groupNames: []
    property var groupIds: ({})
    property string groupKey: ""
    property string verifyId: ""
    readonly property var userBinds: { rev; return binds.filter(b => !b.mine && !b.mouse && b.submap === "" && b.key !== "") }

    readonly property string script: Qt.resolvedUrl("scripts/keys.py").toString().replace("file://", "")
    // em modo de teste o python le/escreve a copia em ~/.cache/quickshell-mine/keys-test/ (criada na primeira vez)
    function py(args) {
        if (!SysAct.dry) return ["python3", script].concat(args)
        return ["sh", "-c", 't="$HOME/.cache/quickshell-mine/keys-test/quickshell-keys.lua"; mkdir -p "${t%/*}"; [ -e "$t" ] || cp "$HOME/.config/hypr/quickshell-keys.lua" "$t" 2>/dev/null; exec python3 "$@" --keys "$t"', "sh", script].concat(args)
    }
    function load() { if (!stP.running) { stP.command = py(["state"]); stP.running = true } }
    Process {
        id: stP
        stdout: StdioCollector { onStreamFinished: {
            let d
            try { d = JSON.parse(text); page.loadErr = false } catch (e) { page.loadErr = true; return }
            page.entries = d.entries; page.conflicts = d.conflicts; page.override = d.override; page.binds = d.binds
            page.hasSubmap = d.hasSubmap; page.editor = d.editor; page.userFile = d.userBinds
            const m = {}, g = {}, names = []
            d.entries.forEach(e => { m[e.id] = e; if (!g[e.grp]) { g[e.grp] = []; names.push(e.grp) } g[e.grp].push(e.id) })
            page.byId = m
            const k = JSON.stringify(g)
            if (k !== page.groupKey) { page.groupKey = k; page.groupIds = g; page.groupNames = names }   // so troca o modelo se a tabela mudou
            page.rev++
            if (page.verifyId !== "") page.verifyDone()
        } }
    }

    // ---- combinacoes ----
    readonly property var modBits: ({ SUPER: 64, WIN: 64, MOD4: 64, LOGO: 64, META: 64, SHIFT: 1, CTRL: 4, CONTROL: 4, ALT: 8, MOD1: 8 })
    function norm(c) {
        const t = c.split("+").map(s => s.trim()).filter(s => s !== "")
        if (!t.length) return { mask: 0, key: "" }
        let mask = 0
        t.slice(0, -1).forEach(x => { mask |= (modBits[x.toUpperCase()] || 0) })
        return { mask: mask, key: t[t.length - 1].toLowerCase() }
    }
    function same(a, b) { return a.mask === b.mask && a.key === b.key }
    function maskText(mask) { return [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]].filter(x => mask & x[0]).map(x => x[1]).join(" + ") }
    function comboText(b) { const m = maskText(b.mask); return m ? m + " + " + b.key : b.key }
    function defaults(e) { return Array.from(e.key) }
    function ovr(e) { return override[e.id] }
    function curCombos(e) {       // combinacoes valendo agora (vazio = desligado)
        const o = ovr(e)
        if (o === false) return []
        if (o !== undefined) return Array.isArray(o) ? o : [o]
        return e.off ? [] : defaults(e)
    }
    function shown(e) { const c = curCombos(e); return c.length ? c : (Array.isArray(ovr(e)) || typeof ovr(e) === "string" ? c : defaults(e)) }
    function stateOf(e) {
        const o = ovr(e)
        if (o === false || (o === undefined && e.off)) return "off"
        if (o !== undefined) return "changed"
        return conflicts[e.id] === "keep" ? "kept" : "ok"
    }
    function bindText(b) { return b.label || b.desc || (b.disp === "__lua" ? "Atalho definido em Lua" : (b.disp + " " + b.arg).trim()) }
    function userHits(e, combos) {       // atalhos do usuario na combinacao
        const out = []
        combos.forEach(c => {
            const n = norm(c)
            userBinds.forEach(b => { if (b.mask === n.mask && b.key.toLowerCase() === n.key && b.release === !!e.release) out.push(b) })
        })
        return out
    }
    readonly property var conflictList: {
        rev
        const out = []
        entries.forEach(e => {
            if (e.off || ovr(e) !== undefined) return
            const dec = conflicts[e.id], hits = userHits(e, defaults(e))
            if (!dec && !hits.length) return
            out.push({ id: e.id, desc: e.desc, combo: defaults(e).join("  /  "), dec: dec || "", who: hits.length ? bindText(hits[0]) : "" })
        })
        return out
    }

    // ---- validar o que o usuario digitou ----
    readonly property var modCanon: ({ SUPER: "SUPER", WIN: "SUPER", MOD4: "SUPER", LOGO: "SUPER", META: "SUPER", SHIFT: "SHIFT", CTRL: "CTRL", CONTROL: "CTRL", ALT: "ALT", MOD1: "ALT" })
    function validate(text) {
        let toks = text.indexOf("+") >= 0 ? text.split("+") : text.split(/\s+/)
        toks = toks.map(s => s.trim()).filter(s => s !== "")
        if (!toks.length) return { err: "" }
        const mods = []
        for (const t of toks.slice(0, -1)) {
            const m = modCanon[t.toUpperCase()]
            if (!m) return { err: "“" + t + "” não é Super, Ctrl, Alt ou Shift." }
            if (mods.indexOf(m) < 0) mods.push(m)
        }
        let key = toks[toks.length - 1]
        if (!/^[A-Za-z0-9_:.\-]+$/.test(key)) return { err: "A tecla “" + key + "” tem caracteres que o Hyprland não aceita." }
        if (modCanon[key.toUpperCase()] && !mods.length) return { err: "Falta a tecla final (por exemplo SUPER + K)." }
        if (key.length === 1) key = key.toUpperCase()
        if (!mods.length && !/^(F\d+|Print|Pause|Insert|XF86\w+)$/i.test(key)) return { err: "Use Super, Ctrl ou Alt junto, senão a tecla deixa de digitar." }
        const order = ["SUPER", "CTRL", "ALT", "SHIFT"]
        return { combo: order.filter(m => mods.indexOf(m) >= 0).concat([key]).join(" + ") }
    }

    // ---- edicao ----
    property string editId: ""
    property int editIdx: 0
    property string pending: ""
    property bool recArmed: false
    signal captured
    readonly property var ev: {
        rev; pending; editId
        if (editId === "" || pending === "") return null
        const v = validate(pending)
        if (!v.combo) return { err: v.err }
        const e = byId[editId]
        const cur = shown(e)
        if (same(norm(cur[editIdx] || ""), norm(v.combo))) return { err: "Já é este atalho." }
        return { combo: v.combo, hit: findConflict(e, editIdx, v.combo) }
    }
    function findConflict(e, idx, combo) {
        const n = norm(combo)
        for (const o of entries) {
            const oc = stateOf(o) === "kept" ? [] : curCombos(o)      // "kept": quem usa a combinacao e o atalho do usuario
            const cs = o.id === e.id ? oc.filter((c, i) => i !== idx) : oc
            for (const c of cs) if (same(norm(c), n) && !!o.release === !!e.release) return { kind: "shell", id: o.id, who: o.desc }
        }
        const u = userHits(e, [combo])
        if (u.length) return { kind: "user", who: bindText(u[0]) }
        return null
    }
    function startEdit(id, idx) {
        if (editId !== id || editIdx !== idx) exitRec()
        editId = id; editIdx = idx; pending = ""; confirmAll = false
        enterRec()
    }
    function cancelEdit() { editId = ""; pending = ""; exitRec() }
    // submap de gravacao: so com o submap definido, fora do modo de teste; sempre volta (Esc, captura, cancelar, 10 s, fechar)
    function enterRec() {
        if (!hasSubmap || SysAct.dry) return
        Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.submap("mine-rec")'])
        recArmed = true; submapT.restart()
    }
    function exitRec() {
        submapT.stop()
        if (recArmed) Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.submap("reset")'])
        recArmed = false
    }
    Timer { id: submapT; interval: 10000; onTriggered: page.exitRec() }

    // tecla do Qt -> nome do Hyprland (null = ignorar)
    readonly property var keyNames: {
        const m = {}
        m[Qt.Key_Print] = "Print"; m[Qt.Key_Tab] = "TAB"; m[Qt.Key_Backtab] = "TAB"; m[Qt.Key_Space] = "Space"; m[Qt.Key_Return] = "Return"; m[Qt.Key_Enter] = "Return"
        m[Qt.Key_Backspace] = "BackSpace"; m[Qt.Key_Delete] = "Delete"; m[Qt.Key_Insert] = "Insert"; m[Qt.Key_Home] = "Home"; m[Qt.Key_End] = "End"
        m[Qt.Key_PageUp] = "Prior"; m[Qt.Key_PageDown] = "Next"; m[Qt.Key_Left] = "Left"; m[Qt.Key_Right] = "Right"; m[Qt.Key_Up] = "Up"; m[Qt.Key_Down] = "Down"
        m[Qt.Key_Pause] = "Pause"; m[Qt.Key_QuoteLeft] = "grave"; m[Qt.Key_AsciiTilde] = "grave"; m[Qt.Key_Period] = "Period"; m[Qt.Key_Greater] = "Period"
        m[Qt.Key_Comma] = "Comma"; m[Qt.Key_Less] = "Comma"; m[Qt.Key_Minus] = "Minus"; m[Qt.Key_Underscore] = "Minus"; m[Qt.Key_Equal] = "Equal"; m[Qt.Key_Plus] = "Equal"
        m[Qt.Key_Slash] = "Slash"; m[Qt.Key_Question] = "Slash"; m[Qt.Key_Semicolon] = "Semicolon"; m[Qt.Key_Colon] = "Semicolon"
        m[Qt.Key_Apostrophe] = "Apostrophe"; m[Qt.Key_QuoteDbl] = "Apostrophe"; m[Qt.Key_BracketLeft] = "bracketleft"; m[Qt.Key_BraceLeft] = "bracketleft"
        m[Qt.Key_BracketRight] = "bracketright"; m[Qt.Key_BraceRight] = "bracketright"; m[Qt.Key_Backslash] = "backslash"; m[Qt.Key_Bar] = "backslash"
        m[Qt.Key_Exclam] = "1"; m[Qt.Key_At] = "2"; m[Qt.Key_NumberSign] = "3"; m[Qt.Key_Dollar] = "4"; m[Qt.Key_Percent] = "5"
        m[Qt.Key_AsciiCircum] = "6"; m[Qt.Key_Ampersand] = "7"; m[Qt.Key_Asterisk] = "8"; m[Qt.Key_ParenLeft] = "9"; m[Qt.Key_ParenRight] = "0"
        m[Qt.Key_VolumeUp] = "XF86AudioRaiseVolume"; m[Qt.Key_VolumeDown] = "XF86AudioLowerVolume"; m[Qt.Key_VolumeMute] = "XF86AudioMute"
        m[Qt.Key_MediaPlay] = "XF86AudioPlay"; m[Qt.Key_MediaTogglePlayPause] = "XF86AudioPlay"; m[Qt.Key_MediaPause] = "XF86AudioPause"
        m[Qt.Key_MediaNext] = "XF86AudioNext"; m[Qt.Key_MediaPrevious] = "XF86AudioPrev"; m[Qt.Key_MediaStop] = "XF86AudioStop"
        m[Qt.Key_MonBrightnessUp] = "XF86MonBrightnessUp"; m[Qt.Key_MonBrightnessDown] = "XF86MonBrightnessDown"
        return m
    }
    readonly property var modKeys: [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr, Qt.Key_CapsLock, Qt.Key_NumLock, Qt.Key_ScrollLock, Qt.Key_Hyper_L, Qt.Key_Hyper_R]
    function hyprKey(k) {
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k)
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
        if (k >= Qt.Key_F1 && k <= Qt.Key_F24) return "F" + (k - Qt.Key_F1 + 1)
        return keyNames[k] || null
    }
    function handleCap(e) {
        e.accepted = true
        if (e.key === Qt.Key_Escape) { cancelEdit(); return }
        if (modKeys.indexOf(e.key) >= 0) return
        const k = hyprKey(e.key)
        if (!k) return
        const ms = []
        if (e.modifiers & Qt.MetaModifier) ms.push("SUPER")
        if (e.modifiers & Qt.ControlModifier) ms.push("CTRL")
        if (e.modifiers & Qt.AltModifier) ms.push("ALT")
        if ((e.modifiers & Qt.ShiftModifier) || e.key === Qt.Key_Backtab) ms.push("SHIFT")
        pending = ms.concat([k]).join(" + ")
        exitRec()
        captured()
    }

    // ---- gravar ----
    property bool saving: false
    property var note: ({ text: "", kind: "" })
    function say(text, kind) { note = { text: text, kind: kind } }
    function clone() { return { conflicts: Object.assign({}, conflicts), override: Object.assign({}, override) } }
    function setOverride(nu, e, list) {      // lista igual ao padrao some do arquivo
        const d = defaults(e)
        if (!e.off && list.length === d.length && list.every((c, i) => same(norm(c), norm(d[i])))) delete nu.override[e.id]
        else nu.override[e.id] = list.length === 1 ? list[0] : list
    }
    function save(nu, id) {
        if (saving) return
        saving = true; verifyId = id; say("Salvando…", "run")
        const real = SysAct.real("atalhos: gravar " + JSON.stringify(nu))
        wP.reload = real
        wP.command = py(["write", JSON.stringify(nu)]); wP.running = true
    }
    Process {
        id: wP
        property bool reload: true
        stdout: StdioCollector { onStreamFinished: {
            let r = { ok: false, err: "resposta vazia" }
            try { r = JSON.parse(text) } catch (e) {}
            if (!r.ok) { page.saving = false; page.verifyId = ""; console.warn("Keys: gravar falhou:", r.err); page.say("Não deu para gravar o atalho: o arquivo ficou como estava. Tente de novo.", "err"); return }
            if (wP.reload) rP.running = true
            else page.load()
        } }
    }
    Process { id: rP; command: ["hyprctl", "reload"]; onExited: reloadT.restart() }
    Timer { id: reloadT; interval: 800; onTriggered: page.load() }
    // le os binds de novo e confere se a combinacao nova esta valendo
    function verifyDone() {
        const e = byId[verifyId]
        verifyId = ""; saving = false; editId = ""; pending = ""
        if (!e) { say("Aplicado", "ok"); return }
        if (SysAct.dry) { say("Aplicado (modo de teste: nada foi recarregado)", "ok"); return }
        const want = stateOf(e) === "off" || stateOf(e) === "kept" ? [] : shown(e)
        const have = binds.filter(b => b.mine && b.desc === "[mine] " + e.desc).map(b => ({ mask: b.mask, key: b.key.toLowerCase() }))
        const ok = want.every(c => have.some(h => same(h, norm(c)))) && (want.length > 0 || !have.some(h => defaults(e).some(c => same(h, norm(c)))))
        say(ok ? "Aplicado: já vale no Hyprland" : "Gravado, mas o Hyprland ainda mostra o atalho antigo (reinicie a sessão se não mudar)", ok ? "ok" : "err")
    }
    Timer { interval: 7000; running: page.note.text !== "" && page.note.kind !== "run"; onTriggered: page.note = { text: "", kind: "" } }

    function commit(replace) {
        const e = byId[editId], r = ev
        if (!e || !r || !r.combo) return
        const nu = clone()
        const list = shown(e).slice()
        list[editIdx] = r.combo
        setOverride(nu, e, list)
        if (r.hit && replace) { if (r.hit.kind === "user") nu.conflicts[e.id] = "replace"; else nu.override[r.hit.id] = false }
        save(nu, e.id)
    }
    function toggleOn(e, on) {
        const nu = clone()
        if (on) { if (e.off) nu.override[e.id] = defaults(e).length === 1 ? defaults(e)[0] : defaults(e); else delete nu.override[e.id] }
        else nu.override[e.id] = false
        save(nu, e.id)
    }
    function resetEntry(e) { const nu = clone(); delete nu.override[e.id]; save(nu, e.id) }
    function setDecision(id, v) { const nu = clone(); nu.conflicts[id] = v; save(nu, id) }
    function resetAll() { const nu = clone(); nu.override = {}; confirmAll = false; save(nu, "") }
    property bool confirmAll: false
    function openUserFile() {
        if (!SysAct.real("abrir " + userFile)) return
        const ed = editor || "xdg-open"
        const tui = ["nvim", "vim", "nano", "micro", "hx", "helix", "vi", "emacs"]
        Quickshell.execDetached(tui.indexOf(ed) >= 0 ? Terminal.runIn([ed, userFile]) : [ed, userFile])
    }

    readonly property var icons: ({ settings: "cog", looks: "layers", wallpaper: "wallpaper", wp_random: "dice", launcher: "apps", home: "home", home_super: "home",
        overview: "view_grid", overlay: "gamepad", osk: "keyboard", desk_edit: "pencil", clipboard: "paste", notif_clear: "broom", close: "close",
        bar_down: "bars", bar_up: "bars", lock: "lock", power: "power", shot: "camera", shot_freeze: "camera", shot_lens: "search", ocr: "crop",
        translate: "translate", picker: "eyedropper", rec: "recordRec", rec_region: "record", rec_stop: "stopCircle", media_toggle: "play",
        media_next: "arrowRight", media_prev: "arrowLeft", media_stop: "stopCircle", terminal: "console" })
    readonly property var grpIcons: ({ "Painéis": "dock", "Barras": "bars", "Sessão": "power", "Capturas": "camera", "Mídia": "play", "Apps": "apps" })
    function iconFor(e) { return icons[e.id] || grpIcons[e.grp] || "keyboard" }

    // teste por IPC (sem teclado): keys edit <id> | type SUPER+ALT+K | apply true|false | state | cancel
    IpcHandler {
        target: "keys"
        function edit(id: string): string { if (!page.byId[id]) return "?"; page.startEdit(id, 0); return "ok" }
        function type(text: string): string { page.pending = text.split("+").join(" + "); page.captured(); return JSON.stringify(page.ev) }
        function cancel(): void { page.cancelEdit() }
        function apply(replace: bool): void { page.commit(replace) }
        function state(): string { return JSON.stringify({ conflicts: page.conflicts, override: page.override, edit: page.editId, pending: page.pending, ev: page.ev, note: page.note, groups: page.groupNames, rec: page.recArmed, sub: page.hasSubmap, dry: SysAct.dry }) }
    }

    // ---- leitura dos atalhos ----
    SetSection {
        visible: page.entries.length === 0
        SetRow {
            icon: page.loadErr ? "info" : "refresh"
            label: page.loadErr ? "Não consegui ler os atalhos" : "Lendo os atalhos…"
            description: page.loadErr ? "A leitura do Hyprland falhou; confira se ele está rodando e tente de novo" : ""
            UiButton { visible: page.loadErr; icon: "refresh"; text: "Tentar de novo"; kind: "ghost"; onClicked: page.load() }
        }
    }

    // ---- aviso do resultado ----
    SetSection {
        visible: page.note.text !== ""
        SetRow {
            icon: page.note.kind === "ok" ? "check" : page.note.kind === "err" ? "info" : "refresh"
            label: page.note.text
        }
    }

    // ---- conflitos ----
    SetSection {
        visible: page.conflictList.length > 0
        title: "Conflitos com os seus atalhos"; icon: "swap_horizontal"
        subtitle: "Combinações que o shell e a sua configuração queriam usar ao mesmo tempo"
        Repeater {
            model: page.conflictList
            delegate: SetRow {
                required property var modelData
                icon: "swap_horizontal"
                label: modelData.desc
                description: modelData.combo + (modelData.dec === "keep" ? " · vale o seu: " + modelData.who : modelData.dec === "replace" ? " · o do shell substituiu o seu" : " · os dois estão ativos: " + modelData.who)
                UiSeg {
                    options: [["keep", "O meu"], ["replace", "O do shell"]]
                    value: modelData.dec
                    enabled: !page.saving
                    onPicked: v => page.setDecision(modelData.id, v)
                }
            }
        }
    }

    // ---- atalhos do shell, por grupo ----
    Repeater {
        model: page.groupNames
        delegate: SetSection {
            id: sec
            required property string modelData
            title: modelData; icon: page.grpIcons[modelData] || "keyboard"
            Repeater {
                model: page.groupIds[sec.modelData]
                delegate: SetRow {
                    id: row
                    required property string modelData
                    readonly property var e: { page.rev; return page.byId[modelData] || ({ id: "", key: [], desc: "", grp: "" }) }
                    readonly property string st: { page.rev; return page.stateOf(e) }
                    readonly property var list: { page.rev; return page.shown(e) }
                    icon: page.iconFor(e)
                    label: e.desc
                    description: st === "kept" ? "Mantido o seu atalho: " + (page.userHits(e, page.defaults(e))[0] ? page.bindText(page.userHits(e, page.defaults(e))[0]) : "nenhum outro usa mais")
                        : st === "changed" ? "Padrão: " + page.defaults(e).join("  /  ").replace(/\s*\+\s*/g, " + ")
                        : st === "off" && e.off ? "Vem desligado; ligue para usar " + page.defaults(e).join(" ou ")
                        : e.locked ? "Funciona com a tela bloqueada" : e.release ? "Dispara ao soltar as teclas" : ""
                    checked: st === "kept" ? undefined : st !== "off"
                    switchOnly: true
                    canReset: st === "changed" || (st === "off" && page.ovr(e) === false && !e.off)
                    enabled: !page.saving
                    onToggled: on => page.toggleOn(e, on)
                    onReset: page.resetEntry(e)
                    onClicked: if (st !== "kept") page.startEdit(e.id, 0)
                    // selo de estado + mudar
                    Rectangle {
                        visible: row.st !== "ok"
                        anchors.verticalCenter: parent.verticalCenter
                        height: 22; width: pl.implicitWidth + 16; radius: 11
                        color: row.st === "changed" ? Theme.tint(0.16) : Theme.track
                        border.width: 1; border.color: row.st === "changed" ? Theme.tint(0.4) : Theme.border
                        UiText { id: pl; anchors.centerIn: parent; font.pixelSize: SetK.fChip - 1; font.weight: Font.Medium
                            color: row.st === "changed" ? Theme.accent : Theme.muted
                            text: row.st === "kept" ? "Seu atalho vence" : row.st === "off" ? "Desligado" : "Alterado" }
                    }
                    UiButton { visible: row.st === "kept"; text: "Usar o do shell"; kind: "ghost"; onClicked: page.setDecision(row.e.id, "replace") }
                    UiButton { visible: row.st !== "kept"; icon: "pencil"; kind: "ghost"; onClicked: page.editId === row.e.id ? page.cancelEdit() : page.startEdit(row.e.id, 0) }

                    below: [
                        Item {
                            width: parent.width; height: caps.implicitHeight + 12
                            Flow {
                                id: caps
                                width: parent.width; spacing: 14
                                Repeater {
                                    model: row.list
                                    delegate: Row {
                                        required property string modelData
                                        required property int index
                                        spacing: 6
                                        UiText { visible: index > 0; anchors.verticalCenter: parent.verticalCenter; text: "ou"; color: Theme.muted; font.pixelSize: 12 }
                                        KeyCaps { combo: modelData; dim: row.st === "off" || row.st === "kept"; anchors.verticalCenter: parent.verticalCenter }
                                        Rectangle {
                                            visible: row.list.length > 1 && row.st !== "kept"
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 24; height: 24; radius: 12
                                            color: pm.containsMouse ? Theme.cardHi : "transparent"
                                            UiIcon { anchors.centerIn: parent; name: "pencil"; size: 13; color: page.editId === row.e.id && page.editIdx === index ? Theme.accent : Theme.muted }
                                            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.startEdit(row.e.id, index) }
                                        }
                                    }
                                }
                            }
                        },
                        Loader {
                            width: parent.width
                            active: page.editId === row.e.id
                            sourceComponent: recC
                        }
                    ]
                }
            }
        }
    }

    // ---- gravador (aparece embaixo da linha em edicao) ----
    Component {
        id: recC
        FocusScope {
            id: rc
            width: parent ? parent.width : 400
            height: col.implicitHeight + 28
            Component.onCompleted: capt.forceActiveFocus()
            Connections { target: page; function onCaptured() { fld.text = page.pending } }
            Connections { target: page; function onEditIdxChanged() { fld.text = ""; capt.forceActiveFocus() } }
            Rectangle { anchors { fill: parent; bottomMargin: 12 } radius: SetK.innerRadius; color: Theme.tint(0.06); border.width: 1; border.color: Theme.tint(0.28) }
            Column {
                id: col
                x: 14; y: 14
                width: parent.width - 28
                spacing: 10
                Item {
                    id: capt
                    width: parent.width; height: 34
                    focus: true
                    Keys.onPressed: e => page.handleCap(e)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        UiIcon { anchors.verticalCenter: parent.verticalCenter; name: "keyboard"; size: 18; color: Theme.accent }
                        UiText { visible: page.pending === ""; anchors.verticalCenter: parent.verticalCenter; text: "Aperte a nova combinação agora…"; color: Theme.text; font.pixelSize: 13 }
                        KeyCaps { visible: page.pending !== ""; anchors.verticalCenter: parent.verticalCenter; combo: page.ev && page.ev.combo ? page.ev.combo : page.pending }
                    }
                    UiButton { visible: page.hasSubmap && !SysAct.dry && !page.recArmed; anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "Gravar de novo"; kind: "ghost"; onClicked: { page.pending = ""; page.enterRec(); capt.forceActiveFocus() } }
                }
                UiText {
                    width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc
                    text: "Esc cancela. O Hyprland pega as combinações que já usa antes da janela" + (page.hasSubmap && !SysAct.dry ? " (por isso os atalhos ficam parados até 10 s enquanto grava)" : "") + ": para essas, digite abaixo."
                }
                UiField {
                    id: fld
                    width: parent.width
                    placeholderText: "ou digite: SUPER + ALT + K"
                    onActiveFocusChanged: if (activeFocus) page.exitRec()
                    onTextEdited: page.pending = text.trim()
                    Keys.onEscapePressed: page.cancelEdit()
                    Keys.onReturnPressed: if (page.ev && page.ev.combo && !page.ev.hit) page.commit(false)
                }
                UiText {
                    visible: text !== ""
                    width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: SetK.fDesc
                    readonly property var v: page.ev
                    color: v && (v.err || v.hit) ? Theme.danger : Theme.muted
                    text: !v ? "" : v.err ? v.err : v.hit ? (v.hit.kind === "shell" ? "Esta combinação já é do atalho do shell “" + v.hit.who + "”." : "Esta combinação já é um atalho seu: " + v.hit.who + ".") : "Livre. Aplicar grava e recarrega o Hyprland."
                }
                Row {
                    spacing: SetK.sm
                    UiButton { text: "Aplicar atalho"; kind: "accent"; enabled: !!page.ev && !!page.ev.combo && !page.ev.hit && !page.saving; onClicked: page.commit(false) }
                    UiButton {
                        visible: !!page.ev && !!page.ev.hit
                        text: "Substituir"; kind: "danger"; enabled: !page.saving
                        onClicked: page.commit(true)
                    }
                    UiButton { text: "Cancelar"; kind: "ghost"; onClicked: page.cancelEdit() }
                }
            }
        }
    }

    // ---- os seus atalhos (so leitura) ----
    SetSection {
        title: "Seus atalhos"; icon: "listCheck"
        subtitle: "Os outros atalhos do Hyprland, lidos agora (só leitura)"
        SetExpander {
            icon: "search"; label: "Ver todos"; description: page.userBinds.length === 0 ? "Nenhum atalho seu" : page.userBinds.length === 1 ? "1 atalho" : page.userBinds.length.toLocaleString(Qt.locale("pt_BR"), "f", 0) + " atalhos"
            lazy: Component {
                SetBlock {
                    id: ub
                    sub: true
                    readonly property var items: {
                        const q = ubF.text.toLowerCase()
                        return page.userBinds.map(b => ({ combo: page.comboText(b), what: page.bindText(b) }))
                            .filter(x => !q || (x.combo + " " + x.what).toLowerCase().includes(q))
                    }
                    UiField { id: ubF; width: parent.width; placeholderText: "Buscar atalho…" }
                    UiText { visible: ub.items.length === 0; width: parent.width; text: ubF.text !== "" ? "Nada encontrado para “" + ubF.text + "”." : "Nenhum atalho seu foi encontrado."; color: Theme.muted; font.pixelSize: SetK.fDesc }
                    ListView {
                        width: parent.width; height: 320
                        clip: true; boundsBehavior: Flickable.StopAtBounds
                        model: ub.items
                        delegate: Item {
                            required property var modelData
                            width: ListView.view.width; height: 34
                            UiText { anchors.verticalCenter: parent.verticalCenter; width: parent.width - kcc.width - 12; elide: Text.ElideRight; text: modelData.what; color: Theme.text; font.pixelSize: 13 }
                            KeyCaps { id: kcc; anchors { right: parent.right; verticalCenter: parent.verticalCenter } combo: modelData.combo; capH: 22 }
                        }
                    }
                }
            }
        }
        SetRow { icon: "pencil"; label: "Editar arquivo"; description: "Abre o keybinds.lua no seu editor"; link: true; onClicked: page.openUserFile() }
    }

    // ---- tudo ----
    SetSection {
        title: "Restaurar"; icon: "restore"
        SetRow {
            icon: "restore"; label: "Restaurar atalhos do shell"
            description: page.confirmAll ? "Apaga as combinações que você mudou; as decisões de conflito ficam." : "Volta todas as combinações ao padrão"
            enabled: !page.saving
            UiButton { visible: !page.confirmAll; text: "Restaurar padrão"; kind: "ghost"; onClicked: page.confirmAll = true }
            UiButton { visible: page.confirmAll; text: "Restaurar tudo"; kind: "danger"; onClicked: page.resetAll() }
            UiButton { visible: page.confirmAll; text: "Cancelar"; kind: "ghost"; onClicked: page.confirmAll = false }
        }
    }
}
