#!/usr/bin/env bash
# Configura métricas e alertas básicos no Google Cloud Monitoring para Cloud Functions (Gen2 = Cloud Run).
# Uso: export GOOGLE_CLOUD_PROJECT=app-ajust-provedor && ./scripts/setup-monitoring.sh
# Requer: Google Cloud SDK (gcloud) instalado e autenticado.

set -euo pipefail

if ! command -v gcloud &>/dev/null; then
  echo "gcloud não encontrado. Instale: https://cloud.google.com/sdk/docs/install"
  echo "Ou use o Cloud Shell (https://shell.cloud.google.com) e execute este script no repositório."
  exit 1
fi

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-app-ajust-provedor}"
METRIC_NAME="painel_cf_error_lines"
CHANNEL_NAME="${ALERT_EMAIL:-}"

echo "==> Projeto: $PROJECT_ID"

gcloud config set project "$PROJECT_ID" >/dev/null

echo "==> Habilitando APIs de Monitoring e Logging..."
gcloud services enable monitoring.googleapis.com logging.googleapis.com --project="$PROJECT_ID" --quiet

echo "==> Criando métrica baseada em log (erros em revisões Cloud Run das Functions)..."
# Gen2 Functions aparecem como cloud_run_revision no Logging
if gcloud logging metrics describe "$METRIC_NAME" --project="$PROJECT_ID" &>/dev/null; then
  echo "    Métrica '$METRIC_NAME' já existe — pulando criação."
else
  gcloud logging metrics create "$METRIC_NAME" \
    --project="$PROJECT_ID" \
    --description="Linhas de log com severity>=ERROR em serviços Cloud Run (inclui Firebase Functions v2)" \
    --log-filter='resource.type="cloud_run_revision"
severity>=ERROR'
  echo "    Métrica criada: $METRIC_NAME"
fi

if [[ -n "$CHANNEL_NAME" ]]; then
  echo "==> Criando canal de notificação por e-mail: $CHANNEL_NAME"
  gcloud alpha monitoring channels create \
    --display-name="Painel provedores — alertas" \
    --type=email \
    --channel-labels=email_address="$CHANNEL_NAME" \
    --project="$PROJECT_ID" 2>/dev/null || echo "    (Canal já pode existir ou comando alpha indisponível — crie no Console.)"
else
  echo "==> Dica: defina ALERT_EMAIL=seu@email.com e execute de novo para criar canal de e-mail."
fi

echo ""
echo "==> Próximo passo manual (2 minutos):"
echo "    1) Abra: https://console.cloud.google.com/monitoring/alerting?project=$PROJECT_ID"
echo "    2) Crie alerta: Métrica → Logging → user.$METRIC_NAME → condição > 0 em 5 min"
echo "    3) Adicione notificação por e-mail ou Slack"
echo ""
echo "==> Dashboard de erros (Logs Explorer):"
echo "    https://console.cloud.google.com/logs/query?project=$PROJECT_ID"
echo "    Filtro sugerido: severity>=ERROR resource.type=\"cloud_run_revision\""
