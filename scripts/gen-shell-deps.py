#!/usr/bin/env python3
# Gera quickshell/mine/data/shell-deps.json a partir dos arrays REQUIRED e OPTIONAL do install.sh (fonte da verdade).
# A janela Aplicativos usa o arquivo para proteger os pacotes de que o shell precisa. Rode apos mexer nas listas.
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIX = {"audio": "áudio", "area": "área", "transferencia": "transferência", "atualizacoes": "atualizações", "icones": "ícones", "interface": "interface",
       "posicao": "posição", "capturas": "capturas", "miniaturas": "miniaturas", "musica": "música", "luz noturna": "luz noturna", "paginas": "páginas",
       "pagina": "página", "padrao": "padrão", "calculadora": "calculadora", "importar": "importar", "gravar": "gravar", "equalizador": "equalizador",
       "videos": "vídeos", "video": "vídeo", "sons": "sons", "avisos": "avisos", "clima/letras": "clima/letras", "Aplicativos": "Aplicativos",
       "funciona sem eles": "funciona sem eles", "notebooks": "notebooks", "bloqueio": "bloqueio", "unidades": "unidades", "moedas": "moedas",
       "tradutor": "tradutor", "preciso": "preciso", "precisa": "precisa", "energia": "energia", "Monitores": "Monitores", "digitar": "digitar", "Wi-Fi": "Wi-Fi",
       "conta-gotas": "conta-gotas", "tema GTK": "tema GTK", "abrir arquivos": "abrir arquivos", "tamanhos mais rapidos": "tamanhos mais rápidos",
       "busca/instalacao": "busca/instalação", "limitador": "limitador", "posicao dos widgets": "posição dos widgets", "jogo": "jogo", "ilha": "ilha"}


def accents(t):
    for k in sorted(FIX, key=len, reverse=True):
        t = re.sub(r"\b" + re.escape(k) + r"\b", FIX[k], t)
    return t


def arr(src, name):
    m = re.search(name + r"=\(\n(.*?)\n\)", src, re.S)
    res = []
    for l in m.group(1).split("\n"):
        pk, _, why = l.partition("#")
        for p in pk.split():
            res.append({"pkg": p, "why": accents(why.strip())})
    return res


OVER = {"quickshell": "o próprio shell", "hyprland": "o compositor (janelas e atalhos)", "pipewire": "áudio", "pipewire-audio": "áudio", "wireplumber": "áudio"}
src = open(ROOT + "/install.sh").read()
out, seen = [], set()
for lvl, name in (("required", "REQUIRED"), ("optional", "OPTIONAL")):
    for e in arr(src, name):
        out.append({"pkg": e["pkg"], "level": lvl, "why": OVER.get(e["pkg"], e["why"])})
        seen.add(e["pkg"])
extra = [("polkit", "pedir a senha em ações de administrador"), ("python", "scripts do shell")]
for p, w in extra:
    if p not in seen:
        out.append({"pkg": p, "level": "required", "why": w})
dst = ROOT + "/quickshell/mine/data/shell-deps.json"
os.makedirs(os.path.dirname(dst), exist_ok=True)
json.dump(out, open(dst, "w"), ensure_ascii=False, indent=1)
print(len(out), "pacotes ->", dst)
