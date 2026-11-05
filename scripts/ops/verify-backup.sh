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
for archive in public-apks source private-config; do tar -tzf "$run_dir/$archive.tar.gz" >/dev/null; done
echo '{"localRestoreChecks":"passed","redisRdb":"valid","archives":"valid"}'
