#!/bin/bash
# Script de Backup e Compactação do Sistema
# Autor: Sistema Antigravity
# Data: $(date +%Y-%m-%d)

set -e  # Para o script em caso de erro

echo "============================================"
echo "   BACKUP DO PAINEL PROVEDORES PROJETO"
echo "============================================"
echo ""

# Configurações
PROJECT_NAME="painel-provedores-projeto"
BACKUP_DIR="/home/app/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${PROJECT_NAME}_${TIMESTAMP}.tar.gz"

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

echo "📦 Criando backup..."
echo "Origem: /home/app/${PROJECT_NAME}"
echo "Destino: ${BACKUP_FILE}"
echo ""

# Compactar EXCLUINDO pastas pesadas desnecessárias
cd /home/app
tar -czf "${BACKUP_FILE}" \
    --exclude="${PROJECT_NAME}/node_modules" \
    --exclude="${PROJECT_NAME}/admin-painel/node_modules" \
    --exclude="${PROJECT_NAME}/admin-painel/dist" \
    --exclude="${PROJECT_NAME}/admin-painel/build" \
    --exclude="${PROJECT_NAME}/proxy-sgp/node_modules" \
    --exclude="${PROJECT_NAME}/api-service/node_modules" \
    --exclude="${PROJECT_NAME}/api-service/dist" \
    --exclude="${PROJECT_NAME}/functions/node_modules" \
    --exclude="${PROJECT_NAME}/app-flutter/*/build" \
    --exclude="${PROJECT_NAME}/app-flutter/*/.dart_tool" \
    --exclude="${PROJECT_NAME}/app-flutter/*/android/build" \
    --exclude="${PROJECT_NAME}/app-flutter/*/ios/Pods" \
    --exclude="${PROJECT_NAME}/.git" \
    --exclude="${PROJECT_NAME}/firestore-debug.log" \
    --exclude="${PROJECT_NAME}/nohup.out" \
    --exclude="${PROJECT_NAME}/firebase-export-*" \
    "${PROJECT_NAME}"

# Verificar tamanho do arquivo
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo ""
echo "✅ Backup criado com sucesso!"
echo "📁 Arquivo: ${BACKUP_FILE}"
echo "📊 Tamanho: ${BACKUP_SIZE}"
echo ""
echo "Para transferir para o novo servidor, execute:"
echo "scp ${BACKUP_FILE} app@168.194.13.18:/home/app/"
echo ""
