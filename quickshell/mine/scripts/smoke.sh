#!/usr/bin/env bash
# Teste rapido do shell: reinicia pelo Hyprland (mantem o ambiente da sessao), espera subir, abre e fecha cada painel e
# cada pagina das configuracoes e procura erros de QML no log. Sai com 1 se o shell caiu ou apareceu erro novo.
# Uso: scripts/smoke.sh [--no-restart] [--keep-open]
set -u
QS="qs -c mine"
ipc() { $QS ipc call "$@" 2>&1; }
restart=1
for a in "$@"; do [ "$a" = "--no-restart" ] && restart=0; done

if [ $restart = 1 ]; then
    hyprctl dispatch 'hl.dsp.exec_cmd("shell-switch restart")' >/dev/null
    sleep 2
fi
for _ in $(seq 1 40); do ipc panels status >/dev/null 2>&1 && break; sleep 0.25; done
if ! ipc panels status >/dev/null 2>&1; then echo "FALHOU: o shell nao respondeu"; exit 1; fi
start=$(date +%s)

step() { printf '  %-28s' "$1"; shift; "$@" >/dev/null 2>&1; sleep "${PAUSE:-0.7}"; if ipc panels status >/dev/null 2>&1; then echo ok; else echo "CAIU"; exit 1; fi; }

echo "paineis:"
step "launcher" ipc launcher toggle;      step "launcher (fechar)" ipc panels closeall
step "inicio" ipc home toggle;            step "inicio (fechar)" ipc panels closeall
step "seletor de wallpaper" ipc wallpaper pick; step "seletor (fechar)" ipc panels closeall
step "visao geral" ipc overview open;     step "visao geral (fechar)" ipc overview close
step "osd" ipc osd preview
step "menu de energia" ipc session menu;  step "menu (fechar)" ipc panels closeall
echo "configuracoes:"
for p in $(ipc settings pages); do step "$p" ipc settings go "$p"; done
ipc settings close >/dev/null

# erros de QML desde o inicio do teste (os avisos conhecidos do Qt/Wayland ficam de fora)
errs=$($QS log 2>/dev/null | grep -E "TypeError|ReferenceError|SyntaxError|is not a type|is not defined|Cannot assign|failed to load|Binding loop|Unable to assign" | sort | uniq -c | sort -rn)
if [ -n "$errs" ]; then echo; echo "erros no log:"; echo "$errs" | sed 's/\x1b\[[0-9;]*m//g' | head -30; exit 1; fi
echo; echo "tudo certo ($(( $(date +%s) - start )) s)"
