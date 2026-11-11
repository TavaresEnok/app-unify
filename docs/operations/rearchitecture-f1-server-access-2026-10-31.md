# F1 C1/E4 — autorização atual nas entradas de servidor

Executor nominal: `executor-codex-task-283c3ce00d51-f1-server-access` (Codex programmer).
Data: 31/10/2026 UTC. Worktree isolada do contrato; sem commit, acesso produtivo,
usuários reais, deploy, migração, distribuição ou alteração Flutter.
Base conferida: HEAD `89faf2c`.
Firebase continua a única autoridade. Revisão independente deste bloco cabe ao
controlador após implementação/checks; nenhum PASS próprio é declarado.

## Retorno da revisão e correções desta tentativa

Parecer independente recebido: FAIL, achados F1-SERVER-R1/P1, R2/P2 e R3/P2.
R1: o lease exige `DocumentSnapshot.createTime` confiável e estritamente posterior
ao corte `RPC_SESSION_RULES_ACTIVE_AFTER` (UTC ISO com milissegundos), configurado
por operação após confirmar Rules estritas ativas. Corte ausente, inválido/futuro
ou criação sem prova nega execução. `createdAt` e `updateTime` não reabilitam fonte
prévia. O gate vale para trigger e recuperação; lock prévio preserva unknown,
sem replay. Nenhum corte produtivo foi configurado. O parâmetro é gate de rollout.

R2: contexto interno por execução identifica a falha no primeiro lookup de Auth
do handler, antes de qualquer efeito nos handlers atuais. Essa falha mantém
authorization-unavailable e termina sem efeito/repetição. O marcador é consumido
na entrada desse lookup e não pode ser fornecido pelo envelope; consultas
posteriores sem prova continuam unknown após possível efeito. Regressões usam
sendPushNotification real com falha na segunda consulta de Auth e conservam unknown
em falha posterior ao efeito. Handlers novos devem preservar a pré-condição de
primeiro lookup anterior a qualquer efeito.

Recuperação R3 autorizada pelo controlador neste contrato, incluindo containment.js,
index.js, testes do builder e contrato. R3 resolvido localmente: 503, falha de
transporte/timeout e resposta ilegível/incompleta da autoridade preservam 503
`authorization-unavailable`. Request/poll/cancel não expõem estado sem autoridade;
checks anteriores ao download/spawn/publicação mantêm a distinção. Após 202,
falha na publicação deixa recibo terminal seguro, sem URL nova e sem replay.
401/403, binding inválido e dono divergente continuam negados. Nenhum detalhe de
rede/token/payload entra na resposta. Callable real recebe unavailable por meio
do builder HTTP real conectado a autoridade simulada, sem fixture que injete 503
no callable. Harness compartilhado com containment evita duplicar mocks de segurança.
R1/R2, unknown/fencing, isolamento de ambiente e publicação atômica preservados.
O bloqueio por escopo das tentativas anteriores é histórico e foi removido pela
ampliação expressa; isso não equivale à aprovação da correção. Nova revisão
independente cabe ao controlador. Nenhum corte operacional foi configurado.

Pareceres independentes PASS de RPC `4804287`, estados `1ec8591` e consolidação
`0b36e36` recebidos no contrato do controlador. Preservados os recibos anteriores
e seus estados históricos. Configuração `b5ab897`, SGP `2ac2bc8` e builder
`447ca7a` continuam referências; nenhum merge é tratado como parecer.

## Contrato e critérios

HTTP verifica ID token com checkRevoked=true e lê Auth.getUser em cada request;
disabled e divergência de papel/tenant/SaaS são negados. Claims do token provam
a origem, claims atuais autorizam o acesso. req.user preexistente é descartado.
Nenhum cache de autorização foi adicionado. Dashboard reutiliza essa verificação
do middleware, mantendo seu cache de dados somente após autorização atual.
Proxy usa o mesmo princípio; rate limiter guarda apenas hint local para contagem,
sem estabelecer req.user. Nenhum providerId=admin implícito foi introduzido.

Login /check-cpf mantém senha SGP válida e contrato elegível como pré-condições.
UID determinístico existente subscriber:tenant:cpf é preservado, com isolamento
de CPF igual A/B. Claims explícitas são persistidas antes de emitir custom token.
Conta vazia só recebe vínculo após autenticação SGP; conflitos SaaS/provedor,
outro tenant/CPF e disabled não são sobrescritos. Lookup só cria usuário em
auth/user-not-found; corrida de criação relê e valida. Outage não recria usuário.
O caminho especial de login DEV que emitia token sem verificar senha SGP foi removido.
Migração de perfil já existente foi conservada, sem executar migração real.

Envelope RPC acrescenta session={authTime,issuedAt,role,providerId,superAdmin}.
Emissor web usa getIdTokenResult da identidade Firebase, timestamp de servidor e
UID do usuário atual. Rules exigem igualdade com auth_time/iat e scope do token,
UID de topo próprio e createdAt=request.time. Não há exceção para versões antigas.
As quatro cópias do contrato permanecem sincronizadas. Metadado é opcional no
tipo apenas para representar fontes legadas, nunca para autorizar execução.
Router normaliza a fonte canônica lida na transação e compara com a entrega;
o lease exige também createTime posterior ao corte de Rules verificado, conforme
correção R1 acima. Sem essa prova, nem uma session válida autoriza execução.
valida sessão/Auth atual antes de chamar handler, inclusive em retomadas.
authTime e issuedAt são comparados a tokensValidAfterTime; papel/tenant atual
devem coincidir com a origem. Não usa createdAt/body para provar sessão.
Lease, ownership, fencing, tombstone, atomicidade e unknown sem replay permanecem.
Uma negação antes do handler não cria efeito nem um falso resultado de sucesso.
Fontes antigas sem prova são negadas; efeitos anteriores incertos mantêm unknown.

uploadProviderLogo verifica bearer revogado, UID, sessão e autorização atual
antes de Storage/Firestore. generateApk continua encaminhando bearer ao backend
configurado; backend preserva SaaS, reautenticação e vínculo job/tenant/purpose.
Falha de autoridade é 503 authorization-unavailable em HTTP/proxy e código
authorization-unavailable no RPC na fronteira comprovadamente anterior ao efeito;
callable logo usa unavailable (HTTP 503). generateApk só o faz se receber 503 do
builder; a recuperação R3 preserva essa resposta pela cadeia HTTP real.
Não vira logout/revogação presumida nem sucesso com dados novos. Cliente RPC
rejeita uma única vez, orienta preservar dados e não repete mutação automaticamente.
Formulários mantêm a rejeição existente; não há limpeza de campos nesse adapter.
Não se registram tokens/senhas/CPF/payload nos novos caminhos de autorização.

## Matriz de cobertura e resíduos

| Transporte | Cobertura local | Resíduo / gate |
| --- | --- | --- |
| API HTTP administrativa/assinante | checkRevoked, disabled, Auth atual, papel e tenant; req.user forjado sem autoridade | disponibilidade do Auth é fail-closed; sem promessa de latência universal |
| Proxy autenticado | verificação separada da contagem; subscriber/provider/SaaS e tenant atuais | cache SGP existente é de dados/credenciais, não autorização; C5/C6 conservados |
| Login proxy | senha/contrato SGP, claims persistidas e conflito negado; UID preservado | clientes de login CPF sem senha precisam atualização/retirada; relogin SGP obrigatório para identidade sem base atual |
| RPC Firestore | envelope ligado às Rules, origem revalidada na execução e recuperação | emulator real obrigatório antes de implantação; SDKs legados sem envelope negados |
| Callable logo / builder | logo: sessão revogada/disabled e scope atuais; builder HTTP e callable reais preservam 503 seguro, negações e binding | R3 corrigido localmente, revisão independente pendente; sem prova de IAM/rede produtiva ou adoção |
| Firestore SDK direto | não recebe garantia deste bloco | clientes: read/create/update/delete; tickets e messages: read; notifications: read; incidents: read/write; diagnostic_results: read/write; users/audit_logs/maintenance_logs: read; wildcards de subcoleções provedores/providers para SaaS; function_responses: read. Dependem de claims/sessão antigas; precisam gate próprio |
| Storage SDK direto | não recebe garantia deste bloco | escrita/delete de logo/icon/banner/background e public_assets; ticket_attachments read/write/delete; diagnostic_reports read/create/update/delete. URLs de download compartilhadas exigem tratamento E9 próprio |
| Configuração pública | projeção pública existente conservada | provedores/providers, branding e public_assets públicos não são revogação privada; compatibilidade pública/mobile ainda pendente |

Flutter, admin_app e versões antigas de SDK que emitem function_requests sem
session não são compatibilizados nem editados. Inventário/atualização ou retirada
é gate antes do corte. Não há prova de adoção de APK, suspensão integral,
sair-de-todos nem revogação universal em 60 segundos. E4/G1/etapa A não concluídos.

## Verificação da recuperação R3 autorizada

Executor nominal: `executor-codex-task-283c3ce00d51-f1-server-access` (Codex programmer).
Uma rodada agrupada dos sete checks obrigatórios ao fim do bloco funcional;
nenhuma falha ou reexecução. Node 24 local no PATH somente dos comandos.
Os recibos 147 Functions / 84 API / 31 UI / 28 proxy + 6 skips abaixo continuam
históricos; a tabela seguinte registra a execução desta recuperação.

| Comando | Status | Resumo atual |
| --- | --- | --- |
| npm --prefix api-service test | PASS | 84/84, 11 arquivos |
| npm --prefix proxy-sgp test | PASS com skips | 28 aprovados, 6 skips Redis, 34 totais |
| npm --prefix functions run test -- --run | PASS | 162/162, 14 arquivos; 15 casos novos conectam callable real ao builder HTTP real e autoridade simulada |
| npm --prefix admin-painel run test | PASS | 31/31, 15 arquivos |
| node scripts/check-contracts.mjs | PASS | cópias sincronizadas |
| node scripts/check-secrets.mjs | PASS | 833 arquivos, exit 0 |
| npm --prefix services/apk-builder test | PASS | 24/24; 5 regressões novas com múltiplos cenários |
| functions/node_modules/.bin/tsc --noEmit -p functions/tsconfig.json | PASS | exit 0; sem emissão |
| git diff --check | PASS | exit 0 |
| Rules Firestore/Storage em emulador | PENDENTE | não executadas; implantação bloqueada por este gate |

Os cenários R3 cobrem 503/500, transporte/timeout e JSON/corpo inválidos, download
e spawn sem efeito sem autoridade, falha após download e antes do spawn, falha
antes da publicação síncrona/assíncrona, poll/cancel sem vazamento de estado nem
cancelamento indevido, 401/403, binding divergente e outro dono. Sucesso SaaS
atual funciona pela cadeia conectada. O teste de publicação assíncrona comprova
erro terminal seguro e ausência de URL nova. Os testes antigos de identidade,
segredos, ambiente e release atômico continuam na suíte, sem enfraquecer asserts.
Mock da autoridade é explícito e não usa Firebase/SGP reais; o endpoint fixo HTTPS
do callable é transportado ao servidor HTTP local somente pelo harness.

Implementação local concluída para encaminhamento ao controlador, sem autoaprovação.
Nova revisão independente obrigatória, compatibilidade dos clientes, Rules reais,
SDKs residuais e gates operacionais continuam pendentes. R3 corrigido localmente
não encerra C1/E4/G0/G1/E8 nem etapa A. Sem commit/deploy/push/distribuição.

## Verificação histórica após FAIL (tentativa anterior)

Rodada obrigatória agrupada única, sem falhas nem reexecuções. Node local 24 no
PATH apenas dos comandos; nenhuma instalação ou serviço iniciado.

| Comando | Status | Resumo |
| --- | --- | --- |
| npm --prefix api-service test | PASS | 84/84, 11 arquivos |
| npm --prefix proxy-sgp test | PASS com skips | 28 aprovados, 6 skips Redis, 34 totais |
| npm --prefix functions run test -- --run | PASS | 147/147, 14 arquivos; 12 regressões adicionais de corte/proveniência e fronteira de autorização |
| npm --prefix admin-painel run test | PASS | 31/31, 15 arquivos |
| node scripts/check-contracts.mjs | PASS | cópias sincronizadas |
| node scripts/check-secrets.mjs | PASS | scanner local, exit 0 |
| functions/node_modules/.bin/tsc --noEmit -p functions/tsconfig.json | PASS | sem emissão |
| git diff --check | PASS | exit 0 |
| Rules em emulador | PENDENTE | não executadas; gate de implantação preservado |
| Autoridade → builder → callable real com 503 | BLOQUEADO HISTÓRICO | R3 fora do escopo naquela tentativa; recuperado no contrato atual |

Fixtures do Firestore simulado agora incluem createTime canônico separado dos
campos do documento e preservado em updates. Regressões cobrem sessão forjada
após revogação em documento criado antes das Rules, trigger, recuperação sem
lock/com lock claimed/running, corte ausente/inválido/futuro/igual e criação
ausente/futura. Checagem C8 anterior e handlers reais continuam na suíte agrupada.
Status histórico daquela tentativa: blocked por R3, com implementação de R1/R2
e checks locais prontos para revisão do controlador. Sem commit/deploy/push.

## Verificação local anterior (preservada)

Harnesses reais de adapters usam Firebase/SGP/Firestore explicitamente simulados.
Cobrem token revogado, disabled, remoção de papel, troca de tenant, old-admin de
assinante, req.user forjado, indisponibilidade sem dados/efeitos, login novo/existente,
conflitos, senha incorreta/ausente, CPF A/B, fila antiga/retomada e callable.
Checks obrigatórios executados em rodada agrupada, com resultados finais abaixo. Regras foram
atualizadas com fixtures legítimas/forjadas; emuladores Firestore/Storage não estão
configurados nesta sessão. Execução real permanece pendente e não é aprovada.
Fixtures anteriores de UID forjado e comando administrativo de assinante também
recebem envelope válido para que a nova exigência de sessão não mascare essas
negações específicas; sintaxe verificada, sem alegar execução de Rules.

| Comando | Status final | Resumo |
| --- | --- | --- |
| npm --prefix api-service test | PASS | 84/84, 11 arquivos |
| npm --prefix proxy-sgp test | PASS com skips | 28 aprovados, 6 ignorados de integração Redis, 34 totais |
| npm --prefix functions run test -- --run | PASS | 135/135, 14 arquivos, incluindo C8 e callable real |
| npm --prefix admin-painel run test | PASS | 31/31, 15 arquivos; reusado após correções exclusivas no servidor |
| node scripts/check-contracts.mjs | PASS | quatro cópias sincronizadas; contrato não mudou após esse check |
| node scripts/check-secrets.mjs | PASS | scanner local, sem credenciais reais |
| TypeScript --noEmit API / Functions / painel | PASS | três projetos, sem emissão/build/deploy |
| git diff --check | PASS | sem erro de whitespace |
| Rules Firestore/Storage em emulador | PENDENTE | fixtures atualizadas; sem hosts de emulador configurados, não executado |

Primeira rodada: API 2 falhas (401 de sessão inválida esperado como 403), Functions
3 falhas (mock de user-not-found sem código Firebase, unavailable callable e
negação antes do handler agora sem efeito incerto), proxy 1 falha (assert de
ausência de leitura de perfil agora conflitando com login fiel que migra perfil).
Corrigidos os mocks/contratos esperados sem retirar as verificações de efeito,
segredo ou isolamento. Reexecução direcionada: API providers 23/23, Functions
router/clients/generateApk 53/53 e proxy wrapper 1/1. Depois da distinção explícita
de conflito 403 e negação de claims contraditórias SaaS+subscriber/providerAdmin,
foram reexecutadas as três suítes de servidor afetadas e tipos API/Functions;
os resultados finais são os da tabela. UI e contratos inalterados foram reusados.
Nenhuma suíte herdada de builder/Python/contato foi repetida neste bloco.
Refinamento final da fixture RPC comprovou também `issuedAt > revogação` com
`authTime < revogação`: renovar um token não reabilita a sessão de origem.
Reexecutado somente requestRouter: 38/38 PASS. Fixtures de Rules passaram
`node --check tests/firestore-rules.test.mjs`; sem execução do emulador.

## Responsáveis e rollout/rollback

Engenharia SaaS responde pela implementação e inventário de acessos/clientes;
controlador pela revisão independente e integração; operação somente após gates.
Antes de deploy: executar Rules em emulador real, revisar contratos de claims e
envelopes em conjunto, validar mobile/admin_app/público, mapear todos os SDKs
residuais, medir disponibilidade/latência e testar backup/rollback identificado.
Preparar clientes compatíveis antes de impor Rules; regras estritas e servidor
devem ser publicados em janela coordenada, após gates, sem permitir comandos
legados durante transição. A fila prévia exige inspeção/reconciliação, não replay
automático. Esta entrega não publica nenhum desses artefatos.
Confirmar primeiro as Rules estritas; só depois escolher corte futuro, configurar
`RPC_SESSION_RULES_ACTIVE_AFTER` e liberar envelopes criados após esse instante.
Até isso, a fila permanece fail-closed; não simular corte retroativo. Reversão de
Rules requer bloquear consumo e definir novo corte após verificá-las novamente.
Não restaurar/importar fila legada com createTime novo. A correção R3 local ainda
exige revisão independente antes de integrar/implantar a cadeia.

Rollback deve preservar checks de sessão/revogação, claims explícitas e negação
de envelopes legados. Restaurar código anterior que reabilite papel/tenant/claim
antigos é proibido: usar correção progressiva ou bloquear a entrada afetada.
Backup deve separar segredos e incluir versão identificada de contratos/regras;
restaurar dados não restaura autorização. Não reabrir CPF sem senha, token/build
de provedor, fallback SGP global ou lock liberável por cliente.
C1/E4/G0/G1 e E8 continuam abertos/parciais. Próximos lotes: E9 anexos/recurso;
compatibilidade pública/mobile/admin_app; C3/C7/C9/C10/C15/C16; orçamento/IAM/
backup/manifestos e mitigação E8 externa. Nenhuma implantação/distribuição aqui.
