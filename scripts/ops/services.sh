#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker nao encontrado no PATH" >&2
  exit 1
fi

action="${1:-status}"
service="${2:-}"

case "$action" in
  start)
    docker compose up -d
    docker compose ps
    ;;
  stop)
    docker compose down
    ;;
  restart)
    if [[ -n "$service" ]]; then
      docker compose restart "$service"
    else
      docker compose restart
    fi
    docker compose ps
    ;;
  rebuild)
    if [[ -n "$service" ]]; then
      docker compose build "$service"
      docker compose up -d --no-deps --force-recreate "$service"
    else
      docker compose build
      docker compose up -d --force-recreate
    fi
    docker compose ps
    ;;
  logs)
    if [[ -n "$service" ]]; then
      docker compose logs --tail=100 --follow "$service"
    else
      docker compose logs --tail=100 --follow
    fi
    ;;
  status)
    docker compose ps
    ;;
  health)
    curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8031/ >/dev/null
    curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8034/health
    echo
    curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8030/health
    echo
    curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8030/ready
    echo
    curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8035/health
    echo
    curl --fail --silent --show-error --max-time 10 http://127.0.0.1:8033/health
    echo
    ;;
  *)
    echo "Uso: $0 {start|stop|restart|rebuild|logs|status|health} [servico]" >&2
    exit 2
    ;;
esac
