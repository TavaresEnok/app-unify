#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
run_dir="$(realpath "${1:?Informe o diretório do backup}")"
verify_db="painel_backup_verify_$$"
# Tabelas que não podem voltar vazias: sem elas o sistema não sobe.
core_counts_sql="SELECT json_build_object('providers',(SELECT count(*) FROM providers),'admin_users',(SELECT count(*) FROM admin_users),'provider_secrets',(SELECT count(*) FROM provider_secrets),'sgp_clients',(SELECT count(*) FROM sgp_clients))"
cleanup() { docker compose exec -T postgres dropdb --if-exists -U sgp_user "$verify_db" >/dev/null; }
trap cleanup EXIT
docker compose exec -T postgres createdb -U sgp_user "$verify_db"
gzip -dc "$run_dir/postgres.sql.gz" | docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U sgp_user -d "$verify_db" >/dev/null
docker compose exec -T postgres psql -U sgp_user -d "$verify_db" -Atc "$core_counts_sql" | node scripts/ops/backup-core-check.cjs logical
docker run --rm --network none --cpus .25 --memory 128m -v "$run_dir:/backup:ro" redis:7-alpine redis-check-rdb /backup/redis-state.rdb >/dev/null
for archive in source apk-state postgres-wal uploads; do tar -tzf "$run_dir/$archive.tar.gz" >/dev/null; done
# APKs públicos só entram no backup completo (domingo).
if [[ -f "$run_dir/public-apks.tar.gz" ]]; then tar -tzf "$run_dir/public-apks.tar.gz" >/dev/null; fi
# Chaves e .env: em claro (tar.gz) ou cifrados para a chave pública GPG (.gpg).
if [[ -f "$run_dir/private-config.tar.gz" ]]; then
  members="$(tar -tzf "$run_dir/private-config.tar.gz")"
  grep -q '/app-secrets.key$' <<<"$members" || { echo 'private-config sem app-secrets.key.' >&2; exit 1; }
  if grep -q 'initial-admin-passwords.txt$' <<<"$members"; then echo 'private-config contém senhas iniciais em texto.' >&2; exit 1; fi
elif [[ ! -s "$run_dir/private-config.tar.gz.gpg" ]]; then
  echo 'private-config ausente.' >&2; exit 1
fi
# Restaura a base física num Postgres isolado (sem rede) e confere as tabelas principais.
docker run --rm --network none --cpus .5 --memory 256m -v "$run_dir:/backup:ro" -e CORE_SQL="$core_counts_sql" postgres:15-alpine sh -ec '
  mkdir -p /tmp/restore && tar -xzf /backup/postgres-base.tar.gz -C /tmp/restore
  chown -R postgres:postgres /tmp/restore && chmod 700 /tmp/restore
  su-exec postgres pg_ctl -D /tmp/restore -o "-c listen_addresses= -c archive_mode=off" -w start >/dev/null
  counts=$(su-exec postgres psql -U sgp_user -d sgp_cache -Atc "$CORE_SQL")
  su-exec postgres pg_ctl -D /tmp/restore -m fast -w stop >/dev/null
  printf "%s\n" "$counts"' | node scripts/ops/backup-core-check.cjs physical
echo '{"localRestoreChecks":"passed","redisRdb":"valid","archives":"valid","physicalBase":"valid"}'
