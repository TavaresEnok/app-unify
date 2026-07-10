# Observabilidade

## Sinais de saude

| Servico | Liveness/readiness |
| --- | --- |
| Painel | `/` |
| API | `/health` |
| Proxy SGP | `/health` e `/ready` |
| APK Builder | `/health` |
| Speed test | `/health` |

`/health` indica processo vivo. `/ready` do proxy verifica PostgreSQL e informa
Redis como degradado quando o fallback em memoria esta ativo.

## Logs

- API e proxy emitem `x-request-id`; preserve esse valor em tickets e incidentes.
- O proxy registra metodo, caminho, status e duracao sem corpo ou credenciais.
- Docker limita cada arquivo de log a 10 MB e mantem tres arquivos.
- Logs do APK ficam em `apk/logs`; nao devem conter query strings de download.

Alertas minimos: indisponibilidade por 2 minutos, taxa 5xx acima de 2% por 5
minutos, `/ready` em 503, espaco em disco acima de 85% e fila de builds travada.
