#!/usr/bin/env bash
# Instala o Quickshell "mine" (moldura + barras + paineis) e a integracao com o Hyprland. Pronto para usar na hora.
#   ./install.sh                 instala tudo: dependencias, shell, atalhos, e inicia o shell agora (sem reiniciar)
#   ./install.sh --uninstall     desfaz o que o instalador fez (pede confirmacao; guarda um backup do shell)
#   ./install.sh --dry-run       mostra o que faria, sem alterar nada
#   ./install.sh --keys          so refaz a escolha dos atalhos (conflitos com os seus) e recarrega o Hyprland
# Atalhos que ja existem no seu Hyprland (conflitos):
#   --replace-keys               o atalho do shell vence (o seu da mesma combinacao e removido)
#   --keep-keys                  o seu vence (o atalho do shell nao e criado)
#   sem nenhum dos dois          pergunta: substituir todos, manter os seus ou decidir um a um
# Programas que brigam com o shell (waybar, mako, dunst, hyprpaper...):
#   --stop-programs              para os que estiverem rodando e desliga o autostart deles (sem perguntar)
#   --keep-programs              nao mexe nesses programas (nem pergunta)
# Outras opcoes:
#   --no-deps       nao instala dependencias (nem o ambiente Python do tema)
#   --minimal       so as dependencias essenciais (sem OCR, tradutor, luz noturna...)
#   --no-autostart  nao inicia o shell no login (so os atalhos)
#   --no-start      nao inicia o shell agora
#   --reset         sobrescreve o seu settings.json com o padrao deste repositorio
#   --yes           responde as perguntas com a resposta padrao (a opcao em maiuscula), sem esperar
#   -h, --help      esta ajuda
# Faz backup (uma vez, como *.mine-orig) de cada arquivo seu que editar; o --uninstall restaura.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$HERE/scripts/mine_install.py"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
QS_DIR="$CONF/quickshell/mine"
HYPR_DIR="$CONF/hypr"
KEYS_FILE="$HYPR_DIR/quickshell-keys.lua"
BIN_DIR="$HOME/.local/bin"
VENV="$HOME/.local/share/quickshell-mine/venv"
STAMP="$(date +%Y%m%d-%H%M%S)"
ORIG=".mine-orig"

DEPS=1; OPTIONAL_DEPS=1; AUTOSTART=1; RESET=0; DRY=0; UNINSTALL=0; ONLY_KEYS=0; START=1; ASSUME_YES=0
KEYMODE=""; PROGMODE=""; DRYF=()
for a in "$@"; do
    case "$a" in
        --no-deps) DEPS=0 ;;
        --minimal) OPTIONAL_DEPS=0 ;;
        --no-autostart) AUTOSTART=0 ;;
        --no-start) START=0 ;;
        --reset) RESET=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --dry-run) DRY=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --keys) ONLY_KEYS=1 ;;
        --replace-keys) KEYMODE=replace ;;
        --keep-keys) KEYMODE=keep ;;
        --stop-programs) PROGMODE=stop ;;
        --keep-programs) PROGMODE=keep ;;
        -h|--help) awk 'NR>1 && /^#/{sub(/^# ?/,""); print; next} NR>1{exit}' "$0"; exit 0 ;;
        *) echo "opcao desconhecida: $a (veja --help)"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------- utilidades
say()  { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
note() { printf '    %s\n' "$*"; }
# executa o comando (ou so mostra, no --dry-run)
run() { if [ "$DRY" = 1 ]; then printf '    [dry-run] %s\n' "$*"; else "$@"; fi; }
# pergunta s/n; --yes usa a resposta padrao; sem entrada (EOF) tambem usa o padrao
ask() {
    local q="$1" d="${2:-n}" a hint="[s/N]"
    [ "$d" = s ] && hint="[S/n]"
    if [ "$ASSUME_YES" = 1 ]; then [ "$d" = s ]; return; fi
    printf '    %s %s ' "$q" "$hint" >&2
    read -r a || { a=""; echo >&2; }
    [ -z "$a" ] && a="$d"
    [[ "$a" =~ ^([sSyY]|[sS][iI][mM]|[yY][eE][sS])$ ]]
}
# le uma letra entre as permitidas (padrao se vazio)
choose() { # pergunta "letras" padrao
    local q="$1" ok="$2" d="$3" a
    if [ "$ASSUME_YES" = 1 ]; then echo "$d"; return; fi
    while :; do
        printf '    %s [%s] ' "$q" "$ok" >&2
        read -r a || { a=""; echo >&2; }
        a="${a:-$d}"; a="${a,,}"
        [[ "$ok" == *"$a"* && ${#a} -eq 1 ]] && { echo "$a"; return; }
        [ "$ASSUME_YES" = 1 ] && { echo "$d"; return; }
    done
}
hypr_up() { command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; }
shell_up() { command -v qs >/dev/null 2>&1 && timeout 3 qs -c mine ipc call settings pages >/dev/null 2>&1; }
ver_lt() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; }
backup_once() { [ -e "$1$ORIG" ] || run cp -a "$1" "$1$ORIG"; }
# copia $1 para $2; se o destino existe e e diferente, guarda o original uma vez (*.mine-orig)
put_file() { # origem destino modo
    if [ -e "$2" ] && cmp -s "$1" "$2"; then return 0; fi
    [ -e "$2" ] && backup_once "$2"
    run install -D -m "${3:-644}" "$1" "$2"
}
append_block() { # arquivo texto  (so se o arquivo ja nao tem o marcador $3)
    if [ "$DRY" = 1 ]; then printf '    [dry-run] adicionaria ao fim de %s: %s\n' "$1" "$(printf '%s' "$2" | tr '\n' '|')"; else printf '%s' "$2" >> "$1"; fi
}
xdg_dir() { # NOME padrao -> caminho absoluto (XDG, ou HOME/padrao)
    local d=""
    d="$(xdg-user-dir "$1" 2>/dev/null || true)"
    if [ -z "$d" ] && [ -f "$CONF/user-dirs.dirs" ]; then
        d="$(sed -n "s/^XDG_$1_DIR=\"\(.*\)\"/\1/p" "$CONF/user-dirs.dirs" | head -1 | sed "s|\$HOME|$HOME|")"
    fi
    { [ -z "$d" ] || [ "$d" = "$HOME" ]; } && d="$HOME/$2"
    printf '%s' "$d"
}
tilde() { local p="$1"; [ "${p#"$HOME"/}" != "$p" ] && p="~/${p#"$HOME"/}"; printf '%s' "$p"; }

NEED_RELOGIN=()          # coisas que so funcionam depois de logout/login
STOP_NOW=()              # programas que o usuario aceitou parar agora
NOTES=()                 # avisos para o resumo final

# ================================================================ desinstalar
[ "$DRY" = 1 ] && DRYF=(--dry)
if [ "$UNINSTALL" = 1 ]; then
    say "Desinstalar o Quickshell \"mine\""
    [ "$DRY" = 1 ] && say "(--dry-run: nada sera alterado)"
    note "Vou: parar o shell, restaurar os seus arquivos do Hyprland/kitty/GTK que editei, tirar os scripts do ~/.local/bin"
    note "e mover $QS_DIR para um backup. Dependencias instaladas e servicos ligados NAO sao desfeitos."
    [ "$ASSUME_YES" = 1 ] || ask "Continuar?" n || { say "Nada foi feito."; exit 0; }

    if shell_up || pgrep -f "qs -c mine" >/dev/null 2>&1; then
        say "Parando o shell"; run qs kill -c mine >/dev/null 2>&1 || run pkill -f "qs -c mine" || true
    fi
    if [ -d "$HYPR_DIR" ]; then
        say "Restaurando a config do Hyprland em $HYPR_DIR"
        python3 "$HELPER" restore-marks --hypr "$HYPR_DIR" "${DRYF[@]}"
        python3 "$HELPER" remove-block --file "$HYPR_DIR/hyprland.lua" --comment '^-- Quickshell \(' --payload 'pcall\(require, "quickshell"\)' "${DRYF[@]}"
        if [ -e "$HYPR_DIR/hyprland.lua$ORIG" ] && ! grep -q 'require, "quickshell"' "$HYPR_DIR/hyprland.lua" 2>/dev/null; then
            [ "$DRY" = 1 ] || rm -f "$HYPR_DIR/hyprland.lua$ORIG"
        fi
        for f in quickshell.lua; do
            if [ -e "$HYPR_DIR/$f$ORIG" ]; then run mv -f "$HYPR_DIR/$f$ORIG" "$HYPR_DIR/$f"; else run rm -f "$HYPR_DIR/$f"; fi
        done
        run rm -f "$HYPR_DIR/quickshell-keys.lua" "$HYPR_DIR/quickshell-blur.lua"
        hypr_up && run hyprctl reload >/dev/null 2>&1 || true
    fi
    for f in "$BIN_DIR/qs-close-or-kill" "$BIN_DIR/session-action" "$BIN_DIR/mine-shell"; do
        if [ -e "$f$ORIG" ]; then run mv -f "$f$ORIG" "$f"; else run rm -f "$f"; fi
    done
    KC="$CONF/kitty/kitty.conf"
    if [ -f "$KC" ]; then
        python3 "$HELPER" remove-block --file "$KC" --comment 'Tema do wallpaper gerado pelo Quickshell' --payload 'include themes/quickshell\.conf' "${DRYF[@]}"
        [ "$DRY" = 1 ] || { rm -f "$CONF/kitty/themes/quickshell.conf" "$KC$ORIG"; rmdir "$CONF/kitty/themes" 2>/dev/null || true; }
    fi
    for v in 3.0 4.0; do
        G="$CONF/gtk-$v/gtk.css"
        if [ -f "$G" ]; then
            python3 "$HELPER" remove-block --file "$G" --comment 'tema do wallpaper do Quickshell' --payload '@import url\("quickshell\.css"\);' "${DRYF[@]}"
            [ "$DRY" = 1 ] || rm -f "$CONF/gtk-$v/quickshell.css" "$G$ORIG"
        fi
    done
    if [ -d "$QS_DIR" ]; then
        WPD="$(python3 -c "import json,os,sys;print(os.path.expanduser(json.load(open(sys.argv[1])).get('wpDir','')))" "$QS_DIR/settings.json" 2>/dev/null || true)"
        if [ "$ASSUME_YES" = 1 ] || ask "Remover $QS_DIR (guardo tudo em ${QS_DIR}.removed-$STAMP, com o seu settings.json)?" n; then
            run mv "$QS_DIR" "${QS_DIR}.removed-$STAMP"; say "Backup em ${QS_DIR}.removed-$STAMP"
            [ -n "$WPD" ] && [ "$DRY" = 0 ] && rmdir "$WPD" 2>/dev/null || true   # so some se estiver vazia (foi criada pelo instalador)
        else say "Mantive $QS_DIR"; fi
    fi
    if [ -d "$VENV" ] && ask "Remover o ambiente Python do tema ($VENV)?" n; then run rm -rf "$VENV"; run rmdir "$(dirname "$VENV")" 2>/dev/null || true; fi
    say "Pronto. Se o instalador desligou o autostart de waybar, mako etc., eles voltaram para o seu hyprland (reinicie-os se quiser)."
    exit 0
fi

[ "$DRY" = 1 ] && DRYF=(--dry)
[ "$DRY" = 1 ] && say "--dry-run: mostrando o que seria feito (nada sera alterado)"

# ================================================================ so os atalhos (--keys) usa as mesmas funcoes abaixo
step_keys() {
    [ -f "$HYPR_DIR/hyprland.lua" ] || return 0
    local tmp tsv ids n mode id combo desc ex wh shown
    tmp="$(mktemp)"; tsv="$(mktemp)"
    local extra=()
    if hypr_up && hyprctl binds -j >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        [ -n "$KEYMODE" ] && extra+=(--static --ignore-decided)
    else
        : >"$tmp"; note "Hyprland nao esta rodando: procuro os atalhos escritos nos arquivos de $HYPR_DIR."
    fi
    python3 "$HELPER" keys-conflicts --lua "$HERE/hypr/quickshell.lua" --binds "$tmp" --keys "$KEYS_FILE" --hypr "$HYPR_DIR" --tsv "${extra[@]}" >"$tsv" || true
    rm -f "$tmp"
    n="$(cut -f1 "$tsv" | sort -u | wc -l)"
    if [ "$n" -eq 0 ]; then
        say "Atalhos: nenhum conflito com os seus"
        [ -f "$KEYS_FILE" ] || python3 "$HELPER" keys-write --keys "$KEYS_FILE" "${DRYF[@]}"
        rm -f "$tsv"; return 0
    fi
    say "Atalhos do shell que ja existem no seu Hyprland ($n):"
    while IFS=$'\t' read -r id combo desc ex wh; do
        printf '      %-22s shell: %-38s seu: %s%s\n' "$combo" "$desc" "$ex" "${wh:+ ($wh)}"
    done <"$tsv"
    mode="$KEYMODE"
    if [ -z "$mode" ]; then
        case "$(choose "Substituir todos (o do shell vence), manter os seus, ou decidir um a um?" "tmu" "m")" in
            t) mode=replace ;; m) mode=keep ;; u) mode=each ;;
        esac
    fi
    local sets=() seen=" "
    while IFS=$'\t' read -r -u3 id combo desc ex wh; do
        case "$seen" in *" $id "*) continue ;; esac
        seen="$seen$id "
        if [ "$mode" = each ]; then
            printf '    %s (%s)\n' "$combo" "$desc" >&2
            case "$(choose "  [s] shell vence / [m] manter o meu" "sm" "m")" in s) sets+=(--set "$id=replace") ;; *) sets+=(--set "$id=keep") ;; esac
        else sets+=(--set "$id=$mode"); fi
    done 3<"$tsv"
    rm -f "$tsv"
    python3 "$HELPER" keys-write --keys "$KEYS_FILE" "${sets[@]}" "${DRYF[@]}"
    say "Escolha salva em $KEYS_FILE (edite la, ou rode ./install.sh --keys)"
}

if [ "$ONLY_KEYS" = 1 ]; then
    [ -f "$HYPR_DIR/quickshell.lua" ] || { warn "Instale primeiro (./install.sh): nao achei $HYPR_DIR/quickshell.lua"; exit 1; }
    step_keys
    hypr_up && { run hyprctl reload >/dev/null 2>&1 || true; say "Hyprland recarregado: atalhos valendo"; }
    exit 0
fi

# ================================================================ versoes
if command -v qs >/dev/null 2>&1; then
    qv="$(qs --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
    if [ -z "$qv" ]; then say "Quickshell encontrado (versao desconhecida)"
    elif ver_lt "$qv" "0.3.0"; then warn "Quickshell $qv e antigo: este shell foi feito na 0.3.2 e pode nao abrir. Atualize (quickshell ou quickshell-git no AUR)."
    elif [ "$qv" = "0.3.2" ]; then say "Quickshell $qv (a versao testada)"
    else say "Quickshell $qv (testado na 0.3.2; deve funcionar)"; fi
fi
HV=""
if command -v hyprctl >/dev/null 2>&1; then
    HV="$(hyprctl version -j 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("tag",""))' 2>/dev/null || true)"
    HV="${HV#v}"
    if [ -z "$HV" ]; then say "Hyprland instalado (versao so aparece com ele rodando)"
    elif ver_lt "$HV" "0.55.0"; then warn "Hyprland $HV: este shell usa a configuracao em Lua (testado na 0.56). Atualize o Hyprland."
    elif ver_lt "$HV" "0.56.0"; then warn "Hyprland $HV: testado na 0.56; a API Lua pode ter diferencas (o hl.unbind dos atalhos precisa dela)."
    else say "Hyprland $HV (testado na 0.56)"; fi
fi

# ================================================================ dependencias (Arch: pacman, so as que faltam)
# essenciais: sem elas partes do shell nao abrem (icones, video, capturas, area de transferencia, tema, sons)
REQUIRED=(
    quickshell hyprland pipewire pipewire-audio wireplumber    # shell, compositor, audio (pw-play)
    qt6-multimedia qt6-multimedia-ffmpeg ffmpeg                # wallpaper em video e quadros dele
    python python-pillow                                       # scripts (posicao dos widgets, capturas, miniaturas)
    ttf-jetbrains-mono-nerd                                    # fonte dos icones da interface
    libnotify curl glib2 xdg-utils procps-ng                   # avisos, clima/letras, tema GTK, abrir arquivos
    wl-clipboard cliphist grim slurp hyprpicker                # area de transferencia, capturas, conta-gotas
    pacman-contrib sound-theme-freedesktop                     # aviso de atualizacoes (checkupdates), sons
)
# extras: cada um liga um recurso (o shell funciona sem eles e avisa o que falta)
OPTIONAL=(
    cava                                                       # visualizador de musica (widget e ilha)
    hyprsunset                                                 # luz noturna
    tesseract tesseract-data-por tesseract-data-eng            # copiar texto da tela (OCR)
    translate-shell                                            # tradutor (launcher "!" e traduzir a tela)
    satty                                                      # anotar capturas
    wf-recorder                                                # gravar a tela
    easyeffects                                                # equalizador
    power-profiles-daemon                                      # perfis de energia
    gnome-keyring                                              # destravar o chaveiro junto com a tela de bloqueio
    networkmanager bluez bluez-utils                           # paginas de Wi-Fi e Bluetooth
    kitty                                                      # terminal padrao do launcher (tema ao vivo)
    libqalculate                                               # calculadora do launcher (unidades, moedas)
    zenity                                                     # importar VPN e escolher arquivos
    expac flatpak                                              # pagina Aplicativos: tamanhos mais rapidos (expac) e busca/instalacao no Flathub (flatpak); funciona sem eles
    brightnessctl upower                                       # brilho e bateria (notebooks)
    ddcutil                                                    # pagina Monitores: brilho de monitor externo (precisa do modulo i2c-dev); funciona sem ele
    pciutils                                                   # GPU na pagina Sobre
    ydotool                                                    # teclado na tela digitar (systemctl --user enable --now ydotool)
    mangohud                                                   # limitador de FPS do overlay de jogo
    imagemagick                                                # icones dos webapps (.ico)
)
FONT_NEW=0
if [ "$DEPS" = 1 ]; then
    want=(); cand=("${REQUIRED[@]}")
    if [ "$OPTIONAL_DEPS" = 1 ]; then cand+=("${OPTIONAL[@]}"); fi
    for p in "${cand[@]}"; do
        # quickshell e hyprland podem vir de pacotes -git/AUR: se o comando ja existe, nao pede o pacote
        case "$p" in quickshell) command -v qs >/dev/null 2>&1 && continue ;; hyprland) command -v hyprctl >/dev/null 2>&1 && continue ;; esac
        want+=("$p")
    done
    if command -v pacman >/dev/null 2>&1; then
        missing=(); mapfile -t missing < <(pacman -T "${want[@]}" 2>/dev/null || true)
        if [ "${#missing[@]}" -gt 0 ]; then
            official=(); aur=()
            for p in "${missing[@]}"; do if pacman -Si "$p" >/dev/null 2>&1; then official+=("$p"); else aur+=("$p"); fi; done
            [[ " ${missing[*]} " == *" ttf-jetbrains-mono-nerd "* ]] && FONT_NEW=1
            say "Faltam ${#missing[@]} pacotes: ${missing[*]}"
            if [ "${#official[@]}" -gt 0 ]; then
                say "Instalando com pacman (pede a sua senha do sudo): ${official[*]}"
                run sudo pacman -S --needed "${official[@]}" || warn "O pacman nao terminou; o shell abre, mas pode faltar recurso."
            fi
            if [ "${#aur[@]}" -gt 0 ]; then
                helper="$(command -v paru || command -v yay || true)"
                if [ -n "$helper" ]; then
                    say "So no AUR: ${aur[*]}"
                    if ask "Instalar com $(basename "$helper")?" s; then run "$helper" -S --needed "${aur[@]}" || warn "O $(basename "$helper") nao terminou."; fi
                else
                    warn "Nao achei no pacman e voce nao tem paru/yay: ${aur[*]}. Instale do AUR (ex.: git clone https://aur.archlinux.org/<pacote>.git && makepkg -si)."
                fi
            fi
        else
            say "Dependencias ja instaladas"
        fi
    else
        echo "Sem pacman: instale manualmente (nomes do Arch, procure o equivalente na sua distribuicao):"
        echo "  essenciais: ${REQUIRED[*]}"
        echo "  extras:     ${OPTIONAL[*]}"
    fi
fi
if ! command -v qs >/dev/null 2>&1 || ! command -v hyprctl >/dev/null 2>&1; then
    warn "Faltam o Quickshell (comando qs) e/ou o Hyprland (hyprctl). Instale (quickshell ou quickshell-git, hyprland) e rode de novo."
    [ "$DRY" = 1 ] || exit 1
fi
if [ "$DEPS" = 1 ] && command -v fc-list >/dev/null 2>&1 && ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd\|JetBrainsMono NF"; then
    if [ "$FONT_NEW" = 1 ] || command -v fc-cache >/dev/null 2>&1; then run fc-cache -f >/dev/null 2>&1 || true; fi
    fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd\|JetBrainsMono NF" || warn "Fonte JetBrainsMono Nerd Font nao encontrada: os icones aparecem como quadrados. Instale ttf-jetbrains-mono-nerd."
elif [ "$FONT_NEW" = 1 ]; then run fc-cache -f >/dev/null 2>&1 || true; fi

# ================================================================ Quickshell
say "Instalando o Quickshell em $QS_DIR"
run mkdir -p "$QS_DIR"
if [ -n "$(ls -A "$QS_DIR" 2>/dev/null)" ] && diff -rq "$HERE/quickshell/mine" "$QS_DIR" 2>/dev/null | grep -qF -e "Only in $HERE/quickshell/mine" -e "Files "; then
    run cp -a "$QS_DIR" "$QS_DIR.backup-$STAMP"
    say "Backup do anterior em $QS_DIR.backup-$STAMP"
fi
run cp -a "$HERE"/quickshell/mine/. "$QS_DIR"/
if [ "$RESET" = 1 ] || [ ! -f "$QS_DIR/settings.json" ]; then
    # pastas do usuario (XDG): a Imagens/Videos do portugues ou Pictures/Videos do ingles
    PICS="$(tilde "$(xdg_dir PICTURES Pictures)")"; VIDS="$(tilde "$(xdg_dir VIDEOS Videos)")"
    if [ "$DRY" = 1 ]; then note "[dry-run] settings.json padrao (wallpapers em $PICS/Wallpapers, capturas em $PICS/Screenshots, gravacoes em $VIDS/Recordings)"
    else
        python3 - "$HERE/quickshell/settings.default.json" "$QS_DIR/settings.json" "$PICS" "$VIDS" <<'PY'
import json, sys
src, dst, pics, vids = sys.argv[1:5]
d = json.load(open(src, encoding="utf-8"))
d["wpDir"] = pics + "/Wallpapers"; d["shotDir"] = pics + "/Screenshots"; d["recDir"] = vids + "/Recordings"
json.dump(d, open(dst, "w", encoding="utf-8"), indent=2, ensure_ascii=False); open(dst, "a").write("\n")
PY
        say "settings.json padrao instalado"
    fi
else
    say "Mantendo o seu settings.json (use --reset para trocar pelo padrao)"
fi

# ---- tema do wallpaper (Material You): venv do Python com a biblioteca materialyoucolor ----
if [ "$DEPS" = 1 ] && [ ! -x "$VENV/bin/python" ]; then
    say "Criando o ambiente Python do tema (materialyoucolor) em $VENV"
    if [ "$DRY" = 1 ]; then note "[dry-run] python3 -m venv $VENV && pip install materialyoucolor"
    elif python3 -m venv "$VENV" && "$VENV/bin/pip" install -q materialyoucolor; then say "Tema Material You pronto"
    else say "Nao consegui instalar o materialyoucolor: o tema do wallpaper usara o calculo simplificado."; fi
fi

# ---- scripts em ~/.local/bin (os atalhos chamam $HOME/.local/bin/...) ----
put_file "$HERE/bin/qs-close-or-kill" "$BIN_DIR/qs-close-or-kill" 755
put_file "$HERE/bin/session-action" "$BIN_DIR/session-action" 755
put_file "$HERE/bin/mine-shell" "$BIN_DIR/mine-shell" 755
say "Scripts instalados em $BIN_DIR (qs-close-or-kill: Super+Q; session-action: bloquear, menu de energia, midia; mine-shell: iniciar/reiniciar o shell)"

# ================================================================ Hyprland (config Lua)
if [ -f "$HYPR_DIR/hyprland.lua" ]; then
    say "Integrando ao Hyprland em $HYPR_DIR"
    put_file "$HERE/hypr/quickshell.lua" "$HYPR_DIR/quickshell.lua"
    if [ "$AUTOSTART" = 0 ]; then run sed -i 's/^local AUTOSTART = true/local AUTOSTART = false/' "$HYPR_DIR/quickshell.lua"; fi
    if ! grep -q 'require, "quickshell"' "$HYPR_DIR/hyprland.lua"; then
        backup_once "$HYPR_DIR/hyprland.lua"
        append_block "$HYPR_DIR/hyprland.lua" $'\n-- Quickshell (moldura, barras e seletor de wallpaper)\npcall(require, "quickshell")\n'
        say "Linha 'require quickshell' adicionada ao fim do hyprland.lua (depois dos seus atalhos, de proposito)"
    fi
    step_keys

    # ---- programas que brigam com o shell ----
    if [ "$PROGMODE" != keep ]; then
        pj="$(mktemp)"
        python3 "$HELPER" progs-scan --hypr "$HYPR_DIR" --settings "$QS_DIR/settings.json" >"$pj" 2>/dev/null || echo '[]' >"$pj"
        pn="$(python3 -c 'import json,sys;print(len(json.load(open(sys.argv[1]))))' "$pj")"
        if [ "$pn" -gt 0 ]; then
            say "Programas que fazem o mesmo que o shell (e brigam com ele):"
            python3 - "$pj" "$HYPR_DIR" <<'PY'
import json, os, sys
for p in json.load(open(sys.argv[1])):
    st = []
    if p["running"]: st.append("rodando agora")
    for l in p["lines"]: st.append(f'autostart em {os.path.relpath(l["file"], sys.argv[2])}:{l["line"]}')
    print(f'      {p["name"]:<18} ({p["kind"]}): ' + "; ".join(st))
PY
            names="$(python3 -c 'import json,sys;print(",".join(p["name"] for p in json.load(open(sys.argv[1]))))' "$pj")"
            if [ "$PROGMODE" = stop ] || ask "Parar agora e desligar o autostart deles (comenta as linhas; --uninstall restaura)?" n; then
                python3 "$HELPER" progs-disable --hypr "$HYPR_DIR" --names "$names" "${DRYF[@]}" | sed 's/^/      /'
                mapfile -t STOP_NOW < <(python3 -c 'import json,sys;print("\n".join(p["name"] for p in json.load(open(sys.argv[1])) if p["running"]))' "$pj")
            else
                NOTES+=("Programas que ficaram: $names (podem sobrepor o shell; rode ./install.sh --stop-programs para tratar)")
            fi
        fi
        rm -f "$pj"
    fi
elif [ -f "$HYPR_DIR/hyprland.conf" ]; then
    warn "Achei $HYPR_DIR/hyprland.conf (formato hyprlang), mas este shell integra pela configuracao em Lua do Hyprland 0.56."
    note "Copie hypr/quickshell.lua para $HYPR_DIR/, ou use no hyprland.conf:  exec-once = qs -c mine  e os binds da tabela em hypr/quickshell.lua."
    put_file "$HERE/hypr/quickshell.lua" "$HYPR_DIR/quickshell.lua"
else
    warn "Nao achei $HYPR_DIR/hyprland.lua: pulei a integracao com o Hyprland (inicie o Hyprland uma vez para ele criar a config e rode de novo)."
fi

# ---- kitty (tema do wallpaper): inclui o arquivo gerado pelo shell ----
KITTY_CONF="$CONF/kitty/kitty.conf"
if [ -f "$KITTY_CONF" ] && ! grep -q 'themes/quickshell.conf' "$KITTY_CONF"; then
    backup_once "$KITTY_CONF"
    run mkdir -p "$CONF/kitty/themes"; [ "$DRY" = 1 ] || : > "$CONF/kitty/themes/quickshell.conf"
    append_block "$KITTY_CONF" $'\n# Tema do wallpaper gerado pelo Quickshell\ninclude themes/quickshell.conf\n'
    say "kitty: linha 'include themes/quickshell.conf' adicionada ao kitty.conf"
fi
# ---- GTK (tema do wallpaper): o gtk.css importa o arquivo gerado pelo shell ----
for v in 3.0 4.0; do
    G="$CONF/gtk-$v/gtk.css"
    if [ -f "$G" ] && ! grep -q 'quickshell.css' "$G"; then
        backup_once "$G"; [ "$DRY" = 1 ] || : > "$CONF/gtk-$v/quickshell.css"
        append_block "$G" $'\n/* tema do wallpaper do Quickshell */\n@import url("quickshell.css");\n'
        say "GTK $v: import adicionado ao gtk.css"
    fi
done

# ---- Brave: o shell escreve a cor do tema na politica gerenciada (precisa existir e ser gravavel) ----
BP=/etc/brave/policies/managed/caelestia.json
if command -v brave >/dev/null 2>&1 && [ ! -w "$BP" ]; then
    NOTES+=("Brave (opcional): para o tema ao vivo rode uma vez: sudo mkdir -p /etc/brave/policies/managed && sudo touch $BP && sudo chown \$USER $BP")
fi

# ---- pastas de wallpapers e capturas ----
WPDIR="$(python3 -c "import json,os,sys;print(os.path.expanduser(json.load(open(sys.argv[1])).get('wpDir','')))" "$QS_DIR/settings.json" 2>/dev/null || true)"
[ -n "$WPDIR" ] || WPDIR="$(xdg_dir PICTURES Pictures)/Wallpapers"
run mkdir -p "$WPDIR"
say "Pasta de wallpapers: $WPDIR (ponha as suas imagens la, ou mude em Configuracoes > Wallpaper)"

# ================================================================ servicos e grupos que os extras precisam
unit_exists() { systemctl "${2:---system}" cat "$1" >/dev/null 2>&1; }
if command -v systemctl >/dev/null 2>&1; then
    if command -v ydotool >/dev/null 2>&1; then
        if unit_exists ydotool.service --user && ! systemctl --user is-active --quiet ydotool.service 2>/dev/null; then
            ask "Ligar o servico do ydotool (teclado na tela digitar nos apps)?" s && run systemctl --user enable --now ydotool.service || true
        fi
        if ! id -nG | tr ' ' '\n' | grep -qx input; then
            if ask "O ydotool precisa que voce esteja no grupo 'input'. Adicionar ($USER) com sudo?" n; then
                run sudo usermod -aG input "${USER:-$(id -un)}" && NEED_RELOGIN+=("o teclado na tela digitar em outros apps (grupo input)")
            else NOTES+=("Sem o grupo 'input' o ydotool pode nao digitar: sudo usermod -aG input \$USER e depois logout/login"); fi
        fi
    fi
    for svc in NetworkManager bluetooth power-profiles-daemon; do
        if unit_exists "$svc.service" && ! systemctl is-active --quiet "$svc.service" 2>/dev/null; then
            case "$svc" in NetworkManager) what="Wi-Fi e rede" ;; bluetooth) what="Bluetooth" ;; *) what="perfis de energia" ;; esac
            ask "O servico $svc ($what) esta parado. Ligar agora e no boot (sudo)?" n && run sudo systemctl enable --now "$svc.service" || true
        fi
    done
fi

# ================================================================ iniciar agora
started=0
if [ "$START" = 1 ] && hypr_up; then
    say "Recarregando o Hyprland (atalhos novos valem agora)"
    run hyprctl reload >/dev/null 2>&1 || true
    for n in "${STOP_NOW[@]}"; do
        [ -n "$n" ] || continue
        say "Parando $n"; run pkill -x "$n" || true
    done
    if [ "$DRY" = 0 ] && shell_up; then
        say "O shell ja estava rodando: reiniciando para carregar a versao nova"
        qs kill -c mine >/dev/null 2>&1 || pkill -f "qs -c mine" || true; sleep 1
    fi
    say "Iniciando o shell"
    if [ "$DRY" = 1 ]; then note "[dry-run] hyprctl dispatch 'hl.dsp.exec_cmd(\"$BIN_DIR/mine-shell start\")' (inicia pelo Hyprland, com o ambiente certo)"
    else
        hyprctl dispatch "hl.dsp.exec_cmd(\"$BIN_DIR/mine-shell start\")" >/dev/null 2>&1 || setsid -f qs -c mine >/dev/null 2>&1
        for _ in $(seq 1 20); do shell_up && { started=1; break; }; sleep 1; done
        if [ "$started" = 1 ]; then say "O shell esta rodando"
        else warn "O shell nao respondeu em 20 s. Veja o erro com:  qs -c mine   (ou: qs log -c mine)"; fi
    fi
elif [ "$START" = 1 ]; then
    NOTES+=("O Hyprland nao esta rodando aqui: abra uma sessao dele; o shell inicia sozinho no login (ou rode: qs -c mine)")
fi

# ================================================================ resumo
echo
say "Resumo"
for n in "${NOTES[@]}"; do note "- $n"; done
if [ "${#NEED_RELOGIN[@]}" -gt 0 ]; then
    for n in "${NEED_RELOGIN[@]}"; do warn "faça logout/login para: $n"; done
    if [ "$DRY" = 0 ] && hypr_up && ask "Sair da sessao do Hyprland agora?" n; then hyprctl dispatch 'hl.dsp.exit()' >/dev/null 2>&1 || true; fi
fi
if [ "$started" = 1 ] || [ "$DRY" = 1 ]; then
    [ "${#NEED_RELOGIN[@]}" -eq 0 ] && say "Tudo pronto: pode usar agora, sem reiniciar."
    note "Super+C configuracoes, Super+W wallpaper, Super+Tab launcher, Super+V visuais, Print captura (todos em docs/ATALHOS.md)"
fi
