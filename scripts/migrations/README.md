# Migracoes de dados

`migrate-provider-config.mjs` consolida campos legacy de `config` na raiz e move integrações para `secrets/sgp`.

O script é idempotente, executa em modo de simulação por padrão e cria um backup por provedor antes de gravar.

```bash
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json node scripts/migrations/migrate-provider-config.mjs
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json node scripts/migrations/migrate-provider-config.mjs --apply
```

Use `--remove-legacy` apenas depois de todos os aplicativos compatíveis estarem publicados. Sem essa opção, os campos antigos permanecem intactos.
