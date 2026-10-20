#!/usr/bin/env bash
# Instala o Quickshell "mine" (moldura + barras + seletor de wallpaper) e a integracao com o Hyprland.
#   ./install.sh                instala tudo (instala dependencias com pacman e cria o venv do tema)
#   ./install.sh --no-deps      nao tenta instalar dependencias
#   ./install.sh --minimal      instala so as dependencias essenciais (sem OCR, tradutor, luz noturna...)
#   ./install.sh --no-autostart nao inicia o shell no login (so os atalhos)
#   ./install.sh --reset        sobrescreve o seu settings.json com o padrao deste repositorio
# Faz backup do que ja existir em ~/.config/quickshell/mine e em ~/.config/hypr.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QS_DIR="$HOME/.config/quickshell/mine"
HYPR_DIR="$HOME/.config/hypr"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEPS=1; OPTIONAL_DEPS=1; AUTOSTART=1; RESET=0
for a in "$@"; do
    case "$a" in
        --no-deps) DEPS=0 ;;
        --minimal) OPTIONAL_DEPS=0 ;;
        --no-autostart) AUTOSTART=0 ;;
        --reset) RESET=1 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) echo "opcao desconhecida: $a"; exit 1 ;;
    esac
done

say() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }

# ---- dependencias (Arch: pacman, so as que faltam) ----
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
    brightnessctl upower                                       # brilho e bateria (notebooks)
    pciutils                                                   # GPU na pagina Sobre
    ydotool                                                    # teclado na tela digitar (systemctl --user enable --now ydotool)
    mangohud                                                   # limitador de FPS do overlay de jogo
    imagemagick                                                # icones dos webapps (.ico)
)
if [ "$DEPS" = 1 ]; then
    if command -v pacman >/dev/null; then
        want=("${REQUIRED[@]}"); [ "$OPTIONAL_DEPS" = 1 ] && want+=("${OPTIONAL[@]}")
        missing=()
        for p in "${want[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p"); done
        if [ "${#missing[@]}" -gt 0 ]; then
            say "Faltam ${#missing[@]} pacotes: ${missing[*]}"
            say "Instalando com pacman (pede a sua senha do sudo)"
            sudo pacman -S --needed "${missing[@]}"
        else
            say "Dependencias ja instaladas"
        fi
    else
        echo "Sem pacman: instale manualmente (nomes do Arch):"
        echo "  essenciais: ${REQUIRED[*]}"
        echo "  extras:     ${OPTIONAL[*]}"
        command -v qs >/dev/null && command -v hyprctl >/dev/null || exit 1
    fi
fi
# a configuracao do Hyprland em Lua: testado na 0.56
if command -v hyprctl >/dev/null; then
    hv="$(hyprctl version -j 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("tag",""))' 2>/dev/null || true)"
    case "$hv" in v0.[0-4]*|v0.5[0-5]*) say "Aviso: Hyprland $hv. Este shell usa a configuracao em Lua (testado na 0.56)." ;; esac
fi

# ---- Quickshell ----
say "Instalando o Quickshell em $QS_DIR"
mkdir -p "$QS_DIR"
if [ -n "$(ls -A "$QS_DIR" 2>/dev/null)" ]; then
    cp -a "$QS_DIR" "$QS_DIR.backup-$STAMP"
    say "Backup do anterior em $QS_DIR.backup-$STAMP"
fi
cp -a "$HERE"/quickshell/mine/. "$QS_DIR"/
if [ "$RESET" = 1 ] || [ ! -f "$QS_DIR/settings.json" ]; then
    cp "$HERE/quickshell/settings.default.json" "$QS_DIR/settings.json"
    say "settings.json padrao instalado"
else
    say "Mantendo o seu settings.json (use --reset para trocar pelo padrao)"
fi

# ---- tema do wallpaper (Material You): venv do Python com a biblioteca materialyoucolor ----
VENV="$HOME/.local/share/quickshell-mine/venv"
if [ ! -x "$VENV/bin/python" ]; then
    say "Criando o ambiente Python do tema (materialyoucolor) em $VENV"
    if python3 -m venv "$VENV" && "$VENV/bin/pip" install -q materialyoucolor; then
        say "Tema Material You pronto"
    else
        say "Nao consegui instalar o materialyoucolor: o tema do wallpaper usara o calculo simplificado."
    fi
fi

# ---- Hyprland (config Lua) ----
if [ -d "$HYPR_DIR" ] && [ -f "$HYPR_DIR/hyprland.lua" ]; then
    say "Integrando ao Hyprland em $HYPR_DIR"
    [ -f "$HYPR_DIR/quickshell.lua" ] && cp -a "$HYPR_DIR/quickshell.lua" "$HYPR_DIR/quickshell.lua.backup-$STAMP"
    cp "$HERE/hypr/quickshell.lua" "$HYPR_DIR/quickshell.lua"
    [ "$AUTOSTART" = 0 ] && sed -i 's/^local AUTOSTART = true/local AUTOSTART = false/' "$HYPR_DIR/quickshell.lua"
    if ! grep -q 'require, "quickshell"' "$HYPR_DIR/hyprland.lua"; then
        cp -a "$HYPR_DIR/hyprland.lua" "$HYPR_DIR/hyprland.lua.backup-$STAMP"
        printf '\n-- Quickshell (moldura, barras e seletor de wallpaper)\npcall(require, "quickshell")\n' >> "$HYPR_DIR/hyprland.lua"
        say "Linha 'require quickshell' adicionada ao hyprland.lua"
    fi
    hyprctl reload >/dev/null 2>&1 || true
else
    say "Nao achei $HYPR_DIR/hyprland.lua: pulei a integracao com o Hyprland."
    say "Copie hypr/quickshell.lua para a sua config e adicione: pcall(require, \"quickshell\")"
fi

# ---- kitty (tema do wallpaper): inclui o arquivo gerado pelo shell ----
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
if [ -f "$KITTY_CONF" ] && ! grep -q 'themes/quickshell.conf' "$KITTY_CONF"; then
    cp -a "$KITTY_CONF" "$KITTY_CONF.backup-$STAMP"
    mkdir -p "$HOME/.config/kitty/themes"; : > "$HOME/.config/kitty/themes/quickshell.conf"
    printf '\n# Tema do wallpaper gerado pelo Quickshell\ninclude themes/quickshell.conf\n' >> "$KITTY_CONF"
    say "kitty: linha 'include themes/quickshell.conf' adicionada ao kitty.conf"
fi

# ---- GTK (tema do wallpaper): o gtk.css importa o arquivo gerado pelo shell ----
for v in 3.0 4.0; do
    G="$HOME/.config/gtk-$v/gtk.css"
    if [ -f "$G" ] && ! grep -q 'quickshell.css' "$G"; then
        cp -a "$G" "$G.backup-$STAMP"; : > "$HOME/.config/gtk-$v/quickshell.css"
        printf '\n/* tema do wallpaper do Quickshell */\n@import url("quickshell.css");\n' >> "$G"
        say "GTK $v: import adicionado ao gtk.css"
    fi
done

# ---- Brave: o shell escreve a cor do tema na politica gerenciada (precisa existir e ser gravavel) ----
BP=/etc/brave/policies/managed/caelestia.json
if [ ! -w "$BP" ]; then
    say "Brave (opcional): para o tema ao vivo rode uma vez: sudo mkdir -p /etc/brave/policies/managed && sudo touch $BP && sudo chown \$USER $BP"
fi

# ---- script do Super+Q (fecha as janelas do Quickshell antes de fechar a janela ativa) ----
mkdir -p "$HOME/.local/bin"; install -m 755 "$HERE/bin/qs-close-or-kill" "$HOME/.local/bin/qs-close-or-kill"
say "Opcional: faca o seu atalho de fechar janela chamar ~/.local/bin/qs-close-or-kill"

# ---- wallpapers ----
WPDIR="$(python3 -c "import json,os;print(os.path.expanduser(json.load(open('$QS_DIR/settings.json')).get('wpDir','~/Imagens/Wallpapers')))" 2>/dev/null || echo "$HOME/Imagens/Wallpapers")"
mkdir -p "$WPDIR"
say "Pasta de wallpapers: $WPDIR (coloque as suas imagens la, ou mude em Configuracoes > Wallpaper)"

say "Pronto. Inicie com:  qs -c mine   (ou faca logout/login)"
say "Atalhos: Super+C configuracoes, Super+W wallpaper, Super+Tab launcher, Print captura, Super+G painel de jogo"
