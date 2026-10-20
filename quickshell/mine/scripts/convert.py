#!/usr/bin/env python3
# Converte imagens (widget "Conversor de imagens" da area de trabalho).
# uso: convert.py <formato png|jpg|webp|avif|pdf> <qualidade 30-100> <same|downloads> <keep 1|0> <single|merge> <arquivo>...
# Uma linha JSON por arquivo: {"in", "out", "ok", "err"}. Nunca sobrescreve (acrescenta -1, -2...). Sem "keep", o
# original vai para a lixeira (gio trash), nunca e apagado.
import json, os, subprocess, sys
from PIL import Image, ImageOps

EXT = {"png": "png", "jpg": "jpg", "webp": "webp", "avif": "avif", "bmp": "bmp", "tiff": "tiff", "pdf": "pdf"}
FMT = {"png": "PNG", "jpg": "JPEG", "webp": "WEBP", "avif": "AVIF", "bmp": "BMP", "tiff": "TIFF", "pdf": "PDF"}


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
    if len(sys.argv) < 7:
        print(json.dumps({"ok": False, "err": "argumentos"}))
        return
    fmt, quality, where, keep = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4] == "1"
    if fmt not in EXT:
        print(json.dumps({"ok": False, "err": "formato desconhecido"}))
        return
    outdir = downloads() if where == "downloads" else None
    merge = sys.argv[5] == "merge" and fmt == "pdf"
    pages = []
    for src in sys.argv[6:]:
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
            elif fmt == "bmp" and im.mode not in ("RGB", "L", "P"):
                im = im.convert("RGB")
            elif im.mode not in ("RGB", "RGBA", "L"):
                im = im.convert("RGBA" if "A" in im.mode or "transparency" in im.info else "RGB")
            d = outdir or os.path.dirname(os.path.abspath(src))
            os.makedirs(d, exist_ok=True)
            base = os.path.splitext(os.path.basename(src))[0]
            if merge:
                pages.append((src, im, d, base))
                continue
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
    if merge and pages:
        res = {"in": pages[0][0], "out": "", "ok": False, "err": ""}
        try:
            out = free_name(pages[0][2], pages[0][3] + "_juntas", "pdf")
            rgb = [p[1].convert("RGB") for p in pages]
            rgb[0].save(out, "PDF", save_all=True, append_images=rgb[1:], resolution=150.0)
            res.update(out=out, ok=True)
            if not keep:
                for p in pages:
                    subprocess.run(["gio", "trash", p[0]], capture_output=True, timeout=10)
        except Exception as e:
            res["err"] = str(e)[:160]
        print(json.dumps(res), flush=True)


if __name__ == "__main__":
    main()
