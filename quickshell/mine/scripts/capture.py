#!/usr/bin/env python3
# Acoes do seletor de area (RegionSelector.qml) sobre a tela congelada:
#   capture.py <acao> <tela.png> x y w h [circle]
# acoes: copy (copia e salva em ~/Imagens/Screenshots), ocr (copia o texto), translate (texto traduzido para o
# portugues), annotate (abre no satty), lens (envia para o litterbox.catbox.moe, apaga em 1 h, e abre o Google Lens)
# Imprime uma linha JSON {ok, msg, text?, path?}.
import json, os, shutil, subprocess, sys, time
from PIL import Image, ImageDraw

HOME = os.path.expanduser("~")
SHOTS = os.path.join(HOME, "Imagens", "Screenshots")

def out(**kw):
    print(json.dumps(kw, ensure_ascii=False))
    sys.exit(0)

def crop(src, x, y, w, h, circle):
    im = Image.open(src).convert("RGBA")
    x, y, w, h = [max(0, int(round(v))) for v in (x, y, w, h)]
    im = im.crop((x, y, x + max(1, w), y + max(1, h)))
    if circle:
        m = Image.new("L", im.size, 0)
        ImageDraw.Draw(m).ellipse((0, 0, im.size[0] - 1, im.size[1] - 1), fill=255)
        im.putalpha(m)
    return im

def notify(title, body, icon=""):
    args = ["notify-send", "-a", "Captura"] + (["-i", icon] if icon else []) + [title, body]
    subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def copy_text(t):
    subprocess.run(["wl-copy"], input=t.encode(), timeout=5)

def ocr(path):
    r = subprocess.run(["tesseract", path, "-", "-l", "por+eng", "--psm", "6"], capture_output=True, text=True, timeout=60)
    return r.stdout.strip()

def main():
    act, src = sys.argv[1], sys.argv[2]
    x, y, w, h = map(float, sys.argv[3:7])
    circle = len(sys.argv) > 7 and sys.argv[7] == "circle"
    im = crop(src, x, y, w, h, circle)
    os.makedirs(SHOTS, exist_ok=True)
    stamp = time.strftime("%Y%m%d_%H-%M-%S")
    path = os.path.join(SHOTS, f"screenshot_{stamp}.png")
    if act == "copy":
        im.save(path)
        with open(path, "rb") as f:
            subprocess.run(["wl-copy", "-t", "image/png"], stdin=f, timeout=5)
        notify("Captura salva", path, path)
        out(ok=True, msg="Copiada e salva", path=path)
    tmp = os.path.join(HOME, ".cache", "quickshell-mine", "capture.png")
    os.makedirs(os.path.dirname(tmp), exist_ok=True)
    # OCR le melhor ampliado e sem transparencia
    big = im.convert("RGB")
    if act in ("ocr", "translate") and big.size[0] < 1200:
        k = max(1, 1200 // max(1, big.size[0]))
        big = big.resize((big.size[0] * min(k, 3), big.size[1] * min(k, 3)), Image.LANCZOS)
    big.save(tmp) if act in ("ocr", "translate") else im.save(tmp)
    if act == "ocr":
        t = ocr(tmp)
        if not t:
            out(ok=False, msg="Nenhum texto encontrado")
        copy_text(t)
        notify("Texto copiado", t[:300])
        out(ok=True, msg="Texto copiado", text=t)
    if act == "translate":
        t = ocr(tmp)
        if not t:
            out(ok=False, msg="Nenhum texto encontrado")
        r = subprocess.run(["trans", "-b", "-no-autocorrect", ":" + (sys.argv[8] if len(sys.argv) > 8 else "pt"), t], capture_output=True, text=True, timeout=30)
        tr = r.stdout.strip()
        if not tr:
            out(ok=False, msg="Não consegui traduzir (sem internet?)", text=t)
        copy_text(tr)
        notify("Tradução copiada", tr[:300])
        out(ok=True, msg="Tradução copiada", text=tr, original=t)
    if act == "annotate":
        im.save(path)
        subprocess.Popen(["satty", "--filename", path, "--output-filename", path, "--copy-command", "wl-copy"], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        out(ok=True, msg="Aberto no satty", path=path)
    if act == "lens":
        r = subprocess.run(["curl", "-fsS", "--max-time", "60", "-F", "reqtype=fileupload", "-F", "time=1h", "-F", "fileToUpload=@" + tmp,
                            "https://litterbox.catbox.moe/resources/internals/api.php"], capture_output=True, text=True)
        url = r.stdout.strip()
        if not url.startswith("http"):
            out(ok=False, msg="Falhou ao enviar a imagem")
        subprocess.Popen(["xdg-open", "https://lens.google.com/uploadbyurl?url=" + url], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        out(ok=True, msg="Abrindo o Google Lens", path=url)
    out(ok=False, msg="Ação desconhecida: " + act)

main()
