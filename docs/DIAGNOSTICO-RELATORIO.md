# Diagnóstico de rede → relatório → atendimento

Como funciona o fluxo que o assinante dispara ao final de um diagnóstico.

## Fluxo

```
Diagnóstico conclui
   ↓
DiagnosticReport.fromState()      ← modelo TIPADO (fim do parse de string)
   ↓
DiagnosticVerdictEngine.evaluate() ← laudo local, determinístico
   ↓
showDiagnosticReportSheet()        ← ponto único para as 6 telas
   ↓
┌──────────────────────┬────────────────────────┬──────────────────┐
│ WhatsApp do suporte  │ Abrir chamado          │ Compartilhar PDF │
│ (upload + link)      │ (upload + link + tick) │ (share sheet)    │
└──────────────────────┴────────────────────────┴──────────────────┘
   ↓
provedores/{id}/diagnostic_results  ← histórico (painel admin já lê)
```

## Arquivos

| Arquivo | Papel |
|---|---|
| `core/models/diagnostic_report.dart` | Modelo tipado da execução (ping, wifi, ONU, velocidade, traceroute, cliente, provedor) |
| `core/services/diagnostic_verdict.dart` | Motor de laudo local com limiares documentados |
| `core/utils/pdf_generator_service.dart` | Gera o PDF a partir dos dados tipados |
| `core/services/diagnostic_report_service.dart` | Upload, WhatsApp, chamado e persistência |
| `core/widgets/diagnostic_report_sheet.dart` | UI de entrega, chamada pelas 6 telas |

## Decisões que valem registrar

**WhatsApp carrega link, não arquivo.** Um deep link `wa.me` só aceita texto — não existe forma de anexar um arquivo a um contato específico programaticamente. Por isso o PDF vai ao Firebase Storage e a mensagem leva a URL. O botão "Compartilhar PDF" continua existindo para quem quiser enviar o arquivo em si (aí o usuário escolhe o contato).

**A URL do Storage é acessível a quem tiver o link.** `getDownloadURL()` devolve uma URL com token que ignora as regras de leitura — é isso que permite o atendente abrir o PDF pelo WhatsApp sem estar logado. Consequência: o relatório **não** traz o CPF completo (`ReportCustomer.maskedDocument`); a identificação para o SGP é o número do contrato.

**O laudo é local e determinístico.** O endpoint `/diagnostic/analyze` do proxy devolve um texto fixo ("Sinal óptico abaixo do ideal -25dBm") independentemente da medição — ele continua existindo por compatibilidade com apps antigos, mas **não** é usado por este fluxo. Cada conclusão do laudo sai de um número medido, com limiar explícito em `DiagnosticVerdictEngine` e coberto por teste.

**Separar "dentro de casa" de "rede do provedor".** O motor compara o ping ao gateway com o ping externo: roteador respondendo bem + internet ruim aponta o provedor (`needsProviderSupport = true`); roteador ruim aponta Wi-Fi/roteador. Wi-Fi fraco também rebaixa a severidade de "velocidade abaixo do contratado", para não gerar chamado indevido.

## Limiares do laudo

| Métrica | Atenção | Crítico |
|---|---|---|
| Sinal óptico RX | < -20 dBm ou > -8 dBm | < -25 dBm |
| Latência ao gateway | > 40 ms | roteador sem resposta |
| Perda externa | ≥ 2% | ≥ 5% |
| Latência externa | > 150 ms | sem resposta |
| Jitter | > 30 ms | — |
| Sinal Wi-Fi | ≤ -70 dBm | ≤ -80 dBm |
| Velocidade vs plano | < 60% | < 30% (se o Wi-Fi estiver bom) |

A velocidade contratada é inferida do nome do plano (`VIBE 500 MEGA` → 500 Mbps, `FIBRA 1 GIGA` → 1000). Sem número reconhecível, a verificação de velocidade é ignorada.

## Mudanças de infraestrutura

- `storage.rules`: novo caminho `providers/{providerId}/diagnostic_reports/{fileName}`, aceitando apenas `application/pdf` até 5 MB, escrita pelo próprio cliente ou admin do provedor.
- `diagnostico_service.dart`: `_updateTestState` passou a aceitar `metrics` — os valores tipados de latência/jitter/perda, que antes eram calculados e descartados dentro de um texto formatado.
- `shared_traceroute_page.dart`: migrado de `Process.run('ping')` (não funciona no iOS) para o endpoint `/diagnostic/traceroute`, o mesmo do diagnóstico completo.

## Wedge — o momento "minha internet está ruim" (estudo §4)

Três melhorias que aprofundam o diferencial sem inchar o app:

**1. Modo rápido (§4.1).** `DiagnosticoService.runQuickCheck()` roda só o subconjunto que decide o veredito — sinal ONU + ping ao roteador + ping externo (+ Wi-Fi) — em ~10-15s. Fica de fora o que é lento/pesado: varredura de LAN, traceroute e os dois speed tests. Ponto de entrada ÚNICO: botão "Está ruim agora? Verificar conexão" no topo da tela de suporte (`shared_suporte_page.dart`), disparando `runQuickDiagnostic()` (`core/widgets/quick_diagnostic_launcher.dart`), que roda headless com progresso e abre a folha de resultado. O laudo completo continua em `runAllTests()`.

**2. Deflexão-first (§4.2).** A folha de resultado (`diagnostic_report_sheet.dart`) reordena as ações pelo veredito:
- **Tudo OK** → sem acionar suporte, só compartilhar.
- **Problema do cliente** (Wi-Fi/roteador) → a auto-resolução é primária ("tente as sugestões primeiro"); falar com o suporte vira saída secundária. Evita visita à toa.
- **Problema do provedor** (fibra/rede) → enviar ao suporte é a ação primária.

**3. Fechar o loop / métrica de ROI (§4.4).** O resultado é persistido em `diagnostic_results` **na abertura da folha** (não só quando há ação), então a métrica conta inclusive os casos que o cliente auto-resolveu. O painel do provedor (`DiagnosticHistoryPage`) foi realinhado ao schema real que o app grava (antes esperava um schema morto — `downloadSpeed`, `healthScore` — que teria quebrado) e ganhou um cabeçalho de métricas: total, **% resolvidos sem visita**, encaminhados ao provedor e críticos. É o número que prova a redução de visita técnica.

> Nota de dedup: o histórico é gravado uma vez (`persistResult` → id) e a URL do PDF é anexada depois via `attachReportUrl`, evitando documento duplicado quando o cliente publica o relatório.

## O que ficou pendente

- **Histórico no painel do provedor**: a coleção `diagnostic_results` agora é escrita, e o painel já tem a tela que a lê — vale conferir se os campos exibidos batem com o que gravamos (`severity`, `headline`, `findings`, `measurements`, `reportUrl`).
- **Retenção dos PDFs**: não há expiração configurada no Storage. Considerar uma regra de ciclo de vida (ex.: apagar após 90 dias).
- **Número de WhatsApp**: depende de `supportContacts` ter um item com `type: 'whatsapp'`. Sem isso o botão aparece desabilitado.
