#!/usr/bin/env python3
# Historico da area de transferencia para o launcher (cliphist): uma lista JSON [{line, text, img}]. Imagens viram
# arquivos em ~/.cache/quickshell-mine/clip/<id>.<ext> (so as 40 mais recentes; ficam guardadas para as proximas vezes).
#   clip.py list [max]     -> lista
#   clip.py delete <linha> -> apaga uma entrada (a linha como o "cliphist list" mostra)
import json, os, re, subprocess, sys

CACHE = os.path.expanduser("~/.cache/quickshell-mine/clip")

def run(args, data=None):
    return subprocess.run(args, input=data, capture_output=True, timeout=5)

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    if cmd == "delete":
        run(["cliphist", "delete"], (sys.argv[2] + "\n").encode())
        print("[]"); return
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 300
    try:
        lines = run(["cliphist", "list"]).stdout.decode("utf-8", "replace").split("\n")
    except Exception:
        print("[]"); return
    os.makedirs(CACHE, exist_ok=True)
    out, imgs = [], 0
    for line in lines:
        if not line.strip():
            continue
        cid, _, text = line.partition("\t")
        item = {"line": line, "text": text, "img": ""}
        m = re.match(r"\[\[ binary data .*?(png|jpeg|jpg|webp|bmp|gif)", text)
        if m and imgs < 40 and cid.isdigit():
            imgs += 1
            ext = "jpg" if m.group(1) == "jpeg" else m.group(1)
            path = os.path.join(CACHE, f"{cid}.{ext}")
            if not os.path.exists(path):
                try:
                    data = run(["cliphist", "decode"], (line + "\n").encode()).stdout
                    if data:
                        with open(path, "wb") as f:
                            f.write(data)
                except Exception:
                    pass
            if os.path.exists(path):
                item["img"] = path
        out.append(item)
        if len(out) >= limit:
            break
    print(json.dumps(out, ensure_ascii=False))

main()
