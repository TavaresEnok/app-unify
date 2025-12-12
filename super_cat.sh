#!/bin/bash

# Define a raiz absoluta do projeto (assumindo que o script é executado dentro da raiz)
PROJECT_ROOT=$(dirname "$0")

OUTPUT_FILE="$PROJECT_ROOT/dossie_ia_projeto.txt"

echo "Gerando dossiê completo para IA a partir de: $PROJECT_ROOT"

(
echo "=============== DOSSIÊ COMPLETO DO PROJETO ==============="
echo "Data: $(date)"
echo "Raiz: $PROJECT_ROOT"
echo ""

# Função para ler arquivos
ler() {
    REL_PATH="$1"
    FULL_PATH="$PROJECT_ROOT/$REL_PATH"
    
    echo ">>> ARQUIVO: $REL_PATH"
    echo "================================================================"
    if [ -f "$FULL_PATH" ]; then
        cat "$FULL_PATH"
    else
        echo "[ERRO] Arquivo não encontrado: $REL_PATH"
    fi
    echo ""
    echo "----------------------------------------------------------------"
    echo ""
}

echo "=== PARTE 1: BACKEND (CLOUD FUNCTIONS - TypeScript) ==="
ler "functions/src/index.ts"
ler "functions/package.json"
ler "functions/tsconfig.json"

echo "=== PARTE 2: FRONTEND CORE (React/Vite/TSX) ==="
ler "admin-painel/src/main.tsx"
ler "admin-painel/src/App.tsx"
ler "admin-painel/vite.config.ts"
ler "admin-painel/package.json"
ler "admin-painel/tailwind.config.cjs"
ler "admin-painel/src/index.css"

echo "=== PARTE 3: FIREBASE & REGRAS DE SEGURANÇA ==="
ler "firebase.json"
ler "firestore.rules"
ler "firestore.indexes.json"
ler "storage.rules"

echo "=== PARTE 4: LÓGICA DE CONTEXTO E CONFIGURAÇÃO (Mais Crítica) ==="
ler "admin-painel/src/contexts/SettingsContext.tsx"
ler "admin-painel/src/contexts/AuthContext.tsx"
ler "admin-painel/src/hooks/useApi.ts"

echo "=== PARTE 5: PÁGINAS DE CONFIGURAÇÃO DE PROVEDOR ==="
ler "admin-painel/src/pages/provider-settings/AppearanceSettings.tsx"
ler "admin-painel/src/pages/provider-settings/MenusSettingsPage.tsx"
ler "admin-painel/src/pages/provider-settings/SupportSettings.tsx"
ler "admin-painel/src/pages/provider-settings/IntegrationsSettings.tsx"
ler "admin-painel/src/pages/provider-settings/FaqSettings.tsx"

echo "=== PARTE 6: PÁGINAS CHAVE DO PAINEL ADMIN ==="
ler "admin-painel/src/pages/DashboardPage.tsx"
ler "admin-painel/src/pages/ProvidersPage.tsx"
ler "admin-painel/src/pages/AdminTicketsPage.tsx"
ler "admin-painel/src/pages/TicketDetailPage.tsx"
ler "admin-painel/src/pages/ProviderDetailPage.tsx"

echo "=== PARTE 7: PÁGINAS CHAVE DO PORTAL DO PROVEDOR ==="
ler "admin-painel/src/pages/provider/ProviderDashboardPage.tsx"
ler "admin-painel/src/pages/provider/ProviderTicketsPage.tsx"
ler "admin-painel/src/pages/provider/MyCompanyPage.tsx"


echo "=============== FIM DO DOSSIÊ ==============="
) > "$OUTPUT_FILE"

echo "✅ Dossiê Completo Gerado!"
echo "Arquivo salvo em: $OUTPUT_FILE"

