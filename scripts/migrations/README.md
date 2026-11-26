# Migracoes de dados

`migrate-provider-config.mjs` consolida campos legacy de `config` na raiz e move integrações para `secrets/sgp`.

O script é idempotente, executa em modo de simulação por padrão e cria um backup por provedor antes de gravar.

```bash
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json node scripts/migrations/migrate-provider-config.mjs
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json node scripts/migrations/migrate-provider-config.mjs --apply
```

Use `--remove-legacy` apenas depois de todos os aplicativos compatíveis estarem publicados. Sem essa opção, os campos antigos permanecem intactos.

## migrate-firestore-to-pg.mjs (já aplicada em 2026-11-25)

Não rode de novo em produção. O script agora:

- recusa rodar se a tabela `providers` já tiver linhas (mensagem "Migração já aplicada");
- com `--dry-run`, roda dentro de uma transação e desfaz tudo no final;
- com `--force`, roda mas nunca sobrescreve o que já está no PostgreSQL (dados do
  painel vencem; segredos existentes ficam como estão);
- só importa backups com personalização real, sem segredos e sem ids `legacy-client-*`.
