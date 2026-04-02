#!/usr/bin/env bash
# Configura métricas e alertas no Google Cloud Monitoring para Cloud Functions (Gen2) e api-service.
#
# Uso:
#   export GOOGLE_CLOUD_PROJECT=app-ajust-provedor
#   export ALERT_EMAIL=seu@email.com          # opcional, cria canal de e-mail
#   ./scripts/setup-monitoring.sh
#
# Requer: Google Cloud SDK (gcloud) instalado e autenticado.
# Alternativa: execute no Cloud Shell -> https://shell.cloud.google.com

set -euo pipefail

if ! command -v gcloud &>/dev/null; then
  echo "❌  gcloud não encontrado."
  echo "    Instale: https://cloud.google.com/sdk/docs/install"
  echo "    Ou copie e cole os comandos individualmente no Cloud Shell:"
  echo "    https://shell.cloud.google.com"
  exit 1
fi

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-app-ajust-provedor}"
ERROR_METRIC="painel_cf_error_lines"
RATE_LIMIT_METRIC="painel_api_rate_limited"
ALERT_EMAIL="${ALERT_EMAIL:-}"
NOTIFICATION_CHANNEL_ID=""

echo "🚀  Projeto: $PROJECT_ID"
gcloud config set project "$PROJECT_ID" >/dev/null

echo ""
echo "==> [1/5] Habilitando APIs..."
gcloud services enable monitoring.googleapis.com logging.googleapis.com --project="$PROJECT_ID" --quiet
echo "    ✅ APIs habilitadas."

echo ""
echo "==> [2/5] Criando métrica de erros em Cloud Functions (Gen2)..."
if gcloud logging metrics describe "$ERROR_METRIC" --project="$PROJECT_ID" &>/dev/null; then
  echo "    Métrica '$ERROR_METRIC' já existe — pulando."
else
  gcloud logging metrics create "$ERROR_METRIC" \
    --project="$PROJECT_ID" \
    --description="Linhas severity>=ERROR em Cloud Run / Firebase Functions v2" \
    --log-filter='resource.type="cloud_run_revision"
severity>=ERROR'
  echo "    ✅ Métrica '$ERROR_METRIC' criada."
fi

echo ""
echo "==> [3/5] Criando métrica de rate-limit na api-service (Docker)..."
if gcloud logging metrics describe "$RATE_LIMIT_METRIC" --project="$PROJECT_ID" &>/dev/null; then
  echo "    Métrica '$RATE_LIMIT_METRIC' já existe — pulando."
else
  gcloud logging metrics create "$RATE_LIMIT_METRIC" \
    --project="$PROJECT_ID" \
    --description="Respostas HTTP 429 (Too Many Requests) na api-service" \
    --log-filter='resource.type="gce_instance"
jsonPayload.statusCode=429'
  echo "    ✅ Métrica '$RATE_LIMIT_METRIC' criada."
fi

echo ""
echo "==> [4/5] Canal de notificação..."
if [[ -n "$ALERT_EMAIL" ]]; then
  echo "    Criando canal de e-mail: $ALERT_EMAIL"
  CHANNEL_OUTPUT=$(gcloud alpha monitoring channels create \
    --display-name="Painel Provedores — Alertas" \
    --type=email \
    --channel-labels=email_address="$ALERT_EMAIL" \
    --project="$PROJECT_ID" \
    --format="value(name)" 2>/dev/null || true)
  if [[ -n "$CHANNEL_OUTPUT" ]]; then
    NOTIFICATION_CHANNEL_ID="$CHANNEL_OUTPUT"
    echo "    ✅ Canal criado: $NOTIFICATION_CHANNEL_ID"
  else
    echo "    ⚠️  Canal pode já existir. Verifique no Console e copie o ID manualmente."
  fi
else
  echo "    ⚠️  ALERT_EMAIL não definido. Defina e execute novamente para criar canal de e-mail."
fi

echo ""
echo "==> [5/5] Criando política de alerta para erros críticos..."
ALERT_POLICY_FILE="$(mktemp /tmp/alert_policy_XXXXXX.json)"

cat > "$ALERT_POLICY_FILE" <<EOF
{
  "displayName": "Painel Provedores — Erros Críticos (Cloud Functions)",
  "conditions": [
    {
      "displayName": "Taxa de erros > 0 em 5 minutos",
      "conditionThreshold": {
        "filter": "metric.type=\"logging.googleapis.com/user/${ERROR_METRIC}\" resource.type=\"cloud_run_revision\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0,
        "duration": "300s",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "perSeriesAligner": "ALIGN_SUM"
          }
        ]
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "3600s"
    }
  },
  "combiner": "OR",
  "enabled": true
  $(if [[ -n "$NOTIFICATION_CHANNEL_ID" ]]; then echo ",\"notificationChannels\": [\"$NOTIFICATION_CHANNEL_ID\"]"; fi)
}
EOF

if gcloud alpha monitoring policies list --project="$PROJECT_ID" --format="value(displayName)" \
   | grep -q "Painel Provedores — Erros Críticos"; then
  echo "    Política já existe — pulando."
else
  gcloud alpha monitoring policies create \
    --policy-from-file="$ALERT_POLICY_FILE" \
    --project="$PROJECT_ID" || echo "    ⚠️  Falha ao criar política via CLI. Crie manualmente conforme instruções abaixo."
  echo "    ✅ Política de alerta criada."
fi
rm -f "$ALERT_POLICY_FILE"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅  Setup concluído!"
echo ""
echo "📊  Links úteis:"
echo "    Logs Explorer (erros):   https://console.cloud.google.com/logs/query;query=severity%3E%3DERROR%20resource.type%3D%22cloud_run_revision%22?project=$PROJECT_ID"
echo "    Métricas:                https://console.cloud.google.com/monitoring/metrics-explorer?project=$PROJECT_ID"
echo "    Alertas:                 https://console.cloud.google.com/monitoring/alerting?project=$PROJECT_ID"
echo ""
echo "📋  Próximos passos (se precisar criar alerta manualmente):"
echo "    1) Acesse: https://console.cloud.google.com/monitoring/alerting/policies/create?project=$PROJECT_ID"
echo "    2) Selecione: Logging → User-defined metrics → $ERROR_METRIC"
echo "    3) Condição: SUM > 0 em 5 minutos"
echo "    4) Adicione canal de notificação (e-mail, Slack, PagerDuty, etc.)"
echo "════════════════════════════════════════════════════════════"
