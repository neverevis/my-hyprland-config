#!/usr/bin/env python3
# Acoes do seletor de area (RegionSelector.qml) sobre a tela congelada:
#   capture.py <acao> <tela.png> x y w h [circle]
# acoes: copy (copia e salva em ~/Imagens/Screenshots), ocr (copia o texto), translate (texto traduzido para o
# portugues), annotate (abre no satty), lens (envia para o litterbox.catbox.moe, apaga em 1 h, e abre QS_SEARCHURL + url; padrao Google Lens)
# translate usa QS_TRANSTO (codigo do idioma, padrao pt)
# Imprime uma linha JSON {ok, msg, text?, path?}.
import json, os, shutil, subprocess, sys, time
from PIL import Image, ImageDraw

HOME = os.path.expanduser("~")
# QS_SHOTDIR (Ferramentas > Captura): pasta das capturas; definido e vazio = so copia, nao salva
SHOTS = os.environ.get("QS_SHOTDIR", os.path.join(HOME, "Imagens", "Screenshots"))
if SHOTS.startswith("~"): SHOTS = os.path.expanduser(SHOTS)

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

def boxes(src, target):
    # traducao no lugar: OCR por paragrafo (tesseract tsv), cada paragrafo traduzido com o trans, mais cor de fundo/texto
    from concurrent.futures import ThreadPoolExecutor
    r = subprocess.run(["tesseract", src, "-", "-l", "por+eng", "--psm", "3", "tsv"], capture_output=True, text=True, timeout=120)
    rows = [l.split("\t") for l in r.stdout.splitlines()[1:]]
    pars = {}
    for c in rows:
        if len(c) < 12 or c[0] != "5" or not c[11].strip():
            continue
        try:
            conf = float(c[10])
        except ValueError:
            continue
        if conf < 35:
            continue
        key = (c[2], c[3], c[4])   # bloco, paragrafo
        l, t, w, h = int(c[6]), int(c[7]), int(c[8]), int(c[9])
        d = pars.setdefault(key, {"x0": l, "y0": t, "x1": l + w, "y1": t + h, "lines": {}})
        d["x0"] = min(d["x0"], l); d["y0"] = min(d["y0"], t); d["x1"] = max(d["x1"], l + w); d["y1"] = max(d["y1"], t + h)
        d["lines"].setdefault(c[5], []).append(c[11].strip())
    im = Image.open(src).convert("RGB")
    lst = []
    for d in pars.values():
        text = " ".join(" ".join(v) for _, v in sorted(d["lines"].items(), key=lambda kv: int(kv[0])))
        if len(text) < 2 or not any(ch.isalpha() for ch in text):
            continue
        lst.append({"x": d["x0"], "y": d["y0"], "w": d["x1"] - d["x0"], "h": d["y1"] - d["y0"], "text": text, "lines": len(d["lines"])})
    lst = lst[:80]
    def tr(b):
        try:
            p = subprocess.run(["trans", "-b", "-no-autocorrect", ":" + target, b["text"]], capture_output=True, text=True, timeout=25)
            return p.stdout.strip()
        except Exception:
            return ""
    with ThreadPoolExecutor(8) as ex:
        res = list(ex.map(tr, lst))
    for b, t in zip(lst, res):
        b["tr"] = t or b["text"]
        x, y, w, h = b["x"], b["y"], b["w"], b["h"]
        edge = []
        for xx in range(x, x + w, max(1, w // 16)):
            edge += [im.getpixel((min(im.width - 1, xx), max(0, y - 2))), im.getpixel((min(im.width - 1, xx), min(im.height - 1, y + h + 2)))]
        for yy in range(y, y + h, max(1, h // 8)):
            edge += [im.getpixel((max(0, x - 2), min(im.height - 1, yy))), im.getpixel((min(im.width - 1, x + w + 2), min(im.height - 1, yy)))]
        bg = tuple(sorted(c[i] for c in edge)[len(edge) // 2] for i in range(3)) if edge else (255, 255, 255)
        lum = 0.2126 * bg[0] + 0.7152 * bg[1] + 0.0722 * bg[2]
        b["bg"] = "#%02x%02x%02x" % bg
        b["fg"] = "#111111" if lum > 140 else "#f2f2f2"
    out(ok=True, msg="%d trechos" % len(lst), boxes=lst, size=[im.width, im.height], translated=any(b["tr"] != b["text"] for b in lst))

def main():
    if sys.argv[1] == "ocrboxes":
        boxes(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "pt")
    act, src = sys.argv[1], sys.argv[2]
    x, y, w, h = map(float, sys.argv[3:7])
    circle = len(sys.argv) > 7 and sys.argv[7] == "circle"
    im = crop(src, x, y, w, h, circle)
    stamp = time.strftime("%Y%m%d_%H-%M-%S")
    if SHOTS: os.makedirs(SHOTS, exist_ok=True)
    path = os.path.join(SHOTS or os.path.join(HOME, ".cache", "quickshell-mine"), f"screenshot_{stamp}.png")
    if act == "copy":
        im.save(path)
        with open(path, "rb") as f:
            subprocess.run(["wl-copy", "-t", "image/png"], stdin=f, timeout=5)
        if not SHOTS:
            os.remove(path)
            notify("Captura copiada", "Na área de transferência (sem salvar)", "")
            out(ok=True, msg="Copiada")
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
        r = subprocess.run(["trans", "-b", "-no-autocorrect", ":" + (os.environ.get("QS_TRANSTO") or "pt"), t], capture_output=True, text=True, timeout=30)
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
        base = os.environ.get("QS_SEARCHURL") or "https://lens.google.com/uploadbyurl?url="
        r = subprocess.run(["curl", "-fsS", "--max-time", "60", "-F", "reqtype=fileupload", "-F", "time=1h", "-F", "fileToUpload=@" + tmp,
                            "https://litterbox.catbox.moe/resources/internals/api.php"], capture_output=True, text=True)
        url = r.stdout.strip()
        if not url.startswith("http"):   # reserva: uguu.se
            r = subprocess.run(["curl", "-fsS", "--max-time", "60", "-F", "files[]=@" + tmp, "https://uguu.se/upload?output=text"], capture_output=True, text=True)
            url = r.stdout.strip()
        if not url.startswith("http"):
            out(ok=False, msg="Falhou ao enviar a imagem")
        subprocess.Popen(["xdg-open", base + url], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        out(ok=True, msg="Abrindo a busca por imagem", path=url)
    out(ok=False, msg="Ação desconhecida: " + act)

main()
