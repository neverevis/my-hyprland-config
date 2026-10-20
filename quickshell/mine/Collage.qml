// Mosaico em arvore: cada no e uma imagem (leaf) ou uma divisao (split) em duas partes, no maximo 6 imagens.
// Guardado em Settings.wpCollageTree (JSON). Vazio = usa o arranjo fixo (Settings.wpCollageLayout) com as imagens antigas.
// Dados: objeto com root (o no raiz) e primary (id da imagem principal). Cada no e leaf (id, img) ou split (dir h = lado a lado, v = um sobre o outro; r = 0.1 a 0.9; a e b = os filhos).
pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property int maxLeaves: 6
    readonly property var presets: ({
        "2v": ["h", 0.5, "L", "L"],
        "2h": ["v", 0.5, "L", "L"],
        "3": ["h", 1 / 3, "L", ["h", 0.5, "L", "L"]],
        "1+2": ["h", 0.6, "L", ["v", 0.5, "L", "L"]],
        "2x2": ["h", 0.5, ["v", 0.5, "L", "L"], ["v", 0.5, "L", "L"]],
        "2+1": ["v", 0.55, ["h", 0.5, "L", "L"], "L"],
        "1+3": ["h", 0.5, "L", ["v", 0.34, "L", ["v", 0.5, "L", "L"]]],
        "6": ["v", 0.5, ["h", 1 / 3, "L", ["h", 0.5, "L", "L"]], ["h", 1 / 3, "L", ["h", 0.5, "L", "L"]]]
    })
    readonly property var presetNames: [["2v", "Lado a lado"], ["2h", "Em cima e embaixo"], ["3", "Três"], ["1+2", "Um grande + dois"], ["2x2", "Quatro"], ["2+1", "Dois + um"], ["1+3", "Um + três"], ["6", "Seis"]]

    // ids sequenciais (c e um contador local: mexer numa propriedade dentro de um binding cria laco)
    function build(sp, imgs, c) {   // sp = "L" ou [dir, r, a, b]; imgs: lista consumida na ordem
        if (sp === "L") return { k: "leaf", id: ++c.n, img: imgs.length ? imgs.shift() : "" }
        const a = build(sp[2], imgs, c)
        return { k: "split", dir: sp[0], r: sp[1], a: a, b: build(sp[3], imgs, c) }
    }
    function fromPreset(name, imgs) { return { root: build(presets[name] ?? presets["2v"], (imgs || []).slice(), { n: 0 }), primary: 1 } }

    // arvore atual (do JSON ou do arranjo fixo antigo); nunca nula
    readonly property var data: {
        const t = Settings.wpCollageTree
        if (t) { try { const d = JSON.parse(t); if (d && d.root) return d } catch (e) {} }
        return fromPreset(Settings.wpCollageLayout, Settings.list(Settings.wpCollage).filter(x => x))
    }
    readonly property bool custom: Settings.wpCollageTree !== ""
    readonly property int primary: data.primary ?? 1

    function walk(n, x, y, w, h, out) {
        if (n.k === "leaf") { out.push({ id: n.id, img: n.img || "", x: x, y: y, w: w, h: h }); return }
        if (n.dir === "h") { const c = w * n.r; walk(n.a, x, y, c, h, out); walk(n.b, x + c, y, w - c, h, out) }
        else { const c = h * n.r; walk(n.a, x, y, w, c, out); walk(n.b, x, y + c, w, h - c, out) }
    }
    // retangulos das imagens (em fracoes 0-1 se w=h=1)
    function rects(w, h) { const o = []; walk(data.root, 0, 0, w, h, o); return o }
    readonly property var leafRects: rects(1, 1)
    readonly property int count: leafRects.length
    // cortes (para as alcas de arrastar): { path, dir, x, y, w, h } da caixa do corte
    function splits(n, x, y, w, h, path, out) {
        if (n.k === "leaf") return
        out.push({ path: path, dir: n.dir, r: n.r, x: x, y: y, w: w, h: h })
        if (n.dir === "h") { const c = w * n.r; splits(n.a, x, y, c, h, path + "a", out); splits(n.b, x + c, y, w - c, h, path + "b", out) }
        else { const c = h * n.r; splits(n.a, x, y, w, c, path + "a", out); splits(n.b, x, y + c, w, h - c, path + "b", out) }
    }
    readonly property var cuts: { const o = []; splits(data.root, 0, 0, 1, 1, "", o); return o }

    // ---- edicao: sempre sobre uma copia, e grava o JSON ----
    function clone(d) { return JSON.parse(JSON.stringify(d)) }
    function save(d) { Settings.wpCollageTree = JSON.stringify(d) }
    function find(n, id, parent, side) {
        if (n.k === "leaf") return n.id === id ? { n: n, parent: parent, side: side } : null
        return find(n.a, id, n, "a") || find(n.b, id, n, "b")
    }
    function maxId(n) { return n.k === "leaf" ? n.id : Math.max(maxId(n.a), maxId(n.b)) }
    function useCurrentAsBase() { return clone(data) }
    function setImage(id, path) { const d = clone(data); const f = find(d.root, id, null, ""); if (f) { f.n.img = path; save(d) } }
    function split(id, dir) {   // divide a imagem em duas (a nova comeca vazia = proxima da pasta)
        if (count >= maxLeaves) return
        const d = clone(data); const f = find(d.root, id, null, ""); if (!f) return
        const nn = { k: "split", dir: dir, r: 0.5, a: f.n, b: { k: "leaf", id: maxId(d.root) + 1, img: "" } }
        if (!f.parent) d.root = nn; else f.parent[f.side] = nn
        save(d)
    }
    function remove(id) {
        if (count <= 1) return
        const d = clone(data); const f = find(d.root, id, null, ""); if (!f || !f.parent) return
        const other = f.parent[f.side === "a" ? "b" : "a"]
        const gp = findParent(d.root, f.parent, null, "")
        if (!gp) d.root = other; else gp.p[gp.s] = other
        if (d.primary === id) d.primary = leafIds(d.root)[0]
        save(d)
    }
    function findParent(n, target, parent, side) {
        if (n === target) return parent ? { p: parent, s: side } : null
        if (n.k === "leaf") return undefined
        const r = findParent(n.a, target, n, "a")
        return r !== undefined ? r : findParent(n.b, target, n, "b")
    }
    function leafIds(n) { return n.k === "leaf" ? [n.id] : leafIds(n.a).concat(leafIds(n.b)) }
    function setPrimary(id) { const d = clone(data); d.primary = id; save(d) }
    function setRatio(path, r) {
        const d = clone(data); let n = d.root
        for (const c of path) n = n[c]
        n.r = Math.max(0.12, Math.min(0.88, r)); save(d)
    }
    function setPreset(name) { save(fromPreset(name, rects(1, 1).map(l => l.img))) }
    function reset() { Settings.wpCollageTree = "" }
}
