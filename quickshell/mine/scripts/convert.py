#!/usr/bin/env python3
# Converte imagens (widget "Conversor de imagens" da area de trabalho).
# uso: convert.py <formato png|jpg|webp|avif|pdf> <qualidade 30-100> <same|downloads> <keep 1|0> <arquivo>...
# Uma linha JSON por arquivo: {"in", "out", "ok", "err"}. Nunca sobrescreve (acrescenta -1, -2...). Sem "keep", o
# original vai para a lixeira (gio trash), nunca e apagado.
import json, os, subprocess, sys
from PIL import Image, ImageOps

EXT = {"png": "png", "jpg": "jpg", "webp": "webp", "avif": "avif", "pdf": "pdf"}
FMT = {"png": "PNG", "jpg": "JPEG", "webp": "WEBP", "avif": "AVIF", "pdf": "PDF"}


def downloads():
    try:
        d = subprocess.run(["xdg-user-dir", "DOWNLOAD"], capture_output=True, text=True, timeout=3).stdout.strip()
        if d and os.path.isdir(d):
            return d
    except Exception:
        pass
    return os.path.expanduser("~/Downloads")


def free_name(d, base, ext):
    p = os.path.join(d, base + "." + ext)
    i = 1
    while os.path.exists(p):
        p = os.path.join(d, "%s-%d.%s" % (base, i, ext))
        i += 1
    return p


def main():
    if len(sys.argv) < 6:
        print(json.dumps({"ok": False, "err": "argumentos"}))
        return
    fmt, quality, where, keep = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4] == "1"
    if fmt not in EXT:
        print(json.dumps({"ok": False, "err": "formato desconhecido"}))
        return
    outdir = downloads() if where == "downloads" else None
    for src in sys.argv[5:]:
        res = {"in": src, "out": "", "ok": False, "err": ""}
        try:
            im = Image.open(src)
            im = ImageOps.exif_transpose(im)
            # sem transparencia em JPG/PDF: achata sobre branco
            if fmt in ("jpg", "pdf") and (im.mode in ("RGBA", "LA") or (im.mode == "P" and "transparency" in im.info)):
                im = im.convert("RGBA")
                bg = Image.new("RGB", im.size, (255, 255, 255))
                bg.paste(im, mask=im.split()[-1])
                im = bg
            elif im.mode not in ("RGB", "RGBA", "L"):
                im = im.convert("RGBA" if "A" in im.mode or "transparency" in im.info else "RGB")
            d = outdir or os.path.dirname(os.path.abspath(src))
            os.makedirs(d, exist_ok=True)
            base = os.path.splitext(os.path.basename(src))[0]
            out = free_name(d, base, EXT[fmt])
            kw = {}
            if fmt in ("jpg", "webp", "avif"):
                kw["quality"] = max(1, min(100, quality))
            if fmt == "jpg":
                kw["optimize"] = True
            if fmt == "pdf":
                kw["resolution"] = 150.0
            im.save(out, FMT[fmt], **kw)
            res.update(out=out, ok=True)
            if not keep and os.path.abspath(out) != os.path.abspath(src):
                subprocess.run(["gio", "trash", src], capture_output=True, timeout=10)
        except Exception as e:
            res["err"] = str(e)[:160]
        print(json.dumps(res), flush=True)


if __name__ == "__main__":
    main()
