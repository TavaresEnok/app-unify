#!/bin/bash
# Script de Transferência para Novo Servidor
# IP do novo servidor: 168.194.13.18

set -e

echo "============================================"
echo "   TRANSFERÊNCIA PARA NOVO SERVIDOR"
echo "============================================"
echo ""

# Configurações do servidor novo
NEW_SERVER_IP="168.194.13.18"
NEW_SERVER_USER="app"
NEW_SERVER_PASS="asdSD@91582685"

# Encontrar o backup mais recente
BACKUP_DIR="/home/app/backups"
LATEST_BACKUP=$(ls -t ${BACKUP_DIR}/painel-provedores-projeto_*.tar.gz 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ Erro: Nenhum backup encontrado!"
    echo "Execute primeiro o script 01_backup.sh"
    exit 1
fi

echo "📦 Backup encontrado: $(basename $LATEST_BACKUP)"
echo "🎯 Servidor destino: ${NEW_SERVER_USER}@${NEW_SERVER_IP}"
echo ""

# Instalar sshpass se não estiver instalado (para automação de senha)
if ! command -v sshpass &> /dev/null; then
    echo "⚙️  Instalando sshpass..."
    sudo apt-get update -qq
    sudo apt-get install -y sshpass
fi

echo "🚀 Transferindo arquivo..."
sshpass -p "${NEW_SERVER_PASS}" scp -o StrictHostKeyChecking=no \
    "${LATEST_BACKUP}" \
    "${NEW_SERVER_USER}@${NEW_SERVER_IP}:/home/app/"

echo ""
echo "✅ Transferência concluída!"
echo ""
echo "Próximo passo:"
echo "1. Copie também o script de setup:"
echo "   sshpass -p '${NEW_SERVER_PASS}' scp 03_setup_servidor.sh ${NEW_SERVER_USER}@${NEW_SERVER_IP}:/home/app/"
echo ""
echo "2. Conecte ao servidor e execute o setup:"
echo "   ssh ${NEW_SERVER_USER}@${NEW_SERVER_IP}"
echo "   bash /home/app/03_setup_servidor.sh"
echo ""
