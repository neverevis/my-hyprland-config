# my-hyprland-config

Um shell em **Quickshell** para o **Hyprland**: uma moldura fina na tela, com barras, painéis e widgets que "crescem" da borda. Tudo se configura por uma janela de configurações, sem editar código. O instalador deixa tudo funcionando na hora, sem reiniciar.

## Capturas de tela

> Ainda sem imagens. Coloque as capturas em `docs/img/` e referencie aqui.

| Área | Arquivo sugerido |
| --- | --- |
| Área de trabalho com widgets e barras | `docs/img/desktop.png` |
| Janela de configurações | `docs/img/configuracoes.png` |
| Seletor de wallpaper | `docs/img/wallpaper.png` |
| Launcher e painel Início | `docs/img/launcher.png` |
| Tela de bloqueio | `docs/img/bloqueio.png` |

## O que tem

- **Moldura e barras**: vidro, blur e grão; barras em qualquer lado, presas ou soltas; dezenas de módulos (ilha dinâmica, workspaces, bandeja, clima, mídia, bateria...); dock.
- **Área de trabalho**: widgets de relógio, clima, calendário, mídia com letra, visualizador, sistema, tarefas, notas, timers e mais; editor na tela.
- **Wallpaper**: imagens e vídeos, 10 transições, mosaico, forma, busca no Wallhaven.
- **Tema**: cores do wallpaper (Material You) aplicadas no shell, no Hyprland, no kitty, no GTK e no Brave; visuais (presets) salvos e exportáveis.
- **Painéis**: launcher com prefixos, Início (áudio, rede, Bluetooth, VPN, energia), notificações, visão geral dos workspaces, barra lateral com chat de IA e tradutor.
- **Sessão**: tela de bloqueio, menu de energia, inatividade, polkit.
- **Ferramentas**: captura de área, OCR, traduzir a tela, gravação, painel de jogo, teclado na tela, luz noturna, equalizador.

Lista completa: [docs/RECURSOS.md](docs/RECURSOS.md).

## Requisitos

- Hyprland com configuração em **Lua** (testado na 0.56) e Quickshell (testado na 0.3.2, o pacote `quickshell` ou `quickshell-git`).
- Arch Linux é o caso suportado (o instalador usa pacman e, para pacotes só do AUR, paru ou yay). Em outra distro o instalador mostra a lista de pacotes para instalar à mão.
- Python 3, para o instalador e os scripts do shell.

## Instalar

```bash
git clone https://github.com/neverevis/my-hyprland-config
cd my-hyprland-config
./install.sh
```

O instalador:

1. confere as versões do Quickshell e do Hyprland e instala o que faltar (pergunta antes de usar sudo);
2. copia o shell para `~/.config/quickshell/mine` e os scripts para `~/.local/bin`;
3. integra ao Hyprland (`hypr/quickshell.lua` + uma linha no fim do `hyprland.lua`), com backup (`*.mine-orig`) de tudo que edita;
4. **mostra os atalhos seus que colidem com os do shell** e pergunta: substituir todos, manter os seus ou decidir um a um;
5. detecta programas que brigam com o shell (waybar, mako, dunst, hyprpaper, eww, ags...) e oferece parar e desligar o autostart deles;
6. oferece ligar serviços que os extras usam (ydotool, NetworkManager, Bluetooth, perfis de energia);
7. recarrega o Hyprland e inicia o shell agora. Só pede logout/login se algo realmente exigir (por exemplo, o grupo `input`).

**Num Arch zerado** (sem `hyprland.lua` nem `hyprland.conf`), o instalador cria `~/.config/hypr/hyprland.lua` a partir do exemplo oficial do Hyprland (`/usr/share/hypr/hyprland.lua`, ou um inicial pequeno se ele não existir), já com o layout de teclado do sistema (`localectl`) e o terminal do shell (`Super + Return` e o terminal do exemplo abrem o terminal padrão escolhido nas configurações). Como não há nada seu para proteger, os atalhos do exemplo que repetem os do shell (por exemplo `Super + Q`, `Super + C`) são trocados pelos do shell sem perguntar; os demais atalhos do exemplo ficam. Com só um `hyprland.conf` antigo, ele avisa e pergunta (padrão: não) se cria o `hyprland.lua` novo; seus atalhos e regras antigos **não** são migrados (o `.conf` fica de backup).

**O que o instalador muda na sua config existente:** só acrescenta `pcall(require, "quickshell")` ao fim do `hyprland.lua` (backup `*.mine-orig`), cria `quickshell.lua`, `quickshell-keys.lua` e `quickshell-blur.lua` na mesma pasta, e (opcional) comenta autostarts de programas que brigam com o shell. O `quickshell-blur.lua`, gerado pelo shell, só contém o que você mudar nas configurações: as regras das janelas do próprio shell, o blur se você ligar "gerenciar blur", e as opções do Hyprland que você alterar na página Hyprland. Nada mais da sua config é sobrescrito.

Opções úteis: `--dry-run` (só mostra o que faria), `--replace-keys` / `--keep-keys` (resolve os conflitos de atalho sem perguntar), `--stop-programs` / `--keep-programs`, `--no-deps`, `--minimal`, `--no-autostart`, `--no-start`, `--reset`, `--keys` (refaz só a escolha dos atalhos), `--yes` (respostas padrão). Veja `./install.sh --help`.

### Desinstalar

```bash
./install.sh --uninstall
```

Para o shell, restaura os arquivos editados (linha do `hyprland.lua`, autostarts comentados, kitty, GTK), tira os scripts e move `~/.config/quickshell/mine` para um backup (`mine.removed-<data>`) depois de confirmar. Pacotes e serviços ligados não são desfeitos.

## Primeiros passos

1. `Super + C` abre as **Configurações**; `Super + V` abre os **Visuais** (presets prontos).
2. Ponha imagens na pasta de wallpapers (o instalador diz qual: `Pictures/Wallpapers` ou o equivalente da sua língua) e abra o seletor com `Super + W`.
3. `Super + Tab` abre o launcher; digite `;` para a área de transferência, `:` para emojis, `=` para contas.
4. `Super + A` abre o painel Início; `Super + L` bloqueia a tela.

## Atalhos

A tabela abaixo (e [docs/ATALHOS.md](docs/ATALHOS.md)) é gerada de `hypr/quickshell.lua` por `python3 scripts/gen-keys-doc.py`. Para mudar uma tecla, edite `~/.config/hypr/quickshell-keys.lua` (formato em [docs/ATALHOS.md](docs/ATALHOS.md)).

<!-- ATALHOS:INICIO -->
| Atalho | Ação |
| --- | --- |
| `Super + C` | Configurações do shell |
| `Super + V` | Visuais (presets do shell) |
| `Super + W` | Seletor de wallpaper |
| `Super + Shift + W` | Wallpaper aleatório |
| `Super + Tab` | Launcher de aplicativos |
| `Super + A` | Painel Início |
| `Super (tocar e soltar)` | Painel Início ao tocar só na tecla Super (desligado por padrão) |
| `` Super + ` `` | Visão geral dos workspaces |
| `Super + G` | Painel de jogo |
| `Super + K` | Teclado na tela |
| `Super + Alt + D` | Editar widgets da área de trabalho |
| `Super + Shift + V` | Histórico da área de transferência |
| `Super + .` | Emojis |
| `Ctrl + Alt + C` | Limpar notificações |
| `Super + Q` | Fechar o painel do shell aberto ou a janela ativa |
| `Super + Return` | Abrir o terminal padrão |
| `Segurar Super` | Segurar Super: mostra barras escondidas e números dos workspaces |
| `Super (tocar e soltar)` | Soltar Super: esconde de novo |
| `Super + L` | Bloquear a tela |
| `Ctrl + Alt + Delete` | Menu de energia |
| `Print` | Capturar uma área (copia e salva) |
| `Super + Shift + S` | Capturar uma área (copia e salva) |
| `Super + Shift + Alt + S` | Capturar uma área e buscar no Google Lens |
| `Super + Shift + T` | Copiar o texto de uma área (OCR) |
| `Super + Alt + T` | Traduzir a tela |
| `Super + Shift + C` | Conta-gotas de cor (copia) |
| `Ctrl + Alt + R` | Gravar a tela (de novo para parar) |
| `Super + Shift + Alt + R` | Gravar uma área |
| `Super + Alt + R` | Parar a gravação |
| `Ctrl + Super + Espaço` ou `XF86AudioPlay` ou `XF86AudioPause` | Tocar / pausar (funciona com a tela bloqueada) |
| `Ctrl + Super + =` ou `XF86AudioNext` | Próxima faixa (funciona com a tela bloqueada) |
| `Ctrl + Super + -` ou `XF86AudioPrev` | Faixa anterior (funciona com a tela bloqueada) |
| `Ctrl + Super + Backspace` ou `XF86AudioStop` | Parar a mídia (funciona com a tela bloqueada) |
<!-- ATALHOS:FIM -->

## Problemas comuns

- **O shell não abriu**: rode `qs -c mine` num terminal e leia o erro, ou `qs log -c mine`. Confira `qs --version` (0.3.x) e se o Hyprland usa a config em Lua.
- **Um atalho não funciona**: provavelmente colide com um seu. Rode `./install.sh --keys` para escolher quem vence. Para ver o que está ligado: `hyprctl binds | grep mine`. Atalhos do shell têm a descrição `[mine] ...`.
- **Aparecem quadrados no lugar dos ícones**: falta a fonte `ttf-jetbrains-mono-nerd` (rode `fc-cache -f` depois de instalar).
- **Barra ou notificação duplicada**: outro programa ainda roda (waybar, mako, dunst, swaync...). Rode `./install.sh --stop-programs`.
- **Falta algum recurso (OCR, gravação, Wi-Fi...)**: o shell avisa qual pacote falta; rode o instalador sem `--minimal` ou instale o pacote. A lista está no início do `install.sh`.
- **Teclado na tela não digita**: precisa do serviço `ydotool` e do grupo `input` (o instalador oferece os dois; o grupo vale após logout/login).
- **Voltar ao que era**: `./install.sh --uninstall`.

## Estrutura

```
quickshell/mine/             o shell (QML e scripts)
quickshell/settings.default.json   configurações padrão
hypr/quickshell.lua          tabela de atalhos, regras de camada e autostart
bin/                         scripts instalados em ~/.local/bin (mine-shell, session-action, qs-close-or-kill)
scripts/                     ajudante do instalador e gerador da documentação
docs/                        RECURSOS, PROGRESSO, ATALHOS
install.sh
```

As configurações ficam em `~/.config/quickshell/mine/settings.json` (salvas pela própria janela). O blur é aplicado ao Hyprland por `~/.config/hypr/quickshell-blur.lua`, gerado pelo shell.

## Documentação

- [docs/RECURSOS.md](docs/RECURSOS.md): tudo que o shell faz, por área
- [docs/PROGRESSO.md](docs/PROGRESSO.md): o que está pronto, em andamento e planejado
- [docs/ATALHOS.md](docs/ATALHOS.md): atalhos de teclado
