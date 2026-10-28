#!/usr/bin/env python3
# Recorta uma imagem para as boas-vindas do terminal. A original nunca e alterada; o resultado vai para <saida> (PNG).
# uso: crop_image.py <origem> <saida> <giro> <x> <y> <largura> <altura>
#   giro em graus (horario, multiplo de 90); x, y, largura, altura: recorte em fracao da imagem ja girada (0..1)
import os, sys
from PIL import Image, ImageOps

src, out = sys.argv[1], sys.argv[2]
rot = int(float(sys.argv[3])) % 360
x, y, w, h = (float(v) for v in sys.argv[4:8])

im = ImageOps.exif_transpose(Image.open(src))
im = im.convert("RGBA" if "A" in im.getbands() or im.mode == "P" and "transparency" in im.info else "RGB")
if rot:
    im = im.rotate(-rot, expand=True)   # PIL gira no sentido anti-horario
l = max(0, min(im.width - 1, round(x * im.width)))
t = max(0, min(im.height - 1, round(y * im.height)))
r = max(l + 1, min(im.width, round((x + w) * im.width)))
b = max(t + 1, min(im.height, round((y + h) * im.height)))
im = im.crop((l, t, r, b))
if max(im.size) > 1600:
    s = 1600 / max(im.size)
    im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
tmp = out + ".tmp"
im.save(tmp, "PNG")
os.replace(tmp, out)
print("%dx%d" % im.size)
