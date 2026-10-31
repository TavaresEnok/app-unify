# F0/F1 — preparação da validação Flutter offline (31/10/2026)

Executor: Codex, `executor-codex-task-a26da62a3bc3-f0-mobile-validation`
(provedor `codex-programmer`, modelo `gpt-6.1-sol`). Base conferida: `875b8e0`.
Matriz §15 do plano consultada: compatibilidade mobile/admin_app e gates
C1/E4/E9 continuam abertos; recibos anteriores são evidência herdada, sem
reexecução neste lote. Revisão independente pertence ao controlador.

## Entrada reproduzível e pré-requisitos

Na raiz do checkout, usar Node como entrada do runner do controlador, com
`/work` gravável, raiz do contêiner read-only, rede `none`, memória `1536m`
e timeout de `120s` por comando. O script limita seus subprocessos ao saldo de
110s totais e preserva stdout/stderr dos comandos reais. O isolamento de rede
é responsabilidade do runner; executar diretamente no host não comprova rede
`none`. Não usar credenciais nem montar diretórios secretos no runner.

Cache público pré-provisionado pelo gerente, ignorado pela regra `node_modules/`:

- `node_modules/.paseo-mobile-cache/flutter`: Flutter **3.38.4**, Dart **3.10.3**,
  snapshot das ferramentas, SDK e artefatos de engine já instalados.
- `node_modules/.paseo-mobile-cache/pub-cache/{hosted,hosted-hashes}`:
  pacotes e hashes públicos correspondentes aos lockfiles dos dois apps.
- `node_modules/.paseo-mobile-cache/mobile-check-tmp/`: temporários grandes e
  configuração/cache XDG; evita ocupar o `/tmp` de 128 MiB. Pode ser removido
  entre execuções quando não houver processo ativo.

Todos os caminhos são derivados da localização do script, inclusive no mount
`/work`; nenhum caminho absoluto do host é gravado no código. O runner chama
`bin/cache/dart-sdk/bin/dart` e `bin/cache/flutter_tools.snapshot` diretamente,
sem bootstrap por `bin/flutter` nem reconstrução da ferramenta.
Antes de qualquer operação Flutter, o checker remove a configuração gerada do
próprio `packages/flutter_tools` e executa Dart diretamente:
`dart pub --suppress-analytics --directory <cache>/flutter/packages/flutter_tools get --offline --enforce-lockfile`.
Valida todos os roots dessa configuração, incluindo pacotes internos do SDK,
por caminho real sob a raiz atual. O mesmo preparo ocorre em cada invocação
de probe/analyze/test-compat, sem confiar em configuração manual anterior.
Os hashes dos pubspecs/locks do flutter_tools e dos apps, binário Dart,
snapshot e metadados de versão são conferidos ao terminar, inclusive em falha.
`FLUTTER_ROOT`, `PUB_CACHE`, `CI`, supressão de analytics e
`--no-version-check` são explícitos. O ambiente dos filhos usa allowlist, não
herda credenciais/proxies, preserva HOME sem redirecioná-lo e usa XDG isolado.

## Comandos e interpretação

```sh
node scripts/diagnostics/mobile-check.mjs probe
node scripts/diagnostics/mobile-check.mjs unified analyze
node scripts/diagnostics/mobile-check.mjs admin_app analyze
node scripts/diagnostics/mobile-check.mjs unified test-compat
node scripts/diagnostics/mobile-check.mjs admin_app test-compat
git diff --check
```

`probe` é preparação, não teste funcional. Executa versões reais Dart/Flutter,
registra SHA-256 dos executáveis/metadados e pubspecs/lockfiles originais e roda
`dart pub --suppress-analytics --directory <app> get --offline --enforce-lockfile`
nos dois apps. Qualquer alteração
dos pubspecs/lockfiles resulta em falha, inclusive após subprocesso malsucedido.
Não restaura silenciosamente arquivos modificados pela ferramenta.
O preparo evita `flutter pub get`, que executa GenerateLocalizationsTarget em
apps com `generate: true`. Flutter real permanece em `--version`, analyze e test.

Cada modo de app remove a configuração gerada anterior e resolve novamente
offline com lockfile obrigatório antes de analisar/testar. Valida que todos os
pacotes resolvidos existem sob a raiz atual, inclusive após resolver links
simbólicos, rejeitando caminhos antigos de outro host. `analyze` executa
`flutter analyze --no-pub --no-fatal-infos
--no-fatal-warnings lib`: avisos/infos permanecem visíveis, erros são fatais.
Não adiciona exclusões nem altera opções de análise existentes.
`test-compat` exige o arquivo `test/compatibility_v2_test.dart` e os artefatos
locais de engine e executa `flutter test --no-pub` nesse arquivo exato.
Ausência de teste/cache/pacote/ferramenta é falha explícita, nunca skip ou PASS.
Falhas de pré-requisito vão ao gerente, sem download, upgrade ou mudança da
política do controlador. O runner deve continuar sem rede também nos modos
funcionais, pois Flutter pode tentar atualizar artefatos incompletos.

## Histórico das tentativas anteriores

Tentativa anterior (evidência herdada, não execução desta continuação): probe
bloqueado com exit 127 por Node ausente e `git diff --check` aprovado. O probe
não iniciou Flutter, e os arquivos novos não estavam no índice naquela rodada.

Nesta continuação, HEAD `875b8e0` e matriz §15.10–15.12 conferidos. Nenhum
`AGENTS.md` foi encontrado nos diretórios ancestrais aplicáveis ou na worktree.
O runner passou a validar também o destino real dos links dos pacotes, para
rejeitar referências indiretas ao host anterior. O caminho de frontend server
da engine exigido pelo modo de teste existe no cache fornecido; essa inspeção
não é execução de teste. Rodada essencial desta continuação:

| Comando | Status | Resultado novo |
| --- | --- | --- |
| `node scripts/diagnostics/mobile-check.mjs probe` | Bloqueado, exit 127 | `/bin/bash: line 1: node: command not found`; o processo Node/Flutter não iniciou |
| `git diff --check` | PASS, exit 0 | Sem erros no diff rastreado; arquivos novos ainda não adicionados ao índice |

Conferência adicional dos dois arquivos novos com
`git diff --no-index --check /dev/null <arquivo>`: nenhuma mensagem de whitespace;
exit 1 de cada comparação representa a diferença em relação a `/dev/null`.
O comando obrigatório `git diff --check` foi isolado novamente após o comando
composto de conferência retornar 1, para registrar seu próprio status sem
confundi-lo com o status das comparações de arquivos novos.

Conferência pontual confirmou ausência de `node`/`nodejs` no PATH e nos
caminhos usuais `/usr/bin/node`, `/usr/local/bin/node`, `/opt/node/bin/node`
e `node_modules/.bin/node`. Nenhuma instalação foi tentada. O controlador deve
executar o probe no runner autorizado com Node disponível. A preparação fica
**bloqueada até essa execução**: não há prova nova de processo Flutter,
resolução offline, relocação para `/work` ou isolamento de rede nesta sessão.
Nenhuma análise ou teste dos apps foi simulado.

Leitura local de `flutter.version.json` informa Flutter 3.38.4 / Dart 3.10.3,
framework `66dd93f9a27ffe2a9bfc8297506ce066ff51265f` e engine
`a5cb96369ef86c7e85abf5d662a1ca5d89775053`; isso é metadado do cache,
não saída de execução. SHA-256 originais conferidos com `sha256sum`:

| Arquivo relativo à raiz | SHA-256 |
| --- | --- |
| `app-flutter/unified/pubspec.lock` | `036856ed961789ca91049bfead6d6da9d9e3320d155919c21c98cc015eb1ac50` |
| `app-flutter/admin_app/pubspec.lock` | `ebd64e4f8ce84a6eec17cc1d4f154b9607e49167217d122f71f59b59355f9c1b` |
| `node_modules/.paseo-mobile-cache/flutter/bin/cache/flutter.version.json` | `5b434368aa80648646b7a1619261997dc9a628fc2b335722fb1156865e27b454` |
| `node_modules/.paseo-mobile-cache/flutter/bin/cache/dart-sdk/bin/dart` | `4b8f28e5e687d04dcdd7040c134226c38898a6babd2baf88280b5fd3c3a58f72` |
| `node_modules/.paseo-mobile-cache/flutter/bin/cache/flutter_tools.snapshot` | `b5c42f443cf98c539fa3cca8120d96fa0ed3c8f6d0d045b7757f0929ed291a25` |

## Retomada atual — 31/10/2026 UTC

Executor `executor-codex-task-a26da62a3bc3-f0-mobile-validation`, Codex /
`codex-programmer`, `gpt-6.1-sol`. HEAD novamente conferido: `875b8e0`.
Matriz §15, incluindo §15.10–15.12, e implementação existente conferidas nesta
worktree; nenhum `AGENTS.md` aplicável encontrado. O script existente foi
preservado. As execuções e hashes da seção anterior são evidência herdada.

Uma execução nova de `node scripts/diagnostics/mobile-check.mjs probe` retornou
**exit 127**, `/bin/bash: line 1: node: command not found`. Nenhum processo
Dart/Flutter ou resolução de pacotes começou. A conferência pontual confirmou
Node ausente no PATH e nos caminhos usuais já descritos. Não há ferramenta do
runner do controlador disponível nesta sessão. Não foram tentados instalação,
download, execução alternativa fora do runner ou mudança de política.

**Impedimento encaminhado ao controlador:** executar o mesmo probe com Node no
runner autorizado (`/work` gravável, raiz read-only, rede `none`, memória
`1536m`, timeout `120s`). O pré-requisito permanece bloqueado até esse resultado;
não há evidência nova de versões executadas, pub get offline ou relocação.
O resultado do check essencial `git diff --check` desta retomada consta também
de `.paseo-result.json`; esse comando não inclui os dois arquivos não rastreados.

Os testes de compatibilidade ainda não existem nesta base, conforme conferência
pontual desta retomada. Analyze/test-compat
não foram executados neste lote; o controlador deverá executá-los nos escopos
de apps posteriores. Revisão independente pendente, separada do bloqueio de
pré-requisito acima.

Nenhum Dart, pubspec ou teste existente editado. Sem APK, deploy, publicação,
serviço, migração, credencial ou rotação SGP. E8 permanece intacto. Este recibo
prepara evidência local e não concede aceite F0/G0/F1/G1 nem distribuição.

## Recuperação autocontida — 31/10/2026 UTC

Executor Codex / `codex-programmer`, `gpt-6.1-sol`, ID
`executor-codex-task-a26da62a3bc3-f0-mobile-validation`. Base `875b8e0`;
matriz §15 e fontes atuais conferidas, sem AGENTS.md aplicável. Os registros
anteriores de bloqueio acima são históricos, preservados sem recontagem.

Pré-requisito externo informado pelo gerente: Node 24 foi disponibilizado em
`node_modules/.paseo-mobile-cache/bin/node`. No runner oficial (rede none,
`/work`, 1536m, 120s), a primeira execução iniciou Dart/Flutter, mas expirou
em 110s durante bootstrap online de flutter_tools causado por paths antigos.
O gerente informou preparo direto offline exit 0 em 0,81s e probe contratado
subsequente exit 0 em 5,52s: Flutter 3.38.4/Dart 3.10.3, unified 234 pacotes,
admin_app 103, pubspecs/locks preservados. Essa evidência foi comunicada no
contrato; os JSON externos não foram inspecionados pelo executor e não são
execução desta implementação nem aprovação final.

A implementação atual incorpora esse preparo direto em todos os perfis,
regenera package_config do SDK e dos apps para a raiz da execução e rejeita
pacotes ausentes, referências externas e symlinks para fora da worktree.
O probe desta retomada parte do config copiado que apontava para `/work`,
enquanto esta worktree possui outro caminho: isso exercita regeneração em
condição relocada, sem exigir cópia adicional de SDK ou preparação manual.
O Node local é usado explicitamente pelo executor; a entrada contratual do
controlador continua sendo `node scripts/diagnostics/mobile-check.mjs probe`.

Nenhum analyze/test-compat executado nesta fase de tooling. Os perfis exigem
ferramentas reais e a ausência de `test/compatibility_v2_test.dart` falha
explicitamente; essa ausência não bloqueia o probe nem a entrega do checker.
Revisão independente e consolidação do plano cabem ao controlador.

Rodada essencial nova após implementar o bloco funcional:

| Comando executado | Status | Evidência nova do executor |
| --- | --- | --- |
| `node_modules/.paseo-mobile-cache/bin/node scripts/diagnostics/mobile-check.mjs probe` | PASS, exit 0 | Dart 3.10.3 e Flutter 3.38.4 iniciados; flutter_tools 102, unified 234 e admin_app 103 pacotes locais; configurações regeneradas, hashes preservados |
| `git diff --check` | PASS, exit 0 | Sem diagnósticos; os dois arquivos entregues permanecem não rastreados, portanto esse comando não inclui seu conteúdo |

Uma execução de cada check nesta retomada, sem repetição de testes funcionais.
Esta execução local não afirma isolamento de rede/root/memória do runner
oficial; o controlador deve verificar a nova implementação nesse runner.
As mensagens genéricas `Downloading packages...` do pub foram mantidas visíveis:
os três comandos usaram `--offline --enforce-lockfile`, sem upgrade ou download
solicitado. O checker não executa o bootstrap online anteriormente observado.

Hashes novos conferidos e preservados do SDK:

| Arquivo em `flutter/packages/flutter_tools/` | SHA-256 |
| --- | --- |
| `pubspec.yaml` | `41bbc5949f7483cf8ad6504cd636fef1701f1e1461277d9ddd34c90986e2e0bf` |
| `pubspec.lock` | `246d46461bdfa97d5734a188d16fc2741dddc88d111eeb49dfe6bc6087bc771f` |

Os hashes do Dart/snapshot/metadados e locks dos apps coincidiram com os valores
históricos acima; a conferência pelo checker é nova, sem recontar os comandos
históricos. Nenhum Dart/pubspec/lockfile rastreado alterado, commit ou deploy.

## Correção de preservação de fontes — tentativa atual

Executor: Codex / `codex-programmer`, `gpt-6.1-sol`, ID
`executor-codex-task-a26da62a3bc3-f0-mobile-validation`; base `875b8e0`.
Matriz §15 consultada; nenhum AGENTS.md aplicável encontrado. Escopo permanece
somente checker/evidência, com revisão independente posterior pelo controlador.

O controlador detectou na tentativa 4 alteração de
`admin_app/lib/l10n/app_localizations.dart`: `flutter pub get` aciona geração
de localizações. Assim, o PASS histórico acima para hashes de ferramentas e
locks não comprovou preservação de fontes. Esse registro é preservado, mas
sua afirmação histórica de nenhum Dart alterado foi invalidada pelo controlador.
Nesta retomada o arquivo já estava igual ao HEAD, conforme contrato e estado
inicial da worktree; nenhum reset/restore foi executado pelo executor.

Pré-verificação externa informada pelo gerente: Dart pub direto offline nos
dois apps passou em 2,74s no runner oficial (Node24, rede none, `/work`),
preservando o hash da localização. Referência externa informada:
`mobile-direct-pub-source-preservation.json` no diretório de evidências do
controlador. Esse JSON não foi inspecionado pelo executor e seu resultado
não é execução do checker corrigido, nem aceite independente.

O checker agora prepara tanto flutter_tools quanto cada app com Dart pub
direto, `--offline --enforce-lockfile`, antes de operações Flutter reais.
Remove e regenera package_config/package_graph a cada execução, inclusive do
SDK, validando roots reais locais de todos os pacotes internos/externos.
O config inicial do flutter_tools nesta retomada ainda referenciava `/work`,
diferente da worktree atual: o probe exercita novamente a relocação inversa.

A proteção captura hashes do conteúdo atual de todas as fontes Dart em lib/test
dos dois apps, incluindo edições locais preexistentes. Conferência do inventário
Git nesta base encontrou todas as 189 fontes Dart rastreadas nessas árvores
(177 lib, 12 test). O checker protege também adições locais nessas árvores;
não depende de Git no runner nem do ponteiro absoluto `.git` da worktree.
Monitores de filesystem ficam ativos durante os subprocessos e uma escrita
observada em fonte protegida interrompe a ferramenta e reprova o comando,
mesmo que os bytes sejam restaurados depois. Hashes são conferidos antes e
depois de **cada subprocesso** e no encerramento; não apenas no snapshot final.
Falha do monitor também reprova. Nenhuma restauração ou alteração de configuração
funcional do app é utilizada. Links simbólicos nas árvores de fontes são
rejeitados explicitamente, sem seguir caminhos externos.

Esta proteção permanece ativa nos modos analyze/test-compat; erros/diagnósticos
das ferramentas continuam visíveis, sem liberar geração de Dart rastreado.
Somente o probe é executado nesta fase: analyze/testes de aplicação ficam nos
escopos consumidores. A ausência do teste compat exigido reprova seu perfil,
mas não bloqueia o probe nem esta entrega de tooling.

Rodada nova do executor após essa correção (uma execução por check):

| Comando | Status | Resultado |
| --- | --- | --- |
| `node_modules/.paseo-mobile-cache/bin/node scripts/diagnostics/mobile-check.mjs probe` | PASS, exit 0 | Dart 3.10.3 / Flutter 3.38.4 reais; flutter_tools 102, unified 234 e admin_app 103 pacotes locais; configurações regeneradas; ferramentas/pubspecs/locks e 189 fontes Dart preservados; nenhuma escrita observada |
| `git diff --check` | PASS, exit 0 | Sem diagnósticos de whitespace no diff rastreado; checker/recibo são arquivos novos não rastreados e não integram esse diff |

SHA-256 inicial e final de `admin_app/lib/l10n/app_localizations.dart`:
`743d8cb5b0dc8a8d845c959b28b4de99a1d301052e966ca0a286855903eea24a`.
Os hashes de ferramentas, SDK e locks registrados acima permaneceram iguais.
A saída genérica `Downloading packages...` do pub ficou visível; todos os
comandos de resolução usaram `--offline --enforce-lockfile`, sem upgrade.
Nenhum fonte foi restaurado ou gerado pelo checker.

Esta execução local do executor não comprova os limites de rede/memória/root
do runner oficial. O controlador deve executar o checker corrigido nesse
runner e conduzir a revisão independente. Os resultados externos anteriores
continuam identificados como pré-verificações, sem recontagem como execução
desta implementação. Cache público e temporários permanecem ignorados em
`node_modules/`; nenhum Dart, pubspec, teste, plano global ou configuração
funcional foi editado. Sem APK/deploy/produção/migração/commit; E8 e SGP intactos.
