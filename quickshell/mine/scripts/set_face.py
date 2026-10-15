#!/usr/bin/env python3
# Troca a foto de perfil (~/.face): recorta a imagem escolhida no centro (quadrado), reduz para 512x512 e salva.
# A foto anterior fica em ~/.face.prev; a primeira foto que existia, em ~/.face.orig (nunca e sobrescrita).
import os, shutil, sys
from PIL import Image, ImageOps

# uso: set_face.py <imagem> [giro x y tamanho]
#   giro em graus (horario, multiplo de 90); x, y, tamanho: recorte quadrado em fracao da imagem ja girada (0..1)
#   sem os extras: recorta o quadrado do centro
src = sys.argv[1]
home = os.path.expanduser("~")
face = os.path.join(home, ".face")

im = ImageOps.exif_transpose(Image.open(src)).convert("RGB")
if len(sys.argv) >= 6:
    rot = int(float(sys.argv[2])) % 360
    if rot:
        im = im.rotate(-rot, expand=True)   # PIL gira no sentido anti-horario
    nx, ny, ns = (float(v) for v in sys.argv[3:6])
    l, t = nx * im.width, ny * im.height
    s = ns * im.width
    box = tuple(round(v) for v in (l, t, l + s, t + s))
else:
    s = min(im.size)
    l, t = (im.width - s) // 2, (im.height - s) // 2
    box = (l, t, l + s, t + s)
im = im.crop(box).resize((512, 512), Image.LANCZOS)

if os.path.exists(face):
    orig = face + ".orig"
    if not os.path.exists(orig):
        shutil.copy2(face, orig)
    shutil.copy2(face, face + ".prev")
tmp = face + ".tmp"
im.save(tmp, "JPEG", quality=92)
os.replace(tmp, face)
print("ok")
