#!/bin/bash
# ============================================
# MIGRAÇÃO AUTOMÁTICA COMPLETA
# Execute apenas este script!
# ============================================

clear
echo "╔════════════════════════════════════════════╗"
echo "║   MIGRAÇÃO AUTOMÁTICA PARA NOVO SERVIDOR   ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Configurações
NOVO_IP="168.194.13.18"
USUARIO="app"
SENHA="asdSD@91582685"

# Verificar se está no diretório correto
if [ ! -d "admin-painel" ]; then
    echo "❌ ERRO: Execute este script de dentro da pasta painel-provedores-projeto"
    exit 1
fi

echo "📋 O que este script vai fazer:"
echo "   1. Instalar sshpass (se necessário)"
echo "   2. Criar backup do projeto"
echo "   3. Transferir para $NOVO_IP"
echo "   4. Configurar servidor novo automaticamente"
echo ""
read -p "Continuar? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado pelo usuário"
    exit 1
fi

# ============================================
# PASSO 1: Instalar sshpass
# ============================================
echo ""
echo "🔧 [1/5] Instalando sshpass..."
if ! command -v sshpass &> /dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y sshpass
    echo "✅ sshpass instalado"
else
    echo "✅ sshpass já instalado"
fi

# ============================================
# PASSO 2: Criar backup
# ============================================
echo ""
echo "📦 [2/5] Criando backup do projeto..."
BACKUP_DIR="/tmp"
BACKUP_FILE="${BACKUP_DIR}/projeto_backup.tar.gz"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

cd /home/app
tar -czf "${BACKUP_FILE}" \
    --exclude="painel-provedores-projeto/node_modules" \
    --exclude="painel-provedores-projeto/admin-painel/node_modules" \
    --exclude="painel-provedores-projeto/admin-painel/dist" \
    --exclude="painel-provedores-projeto/proxy-sgp/node_modules" \
    --exclude="painel-provedores-projeto/api-service/node_modules" \
    --exclude="painel-provedores-projeto/functions/node_modules" \
    --exclude="painel-provedores-projeto/app-flutter/*/build" \
    --exclude="painel-provedores-projeto/.git" \
    --exclude="painel-provedores-projeto/nohup.out" \
    --exclude="painel-provedores-projeto/firebase-export-*" \
    painel-provedores-projeto 2>/dev/null

TAMANHO=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "✅ Backup criado: $TAMANHO"

# ============================================
# PASSO 3: Transferir backup
# ============================================
echo ""
echo "🚀 [3/5] Transferindo backup para $NOVO_IP..."
sshpass -p "${SENHA}" scp -o StrictHostKeyChecking=no "${BACKUP_FILE}" ${USUARIO}@${NOVO_IP}:/home/app/ 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Backup transferido com sucesso"
else
    echo "❌ Erro ao transferir. Verifique IP e senha"
    exit 1
fi

# ============================================
# PASSO 4: Criar script de setup no servidor novo
# ============================================
echo ""
echo "⚙️  [4/5] Preparando servidor novo..."

SETUP_SCRIPT=$(cat << 'EOF'
#!/bin/bash
set -e
echo "Instalando dependências..."
sudo apt-get update -qq
sudo apt-get install -y curl wget git build-essential unzip -qq

echo "Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>/dev/null
sudo apt-get install -y nodejs -qq

echo "Instalando PM2..."
sudo npm install -g pm2 --silent

echo "Descompactando projeto..."
cd /home/app
tar -xzf projeto_backup.tar.gz 2>/dev/null

echo "Instalando dependências do projeto..."
cd painel-provedores-projeto

cd admin-painel && npm install --silent &
cd ../proxy-sgp && npm install --silent &
cd ../api-service && npm install --silent &
cd ../functions && npm install --silent &
wait

echo "✅ Setup concluído!"
EOF
)

echo "$SETUP_SCRIPT" > /tmp/setup_rapido.sh

# Transferir e executar script de setup
sshpass -p "${SENHA}" scp -o StrictHostKeyChecking=no /tmp/setup_rapido.sh ${USUARIO}@${NOVO_IP}:/home/app/ 2>/dev/null
sshpass -p "${SENHA}" ssh -o StrictHostKeyChecking=no ${USUARIO}@${NOVO_IP} "bash /home/app/setup_rapido.sh" 2>&1

# ============================================
# PASSO 5: Criar script de inicialização
# ============================================
echo ""
echo "🎯 [5/5] Criando script de inicialização no servidor..."

START_SCRIPT=$(cat << 'EOF'
#!/bin/bash
cd /home/app/painel-provedores-projeto
pm2 delete all 2>/dev/null || true
cd proxy-sgp && pm2 start index.js --name proxy-sgp
cd ../admin-painel && pm2 start "npm run dev" --name admin-painel
cd ../api-service && pm2 start "npm run dev" --name api-service
pm2 save
pm2 list
echo ""
echo "Serviços rodando em:"
echo "  Admin: http://168.194.13.18:5173"
echo "  Proxy: http://168.194.13.18:3000"
EOF
)

echo "$START_SCRIPT" > /tmp/iniciar.sh
sshpass -p "${SENHA}" scp -o StrictHostKeyChecking=no /tmp/iniciar.sh ${USUARIO}@${NOVO_IP}:/home/app/painel-provedores-projeto/ 2>/dev/null
sshpass -p "${SENHA}" ssh -o StrictHostKeyChecking=no ${USUARIO}@${NOVO_IP} "chmod +x /home/app/painel-provedores-projeto/iniciar.sh"

# ============================================
# FINALIZAÇÃO
# ============================================
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║           ✅ MIGRAÇÃO CONCLUÍDA!            ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "📋 PRÓXIMOS PASSOS (apenas 2!):"
echo ""
echo "1️⃣  Conectar ao servidor novo:"
echo "   ssh app@168.194.13.18"
echo ""
echo "2️⃣  Iniciar os serviços:"
echo "   bash /home/app/painel-provedores-projeto/iniciar.sh"
echo ""
echo "🌐 URLs após iniciar:"
echo "   Admin: http://168.194.13.18:5173"
echo "   Proxy: http://168.194.13.18:3000"
echo ""
