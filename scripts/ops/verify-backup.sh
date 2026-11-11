#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
run_dir="$(realpath "${1:?Informe o diretório do backup}")"
verify_db="painel_backup_verify_$$"
cleanup() { docker compose exec -T postgres dropdb --if-exists -U sgp_user "$verify_db" >/dev/null; }
trap cleanup EXIT
docker compose exec -T postgres createdb -U sgp_user "$verify_db"
gzip -dc "$run_dir/postgres.sql.gz" | docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U sgp_user -d "$verify_db" >/dev/null
docker compose exec -T postgres psql -U sgp_user -d "$verify_db" -Atc 'SELECT count(*) FROM sgp_clients;' | python3 -c 'import sys,json;print(json.dumps({"restoredCacheRows":int(sys.stdin.read())}))'
docker run --rm --network none --cpus .25 --memory 128m -v "$run_dir:/backup:ro" redis:7-alpine redis-check-rdb /backup/redis-state.rdb >/dev/null
for archive in public-apks source private-config apk-state postgres-wal; do tar -tzf "$run_dir/$archive.tar.gz" >/dev/null; done
# Restaura a base física num Postgres isolado (sem rede) e confere o cache.
docker run --rm --network none --cpus .5 --memory 256m -v "$run_dir:/backup:ro" postgres:15-alpine sh -ec '
  mkdir -p /tmp/restore && tar -xzf /backup/postgres-base.tar.gz -C /tmp/restore
  chown -R postgres:postgres /tmp/restore && chmod 700 /tmp/restore
  su-exec postgres pg_ctl -D /tmp/restore -o "-c listen_addresses= -c archive_mode=off" -w start >/dev/null
  rows=$(su-exec postgres psql -U sgp_user -d sgp_cache -Atc "SELECT count(*) FROM sgp_clients;")
  su-exec postgres pg_ctl -D /tmp/restore -m fast -w stop >/dev/null
  printf "{\"physicalBaseRestoredRows\":%s}\n" "$rows"'
echo '{"localRestoreChecks":"passed","redisRdb":"valid","archives":"valid","physicalBase":"valid"}'
