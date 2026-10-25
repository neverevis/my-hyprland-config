# Atalhos de teclado

> Gerado por `scripts/gen-keys-doc.py` a partir da tabela em `hypr/quickshell.lua`. Não edite à mão.

O `install.sh` cria estes atalhos no seu Hyprland. Se uma combinação já era sua, ele pergunta se o shell substitui ou se o seu fica
(`./install.sh --keys` refaz a escolha). Para trocar uma tecla ou desligar um atalho, edite `~/.config/hypr/quickshell-keys.lua`:

```lua
return {
  conflicts = { settings = "replace", looks = "keep" },   -- replace: o do shell vence; keep: o seu vence
  override  = { settings = "SUPER + ALT + C",              -- outra combinação (texto ou lista)
                overview = false },                         -- false desliga
}
```

A coluna **id** é o nome usado nesse arquivo. Os atalhos com Super usam a tecla Windows.

## Painéis

| Atalho | Ação | id |
| --- | --- | --- |
| `Super + C` | Configurações do shell | `settings` |
| `Super + V` | Visuais (presets do shell) | `looks` |
| `Super + W` | Seletor de wallpaper | `wallpaper` |
| `Super + Shift + W` | Wallpaper aleatório | `wp_random` |
| `Super + Tab` | Launcher de aplicativos | `launcher` |
| `Super + A` | Painel Início | `home` |
| `Super (tocar e soltar)` | Painel Início ao tocar só na tecla Super (desligado por padrão) | `home_super` |
| `` Super + ` `` | Visão geral dos workspaces | `overview` |
| `Super + G` | Painel de jogo | `overlay` |
| `Super + K` | Teclado na tela | `osk` |
| `Super + Alt + D` | Editar widgets da área de trabalho | `desk_edit` |
| `Super + Shift + V` | Histórico da área de transferência | `clipboard` |
| `Super + .` | Emojis | `emoji` |
| `Ctrl + Alt + C` | Limpar notificações | `notif_clear` |
| `Super + Q` | Fechar o painel do shell aberto ou a janela ativa | `close` |

## Barras

| Atalho | Ação | id |
| --- | --- | --- |
| `Segurar Super` | Segurar Super: mostra barras escondidas e números dos workspaces | `bar_down` |
| `Super (tocar e soltar)` | Soltar Super: esconde de novo | `bar_up` |

## Sessão

| Atalho | Ação | id |
| --- | --- | --- |
| `Super + L` | Bloquear a tela | `lock` |
| `Ctrl + Alt + Delete` | Menu de energia | `power` |

## Capturas

| Atalho | Ação | id |
| --- | --- | --- |
| `Print` | Capturar uma área (copia e salva) | `shot` |
| `Super + Shift + S` | Capturar uma área (copia e salva) | `shot_freeze` |
| `Super + Shift + Alt + S` | Capturar uma área e buscar no Google Lens | `shot_lens` |
| `Super + Shift + T` | Copiar o texto de uma área (OCR) | `ocr` |
| `Super + Alt + T` | Traduzir a tela | `translate` |
| `Super + Shift + C` | Conta-gotas de cor (copia) | `picker` |
| `Ctrl + Alt + R` | Gravar a tela (de novo para parar) | `rec` |
| `Super + Shift + Alt + R` | Gravar uma área | `rec_region` |
| `Super + Alt + R` | Parar a gravação | `rec_stop` |

## Mídia

| Atalho | Ação | id |
| --- | --- | --- |
| `Ctrl + Super + Espaço` ou `XF86AudioPlay` ou `XF86AudioPause` | Tocar / pausar (funciona com a tela bloqueada) | `media_toggle` |
| `Ctrl + Super + =` ou `XF86AudioNext` | Próxima faixa (funciona com a tela bloqueada) | `media_next` |
| `Ctrl + Super + -` ou `XF86AudioPrev` | Faixa anterior (funciona com a tela bloqueada) | `media_prev` |
| `Ctrl + Super + Backspace` ou `XF86AudioStop` | Parar a mídia (funciona com a tela bloqueada) | `media_stop` |
