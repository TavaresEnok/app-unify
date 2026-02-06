#!/bin/bash
# ========================================
# SCRIPT DE INSTALAÇÃO AUTOMÁTICA
# Adiciona rotas de diagnóstico ao proxy SGP
# ========================================

echo "🚀 Instalador de Rotas de Diagnóstico - Sistema de Diagnóstico Revolucionário"
echo "=============================================================================="
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

# Verifica se está no servidor correto
echo "📍 Verificando ambiente..."
if [ "$(whoami)" != "root" ]; then
    log_error "Este script deve ser executado como root"
    exit 1
fi

if [ ! -d "$PROXY_DIR" ]; then
    log_error "Diretório $PROXY_DIR não encontrado"
    exit 1
fi

log_success "Ambiente verificado"

# Cria diretório de backup
echo ""
echo "💾 Criando backup..."
mkdir -p "$BACKUP_DIR"
cp "$PROXY_DIR/index.js" "$BACKUP_DIR/index.js.$TIMESTAMP"
log_success "Backup criado em: $BACKUP_DIR/index.js.$TIMESTAMP"

# Verifica se as rotas já existem
if grep -q "/diagnostic/onu-signal" "$PROXY_DIR/index.js"; then
    log_warning "Rotas de diagnóstico já parecem estar instaladas"
    read -p "Deseja reinstalar? (s/N): " reinstall
    if [ "$reinstall" != "s" ] && [ "$reinstall" != "S" ]; then
        echo "Instalação cancelada"
        exit 0
    fi
fi

# Adiciona as rotas
echo ""
echo "📝 Adicionando rotas de diagnóstico..."

# Encontra a linha antes de "const PORT"
LINE_NUMBER=$(grep -n "const PORT = 3002;" "$PROXY_DIR/index.js" | cut -d: -f1)

if [ -z "$LINE_NUMBER" ]; then
    log_error "Não foi possível encontrar 'const PORT = 3002;' no arquivo"
    exit 1
fi

# Cria arquivo temporário com as novas rotas
cat > /tmp/diagnostic_routes.txt << 'EOF'

// ========================================
// ROTAS DE DIAGNÓSTICO - Adicionadas automaticamente
// Data de instalação: $(date)
// ========================================

// ROTA 8: BUSCAR SINAL DA ONU (DIAGNÓSTICO)
app.post('/diagnostic/onu-signal', async (req, res) => {
    const { cpfCnpj, senha, contrato, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';

    if (!cpfCnpjUnformatted || !senha || !contrato || !sgpParams || !sgpBaseUrl) {
        return res.status(400).json({ error: { message: "cpfCnpj, senha, contrato, sgpParams e sgpBaseUrl são obrigatórios." } });
    }

    console.log(`[Diagnostic ONU] Buscando sinal da ONU para contrato: ${contrato}`);

    try {
        const onuParams = {
            ...sgpParams,
            cpfcnpj: cpfCnpjUnformatted,
            senha: senha,
            contrato: contrato.toString(),
            signal: '1',
            connection: '1',
            temperature: '1',
            url: formatSgpUrl(sgpBaseUrl, '/api/fttx/onu/list/')
        };

        const onuResponse = await executePhp(onuParams);

        if (!onuResponse || !Array.isArray(onuResponse) || onuResponse.length === 0) {
            return res.status(404).json({ error: { message: "Nenhuma ONU encontrada para este contrato." } });
        }

        const onu = onuResponse[0];
        
        const formattedData = {
            signalRx: parseFloat(onu.signal?.rx || onu.rx_power || '-999'),
            signalTx: parseFloat(onu.signal?.tx || onu.tx_power || '-999'),
            connectionStatus: onu.connection || onu.status || 'unknown',
            oltId: parseInt(onu.olt_id || onu.oltId || '0'),
            slot: parseInt(onu.slot || '0'),
            pon: parseInt(onu.pon || '0'),
            onuId: parseInt(onu.onuid || onu.onu_id || '0'),
            temperature: onu.temperature ? parseFloat(onu.temperature) : null,
            oltTemperature: onu.olt_temperature ? parseFloat(onu.olt_temperature) : null,
            voltage: onu.voltage ? parseFloat(onu.voltage) : null,
            model: onu.modelo || onu.model || 'Desconhecido',
            serialNumber: onu.serial || onu.serial_number || null,
        };

        console.log(`[Diagnostic ONU] RX=${formattedData.signalRx} dBm, TX=${formattedData.signalTx} dBm`);
        res.status(200).json({ data: formattedData });

    } catch (error) {
        console.error("Erro /diagnostic/onu-signal:", error.message);
        res.status(500).json({ error: { message: error.message || "Erro ao buscar sinal da ONU." } });
    }
});

// ROTA 9: VERIFICAR STATUS DE ACESSO (DIAGNÓSTICO)
app.post('/diagnostic/verify-access', async (req, res) => {
    const { cpfCnpj, senha, contrato, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';

    if (!cpfCnpjUnformatted || !contrato || !sgpParams || !sgpBaseUrl) {
        return res.status(400).json({ error: { message: "cpfCnpj, contrato, sgpParams e sgpBaseUrl são obrigatórios." } });
    }

    try {
        const accessParams = {
            ...sgpParams,
            contrato: contrato.toString(),
            uracontato: '',
            url: formatSgpUrl(sgpBaseUrl, '/ws/ura/verificaacesso/')
        };

        const accessResponse = await executePhp(accessParams);
        const status = parseInt(accessResponse.status || '0');
        
        const statusMap = { 1: 'Online', 2: 'Offline', 3: 'Bloqueado por Inadimplência', 8: 'Em Manutenção', 9: 'Manutenção Programada' };

        res.status(200).json({ 
            data: {
                status,
                statusText: statusMap[status] || 'Desconhecido',
                message: accessResponse.msg || '',
                maintenance: status === 8 || status === 9,
                blocked: status === 3 || status === 4,
                estimatedTime: accessResponse.tempo || null,
            }
        });
    } catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});

// ROTA 10: ABRIR CHAMADO TÉCNICO
app.post('/diagnostic/open-ticket', async (req, res) => {
    const { cpfCnpj, senha, contrato, content, priority, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';

    if (!cpfCnpjUnformatted || !senha || !contrato || !content || !sgpParams || !sgpBaseUrl) {
        return res.status(400).json({ error: { message: "Dados incompletos" } });
    }

    try {
        const ticketParams = {
            ...sgpParams,
            cpfcnpj: cpfCnpjUnformatted,
            senha: senha,
            contrato: contrato.toString(),
            conteudo: content,
            ocorrenciatipo: '5',
            motivoos: '40',
            os_prioridade: (priority || 2).toString(),
            url: formatSgpUrl(sgpBaseUrl, '/api/central/chamado/')
        };

        const ticketResponse = await executePhp(ticketParams);

        res.status(200).json({ 
            data: {
                ticketId: ticketResponse.os_id?.toString(),
                protocol: ticketResponse.protocolo,
                message: 'Chamado criado com sucesso'
            }
        });
    } catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});

// ROTA 11: ANÁLISE COMPLETA (Expert System)
app.post('/diagnostic/analyze', async (req, res) => {
    const { localTests, sgpData, clientInfo } = req.body;

    if (!localTests || !sgpData) {
        return res.status(400).json({ error: { message: "localTests e sgpData obrigatórios" } });
    }

    let problem, category, confidence, solution, estimatedTime, priority = 2;

    // Expert System
    if (sgpData.signalRx < -26) {
        problem = 'Sinal Óptico Degradado';
        category = 'FIBER_ISSUE';
        confidence = 0.95;
        solution = 'Técnico necessário para verificar conectores e emendas';
        estimatedTime = '15-20 minutos';
        priority = 3;
    } else if (sgpData.maintenance) {
        problem = 'Manutenção Programada';
        category = 'MAINTENANCE';
        confidence = 1.0;
        solution = 'Aguarde o término da manutenção';
        estimatedTime = sgpData.estimatedTime || 'A definir';
        priority = 1;
    } else if (sgpData.blocked) {
        problem = 'Bloqueio por Inadimplência';
        category = 'BILLING_BLOCK';
        confidence = 1.0;
        solution = 'Regularize o pagamento';
        estimatedTime = 'Imediato';
        priority = 1;
    } else if (sgpData.signalRx >= -23 && localTests.latency > 100) {
        problem = 'Problema de Latência';
        category = 'WIFI_ISSUE';
        confidence = 0.80;
        solution = 'Verifique WiFi ou aproxime-se do roteador';
        estimatedTime = '0 minutos';
        priority = 1;
    } else {
        problem = 'Conexão Normal';
        category = 'HEALTHY';
        confidence = 0.90;
        solution = 'Seus parâmetros estão OK';
        estimatedTime = 'N/A';
        priority = 1;
    }

    res.status(200).json({ 
        data: { problem, category, confidence, solution, estimatedTime, priority, timestamp: new Date().toISOString() }
    });
});

// ========================================
// FIM DAS ROTAS DE DIAGNÓSTICO
// ========================================

EOF

# Insere as rotas antes de "const PORT"
INSERT_LINE=$((LINE_NUMBER-1))
{
    head -n $INSERT_LINE "$PROXY_DIR/index.js"
    cat /tmp/diagnostic_routes.txt
    tail -n +$((INSERT_LINE+1)) "$PROXY_DIR/index.js"
} > /tmp/index.js.new

# Substitui o arquivo original
mv /tmp/index.js.new "$PROXY_DIR/index.js"
rm /tmp/diagnostic_routes.txt

log_success "Rotas adicionadas com sucesso!"

# Reinicia o servidor
echo ""
echo "🔄 Reiniciando servidor proxy..."

if command -v pm2 &> /dev/null; then
    pm2 restart proxy-sgp 2>/dev/null || pm2 start "$PROXY_DIR/index.js" --name proxy-sgp
    log_success "Servidor reiniciado via PM2"
else
    log_warning "PM2 não encontrado. Reinicie manualmente: cd $PROXY_DIR && node index.js"
fi

# Resumo
echo ""
echo "=============================================================================="
log_success "INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "📋 Rotas adicionadas:"
echo "   • POST /diagnostic/onu-signal"
echo "   • POST /diagnostic/verify-access"
echo "   • POST /diagnostic/open-ticket"
echo "   • POST /diagnostic/analyze"
echo ""
echo "💾 Backup salvo em: $BACKUP_DIR/index.js.$TIMESTAMP"
echo ""
echo "🔗 Endpoint do proxy: http://45.176.56.70:3000"
echo ""
log_success "Sistema pronto para receber diagnósticos!"
echo "=============================================================================="
