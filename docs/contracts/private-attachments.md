# Anexos privados v2 — contrato F1/E9

Executor nominal: `executor-codex-task-04a9bc62a88b-f1-private-attachments`.
Base `804762d`, incluindo servidor `858be72`. Implementação local; revisão
independente pelo controlador ainda obrigatória. Sem implantação/distribuição.

## Autoridade e transporte

Express existente, atrás do prefixo público `/api` quando configurado no painel:

| Método | Caminho relativo ao Express | Corpo / retorno |
| --- | --- | --- |
| PUT | `/private/tickets/{ticketID}/attachments/{attachmentID}` | Binário PNG/JPEG, até 5 MiB; `{attachmentId, version:2}` |
| GET | mesmo caminho | Bytes autenticados; sem cache, disposition attachment e nosniff |
| PUT | `/private/providers/{providerID}/results/{resultID}/reports/{attachmentID}` | PDF, até 5 MiB; mesma confirmação |
| GET | mesmo caminho | Bytes PDF para download, nunca iframe/conteúdo ativo |

Bearer somente no header Authorization. IDs são opacos, alfanuméricos, `_` ou
`-`, entre 1 e 128 caracteres; cliente gera UUID estável por upload, sem filename,
URL, path, owner, token ou destino no corpo/query. Não há comando RPC novo.
`CREATE_TICKET` e `REPLY_TO_TICKET` rejeitam campos de associação de arquivos;
o endpoint é a autoridade exclusiva. Dados históricos de mensagens permanecem.

Identidade vem de `verifyToken` C1/E4: verificação revogada, Auth atual,
disabled, comparação de claims. Revalidação após I/O e leitura canônica antes da
entrega/commit. SaaS exige superAdmin explícito e papel consistente; provedor
exige providerAdmin e tenant canônico; assinante exige subscriber, mesmo tenant
e createdByUid igual ao UID atual. Claim CPF, body e nome do objeto não provam
autoria. Não há lookup global/limit1 nem fallback CPF. Alteração do dono invalida
metadados antigos, inclusive para novo dono; reconciliação é procedimento futuro.
Autorização é pontual; revogação posterior não recolhe bytes já entregues.

Relatório exige documento canônico em
`provedores/{providerID}/diagnostic_results/{resultID}`, providerId igual ao path,
createdByUid, schemaVersion=2 e **createTime do Firestore** estritamente posterior a
`PRIVATE_DIAGNOSTIC_RULES_ACTIVE_AFTER`. Gate ausente/inválido ou documento antigo
nega leitura/upload, inclusive SaaS, pois autoria antiga poderia ter sido forjada.
O controlador só poderá configurar esse corte após Rules verificadas/publicadas,
compatibilidade e rollout aprovados. Não configurar retroativamente para aceitar
documentos legados; schemaVersion/createdAt enviados pelo cliente não bastam.
Leitura direta Firestore de diagnostic_results por assinante permanece negada,
inclusive para documentos recém-criados ou com owner/tenant/schema/data
coincidentes. Acesso privado aos arquivos passa pelo backend com o corte canônico;
o SDKv2 não deve instalar listener de histórico para assinante. Leitura de
diagnósticos por providerAdmin do próprio tenant e SaaS permanece permitida.

## Persistência, retry e falhas

Storage ADC apenas no servidor, bucket fixado pelo operador com
`FIREBASE_STORAGE_BUCKET`; nenhum destino vem do cliente. Objeto imutável em
`private_v2/{tenant}/{tickets|results}/{resourceID}/{attachmentID}`.
Firestore backend-only em `{resource}/private_attachments/{attachmentID}` guarda
version, providerId, ownerUid, resourceId, attachmentId, path, checksum SHA256,
size, mime, state, generation e createdAt. Não contém bearer/downloadToken.
Nenhum makePublic, URL assinada ou URL de download é produzido.

Transação reserva estado pending e fingerprint; Storage usa ifGenerationMatch=0;
valida objeto/metadados/bytes por geração; outra transação revalida recurso e
confirma committed junto da mensagem determinística `attachment_{ID}` ou do
reportAttachmentId. Reserva e confirmação só aceitam pending sem campo generation
ou committed com geração string decimal positiva; retry committed exige a mesma
geração do objeto verificado. Estado ausente/desconhecido ou geração inconsistente
nunca é promovido automaticamente, mesmo se alterado durante o I/O.
Não existe transação Storage/Firestore. Mesmo ID com corpo
diferente ou dono alterado retorna conflito; retry idêntico recupera pending sem
duplicar mensagem. A chave é escopada ao recurso, não global entre recursos.
Commit perdido pode ser repetido; ticket/mensagem inicial não são recriados pelo
upload. Leitura exige committed, vínculo integral, tamanho/tipo/checksum e
generation; rejeita downloadTokens inesperados. Ausência/erro/objeto órfão nunca
vira referência servida ou resposta de sucesso.

Validação binária básica: assinatura/estrutura IHDR e dimensões limitadas para
PNG, marcadores JPEG e header/EOF PDF, MIME exato. Não é antivírus nem validação
semântica de PDF; arquivo é download, PDF nunca executado pelo painel. Oito
requisições simultâneas por processo, parser sem compressão até 5 MiB; body e
download de verificação podem coexistir (~80 MiB de buffers nas oito vagas,
mais overhead). Proxy/replicas e limites de processo exigem orçamento F0.

Pending/órfãos ficam privados, sem limpeza automática nesta entrega. Engenharia
SaaS deve definir prazo de retenção, backup e reconciliador por metadado, geração
e checksum; inventariar em modo leitura, quarentena e revisão antes de apagar.
Não adotar órfão por nome nem apagar qualquer objeto real neste lote.

## Painel e SDK/mobile v2

AddTicketDialog cria ticket primeiro, preserva ticketID/arquivo/campos se upload
falhar e reutiliza UUID no retry. Campos ficam bloqueados após criação parcial;
cancelamento/troca de identidade cancela o envio e descarta respostas tardias.
PrivateAttachment busca bytes sob Bearer, cria blobURL local e revoga ao trocar
recurso/sessão ou desmontar. URLs não ficam em localStorage. PDF só baixa;
TicketDetail e DiagnosticHistory não abrem URLs legadas automaticamente.

SDK v2 futuro deverá criar resultado com schemaVersion=2, providerId do token,
createdByUid=auth.uid e createdAt=serverTimestamp; apenas schema diagnóstico
permitido. Medidas são dados declarados pelo cliente, não laudo confiável nem
autoridade administrativa. Não pode atualizar medidas/owner/tenant/status/ref;
associação posterior do PDF ocorre por PUT no resultID já criado, não por URL.
O backend usa o estado atual da identidade, nunca status informado pelo app.

Flutter/unified e admin_app **não foram alterados**. SDKv1 perde upload direto,
CPF legado e associação reportUrl; exige atualização/distribuição/compatibilidade
testada antes de publicar backend/Rules. Não conservar endpoint inseguro para
compatibilidade. Compartilhamento PDF fora do app precisa decisão controlada
futura (p.ex. arquivo local); não gerar link permanente por conveniência.

Rules negam todo acesso SDK a private_v2 e metadados backend-only, inclusive
SaaS. v1 anexos/relatórios nega assinantes e novas escritas; administradores do
próprio tenant/SaaS conservam leitura/apagamento administrativo legado. Wildcards
diagnostic_results excluídas das permissões SaaS genéricas. Branding/public_assets
e política existente de APKs públicos preservadas; secrets/build não ampliados.
SDK ainda usa claims do token: revogação residual de E4 é gate independente.

## Links antigos — procedimento seco, não executado

Rules **não revogam** downloadURLs já distribuídas. Controlador coordena;
engenharia SaaS deve nomear operador de Storage/IAM e responsável pelo backup
antes do gate. Inventário futuro autorizado deve relacionar geração, token,
recurso, tenant, proprietário verificável, consumidores e distribuição, sem
copiar segredos para logs/recibos. Separar branding/APK público de documento
privado, referência desconhecida e compartilhamento externo. Backup cifrado
restrito + manifesto/checksum e ensaio de restauração precedem qualquer mudança.
Revisão humana decide vínculo/remediação, aviso e atualização de consumidores;
sem owner verificável, quarentena e bloqueio, nunca permissão tenant-wide.
Somente operação futura autorizada remove/rotaciona tokens dos objetos privados
classificados, valida links anteriores revogados e acesso v2 legítimo, com recibo
por geração. Rollback recupera disponibilidade segura sem restaurar tokens ou
acesso alheio/segredos. Nada desse inventário/backup/revogação foi executado.

E9/C1/E4/G0/G1 seguem parciais até revisão, Rules emuladas, jornadas SaaS/provedor/
assinante, SDK/mobile, IAM, objetos antigos, implantação e distribuição.
