# Guia de design do shell "mine"

Destilado das skills instaladas em ~/.claude/skills e traduzido para QML:
emil-design-eng; impeccable com todas as referencias (craft-floor, polish, layout, typeset, operate,
animate, quieter, distill, clarify, colorize, delight, harden, onboard, optimize, audit, critique, adapt,
bolder, overdrive, shape, new-work e os modos); taste-skill (app-screens, tells, motion, type, colour,
copy, critique, layout); apple-design; review-animations, animate, animation-performance,
improve-animations, find-animation-opportunities, animation-vocabulary; break-ui (com o catalogo).
Vale para tudo: configuracoes, paineis, barra, widgets da area de trabalho, janelas.
Partes das skills que sao so de web/landing page (scroll scenes, preloaders, imagens de acervo, scripts
de navegador, Core Web Vitals, iOS/Android) ficaram de fora de proposito.

## 0. O que nunca muda (identidade escolhida pelo usuario)
- O shell e uma ferramenta de uso diario (modo "Operate"): quem usa precisa saber onde tudo esta antes
  de notar o estilo. Bonito aqui = preciso, calmo, coerente e com cara propria.
- O "mundo" do shell empresta so quatro coisas: tipo, paleta, densidade e um gesto assinatura. Nunca
  inventa navegacao ou controles diferentes do que as pessoas ja conhecem. Gestos assinatura do shell:
  moldura integrada (barras e paineis saem da moldura), relogio flor, digitos que rolam, formas, cores
  do tema vindas do wallpaper.
- Cor faz trabalho de verdade (estado, selecao, dados, o gesto assinatura). "Tudo cinza com um acento"
  nao e contencao, e o padrao generico sem polimento.
- O pedido do usuario vence regra generica: Vidro (Theme.gl), blur, temas, formas e animacoes
  atribuidas ficam. Nunca remover funcionalidade, opcao, atalho ou IPC. Nunca mudar escolhas salvas
  (settings.json: animacoes atribuidas via MotionAnim { use }, widgets, cores). Mudar so desenho,
  espacamento, textos, estados e microinteracoes.
- Refinar preserva; redesenhar substitui. Este guia e de refinamento: se um conceito inteiro estiver
  errado, dizer ao usuario em vez de trocar escondido.

## 1. Tokens (use sempre; nada de numero solto)
- Espaco: SetK.xs 4, sm 8, md 12, lg 16, xl 24, xxl 32 (base 4). Grupos apertados, separacao generosa;
  espaco acima de um titulo >= 2x o espaco abaixo dele. Um gutter so por contexto.
- Texto (uma familia, poucos tamanhos e bem separados; 4-6 por tela, nunca 9 parecidos):
  pagina SetK.fPage 26; secao 13-16 semibold; linha SetK.fRow 14 medium; descricao/meta SetK.fDesc 12;
  piso 11 (excecao rara: barra vertical fina, reportada). Se dois tamanhos quase iguais, vire um so.
- Peso: no maximo 3 por superficie; Bold faz um trabalho por tela. Numero grande pode ser regular.
  Nao mudar peso no hover (o texto reflui). Texto claro em fundo escuro: um passo de peso a menos ou um
  pouco mais de espacamento.
- Numeros que mudam (relogio, %, MB, contadores, tempos): font.features: { "tnum": 1 }.
- Raio: familia "macia". Caixa 18 (SetK.boxRadius), dentro dela 12 (innerRadius), controles 8-10,
  pilulas redondas. Raios aninhados descem (18 > 12 > 8 > 4).
- Movimento: SetK.fast 140, SetK.base 200, curva SetK.ease = (0.23, 1, 0.32, 1). Mover na tela:
  (0.77, 0, 0.175, 1). Gaveta/painel: (0.32, 0.72, 0, 1). Saida definitiva curta: (0.55, 0.055, 0.675, 0.19).
- Cor: Theme.* sempre (um hex solto e o comeco de uma segunda paleta). Nada de cinzas novos entre os
  papeis: texto mais quieto = Theme.muted; superficie mais quieta = um degrau de tom.

## 2. Cor e superficie
- Proporcao: fundo domina; acento abaixo de ~5% da tela e so em: selecao atual, estado ligado, a acao
  principal da tela, o dado principal. Acento em 5 lugares deixa de dizer "aqui".
- Separacao: 1px (Theme.border ~0.55) OU um degrau de tom; borda ou sombra, nunca as duas. Sombra so no
  que flutua (menu, popup, tooltip, dialogo). Sem cartao dentro de cartao.
- Texto em 3 niveis: Theme.text, Theme.muted, desabilitado. Contraste de texto >= 4.5:1 (grande >= 3:1).
  Nao baixar opacidade de texto sem checar contraste; esmaecido nunca abaixo de ~40%; desabilitado
  legivel e com o motivo escrito. Cinza sobre cor: usar o tom da propria cor.
- Status: pilula com tinta palida e texto escuro do mesmo tom; vermelho e sinal, nao textura (uma marca
  por objeto). Cor diz bom/ruim, nao sobe/desce; mudanca zero ou indefinida fica cinza.
- Proibidos por padrao: gradiente em fundo/botao/texto, brilho (glow), sombra cinza em todo cartao,
  icone em quadradinho colorido repetido em toda linha, rotulo "eyebrow" pequeno e espacado em cima de
  titulo, numeracao 01/02/03, texto em maiusculas espacadas espalhado. Vidro so onde o usuario ligou.
- Icones: uma familia (Ico), contorno, 16-20 px; Theme.muted quando nao sao estado. Nunca caractere
  unicode ou emoji fazendo papel de icone. Excecao de estado: botao de alternancia rapida com circulo
  cheio = ligado.
- Navegacao lateral: item ativo = pilula neutra (Theme.cardHi) com texto Theme.text; sem barra
  colorida na esquerda; acento no maximo no icone do item ativo. Contagem no item so quando e fila que
  pede acao, e o substantivo fica claro.

## 3. Hierarquia, layout e carga cognitiva
- Cada tela responde a UMA pergunta primeiro; o maior bloco/numero e o que responde. Titulos sao
  substantivos curtos (2-5 palavras).
- Squint test: com a imagem borrada aparecem o principal, o secundario e os grupos, nessa ordem.
- Poucas bordas esquerdas (2-3 posicoes x reaproveitadas). Grade fecha a conta: colunas e gutters
  somam a largura.
- Carga: no maximo ~4 opcoes visiveis por ponto de decisao; 1 acao principal, 1-2 secundarias, o resto
  num menu ou expansor (divulgacao progressiva). Nada que obrigue lembrar algo de outra tela.
- Linhas de configuracao: rotulo 14 medium + descricao 12 muted; controle a direita centrado na linha do
  titulo. Mostrar o resultado do ajuste perto dele (previa). Um modelo de salvar por tela (aqui: cada
  controle salva sozinho).
- Previas e miniaturas: conteudo real (wallpaper atual, apps de verdade, a propria interface), nunca
  formas abstratas, barras cinza falsas ou "dashboard fake".
- Espaco vazio planejado parece calmo; vazio que sobrou parece inacabado (coluna vazia, cartao esticado
  ate a altura do vizinho).

## 4. Dados, listas e graficos (widgets, Inicio, Aplicativos)
- Numeros: tnum, alinhados a direita em colunas, casas decimais fixas por metrica (% com 0-1, contagens
  sem), separador de milhar pt-BR (1.284), unidade como sufixo menor em Theme.muted ("5 min", "33 %").
- Zero real impresso ("0", "0 %"); ausente = "—" pequeno e cinza (nunca "--" grande, parece carregando).
  Nunca mostrar null/undefined/NaN.
- Listas: cortar em 4-6 itens com "Ver tudo" e o total; uma marca de status por linha; acao da linha
  numa coluna fixa no fim; sem zebra; linhas 36-56 px.
- Graficos: uma serie (sem legenda para serie unica), 3-5 linhas de grade fracas, linha reta 1-3 px sem
  suavizar, preenchimento no maximo ~14 %, eixo com escala redonda; barra de progresso na razao real.
  Evento que importa ganha marca e rotulo curto.
- Pessoas/objetos: avatar/inicial com fallback; capa do album, icone do app; nomes curtos e iguais em
  toda largura.

## 5. Estados e robustez (harden + break-ui)
- Todo controle: normal, hover, pressionado, foco visivel, desabilitado, carregando, erro.
- Vazio, por tipo: primeiro uso (o que vai aparecer aqui + a acao para comecar), limpo pelo usuario
  (toque leve), sem resultado ("Nada encontrado para “x”" + outra tentativa), sem permissao (por que e
  como liberar), erro (o que falhou + "Tentar de novo"). Vazio mantem a moldura e o cabecalho.
- Carregando: layout final com barras cinza no tamanho real, sem shimmer e sem mover nada quando o dado
  chega. Atualizar dado ja na tela mantem o valor antigo.
- Erro: dentro do bloco que falhou, nunca derrubando a tela toda; frase do problema + saida; nunca a
  mensagem crua (TypeError, codigo).
- Pior caso realista (testar com estes, pela mesma entrada dos dados): nome de app enorme, titulo de
  musica com 80 caracteres, SSID longo, nome de arquivo sem espacos ("IMG_20250914_183022_HDR.HEIC"),
  palavra alema/composta, acentos e emoji (inclusive no inicio: charAt(0) quebra emoji), CJK, texto com
  quebra de linha num campo de uma linha, 0 / 1 / 1.000 itens, valor 142 % ou negativo, valor que muda
  99 -> 100, imagem que nao carrega (fallback), logo escuro no tema escuro, tempo "agora" (nao "0 s").
  Singular certo para 1 ("1 app", "1 tarefa").
- Texto: elide ou quebra dentro da caixa, nunca estoura; chip nunca espremido; largura do que e fixo
  (icone, avatar) nao encolhe.
- Acoes: botao fica ocupado/desabilitado enquanto a acao roda (sem clique duplo); arrastar interrompido
  (soltar fora, perder o foco, outra janela) limpa o estado e o proximo arraste funciona.
- Destrutivo: por ultimo, em Theme.danger, com a consequencia em palavras; desfazer quando seguro,
  confirmacao so para o irreversivel, nomeando a acao no botao ("Remover app", nunca "OK").

## 6. Movimento (decida nesta ordem)
1. Deve animar? 100+/dia (atalho de teclado, abrir launcher pelo teclado, navegar lista com setas,
   trocar de workspace) = nada ou quase imperceptivel; dezenas/dia (hover, alternancias) = sutil e
   rapido; ocasional (paineis, dialogos, notificacoes) = padrao; raro (primeiro uso, sucesso) = pode ter
   charme.
2. Proposito nomeado: feedback, consistencia espacial, indicar estado, evitar salto brusco, explicar.
   "Fica bonito" so vale no unico momento assinatura da superficie.
3. Curva: entrar/sair = ease-out (SetK.ease); mover na tela = ease-in-out forte; cor/hover = 140-180 ms;
   loop constante = linear. Nunca ease-in (InQuad/InCubic/...) entrando; nunca quique/elastico em UI.
4. Duracao: pressionar 100-160 ms; tooltip/popup 125-200; menu 150-250; painel/dialogo 200-300 (ate 450
   para coisa grande). Saida ~60-70 % da entrada.
5. Fisica: nunca escala 0 — entrar de 0.95-0.97 + opacidade. Popups e menus crescem do gatilho
   (transformOrigin do lado do botao/clique); dialogos centrais ficam no centro. Entrar e sair pelo
   mesmo caminho.
6. Pressionar: o que e clicavel responde no press (onPressed), nao no release: scale 0.97 (120-160 ms
   ease-out) ou fundo escurece. Linhas largas so escurecem.
7. Interrompivel: Behavior/NumberAnimation que reparte do valor atual; nunca bloquear clique durante
   animacao. Molas so para arrastar/gesto (amortecimento ~1.0; quique so se o gesto teve impulso).
8. Tooltip: atraso so no primeiro; vizinho em ate ~600 ms aparece na hora.
9. Lista que entra junta (ocasional): escalonar 30-60 ms, no maximo ~6 itens, sem bloquear.
10. Nada se move por cima de texto sendo lido; nenhum conteudo fica invisivel esperando animacao; sem
    loop que nao significa nada (ponto pulsando, brilho correndo); loops param quando escondidos.
11. Crossfade que mostra dois estados sobrepostos: um blur leve (2-4 px) durante a troca resolve.
12. Performance: animar so opacity/scale/x/y (acordeao e excecao); nada de width/height/radius por quadro
    no hover; animacao/Timer/Canvas parados quando escondidos (running/enabled ligados a visibilidade);
    layer/MultiEffect so enquanto o efeito esta ligado. Medir CPU parado (~2-5 %) depois de mudar.
13. Movimento reduzido: ainda nao existe opcao; quando existir, trocar deslocamentos por fade curto e
    parar loops, mantendo o feedback de estado.

## 7. Textos (pt-BR)
- Curto e da lingua do usuario; uma palavra por conceito no shell todo.
- Botoes: verbo + objeto, 1-3 palavras ("Remover app", "Escolher imagem"); nunca "OK", "Sim", "Enviar".
- Erro: o que falhou, por que (se ajuda) e como sair. Sem culpar o usuario, sem codigo.
- Ajuda responde a pergunta implicita, nao repete o rotulo; detalhe raro vai para o expansor/tooltip.
- Sem palavras de marketing (desbloquear, potencializar, sem esforco), sem "nao e so X, e Y", travessao
  com moderacao, aspas curvas e reticencias de verdade ("…").
- Ensinar no contexto: estado vazio e tooltip no ponto de uso; nada de tour obrigatorio; mostrar o
  atalho de teclado perto da acao quando existir.

## 8. Adaptacao
- Funciona em monitores e escalas diferentes, barras horizontais e verticais, varios monitores.
- Nada depende so de hover (tela de toque existe): a acao escondida no hover tem outro caminho.
- Area de clique >= 24 px mesmo quando o desenho e menor.
- Tema claro e escuro compostos, nao invertidos; nada de cor fixa que some num dos dois.

## 9. Ousadia (bolder / overdrive / delight)
- Um momento assinatura por superficie, feito direito; o resto quieto para ele aparecer.
- Antes de qualquer efeito ambicioso (shader, transicao cinematica, fisica), propor 2-3 direcoes ao
  usuario com custo de CPU e esperar a escolha.
- "Mais ousado" = levar uma parte ao nivel que o resto do sistema ja tem, com o vocabulario dele, sem
  cor/fonte/raio novos. Charme so em momentos que merecem (primeiro uso, conclusao, recuperacao).

## 10. Revisar (no resultado renderizado, nunca so no codigo)
- Um segundo: o que se ve primeiro? Cinco segundos: da para dizer o que e e o que fazer?
- Squint, bordas esquerdas, espaco/vazios, tipo (saltos claros), cor (onde esta o acento), mesmice.
- Heuristicas de Nielsen como checklist: status visivel, linguagem do usuario, saida facil (Esc, voltar,
  desfazer), consistencia, prevencao de erro, reconhecer em vez de lembrar, atalhos para quem sabe,
  minimalismo, erros com saida, ajuda no contexto.
- Personas: "Alex" (power user: atalhos, Esc, nenhuma animacao lenta no caminho), "Sam" (teclado e
  foco visivel, contraste, nada so por cor), "Riley" (vazios, textos enormes, 0/1/1.000).
- Severidade: P0 impede a tarefa; P1 dificulta muito/contraste ruim; P2 incomoda; P3 polimento.
- Capturas no tamanho real, poucas, juntando as checagens numa olhada; corrigir os 3 piores e olhar de
  novo; no maximo 3 rodadas. Dizer o que nao deu para verificar (hover, press, gestos) em vez de supor.
