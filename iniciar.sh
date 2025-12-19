#!/bin/bash
cd /home/app/painel-provedores-projeto

echo "🛑 Parando serviços antigos..."
pm2 delete all 2>/dev/null || true

echo "🚀 Iniciando serviços..."
cd proxy-sgp
pm2 start index.js --name "proxy-sgp"

cd ../admin-painel
pm2 start "npm run dev" --name "admin-painel"

cd ../api-service
pm2 start "npm run dev" --name "api-service"

cd ../speed_test_server
pm2 start server.js --name "speed-test-server"

pm2 save
echo ""
echo "✅ Serviços iniciados!"
pm2 list
echo ""
echo "🌐 Acesse:"
echo "   Admin: http://168.194.13.18:5173"
echo "   Proxy: http://168.194.13.18:3000"
