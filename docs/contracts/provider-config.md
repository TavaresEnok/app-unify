# Contrato: Provider Config

Atualizado em 2026-10-31. Implementação local F1; não implantada.

## Fonte de verdade

- Tipo canonico: `shared/contracts/index.ts`
- Defaults web: `admin-painel/src/features/provider-settings/defaults.ts`
- Schema de secoes: `admin-painel/src/features/provider-settings/schema.ts`
- Normalizador web: `admin-painel/src/features/provider-settings/normalizers.ts`
- Normalizador Flutter: `lib/core/models/provider_config_normalizer.dart`
- Normalizador Flutter unified: `app-flutter/unified/lib/core/models/provider_config_normalizer.dart`

## Compatibilidade

O sistema continua lendo:

1. defaults canonicos;
2. campos legados em `config`;
3. campos atuais na raiz de `provedores/{providerId}`;
4. nenhum secret é lido pelo painel, inclusive SaaS; documentos legados passam
   pela projeção HTTP sanitizada antes de chegar à UI.

A escrita de personalização usa `UPDATE_PROVIDER_CONFIG`, validado no backend
por `shared/runtime/providerConfig.ts` (cópias para cada pacote autônomo,
comparadas por regressão). HTTP `POST /admin/providers` também valida entradas;
campos desconhecidos, tipos incorretos e credenciais aninhadas são rejeitados.
Os tipos TypeScript legados extensíveis não substituem esse schema em runtime.
Escritas diretas nos documentos públicos foram bloqueadas pelas regras locais.
Leituras HTTP removem campos legados fora da allowlist; o painel consulta essa
projeção a cada 15 segundos, sem listeners de documentos públicos mistos/secrets.

Somente `POST /admin/providers/:providerId/integration` substitui conjuntamente
`apiToken`, `sgpBaseUrl` e `appName`. Exige SaaS nos claims atuais, token
verificado com revogação e autenticação de até cinco minutos. O formulário começa
vazio e a resposta contém apenas sucesso. Firestore privado continua como ponte.
Não há GET de token, migração para Secret Manager nem transmissão de credencial
ao SGP neste fluxo. HTTPS é validado sintaticamente; DNS/conexão/redirect/SSRF e
teste candidato/ativação versionada continuam pendentes.

Backups novos têm `schemaVersion: 1` e somente personalização sanitizada.
Raiz e `config` legado são sanitizados separadamente e seus mapas permitidos
combinados recursivamente, com precedência da raiz por campo e substituição
integral de arrays. Normalização, backup e restore usam a mesma resolução,
sem incluir defaults no snapshot.
Backups antigos são lidos exclusivamente pelo backend; o RPC fornece metadados
e o restore extrai somente a allowlist. Em transação, remove todos os campos
personalizáveis atuais (raiz e `config` legado), aplica a versão sanitizada e
preserva identidade Android, distribuição, acesso e integração atuais. Não lê
nem grava `secrets/sgp`, mesmo quando o solicitante é SaaS. Token/URL/app nunca
são recuperados de backup de personalização. Recuperação privada é outro fluxo.

As regras locais negam secrets/backups diretos nas duas coleções e wildcards.
A leitura direta aceita somente uma projeção plana de branding com campos e
tipos explícitos. Mapas/listas de configuração rica, campos desconhecidos e URL
interna são negados mesmo em documentos legados: a leitura rica passa pelo HTTP
sanitizado. Não há prova recursiva de segurança por uma blacklist rasa.
Isso exige compatibilizar os leitores mobile diretos antes da implantação;
nenhuma limpeza ou migração de documentos reais foi executada.
Gates antes de publicar: emulador real, classificação/sanitização controlada das
projeções legadas sem perder destino operacional, compatibilidade mobile e paths
de assets. Nenhum documento real foi consultado ou alterado neste lote.

## Layouts

`strings.layoutThemes` mantém o formato legado de texto JSON, com validação
explícita dos layouts `layout_01` a `layout_06` e somente os doze campos de cor
produzidos pela tela de aparência. JSON inválido, layouts/campos desconhecidos,
credenciais e valores estruturados onde se espera cor textual são rejeitados
na entrada. A saída legada remove propriedades não permitidas também dentro
desse JSON; temas válidos permanecem na leitura, escrita e backup/restore.

Layouts canonicos:

- `layout_02`
- `layout_03`
- `layout_04`
- `layout_05`
- `layout_06`

Fallback: `layout_06`.

## Estilos de diagnostico

- `default`
- `diagnostic_02`
- `diagnostic_03`
- `diagnostic_05`
- `diagnostic_06`
- `diagnostic_07`

## Grupos configuraveis

| Area | Campos |
| --- | --- |
| Aparencia | `layoutType`, `diagnosticStyle`, cores, `other.useBackgroundImage` |
| Tipografia | `typography` |
| Imagens | `logoUrl`, `iconUrl`, `backgroundUrl` |
| Menus | `menuConfig` |
| Dashboard | `dashboardConfig`, `dashboard` legado |
| Conteudo | `imageCarousel`, `promotions`, `notifications`, `tips`, `faq`, `messages`, `strings`, `termsOfUse` |
| Modulos | `features` |
| Integracoes | Fora da personalização; substituição SaaS no backend |
| Suporte | `supportContacts`, `supportChannels` |
| Social | `social`, `socialNetworks` |
| Distribuicao | `appVersion`, build Android |

## Migracao

Script idempotente:

```bash
node scripts/migrations/migrate-provider-config.mjs
node scripts/migrations/migrate-provider-config.mjs --apply
node scripts/migrations/migrate-provider-config.mjs --apply --remove-legacy
```

O modo padrao e dry-run. O script cria backup em
`provedores/{providerId}/migration_backups/provider-config-v1` antes de aplicar.

## Evidências locais e limites

- Config vazia renderiza com defaults.
- Subpagina salva sem apagar campos de outras subpaginas.
- Entradas de configuração rejeitam secrets; saídas HTTP/normalizadores removem
  dados legados. Isso não comprova limpeza de documentos reais preexistentes.
- Flutter unified le formato atual e legado.
- Regressões API/Functions/UI aprovadas; regras novas escritas, ainda sem
  emulador nesta sessão (Java indisponível). Sem implantação/distribuição.
