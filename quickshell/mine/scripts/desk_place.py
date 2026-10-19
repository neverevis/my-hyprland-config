#!/usr/bin/env python3
"""Posicao automatica e brilho dos widgets da area de trabalho a partir do wallpaper.

Uso: desk_place.py <wallpaper> <telaW> <telaH> <json>
json = { "area": [x, y, w, h], "widgets": [{ "id", "x", "y", "w", "h", "mode": "free" | "calm" | "busy" }] }
Saida (stdout, JSON): { id: { "fx", "fy", "lum" } }
  - calm/busy: fx, fy (0..1 dentro da area) do lugar com menos/mais detalhe (bordas) que nao cruza outro widget
  - lum: brilho medio (0..1) do wallpaper embaixo do widget (para escolher texto claro ou escuro)
O wallpaper e recortado como na tela (preenche cortando, PreserveAspectCrop) e reduzido para ficar rapido.
"""
import json
import sys

from PIL import Image, ImageFilter, ImageOps


def main():
    path, sw, sh, spec = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), json.loads(sys.argv[4])
    k = 8  # 1 pixel reduzido = k pixels da tela
    gw, gh = max(8, sw // k), max(8, sh // k)
    img = Image.open(path).convert("RGB")
    img = ImageOps.fit(img, (gw, gh), Image.BILINEAR)
    gray = ImageOps.grayscale(img)
    edges = gray.filter(ImageFilter.FIND_EDGES)
    flat = lambda im: list(im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata())
    L = flat(gray)
    E = flat(edges)

    def integral(vals):
        I = [[0.0] * (gw + 1) for _ in range(gh + 1)]
        for y in range(gh):
            row = 0.0
            for x in range(gw):
                row += vals[y * gw + x]
                I[y + 1][x + 1] = I[y][x + 1] + row
        return I

    IL, IE = integral(L), integral(E)

    def box(I, x, y, w, h):
        x0, y0 = max(0, min(gw, x)), max(0, min(gh, y))
        x1, y1 = max(0, min(gw, x + w)), max(0, min(gh, y + h))
        a = max(1, (x1 - x0) * (y1 - y0))
        return (I[y1][x1] - I[y0][x1] - I[y1][x0] + I[y0][x0]) / a

    ax, ay, aw, ah = [v / k for v in spec["area"]]
    out, taken = {}, []
    # widgets livres ocupam o lugar deles; os automaticos procuram lugar depois (os maiores primeiro)
    ws = spec["widgets"]
    for wd in ws:
        if wd.get("mode", "free") == "free":
            taken.append((wd["x"] / k, wd["y"] / k, wd["w"] / k, wd["h"] / k))
    for wd in sorted([w for w in ws if w.get("mode") in ("calm", "busy")], key=lambda w: -w["w"] * w["h"]):
        w, h = wd["w"] / k, wd["h"] / k
        best, bx, by = None, ax, ay
        step = 2
        y = ay
        while y + h <= ay + ah + 0.01:
            x = ax
            while x + w <= ax + aw + 0.01:
                pad = 2
                hit = any(x < tx + tw + pad and tx < x + w + pad and y < ty + th + pad and ty < y + h + pad for tx, ty, tw, th in taken)
                if not hit:
                    e = box(IE, int(x), int(y), int(w), int(h))
                    score = e if wd["mode"] == "calm" else -e
                    if best is None or score < best:
                        best, bx, by = score, x, y
                x += step
            y += step
        taken.append((bx, by, w, h))
        fx = 0.5 if aw - w <= 0 else (bx - ax) / (aw - w)
        fy = 0.5 if ah - h <= 0 else (by - ay) / (ah - h)
        out[wd["id"]] = {"fx": max(0, min(1, fx)), "fy": max(0, min(1, fy)), "x": bx * k, "y": by * k}
    for wd in ws:
        r = out.get(wd["id"])
        x, y = (r["x"], r["y"]) if r else (wd["x"], wd["y"])
        lum = box(IL, int(x / k), int(y / k), int(wd["w"] / k), int(wd["h"] / k)) / 255.0
        out.setdefault(wd["id"], {})["lum"] = round(lum, 3)
    print(json.dumps(out))


if __name__ == "__main__":
    main()
