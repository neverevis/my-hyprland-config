# Recursos

Tudo que o shell faz, por área. Feito a partir dos comentários de cabeçalho de cada arquivo em `quickshell/mine/`. Atalhos: [ATALHOS.md](ATALHOS.md).

## O que o instalador muda

- Config existente: só acrescenta `pcall(require, "quickshell")` ao fim do `hyprland.lua` (backup `*.mine-orig`) e cria `quickshell.lua`, `quickshell-keys.lua`, `quickshell-blur.lua` ao lado. Conflitos de atalho são resolvidos por você (`--replace-keys` / `--keep-keys`).
- `quickshell-blur.lua` (gerado por `HyprSync.qml` + `HyprConf.qml`) só aplica: regras de camada/janela do próprio shell (namespaces `mine-*`, janela de configurações, opacidade 1 das janelas `org.quickshell`); `decoration.blur` só se "gerenciar blur" estiver ligado; bordas só se o tema do wallpaper nas bordas estiver ligado; e as opções do Hyprland que você mudou na página Hyprland (`hl.config` só com as chaves alteradas), monitores, autostart e cursor só se configurados. O que você não mexer no shell continua como no seu `hyprland.lua`.
- Sistema zerado: cria o `hyprland.lua` do exemplo oficial do Hyprland (teclado do `localectl`, terminal do shell) e o shell vence os conflitos de atalho; só `hyprland.conf`: pergunta antes e não migra os atalhos antigos.

## Moldura e barras

- Moldura fina na tela com cantos arredondados, vidro (opacidade + blur) e grão; cor e arredondamento configuráveis (`Geometry.qml`).
- Barras em qualquer lado, presas na moldura ou soltas, com seções, grupos em pílula e estilos por módulo (clique direito no módulo abre o editor de estilo).
- Módulos: relógio, workspaces (vários estilos), janela ativa, CPU, memória, GPU, temperatura, rede (velocidade), volume, bateria (7 estilos), brilho, bandeja do sistema, clima, mídia, atualizações, teclado, gravação, notificações, launcher, paleta, texto.
- **Ilha dinâmica**: pílula que muda conforme o que acontece (`IslandModule.qml`).
- **Dock** (`TaskbarModule.qml`): apps fixados e abertos, ampliação, miniatura das janelas, menu de clique direito.
- Cartão de detalhes ao parar o mouse num módulo; segurar Super mostra barras escondidas e os números dos workspaces.
- Cantos ativos (`HotCorners.qml`) e mapa ao vivo da tela nas configurações.

## Área de trabalho

- Widgets: relógio (flor, digital, diário, pixel, animado), clima, relógio mundial, calendário, mídia com letra sincronizada, visualizador, sistema, usuário, tarefas, notas, timers, texto, imagem e conversor de imagens.
- Editor na tela: galeria de widgets, inspetor com abas, arrastar e redimensionar, desfazer/refazer, multisseleção, travar posições, copiar estilo.
- Composições (looks) por widget, fundo fosco e posição automática pela área calma do wallpaper; os widgets também aparecem na tela de bloqueio.
- Presets da área de trabalho salvos com nome.

## Wallpaper

- Imagens e vídeos (MP4, WebM, MKV, MOV), troca automática, aleatório, transições (fade, deslizar, cortina, círculo, zoom e as de shader: dissolver, pixelar, ondas, persianas, redemoinho).
- Estilo normal, numa forma ou em mosaico (editor em árvore); desfoque dividido; deslize ao trocar de workspace.
- Seletor em painel (grade ou lista, ordem manual, lixeira, prévia ao vivo) e busca no **Wallhaven** com filtros e download.

## Tema e visuais

- Tema Material You gerado do wallpaper (`PaletteExtractor.qml`), claro/escuro ou esquemas prontos e os seus; aplicado no shell, nas bordas do Hyprland, no kitty, no GTK 3/4, no Qt e no Brave.
- **Visuais** (presets do shell inteiro): escolhe o que entra (widgets, wallpaper, barras, cores, animações, painéis, bloqueio, Hyprland, fontes), aplica com desfazer, exporta e importa `.zip`.
- Sistema de **animações** nomeadas com editor de curvas Bézier e molas, por lugar do shell.
- Papéis de fonte, formatos de hora e data, formas (flor de pétalas ajustáveis e outras) para recortar imagens.

## Painéis

- **Launcher**: apps por uso e favoritos, ações do `.desktop`; prefixos para ações (`/`), área de transferência com imagens (`;`), emojis (`:`), símbolos (`.`), calculadora (`=`), comandos (`$`), web (`?`), atalhos do Hyprland (`<`), tradutor (`!`); acha também opções das configurações.
- **Início**: abas Início, Mídia, Áudio, Sistema, Conexão, Bluetooth; botões rápidos, Wi-Fi, Bluetooth, VPN (NetworkManager), volume por app, energia, agenda.
- **Notificações**: o shell é o servidor (org.freedesktop.Notifications); avisos crescem da moldura, agrupam por app, deslizar dispensa, histórico, não perturbe.
- **OSD** de volume, microfone e mídia.
- **Visão geral** dos workspaces e **barra lateral esquerda** (chat de IA com Ollama/OpenAI/Gemini, tradutor, mídia).
- **Prateleira de arquivos** (soltar e arrastar entre apps).

## Sessão e sistema

- Tela de bloqueio (protocolo de sessão do Wayland, senha pelo PAM, chaveiro, relógio flor), menu de energia (hibernar, firmware, avisos de atualização em andamento), inatividade sem hypridle (`Idle.qml`), agente **polkit** próprio.
- Luz noturna (hyprsunset) com horário, proteção contra clarão, proteção de volume, equalizador (EasyEffects), tema de ícones e cursor, mouse, fontes (com download do Google Fonts), webapps, aplicativos padrão.
- Opções do Hyprland (espaçamentos, bordas, sombra, foco, teclado, mouse) e blur, pela janela de configurações.
- Aviso e instalação de atualizações do pacman (`SystemGuard.qml`).

## Ferramentas

- **Captura de área** com ações: copiar e salvar, Google Lens, OCR (tesseract), traduzir (no lugar da tela), anotar (satty), gravar.
- **Gravação** de tela ou área (wf-recorder) com áudio do sistema e microfone, moldura em volta da área.
- Conta-gotas de cor, **painel de jogo** (mira, notas, volume por app, limitador de FPS pelo mangohud), teclado na tela ABNT2/US (ydotool).
- Uso do Claude Code lido de arquivos locais (módulo opcional da barra).

## Janela de configurações

Páginas em duas áreas, **Personalização** (Início, Tema e cores, Wallpaper já no novo formato; Moldura, Barras, Widgets, Painéis, Launcher, Notificações, Animações, Visuais, Blur) e **Sistema** (Sessão, Hyprland, Ferramentas, Sistema, Sobre, Perfil). Busca nas opções, mudanças valem ao vivo e ficam salvas em `settings.json`. Veja o andamento da migração em [PROGRESSO.md](PROGRESSO.md).

## Integração por linha de comando

Tudo é controlável por `qs -c mine ipc call <alvo> <função>` (alvos como `settings`, `launcher`, `home`, `wallpaper`, `overview`, `session`, `media`, `region`, `recorder`, `desktop`, `notifications`, `night`, `looks`...). Os atalhos usam isso.

## Aplicativos (janela)
- `qs -c mine ipc call apps window` alterna a janela; `apps open <apps|pkgs|install|updates>` abre numa aba; também está no launcher ("Aplicativos") e em Configurações > Aplicativos.
- Pacotes: todos os do pacman, com busca, filtros (explícitos, AUR, órfãos), ordem por nome/tamanho, "Necessário para" e remoção protegida (`pacman -Rs --print` antes; bloqueia o que o shell exige, avisa o que é recurso opcional).
- Nada roda com a janela fechada; AUR e Flathub só são consultados quando você busca em Instalar.

## Terminal (página de configurações)
- Terminal padrão, visual do kitty/foot (transparência, imagem de fundo, margem, fonte, cursor), prompt montado (starship) e boas-vindas com imagem (fastfetch/chafa), tudo com uma maquete do terminal onde as peças se arrastam; gera arquivos em `~/.config/quickshell-mine` e `~/.config/fish/conf.d/mine-*.fish`, que somem ao desligar.
