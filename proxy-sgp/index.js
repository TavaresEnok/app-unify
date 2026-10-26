const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const { Pool } = require('pg');
const admin = require('firebase-admin');
const Redis = require('ioredis');
const { randomUUID } = require('crypto');
const fs = require('fs');
const { loadConfig } = require('./lib/config');
const { maskCpfCnpj, secureLog } = require('./lib/secure-log');
const { canIssueClientToken } = require('./lib/client-access');
const { createRateLimiter } = require('./lib/rate-limiter');

const config = loadConfig();

// Initialize Firebase Admin (Uses ADC)
const firebaseCredentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (firebaseCredentialsPath && !fs.existsSync(firebaseCredentialsPath)) {
    throw new Error(`Firebase credentials file not found: ${firebaseCredentialsPath}`);
}
if (!admin.apps.length) {
    admin.initializeApp({ projectId: process.env.GOOGLE_CLOUD_PROJECT || undefined });
}
const firestoreDb = admin.firestore();

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use((req, res, next) => {
    const requestId = req.get('x-request-id') || randomUUID();
    const startedAt = Date.now();
    req.requestId = requestId;
    res.set('x-request-id', requestId);
    res.on('finish', () => {
        if (req.path === '/health') return;
        console.log(JSON.stringify({
            severity: res.statusCode >= 500 ? 'ERROR' : 'INFO',
            message: 'request.completed',
            requestId,
            method: req.method,
            path: req.path,
            status: res.statusCode,
            durationMs: Date.now() - startedAt,
        }));
    });
    next();
});

// --- REDIS CONNECTION ---
const REDIS_URL = config.redisUrl;
let redis = null;
let redisConnected = false;

try {
    redis = new Redis(REDIS_URL, {
        maxRetriesPerRequest: 3,
        retryStrategy: (times) => Math.min(times * 200, 3000),
        lazyConnect: true,
    });
    redis.connect().then(() => {
        redisConnected = true;
        console.log('✅ Redis conectado com sucesso');
    }).catch(err => {
        console.warn('⚠️ Redis indisponível, usando fallback in-memory:', err.message);
        redisConnected = false;
    });
    redis.on('error', () => { redisConnected = false; });
    redis.on('connect', () => { redisConnected = true; });
} catch (err) {
    console.warn('⚠️ Falha ao inicializar Redis, usando fallback in-memory');
}

// --- RATE LIMITING (Redis-backed com fallback in-memory) ---
// /health e /ready ficam isentos para o healthcheck nunca receber 429.
const rateLimiter = createRateLimiter({
    getRedis: () => (redisConnected ? redis : null),
    windowMs: config.rateLimitWindowMs,
    maxRequests: config.rateLimitMaxRequests,
});

// Limpa fallback in-memory a cada 5 minutos
setInterval(rateLimiter.pruneFallback, 5 * 60 * 1000);

// --- CACHE SYSTEM (Redis-backed com fallback in-memory) ---
const cacheStoreFallback = new Map();
const CACHE_TTL_MS = config.cacheTtlMs;

async function getFromCache(key) {
    try {
        if (redisConnected && redis) {
            const cached = await redis.get(`cache:${key}`);
            if (cached) return JSON.parse(cached);
            return null;
        }
    } catch (err) { /* fallback */ }

    // Fallback in-memory
    if (!cacheStoreFallback.has(key)) return null;
    const item = cacheStoreFallback.get(key);
    if (Date.now() > item.expiry) {
        cacheStoreFallback.delete(key);
        return null;
    }
    return item.data;
}

async function setInCache(key, data) {
    try {
        if (redisConnected && redis) {
            await redis.set(`cache:${key}`, JSON.stringify(data), 'PX', CACHE_TTL_MS);
            return;
        }
    } catch (err) { /* fallback */ }

    // Fallback in-memory
    cacheStoreFallback.set(key, {
        data,
        expiry: Date.now() + CACHE_TTL_MS
    });
}
// ----------------------------------------

// --- CONFIGURAÇÃO ---
// Debug logging — desabilitado em produção para reduzir ruído nos logs
// Para habilitar, defina DEBUG_REQUESTS=true no .env
if (process.env.DEBUG_REQUESTS === 'true') {
    app.use((req, res, next) => {
        console.log(`[DEBUG] ${req.method} ${req.url} from ${req.ip}`);
        next();
    });
}

// CORS — restringir origens permitidas
const ALLOWED_ORIGINS = config.allowedOrigins;
app.use(cors({
    origin: (origin, callback) => {
        // Permitir requisições sem origin (mobile apps, curl, server-to-server)
        if (!origin) return callback(null, true);
        if (ALLOWED_ORIGINS.includes(origin)) return callback(null, true);
        console.warn(`[CORS] Origem bloqueada: ${origin}`);
        callback(new Error('Bloqueado por política CORS'));
    },
    credentials: true,
}));
app.use(bodyParser.json());
app.use(rateLimiter); // Aplica rate limiting a todas as rotas

const PROXY_SECRET_KEY = config.proxySecret;
if (!PROXY_SECRET_KEY) {
    console.warn('[WARN] PROXY_SECRET não definido: rotas administrativas retornarão 503.');
}
// Mock de login só se explicitamente habilitado (nunca em produção sem intenção)
const DEV_CPF = config.devCpf;
// --------------------
const pool = new Pool({
    connectionString: config.databaseUrl,
});

pool.on('error', (err) => {
    console.error("Erro inesperado no banco de dados PostgreSQL", err);
});
// Função para chamar a API do SGP diretamente via HTTP (substitui o PHP)
async function callSgpApi(params) {
    const { url, ...rest } = params;

    if (!url) {
        throw new Error('URL é obrigatória para chamar SGP');
    }
    // Defesa em profundidade contra SSRF: valida o host antes de qualquer axios.
    assertSafeSgpUrl(url);

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

// Bloqueia SSRF: rejeita esquemas não-http(s) e hosts internos (loopback,
// faixas privadas, link-local/metadata, CGNAT). Chokepoint usado por todas as
// chamadas ao SGP, cobrindo inclusive sgpBaseUrl vindo do corpo da requisição.
function assertSafeSgpUrl(sgpBaseUrl) {
    let parsed;
    try {
        parsed = new URL(sgpBaseUrl.trim());
    } catch {
        throw new Error('sgpBaseUrl inválida.');
    }
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
        throw new Error('sgpBaseUrl deve usar http(s).');
    }
    const host = parsed.hostname.toLowerCase();
    const ipMatch = host.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
    if (host === 'localhost' || host.endsWith('.localhost')) {
        throw new Error('sgpBaseUrl aponta para host interno.');
    }
    if (ipMatch) {
        const [a, b] = ipMatch.slice(1).map(Number);
        const isPrivate = a === 10 || a === 127 || a === 0 ||
            (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) ||
            (a === 169 && b === 254) || (a === 100 && b >= 64 && b <= 127) || a >= 224;
        if (isPrivate) throw new Error('sgpBaseUrl aponta para faixa de IP interna.');
    }
    return parsed;
}

function formatSgpUrl(sgpBaseUrl, path) {
    assertSafeSgpUrl(sgpBaseUrl);
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

// --- HELPER: credenciais SGP (NUNCA hardcodar tokens no repositório) ---
async function ensureSgpCredentials(body) {
    const sgpParams = {};
    let sgpBaseUrl = '';

    if (!body.providerId && (body.cpfCnpj || body.cpf)) {
        try {
            const cpfCnpj = (body.cpfCnpj || body.cpf).replace(/[^0-9]/g, '');
            let clienteDoc = await firestoreDb.collection('clientes').doc(cpfCnpj).get();
            if (!clienteDoc.exists) {
                const matches = await firestoreDb.collection('clientes').where('cpfCnpj', '==', cpfCnpj).limit(1).get();
                clienteDoc = matches.docs[0];
            }
            if (clienteDoc?.exists) body.providerId = clienteDoc.data().providerId;
        } catch (error) {
            console.error("[SGP-API] Erro ao buscar providerId do cliente:", error.message);
        }
    }

    if (body.providerId) {
        try {
            const providerRef = firestoreDb.collection('provedores').doc(body.providerId);
            const [providerDoc, secretDoc] = await Promise.all([
                providerRef.get(),
                providerRef.collection('secrets').doc('sgp').get(),
            ]);
            if (secretDoc.exists) {
                const integrations = secretDoc.data().integrations;
                if (integrations) {
                    sgpParams.token = integrations.apiToken;
                    sgpParams.app = integrations.appName;
                    sgpBaseUrl = integrations.sgpBaseUrl || '';
                }
            }
            const provider = providerDoc.exists ? providerDoc.data() : {};
            sgpBaseUrl = sgpBaseUrl || provider?.details?.systemUrl || provider?.sgpBaseUrl || '';
        } catch (error) {
            console.error("[SGP-API] Erro ao buscar secrets:", error.message);
        }
    }

    if (!sgpBaseUrl) sgpBaseUrl = process.env.SGP_BASE_URL || 'https://vibetelecom.sgp.net.br';
    sgpBaseUrl = sgpBaseUrl.trim().replace(/\/$/, '');

    if (!sgpParams.token && process.env.SGP_TOKEN) sgpParams.token = process.env.SGP_TOKEN;
    if (!sgpParams.app && process.env.SGP_APP_NAME) sgpParams.app = process.env.SGP_APP_NAME;

    return { sgpParams, sgpBaseUrl };
}

function requireSgpClientCredentials(sgpParams, res) {
    if (!sgpParams?.token || !sgpParams?.app) {
        res.status(503).json({
            error: { message: 'Integração SGP indisponível para este provedor.' },
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
    // Comparação em tempo constante — evita distinguir o segredo por timing.
    const provided = typeof secret === 'string' ? Buffer.from(secret) : Buffer.alloc(0);
    const expected = Buffer.from(PROXY_SECRET_KEY);
    const matches = provided.length === expected.length &&
        require('crypto').timingSafeEqual(provided, expected);
    if (!matches) {
        res.status(403).json({ error: { message: 'Acesso não autorizado.' } });
        return false;
    }
    return true;
}

// Middleware de Autenticação Firebase
async function verifyFirebaseToken(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: { message: 'Não autorizado. Token Ausente.' } });
    }
    const token = authHeader.split('Bearer ')[1];
    try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        const reqCpf = (req.body.cpfCnpj || req.body.cpf || '').replace(/[^0-9]/g, '');
        
        // Se houver CPF na requisição, ele DEVE bater com o UID do token (que é o CPF do login)
        if (reqCpf && decodedToken.uid !== reqCpf) {
            console.error(`[AUTH] Tentativa de acesso cruzado: UID(${decodedToken.uid}) tentou acessar CPF(${reqCpf})`);
            return res.status(403).json({ error: { message: 'Acesso negado: Tentativa de acessar dados de outro cliente.' } });
        }

        // Vínculo de tenant (A2): se o token carrega providerId, ele é a fonte da
        // verdade — rejeita divergência e ignora qualquer providerId do corpo.
        // Tokens legados sem o claim mantêm o comportamento anterior.
        if (decodedToken.providerId) {
            if (req.body.providerId && req.body.providerId !== decodedToken.providerId) {
                console.error(`[AUTH] providerId do corpo (${req.body.providerId}) diverge do token (${decodedToken.providerId})`);
                return res.status(403).json({ error: { message: 'Acesso negado: provedor não corresponde ao token.' } });
            }
            req.body.providerId = decodedToken.providerId;
        }

        req.user = decodedToken;
        next();
    } catch (error) {
        console.error('[AUTH] Erro na verificação do token:', error.message);
        return res.status(401).json({ error: { message: 'Não autorizado. Token Inválido ou Expirado.' } });
    }
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
app.post('/get-consumption-data', verifyFirebaseToken, async (req, res) => {
    const { cpfCnpj, senha: senhaInput, mes, ano } = req.body;
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials(req.body);
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
        (console.error("[proxy] erro interno:", error && error.message), res.status(500).json({ error: { message: "Erro interno." } }));
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
    const saveBatch = async (clients) => {
        const client = await pool.connect();
        try {
            await client.query("BEGIN");
            for (const c of clients) {
                if (c?.id) {
                    await client.query(
                        `INSERT INTO "${tableName}" (id, nome, cpfcnpj, contratos) 
                         VALUES ($1, $2, $3, $4) 
                         ON CONFLICT (id) DO UPDATE SET 
                         nome = EXCLUDED.nome, cpfcnpj = EXCLUDED.cpfcnpj, contratos = EXCLUDED.contratos`,
                        [c.id, c.nome, c.cpfcnpj, JSON.stringify(c.contratos)]
                    );
                }
            }
            await client.query("COMMIT");
        } catch (err) {
            await client.query("ROLLBACK");
            throw err;
        } finally {
            client.release();
        }
    };

    try {
        console.log(`[SYNC] Iniciando sincronização incremental para ${providerId}...`);

        // Criar tabela se não existir (apenas na primeira vez)
        await pool.query(`CREATE TABLE IF NOT EXISTS "${tableName}" (id INTEGER PRIMARY KEY, nome TEXT, cpfcnpj TEXT, contratos TEXT)`);


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
        if (!res.headersSent) (console.error("[proxy] erro interno:", error && error.message), res.status(500).json({ error: { message: "Erro interno." } }));
    }
});
app.post('/get-cached-clients', async (req, res) => {
    const { secret, providerId } = req.body;
    const { limit = 25, offset = 0, searchTerm = '' } = req.body.params || {};

    if (!assertProxySecret(secret, res)) return;

    if (typeof providerId !== 'string' || !providerId.trim()) {
        return res.status(400).json({ error: { message: 'providerId é obrigatório.' } });
    }

    const tableName = `clients_${providerId.replace(/[^a-zA-Z0-9_]/g, '')}`;
    console.log(`[CACHE] Buscando clientes para ${providerId}: limit=${limit}, offset=${offset}, search="${searchTerm}"`);

    const searchQuery = `%${searchTerm}%`;

    try {
        const countRes = await pool.query(`SELECT COUNT(*) as total FROM "${tableName}" WHERE nome ILIKE $1 OR cpfcnpj ILIKE $2`, [searchQuery, searchQuery]);
        const total = parseInt(countRes.rows[0].total, 10);

        const rowsRes = await pool.query(`SELECT * FROM "${tableName}" WHERE nome ILIKE $1 OR cpfcnpj ILIKE $2 LIMIT $3 OFFSET $4`, [searchQuery, searchQuery, limit, offset]);
        const clientes = rowsRes.rows.map(row => ({
            ...row,
            contratos: JSON.parse(row.contratos || '[]')
        }));

        return res.status(200).json({ clientes, paginacao: { total, limit, offset } });
    } catch (err) {
        if (err.code === '42P01') { // undefined_table
            console.warn(`[CACHE] Tabela ${tableName} não existe ainda.`);
            return res.status(200).json({ clientes: [], paginacao: { total: 0, limit, offset } });
        }
        console.error(`[CACHE] Erro DB: ${err.message}`);
        (console.error("[proxy] erro DB:", err && err.message), res.status(500).json({ error: { message: "Erro interno." } }));
        return;
    }
});
app.post('/get-single-client', async (req, res) => {
    const { secret, providerId, params } = req.body;
    if (!assertProxySecret(secret, res)) return;
    if (typeof providerId !== 'string' || !providerId.trim()) {
        return res.status(400).json({ error: { message: 'providerId é obrigatório.' } });
    }
    const tableName = `clients_${providerId.replace(/[^a-zA-Z0-9_]/g, '')}`;
    
    try {
        const resDb = await pool.query(`SELECT * FROM "${tableName}" WHERE id = $1`, [params?.clientId]);
        if (resDb.rows.length === 0) return res.status(404).json({ error: "Cliente não encontrado." });
        
        const row = resDb.rows[0];
        row.contratos = JSON.parse(row.contratos || '[]');
        return res.status(200).json(row);
    } catch (err) {
        console.error(`[CACHE] Erro DB Single: ${err.message}`);
        (console.error("[proxy] erro DB:", err && err.message), res.status(500).json({ error: { message: "Erro interno." } }));
        return;
    }
});
// 3. Info Básica Cliente (Check-CPF) + Mock
app.post('/check-cpf', async (req, res) => {
    const { cpf } = req.body;
    const cpfCnpjUnformatted = cpf ? cpf.replace(/[^0-9]/g, '') : '';
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials(req.body);
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
        let mockToken = '';
        try {
            mockToken = await admin.auth().createCustomToken(DEV_CPF);
        } catch (e) { console.error('[MOCK] Auth Error', e); }

        return res.status(200).json({
            nome: "Desenvolvedor Teste Mock",
            cpfCnpj: DEV_CPF,
            plano: "Fibra 500MB Mock",
            status: "Ativo",
            valorFatura: "99,90",
            vencimentoFatura: "10/12/2025",
            contratoId: 222356,
            email: "dev@teste.com",
            customToken: mockToken
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
        const contractAccountStatus = contrato.contratoStatusDisplay
            || contrato.contratoStatus
            || contrato.status
            || '';
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

        // Segundo fator (C2): quando REQUIRE_LOGIN_SECOND_FACTOR=true, o login por
        // CPF exige também a senha central do contrato antes de emitir o token —
        // fechando a tomada de conta por CPF (semi-público). Desligado por padrão
        // para não quebrar o app atual; a UI Flutter precisa enviar `senha`.
        if (process.env.REQUIRE_LOGIN_SECOND_FACTOR === 'true') {
            const provided = typeof req.body.senha === 'string' ? req.body.senha.trim() : '';
            const contratoSenha = contrato.contratoCentralSenha || '';
            if (!provided || !contratoSenha || provided !== String(contratoSenha)) {
                console.warn('[Check-CPF] Segundo fator ausente/incorreto — token não emitido.');
                return res.status(401).json({ error: { message: 'Credenciais inválidas.' } });
            }
        }

        // O acesso ao app depende do contrato, não do estado momentâneo da conexão.
        if (canIssueClientToken(contractAccountStatus)) {
            try {
                // Vincula o provedor ao token (A2): downstream a identidade do
                // tenant vem do claim verificado, não do corpo da requisição.
                const claims = req.body.providerId ? { providerId: req.body.providerId } : undefined;
                const customToken = await admin.auth().createCustomToken(cpfCnpjUnformatted, claims);
                responseData.customToken = customToken;
                console.log('[Check-CPF] Custom Token gerado para contrato elegível.');
            } catch (tokenError) {
                console.error('[Check-CPF] Falha ao gerar Custom Token do Firebase:', tokenError.message);
            }
        } else {
            console.log('[Check-CPF] Token não gerado para contrato encerrado ou inativo.');
        }

        res.status(200).json(responseData);
    } catch (error) { (console.error("[proxy] erro interno:", error && error.message), res.status(500).json({ error: { message: "Erro interno." } })); }
});
// 4. Rotas de Hardware // 3. Rotas Diagnóstico / ONU
app.post('/diagnostic/onu-signal', verifyFirebaseToken, async (req, res) => { handleOnuRequest(req, res, true); });
app.post('/diagnostic/onu-signal-base', verifyFirebaseToken, async (req, res) => { handleOnuRequest(req, res, false); });
async function handleOnuRequest(req, res, useFilters) {
    const { cpfCnpj, senha: senhaInput, contrato } = req.body;
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;
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
    if (!cpfCnpjUnformatted) return res.status(400).json({ error: { message: "Dados incompletos (CPF)." } });
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
    } catch (error) { (console.error("[proxy] erro interno:", error && error.message), res.status(500).json({ error: { message: "Erro interno." } })); }
}
// 4. Rota Analyze
// 4. Rota Analyze
// ATENÇÃO: retorna análise PLACEHOLDER fixa (não há motor de diagnóstico real).
// Mantida por compatibilidade com apps antigos (contracts.js "keep-temporarily").
// Não exibir como diagnóstico real sem implementar a análise de fato.
app.post('/diagnostic/analyze', verifyFirebaseToken, async (req, res) => {
    res.status(200).json({
        data: {
            problem: "Sinal óptico abaixo do ideal (-25dBm)",
            category: "FIBER_ISSUE",
            confidence: 0.95,
            solution: "Verificar integridade do cabo de fibra e conexões.",
            estimatedTime: "24h",
            priority: 1,
            timestamp: new Date().toISOString()
        }
    });
});
// 5. Rotas CPE Manager (Wi-Fi)
app.post('/cpe/wifi/list', verifyFirebaseToken, async (req, res) => {
    const { cpfCnpj, senha: senhaInput, contrato } = req.body;
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials(req.body);
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
        (console.error("[proxy] erro interno:", error && error.message), res.status(500).json({ error: { message: "Erro interno." } }));
    }
});
app.post('/cpe/wifi/update', verifyFirebaseToken, async (req, res) => {
    const { cpfCnpj, senha: senhaInput, contrato, wifiId, ssid, password } = req.body;
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials(req.body);
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
        (console.error("[proxy] erro interno:", error && error.message), res.status(500).json({ error: { message: "Erro interno." } }));
    }
});

// 6. ROTA DE FATURAS (APP FLUTTER) - ADICIONADA
app.post('/get-client-data-for-login', async (req, res) => {
    // Mantida por compatibilidade com apps antigos em campo (contracts.js:
    // decision "keep-temporarily"). Não implementada: responde 501 sem tocar no
    // SGP — os campos sgpParams/sgpBaseUrl do corpo são deliberadamente
    // ignorados para não abrir superfície de SSRF/injeção de credencial.
    const { cpfCnpj } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    if (DEV_CPF && cpfCnpjUnformatted === DEV_CPF) {
        return res.status(200).json({
            data: {
                cpfCnpj: DEV_CPF, userName: "Dev Teste", userPlan: "Fibra Mock",
                userStatus: "Ativo", billValue: "R$ 99,90", billDueDate: "Vence em 10/12"
            }
        });
    }
    res.status(501).json({ error: "Rota em manutenção. Use Check-CPF." });
});
app.post('/get-invoices', verifyFirebaseToken, async (req, res) => {
    const { cpfCnpj } = req.body;
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;

    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';

    if (!cpfCnpjUnformatted) {
        return res.status(400).json({ error: { message: "cpfCnpj obrigatório." } });
    }

    // CACHE CHECK
    const providerCacheKey = String(req.body.providerId || 'unknown').replace(/[^a-zA-Z0-9_-]/g, '');
    const cacheKey = `invoices_${providerCacheKey}_${cpfCnpjUnformatted}`;
    const cachedData = await getFromCache(cacheKey);
    if (cachedData) {
        console.log(`[Faturas] Hit Cache para ${maskCpfCnpj(cpfCnpjUnformatted)}`);
        return res.status(200).json(cachedData);
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

        const responseData = { data: formattedInvoices };
        await setInCache(cacheKey, responseData);

        res.status(200).json(responseData);
    } catch (error) {
        console.error("Erro geral na rota /get-invoices:", error.message);
        (console.error("[proxy] erro faturas:", error && error.message), res.status(500).json({ error: { message: "Erro interno ao buscar faturas." } }));
    }
});

// 7. ROTA DESBLOQUEIO CONFIANCA
app.post('/unlock-trust', verifyFirebaseToken, async (req, res) => {
    const { cpfCnpj } = req.body;
    const cpfCnpjUnformatted = cpfCnpj ? cpfCnpj.replace(/[^0-9]/g, '') : '';
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;

    if (!cpfCnpjUnformatted) {
        return res.status(400).json({ error: { message: "cpfCnpj é obrigatório." } });
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
        (console.error("[proxy] erro desbloqueio:", error && error.message), res.status(500).json({ error: { message: "Erro interno ao processar desbloqueio." } }));
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/ready', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        if (redisConnected && redis) await redis.ping();
        res.status(200).json({ status: 'ready', postgres: 'ok', redis: redisConnected ? 'ok' : 'degraded' });
    } catch (error) {
        res.status(503).json({ status: 'not-ready', postgres: 'error', redis: redisConnected ? 'ok' : 'degraded' });
    }
});

const PORT = config.port;
// Iniciar Cron Jobs
require('./cron-jobs')(app, { admin, firestoreDb, ensureSgpCredentials, callSgpApi });

app.listen(PORT, () => { console.log(`✅ Proxy SGP PROD rodando na porta ${PORT}`); });
