# F1 E1/C14 — estados honestos (31/10/2026)

## Ficha atual de rastreabilidade — consolidação documental

Implementação `1ec8591`, integrada pelo controlador em `385ea65` (Git conferido).
O recibo abaixo registra revisão pendente; parecer independente não anexado
nesta worktree deve ser vinculado pelo controlador, sem inferir aprovação pelo
merge. UI28/proxy26 aprovados + seis skips/contato3, tipos UI, scan 821 arquivos e
whitespace são resultados reutilizados, sem reexecução nesta consolidação.
Não implantado/distribuído; E1/C14 permanecem abertos até aceite completo.
Contato sem destino/propriedade/recebimento comprovados continua indisponível;
501 e estados exigem compatibilidade com consumidores/versões efetivos.
Seções 9/15.10 do [plano](../plano-rearquitetura-2026-10-30.md) vinculam os gates.
Executor documental: `executor-codex-task-f73d0e4cd415-f1-evidence-update`;
revisão desta adição cabe ao controlador. Histórico de implementação preservado.

## Recibo histórico de implementação

Executor nominal: Codex, programador executor desta tarefa delimitada
`f73d0e4cd415-f1-honest-states`, nesta worktree. Implementação local, sujeita à
revisão independente do controlador. Continuação das fases 0/1 e matriz 15 do
plano de 30/10/2026; o plano e evidências de outros executores não foram editados.
Não foram encontrados AGENTS.md na worktree ou nos ancestrais consultados.

## Indicadores e estados

Origem consultada: `api-service/src/services/dashboardData.ts` e sua implementação
equivalente em `functions/src/app/dashboardData.ts`. As páginas usam as rotas
panel da API via `useApi` e mantêm a autenticação
existente, sem alterar autorização, saída SGP ou coletas.

| Indicador | Significado/origem | Período e limites |
| --- | --- | --- |
| Provedores SaaS | Quantidade de documentos em Firestore/provedores | Total consultado, sem período; não prova atividade |
| Clientes SaaS | Quantidade de documentos em Firestore/clientes | Registros totais, não instalações nem clientes ativos |
| Clientes do provedor | totalClients: count de clientes filtrado por providerId | Total cadastrado, sem período; não usa status/FCM como instalação |
| Tickets abertos, ambos | count em tickets com status Aberto ou Em Andamento; filtro de tenant no provedor | Fila consultada, sem período |
| Notificações SaaS | count em notifications com createdAt >= início da janela móvel de 24h do backend | Registros criados, não entrega/leitura |
| Clientes por provedor | count de clientes filtrado por providerId de cada provedor | Consulta agregada, até seis provedores exibidos, sem série temporal; zero tem barra de largura zero |
| Tickets recentes | Até cinco registros, ordenados por updatedAt, filtrados no provedor | Não é histórico completo. Data de ticket vem do registro; ausente é N/A |
| Instalações, adesões, nota Play Store | Sem medição disponível | N/D; retirados estimativa 68%, trends 6/4 e série fixa de 12 semanas |

Nenhuma consulta é rotulada como tempo real. Não se gera timestamp de upstream
com o relógio local. StatsCard não gera badge Atual, tendência ou frescor por
ausência de metadados. Contagem ausente/inválida é N/D; zero só é renderizado a
partir de número inteiro não negativo recebido.
As rotas panel mantêm cache agregado de até 10 segundos por escopo global/tenant,
com autorização antes da leitura. Retry limpa o prefetch do cliente; não invalida
esse cache do servidor nem transforma sua resposta em medição de frescor.

O controlador de estado tem loading, ready, error, stale e denied. Vazio é
representado por lista explicitamente retornada vazia em ready; ausência de lista
mostra indisponibilidade. Falha inicial não cria contagens nem listas vazias.
Recarregar é explícito e a navegação permanece renderizada. Falha de atualização
mantém somente dados da mesma identidade com aviso de desatualização, inclusive
durante a atualização seguinte.

Cada identidade de sessão (objeto autenticado), papel e tenant recebe controlador
novo, ocultando imediatamente dados anteriores. Cleanup cancela publicação de
respostas antigas, e geração descarta pedidos concorrentes ultrapassados.
Prefetch de dashboard é limpo antes das consultas para não reapresentar um cache
anterior na troca de sessão/escopo ou no retry. Nenhuma reautenticação é relaxada.

## Diagnóstico: contrato e consumidores

`POST /diagnostic/analyze` mantém o middleware Firebase e os checks existentes de
CPF/papel/tenant. Uma chamada autorizada recebe HTTP 501:

```json
{"error":{"code":"DIAGNOSTIC_UNAVAILABLE","message":"Análise de diagnóstico indisponível. Nenhuma análise medida foi realizada."}}
```

Não há data, laudo, categoria, confidence, solução, prioridade ou timestamp.
Nenhum SGP é chamado pelo handler. A rota permanece no catálogo como manutenção
temporária indisponível, com retirada planejada após gate legado/mobile. O
envelope error.message é o padrão compreensível das outras falhas do proxy.
As rotas ONU e outros endpoints não foram alterados.

| Referência no código atual | Relação e limite |
| --- | --- |
| proxy-sgp/index.js e contracts.js | Implementação/contrato da rota mantida; não é evidência de consumidor ativo |
| unified/core/services/diagnostic_verdict.dart | Comentário referencia a antiga rota; DiagnosticVerdictEngine avalia DiagnosticReport localmente |
| unified/core/widgets/diagnostic_report_sheet.dart | Chamada real a DiagnosticVerdictEngine().evaluate(report); preservada |
| admin-painel/features/diagnostics/diagnosticService.ts | Assina diagnostic_results no Firestore; não chama analyze |
| api-service/src/routes/diagnostics.routes.ts | Fachada de diagnóstico; busca textual não encontrou consumidor analyze |
| Apps legados/APKs distribuídos | Inventário de versões e tratamento de 501 ainda pendentes; nenhuma compatibilidade distribuída é afirmada |

Gate antes de retirada/distribuição: responsável deve identificar versões e
consumidores efetivamente ativos, verificar apresentação de error.message/501 em
cada versão suportada e definir prazo de retirada. Flutter não foi alterado nem
testado neste lote. O motor local não é substituído por esta indisponibilidade.

## Contato C14

O HTML continua sem destino verificado (`data-contact-url=""`). Exibe canal
indisponível antes e depois de submit, mantém o campo e não simula espera, envio,
agendamento, recebimento ou reset. A âncora contact aponta ao formulário.

O módulo permite configurar futuramente uma página HTTPS de contato externo:
valida URL absoluta, protocolo, host e ausência de credenciais/query/fragmento.
Nenhum canal foi inventado ou configurado. Abrir página externa não encaminha o
email digitado; não há persistência, coleta adicional, endpoint novo nem log de
campo. Abertura permitida informa explicitamente que nenhuma mensagem foi enviada
pelo formulário e exige confirmação no canal; bloqueio/exceção informa falha e
preserva campo. Validação sintática não comprova propriedade do destino.

C14 permanece contido e aberto: responsável comercial precisa validar destino,
propriedade, jornada de contato e recebimento controlado antes de habilitar canal.
Preços e demais textos comerciais não foram reformulados.

## Verificação e limites

Testes novos executam o controlador real e renderizam componentes React em SSR
com seus snapshots de estado (sem snapshots textuais de implementação). Cobrem
zero/vazio medidos, dados ausentes, erro inicial, stale, retry, N/D, papéis,
cancelamento e respostas concorrentes/atrasadas entre controladores de identidade.
As páginas usam harness de hook de estado para renderização; não é E2E de browser
nem prova da emissão real de claims ou de Firestore em produção.

O teste HTTP inicia o app Express real apenas em loopback, com Firebase, Redis,
PostgreSQL e transporte SGP explicitamente simulados. Testa identidades sintéticas
A/B/SaaS, 501 estável, 401 sem token/inválido, 403 por tenant/CPF divergente e 400
por CPF ausente; mede zero efeitos SGP/PG/Firestore nesse percurso.

Contato usa harness EventTarget com eventos submit canceláveis e o listener real:
destino ausente/inválido, janela permitida/bloqueada/exceção, campo preservado,
email não encaminhado e exportação browser carregada via VM. Não valida
recebimento externo ou comportamento de APK.

Rodada obrigatória iniciada após completar o bloco funcional. A primeira
tentativa de cada comando (e do TypeScript adicional) terminou com código 127:
Node não constava no PATH. Não executou testes. Foi usado o runtime já instalado
em /home/app/.local/share/node24/bin, ajustando PATH somente nos processos.

| Comando | Resultado desta execução |
| --- | --- |
| npm --prefix admin-painel run test | PASS: 14 arquivos, 28 testes (8 novos neste escopo) |
| npm --prefix proxy-sgp test | PASS: 32 testes, 26 aprovados, 6 skips existentes de integração com armazenamento; nenhum serviço real foi ativado |
| node --test landing-page/contact-form.test.js | PASS: 3 testes |
| node scripts/check-secrets.mjs | PASS: 821 arquivos verificados |
| npm --prefix admin-painel exec -- tsc --project admin-painel/tsconfig.json --noEmit | PASS: check adicional de tipos |

O teste HTTP de indisponibilidade é novo; os demais testes do proxy foram
reexecutados por esse comando, com os seis skips reportados acima. Nenhum recibo
de teste anterior foi apresentado como reexecução. Após a rodada com runtime
resolvido não houve mudança de código: somente conclusão desta evidência e
metadados de entrega. `git diff --check` também passou.

Não houve deploy, push, merge, commit, migração, distribuição, acesso a produção
ou uso de credenciais/API paga. Token SGP privado intocado; E8 permanece aberto.
E1/C14/G1 não são encerrados integralmente por estes testes locais.
