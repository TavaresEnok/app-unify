# Contrato: Provider Config

Inventario inicial criado em 2026-07-10.

O objetivo deste contrato e definir a configuracao white-label de cada provedor sem quebrar o formato antigo.

## Fonte atual

Arquivos relevantes:

- `admin-painel/src/contexts/SettingsContext.tsx`
- `admin-painel/src/lib/types/provider-config.ts`
- `functions/src/index.ts`
- `lib/core/providers/configuration_provider.dart`
- layouts Flutter em `lib/layouts/*`

## Defaults atuais do painel

Valores principais observados em `SettingsContext`:

```ts
{
  themeColor: "#673AB7",
  secondaryColor: "#9575CD",
  textColor: "#FFFFFF",
  invoiceColor: "#10B981",
  actionColor: "#E11D48",
  cardColor: "#F8F8F8",
  cardTextColor: "#333333",
  logoUrl: "",
  layoutType: "layout_06",
  quickActionsCardColor: "#FFFFFF",
  quickActionsTextColor: "#333333",
  otherCardsColor: "#FFFFFF",
  otherCardsTextColor: "#333333"
}
```

## Layouts suportados no tipo TypeScript

```ts
"layout_02" | "layout_03" | "layout_04" | "layout_05" | "layout_06"
```

Observacao:

- A tela de aparencia tambem apresenta `layout_01`; confirmar se o app Flutter suporta este layout antes de considerar canonico.

## Estilos de diagnostico suportados

```ts
"default" | "diagnostic_02" | "diagnostic_03" | "diagnostic_05" | "diagnostic_06" | "diagnostic_07"
```

## Grupos de configuracao

### Identidade visual

- `layoutType`
- `diagnosticStyle`
- `themeColor`
- `secondaryColor`
- `backgroundColor`
- `cardColor`
- `textColor`
- `iconColor`
- `actionColor`
- `invoiceColor`
- `logoUrl`
- `iconUrl`
- `backgroundUrl`
- `typography`

### Conteudo

- `menuConfig`
- `imageCarousel`
- `dashboardConfig`
- `promotions`
- `notifications`
- `faq`
- `messages`
- `strings`
- dicas/tips

### Configuracao

- `features`
- `supportContacts`
- `supportChannels`
- `social`
- `other`
- `integrations`

### Distribuicao

- dados para build Android
- logo de build
- package/app name
- historico de builds

## Regra de compatibilidade atual

Leitura no painel:

1. Comeca com defaults.
2. Mescla `data.config`.
3. Mescla campos da raiz do documento.
4. Injeta secrets de `provedores/{providerId}/secrets/sgp`.

Escrita no painel:

1. Copia `config`.
2. Remove `integrations` do payload publico.
3. Salva `integrations` em `secrets/sgp`.
4. Salva o resto em `provedores/{providerId}` com merge.

Escrita em Function legacy:

- `UPDATE_PROVIDER_CONFIG` espelha dados na raiz e em `config`.

## Decisao canonica proposta

Formato canonico futuro:

```ts
{
  configVersion: 2,
  identity: {},
  content: {},
  features: {},
  integrationsPublic: {},
  distribution: {},
  updatedAt: Timestamp
}
```

Secrets:

```ts
provedores/{providerId}/secrets/sgp
{
  integrations: {
    appName?: string;
    apiToken?: string;
  }
}
```

Enquanto o app Flutter nao estiver migrado, manter leitura e escrita compativel com campos atuais.

## Tarefas antes de migrar schema

1. Confirmar todos os campos lidos pelo app Flutter.
2. Confirmar todos os campos escritos pelas subpaginas de configuracao.
3. Criar `normalizeProviderConfig` no front.
4. Criar normalizador equivalente em Dart.
5. Criar migracao idempotente.
6. Rodar migracao apenas apos backup.
