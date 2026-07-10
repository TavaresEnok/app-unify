# Contrato: Provider Config

Atualizado em 2026-07-10.

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
4. secrets em `provedores/{providerId}/secrets/sgp` quando o painel tem permissao.

A escrita do painel salva campos publicos na raiz do provedor, remove
`integrations` do documento publico e grava dados SGP em `secrets/sgp`.

## Layouts

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
| Integracoes | `integrations` apenas em secrets |
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

## Garantias atuais

- Config vazia renderiza com defaults.
- Subpagina salva sem apagar campos de outras subpaginas.
- Secrets SGP nao ficam no documento publico.
- Flutter root e Flutter unified leem formato atual e legado.
