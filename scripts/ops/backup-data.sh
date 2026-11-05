#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
backup_dir="${PAINEL_BACKUP_DIR:-/home/app/.backups/painel_provedores}"
mkdir -p "$backup_dir"
backup_path="$backup_dir/postgres-$(date -u +%Y%m%dT%H%M%SZ).sql.gz"
docker compose exec -T postgres pg_dump -U sgp_user --no-owner sgp_cache | gzip > "$backup_path.tmp"
gzip -t "$backup_path.tmp"
mv "$backup_path.tmp" "$backup_path"
printf 'Backup criado: %s\n' "$backup_path"

if [[ -n "${PAINEL_BACKUP_BUCKET:-}" ]]; then
  node scripts/ops/upload-backup.cjs "$backup_path" "$PAINEL_BACKUP_BUCKET" "backend_backups/postgres/$(basename "$backup_path")"
fi
