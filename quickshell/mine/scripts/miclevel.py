#!/usr/bin/env python3
# Nivel do microfone ao vivo: le PCM s16 mono da entrada padrao (pw-cat) e imprime o pico 0-100 cerca de 12 vezes por segundo.
# Imprime so quando o valor muda; sai quando a entrada fecha.
import sys, struct, array
rate = 8000
chunk = rate // 12 * 2
last = -1
buf = sys.stdin.buffer
while True:
    d = buf.read(chunk)
    if not d:
        break
    d = d[: len(d) // 2 * 2]
    a = array.array("h"); a.frombytes(d)
    pk = max((abs(x) for x in a), default=0)
    v = min(100, int((pk / 32768.0) ** 0.5 * 25) * 4)   # raiz: sons baixos aparecem mais; passos de 4 (menos redesenho)
    if v != last:
        print(v, flush=True); last = v
