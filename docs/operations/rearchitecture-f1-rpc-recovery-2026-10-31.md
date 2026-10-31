# F1 / C8 — recuperação conservadora do RPC legado

Executor nominal: `executor-codex-task-f73d0e4cd415-f1-rpc-recovery`.
Base informada: HEAD integrado `a48b2d8`; entregas anteriores preservadas.
Escopo: implementação local nesta worktree; revisão independente pelo controlador.
Não houve deploy, migração, produção, credenciais reais, serviços novos, push ou commit.
O segredo privado SGP e E8 permanecem intocados. Este documento não encerra C8,
F0/F1 ou G1 e não altera o plano nem evidências de outros executores.

## Classificação de todos os handlers

| Comando | Política de retomada após início | Motivo |
| --- | --- | --- |
| GET_DASHBOARD_DATA | Leitura repetível | Reconsulta dados e autorização SaaS atual |
| GET_PROVIDER_DASHBOARD_DATA | Leitura repetível | Reconsulta tenant e autorização atual |
| GET_ALL_TICKETS | Leitura repetível | Sem mutação |
| GET_PROVIDER_TICKETS | Leitura repetível | Sem mutação, acesso atual do provedor |
| LIST_ADMIN_USERS | Leitura repetível | Sem mutação, papel SaaS atual |
| LIST_PROVIDER_CLIENTS | Leitura repetível | Sem mutação, tenant atual |
| GET_CLIENT_DETAILS | Leitura repetível | Sem mutação, tenant atual |
| LIST_PROVIDER_BACKUPS | Leitura repetível | Sem mutação, acesso atual |
| SGP_API_PROXY: get/get_single/status | Leitura repetível | Cache/consulta de estado; status não dispara sync |
| SGP_API_PROXY: sync | Efeito incerto | POST inicia trabalho externo |
| UPDATE_PROVIDER_CONFIG | Efeito incerto | Repetição pode sobrescrever edição concorrente |
| UPDATE_PROVIDER_DETAILS | Efeito incerto | Mutação com tempo/edição concorrente |
| CREATE_PROVIDER | Efeito incerto | Marcador por ID não torna leitura+escrita atômicas |
| DELETE_PROVIDER | Efeito incerto | Exclusão parcial/cascata e Auth |
| SEND_PUSH_NOTIFICATION | Efeito incerto | FCM e journal sem transação comum |
| SEND_SCOPED_NOTIFICATION | Efeito incerto | FCM e journal sem transação comum |
| SEND_SCOPED_NOTIFICATION_SEGMENTED | Efeito incerto | Lotes FCM parcialmente enviados |
| CREATE_TICKET | Efeito incerto | Documentos separados; pode reabrir/sobrescrever ticket |
| REPLY_TO_TICKET | Efeito incerto | Mensagem com ID automático |
| UPDATE_TICKET_STATUS | Efeito incerto | Pode sobrescrever status posterior |
| DELETE_TICKET | Efeito incerto | Exclusão recursiva parcial |
| CREATE_ADMIN_USER | Efeito incerto | Auth+claims+Firestore e compensação parcial |
| DELETE_ADMIN_USER | Efeito incerto | Auth+Firestore separados |
| SET_SUPER_ADMIN_BY_EMAIL | Efeito incerto | Pode restaurar privilégio revogado |
| DELETE_CLIENT | Efeito incerto | Pode excluir cache recriado posteriormente |
| BACKUP_PROVIDER_CONFIG | Efeito incerto | Mesmo ID não fixa conteúdo/tempo do backup |
| RESTORE_PROVIDER_CONFIG | Efeito incerto | Reaplicação pode sobrescrever edição posterior |
| DELETE_PROVIDER_BACKUP | Efeito incerto | Pode apagar documento recriado |
| Desconhecido | Negado | Sem handler/política implícitos |

Nenhuma mutação atual tem prova suficiente de idempotência para replay automático.
Não há promessa de exatamente uma vez, cancelamento ou desfazimento de SGP/FCM/build.
O callable de build é independente deste roteador e não foi alterado.

## Posse, identidade e atomicidade

`function_requests` é a fonte canônica, lida na transação de claim. Regras atuais
permitem somente criação autenticada pelo próprio UID, sem alteração posterior.
Entrega e documento são comparados em memória depois da normalização; não há hash
de payload. Lock guarda apenas comando, UID, versão `updateTime` da origem,
política, owner aleatório, fence crescente, estado e expiração. A versão vincula
o payload original sem replicar conteúdo privado. Mudança da origem impede start,
renovação e conclusão e exige reconciliação após expiração. UID aninhado só é
aceito pelo contrato legado na ausência do UID superior; divergência é rejeitada,
e o campo aninhado é removido antes do handler. Papel/tenant do payload nunca
definem identidade. A confiança no UID superior depende das regras de criação
existentes: isto não autentica produtores Admin SDK arbitrários.

Transições: inexistente → claimed → running → completed/unknown. Lease de 120 s,
heartbeat de 30 s com uma renovação em voo; encerramento limpa timer e aguarda a
renovação. Start é persistido antes de chamar o handler. Cada operação de posse
revalida owner, fence, origem e lease. Resposta e estado terminal compartilham a
mesma transação, sem `.set` independente. Helpers sem uso que permitiam escrita
sem fencing foram removidos; writeResponse constrói somente envelopes, com
regressões de formato/TTL/limite de tamanho preservadas. Erros de leitura/claim/commit propagam; duplicidade só decorre
de estado efetivamente lido. Conflitos transacionais reexecutam apenas persistência,
nunca o handler. Auditoria RPC recebe envelope sem payload; logs RPC não incluem
erros dinâmicos, resultado, credenciais ou payload privado. Rejeições propagadas
ao runtime usam erro retryable estático sem causa privada anexada, pois o próprio
runtime também pode registrar invocações rejeitadas.

| Interrupção | Retomada |
| --- | --- |
| Antes do claim | Redelivery com retry ativado ou descoberta agendada recente |
| Depois do claim, antes do start persistido | Nova posse após expiração; handler revalida autorização atual |
| Depois do start, antes de qualquer efeito | Leitura pode retomar; mutação fica unknown conservadoramente |
| Depois do efeito, antes da resposta | Mutação fica unknown, sem nova invocação |
| Commit aplicado, confirmação perdida | Resposta/tombstone lidos impedem repetição |
| Perda de heartbeat/posse | Invocação não publica resultado; recuperação classifica marcador durável |

Não se tenta cancelar um efeito já iniciado. Uma leitura suspensa pode coexistir
com nova leitura, mas somente o novo proprietário publica. Para mutações expiradas
em running não se concede novo efeito. Falha de persistência após efeito preserva
running até reconciliador gravar unknown; se o banco continuar indisponível a
incerteza continua no marcador original, sem falso sucesso. Erro lançado por
handler mutável também vira unknown, inclusive negação anterior ao efeito: a
fronteira conservadora é a invocação, pois handlers não oferecem recibo transacional
de efeito. Isso pode demandar intervenção mesmo quando nada ocorreu.

Handlers reais mantêm suas verificações de Auth/papel/tenant e documentos de
domínio antes do efeito, inclusive em retomadas. Não se modifica autorização de
domínio. A revogação não cancela um efeito que já passou pela autorização; esse
limite temporal preexistente não é resolvido por lease.

## Recuperação e retenção

`recoverFunctionRequests` é exportado em `index.ts`: agendamento real a cada cinco
minutos, `maxInstances: 1`, timeout de 540 s e os mesmos secrets declarados do
trigger (nenhum valor lido nesta execução). Consulta até 25 leases expirados e
25 locks antigos com claimedAt anterior a dez minutos. Locks de formato antigo
sem prova de início ficam unknown; resposta existente estabelece tombstone.
Depois percorre até 25 origens recentes com createdAt entre agora−7 dias e agora,
ordenadas por createdAt/ID, com checkpoint persistente em maintenance_logs.
Não há nova fila ou banco; checkpoint contém somente posição. Limite de 40 s
impede novos inícios após o orçamento, sem interromper handler em andamento.
Uma operação já iniciada pode usar o timeout restante; a invocação pode ser
interrompida pelo runtime e será classificada pelo mesmo protocolo.

Consultas usam índices simples automáticos e ordenação por nome do documento;
nenhum índice composto novo foi necessário localmente. Confirmar índices reais
no gate de homologação. Falhas de consulta propagam ou adiam aquele item sem
arquivamento; falha na descoberta recente mantém checkpoint anterior ao item.
Não há retry quente em loop. Congestionamento persistente no primeiro lote pode
exigir engenharia; o reconciliador não promete SLA de esvaziamento sob falha
contínua, backlog acima da capacidade ou handlers lentos. Origens sem createdAt
ou anteriores à janela e sem lock dependem de redelivery/inspeção SaaS.

Cleanup diário processa no máximo 100 respostas expiradas por execução. Só remove
origem/resposta concluída, com revalidação transacional, mantendo tombstone de
conclusão permanente contra redelivery depois do TTL de sete dias. Não apaga locks
vivos, pending, unknown ou origem necessária à reconciliação. Resposta unknown
usa ErrorCode legado `conflict`, `reconciliationRequired: true`, mensagem explícita
para não reenviar e não recebe TTL. Nenhum endpoint permite ao usuário liberar
posse, declarar sucesso ou repetir efeito.

Engenharia SaaS deve investigar unknown por ID usando recibos reais de domínio,
Auth, provedor/SGP/FCM quando disponíveis. Sem prova externa, manter desconhecido
e bloquear repetição; FCM pode não oferecer prova individual suficiente. Não
reescrever locks para liberar replay nem executar manualmente efeitos como parte
desta entrega. Correção de domínio, eventual nova operação e descarte de evidência
exigem procedimento próprio revisado, autorização atual e avaliação do caso.
Retenção permanente de tombstones e unknown é intencional; política de arquivo,
custo, proteção e eventual descarte por janela comprovada fica para operação SaaS.
Não configurar TTL automático em locks/unknown/origens pendentes.

## Aceite local, testes e riscos

Regressões usam roteador, lease, handlers reais de leitura/FCM e callbacks reais
de trigger/agendamento, com Firestore sintético. A simulação verifica versões de
leituras no commit, descarta writes em falha, publica atomicamente e repete callback
sob conflito; proíbe leitura após escrita. Relógio/timers controlados cobrem corrida,
commit falho/ACK perdido, claims, leases, dono antigo, heartbeat e perda de posse,
revogação, tenant forjado, legado, recuperação antes/depois do efeito e cleanup.
Não é emulador Firebase: índices, Rules/IAM, timeout/redelivery reais e semântica
distribuída precisam de homologação. Não há serviço externo exigido pelos testes.

Resultados reais finais nesta worktree (exit 0 em todos):

| Comando | Resultado |
| --- | --- |
| `npm --prefix functions run test -- --run` | 13 arquivos, 120 testes aprovados, sem skips; 11,49 s na rodada final |
| `node scripts/check-contracts.mjs` | Contratos compartilhados sincronizados |
| `node scripts/check-secrets.mjs` | Scan aprovado, 816 arquivos rastreados/não rastreados |
| `functions/node_modules/.bin/tsc --project functions/tsconfig.json --noEmit` | Tipagem aprovada, sem geração de artefatos |
| `git diff --check` | Sem erros de whitespace |

Os comandos Node usaram `PATH=/home/app/.local/share/node24/bin:$PATH` para acessar
o runtime já instalado. Nenhuma instalação foi necessária. A tentativa inicial
dos três comandos obrigatórios terminou em exit 127 antes de executar checks,
pois node estava ausente do PATH; a tentativa inicial de tipagem também apontava
para um binário inexistente na raiz. São falhas de preparação registradas, não
testes executados/aprovados.

Houve três execuções efetivas da suíte: a primeira teve 106 aprovados/11 falhos
por captura de Date.now no roteador importado antes do relógio controlado do teste.
A consulta ao relógio foi corrigida sem remover asserções. A segunda aprovou 117.
Após endurecer a rejeição sem dados privados, remover escrita sem fencing sem uso
e acrescentar regressões de orçamento/TTL/erro privado, a terceira aprovou 120.
Contratos, secrets e tipagem tiveram três execuções efetivas aprovadas, agrupadas
às mesmas rodadas. Não se apresenta nenhum teste herdado como reexecução; não
houve emulador, teste em produção ou ensaio real de implantação.

| Critério | Aceite/risco local | Gate restante |
| --- | --- | --- |
| Lease/fencing/resposta coerente | Implementado, regressões locais nesta entrega | Revisão independente e falhas reais de rede/commit |
| Classificação e não replay de efeito incerto | Conservadora, todas as mutações bloqueadas após start incompleto | Recibos operacionais/reconciliação SaaS |
| Recuperação e cleanup reais | Conectados a exports agendados, lotes e retenção limitados | Implantar artefato revisado, confirmar índices e capacidade |
| C8 integral | Não encerrado por código/testes locais | Ensaio de interrupção real e observação após implantação |

Próximo gate: revisão independente; preparar homologação isolada autorizada com
Rules/IAM e versões de consumidores verificadas; drenar invocações do código
antigo sem fencing antes de ativar a versão nova; exercitar falha antes do claim,
após start e após efeito/antes da resposta, suspensão/lease e confirmação perdida.
Confirmar nenhum segundo efeito, resposta compreensível em clientes legados,
checkpoint/índices/agendamento/retentativas e retenção sem TTL indevido.
Esta entrega não autoriza nem executa esse deploy/ensaio.
