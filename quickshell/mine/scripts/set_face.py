#!/usr/bin/env python3
# Troca a foto de perfil (~/.face): recorta a imagem escolhida no centro (quadrado), reduz para 512x512 e salva.
# A foto anterior fica em ~/.face.prev; a primeira foto que existia, em ~/.face.orig (nunca e sobrescrita).
import os, shutil, sys
from PIL import Image, ImageOps

src = sys.argv[1]
home = os.path.expanduser("~")
face = os.path.join(home, ".face")

im = ImageOps.exif_transpose(Image.open(src)).convert("RGB")
s = min(im.size)
l, t = (im.width - s) // 2, (im.height - s) // 2
im = im.crop((l, t, l + s, t + s)).resize((512, 512), Image.LANCZOS)

if os.path.exists(face):
    orig = face + ".orig"
    if not os.path.exists(orig):
        shutil.copy2(face, orig)
    shutil.copy2(face, face + ".prev")
tmp = face + ".tmp"
im.save(tmp, "JPEG", quality=92)
os.replace(tmp, face)
print("ok")
