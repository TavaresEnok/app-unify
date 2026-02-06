#!/bin/bash
# ========================================
# SCRIPT DE CORREÇÃO TOTAL DO PROXY
# Sobrescreve index.js com a versão correta
# ========================================
echo "🚀 Corretor Total do Proxy SGP"
echo "=================================================="
PROXY_DIR="$HOME/proxy-sgp"
BACKUP_DIR="$HOME/proxy-sgp-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# Verifica root
if [ "$(whoami)" != "root" ]; then
    echo "❌ Execute como root"
    exit 1
fi
if [ ! -d "$PROXY_DIR" ]; then
    echo "❌ Diretório $PROXY_DIR não encontrado"
    exit 1
fi
# Backup
mkdir -p "$BACKUP_DIR"
cp "$PROXY_DIR/index.js" "$BACKUP_DIR/index.js.full_backup.$TIMESTAMP"
echo "✅ Backup salvo em $BACKUP_DIR/index.js.full_backup.$TIMESTAMP"
# Escreve o novo index.js completo
echo "📝 Escrevendo novo index.js..."
cat > "$PROXY_DIR/index.js" << 'EOF'
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { spawn } = require('child_process');
const sqlite3 = require('sqlite3').verbose();
const app = express();
app.use(cors());
app.use(bodyParser.json());
const PROXY_SECRET_KEY = "CHAVE_SECRETA_MUITO_FORTE_12345"; 
const DB_FILE_PATH = './cache.db'; 
const db = new sqlite3.Database(DB_FILE_PATH, (err) => {
    if (err) console.error("Erro ao abrir o banco de dados:", err.message);
    else console.log("Conectado ao banco de dados SQLite 'cache.db'.");
});
function executePhp(params) {
    return new Promise((resolve, reject) => {
        const phpProcess = spawn('php', ['proxy.php']);
        let stdoutData = '';
        let stderrData = '';
        phpProcess.stdout.on('data', (data) => { stdoutData += data.toString(); });
        phpProcess.stderr.on('data', (data) => { stderrData += data.toString(); });
        phpProcess.on('close', (code) => {
            if (code !== 0 || stderrData) {
                console.error("Erro no processo PHP:", stderrData || `Código de saída ${code}`);
                return reject(new Error(stderrData || `Processo PHP terminou com código ${code}`));
            }
            try {
                resolve(JSON.parse(stdoutData));
            } catch (e) {
                console.error("Resposta inválida (não JSON) do PHP:", stdoutData);
                reject(new Error(`Resposta inválida do PHP: ${stdoutData}`));
            }
        });
        phpProcess.stdin.write(JSON.stringify({ params }));
        phpProcess.stdin.end();
    });
}
function formatSgpUrl(sgpBaseUrl, path) {
    let base = sgpBaseUrl.trim().replace(/\/$/, '');
    return `${base}${path}`;
}
// ROTA 5: BUSCAR DADOS DE CONSUMO
app.post('/get-consumption-data', async (req, res) => {
    const { cpfCnpj, senha, sgpParams, sgpBaseUrl } = req.body; 
    if (!cpfCnpj || !senha || !sgpParams || !sgpBaseUrl) {
        return res.status(400).json({ error: { message: "cpfCnpj, senha, sgpParams e sgpBaseUrl são obrigatórios." } });
    }
    try {
        console.log(`[Consumo] Buscando dados de consumo para: ${cpfCnpj}`);
        const consultaParams = {
            ...sgpParams,
            cpfcnpj: cpfCnpj,
            url: formatSgpUrl(sgpBaseUrl, '/ws/ura/consultacliente/')
        };
        const consultaResponse = await executePhp(consultaParams);
        if (!consultaResponse || !Array.isArray(consultaResponse.contratos) || consultaResponse.contratos.length === 0) {
            return res.status(404).json({ error: { message: "Nenhum contrato encontrado." } });
        }
        const contratoId = consultaResponse.contratos[0].contratoId;
        const hoje = new Date();
        const extratoParams = {
            ...sgpParams,
            cpfcnpj: cpfCnpj,
            senha: senha,
            contrato: contratoId.toString(),
            mes: (hoje.getMonth() + 1).toString(),
            ano: hoje.getFullYear().toString(),
            url: formatSgpUrl(sgpBaseUrl, '/api/central/extratouso/')
        };
        const extratoResponse = await executePhp(extratoParams);
        const consumoData = extratoResponse;
        const totalBytes = consumoData?.total ?? 0;
        const usedGb = totalBytes / (1024 * 1024 * 1024);
        const planName = consumoData?.plano ?? "Plano não informado";
        res.status(200).json({ data: { usedGb, planName, period: `${(hoje.getMonth() + 1).toString().padStart(2, '0')}/${hoje.getFullYear()}` } });
    } catch (error) {
        console.error("Erro /get-consumption-data:", error.message);
        res.status(500).json({ error: { message: error.message } });
    }
});
// ROTA 1: SINCRONIZAR CLIENTES
app.post('/sync-clients', async (req, res) => {
    const { secret, params, providerId, sgpBaseUrl } = req.body; 
    if (secret !== PROXY_SECRET_KEY) return res.status(403).json({ error: "Acesso não autorizado." });
    if (!providerId || !sgpBaseUrl) return res.status(400).json({ error: "providerId e sgpBaseUrl são obrigatórios." });
    const tableName = `clients_${providerId.replace(/[^a-zA-Z0-9_]/g, '')}`;
    try {
        const phpParams = { ...params, url: formatSgpUrl(sgpBaseUrl, '/api/ura/clientes/') };
        const firstPageData = await executePhp(phpParams);
        if (!firstPageData || !firstPageData.paginacao || !firstPageData.paginacao.total) throw new Error("API SGP inválida.");
        
        const totalClients = firstPageData.paginacao.total;
        const limit = parseInt(params.limit) || 100;
        let allClients = firstPageData.clientes || [];
        const totalPages = Math.ceil(totalClients / limit);
        if (totalPages > 1) {
            const pageTasks = [];
            for (let page = 2; page <= totalPages; page++) {
                const pagedParams = { ...phpParams, offset: ((page - 1) * limit).toString() };
                pageTasks.push(executePhp(pagedParams).catch(err => ({ clientes: [] })));
            }
            const remainingPages = await Promise.all(pageTasks);
            remainingPages.forEach(p => { if (p.clientes) allClients = allClients.concat(p.clientes); });
        }
        db.serialize(() => {
            db.run(`DROP TABLE IF EXISTS ${tableName}`);
            db.run(`CREATE TABLE IF NOT EXISTS ${tableName} (id INTEGER PRIMARY KEY, nome TEXT, cpfcnpj TEXT, contratos TEXT)`, () => {
                 const stmt = db.prepare(`INSERT OR REPLACE INTO ${tableName} (id, nome, cpfcnpj, contratos) VALUES (?, ?, ?, ?)`);
                 allClients.forEach(client => {
                     if (client && client.id) stmt.run(client.id, client.nome, client.cpfcnpj, JSON.stringify(client.contratos));
                 });
                 stmt.finalize(() => {
                     res.status(200).json({ message: `Sincronização concluída! ${allClients.length} clientes.`, count: allClients.length });
                 });
            });
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
// ROTA 2: BUSCAR CLIENTES DO CACHE
app.post('/get-cached-clients', (req, res) => {
    const { secret, providerId } = req.body;
    const { limit = 25, offset = 0, searchTerm = '' } = req.body.params || {};
    if (secret !== PROXY_SECRET_KEY) return res.status(403).json({ error: "Acesso não autorizado." });
    const tableName = `clients_${providerId.replace(/[^a-zA-Z0-9_]/g, '')}`;
    const searchQuery = `%${searchTerm}%`;
    db.get(`SELECT COUNT(*) as total FROM ${tableName} WHERE nome LIKE ? OR cpfcnpj LIKE ?`, [searchQuery, searchQuery], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        const total = row ? row.total : 0;
        db.all(`SELECT * FROM ${tableName} WHERE nome LIKE ? OR cpfcnpj LIKE ? LIMIT ? OFFSET ?`, [searchQuery, searchQuery, limit, offset], (err, rows) => {
            if (err) return res.status(500).json({ error: err.message });
            const clients = rows.map(r => ({ ...r, contratos: JSON.parse(r.contratos || '[]') }));
            res.status(200).json({ clientes: clients, paginacao: { total, limit, offset } });
        });
    });
});
// ROTA 3: BUSCAR UM ÚNICO CLIENTE DO CACHE
app.post('/get-single-client', (req, res) => {
    const { secret, providerId, params } = req.body;
    if (secret !== PROXY_SECRET_KEY) return res.status(403).json({ error: "Acesso não autorizado." });
    const tableName = `clients_${providerId.replace(/[^a-zA-Z0-9_]/g, '')}`;
    db.get(`SELECT * FROM ${tableName} WHERE id = ?`, [params?.clientId], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!row) return res.status(404).json({ error: "Cliente não encontrado." });
        row.contratos = JSON.parse(row.contratos || '[]');
        res.status(200).json(row);
    });
});
// ROTA 4: LOGIN LEGADO
app.post('/get-client-data-for-login', async (req, res) => {
    const { cpfCnpj, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    if (!cpfCnpjUnformatted || !sgpParams || !sgpBaseUrl) return res.status(400).json({ error: { message: "Dados incompletos." } });
    try {
        const consultaParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, url: formatSgpUrl(sgpBaseUrl, '/ws/ura/consultacliente/') };
        const clientDataSgp = await executePhp(consultaParams);
        if (!clientDataSgp || !Array.isArray(clientDataSgp.contratos) || clientDataSgp.contratos.length === 0) {
            return res.status(404).json({ error: { message: "Cliente não encontrado." } });
        }
        const contrato = clientDataSgp.contratos[0];
        let firstOpenInvoice = null;
        try {
            const faturaParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, status: 'abertos', limit: '1', offset: '0', url: formatSgpUrl(sgpBaseUrl, '/api/ura/titulos/') };
            const faturaResponse = await executePhp(faturaParams);
            if (faturaResponse?.titulos && faturaResponse.titulos.length > 0) firstOpenInvoice = faturaResponse.titulos[0];
        } catch (e) {}
        const formattedData = {
            cpfCnpj: contrato.cpfCnpj,
            senha: contrato.contratoCentralSenha,
            userName: contrato.razaoSocial,
            userPlan: contrato.servico_plano,
            userStatus: contrato.contratoStatusDisplay,
            billValue: `R$ ${parseFloat(firstOpenInvoice?.valor ?? contrato.contratoValorAberto ?? 0).toFixed(2).replace('.', ',')}`,
            billDueDate: firstOpenInvoice?.dataVencimento ? `Vence em ${firstOpenInvoice.dataVencimento}` : 'Nenhuma fatura em aberto',
        };
        res.status(200).json({ data: formattedData });
    } catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
// ROTA 6: BUSCAR FATURAS
app.post('/get-invoices', async (req, res) => {
    const { cpfCnpj, sgpParams, sgpBaseUrl } = req.body; 
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    if (!cpfCnpjUnformatted || !sgpParams || !sgpBaseUrl) return res.status(400).json({ error: { message: "Dados incompletos." } });
    try {
        const url = formatSgpUrl(sgpBaseUrl, '/api/ura/titulos/');
        const paramsAbertos = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, status: 'abertos', url };
        const paramsPagos = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, status: 'pagos', url };
        const [responseAbertos, responsePagos] = await Promise.all([
             executePhp(paramsAbertos).catch(() => ({ titulos: [] })),
             executePhp(paramsPagos).catch(() => ({ titulos: [] }))
        ]);
        let formattedInvoices = [];
        if (responseAbertos?.titulos) formattedInvoices.push(...responseAbertos.titulos.map(inv => ({ ...inv, pago: false, valor: parseFloat(inv.valor ?? 0).toFixed(2).replace('.',',') })));
        if (responsePagos?.titulos) formattedInvoices.push(...responsePagos.titulos.map(inv => ({ ...inv, pago: true, valor: parseFloat(inv.valor ?? 0).toFixed(2).replace('.',',') })));
        res.status(200).json({ data: formattedInvoices });
    } catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
// ROTA 7: PROMESSA DE PAGAMENTO
app.post('/make-payment-promise', async (req, res) => {
    const { cpfCnpj, sgpParams, sgpBaseUrl } = req.body; 
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    if (!cpfCnpjUnformatted || !sgpParams || !sgpBaseUrl) return res.status(400).json({ error: { message: "Dados incompletos." } });
    try {
        const consultaParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, url: formatSgpUrl(sgpBaseUrl, '/ws/ura/consultacliente/') };
        const consultaResponse = await executePhp(consultaParams);
        if (!consultaResponse || !Array.isArray(consultaResponse.contratos) || consultaResponse.contratos.length === 0) return res.status(404).json({ error: { message: "Contrato não encontrado." } });
        
        const contratoId = consultaResponse.contratos[0].contratoId;
        const promessaParams = { ...sgpParams, contrato: contratoId.toString(), url: formatSgpUrl(sgpBaseUrl, '/api/ura/liberacaopromessa/') };
        const promessaResponse = await executePhp(promessaParams);
        if (promessaResponse?.status === false) return res.status(400).json({ error: { message: promessaResponse.msg || "Falha na promessa." } });
        res.status(200).json({ success: true, message: promessaResponse?.msg || "Promessa realizada!" });
    } catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
// ROTAS DE DIAGNÓSTICO (8, 9, 10, 11)
app.post('/diagnostic/onu-signal', async (req, res) => {
    const { cpfCnpj, senha, contrato, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    if (!cpfCnpjUnformatted || !contrato || !sgpParams || !sgpBaseUrl) return res.status(400).json({ error: { message: "Dados incompletos." } });
    try {
        const onuParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, senha, contrato: contrato.toString(), signal: '1', connection: '1', temperature: '1', url: formatSgpUrl(sgpBaseUrl, '/api/fttx/onu/list/') };
        const onuResponse = await executePhp(onuParams);
        if (!onuResponse || !Array.isArray(onuResponse) || onuResponse.length === 0) return res.status(404).json({ error: { message: "Nenhuma ONU encontrada." } });
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
        res.status(200).json({ data: formattedData });
    } catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
app.post('/diagnostic/verify-access', async (req, res) => {
    const { cpfCnpj, contrato, sgpParams, sgpBaseUrl } = req.body;
    if (!contrato || !sgpParams || !sgpBaseUrl) return res.status(400).json({ error: { message: "Dados incompletos." } });
    try {
        const accessParams = { ...sgpParams, contrato: contrato.toString(), uracontato: '', url: formatSgpUrl(sgpBaseUrl, '/ws/ura/verificaacesso/') };
        const accessResponse = await executePhp(accessParams);
        const status = parseInt(accessResponse.status || '0');
        const statusMap = { 1: 'Online', 2: 'Offline', 3: 'Bloqueado por Inadimplência', 8: 'Em Manutenção', 9: 'Manutenção Programada' };
        res.status(200).json({ data: { status, statusText: statusMap[status] || 'Desconhecido', message: accessResponse.msg || '', maintenance: status === 8 || status === 9, blocked: status === 3 || status === 4, estimatedTime: accessResponse.tempo || null } });
    } catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
app.post('/diagnostic/open-ticket', async (req, res) => {
    const { cpfCnpj, senha, contrato, content, priority, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    if (!cpfCnpjUnformatted || !contrato || !content || !sgpParams || !sgpBaseUrl) return res.status(400).json({ error: { message: "Dados incompletos" } });
    try {
        const ticketParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, senha, contrato: contrato.toString(), conteudo: content, ocorrenciatipo: '5', motivoos: '40', os_prioridade: (priority || 2).toString(), url: formatSgpUrl(sgpBaseUrl, '/api/central/chamado/') };
        const ticketResponse = await executePhp(ticketParams);
        res.status(200).json({ data: { ticketId: ticketResponse.os_id?.toString(), protocol: ticketResponse.protocolo, message: 'Chamado criado com sucesso' } });
    } catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
app.post('/diagnostic/analyze', async (req, res) => {
    const { localTests, sgpData } = req.body;
    if (!localTests || !sgpData) return res.status(400).json({ error: { message: "Dados incompletos" } });
    let problem, category, confidence, solution, estimatedTime, priority = 2;
    if (sgpData.signalRx < -26) { problem = 'Sinal Óptico Degradado'; category = 'FIBER_ISSUE'; confidence = 0.95; solution = 'Técnico necessário'; estimatedTime = '15-20 minutos'; priority = 3; }
    else if (sgpData.maintenance) { problem = 'Manutenção Programada'; category = 'MAINTENANCE'; confidence = 1.0; solution = 'Aguarde'; estimatedTime = sgpData.estimatedTime || 'A definir'; priority = 1; }
    else if (sgpData.blocked) { problem = 'Bloqueio por Inadimplência'; category = 'BILLING_BLOCK'; confidence = 1.0; solution = 'Regularize o pagamento'; estimatedTime = 'Imediato'; priority = 1; }
    else if (sgpData.signalRx >= -23 && localTests.latency > 100) { problem = 'Problema de Latência'; category = 'WIFI_ISSUE'; confidence = 0.80; solution = 'Verifique WiFi'; estimatedTime = '0 minutos'; priority = 1; }
    else { problem = 'Conexão Normal'; category = 'HEALTHY'; confidence = 0.90; solution = 'OK'; estimatedTime = 'N/A'; priority = 1; }
    res.status(200).json({ data: { problem, category, confidence, solution, estimatedTime, priority, timestamp: new Date().toISOString() } });
});
// ========================================
// ROTA DE LOGIN (CORRIGIDA v2)
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
        // USANDO A ROTA CORRETA: /ws/ura/consultacliente/
        const clientParams = {
            ...sgpParams,
            cpfcnpj: cpfCnpjUnformatted,
            url: formatSgpUrl(sgpBaseUrl, '/ws/ura/consultacliente/')
        };
        console.log(`[Login] Consultando SGP (consultacliente)...`); 
        const clientResponse = await executePhp(clientParams);
        if (!clientResponse || !Array.isArray(clientResponse.contratos) || clientResponse.contratos.length === 0) {
            console.warn(`[Login] Cliente não encontrado: ${cpfCnpjUnformatted}`);
            return res.status(404).json({
                error: { message: "Cliente não encontrado." }
            });
        }
        const contrato = clientResponse.contratos[0];
        const formattedData = {
            nome: contrato.razaoSocial || 'Cliente',
            cpfCnpj: contrato.cpfCnpj || cpfCnpjUnformatted,
            senha: contrato.contratoCentralSenha || '',
            plano: contrato.servico_plano || 'Plano Padrão',
            status: contrato.contratoStatusDisplay || 'Ativo',
            valorFatura: contrato.contratoValorAberto || '0,00',
            vencimentoFatura: '10',
            contratoId: contrato.contratoId,
            email: contrato.email
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
const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => { 
    console.log(`✅ Micro-proxy SGP (versão SQLite) rodando em http://0.0.0.0:${PORT}`);
});
EOF
echo "✅ index.js atualizado com sucesso!"
# Reinicia o servidor
echo "🔄 Reiniciando servidor proxy..."
if command -v pm2 &> /dev/null; then
    pm2 restart proxy-sgp 2>/dev/null || pm2 start "$PROXY_DIR/index.js" --name proxy-sgp
    echo "✅ Servidor reiniciado via PM2"
else
    echo "⚠️  PM2 não encontrado. Reinicie manualmente: cd $PROXY_DIR && node index.js"
fi
echo ""
echo "🎉 CORREÇÃO APLICADA! Tente fazer login no app novamente."
