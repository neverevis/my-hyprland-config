#!/usr/bin/env python3
# Uso do Claude Code lido so de arquivos locais (~/.claude/projects/*/*.jsonl): sem rede, sem chaves.
# Soma os tokens (entrada + saida + criacao de cache; leitura de cache nao conta) da janela de 5 h,
# do dia e da semana, diz quando a janela zera e quais sessoes estao ativas. Le so o que cresceu desde a ultima vez
# (cache em ~/.cache/quickshell-mine/claude-usage.json). Imprime um JSON.
import json, os, sys, time, glob
from datetime import datetime

HOME = os.path.expanduser("~")
ROOT = os.path.join(HOME, ".claude", "projects")
CACHE = os.path.join(HOME, ".cache", "quickshell-mine", "claude-usage.json")
now = time.time()
WEEK = 7 * 86400

def out(d):
    print(json.dumps(d))
    sys.exit(0)

if not os.path.isdir(ROOT):
    out({"ok": False, "reason": "sem ~/.claude/projects"})

try:
    cache = json.load(open(CACHE))
except Exception:
    cache = {}
files = {}
for p in glob.glob(os.path.join(ROOT, "*", "*.jsonl")):
    try:
        st = os.stat(p)
    except OSError:
        continue
    if now - st.st_mtime > WEEK:
        continue
    files[p] = st
newc = {}
for p, st in files.items():
    c = cache.get(p) or {"size": 0, "ev": [], "seen": []}
    if st.st_size < c["size"]:
        c = {"size": 0, "ev": [], "seen": []}
    if st.st_size > c["size"]:
        seen = set(c["seen"])
        try:
            with open(p, "rb") as f:
                f.seek(c["size"])
                data = f.read(st.st_size - c["size"])
            # so linhas completas
            cut = data.rfind(b"\n")
            if cut >= 0:
                chunk, used = data[:cut + 1], cut + 1
            else:
                chunk, used = b"", 0
            for ln in chunk.split(b"\n"):
                if b'"usage"' not in ln or b'"assistant"' not in ln:
                    continue
                try:
                    d = json.loads(ln)
                    m = d.get("message") or {}
                    u = m.get("usage")
                    if not u:
                        continue
                    mid = m.get("id") or d.get("uuid")
                    if mid in seen:
                        continue
                    seen.add(mid)
                    t = datetime.strptime(d["timestamp"].replace("Z", "+0000"), "%Y-%m-%dT%H:%M:%S.%f%z").timestamp()
                    tok = (u.get("input_tokens") or 0) + (u.get("output_tokens") or 0) + (u.get("cache_creation_input_tokens") or 0)
                    c["ev"].append([t, tok])
                except Exception:
                    continue
            c["size"] += used
            c["seen"] = list(seen)[-4000:]
        except OSError:
            pass
    c["ev"] = [e for e in c["ev"] if now - e[0] <= WEEK]
    newc[p] = c
try:
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    json.dump(newc, open(CACHE, "w"))
except OSError:
    pass

ev = [e for c in newc.values() for e in c["ev"]]
w5 = [e for e in ev if now - e[0] <= 5 * 3600]
day0 = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0).timestamp()
reset = (min(e[0] for e in w5) + 5 * 3600) if w5 else 0
sess = []
for p, st in files.items():
    age = now - st.st_mtime
    if age < 900:
        sess.append({"project": os.path.basename(os.path.dirname(p)).replace("-home-" + os.path.basename(HOME) + "-", "").replace("-", "/"),
                     "busy": age < 45, "age": int(age)})
sess.sort(key=lambda s: s["age"])
out({"ok": True, "tokens5h": sum(e[1] for e in w5), "tokensDay": sum(e[1] for e in ev if e[0] >= day0),
     "tokensWeek": sum(e[1] for e in ev), "reset": reset, "msgs5h": len(w5), "sessions": sess[:6]})
