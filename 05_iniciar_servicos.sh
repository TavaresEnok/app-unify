#!/bin/bash
# Script para Iniciar Todos os Serviços com PM2
# Execute este script NO SERVIDOR NOVO após configurar .env

set -e

echo "============================================"
echo "   INICIANDO SERVIÇOS COM PM2"
echo "============================================"
echo ""

cd /home/app/painel-provedores-projeto

# Parar todos os processos PM2 anteriores (se existirem)
pm2 delete all 2>/dev/null || true

echo "🚀 Iniciando Proxy SGP..."
cd proxy-sgp
pm2 start index.js --name "proxy-sgp" --watch

echo ""
echo "🚀 Iniciando Admin Painel (Dev Server)..."
cd ../admin-painel
pm2 start "npm run dev" --name "admin-painel"

echo ""
echo "🚀 Iniciando API Service..."
cd ../api-service
pm2 start "npm run dev" --name "api-service"

echo ""
echo "💾 Salvando configuração do PM2..."
pm2 save

echo ""
echo "✅ Todos os serviços iniciados!"
echo ""
pm2 status
echo ""
echo "📋 Comandos úteis:"
echo "  - Ver logs: pm2 logs"
echo "  - Ver logs de um serviço: pm2 logs proxy-sgp"
echo "  - Parar tudo: pm2 stop all"
echo "  - Reiniciar: pm2 restart all"
echo "  - Monitorar: pm2 monit"
echo ""
echo "🌐 URLs:"
echo "  - Admin Painel: http://168.194.13.18:5173"
echo "  - Proxy SGP: http://168.194.13.18:3000"
echo "  - API Service: http://168.194.13.18:3001"
echo ""
