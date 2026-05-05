#!/usr/bin/env bash
set -euo pipefail

# Mede latência média e p95 de endpoints críticos do app/adm.
# Uso:
#   BASE_URL="http://localhost:8034" RUNS=10 ./scripts/measure_api_latency.sh
# Variáveis opcionais:
#   CHECK_CPF_PAYLOAD='{"cpf":"12345678901","sgpParams":{"token":"x","app":"APP"},"sgpBaseUrl":"https://example.com"}'
#   INVOICES_PAYLOAD='{"cpfCnpj":"12345678901","sgpParams":{"token":"x","app":"APP"},"sgpBaseUrl":"https://example.com"}'
#   ADMIN_LOGIN_PAYLOAD='{"email":"admin@example.com","password":"secret"}'

BASE_URL="${BASE_URL:-http://localhost:8034}"
RUNS="${RUNS:-5}"
TIMEOUT="${TIMEOUT:-20}"

CHECK_CPF_PAYLOAD="${CHECK_CPF_PAYLOAD:-{\"cpf\":\"12345678901\"}}"
INVOICES_PAYLOAD="${INVOICES_PAYLOAD:-{\"cpfCnpj\":\"12345678901\"}}"
ADMIN_LOGIN_PAYLOAD="${ADMIN_LOGIN_PAYLOAD:-}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

collect() {
  local name="$1"
  local method="$2"
  local url="$3"
  local payload="${4:-}"
  local outfile="$TMP_DIR/${name}.times"
  : > "$outfile"

  echo "\n== $name =="
  echo "Endpoint: $method $url"

  local i
  for ((i=1; i<=RUNS; i++)); do
    local out
    if [[ "$method" == "GET" ]]; then
      out=$(curl -sS -m "$TIMEOUT" -o /dev/null -w "%{http_code} %{time_total}" "$url" || echo "000 0")
    else
      out=$(curl -sS -m "$TIMEOUT" -o /dev/null -w "%{http_code} %{time_total}" \
        -H "Content-Type: application/json" \
        -X "$method" -d "$payload" "$url" || echo "000 0")
    fi

    local code time
    code="${out%% *}"
    time="${out##* }"

    printf "%s\n" "$time" >> "$outfile"
    printf "run=%02d status=%s time=%ss\n" "$i" "$code" "$time"
  done

  awk '
    BEGIN { sum=0; count=0 }
    { times[count]=$1; sum+=$1; count++ }
    END {
      if (count == 0) { print "avg=0 p95=0"; exit }
      for (i=0; i<count; i++) {
        for (j=i+1; j<count; j++) {
          if (times[i] > times[j]) {
            tmp=times[i]; times[i]=times[j]; times[j]=tmp
          }
        }
      }
      p95_index=int(count*0.95)-1
      if (p95_index < 0) p95_index=0
      if (p95_index >= count) p95_index=count-1
      avg=sum/count
      p95=times[p95_index]
      printf "RESULT avg=%.3fs p95=%.3fs samples=%d\n", avg, p95, count
    }
  ' "$outfile"
}

echo "Baseline de latência"
echo "BASE_URL=$BASE_URL RUNS=$RUNS TIMEOUT=${TIMEOUT}s"

collect "health" "GET" "$BASE_URL/health"
collect "check-cpf" "POST" "$BASE_URL/check-cpf" "$CHECK_CPF_PAYLOAD"
collect "invoices" "POST" "$BASE_URL/get-invoices" "$INVOICES_PAYLOAD"

if [[ -n "$ADMIN_LOGIN_PAYLOAD" ]]; then
  collect "admin-login" "POST" "$BASE_URL/admin/auth/login" "$ADMIN_LOGIN_PAYLOAD"
else
  echo "\n== admin-login =="
  echo "SKIP: defina ADMIN_LOGIN_PAYLOAD para medir /admin/auth/login"
fi

echo "\nConcluído. Use os RESULT como baseline no roadmap."