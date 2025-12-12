#!/bin/bash
# Script de Descompactação e Configuração do Projeto
# Execute este script NO SERVIDOR NOVO após o setup

set -e

echo "============================================"
echo "   DESCOMPACTAÇÃO E SETUP DO PROJETO"
echo "============================================"
echo ""

# Encontrar o backup mais recente
LATEST_BACKUP=$(ls -t /home/app/painel-provedores-projeto_*.tar.gz 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ Erro: Nenhum backup encontrado em /home/app/"
    exit 1
fi

echo "📦 Backup encontrado: $(basename $LATEST_BACKUP)"
echo ""

# Descompactar
echo "📂 Descompactando projeto..."
cd /home/app
tar -xzf "$LATEST_BACKUP"

# Navegar para o projeto
cd /home/app/painel-provedores-projeto

echo ""
echo "📦 Instalando dependências do Admin Painel..."
cd admin-painel
npm install

echo ""
echo "📦 Instalando dependências do Proxy SGP..."
cd ../proxy-sgp
npm install

echo ""
echo "📦 Instalando dependências do API Service..."
cd ../api-service
npm install

echo ""
echo "📦 Instalando dependências do Functions..."
cd ../functions
npm install

echo ""
echo "📱 Configurando Flutter (App Unificado)..."
cd ../app-flutter/unified
export PATH="$PATH:/home/app/flutter/bin"
flutter pub get

echo ""
echo "✅ Projeto configurado!"
echo ""
echo "📋 Próximos passos MANUAIS:"
echo ""
echo "1. Configurar variáveis de ambiente:"
echo "   - Edite /home/app/painel-provedores-projeto/.env"
echo "   - Atualize URLs e credenciais para o novo servidor"
echo ""
echo "2. Configurar Firebase:"
echo "   - Verifique credenciais em firebase.json"
echo "   - Se necessário, faça login: firebase login"
echo ""
echo "3. Iniciar serviços com PM2:"
echo "   Execute o script: bash 05_iniciar_servicos.sh"
echo ""
