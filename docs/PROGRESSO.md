# Progresso

Resumo do que está pronto, do que está em andamento e do que vem depois. Atualizado em 2026-10-25.

## Pronto

| Área | O que já funciona |
| --- | --- |
| Moldura e barras | moldura com vidro, barras soltas ou presas, estilos de grupo, dock, bandeja, ilha, bateria, brilho, cantos ativos, Super segurado |
| Área de trabalho | todos os widgets, composições (looks), editor redesenhado (galeria, inspetor, desfazer), preset de estilo |
| Wallpaper | imagens e vídeo, 10 transições, mosaico, desfoque dividido, seletor em grade, Wallhaven |
| Tema | Material You, esquemas nomeados, kitty/GTK/Qt/Brave, visuais exportáveis |
| Painéis | launcher com prefixos, Início, notificações agrupadas, overview, barra lateral esquerda (IA e tradutor) |
| Sessão | bloqueio, menu de energia, inatividade, polkit |
| Ferramentas | captura, OCR, traduzir a tela, gravação com som, painel de jogo, teclado na tela, luz noturna, EQ |
| Instalação | instalador plug-and-play: atalhos com resolução de conflitos, detecção de programas conflitantes, início imediato, `--uninstall`, `--dry-run` |
| Documentação | README, RECURSOS, ATALHOS (gerado), PROGRESSO |

## Em andamento: redesenho das configurações

Nova arquitetura com duas áreas, **Personalização** e **Sistema**, e um kit de componentes `Set*`.

- Todas as páginas de Personalização já estão no novo formato: Início, Tema e cores, Wallpaper (com palco que toca as transições de verdade), Área de trabalho, Barras e moldura, Painéis, Janelas, Animações e Visuais.
- Em Sistema, já migradas: Mouse e teclado, Energia e sessão, Ferramentas, Conta e Sobre. Aplicativos (instalar, remover, atualizar, ao iniciar, apps padrão e webapps; script `scripts/apps.py`, modo de teste com `QS_APPS_DRYRUN=1`). Som (saídas, entradas com medidor ao vivo, volume por app, sons do shell, equalizador), Rede e Bluetooth (Wi-Fi, cabo, VPN, pareamento), Monitores (disposição, resolução, escala, posição, brilho, luz noturna, VRR; pergunta de 15 s em `Displays.qml`) e Data, hora e idioma (formato, fuso e NTP por pkexec, idioma). Modo de teste dessas quatro: `QS_SYS_DRYRUN=1` ou o arquivo `~/.cache/quickshell-mine/sys-dryrun`. Atalhos de teclado continua como "em breve".
- Pendências de acabamento: controles inline nas páginas antigas, cartão de usuário (avatar sobreposto) e composições de banner.

## Planejado: configurações do sistema operacional

Páginas de Sistema para dispensar outros painéis:

1. **Editor de atalhos de teclado** (escreve em `~/.config/hypr/quickshell-keys.lua`; o formato já está pronto, veja [ATALHOS.md](ATALHOS.md))
2. Energia (perfil e sessão)

(Aplicativos, Som, Rede e Bluetooth, Monitores e Data/hora já estão prontos.)

## Problemas conhecidos e limites

- **Vários monitores**: a área de trabalho e parte dos painéis são pensadas para uma tela (camada de widgets só na principal; a página Monitores já ajusta cada tela, mas o seletor de monitor dos painéis ainda não existe).
- Transições com shader foram feitas como aproximações e não foram conferidas visualmente em todos os casos.
- Sem bateria ou backlight (PC de mesa) esses módulos somem; o visual da bateria não foi testado em notebook.
- Vidro dos widgets é um gradiente estático (não é blur real de fundo).
- Brave: o tema ao vivo exige criar uma vez `/etc/brave/policies/managed/caelestia.json` gravável pelo usuário.
- Colar "superpaste" depende de `wtype` e não foi incluído.
- O instalador só integra com a configuração **Lua** do Hyprland (0.56); com `hyprland.conf` ele só copia os arquivos e explica o que fazer.

## Histórico resumido

- **Configurações**: arquitetura Personalização/Sistema, kit `Set*`, páginas Início, Tema e Wallpaper (palco das transições, Super+V abre Visuais).
- **Widgets da área de trabalho**: composições, looks por widget, editor redesenhado, desempenho (modelos estáveis, animações só quando visíveis).
- **Barras (B2/B3)**: bateria, brilho, workspaces, grupos, dock, bandeja, mídia, ilha, popups.
- **Sistema (Y1/Y2)**: bloqueio, gravação, seletor de área, menu de sessão, polkit, EQ, teclado na tela.
- **Painéis (S1/S2/W2)**: áudio, VPN, launcher, overview, seletor de wallpaper, Wallhaven, barra lateral esquerda com IA.
- **Wallpaper (W1)**: transições com shader, mosaico, desfoque dividido.
