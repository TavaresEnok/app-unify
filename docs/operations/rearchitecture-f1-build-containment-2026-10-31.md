# Contenção F1 de builds — 31/10/2026

Executor nominal: `executor-codex-task-645c61b8262c-f1-build-containment`.
Worktree: `task-645c61b8262c-f1-build-containment`, base integrada `047ab67`.
Implementação local; revisão independente obrigatória pelo controlador.
Sem commit, deploy, distribuição, migração, acesso produtivo ou alteração de
credenciais/keystore reais. E8 upstream permanece aberto e intocado.

Lotes anteriores **revisados/integrados**: `17baa3af4fe4`/`b5ab897` (configuração)
e `2eda0f2a79ac`/`2ac2bc8` (saída SGP). Esses estados atualizam relatos históricos
de implementador que ainda diziam revisão pendente. Recibos herdados: API 69,
Functions 89, proxy 25 pass + 6 skips Redis; não são reexecuções deste lote.
O diretório externo informado pelo gerente
`/home/app/srv_projetos/orchestration/evidence/painel_provedores/config-boundary-20261031`
não está acessível nesta sessão (No such file or directory). O manifesto/log dos
dez testes Java21/demo aprovados pelo gerente é evidência externa a incorporar;
não foi copiado, reexecutado ou inventado.

## Código e operação

O HTTP anterior validava somente claim, o Compose montava a conta administrativa
e o subprocesso herdava process.env. O callable executava Python sob a Function;
o script publicava arquivo por nome e descartava símbolos temporários. São
condições observadas nas fontes anteriores, sem atribuí-las a implantação futura.

Agora a API valida Firebase real/revogado/disabled e papel SaaS atual, tenant
existente/ativo, propósito/job e autenticação recente. Builder revalida antes de
download/spawn e release; cancelamento torna o job terminal e mata processo quando
presente. API mantém apenas binding sem token por 30 minutos; reinícios negam
continuação sem prova. O callable encaminha ao mesmo HTTP ou falha fechado.
Detalhes e erros: [contrato](../contracts/build-containment.md).

Compose remove conta administrativa do builder e o tira da rede painel_net de
Postgres/Redis/proxy. Só Caddy liga também a rede apk_build_edge para entrada;
autoridade sai por HTTPS fixo público. Sem Docker socket/env_file/monorepo montado.
SDK é somente leitura; caches são volumes nomeados específicos. Dockerfile exclui
material administrativo/assinatura do template antes de criar camada da imagem.
A imagem deve ser reconstruída antes de usar essa configuração; não foi criada
ou executada nesta sessão. A inspeção estática não comprova firewall, IAM ou
negação real de acesso a serviços por rede/host/egress/proxy público.

**Risco residual explícito:** o keystore e signing.properties existentes continuam
montados no builder; Python/Gradle podem acessá-los e assinar, e o processo Node
continua com escrita no volume de releases. Caches e dependências de build podem
executar código com esse acesso. F7 deverá separar assinatura/publicação e
credenciais, além de testar integridade da cadeia. Não chamar E2 inteiro fechado.
O certificado inventariado ainda exige conferência real contra a assinatura.

## Gatilho operacional antes de novos builds

Responsáveis: engenharia SaaS e gerente/controlador devem concluir revisão deste
lote, reconstruir imagem sem resíduos antigos, configurar autoridade HTTPS fixa,
isolar rede efetiva e verificar ausência de ADC/metadados/segredos produtivos.
Nenhuma dessas ações foi executada aqui. Não iniciar builders legados em paralelo.
Inventariar pacotes e certificados já publicados e todos os nomes/IDs que colidem;
importação administrativa revisada deve criar apk/identities.json schema 1 conforme
o contrato. Ausência não permite bootstrap automático, novo applicationId ou
troca de assinatura. Resolver ambiguidade com inventário humano, preservando
IDs/pacotes/assinaturas publicados. Os testes usam somente `br.com.legacy` e
`br.com.existing.unchanged`, nomes e fingerprints sintéticos; não são dados a
importar. Duplicar fixture para isp-a/ispa ou mesmo nome deve bloquear.

Preparar apk/private com permissões restritas e retenção/backup de símbolos,
manifestos, mappings e logs fora de public_apks. Não mover logs antigos para a
árvore pública. Estado antigo deve ser preservado para histórico, sem reativar
jobs em execução; APK_JOB_STATE_PATH novo aponta à área privada. Releases
históricos permanecem nos caminhos existentes; novos usam tenant/versão/build.
Validar SDK somente leitura em ambiente próprio; não conceder mount host amplo
para contornar incompatibilidade. Auth recente (cinco minutos) antes da solicitação
e spawn pode exigir reautenticação do operador. Publicação até 30 minutos usa
binding em memória e nova validação atual. Falha de autoridade fecha a geração.

## Validação local

Suíte sintética: endpoints Express reais de builder e autorização, callable real
com conector simulado, subprocesso simulado e Python real com comandos Flutter
simulados. Cobre negações, polling/erros, revogação após aceite, cancelamento,
colisões e retenção/checksums depois de TemporaryDirectory real limpar a fonte.
Nenhum Flutter/Gradle/keystore real ou conexão Firebase/SGP produtiva.

Primeira rodada dos checks obrigatórios (Node 24 disponível fora do PATH inicial;
PATH ajustado só nos comandos, sem alterar host):

| Comando | Status | Resultado novo |
| --- | --- | --- |
| `npm --prefix services/apk-builder test` | exit 0 | 14 pass |
| `npm --prefix api-service test` | exit 0 | 77 pass, 10 arquivos |
| `npm --prefix functions run test -- --run` | exit 0 | 94 pass, 13 arquivos |
| `python3 -m unittest discover -s scripts/build -p 'test_*.py'` | exit 0 | 5 pass |
| `node scripts/check-secrets.mjs` | exit 0 | 812 arquivos, sem achados |

Checks adicionais: `tsc --noEmit` da API e Functions e `git diff --check`, exit 0.
Suítes usam mocks explícitos; os cinco checks não provam IAM/rede/assinatura.
Python imprimiu avisos de cache opcional `/root/.pub-cache` sem permissão;
nenhum comando Flutter/Gradle foi executado. A suíte não altera esse cache.
Após a rodada, revisão local endureceu permissões de diretórios privados (0700,
inclusive diretório pré-existente do job-store) e estabilizou erro de URL operacional
inválida no callable. Esses ajustes motivam repetição apenas de builder, Python,
Functions e scanner; API77 é reutilizado sem reexecução.

Revalidação motivada por esses ajustes: builder 14 pass/exit 0, Functions 94
pass/exit 0, Python 5 pass/exit 0, scanner 812 arquivos/exit 0. API77 permanece
válido da primeira rodada. Functions `tsc --noEmit` repetido após o ajuste da URL.
Contagem: cinco comandos obrigatórios na primeira rodada, quatro repetidos por
mudança relevante, nenhum teste produtivo/pesado e nenhum recibo herdado reexecutado
como tal. Inspeção final dos gatilhos localizou a UI SaaS → HTTP builder e o
callable exportado → mesmo HTTP; sem outro spawn Python nesses caminhos.

## Gates e rollback

### Correção local da revisão F1-REVIEW-01

A revisão independente anterior reprovou a cópia direta para o destino público:
uma falha podia deixar binário parcial acessível. Executor nominal permanece
`executor-codex-task-645c61b8262c-f1-build-containment`. A correção prepara uma
cópia em diretório privado 0700, verifica SHA-256 e fsync do arquivo, revalida a
autorização e libera por hard link atômico/exclusivo. Nenhuma cópia ocorre na
árvore servida. EEXIST preserva release existente; EXDEV falha fechado, sem
fallback. A cópia privada é removida após sucesso/falha; uma falha dessa limpeza
após liberação não declara falho um efeito já concluído. Crash/efeito incerto C8
continua pendente. Não é alegada atomicidade com revogação concorrente Firebase.

Antes de operar, verificar hard links entre os subdiretórios private/public do
mount apk/releases no filesystem real. Isso não foi testado em containers ou no
host operacional; nenhum mount/serviço real foi alterado. Diretórios vazios de
release podem restar após falha de link, sem binário parcial. Resíduos privados
após interrupção exigem retenção/limpeza operacional e nunca são servidos.

Cinco regressões adicionais usam HTTP Express real e conectores/subprocesso
simulados: cópia parcial com EIO e limpeza, visibilidade somente após link real,
cópia corrompida/revogação durante preparo, EXDEV e colisão EEXIST preservando
release anterior, além de configuração do store/prefixo público dedicado. Os
recibos acima pertencem à tentativa anterior. A reprovação anterior
permanece no histórico e nova revisão independente cabe ao controlador.

A inspeção do Compose mostrou que preparação privada e saída pública em bind
mounts distintos poderiam produzir EXDEV mesmo no mesmo disco host. A declaração
agora monta apk/releases uma única vez no builder, contendo private e public;
landing monta somente public em /public_apks/f1. O mount legado ./public_apks
continua somente na landing para preservar links antigos, sem escrita pelo
builder. Novos links são /public_apks/f1/{tenant}/{versão}/{build}/app.*.
Preparar previamente apk/releases/public e apk/releases/private (0700 para
private), sem symlinks/mounts aninhados; conferir hard links e leitura pública
somente do subtree public antes de novos builds. Nenhuma preparação real foi
feita aqui. Caddy mantém o encaminhamento existente /public_apks/*.

Rodada obrigatória desta correção: builder 18 pass, API 77 pass (10 arquivos),
Functions 94 pass (13 arquivos), Python 5 pass, scanner 812 arquivos sem achados;
todos exit 0. Depois dessa rodada, o ajuste relevante de mounts/store/prefixo e
sua quinta regressão motivaram repetir somente builder e scanner. API/Functions/
Python dessa rodada são reutilizados, sem alteração de seus caminhos de código.
Repetição concluída: builder **19 pass/exit 0** e scanner **812 arquivos, sem
achados/exit 0**. `git diff --check` também exit 0. Nesta retomada foram cinco
comandos obrigatórios na rodada inicial e duas repetições justificadas pela
mudança de código/configuração. Nenhum recibo herdado foi apresentado como novo.

Código/testado/revisado/implantado/distribuído são estados distintos. Este lote
não encerra E2/E3/C12/C13/G0/G1. Pendentes: revisão independente, prova IAM/rede,
assinatura/atualização de app existente, retenção/recuperação operacional e
simbolização, imagem e projeção móvel efetivamente distribuídas. UI permanece
SaaS; personalização não chama geração; provedor consome apenas versão/link
público da projeção existente e não ganha acesso a logs. Nenhum assinante/provedor
foi adicionado como executor de fila.

Rollback seguro desabilita a geração/retira endpoint e preserva releases/recibos/
identidades/símbolos. Nunca restaurar montagem de segredos, geração para provedor,
normalização de pacote, sobrescrita por nome ou Python privilegiado no callable.
Não prometer desfazer assinatura/liberação já concluída. Próximos lotes: C8
lease/efeitos incertos, compatibilidade/projeções/mobile/assets e demais F0/F1.
