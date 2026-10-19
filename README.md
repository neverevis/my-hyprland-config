# my-hyprland-config

Meu shell em **Quickshell** para o **Hyprland**: uma moldura fina na tela com barras que "sobem" da borda, tudo configurável por uma janela de configurações (sem editar código).

## O que tem

- **Moldura** com cantos arredondados, vidro (opacidade + blur) e grão; **barras** em qualquer lado, presas na moldura ou soltas, com seções, grupos em pílula e dezenas de módulos (ilha dinâmica, workspaces, bandeja, privacidade, atualizações, clima, mídia...). Parar o mouse num módulo abre um cartão de detalhes.
- **Dock** com ampliação dos ícones, miniatura das janelas e apps fixados.
- **Widgets na área de trabalho** (relógio flor/digital/diário/pixel, clima, relógio mundial, calendário, mídia com letra sincronizada, visualizador, sistema, usuário, tarefas, notas, timers, texto, imagem): arrastar, redimensionar, inspetor na tela, posição automática pela área calma do wallpaper, também na tela de bloqueio.
- **Visuais (presets)** do shell inteiro — widgets, wallpaper, barras, cores, animações, painéis, bloqueio, Hyprland e fontes — com miniatura, desfazer e exportar/importar `.zip`.
- **Tema pelo wallpaper (Material You)** aplicado no shell, nas bordas do Hyprland, no kitty, no GTK3/4 e no Brave.
- **Wallpaper**: imagens e vídeos, transições, deslize ao trocar de workspace, desfoque/escurecimento com janelas, modo centralizado em forma e mosaico; busca no Wallhaven.
- **Launcher** com prefixos: apps, comandos, área de transferência com imagens, emojis e símbolos, atalhos do Hyprland, tradutor, calculadora, busca na web (buscador configurável) e nas opções do shell.
- **Notificações** que crescem da moldura, **OSD**, **tela de bloqueio** (relógio flor, senha em formas, chaveiro), **menu de energia** que avisa se houver atualização do pacman rodando.
- **Ferramentas**: captura de área, OCR, traduzir a tela, anotar, Google Lens, gravar tela/área com som, prateleira de arquivos, painel de jogo (mira, notas, volume por app), luz noturna com horário, proteção contra clarão, cantos ativos, equalizador (EasyEffects), proteção de volume.
- **Configurações** numa janela normal: páginas para tudo, incluindo as opções do Hyprland (espaçamentos, bordas, monitor, teclado, apps ao iniciar) e uma biblioteca de **animações** com editor de curvas e molas.

## Requisitos

- Arch Linux (o instalador usa o pacman; em outra distro instale os pacotes equivalentes à mão)
- Hyprland com configuração em **Lua** (testado na 0.56)
- Quickshell (testado na 0.3.2)

O instalador instala o que faltar. **Essenciais**: quickshell, hyprland, pipewire, pipewire-audio, wireplumber, qt6-multimedia, qt6-multimedia-ffmpeg, ffmpeg, python, python-pillow, ttf-jetbrains-mono-nerd, libnotify, curl, glib2, xdg-utils, procps-ng, wl-clipboard, cliphist, grim, slurp, hyprpicker, pacman-contrib, sound-theme-freedesktop. **Extras** (cada um liga um recurso; pule com `--minimal`): cava, hyprsunset, tesseract (+ dados por/eng), translate-shell, satty, wf-recorder, easyeffects, power-profiles-daemon, gnome-keyring, networkmanager, bluez, kitty. O tema Material You usa um venv próprio em `~/.local/share/quickshell-mine` (sem sudo).

## Instalar

```bash
git clone https://github.com/neverevis/my-hyprland-config
cd my-hyprland-config
./install.sh
```

Opções: `--no-deps` (não instala nada), `--minimal` (só as dependências essenciais), `--no-autostart` (só atalhos, sem iniciar no login), `--reset` (substitui o seu `settings.json` pelo padrão do repositório).

O script:

1. instala as dependências que faltarem (Arch/pacman, pede o sudo);
2. copia `quickshell/mine` para `~/.config/quickshell/mine` (com backup do que já existir);
3. instala `hypr/quickshell.lua` em `~/.config/hypr/` e adiciona `pcall(require, "quickshell")` ao `hyprland.lua` (com backup);
4. cria a pasta de wallpapers (`~/Imagens/Wallpapers` por padrão).

Depois: `qs -c mine` ou faça logout/login.

## Atalhos

| Atalho | Ação |
| --- | --- |
| Super + C | Janela de configurações |
| Super + W | Seletor de wallpaper |
| Super + Tab | Launcher |
| Super + A | Painel Início |
| Super + ` | Visão geral dos workspaces |
| Super + L | Bloquear |
| Super + G | Painel de jogo |
| Print | Capturar uma área |
| Super + Shift + T | Copiar texto da tela (OCR) |
| Ctrl + Alt + Delete | Menu de energia |

Mude no `hypr/quickshell.lua`. Os wallpapers **não** estão no repositório: ponha as suas imagens na pasta configurada em *Configurações → Wallpaper*.

## Estrutura

```
quickshell/mine/             o shell (QML)
quickshell/mine/scripts/material.py   gerador do tema (Material You)
quickshell/settings.default.json   configurações padrão (visual igual ao meu)
hypr/quickshell.lua          atalhos, regras de camada e autostart
install.sh
```

As configurações ficam em `~/.config/quickshell/mine/settings.json` (salvas pela própria janela de configurações). O blur é aplicado ao Hyprland por `~/.config/hypr/quickshell-blur.lua`, gerado pelo shell.
