# Scripts operacionais

Os scripts executaveis ficam agrupados por responsabilidade:

- `ops/services.sh`: iniciar, parar, reconstruir, inspecionar e validar os
  servicos Docker Compose.
- `diagnostics/measure-api-latency.sh`: medir media e p95 dos endpoints HTTP.
- `cloud/setup-monitoring.sh`: configurar metricas e alertas no Google Cloud.
- `migrations/migrate-provider-config.mjs`: migracao idempotente de configuracao
  dos provedores, em dry-run por padrao.

Exemplos:

```bash
npm run services -- status
npm run services -- rebuild frontend
npm run services -- health
npm run measure:latency
```

Regras:

- Nao incluir senhas, tokens ou caminhos absolutos de uma maquina.
- Scripts destrutivos devem exigir confirmacao explicita e oferecer dry-run.
- Instaladores pontuais e scripts que reescrevem codigo-fonte nao devem ser
  mantidos no repositorio.
