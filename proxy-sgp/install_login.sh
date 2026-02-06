#!/bin/bash
# ========================================
# SCRIPT DE INSTALAÇÃO DA ROTA DE LOGIN
# Adiciona a rota /check-cpf ao proxy SGP
# ========================================
echo "🚀 Instalador da Rota de Login (/check-cpf)"
echo "=================================================="
echo ""
# Configurações
PROXY_DIR="$HOME/proxy-sgp"
BACKUP_DIR="$HOME/proxy-sgp-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
# Função de log
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}
log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}
log_error() {
    echo -e "${RED}❌ $1${NC}"
}
# Verifica se está no servidor correto (root)
if [ "$(whoami)" != "root" ]; then
    log_error "Este script deve ser executado como root"
    exit 1
fi
if [ ! -d "$PROXY_DIR" ]; then
    log_error "Diretório $PROXY_DIR não encontrado"
    exit 1
fi
# Cria diretório de backup
mkdir -p "$BACKUP_DIR"
cp "$PROXY_DIR/index.js" "$BACKUP_DIR/index.js.login_backup.$TIMESTAMP"
log_success "Backup criado em: $BACKUP_DIR/index.js.login_backup.$TIMESTAMP"
# Verifica se a rota já existe
if grep -q "/check-cpf" "$PROXY_DIR/index.js"; then
    log_warning "A rota /check-cpf já parece estar instalada."
    read -p "Deseja reinstalar? (s/N): " reinstall
    if [ "$reinstall" != "s" ] && [ "$reinstall" != "S" ]; then
        echo "Instalação cancelada"
        exit 0
    fi
fi
# Encontra a linha antes de "const PORT" para inserir a rota
LINE_NUMBER=$(grep -n "const PORT = 3002;" "$PROXY_DIR/index.js" | cut -d: -f1)
if [ -z "$LINE_NUMBER" ]; then
    log_error "Não foi possível encontrar 'const PORT = 3002;' no arquivo"
    exit 1
fi
# Cria arquivo temporário com a rota de login
cat > /tmp/login_route.txt << 'EOF'
// ========================================
// ROTA DE LOGIN (Adicionada automaticamente)
// ========================================
app.post('/check-cpf', async (req, res) => {
    const { cpf, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpf ? cpf.replace(/[^0-9]/g, '') : '';
    if (!cpfCnpjUnformatted || !sgpParams || !sgpBaseUrl) {
        return res.status(400).json({
            error: { message: "cpf, sgpParams e sgpBaseUrl são obrigatórios." }
        });
    }
    console.log(`[Login] Verificando CPF/CNPJ: ${cpfCnpjUnformatted}`);
    try {
        // Busca cliente no SGP
        const clientParams = {
            ...sgpParams,
            q: cpfCnpjUnformatted,
            cpf_cnpj: cpfCnpjUnformatted,
            url: formatSgpUrl(sgpBaseUrl, '/api/cliente/list/')
        };
        const clientResponse = await executePhp(clientParams);
        if (!clientResponse || !Array.isArray(clientResponse) || clientResponse.length === 0) {
            console.warn(`[Login] Cliente não encontrado: ${cpfCnpjUnformatted}`);
            return res.status(404).json({
                error: { message: "Cliente não encontrado." }
            });
        }
        const client = clientResponse[0];
        const formattedData = {
            nome: client.nome || client.razao_social || 'Cliente',
            cpfCnpj: client.cpf_cnpj || cpfCnpjUnformatted,
            senha: client.senha || '',
            plano: client.plano_nome || 'Plano Padrão',
            status: client.bloqueado === 'S' ? 'Bloqueado' : 'Ativo',
            valorFatura: '0,00',
            vencimentoFatura: '10',
            contratoId: client.id || client.contrato_id,
            email: client.email
        };
        console.log(`[Login] Cliente encontrado: ${formattedData.nome}`);
        res.status(200).json(formattedData);
    } catch (error) {
        console.error("Erro na rota /check-cpf:", error.message);
        res.status(500).json({
            error: { message: error.message || "Erro interno ao verificar CPF." }
        });
    }
});
EOF
# Insere a rota no arquivo index.js
INSERT_LINE=$((LINE_NUMBER-1))
{
    head -n $INSERT_LINE "$PROXY_DIR/index.js"
    cat /tmp/login_route.txt
    tail -n +$((INSERT_LINE+1)) "$PROXY_DIR/index.js"
} > /tmp/index.js.new
# Substitui o arquivo original
mv /tmp/index.js.new "$PROXY_DIR/index.js"
rm /tmp/login_route.txt
log_success "Rota /check-cpf adicionada com sucesso!"
# Reinicia o servidor
echo ""
echo "🔄 Reiniciando servidor proxy..."
if command -v pm2 &> /dev/null; then
    pm2 restart proxy-sgp 2>/dev/null || pm2 start "$PROXY_DIR/index.js" --name proxy-sgp
    log_success "Servidor reiniciado via PM2"
else
    log_warning "PM2 não encontrado. Reinicie manualmente: cd $PROXY_DIR && node index.js"
fi
echo ""
log_success "INSTALAÇÃO CONCLUÍDA! Tente fazer login no app novamente."
