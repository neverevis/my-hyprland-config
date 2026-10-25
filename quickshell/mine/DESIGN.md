# Guia de design do shell "mine"

Destilado das skills instaladas em ~/.claude/skills (emil-design-eng, impeccable, taste-skill/app-screens,
apple-design, review-animations, animate, animation-performance, improve-animations,
find-animation-opportunities, break-ui), traduzido para QML. Vale para tudo: configuracoes, paineis,
barra, widgets da area de trabalho, janelas.

## 0. O que nunca muda (identidade escolhida pelo usuario)
- O shell e uma ferramenta de uso diario (modo "Operate"): clareza, consistencia e rapidez valem mais
  que efeito. Bonito aqui = preciso, calmo e coerente.
- Identidade que fica: moldura integrada (barras e paineis saem da moldura), relogio flor, digitos que
  rolam, cores do tema vindas do wallpaper, sistema de animacoes proprio (MotionAnim / Motion.qml),
  Vidro quando o usuario liga (Theme.gl). O "brief" do usuario vence as regras genericas: nao tirar vidro,
  blur, temas, formas nem nenhuma opcao.
- Nunca remover funcionalidade, opcao, atalho ou IPC. Nunca mudar escolhas salvas do usuario
  (settings.json: animacoes atribuidas, widgets, cores). Mudar so o desenho, o espacamento, os textos
  e as microinteracoes.

## 1. Tokens (use sempre; nada de numero solto)
- Espaco: SetK.xs 4, sm 8, md 12, lg 16, xl 24, xxl 32 (base 4). Grupos apertados, separacao generosa;
  mais espaco acima de um titulo do que abaixo.
- Texto (uma familia; 4-6 tamanhos): titulo de pagina SetK.fPage 26; titulo de secao 13-16 semibold;
  linha SetK.fRow 14 medium; descricao/meta SetK.fDesc 12; nada abaixo de 11. No maximo 3 pesos; Bold
  para uma coisa por tela. Numeros que mudam (relogio, %, MB, contadores): font.features { "tnum": 1 }.
- Raio: familia "macia" ja escolhida. Caixa 18 (SetK.boxRadius), dentro dela 12 (innerRadius), controles
  pequenos 8-10, pilulas totalmente redondas. Raios aninhados descem (18 > 12 > 8).
- Movimento: SetK.fast 140, SetK.base 200, curva SetK.ease (= cubic-bezier(0.23, 1, 0.32, 1), ease-out
  forte). Movimento na tela: (0.77, 0, 0.175, 1). Gaveta/painel: (0.32, 0.72, 0, 1).
- Cor: Theme.* sempre. Acento (Theme.accent / tint) so em: selecao atual, estado ligado, a acao
  principal da tela e dados. Nunca como decoracao de cromo repetida em toda linha.

## 2. Cor e superficie
- Separacao por 1px (Theme.border, ~0.55 de opacidade) ou um degrau de tom; borda OU sombra, nunca as
  duas. Sombra so no que flutua (menu, popup, tooltip, dialogo).
- Texto em 3 niveis: Theme.text, Theme.muted, e desabilitado = opacidade 0.45 + motivo escrito. Contraste
  de texto >= 4.5:1 (cinza sobre cor: use tom da propria cor, nao cinza).
- Sem gradiente em fundo/botao/texto. Sem brilho (glow) de borda. Vidro so onde o usuario ligou.
- Icones: uma familia (Ico), contorno, 16-20 px na navegacao e nas linhas, cinza (Theme.muted) quando
  nao sao estado. Evitar o icone dentro de quadradinho colorido repetido em toda linha/cartao (o
  "kit generico"); um icone simples ajuda mais. Excecao: botoes de alternancia rapida (estilo
  Android/GNOME), onde o circulo cheio indica "ligado" — isso e estado, pode.
- Navegacao lateral: item ativo = pilula neutra (Theme.cardHi / tint baixo) com texto em Theme.text;
  sem barra colorida na esquerda; o acento no maximo no icone do item ativo.

## 3. Hierarquia e layout
- Cada tela responde a UMA pergunta primeiro; o maior bloco e o que responde. Titulos sao substantivos
  (sem "eyebrow"/rotulo pequeno em cima de titulo, sem numeracao 01/02).
- Sem cartao dentro de cartao. Grupos por proximidade antes de caixas.
- Um alinhamento esquerdo continuo do titulo ate a ultima linha. Um gutter so por contexto.
- Linhas de configuracao: rotulo 14 medium + descricao 12 muted; controle a direita centralizado na
  linha do titulo. Mostrar o resultado do ajuste perto dele (previa) quando possivel.
- Miniaturas/previas: conteudo real (wallpaper atual, apps de verdade, a propria interface em miniatura),
  nunca formas abstratas ou barras cinza falsas.
- Estados: vazio (diz o que e e qual a proxima acao), carregando (layout final com barras cinza no
  tamanho real, sem shimmer), erro (dentro do bloco, uma frase: o que falhou + "Tentar de novo"), zero
  real impresso como "0", ausente como "—".
- Textos: pt-BR curto, verbo + objeto nos botoes ("Remover app", nao "OK"); erros dizem o problema e a
  saida; uma palavra por conceito no shell todo.

## 4. Movimento (decida nesta ordem)
1. Deve animar? Frequencia: 100+/dia (atalho de teclado, abrir launcher pelo teclado, navegar lista) =
   nada ou quase imperceptivel; dezenas/dia (hover, alternancias) = sutil e rapido; ocasional (paineis,
   dialogos, notificacoes) = padrao; raro (primeiro uso, sucesso) = pode ter charme.
2. Proposito nomeado: feedback, consistencia espacial, indicar estado, evitar salto brusco. "Fica
   bonito" nao vale em coisa frequente.
3. Curva: entrar/sair = ease-out (SetK.ease); mover na tela = ease-in-out forte; hover/cor = 140 ms.
   Nunca ease-in (Easing.InQuad/InCubic...) em interface.
4. Duracao: pressionar 100-160 ms; tooltip/popup pequeno 125-200; menu 150-250; painel/dialogo 200-300
   (ate 500 so para coisa grande). Saida mais rapida que entrada.
5. Fisica: nunca escala 0 — entrar de scale 0.95-0.97 + opacidade 0. Popups e menus crescem a partir do
   gatilho (transformOrigin do lado do botao); dialogos centrais ficam no centro.
6. Pressionar: tudo que e clicavel encolhe para 0.97 (Behavior on scale 120-160 ms ease-out) ou escurece
   o fundo na hora do press (onPressed, nao no release).
7. Interrompivel: Behavior/NumberAnimation que reparte do valor atual; nada de bloquear clique durante
   animacao. Molas so para arrastar/gesto.
8. Tooltip: atraso so no primeiro; nos vizinhos logo em seguida, aparece na hora.
9. Lista que entra junta (ocasional): escalonar 30-60 ms por item, no maximo ~6 itens, sem bloquear.
10. Performance: animar so opacity/scale/x/y; nada de width/height/radius por quadro (excecao: acordeao);
    animacao parada quando escondida (running/enabled ligados a visibilidade); layer/MultiEffect so
    enquanto o efeito esta ligado; nada de Timer/Canvas repintando escondido.
11. Movimento reduzido: ainda nao existe opcao; quando existir, trocar deslocamentos por fade curto.

## 5. Verificar (no resultado renderizado)
- Squint test: com a imagem borrada, da para ver o principal, o secundario e os grupos?
- Textos longos (nomes de app enormes, titulos de musica, nomes de rede) cortam com elide ou quebram,
  nunca estouram; contagem 1 no singular ("1 app"); listas vazias tem estado vazio.
- Hover, pressionado, foco, desabilitado e carregando existem em todo controle.
- Captura de tela no tamanho real, poucas, juntando as verificacoes numa olhada.
