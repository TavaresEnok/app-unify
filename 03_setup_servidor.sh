#!/bin/bash
# Script de Setup do Novo Servidor
# Execute este script NO SERVIDOR NOVO (168.194.13.18)

set -e

echo "============================================"
echo "   SETUP DO SERVIDOR NOVO"
echo "============================================"
echo ""

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo apt-get update
sudo apt-get upgrade -y

# Instalar dependências base
echo ""
echo "📦 Instalando dependências base..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    unzip \
    software-properties-common \
    ca-certificates \
    gnupg

# Instalar Node.js 20.x (LTS)
echo ""
echo "📦 Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar instalação
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
echo "✅ Node.js instalado: $NODE_VERSION"
echo "✅ npm instalado: $NPM_VERSION"

# Instalar PM2 (Process Manager)
echo ""
echo "📦 Instalando PM2..."
sudo npm install -g pm2

# Configurar PM2 para iniciar no boot
sudo pm2 startup systemd -u app --hp /home/app

# Instalar Flutter SDK (para builds do app)
echo ""
echo "📦 Instalando Flutter SDK..."
cd /home/app
if [ ! -d "flutter" ]; then
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
    tar xf flutter_linux_3.24.5-stable.tar.xz
    rm flutter_linux_3.24.5-stable.tar.xz
fi

# Adicionar Flutter ao PATH
if ! grep -q "flutter/bin" ~/.bashrc; then
    echo 'export PATH="$PATH:/home/app/flutter/bin"' >> ~/.bashrc
fi

export PATH="$PATH:/home/app/flutter/bin"

# Aceitar licenças do Android
yes | flutter doctor --android-licenses 2>/dev/null || true

echo ""
echo "✅ Dependências instaladas!"
echo ""
echo "📋 Resumo:"
echo "  - Node.js: $NODE_VERSION"
echo "  - npm: $NPM_VERSION"
echo "  - PM2: $(pm2 --version)"
echo "  - Flutter: $(flutter --version | head -1)"
echo ""
echo "Próximo passo: Execute o script 04_descompactar_setup.sh"
echo ""
