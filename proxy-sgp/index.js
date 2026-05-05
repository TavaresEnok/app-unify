const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const sqlite3 = require('sqlite3').verbose();
const app = express();

// --- RATE LIMITING ---
// Configuração de rate limiting para proteger contra abuso
const rateLimitStore = new Map();
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minuto
const RATE_LIMIT_MAX_REQUESTS = 60; // 60 requisições por minuto

function rateLimiter(req, res, next) {
    const clientId = req.ip || req.headers['x-forwarded-for'] || 'unknown';
    const now = Date.now();

    if (!rateLimitStore.has(clientId)) {
        rateLimitStore.set(clientId, { count: 1, startTime: now });
        return next();
    }

    const clientData = rateLimitStore.get(clientId);

    // Reset se a janela expirou
    if (now - clientData.startTime > RATE_LIMIT_WINDOW_MS) {
        rateLimitStore.set(clientId, { count: 1, startTime: now });
        return next();
    }

    // Incrementa contador
    clientData.count++;

    // Verifica limite
    if (clientData.count > RATE_LIMIT_MAX_REQUESTS) {
        const retryAfter = Math.ceil((clientData.startTime + RATE_LIMIT_WINDOW_MS - now) / 1000);
        res.set('Retry-After', retryAfter.toString());
        res.set('X-RateLimit-Limit', RATE_LIMIT_MAX_REQUESTS.toString());
        res.set('X-RateLimit-Remaining', '0');
        return res.status(429).json({
            error: {
                message: 'Muitas requisições. Tente novamente em alguns segundos.',
                retryAfter
            }
        });
    }

    // Adiciona headers informativos
    res.set('X-RateLimit-Limit', RATE_LIMIT_MAX_REQUESTS.toString());
    res.set('X-RateLimit-Remaining', (RATE_LIMIT_MAX_REQUESTS - clientData.count).toString());

    next();
}

// Limpa clientes inativos a cada 5 minutos
setInterval(() => {
    const now = Date.now();
    for (const [clientId, data] of rateLimitStore.entries()) {
        if (now - data.startTime > RATE_LIMIT_WINDOW_MS * 5) {
            rateLimitStore.delete(clientId);
        }
    }
}, 5 * 60 * 1000);

// --- CACHE SYSTEM (Simple In-Memory) ---
const cacheStore = new Map();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 Minutes

function getFromCache(key) {
    if (!cacheStore.has(key)) return null;
    const item = cacheStore.get(key);
    if (Date.now() > item.expiry) {
        cacheStore.delete(key);
        return null;
    }
    return item.data;
}

function setInCache(key, data) {
    cacheStore.set(key, {
        data,
        expiry: Date.now() + CACHE_TTL_MS
    });
}
// ----------------------------------------

// --- CONFIGURAÇÃO ---
app.use((req, res, next) => {
    console.log(`[DEBUG] Incoming Request: ${req.method} ${req.url} from ${req.ip}`);
    next();
});
app.use(cors());
app.use(bodyParser.json());
app.use(rateLimiter); // Aplica rate limiting a todas as rotas

const PROXY_SECRET_KEY = process.env.PROXY_SECRET || process.env.PROXY_SECRET_KEY || '';
if (!PROXY_SECRET_KEY) {
    console.warn('[WARN] PROXY_SECRET não definido: rotas administrativas (/sync-clients, /build-apk, etc.) retornarão 503.');
}
// Mock de login só se explicitamente habilitado (nunca em produção sem intenção)
const ENABLE_DEV_MOCK = process.env.ENABLE_DEV_CPF_MOCK === 'true';
const DEV_CPF = ENABLE_DEV_MOCK ? (process.env.DEV_MOCK_CPF || '').replace(/\D/g, '') : '';
// --------------------
const DB_FILE_PATH = './cache.db';
const db = new sqlite3.Database(DB_FILE_PATH, (err) => {
    if (err) console.error("Erro ao abrir o banco de dados:", err.message);
    else console.log("Conectado ao banco de dados SQLite 'cache.db'.");
});

// Função para chamar a API do SGP diretamente via HTTP (substitui o PHP)
async function callSgpApi(params) {
    const { url, ...rest } = params;

    if (!url) {
        throw new Error('URL é obrigatória para chamar SGP');
    }

    console.log(`[SGP-API] Chamando: ${url}`);
    secureLog(`[SGP-API] Params:`, rest);

    // Endpoints que exigem JSON (apenas liberacaopromessa precisa JSON)
    const jsonEndpoints = ['/api/ura/liberacaopromessa/'];
    const useJson = jsonEndpoints.some(ep => url.includes(ep));

    // Endpoints que exigem GET (fttx e cpemanager)
    const getEndpoints = ['/api/fttx/', '/api/cpemanager/'];
    const useGet = getEndpoints.some(ep => url.includes(ep));

    try {
        let response;

        if (useGet) {
            // Para endpoints FTTX/CPE, usar GET com query params
            console.log(`[SGP-API] Usando método GET com query params`);
            response = await axios.get(url, {
                params: rest,
                timeout: 60000
            });
        } else if (useJson) {
            console.log(`[SGP-API] Usando Content-Type: application/json`);
            response = await axios.post(url, rest, {
                headers: { 'Content-Type': 'application/json' },
                timeout: 60000
            });
        } else {
            // Para outros endpoints, usa form-urlencoded (igual ao PHP)
            console.log(`[SGP-API] Usando Content-Type: application/x-www-form-urlencoded`);
            const formData = new URLSearchParams();
            for (const [key, value] of Object.entries(rest)) {
                if (value !== undefined && value !== null) {
                    formData.append(key, value.toString());
                }
            }
            response = await axios.post(url, formData.toString(), {
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                timeout: 60000
            });
        }

        console.log(`[SGP-API] Resposta OK de ${url}`);
        return response.data;
    } catch (error) {
        console.error(`[SGP-API] Erro ao chamar ${url}:`, error.message);
        if (error.response) {
            secureLog(`[SGP-API] Response data:`, error.response.data);
            throw new Error(`SGP retornou erro HTTP ${error.response.status}`);
        }
        throw new Error(`Erro de conexão com SGP: ${error.message}`);
    }
}

// Mantém compatibilidade com código antigo que usa executePhp
const executePhp = callSgpApi;

function formatSgpUrl(sgpBaseUrl, path) {
    let base = sgpBaseUrl.trim().replace(/\/$/, '');
    return `${base}${path}`;
}

// Helper to parse signal values like "N/A" or "-23.5 dBm"
function parseSignalValue(value) {
    if (!value || value === 'N/A' || value === 'null') return null;
    // Remove "dBm" suffix and parse
    const numStr = value.toString().replace(/\s*dBm\s*/i, '').trim();
    const num = parseFloat(numStr);
    return isNaN(num) ? null : num;
}

const SENSITIVE_KEY_PATTERNS = ['senha', 'password', 'token', 'authorization', 'cpf', 'cnpj', 'apiToken', 'codigoPix', 'linha_digitavel'];

function isSensitiveKey(key = '') {
    const normalized = String(key).toLowerCase();
    return SENSITIVE_KEY_PATTERNS.some((pattern) => normalized.includes(pattern.toLowerCase()));
}

function maskString(value) {
    if (typeof value !== 'string') return value;
    if (value.length <= 4) return '***';
    return `${value.slice(0, 2)}***${value.slice(-2)}`;
}

function maskCpfCnpj(value) {
    const digits = String(value || '').replace(/\D/g, '');
    if (!digits) return 'N/A';
    if (digits.length <= 4) return '***';
    return `${digits.slice(0, 2)}***${digits.slice(-2)}`;
}

function sanitizeForLog(value, currentKey = '') {
    if (value === null || value === undefined) return value;
    if (Array.isArray(value)) return value.map((item) => sanitizeForLog(item, currentKey));

    if (typeof value === 'object') {
        const sanitized = {};
        for (const [key, val] of Object.entries(value)) {
            sanitized[key] = sanitizeForLog(val, key);
        }
        return sanitized;
    }

    if (isSensitiveKey(currentKey)) {
        if (typeof value === 'string') return maskString(value);
        if (typeof value === 'number') return -1;
        return '***';
    }

    return value;
}

function secureLog(prefix, payload) {
    if (payload === undefined) {
        console.log(prefix);
        return;
    }
    console.log(prefix, sanitizeForLog(payload));
}

// --- HELPER: credenciais SGP (NUNCA hardcodar tokens no repositório) ---
function ensureSgpCredentials(body) {
    const sgpParams = { ...(body.sgpParams || {}) };
    const sgpBaseUrl = (body.sgpBaseUrl || process.env.SGP_BASE_URL || 'https://vibetelecom.sgp.net.br').trim().replace(/\/$/, '');

    if (!sgpParams.token && process.env.SGP_TOKEN) sgpParams.token = process.env.SGP_TOKEN;
    if (!sgpParams.app && process.env.SGP_APP_NAME) sgpParams.app = process.env.SGP_APP_NAME;

    return { sgpParams, sgpBaseUrl };
}

function requireSgpClientCredentials(sgpParams, res) {
    if (!sgpParams?.token || !sgpParams?.app) {
        res.status(503).json({
            error: { message: 'Integração SGP incompleta: envie sgpParams no app ou defina SGP_TOKEN e SGP_APP_NAME no servidor.' },
        });
        return false;
    }
    return true;
}

function assertProxySecret(secret, res) {
    if (!PROXY_SECRET_KEY) {
        res.status(503).json({ error: { message: 'Servidor não configurado (defina PROXY_SECRET).' } });
        return false;
    }
    if (secret !== PROXY_SECRET_KEY) {
        res.status(403).json({ error: { message: 'Acesso não autorizado.' } });
        return false;
    }
    return true;
}

async function resolveClientContractCredentials({ cpfCnpjUnformatted, sgpParams, sgpBaseUrl, contratoPreferido }) {
    const consultaParams = {
        ...sgpParams,
        cpfcnpj: cpfCnpjUnformatted,
        url: formatSgpUrl(sgpBaseUrl, '/api/ura/consultacliente/')
    };

    const consultaResponse = await executePhp(consultaParams);
    if (!consultaResponse || !Array.isArray(consultaResponse.contratos) || consultaResponse.contratos.length === 0) {
        throw new Error('Nenhum contrato encontrado.');
    }

    let contratoSelecionado = consultaResponse.contratos[0];
    if (contratoPreferido) {
        const found = consultaResponse.contratos.find((c) => String(c?.contratoId) === String(contratoPreferido));
        if (found) contratoSelecionado = found;
    }

    return {
        contratoId: contratoSelecionado?.contratoId ? String(contratoSelecionado.contratoId) : null,
        senhaCentral: contratoSelecionado?.contratoCentralSenha || '',
        contrato: contratoSelecionado,
    };
}

// 1. Rota de Consumo
app.post('/get-consumption-data', async (req, res) => {
    const { cpfCnpj, senha: senhaInput, mes, ano } = req.body;
    const { sgpParams, sgpBaseUrl } = ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;

    if (!cpfCnpj) return res.status(400).json({ error: { message: "Dados incompletos (CPF)." } });

    try {
        const cpfCnpjUnformatted = cpfCnpj.replace(/[^0-9]/g, '');
        const { contratoId, senhaCentral } = await resolveClientContractCredentials({
            cpfCnpjUnformatted,
            sgpParams,
            sgpBaseUrl,
        });

        if (!contratoId) {
            return res.status(404).json({ error: { message: 'Nenhum contrato encontrado.' } });
        }

        const senha = senhaInput || senhaCentral;
        if (!senha) {
            return res.status(503).json({ error: { message: 'Credencial do contrato indisponível para extrato de consumo.' } });
        }

        const hoje = new Date();
        // Use provided month/year or default to current
        // Note: JS getMonth() is 0-indexed (0=Jan), SGP expects 1-12
        const targetMonth = mes ? mes.toString() : (hoje.getMonth() + 1).toString();
        const targetYear = ano ? ano.toString() : hoje.getFullYear().toString();

        console.log(`[Consumo] Buscando extrato para Contrato ${contratoId} - ${targetMonth}/${targetYear}`);

        const extratoParams = {
            ...sgpParams,
            cpfcnpj: cpfCnpjUnformatted,
            senha: senha,
            contrato: contratoId,
            mes: targetMonth,
            ano: targetYear,
            url: formatSgpUrl(sgpBaseUrl, '/api/central/extratouso/')
        };

        const extratoResponse = await executePhp(extratoParams);

        // DEBUG: Inspetor de Resposta SGP
        console.log(`[Consumo DEBUG] Keys recebidas: ${Object.keys(extratoResponse || {}).join(', ')}`);
        if (extratoResponse?.extrato) {
            console.log(`[Consumo DEBUG] Tipo de 'extrato': ${typeof extratoResponse.extrato}, IsArray: ${Array.isArray(extratoResponse.extrato)}, Length: ${extratoResponse.extrato?.length}`);
            if (Array.isArray(extratoResponse.extrato) && extratoResponse.extrato.length > 0) {
                console.log(`[Consumo DEBUG] Primeiro item:`, JSON.stringify(extratoResponse.extrato[0]));
            }
        } else {
            console.log(`[Consumo DEBUG] Campo 'extrato' está AUSENTE ou NULO.`);
        }

        const usedGb = (extratoResponse?.total ?? 0) / (1024 * 1024 * 1024);

        // Tenta encontrar o array de detalhes em varios campos comuns do SGP
        const rawDetails = extratoResponse?.extrato ?? extratoResponse?.list ?? extratoResponse?.sessions ?? extratoResponse?.detalhes ?? [];

        // [FIX] Aggregate data by day to prevent App crash with huge lists
        const dailyMap = {};
        let totalBytes = 0;

        if (Array.isArray(rawDetails)) {
            rawDetails.forEach(item => {
                try {
                    // Try to parse date (usually 'data_inicio' or 'data')
                    const dateStr = item.data_inicio || item.data || item.start_time;
                    if (dateStr) {
                        const date = new Date(dateStr);
                        if (!isNaN(date.getTime())) {
                            const day = date.getDate(); // 1-31
                            const down = parseFloat(item.download || 0);
                            const up = parseFloat(item.upload || 0);
                            const sessionTotal = down + up;

                            dailyMap[day] = (dailyMap[day] || 0) + sessionTotal;
                            totalBytes += sessionTotal;
                        }
                    }
                } catch (e) { }
            });
        }

        // Format for App: [{ day: 1, gb: 2.5 }, ...]
        const dailyDetails = Object.keys(dailyMap).map(day => ({
            day: parseInt(day),
            gb: dailyMap[day] / (1024 * 1024 * 1024)
        })).sort((a, b) => a.day - b.day);

        // Calculate total only if API didn't provide it (or if we trust ours more)
        const finalUsedGb = (extratoResponse?.total ? parseFloat(extratoResponse.total) : totalBytes) / (1024 * 1024 * 1024);

        res.status(200).json({
            data: {
                usedGb: finalUsedGb,
                planName: extratoResponse?.plano ?? "Plano não informado",
                period: `${targetMonth.padStart(2, '0')}/${targetYear}`,
                details: dailyDetails // Now simplified
            }
        });
    } catch (error) {
        console.error(`[Consumo] Erro: ${error.message}`);
        res.status(500).json({ error: { message: error.message } });
    }
});
// 2. Rotas Sincronização Clientes
const activeSyncs = new Set();

app.post('/sync-clients', async (req, res) => {
    const { secret, params, providerId, sgpBaseUrl } = req.body;
    if (!assertProxySecret(secret, res)) return;

    // Evitar concorrência para o mesmo provedor
    if (activeSyncs.has(providerId)) {
        return res.status(409).json({ error: "Já existe uma sincronização em andamento para este provedor." });
    }
    activeSyncs.add(providerId);

    const tableName = `clients_${providerId.replace(/[^a-zA-Z0-9_]/g, '')}`;

    // Helper para salvar lote
    const saveBatch = (clients) => {
        return new Promise((resolve, reject) => {
            db.serialize(() => {
                db.run("BEGIN TRANSACTION");
                const stmt = db.prepare(`INSERT OR REPLACE INTO ${tableName} (id, nome, cpfcnpj, contratos) VALUES (?, ?, ?, ?)`);
                clients.forEach(c => {
                    if (c?.id) stmt.run(c.id, c.nome, c.cpfcnpj, JSON.stringify(c.contratos));
                });
                stmt.finalize();
                db.run("COMMIT", (err) => {
                    if (err) reject(err);
                    else resolve();
                });
            });
        });
    };

    try {
        console.log(`[SYNC] Iniciando sincronização incremental para ${providerId}...`);

        // Criar tabela se não existir (apenas na primeira vez)
        await new Promise((resolve, reject) => {
            db.run(`CREATE TABLE IF NOT EXISTS ${tableName} (id INTEGER PRIMARY KEY, nome TEXT, cpfcnpj TEXT, contratos TEXT)`, (err) => {
                if (err) reject(err); else resolve();
            });
        });

        // Loop principal
        const firstPageParams = { ...params, limit: 100, pagina: 1, url: formatSgpUrl(sgpBaseUrl, '/api/ura/clientes/') };
        const firstPageData = await executePhp(firstPageParams);

        if (!firstPageData?.paginacao?.total) throw new Error("API SGP inválida.");

        const totalClients = firstPageData.paginacao.total;
        const totalPages = firstPageData.paginacao.ultima_pagina || Math.ceil(totalClients / 100);

        console.log(`[SYNC] Total: ${totalClients}, Páginas: ${totalPages}`);

        // Salva página 1
        if (firstPageData.clientes?.length) {
            await saveBatch(firstPageData.clientes);
            console.log(`[SYNC] Página 1 salva (${firstPageData.clientes.length} clientes).`);
        }

        // Responde imediatamente para não dar timeout no client
        res.status(200).json({
            message: "Sincronização iniciada em background.",
            totalEstimate: totalClients,
            status: "processing"
        });

        // Processamento em background das demais páginas
        (async () => {
            let totalSaved = firstPageData.clientes?.length || 0;

            for (let page = 2; page <= totalPages; page++) {
                try {
                    // Verificar se ainda devemos continuar (opcional)
                    const pageParams = { ...params, limit: 100, pagina: page, url: formatSgpUrl(sgpBaseUrl, '/api/ura/clientes/') };
                    const pageData = await executePhp(pageParams);

                    if (pageData?.clientes?.length) {
                        await saveBatch(pageData.clientes);
                        totalSaved += pageData.clientes.length;
                        console.log(`[SYNC] Página ${page}/${totalPages} salva (+${pageData.clientes.length}). Total: ${totalSaved}`);
                    } else {
                        break;
                    }
                    // Delay maior para evitar timeout do SGP
                    await new Promise(r => setTimeout(r, 500));
                } catch (err) {
                    console.error(`[SYNC] Erro página ${page}: ${err.message}`);
                }
            }
            console.log(`[SYNC] Finalizado. Total salvo: ${totalSaved}`);
            activeSyncs.delete(providerId);
        })();

    } catch (error) {
        activeSyncs.delete(providerId);
        console.error(`[SYNC] Erro fatal: ${error.message}`);
        // Se ainda não respondeu (erro na pg 1), responde agora
        if (!res.headersSent) res.status(500).json({ error: { message: error.message } });
    }
});
app.post('/get-cached-clients', (req, res) => {
    const { secret, providerId } = req.body;
    const { limit = 25, offset = 0, searchTerm = '' } = req.body.params || {};

    if (!assertProxySecret(secret, res)) return;

    const tableName = `clients_${providerId.replace(/[^a-zA-Z0-9_]/g, '')}`;
    console.log(`[CACHE] Buscando clientes para ${providerId}: limit=${limit}, offset=${offset}, search="${searchTerm}"`);

    const searchQuery = `%${searchTerm}%`;
    db.get(`SELECT COUNT(*) as total FROM ${tableName} WHERE nome LIKE ? OR cpfcnpj LIKE ?`, [searchQuery, searchQuery], (err, row) => {
        if (err) {
            if (err.message.includes('no such table')) {
                console.warn(`[CACHE] Tabela ${tableName} não existe ainda.`);
                return res.status(200).json({ clientes: [], paginacao: { total: 0, limit, offset } });
            }
            console.error(`[CACHE] Erro Count: ${err.message}`);
            return res.status(500).json({ error: { message: err.message } });
        }

        const total = row ? row.total : 0;
        console.log(`[CACHE] Total encontrado: ${total}`);

        db.all(`SELECT * FROM ${tableName} WHERE nome LIKE ? OR cpfcnpj LIKE ? LIMIT ? OFFSET ?`, [searchQuery, searchQuery, limit, offset], (err, rows) => {
            if (err) {
                console.error(`[CACHE] Erro Select: ${err.message}`);
                return res.status(500).json({ error: { message: err.message } });
            }
            const clients = rows.map(r => ({ ...r, contratos: JSON.parse(r.contratos || '[]') }));
            console.log(`[CACHE] Retornando ${clients.length} clientes.`);
            res.status(200).json({ clientes: clients, paginacao: { total, limit, offset } });
        });
    });
});
app.post('/get-single-client', (req, res) => {
    const { secret, providerId, params } = req.body;
    if (!assertProxySecret(secret, res)) return;
    const tableName = `clients_${providerId.replace(/[^a-zA-Z0-9_]/g, '')}`;
    db.get(`SELECT * FROM ${tableName} WHERE id = ?`, [params?.clientId], (err, row) => {
        if (err) return res.status(500).json({ error: { message: err.message } });
        if (!row) return res.status(404).json({ error: "Cliente não encontrado." });
        row.contratos = JSON.parse(row.contratos || '[]');
        res.status(200).json(row);
    });
});
// 3. Info Básica Cliente (Check-CPF) + Mock
app.post('/check-cpf', async (req, res) => {
    const { cpf } = req.body;
    const cpfCnpjUnformatted = cpf ? cpf.replace(/[^0-9]/g, '') : '';
    const { sgpParams, sgpBaseUrl } = ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;

    console.log(`\n[Check-CPF] Recebido POST para CPF: ${maskCpfCnpj(cpfCnpjUnformatted || cpf)}`);

    if (!cpfCnpjUnformatted) return res.status(400).json({ error: { message: "Dados incompletos." } });

    // CACHE DISABLED to always fetch fresh connection status (verificaacesso)
    // const cacheKey = `check_cpf_${cpfCnpjUnformatted}`;
    // const cachedData = getFromCache(cacheKey);
    // if (cachedData) {
    //     console.log(`[Check-CPF] Hit Cache para ${cpfCnpjUnformatted}`);
    //     return res.status(200).json(cachedData);
    // }

    // Log para debug
    console.log(`[Check-CPF] Iniciando check para ${maskCpfCnpj(cpfCnpjUnformatted)}`);
    console.log(`[Check-CPF] Params usados: App=${sgpParams.app}, URL=${sgpBaseUrl}`);
    // MOCK LOGIN (somente com ENABLE_DEV_CPF_MOCK=true + DEV_MOCK_CPF)
    if (DEV_CPF && cpfCnpjUnformatted === DEV_CPF) {
        console.log(`[MOCK] Login Check-CPF para DEV: ${maskCpfCnpj(DEV_CPF)}`);
        return res.status(200).json({
            nome: "Desenvolvedor Teste Mock",
            cpfCnpj: DEV_CPF,
            plano: "Fibra 500MB Mock",
            status: "Ativo",
            valorFatura: "99,90",
            vencimentoFatura: "10/12/2025",
            contratoId: 222356,
            email: "dev@teste.com"
        });
    }
    try {
        const clientParams = {
            ...sgpParams,
            cpfcnpj: cpfCnpjUnformatted,
            url: formatSgpUrl(sgpBaseUrl, '/api/ura/consultacliente/')
        };
        const clientResponse = await executePhp(clientParams);

        secureLog('[Check-CPF] Consulta cliente (sanitizado):', {
            contratosEncontrados: clientResponse?.contratos?.length || 0,
            primeiroContratoId: clientResponse?.contratos?.[0]?.contratoId || null,
        });

        if (!clientResponse?.contratos?.length) return res.status(404).json({ error: { message: "Cliente não encontrado." } });

        let contrato = clientResponse.contratos[0];
        let valorAberto = parseFloat(contrato.contratoValorAberto || '0');
        let vencimento = contrato.cobVencimento;

        // Se o valor vier zerado do cadastro, busca nas faturas abertas
        if (!valorAberto || valorAberto <= 0) {
            try {
                const titlesParams = {
                    ...sgpParams,
                    cpfcnpj: cpfCnpjUnformatted,
                    status: 'abertos',
                    url: formatSgpUrl(sgpBaseUrl, '/api/ura/titulos/')
                };
                console.log('[Check-CPF] Valor zerado. Buscando títulos abertos...');
                const titlesResponse = await executePhp(titlesParams);

                if (titlesResponse?.titulos?.length) {
                    // Filtra apenas faturas vencidas ou a vencer nos próximos 45 dias
                    // Isso evita somar faturas de anos futuros se o provedor gerou carnê
                    const now = new Date();
                    const limitDate = new Date();
                    limitDate.setDate(limitDate.getDate() + 45); // Próximos 45 dias

                    // Ordena por vencimento (mais antiga primeiro)
                    const sortedTitles = titlesResponse.titulos.sort((a, b) => {
                        return new Date(a.dataVencimento) - new Date(b.dataVencimento);
                    });

                    // Pega a fatura mais antiga em aberto (foco no "próximo pagamento" ou "dívida antiga")
                    // O cliente pediu: "fatura pendente que está depois do que foi paga pela ultima vez ou do mês"
                    // Vamos somar todas as vencidas + a atual. Descartar as muito futuras.

                    const validTitles = sortedTitles.filter(t => {
                        const d = new Date(t.dataVencimento);
                        return d <= limitDate;
                    });

                    // Se tiver títulos válidos (limitados no tempo), usa eles. Se não, usa o primeiro da lista geral (mesmo que longe) para não mostrar zero.
                    const titlesToSum = validTitles.length > 0 ? validTitles : [sortedTitles[0]];

                    valorAberto = titlesToSum.reduce((sum, t) => sum + parseFloat(t.valor || 0), 0);
                    vencimento = titlesToSum[0].dataVencimento;

                    console.log(`[Check-CPF] Novo valor calculado (Inteligente): ${valorAberto}, Vencimento: ${vencimento}`);
                }
            } catch (e) {
                console.error('[Check-CPF] Erro ao buscar títulos para saldo:', e?.message || 'erro desconhecido');
            }
        }

        const responseData = {
            nome: contrato.razaoSocial,
            cpfCnpj: contrato.cpfCnpj,
            plano: contrato.servico_plano,
            status: contrato.contratoStatusDisplay || "Ativo", // Será substituído abaixo se verificaAcesso funcionar
            valorFatura: valorAberto.toFixed(2).replace('.', ','),
            vencimentoFatura: vencimento
                ? (vencimento.toString().includes('-')
                    ? vencimento.split('-').reverse().join('/')
                    : `Dia ${vencimento}`)
                : "N/A",
            contratoId: contrato.contratoId,
            email: "cliente@email.com"
        };

        // ========================================================================
        // CONSULTA DE STATUS DE CONEXÃO REAL (verificaacesso)
        // ========================================================================
        try {
            const contratoId = contrato.contratoId;
            const senhaCentral = contrato.contratoCentralSenha || '';

            if (contratoId && senhaCentral) {
                console.log(`[Check-CPF] Consultando verificaacesso para contrato ${contratoId}...`);

                const verificaParams = {
                    cpfcnpj: cpfCnpjUnformatted,
                    senha: senhaCentral,
                    contrato: contratoId.toString(),
                    url: formatSgpUrl(sgpBaseUrl, '/api/central/verificaacesso/')
                };

                const verificaResponse = await executePhp(verificaParams);
                secureLog('[Check-CPF] verificaacesso Resposta (sanitizada):', verificaResponse);

                // A API retorna o status de disponibilidade da conexão
                if (verificaResponse) {
                    // SGP retorna: {"msg":"Serviço Online","status":1} para online
                    // Verifica diferentes formatos de resposta do SGP
                    if (verificaResponse.status === 1 || verificaResponse.status === '1') {
                        responseData.status = 'Online';
                    } else if (verificaResponse.msg?.toLowerCase().includes('online')) {
                        responseData.status = 'Online';
                    } else if (verificaResponse.online === true || verificaResponse.online === 1 || verificaResponse.online === '1') {
                        responseData.status = 'Online';
                    } else if (typeof verificaResponse.status === 'string' && (verificaResponse.status.toLowerCase() === 'online' || verificaResponse.status.toLowerCase() === 'ativo')) {
                        responseData.status = 'Online';
                    } else if (verificaResponse.disponivel === true || verificaResponse.disponivel === 1) {
                        responseData.status = 'Online';
                    } else if (verificaResponse.ativo === true || verificaResponse.ativo === 1) {
                        responseData.status = 'Online';
                    } else if (verificaResponse.acesso === true || verificaResponse.acesso === 1 || verificaResponse.acesso === 'liberado') {
                        responseData.status = 'Online';
                    } else {
                        responseData.status = 'Offline';
                    }
                    console.log(`[Check-CPF] Status de conexão final: ${responseData.status}`);
                }
            } else {
                console.log('[Check-CPF] Dados insuficientes para verificaacesso:', { contratoId, senhaCentral: senhaCentral ? '***' : 'null' });
            }
        } catch (verificaError) {
            console.error('[Check-CPF] Erro ao consultar verificaacesso:', verificaError.message);
            // Em caso de erro, mantém o status do contrato como fallback
        }
        // ========================================================================

        secureLog('[Check-CPF] Resposta enviada (sanitizada):', responseData);

        // CACHE DISABLED - also disable save
        // setInCache(cacheKey, responseData);

        res.status(200).json(responseData);
    } catch (error) { res.status(500).json({ error: { message: error.message } }); }
});
app.post('/get-client-data-for-login', async (req, res) => {
    // Mesma lógica do check-cpf mas com faturas
    const { cpfCnpj, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    if (DEV_CPF && cpfCnpjUnformatted === DEV_CPF) {
        return res.status(200).json({
            data: {
                cpfCnpj: DEV_CPF, userName: "Dev Teste", userPlan: "Fibra Mock",
                userStatus: "Ativo", billValue: "R$ 99,90", billDueDate: "Vence em 10/12"
            }
        });
    }
    // ... Implementação padrão (omitida para brevidade pois check-cpf é o principal) ...
    // Se precisar do código completo desta rota, avise.
    res.status(501).json({ error: "Rota em manutenção. Use Check-CPF." });
});
// 4. Rotas de Hardware / Diagnóstico (ONU)
app.post('/diagnostic/onu-signal', async (req, res) => { handleOnuRequest(req, res, true); });
app.post('/diagnostic/onu-signal-base', async (req, res) => { handleOnuRequest(req, res, false); });
async function handleOnuRequest(req, res, useFilters) {
    const { cpfCnpj, senha: senhaInput, contrato, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    if (DEV_CPF && cpfCnpjUnformatted === DEV_CPF) {
        return res.status(200).json({
            data: {
                signalRx: -19.5, signalTx: 2.5, connectionStatus: 'Online',
                oltId: 1, slot: 1, pon: 4, onuId: 10, temperature: 45.0,
                oltTemperature: 40.0, voltage: 3.3, model: 'ZTE-F601-MOCK',
                serialNumber: 'ZTEGC06EED44'
            },
            mock: true
        });
    }
    if (!cpfCnpjUnformatted || !sgpParams || !sgpBaseUrl) return res.status(400).json({ error: { message: "Dados incompletos." } });
    try {
        let senha = senhaInput;
        let contratoResolvido = contrato;

        if (!senha || !contratoResolvido) {
            const resolved = await resolveClientContractCredentials({
                cpfCnpjUnformatted,
                sgpParams,
                sgpBaseUrl,
                contratoPreferido: contrato,
            });
            senha = senha || resolved.senhaCentral;
            contratoResolvido = contratoResolvido || resolved.contratoId;
        }

        if (!senha) {
            return res.status(503).json({ error: { message: 'Credencial do contrato indisponível para diagnóstico ONU.' } });
        }

        const onuParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, senha, url: formatSgpUrl(sgpBaseUrl, '/api/fttx/onu/list/') };
        if (useFilters) { onuParams.signal = '1'; onuParams.connection = '1'; }
        if (contratoResolvido) onuParams.contrato = contratoResolvido.toString();
        const onuResponse = await executePhp(onuParams);
        if (!onuResponse || !Array.isArray(onuResponse) || onuResponse.length === 0) return res.status(404).json({ error: { message: "Nenhuma ONU encontrada." } });
        const onu = onuResponse[0];

        // DEBUG: Log raw ONU response to see field names
        secureLog('[ONU DEBUG] Raw response (sanitizada):', onu);

        const formattedData = {
            // Signal: SGP returns info_rx/info_tx as "N/A" or "-23.5 dBm"
            signalRx: parseSignalValue(onu.info_rx),
            signalTx: parseSignalValue(onu.info_tx),
            // Status: SGP returns online as boolean
            connectionStatus: onu.online ? 'Online' : 'Offline',
            // OLT Info
            oltId: parseInt(onu.olt_id || '0'),
            oltName: onu.olt_name || null,
            slot: parseInt(onu.slot || '0'),
            pon: parseInt(onu.pon || '0'),
            onuId: parseInt(onu.onuid || onu.onu_id || '0'),
            // Other info
            temperature: onu.temperature ? parseFloat(onu.temperature) : null,
            voltage: onu.voltage ? parseFloat(onu.voltage) : null,
            model: onu.type || onu.modelo || 'Desconhecido',
            serialNumber: onu.phy_addr || onu.serial || null,
            // Extra info
            mode: onu.mode || null,
            vlan: onu.vlan || null,
            cto: onu.cto || null,
            lastUpdate: onu.info_date || null,
        };
        res.status(200).json({ data: formattedData });
    } catch (error) { res.status(500).json({ error: { message: error.message } }); }
}
// 4.1 Rota de Análise Inteligente (IA Mock)
app.post('/diagnostic/analyze', async (req, res) => {
    // Recebe os dados do diagnóstico
    const { cpfCnpj, data } = req.body;
    // Mock Analysis - Estrutura exata esperada pelo App (com wrapper data)
    const mockAnalysis = {
        data: {
            problem: "Sinal óptico abaixo do ideal (-25dBm)",
            category: "FIBER_ISSUE", // DiagnosticCategory.FIBER_ISSUE
            confidence: 0.95,
            solution: "Verificar integridade do cabo de fibra e conexões.",
            estimatedTime: "24h",
            priority: 1, // High
            timestamp: new Date().toISOString()
        }
    };
    // Developer Backdoor
    if (DEV_CPF && cpfCnpj && cpfCnpj.replace(/[^0-9]/g, '') === DEV_CPF) {
        return res.status(200).json(mockAnalysis);
    }
    res.status(200).json(mockAnalysis);
});
// 5. Rotas CPE Manager (Wi-Fi)
app.post('/cpe/wifi/list', async (req, res) => {
    const { cpfCnpj, senha: senhaInput, contrato } = req.body;
    const { sgpParams, sgpBaseUrl } = ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    let contratoId = contrato;
    let senha = senhaInput;

    if (!cpfCnpjUnformatted) {
        return res.status(400).json({ error: { message: 'Dados incompletos (CPF).' } });
    }

    try {
        if (!senha || !contratoId) {
            const resolved = await resolveClientContractCredentials({
                cpfCnpjUnformatted,
                sgpParams,
                sgpBaseUrl,
                contratoPreferido: contrato,
            });
            contratoId = contratoId || resolved.contratoId;
            senha = senha || resolved.senhaCentral;
        }

        if (!contratoId || !senha) {
            return res.status(503).json({ error: { message: 'Credenciais do contrato indisponíveis para listar Wi-Fi.' } });
        }

        const fullUrl = formatSgpUrl(sgpBaseUrl, `/api/cpemanager/servico/${contratoId}/wifi/list/`);
        console.log(`[WIFI-LIST] URL SGP: ${fullUrl}`);
        const wifiParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, senha, url: fullUrl };
        const response = await executePhp(wifiParams);
        // Check if response contains PHP errors or execution errors
        if (response && (response.message || response.error)) {
            secureLog(`[WIFI-LIST] Resposta SGP (Possível Erro):`, response);
        } else {
            console.log(`[WIFI-LIST] Sucesso. Itens encontrados:`, Array.isArray(response) ? response.length : 'Obj');
        }
        res.status(200).json({ success: true, data: response });
    } catch (error) {
        console.error(`[WIFI-LIST] CRITICAL ERROR:`, error.message);
        res.status(500).json({ error: { message: error.message } });
    }
});
app.post('/cpe/wifi/update', async (req, res) => {
    const { cpfCnpj, senha: senhaInput, contrato, wifiId, ssid, password } = req.body;
    const { sgpParams, sgpBaseUrl } = ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    console.log(`[WIFI-UPDATE] Tentando atualizar WiFi ID: ${wifiId} do Contrato: ${contrato}`);
    if (!contrato || !wifiId || !ssid || !password) return res.status(400).json({ error: { message: "Dados incompletos" } });
    try {
        let senha = senhaInput;
        if (!senha) {
            const resolved = await resolveClientContractCredentials({
                cpfCnpjUnformatted,
                sgpParams,
                sgpBaseUrl,
                contratoPreferido: contrato,
            });
            senha = resolved.senhaCentral;
        }

        if (!senha) {
            return res.status(503).json({ error: { message: 'Credencial do contrato indisponível para atualizar Wi-Fi.' } });
        }

        const updateParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, senha, wifi_id: wifiId, ssid, password, url: formatSgpUrl(sgpBaseUrl, `/api/cpemanager/servico/${contrato}/wifi/update/`) };
        const response = await executePhp(updateParams);
        secureLog(`[WIFI-UPDATE] Resposta SGP:`, response);
        res.status(200).json({ success: true, data: response });
    } catch (error) {
        console.error(`[WIFI-UPDATE] ERROR:`, error.message);
        res.status(500).json({ error: { message: error.message } });
    }
});

// 6. ROTA DE FATURAS (APP FLUTTER) - ADICIONADA
app.post('/get-invoices', async (req, res) => {
    const { cpfCnpj } = req.body;
    const { sgpParams, sgpBaseUrl } = ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;

    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';

    // CACHE CHECK
    const cacheKey = `invoices_${cpfCnpjUnformatted}`;
    const cachedData = getFromCache(cacheKey);
    if (cachedData) {
        console.log(`[Faturas] Hit Cache para ${maskCpfCnpj(cpfCnpjUnformatted)}`);
        return res.status(200).json(cachedData);
    }

    if (!cpfCnpjUnformatted) {
        return res.status(400).json({ error: { message: "cpfCnpj obrigatório." } });
    }
    console.log(`[Faturas] Buscando faturas para: ${maskCpfCnpj(cpfCnpjUnformatted)} no SGP: ${sgpBaseUrl}`);

    try {
        const url = formatSgpUrl(sgpBaseUrl, '/api/ura/titulos/');

        // Busca faturas abertas e pagas em paralelo
        const paramsAbertos = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, status: 'abertos', url };
        const paramsPagos = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, status: 'pagos', url };

        console.log(`[Faturas] Buscando abertas e pagas em paralelo...`);
        const [responseAbertos, responsePagos] = await Promise.all([
            executePhp(paramsAbertos).catch(err => { console.error(`[Faturas] Erro ao buscar abertas: ${err.message}`); return { titulos: [] }; }),
            executePhp(paramsPagos).catch(err => { console.error(`[Faturas] Erro ao buscar pagas: ${err.message}`); return { titulos: [] }; })
        ]);

        // DEBUG: Log raw response to find PIX field name
        if (responseAbertos?.titulos && responseAbertos.titulos.length > 0) {
            secureLog(`[Faturas DEBUG] Primeiro título aberto (sanitizado):`, responseAbertos.titulos[0]);
        }

        let formattedInvoices = [];

        if (responseAbertos?.titulos && Array.isArray(responseAbertos.titulos)) {
            console.log(`[Faturas] ${responseAbertos.titulos.length} faturas abertas encontradas.`);
            formattedInvoices.push(...responseAbertos.titulos.map(inv => ({
                id: inv.id?.toString() || inv.nossoNumero || '0',
                numero: inv.nossoNumero || inv.numeroDocumento?.toString() || '0',
                valor: parseFloat(inv.valor ?? 0),
                vencimento: inv.dataVencimento,
                status: 'pendente',
                link: inv.link,
                linha_digitavel: inv.linhaDigitavel,
                pix_copia_cola: inv.codigoPix,
            })));
        }

        if (responsePagos?.titulos && Array.isArray(responsePagos.titulos)) {
            console.log(`[Faturas] ${responsePagos.titulos.length} faturas pagas encontradas.`);
            formattedInvoices.push(...responsePagos.titulos.map(inv => ({
                id: inv.id?.toString() || inv.nossoNumero || '0',
                numero: inv.nossoNumero || inv.numeroDocumento?.toString() || '0',
                valor: parseFloat(inv.valor ?? 0),
                vencimento: inv.dataVencimento,
                status: 'pago',
                dataPagamento: inv.dataPagamento,
                link: inv.link,
                linha_digitavel: inv.linhaDigitavel,
                pix_copia_cola: inv.codigoPix,
            })));
        }

        console.log(`[Faturas] Total de faturas formatadas: ${formattedInvoices.length}`);
        console.log(`[Faturas] Total de faturas formatadas: ${formattedInvoices.length}`);

        const responseData = { data: formattedInvoices };
        setInCache(cacheKey, responseData);

        res.status(200).json(responseData);
    } catch (error) {
        console.error("Erro geral na rota /get-invoices:", error.message);
        res.status(500).json({ error: { message: error.message || "Erro interno ao buscar faturas." } });
    }
});

// 7. ROTA DE DESBLOQUEIO POR CONFIANÇA (APP FLUTTER) - ADICIONADA
app.post('/unlock-trust', async (req, res) => {
    const { cpfCnpj, sgpParams, sgpBaseUrl } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';

    if (!cpfCnpjUnformatted || !sgpParams || !sgpBaseUrl) {
        return res.status(400).json({ error: { message: "cpfCnpj, sgpParams e sgpBaseUrl são obrigatórios." } });
    }
    console.log(`[Unlock] Solicitando desbloqueio para: ${maskCpfCnpj(cpfCnpjUnformatted)}`);

    try {
        // 1. Busca contrato do cliente
        const consultaParams = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, url: formatSgpUrl(sgpBaseUrl, '/api/ura/consultacliente/') };
        const consultaResponse = await executePhp(consultaParams);

        if (!consultaResponse || !Array.isArray(consultaResponse.contratos) || consultaResponse.contratos.length === 0) {
            return res.status(404).json({ error: { message: "Nenhum contrato encontrado para este cliente." } });
        }
        const contratoId = consultaResponse.contratos[0].contratoId;

        // 2. Solicita liberação por promessa
        const promessaParams = { ...sgpParams, contrato: contratoId.toString(), url: formatSgpUrl(sgpBaseUrl, '/api/ura/liberacaopromessa/') };
        const promessaResponse = await executePhp(promessaParams);

        if (promessaResponse?.status === false) {
            return res.status(400).json({ error: { message: promessaResponse.msg || "Não foi possível realizar o desbloqueio." } });
        }

        console.log(`[Unlock] Sucesso para contrato ${contratoId}`);
        res.status(200).json({ success: true, message: promessaResponse?.msg || "Desbloqueio realizado com sucesso!" });
    } catch (error) {
        console.error("Erro na rota /unlock-trust:", error.message);
        res.status(500).json({ error: { message: error.message || "Erro interno ao processar desbloqueio." } });
    }
});

// 8. ROTA DE BUILD DE APK (ADMIN PANEL) - MELHORADA
app.post('/build-apk', async (req, res) => {
    const { secret, architecture = 'arm64-v8a', providerId = 'default' } = req.body;

    if (!assertProxySecret(secret, res)) return;

    console.log(`[Build-APK] Iniciando build para ${architecture}...`);

    try {
        const { exec } = require('child_process');
        const { promisify } = require('util');
        const execAsync = promisify(exec);

        // Executar script de build com timeout estendido
        const buildScript = '/home/app/painel-provedores-projeto/build-apk.sh';
        const command = `bash ${buildScript} ${providerId} ${architecture}`;

        console.log(`[Build-APK] Executando: ${command}`);
        console.log(`[Build-APK] Timeout: 10 minutos (600s)`);

        let buildResult;
        try {
            buildResult = await execAsync(command, {
                cwd: '/home/app/painel-provedores-projeto',
                timeout: 600000, // 10 minutos timeout
                maxBuffer: 10 * 1024 * 1024 // 10MB buffer para logs grandes
            });
        } catch (buildError) {
            console.error(`[Build-APK] Erro no build:`, buildError.message);
            console.error(`[Build-APK] Stderr:`, buildError.stderr);
            console.error(`[Build-APK] Stdout:`, buildError.stdout);

            // Se erro for de timeout, informar ao usuário
            if (buildError.killed || buildError.signal === 'SIGTERM') {
                return res.status(504).json({
                    error: {
                        message: 'Build excedeu tempo limite de 10 minutos. Tente novamente ou use APK pré-compilado.',
                        timeout: true
                    }
                });
            }

            // Outros erros de build
            return res.status(500).json({
                error: {
                    message: `Erro ao compilar: ${buildError.message}`,
                    details: buildError.stderr || buildError.stdout
                }
            });
        }

        const { stdout, stderr } = buildResult;

        if (stderr) {
            console.log(`[Build-APK] Stderr (warnings):`, stderr.substring(0, 500));
        }

        console.log(`[Build-APK] Build concluído! Output:`, stdout.substring(stdout.length - 500));

        // Determinar nome do APK gerado
        const apkMap = {
            'arm64-v8a': 'app-arm64-v8a.apk',
            'armeabi-v7a': 'app-armeabi-v7a.apk',
            'all': 'app-release.apk',
            'universal': 'app-release.apk'
        };

        const apkFileName = apkMap[architecture] || 'app-release.apk';
        const timestamp = new Date().getTime();

        // Verificar se APK foi realmente gerado
        const fs = require('fs');
        const apkPath = `/home/app/painel-provedores-projeto/admin-painel/public/${apkFileName}`;

        if (!fs.existsSync(apkPath)) {
            console.error(`[Build-APK] APK não encontrado em ${apkPath}`);
            return res.status(500).json({
                error: {
                    message: 'APK não foi gerado. Verifique logs do Flutter.',
                    apkPath
                }
            });
        }

        // Obter informações do APK gerado
        const stats = fs.statSync(apkPath);
        const sizeInMB = (stats.size / (1024 * 1024)).toFixed(2);

        // URL do APK com timestamp para evitar cache
        const apkUrl = `/${apkFileName}?t=${timestamp}`;

        console.log(`[Build-APK] ✅ Sucesso! APK: ${apkUrl}, Tamanho: ${sizeInMB}MB`);

        res.status(200).json({
            success: true,
            apkUrl,
            architecture,
            timestamp: new Date().toISOString(),
            size: `${sizeInMB} MB`
        });

    } catch (error) {
        console.error(`[Build-APK] Erro crítico não tratado:`, error?.message || 'erro desconhecido');
        res.status(500).json({
            error: {
                message: `Erro inesperado: ${error.message}`,
                stack: error.stack
            }
        });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3002;
app.listen(PORT, () => { console.log(`✅ Proxy SGP PROD rodando na porta ${PORT}`); });
