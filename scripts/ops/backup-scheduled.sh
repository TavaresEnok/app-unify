#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
backup_dir="${PAINEL_BACKUP_DIR:-/home/app/.backups/painel_provedores}"
mkdir -p "$backup_dir/runs"
exec 9>"$backup_dir/scheduled.lock"
flock -n 9 || { echo 'Backup já está em andamento.'; exit 1; }
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
run_dir="$backup_dir/runs/$run_id"
mkdir "$run_dir"
trap 'echo "Backup interrompido: $run_id" >&2' ERR
docker compose exec -T postgres pg_dump -U sgp_user --no-owner sgp_cache | gzip > "$run_dir/postgres.sql.gz"
gzip -t "$run_dir/postgres.sql.gz"
# PITR: base física (com o WAL necessário) + WAL arquivado desde a base anterior.
# Com a base de ontem e este WAL, dá para restaurar qualquer ponto entre as duas.
docker compose exec -T postgres pg_basebackup -U sgp_user -D - -Ft -X fetch -c fast | gzip > "$run_dir/postgres-base.tar.gz"
docker compose exec -T postgres sh -c 'cd /wal-archive && tar -cf - .' | gzip > "$run_dir/postgres-wal.tar.gz"
# Só depois de copiado: descarta o WAL anterior à base mais recente já arquivada.
docker compose exec -T postgres sh -c 'label=$(ls -1 /wal-archive/*.backup 2>/dev/null | tail -n 1); if [ -n "$label" ]; then pg_archivecleanup /wal-archive "$(basename "$label")"; fi'
redis_temp="/tmp/painel-backup-$run_id.rdb"
docker compose exec -T redis-state redis-cli --rdb "$redis_temp"
docker compose cp "redis-state:$redis_temp" "$run_dir/redis-state.rdb"
docker compose exec -T redis-state rm "$redis_temp"
# Estado do apk-builder (jobs, registro de identidades, APKs publicados pelo F1).
# Os arquivos são do root no container, por isso o tar roda lá dentro.
docker compose exec -T apk-builder tar -cf - -C /home/app/projects/painel_provedores/apk private releases/public -C /run build-identities.json | gzip > "$run_dir/apk-state.tar.gz"
tar -czf "$run_dir/public-apks.tar.gz" public_apks
git ls-files -co --exclude-standard -z | python3 -c 'import os,sys; sys.stdout.buffer.write(b"\0".join(p for p in sys.stdin.buffer.read().split(b"\0") if p and os.path.lexists(p))+b"\0")' | tar --null -T - -czf "$run_dir/source.tar.gz"
tar -czf "$run_dir/private-config.tar.gz" .env api-service/.env proxy-sgp/.env -C /home/app/.secrets painel_provedores
chmod 600 "$run_dir"/*
bash scripts/ops/verify-backup.sh "$run_dir"
node scripts/ops/backup-cloud.cjs "$run_dir"
echo "Backup concluído: $run_id"
