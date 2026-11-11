# F1 — fronteira de configuração, segredos e personalização (31/10/2026 UTC)

Estado: **código implementado e testes unitários aprovados; não implantado; não distribuído**.
Implementação concluída para encaminhamento à revisão independente do controlador.
Sem commit, push, merge, deploy, produção, credenciais reais, alteração de serviços,
migração de banco/framework ou uso de API paga. A worktree autorizada é
`task-17baa3af4fe4-f1-config-boundary`. Baselines `aeef740` e `608af5f`
continuam ancestrais de HEAD (duas verificações `git merge-base --is-ancestor`, exit 0).

## Implementação entregue

- Allowlist com tipos e estrutura aninhada em `shared/runtime/providerConfig.ts`,
  espelhada nos três pacotes autônomos e comparada em teste. Entradas desconhecidas
  ou sensíveis falham; respostas legadas são projetadas sem campos desconhecidos.
  Inclui personalização de cores, textos, FAQ, contatos, menus internos/externos,
  dashboard, promoções, splash/login e flags visuais existentes.
- HTTP provedores distingue edição comercial SaaS da personalização do tenant.
  RPC config/details valida antes dos efeitos; não grava integração. Edição de
  detalhes usa paths permitidos e preserva URL operacional e flags nativas legadas.
  Auditoria de configuração registra metadados, sem payload bruto, até quando um
  valor privado tenta se disfarçar como texto de personalização.
- Substituição privada exclusiva SaaS: `POST /admin/providers/:providerId/integration`.
  Revalida revogação/usuário atual e autenticação recente (cinco minutos); exige
  token/URL/app completos e não fornece leitura do valor existente. Guarda somente
  na ponte Firestore privada. Sem comunicação upstream neste endpoint.
- Painel deixa de ler secrets/documentos brutos; recebe projeção HTTP sanitizada
  com atualização a cada 15 segundos, sem reemitir dados inalterados ou de outro tenant (regressão de preservação de edição local). Personalização é salva por RPC validado.
  Provedor não recebe formulário/navegação de integração; SaaS recebe formulário
  vazio de substituição. Editor comercial não contém URL/app/token de integração.
- Regras Firestore locais bloqueiam escrita direta de configuração nas coleções
  atual/legada e acesso direto a secrets/backups, inclusive wildcards sobrepostas.
  Wildcards genéricas deixam de autorizar provedores; permissões explicitamente
  declaradas de incidentes/diagnósticos continuam. Documentos públicos contendo
  campos de integração legados falham fechados na leitura direta.
- Storage restringe assets legados da raiz a nomes de branding e mantém
  `public_assets`; secrets/backups mistos não possuem regra permissiva. É
  necessário conferir paths históricos antes de qualquer implantação.
- Backup novo: schema v1, apenas personalização. Restore antigo/novo sanitizado e
  transacional substitui exatamente o namespace personalizável, removendo campos
  posteriores da raiz e do legado `config`. Preserva estado administrativo,
  identidade Android, distribuição e integração atuais, sem ler/gravar documento
  privado. Listagem de backups devolve somente metadados. Nesta execução, restore
  rejeita snapshots inválidos (incluindo arrays), versões de schema desconhecidas
  e IDs que contenham caminhos; exclusão também valida o ID. A rejeição antecede
  qualquer escrita e impede apagar personalização ao receber backup malformado.

## Verificação observada

Ambiente: Node **v24.22.1**, Vitest **4.1.12**. Node já instalado em
`/home/app/.local/share/node24/bin`, acrescentado somente ao PATH dos comandos;
nenhum serviço ou instalação foi alterado.

| Comando | Estado final | Resultado |
| --- | --- | --- |
| `npm --prefix api-service test` | aprovado | 48/48, 8 arquivos |
| `npm --prefix functions exec -- vitest run` (cwd `functions/`) | aprovado | 82/82, 11 arquivos |
| `npm --prefix admin-painel run test` | aprovado | 19/19, 9 arquivos |
| `node scripts/check-contracts.mjs` | aprovado | contratos sincronizados, uma execução nesta retomada |
| `node scripts/check-secrets.mjs` | aprovado | 792 arquivos, uma execução nesta retomada |
| `tsc --noEmit -p <pacote>/tsconfig.json` (API/Functions) e `tsconfig.app.json` (painel) | aprovado | três pacotes sem erros; Functions/painel revalidados após alterações de fluxos |
| `git diff --check` | aprovado | sem erros de whitespace |
| Emulador Firestore/Storage | **pendente** | `java -version`: command not found; sem instalação autorizada neste lote |

Histórico anterior: o comando obrigatório Functions sem flags iniciou Vitest na raiz do monorepo:
foi interrompido (exit 130), sem contar os testes de regras/Node/E2E descobertos
indevidamente como aceites. Uma primeira correção de config duplicou o path e
falhou antes dos testes. As flags finais acima delimitam corretamente a suíte.
As cinco primeiras tentativas obrigatórias falharam com exit 127 por Node fora
do PATH, antes de executar testes; não foram tratadas como aprovação.
Falhas das regressões novas foram corrigidas nos próprios fixtures: ID de snapshot
HTTP ausente, parêntese do mock Functions e reutilização indevida de Response no
mock UI. Não houve remoção de asserções para ocultar falhas. As expectativas
legadas que autorizavam leitura de secrets por provedor ou URL em saída pública
foram deliberadamente substituídas pela nova política e cobertura negativa.

Testes cobrem papéis/tenants, tentativas aninhadas/arrays/campos desconhecidos,
respostas legadas, auditoria sem payload, UI sem leitura privada, substituição
SaaS, backup sem leitura privada, restore antigo misto para SaaS e provedor,
remoção exata de campos e integração privada sintética intocada.
Os dez casos declarados em `tests/firestore-rules.test.mjs` incluem regras
sobrepostas, coleções legadas, leituras de documentos mistos e Storage; estão
**escritos, mas não homologados em emulador**.

Nesta execução os cinco checks obrigatórios passaram em uma rodada, exit 0:
API 48/48, Functions 82/82, painel 19/19, contratos sincronizados e scan de
792 arquivos aprovado. TypeScript e diff registrados na tabela anterior são
evidências herdadas, não novos checks obrigatórios desta execução.
As seis regressões novas cobrem snapshots/versões inválidos e IDs de backup,
mais quatro condições que negam substituição SaaS sem alterar o segredo privado
sintético: revogação, conta desativada, papel removido e autenticação antiga.
O comando literal Functions funciona com cwd em `functions/`, carregando
a configuração existente sem flags nem descoberta do monorepo. O contexto
recebido trazia falha dessa descoberta ampla, inclusive benchmark que exigia
Redis isolado; nenhum benchmark ou teste existente foi enfraquecido para passar.
Foram acrescentadas regressões para rejeição de envelopes RPC desconhecidos,
metadados de backup com objetos arbitrários, ID HTTP inválido e remoção de
`apiUrl` na saída. As cópias do schema continuam iguais ao canônico.

A leitura direta Firestore passou a uma allowlist plana tipada de branding.
Uma blacklist em poucos níveis não protege segredos em arrays/mapas profundos
preexistentes. Por isso documentos ricos, inclusive legítimos, falham fechados
nessa leitura; o painel mantém personalização completa por HTTP sanitizado/RPC.
A compatibilidade de leitores diretos mobile deve ser resolvida antes de deploy:
não apresentar a regra como homologada ou como compatível com todos os apps.
Nenhuma projeção real foi consultada, transformada ou publicada.

## Recuperação da validação contratada na raiz

Em 31/10/2026 UTC, preservados código, baselines e recibos anteriores, foi
acrescentado `vitest.config.mts` na raiz. A entrada importa integralmente
`functions/vitest.config.mts` e define root absoluto via
`fileURLToPath(new URL('./functions/', import.meta.url))`, sem copiar allowlists
ou thresholds. A configuração própria de Functions permanece inalterada.

Causa: `npm --prefix functions exec` mantém o cwd da raiz. Sem essa entrada,
Vitest descobria testes de outros pacotes, benchmark Redis e E2E/UI. Os recibos
anteriores com cwd `functions/` comprovavam apenas aquela execução distinta;
não eram validação da chamada real do controlador. Os registros acima são
históricos. Esta recuperação valida o comando literal na raiz, sem flags extras.

Uma rodada essencial nova, todos os comandos com cwd na raiz autorizada:

| Comando | Status | Resultado |
| --- | --- | --- |
| `npm --prefix api-service test` | exit 0 | 48/48, 8 arquivos |
| `npm --prefix functions exec -- vitest run` | exit 0 | root Functions, 82/82, 11 arquivos; sem benchmark Redis/E2E/UI |
| `npm --prefix admin-painel run test` | exit 0 | 19/19, 9 arquivos |
| `node scripts/check-contracts.mjs` | exit 0 | contratos sincronizados |
| `node scripts/check-secrets.mjs` | exit 0 | 793 arquivos, scan aprovado |

Node v24.22.1 pelo PATH local existente; Vitest 4.1.12. API/UI continuam com
comandos/configurações próprios. Nenhuma alteração de mock, asserção, teste,
threshold ou lista de coleta para obter aprovação; nenhum Redis/serviço iniciado.
TypeScript herdado não reexecutado; emulador de regras **não executado**.
Implementação concluída e encaminhada à revisão independente do controlador.
Estado: **código/testes locais aprovados; não implantado; não distribuído**.

## Gates e pendências

### Correção após revisão R1/R2 — 31/10/2026 UTC

Revisão anterior reprovada: os testes históricos não cobriam o payload real
`strings.layoutThemes` nem mapas divididos entre raiz e `config`. Evidências
anteriores preservadas, sem atribuir a elas cobertura dos defeitos.

R1 corrigido no schema canônico e nas três cópias: JSON legado de temas
decodificado/validado por seis layouts e doze campos de cor explícitos.
Campos desconhecidos/sensíveis e tipos inválidos são rejeitados na entrada;
saídas legadas filtram seu conteúdo. A regressão da tela percorre alteração
de cor, troca de layout, restauração de cores e serviço real de save até o
RPC, comprovando preservação de temas e rejeição de campos extras.

R2 corrigido com resolução recursiva comum a normalizador, backup e restore,
após sanitizar separadamente raiz e legado. Raiz prevalece por campo; arrays
substituem integralmente. Testes para provedor e SaaS cobrem snapshots novos e
antigos mistos, mapas divididos/conflitos, remoção de campos posteriores,
arrays vazios, integração/identidade/permissões preservadas e documento privado
sintético intocado, sem leitura ou escrita. Não se mesclam defaults ao snapshot.

Rodada essencial desta correção, todos os comandos **na raiz autorizada**,
Node v24.22.1/Vitest 4.1.12 existentes, sem instalação ou serviços:

| Comando | Status | Resultado |
| --- | --- | --- |
| `npm --prefix api-service test` | exit 0 | 48/48, 8 arquivos |
| `npm --prefix functions exec -- vitest run` | exit 0 | 87/87, 11 arquivos; root Functions |
| `npm --prefix admin-painel run test` | exit 0 | 20/20, 10 arquivos |
| `node scripts/check-contracts.mjs` | exit 0 | contratos sincronizados |
| `node scripts/check-secrets.mjs` | exit 0 | 794 arquivos |
| `git diff --check` | exit 0 | sem erros |

Cinco checks obrigatórios executados uma vez, sem falhas nem repetição.
A configuração raiz herdada permanece integral, sem coleta de Redis/E2E/UI;
execuções históricas com cwd Functions continuam distintas desta evidência.
TypeScript não reexecutado; emulador Firestore/Storage **não executado**.
Baselines verificados como ancestrais; sem commit por contrato.
**Código/testes locais aprovados; não implantado, não distribuído.**
Nova revisão independente pendente, encaminhada ao controlador via recibo.
Nenhum achado abrangente ou gate encerrado; pendências abaixo preservadas.

C4/C11 têm contenção implementada/testada no escopo local, sem encerramento:
faltam revisão independente, regras reais, classificação das projeções existentes,
compatibilidade e implantação. E3 é **parcial**, pois builds/callables/builder/IAM
e demais caminhos privilegiados recebem outro lote. E9 continua parcial.

Antes de regras reais: verificar dados legados com procedimento controlado sem
exibir valores, preservar destino operacional na ponte privada e validar que o
app móvel ainda carrega branding. O painel atualizado usa HTTP sanitizado, mas
apps antigos podem ler Firestore diretamente. Conferir assets fora da nova lista,
leitores de subcoleções antes permitidas pela wildcard e clientes `admin_app`
que enviavam credenciais pelo cadastro público (agora rejeitados).
Não executar o antigo migrador geral de configuração sem nova revisão: ele foi
documentado antes da fronteira SaaS.

G1 não concedido. Permanecem abertos C5/SSRF (DNS/conexão/redirect), builds/E2,
revogação uniforme/E4 e reautenticação de todos os caminhos, E8/rotação upstream,
Secret Manager/candidato-teste-ativação, produção, APK/adoção e recuperação integral.
Nenhum token operacional real foi consultado, substituído, copiado ou revogado.
Rollback não pode reabrir secrets/backups ou escrita genérica ao provedor.
