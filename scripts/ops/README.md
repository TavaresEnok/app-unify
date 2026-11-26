# Operação: backup, restauração e monitor

## Backup diário (`painel-backup.timer`, 03h de Fortaleza)

`backup-scheduled.sh` gera em `/home/app/.backups/painel_provedores/runs/<id>/`:

| Arquivo | Conteúdo |
|---|---|
| `postgres.sql.gz` | dump lógico de todo o `sgp_cache` (provedores, admins, segredos cifrados, assinantes, chamados...) |
| `postgres-base.tar.gz` + `postgres-wal.tar.gz` | base física + WAL (PITR) |
| `uploads.tar.gz` | volume `/srv/uploads` (logos/banners em `public/`, anexos em `private/`) |
| `redis-state.rdb` | filas e estado persistente |
| `apk-state.tar.gz` | estado do apk-builder; os APKs publicados só no backup de domingo |
| `public-apks.tar.gz` | só no domingo (`PAINEL_BACKUP_APKS_FULL=true` força) |
| `private-config.tar.gz` | `.env` + `/home/app/.secrets/painel_provedores`, **sem** `initial-admin-passwords.txt` e sem `firestore-legacy-backup-*` |
| `auth-*.json`, export Firestore | legado Firebase; best-effort, `PAINEL_BACKUP_FIRESTORE=false` desliga |

`verify-backup.sh` restaura o dump e a base física em bancos isolados e falha se
`providers`, `admin_users` ou `provider_secrets` voltarem vazias.
`backup-cloud.cjs` envia tudo para `gs://$PAINEL_BACKUP_BUCKET/backend_backups/runs/<id>/`
e grava `manifest.json` por último (com `warnings` se o export legado falhar).

Rodar na mão: `sudo systemctl start painel-backup.service` e `journalctl -u painel-backup -n 40`.

## Restaurar (servidor novo)

1. `tar -xzf private-config.tar.gz` (ou `gpg -d private-config.tar.gz.gpg | tar -xz`) e devolva
   `.env`, `api-service/.env`, `proxy-sgp/.env` e `/home/app/.secrets/painel_provedores/` (modo 600).
   Sem `app-secrets.key` os segredos de ERP do banco não abrem.
2. `docker compose up -d postgres redis-state` e
   `gzip -dc postgres.sql.gz | docker compose exec -T postgres psql -U sgp_user -d sgp_cache`.
3. Uploads: `docker compose up -d api-service` e
   `gzip -dc uploads.tar.gz | docker compose exec -T api-service tar -xf - -C /srv`.
4. APKs: `apk-state.tar.gz` e `public-apks.tar.gz` do domingo mais recente.
5. `bash scripts/ops/services.sh rebuild` e `bash scripts/ops/services.sh health`.

## Monitor e avisos

`healthcheck.cjs` confere `/api/ready`, `/sgp/ready`, `/speedtest/health`, `/painel/`, `/`,
containers doentes/parados, disco (≥ 90%) e idade do backup (> 26 h). Avisa quando a
falha começa, quando some e a cada 6 h enquanto continua.

- Destino do aviso: `PAINEL_ALERT_WEBHOOK_URL=https://...` em
  `/home/app/.secrets/painel_provedores/alert.env` (modo 600). Recebe `POST` JSON: `{"text"}` no Google Chat,
  `{"content"}` no Discord e `{"text","content"}` nos demais (Slack, n8n...).
- Instalar o cron (a cada 5 min): veja `monitor.cron`.
- Falha do backup: o próprio script avisa; para pegar timeout/kill instale também
  `painel-alert@.service` e a versão nova de `painel-backup.service`:
  `sudo cp scripts/ops/painel-alert@.service scripts/ops/painel-backup.service /etc/systemd/system/ && sudo systemctl daemon-reload`.
- Na mão: `bash scripts/ops/services.sh monitor`.

## Credenciais com menor privilégio (pendente do dono)

Hoje a mesma `service-account.json` faz FCM nos containers e grava/apaga o bucket de backup.
Quem invadir um container leva também os backups. Passos no Console do Google Cloud:

1. Bucket próprio para backup (ex.: `painel-backups-<sufixo>`) com **retention policy** de 30 dias
   (ou versionamento) e regra de ciclo de vida que apaga depois de 35 dias.
2. Conta de serviço só de backup nesse bucket com `roles/storage.objectCreator` **e**
   `roles/storage.objectViewer` (o envio confere tamanho/geração de cada arquivo e a limpeza
   lista o bucket; só com objectCreator o backup falha), mais
   `roles/datastore.importExportAdmin` enquanto o export do Firestore existir.
   Gravar a chave em `/home/app/.secrets/painel_provedores/backup-sa.json` e trocar
   `GOOGLE_APPLICATION_CREDENTIALS` e `PAINEL_BACKUP_BUCKET` no `painel-backup.service`.
   Com retention policy a limpeza de 30 dias do script falha de propósito; troque pelo ciclo de vida.
3. Nos containers, conta só com `roles/firebasecloudmessaging.admin` (e `Service Account Token Creator`
   em si mesma enquanto o login legado do Firebase existir, até 2027-01-31).
4. Chaves fora do bucket dos dumps: gere um par GPG **fora do servidor**, importe só a pública
   (`gpg --import publica.asc`) e defina `PAINEL_BACKUP_GPG_RECIPIENT=<id ou e-mail da chave>` no
   `painel-backup.service`. O `private-config` passa a sair como `private-config.tar.gz.gpg`.
