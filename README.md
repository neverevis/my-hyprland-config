# my-hyprland-config

Meu shell em **Quickshell** para o **Hyprland**: uma moldura fina na tela com barras que "sobem" da borda, tudo configurável por uma janela de configurações (sem editar código).

## O que tem

- **Moldura** com cantos arredondados, contorno opcional, efeito vidro (opacidade + blur) e grão.
- **Várias barras**, em qualquer lado, com **seções** posicionáveis e **módulos**: relógio, workspaces (10 estilos), janela ativa, CPU, memória, volume, bandeja do sistema e texto.
- Barras que **se escondem** e aparecem ao passar o mouse, com animação por curva de Bézier.
- **Wallpaper em QML** com transições (fade, slide, wipe, circle, zoom) e **seletor** que sai da moldura (qualquer lado, acoplado ou flutuante). As barras saem da frente dele.
- **Tema pelo wallpaper (Material You)**, igual ao Caelestia: a cor-fonte vem da imagem (quantização + pontuação) e um esquema do Material gera os papéis de cor (variantes tonal spot, vibrante, expressivo, etc., escuro/claro). Aplica na moldura, barras, janelas e nas bordas do Hyprland; há um módulo de barra com as bolinhas das cores. O tema também é aplicado no kitty (`~/.config/kitty/themes/quickshell.conf`, recarregado ao vivo), nos apps GTK3/GTK4 (`quickshell.css` importado pelo `gtk.css`) e no Brave (cor-semente na política gerenciada `/etc/brave/policies/managed/caelestia.json`, que precisa ser gravável pelo seu usuário).
- **Biblioteca de animações** nomeadas (editor de curva arrastando os pontos) e página de **Blur**.

## Requisitos

- Hyprland com configuração em **Lua** (testado na 0.56) e `hyprctl`
- Quickshell (testado na 0.3.2)
- PipeWire (módulo de volume)
- `python3` com `venv` (o instalador cria um venv em `~/.local/share/quickshell-mine` e instala o `materialyoucolor` nele, sem sudo)

## Instalar

```bash
git clone https://github.com/neverevis/my-hyprland-config
cd my-hyprland-config
./install.sh
```

Opções: `--no-deps` (não instala nada), `--no-autostart` (só atalhos, sem iniciar no login), `--reset` (substitui o seu `settings.json` pelo padrão do repositório).

O script:

1. instala dependências que faltarem (Arch/pacman);
2. copia `quickshell/mine` para `~/.config/quickshell/mine` (com backup do que já existir);
3. instala `hypr/quickshell.lua` em `~/.config/hypr/` e adiciona `pcall(require, "quickshell")` ao `hyprland.lua` (com backup);
4. cria a pasta de wallpapers (`~/Imagens/Wallpapers` por padrão).

Depois: `qs -c mine` ou faça logout/login.

## Atalhos

| Atalho | Ação |
| --- | --- |
| Super + C | Janela de configurações |
| Super + W | Seletor de wallpaper |

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
