#!/usr/bin/env python3
# Gera miniaturas (padrao freedesktop: ~/.cache/thumbnails/large/<md5 da uri>.png, 256 px) das imagens de uma pasta.
# Imprime o caminho de cada imagem assim que a miniatura dela fica pronta. Uso: thumbs.py <pasta>
import hashlib, os, sys
from urllib.parse import quote
from PIL import Image, ImageOps, PngImagePlugin

EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".avif", ".tif", ".tiff"}
out_dir = os.path.expanduser("~/.cache/thumbnails/large")
os.makedirs(out_dir, exist_ok=True)

def uri(path):
    # mesma codificacao do encodeURIComponent do QML, pedaco por pedaco
    return "file://" + "/".join(quote(p, safe="!~*'()") for p in path.split("/"))

d = sys.argv[1]
try:
    names = sorted(os.listdir(d))
except OSError:
    sys.exit(0)
for n in names:
    p = os.path.join(d, n)
    if os.path.splitext(n)[1].lower() not in EXTS or not os.path.isfile(p):
        continue
    u = uri(p)
    t = os.path.join(out_dir, hashlib.md5(u.encode()).hexdigest() + ".png")
    mt = int(os.path.getmtime(p))
    if os.path.exists(t) and os.path.getmtime(t) >= mt:
        continue
    try:
        im = Image.open(p)
        im.draft("RGB", (512, 512))   # jpeg: decodifica ja reduzido (bem mais rapido)
        im = ImageOps.exif_transpose(im).convert("RGBA")
        im.thumbnail((256, 256), Image.LANCZOS)
        info = PngImagePlugin.PngInfo()
        info.add_text("Thumb::URI", u)
        info.add_text("Thumb::MTime", str(mt))
        tmp = t + ".tmp"
        im.save(tmp, "PNG", pnginfo=info)
        os.replace(tmp, t)
        print(p, flush=True)
    except Exception:
        pass
