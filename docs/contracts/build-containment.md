# F1: contrato de geração restrita

`POST /generate-apk` mantém providerId/appName/logoUrl/format e `async: true`;
202 retorna jobId/status. `GET /jobs/:id` mantém preparing/running/succeeded/failed,
404 para ausente/expirado e erro estável de autorização 403. Indisponibilidade da
autoridade retorna 503 com `{ success: false, error: 'authorization-unavailable' }`,
sem estado do job. Isso vale para solicitação, consulta e cancelamento e para
revalidações anteriores ao download, spawn e publicação. Timeout, transporte,
configuração inválida e resposta ilegível/incompleta da autoridade também são
indisponibilidade fail-closed; não representam revogação. Respostas 401/403 da
autoridade, binding divergente e outro dono continuam negados com 403.
Falha/interrupção
nunca retorna downloadUrl novo. Logs, símbolos e caminhos internos não integram
as respostas. `POST /jobs/:id/cancel` exige SaaS atual e dono do job, retorna
terminal failed ou 409 se o efeito já terminou; não desfaz release anterior.

O callable generateApk mantém o nome exportado, encaminha apenas os campos do
contrato ao builder estático, retorna jobId/status para polling HTTP e falha
fechado sem configuração. Não executa Python nem assina/publica na Function.
Na cadeia autoridade → builder HTTP → callable, 503 é `unavailable` com mensagem
`authorization-unavailable`, nunca `permission-denied`. Se a solicitação já foi
aceita com 202, indisponibilidade na publicação termina o job com erro seguro
`authorization-unavailable`, sem downloadUrl novo. Não há repetição automática;
consulta indisponível preserva os dados anteriores como não atualizados e o
cancelamento indisponível não altera o estado. Requer nova ação explícita após
recuperação, mantendo todas as verificações atuais.

`POST /api/internal/builds/authorize` é a fronteira Firebase na API existente.
Verifica bearer real com revogação, getUser/disabled/customClaims.superAdmin
atuais e existência/estado ativo de provedores/{providerId}. SaaS tem escopo
global conforme a matriz; providerAdmin/subscriber não têm escopo de geração.
O tenant solicitado é um alvo, nunca prova de autorização. Papéis/UID/tenant
fornecidos no body não substituem identidade validada. O binding inclui jobId,
providerId e purpose request/spawn/publish/poll. Request e spawn exigem auth_time
de até cinco minutos. A API retém só UID/tenant/job por até 30 minutos em memória
para revalidação de publicação após builds demorados, sempre repetindo a consulta
de revogação e papel atual. Poll exige acesso atual, sem liberar efeitos.
Reiniciar API perde essa prova; reiniciar builder torna jobs ativos failed.
Nenhum deles retoma efeitos sem nova solicitação autorizada.

APK_AUTHORIZATION_URL (HTTPS absoluto, sem credenciais/query/fragment) é
configuração operacional fixa para esse endpoint; APK_BUILDER_URL é configuração
fixa HTTPS da Function. Ausência, timeout, redirect ou resposta sem o binding
esperado nega execução. Nenhuma URL de autoridade vem do payload. Bearer fica
somente na memória da requisição/closure; não entra em argumentos, ambiente,
job-store, manifesto ou log. A indisponibilidade não libera por cache.

O registro APK_IDENTITY_REGISTRY tem schema 1, reviewed true e identities com
providerId, appName, applicationId, signingCertificateSha256 e inventoryReviewed
true. É importado administrativamente após inventário, montado somente leitura.
Não há endpoint de autoinscrição. Ausente/ambíguo/conflitante bloqueia com 409
identity-inventory-required. IDs normalizados como isp-a/ispa, nomes equivalentes
e pacotes repetidos bloqueiam; não se deriva pacote novo. O fingerprint registra
a identidade inventariada; não é prova local de assinatura efetiva do binário.

Python produz apenas staging privado em tenant/versão/build. Sucesso exige
artefato não vazio, símbolos Dart para builds ofuscados e mapping R8 quando a
configuração minifica, cópias verificadas por SHA-256 e manifesto antes do cleanup.
Node confere metadados/checksums, prepara uma cópia independente em diretório
privado 0700, verifica seu checksum e sincroniza o arquivo antes de repetir a
autorização. A liberação usa hard link atômico e exclusivo para
public_apks/{tenant}/{versão}/{build}/app.{apk|aab}; destino existente ou volumes
em filesystems diferentes negam publicação, sem fallback de cópia pública.
A cópia privada é removida ao terminar; falha parcial de cópia não cria destino
público. Compose monta apenas apk/releases no builder, com preparação em private
e destino em public, evitando hard link entre bind mounts distintos. Landing
monta somente apk/releases/public sob /public_apks/f1; releases legados continuam
no mount público anterior, sem escrita do builder. APK_PUBLICATION_DIR,
APK_OUTPUT_DIR e APK_PUBLIC_URL_PREFIX são configuração operacional fixa.
Hard links nesse mount continuam gate operacional no ambiente real. Só o binário entra na
árvore pública. O release antigo não é atualizado implicitamente; publicar
personalização é uma capacidade distinta e salvar cor não cria jobs.

Limites: checksum/presença não atestam certificado, instalação ou atualização
Android. O teste real desses itens, IAM/rede e simbolização é gate operacional.
Revalidação impede efeitos futuros após negação observada, sem prometer atomicidade
com revogação concorrente no Firebase nem reversão de assinatura já executada.
C8 (lease/efeito incerto após crash) e F7 continuam pendentes.
