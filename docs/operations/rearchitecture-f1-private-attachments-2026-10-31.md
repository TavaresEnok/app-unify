# Recibo F1/E9 — anexos privados — 31/10/2026

Executor: `executor-codex-task-04a9bc62a88b-f1-private-attachments` (conta
codex-programmer). Somente worktree `task-04a9bc62a88b-f1-private-attachments`.
HEAD inicial `804762d`, com servidor `858be72`; preservados configuração
`b5ab897`, SGP `2ac2bc8`, builder `447ca7a`, RPC `4804287`, estados `1ec8591`.
Pareceres independentes PASS dessas entregas, inclusive servidor, informados
pelo controlador no contrato atual; registros anteriores FAIL/correções/revisão
pendente continuam históricos. Esta implementação exige revisão própria.
Sem commit, merge, push, deploy, acesso produtivo/credenciais, migração ou APK.

Contrato e limites: [private-attachments](../contracts/private-attachments.md).
Responsável por revisão/integração: controlador do chat; operação futura:
engenharia SaaS, operador nominal de IAM/Storage/backup ainda a designar antes
de liberar rollout. E8 continua externo, intocado.

## Fontes atuais e consumidores reais

| Fonte | Escrita/leitura anterior | Tratamento neste lote |
| --- | --- | --- |
| AddTicketDialog | uploadBytes + getDownloadURL antes de CREATE_TICKET | ticket primeiro, PUT autenticado estável, falha parcial explícita |
| TicketDetailPage/ticketService | imageUrl renderizada diretamente | attachmentId e bytes privados; URL legada rotulada sem abrir |
| Functions handlers/tickets.ts | imageUrl aceita CREATE/REPLY; fallback CPF | rejeição de associação externa; UID e tenant canônicos |
| Express tickets.routes.ts | resposta administrativa; escopo frouxo providerId | papel administrativo explícito e rejeição de URL/path |
| DiagnosticHistoryPage/diagnosticService | listener diagnostic_results e reportUrl externo | reportAttachmentId por endpoint; desconhecidos não abertos |
| unified/core/services/diagnostic_report_service.dart | uploadReport/getDownloadURL, persistResult, attachReportUrl, texto com reportUrl e abertura de ticket | inventariado, sem alteração; gate SDKv2 |
| unified/core/widgets/diagnostic_report_sheet.dart | persistResult, attachReportUrl, sharePdf | consumidor confirmado, gate atualização/distribuição |
| unified/core/utils/pdf_generator_service.dart | compartilhamento PDF local | decisão futura sobre canal fora do app; sem link novo |
| unified/core/pages/diagnostics/diagnostic_{03,05,06,07}_page.dart | ações _sharePdf | consumidores confirmados; validar todas variantes/layouts no próximo lote |
| unified/core/models/diagnostic_report.dart | measurements serializa relatório inclusive customer/provider | dados do cliente não viram autoridade; schema/compatibilidade pendentes no mobile |
| admin_app/pages/tickets/tickets_list_page.dart | leitor de tickets | somente inventário; não alterado nem validado em dispositivo |
| Firestore/Storage rules + tests/firestore-rules.test.mjs | criação diagnóstico sem autoria e acesso storage por tenant | schema/autoria, namespaces privados e bypass de wildcard fechados |

Não confundir texto histórico de mensagem com associação autorizada: não se
apagam mensagens, referências ou arquivos antigos. URLs dentro de texto não são
convertidas em links pelo novo componente. Inventário por versões em campo,
objetos/generation/downloadTokens e compartilhamento externo segue pendente.

## Implementação e evidência

Express real com Auth/Firestore/Storage sintéticos: tabela SaaS, provider A/B,
subscriber A1/A2/B1, mudança de dono/claims/revogação, indisponibilidade, forjas,
pending/órfão, upload/commit falhos, geração/checksum e retry. Handlers Functions
reais: autoria, tenant, negação de CPF e associações/URLs. UI: controlador real
de draft e render harness dos eventos reais de criação/falha/retry/cancelamento/
troca de identidade; componente privado e capacidade blob com descarte tardio.
Não acessam conta/bucket real; não constituem ensaio de IAM/rede/produção.

| Comando | Resultado final | Limite |
| --- | --- | --- |
| `npm --prefix api-service test` | PASS, 103/103 em 12 arquivos | Express/handlers reais; autoridades e persistência sintéticas |
| `npm --prefix functions run test -- --run` | PASS, 171/171 em 15 arquivos | Reutilizado após mudanças finais exclusivas da API/fixtures/documentação |
| `npm --prefix admin-painel run test` | PASS, 41/41 em 19 arquivos | Controlador/render harness, sem browser/dispositivo completo; sem mudança web posterior |
| `node scripts/check-contracts.mjs` | PASS | Quatro contratos sincronizados; sem mudança contratual posterior |
| `node scripts/check-secrets.mjs` | PASS, 845 arquivos | Scan local; não prova IAM; nenhum segredo operacional consultado |
| `npm --prefix api-service run build` | PASS | Build final após ajuste do cap de memória |
| `npm --prefix functions run build` | PASS | TypeScript, sem publicação |
| `npm --prefix admin-painel run build` | PASS | TypeScript + Vite, 2616 módulos; saída local ignorada pelo Git |
| `node --check tests/firestore-rules.test.mjs` | PASS | Sintaxe JavaScript; não compila/executa Rules |
| `git diff --check` | PASS | Whitespace |

Execução inicial dos cinco checks, três builds e sintaxe não iniciou por Node
ausente no PATH (exit 127). Localizada instalação já existente em
`/home/app/.local/share/node24/bin`; comandos executados com PATH local, sem
instalação ou alteração de host. Primeira suíte API executada: 88 PASS/13 FAIL,
causados pelo mock de subcoleções que omitia o nome da coleção. Corrigido o
simulador, preservadas as asserções; repetição API 102/102 e build PASS.
Conferência final acrescentou retenção da vaga de memória durante handler ainda
ativo após desconexão e regressão do cap: nova repetição somente API/build,
103/103 e PASS. Suites Functions/painel e contratos não foram repetidos sem
mudança pertinente. Conferência final após atualização do recibo/fixtures:
scan PASS (845 arquivos), sintaxe PASS e whitespace PASS. Nenhum teste existente
foi relaxado para ocultar falha:
fixture antiga de upload SDK passa a esperar negação pela política v2.

Fixtures Rules usam projeto `demo-private-attachments`, incluem R1/envelope
atual e isolamento/wildcard. Java não disponível no PATH desta sessão; execução
real Firestore/Storage emuladores é **gate pendente antes de implantação**, não
PASS por inspeção. Os 10/10 Java21/demo informados anteriormente pelo gerente
são evidência histórica externa, não execução deste lote.

## Gates e continuidade

### Retorno de revisão F1-PRIVATE-R1/R2

Revisão independente anterior: **FAIL**, preservado neste registro. R1 identificou
leitura SDK por owner/providerId legados forjáveis; R2 reproduziu promoção indevida
de pending para quarantined e depois committed durante download de verificação.
Executor nominal deste retorno: `executor-codex-task-04a9bc62a88b-f1-private-attachments`.

R1: leitura Firestore de diagnóstico negada a todos assinantes, mesmo com schema
v2 e timestamps coincidentes; acesso privado a arquivo pelo backend com createTime
canônico. Admin do próprio tenant/SaaS mantidos. Fixtures adicionam legado com
providerId/createdByUid coincidentes e schemaVersion/createdAt forjados, incluindo
reportUrl, com negação a dono declarado/terceiro/cross-tenant. Novo SDKv2 deverá
respeitar ausência de listener direto de histórico para assinantes.

R2: reserva e commit validam state/generation; pending só sem generation,
committed só com geração string decimal positiva e igual ao objeto verificado.
Regressões HTTP Express reais alteram metadados durante I/O para ticket e relatório:
estado ausente/quarantined/null, pending com generation, committed sem geração,
geração numérica/vazia/zero/divergente. Exigem conflito, nenhum efeito associado,
metadado preservado, leitura sem bytes e retry sem promoção. Simuladores locais,
sem bucket/conta real.

Validação nova após R1/R2, com PATH Node24 local (uma rodada, sem repetição):

| Comando | Resultado |
| --- | --- |
| `npm --prefix api-service test` | PASS, 105/105, 12 arquivos |
| `npm --prefix functions run test -- --run` | PASS, 171/171, 15 arquivos; executado novamente neste retorno |
| `npm --prefix admin-painel run test` | PASS, 41/41, 19 arquivos; executado novamente neste retorno |
| `node scripts/check-contracts.mjs` | PASS |
| `node scripts/check-secrets.mjs` | PASS, 845 arquivos no momento do scan |
| `npm --prefix api-service run build` | PASS |
| `npm --prefix functions run build` | PASS |
| `npm --prefix admin-painel run build` | PASS, TypeScript + Vite, 2616 módulos |
| `node --check tests/firestore-rules.test.mjs` | PASS, somente sintaxe da fixture |
| `git diff --check` | PASS |

Os resultados da primeira implementação acima permanecem históricos. Nenhuma
falha de check nesta rodada; nova revisão independente ainda pendente.

Java novamente ausente (`java -version`: exit 127); não executados emuladores.
Fixtures não aprovam Rules por inspeção; execução demo real continua gate.

1. Controlador revisa diff/evidência independentemente; nada integrado aqui.
2. Testar Rules em emuladores demo e jornadas completas SaaS/provedor/assinante,
   bucket privado/IAM sem tokens automáticos, capacidade/memória/retensão.
3. Engenharia atualiza SDK/mobile/admin_app e distribui versões compatíveis;
   SDKv1 sem ownership confiável não recebe fallback público/por tenant.
4. Coordenar Rules verificadas e corte PRIVATE_DIAGNOSTIC_RULES_ACTIVE_AFTER
   posterior, SDKv2 e backend sem habilitar antecipadamente. Nenhum corte real
   configurado; teste usa somente env sintética no próprio processo.
5. Inventariar/classificar/backup/reconciliar objetos e tokens antigos segundo
   procedimento seco do contrato; operador nominal ainda deve ser designado.
6. Backup/rollback seguro antes de deploy futuro; não reabrir segredos, acesso
   alheio, sessão revogada ou capabilities antigas para recuperar cliente legado.

E9/C1/E4/G0/G1 permanecem parciais; etapa A e SDK não têm autorização universal.
E8 externo não alterado. Próximos lotes: publicconfig/mobile/admin_app, revogação
SDK, C3/C7/C9/C10/C15/C16 e F0 orçamento/IAM/backup/manifestos. Nenhum serviço,
engine, comando RPC, dependência pesada ou migração introduzido.
