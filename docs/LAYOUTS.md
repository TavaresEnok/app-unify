# Layouts do app — matriz de features e dívida

## Matriz features × layout (medição corrigida)

Cobertura das 12 features "core" por layout, contando **qualquer** literal de rota
nos arquivos do layout (não só `onNavigate('...')`):

| Feature | L02 | L03 | L04 | L05 | L06 |
|---|:-:|:-:|:-:|:-:|:-:|
| dashboard (home) | — | ✓ | — | ✓ | ✓ |
| invoices | ✓ | ✓ | ✓ | ✓ | ✓ |
| internet_usage | ✓ | ✓ | ✓ | ✓ | ✓ |
| contract | ✓ | ✓ | ✓ | ✓ | ✓ |
| network_diagnostic | ✓ | ✓ | ✓ | ✓ | ✓ |
| speed_test | ✓ | ✓ | ✓ | ✓ | ✓ |
| trace_route | ✓ | ✓ | ✓ | ✓ | ✓ |
| wifi | ✓ | ✓¹ | ✓ | ✓ | ✓ |
| my_ip | ✓ | ✓ | ✓ | ✓ | ✓ |
| support | ✓ | ✓ | ✓ | ✓ | ✓ |
| notifications | ✓ | ✓ | ✓ | ✓ | ✓ |
| faq | ✓ | ✓ | ✓ | ✓ | ✓ |

¹ Adicionado nesta rodada (ver abaixo). "dashboard" ausente em L02/L04 é falso
positivo: nesses layouts a própria home é o dashboard.

## Correção de uma afirmação anterior

Numa análise anterior eu afirmei que **o layout_04 expunha só 4 de 12 features**.
**Isso estava errado — foi artefato de medição.** O regex usado só capturava
`onNavigate('rota')`, `'route': 'rota'` e `navigateTo('rota')`. Mas o layout_04
passa a rota como **3º argumento** de helpers (`_buildQuickAction(icon, label,
'speed_test')`, `_buildServiceItem(..., 'trace_route')`), que o regex não via.

Medindo por qualquer literal de rota, o layout_04 tem **11/12** — inclusive uma
seção "Serviços" completa (traceroute, consumo, meu IP, contrato, FAQ). Não havia
buraco de feature ali. Lição registrada: medir de novo antes de agir; a segunda
medição derrubou a primeira conclusão.

## O único desvio real corrigido

**layout_03 não oferecia o Wi-Fi** no dashboard, apesar de:
- ter o arquivo `layouts/layout_03/wifi_page.dart`,
- esse arquivo estar wired no `layout_selector.dart` (`l03_wifi`),
- o dispatcher (`painel_page.dart`) resolver a rota `wifi`.

Ou seja, a página existia e era alcançável por rota, mas nenhum botão levava até
ela — omissão acidental. Adicionado um item "Meu Wi-Fi" na lista `_features` do
`layout_03/dashboard_page.dart` (a lista é data-driven, então foi só mais uma
entrada, no mesmo padrão).

## A dívida que permanece (não é buraco de feature)

### Consolidação — passo 1 concluído (fundação + login)

- **`core/theme/layout_tokens.dart`** — fonte ÚNICA de aparência: `LayoutTokens.of(layoutType)`
  resolve o layout uma vez num objeto imutável (cores, flags dark/neumórfico,
  raio, decoração de card). Os valores espelham os antigos do `SharedThemeHelper`.
- **`SharedThemeHelper` agora delega** a `LayoutTokens` (mesmos valores) → zero
  mudança visual nos call-sites existentes; migração pode ser incremental.
- **`layoutTokensProvider`** (Riverpod) expõe os tokens do provedor atual.
- **`core/pages/unified_login_page.dart`** — um login temático substitui os cinco
  `layouts/layout_0X/login_page.dart` (≈1.700 linhas → 247). O `LayoutSelector`
  aponta todos os layouts para ele. Coberto por testes de tokens.

  ⚠️ Sem QA visual automatizado: o login unificado é consistente e correto, mas
  o visual difere dos 5 designs bespoke anteriores — validar em dispositivo.

**Próximos passos (mesma receita):** diagnóstico (6 telas → 1) e depois os
dashboards, sempre lendo `LayoutTokens` em vez de comparar `layoutType`.

### A dívida que permanece

O problema dos layouts **não** é feature faltando — é **custo de manutenção**:

- 5× `dashboard_page.dart` (680–1819 linhas), 5× `login_page.dart`, 5× `theme.dart`.
- ~100 comparações literais de `layout_0X` fora da pasta `layouts/`.
- Três estratégias concorrentes para o mesmo problema (duplicação total, páginas
  `shared_*` que ramificam por dentro, e o `LayoutSelector`).

Cada feature nova nasce 5–6 vezes, e um bug corrigido num dashboard fica nos
outros quatro. O alvo continua sendo **uma tela por feature, N temas** (design
tokens resolvidos num único lugar), com migração incremental: login → diagnóstico
→ dashboards. Isso é refatoração grande e arriscada sem QA visual — deve ser feita
por etapas, não num big-bang. Fica como trabalho dedicado, com este documento como
linha de base.
