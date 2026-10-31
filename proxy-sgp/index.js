const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const outbound = require('./lib/sgp-outbound');
const { formatSgpUrl } = outbound;
const { Pool } = require('pg');
const admin = require('firebase-admin');
const Redis = require('ioredis');
const { randomUUID } = require('crypto');
const fs = require('fs');
const { secretMatches } = require('./lib/internal-secret');
const stateRedis = process.env.JOBS_REDIS_URL ? new Redis(process.env.JOBS_REDIS_URL, { maxRetriesPerRequest: 1 }) : null;
stateRedis?.on('error', () => undefined);
const { createUpstream, readTtl } = require('./lib/upstream');
const upstream = createUpstream({ getRedis: () => stateRedis, getCacheRedis: () => redis,
    maxPerProvider: process.env.SGP_BACKGROUND === 'true' ? 2 : 4,
    maxPerHost: process.env.SGP_BACKGROUND === 'true' ? 4 : 8,
});
const { loadConfig } = require('./lib/config');
const { maskCpfCnpj, secureLog } = require('./lib/secure-log');
const { canIssueClientToken, subscriberIdentity, passwordMatches } = require('./lib/client-access');
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
    getRedis: () => stateRedis,
    windowMs: config.rateLimitWindowMs,
    maxRequests: config.rateLimitMaxRequests,
    getClientId: async (req) => {
        const token = req.headers.authorization?.startsWith('Bearer ') ? req.headers.authorization.slice(7) : null;
        if (token) {
            try {
                const hint = await admin.auth().verifyIdToken(token);
                return `user:${hint.providerId || 'global'}:${hint.uid}`;
            } catch { return `invalid:${req.ip}`; }
        }
        const secret = req.body?.secret;
        const expected = config.proxySecret;
        if (secretMatches(secret, expected)) {
            return `service:${req.body.providerId || 'global'}`;
        }
        return `ip:${req.ip}`;
    },
});

// Limpa fallback in-memory a cada 5 minutos
setInterval(rateLimiter.pruneFallback, 5 * 60 * 1000).unref();

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
async function rawSgpApi(params) {
    const { url, ...rest } = params;

    if (!url) {
        throw new Error('URL é obrigatória para chamar SGP');
    }
    // Final URL validation; the shared transport also pins and checks the socket.
    outbound.parseSgpUrl(url);

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
            response = await outbound.request(url, undefined, { method: 'GET',
                params: rest,
                timeout: 60000
            });
        } else if (useJson) {
            console.log(`[SGP-API] Usando Content-Type: application/json`);
            response = await outbound.request(url, rest, {
                encoding: 'json',
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
            response = await outbound.request(url, formData, {
                encoding: 'form',
                timeout: 60000
            });
        }

        console.log(`[SGP-API] Resposta OK de ${url}`);
        return response.data;
    } catch (error) {
        console.error(`[SGP-API] Erro ao chamar ${url}:`, error.message);
        if (error.response) {
            secureLog(`[SGP-API] Response data:`, error.response.data);
            throw Object.assign(new Error(`SGP retornou erro HTTP ${error.response.status}`), { response: { status: error.response.status } });
        }
        throw new Error(`Erro de conexão com SGP: ${error.message}`);
    }
}

async function callSgpApi(params) {
    const { providerId, cache = true, ...body } = params;
    if (!providerId) throw Object.assign(new Error('Provedor obrigatório.'), { status: 503 });
    const credentials = await ensureSgpCredentials({ providerId });
    const target = outbound.parseSgpUrl(body.url);
    const approved = outbound.parseSgpUrl(credentials.sgpBaseUrl);
    if (target.origin !== approved.origin || !target.pathname.startsWith(approved.pathname.replace(/\/$/, '') + '/') ||
        (body.token !== undefined && body.token !== credentials.sgpParams.token) ||
        (body.app !== undefined && body.app !== credentials.sgpParams.app)) throw Object.assign(new Error('Destino ou credenciais SGP divergentes.'), { status: 503 });
    const data = { ...body }; delete data.url;
    return upstream.execute({ providerId, url: params.url,
        body: data, ttl: cache ? readTtl(params.url) : 0, mutate: /liberacaopromessa|wifi\/update/.test(params.url) }, () => rawSgpApi(body));
}

// Mantém compatibilidade com código antigo que usa executePhp
const executePhp = callSgpApi;

// Helper to parse signal values like "N/A" or "-23.5 dBm"
function parseSignalValue(value) {
    if (!value || value === 'N/A' || value === 'null') return null;
    // Remove "dBm" suffix and parse
    const numStr = value.toString().replace(/\s*dBm\s*/i, '').trim();
    const num = parseFloat(numStr);
    return isNaN(num) ? null : num;
}

// --- HELPER: credenciais SGP (NUNCA hardcodar tokens no repositório) ---
async function loadSgpCredentials(body) {
    const providerId = body.providerId;
    if (typeof providerId !== 'string' || !/^[a-z0-9_-]+$/i.test(providerId)) throw Object.assign(new Error('Provedor obrigatório.'), { status: 503 });
    const ref = firestoreDb.collection('provedores').doc(providerId);
    const [provider, secret] = await Promise.all([ref.get(), ref.collection('secrets').doc('sgp').get()]);
    if (!provider.exists) throw Object.assign(new Error('Provedor indisponível.'), { status: 503 });
    const integration = outbound.privateIntegration(secret.data()?.integrations);
    return { sgpParams: { providerId, token: integration.token, app: integration.app }, sgpBaseUrl: integration.baseUrl };
}

const credentialCache = new Map();
async function ensureSgpCredentials(body) {
    if (['url', 'token', 'app', 'sgpBaseUrl', 'sgpParams', 'apiToken', 'appName'].some(key => Object.prototype.hasOwnProperty.call(body, key))) throw Object.assign(new Error('Configuração SGP não permitida no pedido.'), { status: 400 });
    const providerId = body.providerId;
    if (!providerId) return loadSgpCredentials(body);
    const cached = credentialCache.get(providerId);
    if (cached && cached.expires > Date.now()) return cached.value;
    if (credentialCache.size >= 128) credentialCache.delete(credentialCache.keys().next().value);
    const value = loadSgpCredentials(body);
    credentialCache.set(providerId, { value, expires: Date.now() + 15000 });
    try { return await value; } catch (error) { credentialCache.delete(providerId); throw error; }
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
    const matches = secretMatches(secret, PROXY_SECRET_KEY);
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
        const decodedToken = await require('./lib/current-auth').currentIdentity(admin.auth(), token);
        const reqCpf = (req.body.cpfCnpj || req.body.cpf || '').replace(/[^0-9]/g, '');
        
        if (!reqCpf) return res.status(400).json({ error: { message: 'CPF/CNPJ obrigatório.' } });
        if (decodedToken.superAdmin === true) {
            if (!req.body.providerId) return res.status(400).json({ error: { message: 'Provedor obrigatório.' } });
        } else if (decodedToken.role === 'providerAdmin' && decodedToken.providerId) {
            const providerId = decodedToken.providerId;
            if (req.body.providerId && req.body.providerId !== providerId) return res.status(403).json({ error: { message: 'Provedor inválido.' } });
            const cached = await firestoreDb.collection('provedores').doc(providerId).collection('clientes').doc(reqCpf).get();
            const installed = await firestoreDb.collection('clientes').where('providerId', '==', providerId).where('cpfCnpj', '==', reqCpf).limit(1).get();
            if (!cached.exists && installed.empty) return res.status(403).json({ error: { message: 'Cliente não pertence ao provedor.' } });
            req.body.providerId = providerId;
        } else {
            if (decodedToken.role !== 'subscriber' || !decodedToken.providerId || decodedToken.cpfCnpj !== reqCpf ||
                (req.body.providerId && req.body.providerId !== decodedToken.providerId)) {
                return res.status(403).json({ error: { message: 'Acesso negado.' } });
            }
            req.body.providerId = decodedToken.providerId;
        }

        req.user = decodedToken;
        next();
    } catch (error) {
        const failure = require('./lib/current-auth').authFailure(error);
        return res.status(failure.status).json({ error: { code: failure.code, message: failure.status === 503 ? 'Autorização indisponível. Preserve os dados e tente mais tarde.' : failure.status === 403 ? 'Acesso negado. Autentique novamente.' : 'Sessão inválida.' } });
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
        (console.error("[proxy] erro interno:", error && error.message), res.status(error.status || 502).json({ error: { message: "Erro interno." } }));
    }
});
// 2. Rotas Sincronização Clientes
function requireInternalSecret(req, res) {
    const supplied = req.body?.secret;
    const expected = config.proxySecret;
    if (!secretMatches(supplied, expected)) {
        res.status(403).json({ error: { message: 'Não autorizado.' } });
        return false;
    }
    return true;
}
app.post('/sync-clients', async (req, res) => {
    if (!requireInternalSecret(req, res)) return;
    try {
        const { enqueueSync } = require('./lib/jobs');
        const job = await enqueueSync(req.body.providerId);
        res.status(202).json({ jobId: job.id, status: await job.getState(), message: 'Sincronização agendada.' });
    } catch (error) {
        console.error('[SYNC] enqueue failed', error.message);
        res.status(503).json({ error: { message: 'Fila indisponível. Tente novamente.' } });
    }
});
app.post('/sync-status', async (req, res) => {
    if (!requireInternalSecret(req, res)) return;
    const job = await require('./lib/jobs').getQueue().getJob(String(req.body.jobId || ''));
    if (!job || job.data.providerId !== req.body.providerId) return res.status(404).json({ error: { message: 'Trabalho não encontrado.' } });
    res.json({ jobId: job.id, status: await job.getState(), progress: job.progress, count: job.returnvalue?.count || 0 });
});

app.post('/get-cached-clients', async (req, res) => {
    if (!requireInternalSecret(req, res)) return;
    const { providerId, params = {} } = req.body;
    if (typeof providerId !== 'string' || !providerId) return res.status(400).json({ error: { message: 'Provedor obrigatório.' } });
    await require('./lib/client-cache').ensureClientCache(pool);
    const limit = Math.min(100, Math.max(1, Math.trunc(Number(params.limit) || 25)));
    const search = String(params.searchTerm || '').slice(0, 100);
    const offset = Math.min(10000, Math.max(0, Math.trunc(Number(params.offset) || 0)));
    const [rows, total] = await Promise.all([
        pool.query('SELECT client_id AS id,nome,cpfcnpj,contratos FROM sgp_clients WHERE provider_id=$1 AND nome ILIKE $2 ORDER BY nome,client_id LIMIT $3 OFFSET $4', [providerId, `%${search}%`, limit, offset]),
        pool.query('SELECT COUNT(*) FROM sgp_clients WHERE provider_id=$1 AND nome ILIKE $2', [providerId, `%${search}%`]),
    ]);
    res.json({ clientes: rows.rows, paginacao: { total: Number(total.rows[0].count), limit, offset } });
});
app.post('/get-single-client', async (req, res) => {
    if (!requireInternalSecret(req, res)) return;
    await require('./lib/client-cache').ensureClientCache(pool);
    const result = await pool.query('SELECT client_id AS id,nome,cpfcnpj,contratos FROM sgp_clients WHERE provider_id=$1 AND client_id=$2', [req.body.providerId, String(req.body.params?.clientId || '')]);
    if (!result.rows.length) return res.status(404).json({ error: { message: 'Cliente não encontrado.' } });
    res.json(result.rows[0]);
});
// 3. Info Básica Cliente (Check-CPF) + Mock
const loginCredentialLimiter = createRateLimiter({ getRedis: () => stateRedis, windowMs: 60000, maxRequests: 10,
    getClientId: req => `login:${require('crypto').createHash('sha256').update(`${req.body?.providerId || ''}:${String(req.body?.cpf || '').replace(/\D/g, '')}`).digest('hex')}`,
});
app.post('/check-cpf', loginCredentialLimiter, async (req, res) => {
    if (!req.body.providerId || typeof req.body.senha !== 'string' || !req.body.senha || req.body.senha.length > 512) {
        return res.status(401).json({ error: { message: 'CPF/CNPJ, provedor e senha são obrigatórios. Atualize o aplicativo.' } });
    }
    const { cpf } = req.body;
    const cpfCnpjUnformatted = typeof cpf === 'string' ? cpf.replace(/[^0-9]/g, '') : '';
    if (!/^\d{11}(\d{3})?$/.test(cpfCnpjUnformatted)) return res.status(401).json({ error: { message: 'Credenciais inválidas.' } });
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials(req.body);
    if (!requireSgpClientCredentials(sgpParams, res)) return;

    console.log(`\n[Check-CPF] Recebido POST para CPF: ${maskCpfCnpj(cpfCnpjUnformatted || cpf)}`);

    if (!cpfCnpjUnformatted) return res.status(400).json({ error: { message: "Dados incompletos." } });

    // Log para debug
    console.log(`[Check-CPF] Iniciando check para ${maskCpfCnpj(cpfCnpjUnformatted)}`);
    console.log(`[Check-CPF] Params usados: App=${sgpParams.app}, URL=${sgpBaseUrl}`);
    try {
        const clientParams = {
            ...sgpParams,
            cache: false,
            cpfcnpj: cpfCnpjUnformatted,
            url: formatSgpUrl(sgpBaseUrl, '/api/ura/consultacliente/')
        };
        const clientResponse = await executePhp(clientParams);

        secureLog('[Check-CPF] Consulta cliente (sanitizado):', {
            contratosEncontrados: clientResponse?.contratos?.length || 0,
            primeiroContratoId: clientResponse?.contratos?.[0]?.contratoId || null,
        });

        if (!clientResponse?.contratos?.length) return res.status(404).json({ error: { message: "Cliente não encontrado." } });

        let contrato = clientResponse.contratos.find(item => passwordMatches(req.body.senha, String(item.contratoCentralSenha || '')) && canIssueClientToken(item.contratoStatusDisplay || item.contratoStatus || item.status));
        if (!contrato) return res.status(401).json({ error: { message: 'Credenciais inválidas.' } });
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
                    providerId: sgpParams.providerId,
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

        // O acesso ao app depende do contrato, não do estado momentâneo da conexão.
        if (canIssueClientToken(contractAccountStatus)) {
            try {
                // Vincula o provedor ao token (A2): downstream a identidade do
                // tenant vem do claim verificado, não do corpo da requisição.
                const identity = subscriberIdentity(req.body.providerId, cpfCnpjUnformatted);
                const customToken = await require('./lib/current-auth').persistSubscriber(admin.auth(), identity);
                await require('./lib/subscriber-profile').migrateSubscriberProfile(firestoreDb, identity, responseData, () => admin.firestore.FieldValue.serverTimestamp());
                responseData.customToken = customToken;
                console.log('[Check-CPF] Custom Token gerado para contrato elegível.');
            } catch (tokenError) {
                const failure = require('./lib/current-auth').authFailure(tokenError);
                return res.status(failure.status).json({ error: { code: failure.code, message: 'Não foi possível autorizar a sessão.' } });
            }
        } else {
            console.log('[Check-CPF] Token não gerado para contrato encerrado ou inativo.');
        }

        res.status(200).json(responseData);
    } catch (error) { (console.error("[proxy] erro interno:", error && error.message), res.status(error.status || 502).json({ error: { message: "Erro interno." } })); }
});
// 4. Rotas de Hardware // 3. Rotas Diagnóstico / ONU
app.post('/diagnostic/onu-signal', verifyFirebaseToken, (req, res, next) => handleOnuRequest(req, res, true).catch(next));
app.post('/diagnostic/onu-signal-base', verifyFirebaseToken, (req, res, next) => handleOnuRequest(req, res, false).catch(next));
async function handleOnuRequest(req, res, useFilters) {
    try {
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
    } catch (error) { (console.error("[proxy] erro interno:", error && error.message), res.status(error.status || 502).json({ error: { message: "Erro interno." } })); }
}
// Compatibility route retained until the legacy/mobile retirement gate.
// No measured analysis engine exists in this proxy.
app.post('/diagnostic/analyze', verifyFirebaseToken, async (req, res) => {
    res.status(501).json({
        error: {
            code: 'DIAGNOSTIC_UNAVAILABLE',
            message: 'Análise de diagnóstico indisponível. Nenhuma análise medida foi realizada.'
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
        (console.error("[proxy] erro interno:", error && error.message), res.status(error.status || 502).json({ error: { message: "Erro interno." } }));
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
        (console.error("[proxy] erro interno:", error && error.message), res.status(error.status || 502).json({ error: { message: "Erro interno." } }));
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
    try {
        const url = formatSgpUrl(sgpBaseUrl, '/api/ura/titulos/');

        // Busca faturas abertas e pagas em paralelo
        const paramsAbertos = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, status: 'abertos', url };
        const paramsPagos = { ...sgpParams, cpfcnpj: cpfCnpjUnformatted, status: 'pagos', url };

        console.log(`[Faturas] Buscando abertas e pagas em paralelo...`);
        const [responseAbertos, responsePagos] = await Promise.all([
            executePhp(paramsAbertos),
            executePhp(paramsPagos)
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


        res.status(200).json(responseData);
    } catch (error) {
        console.error("Erro geral na rota /get-invoices:", error.message);
        (console.error("[proxy] erro faturas:", error && error.message), res.status(error.status || 502).json({ error: { message: "Erro interno ao buscar faturas." } }));
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
        (console.error("[proxy] erro desbloqueio:", error && error.message), res.status(error.status || 502).json({ error: { message: "Erro interno ao processar desbloqueio." } }));
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/ready', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        if (!stateRedis) throw new Error('Redis de coordenação ausente.');
        await stateRedis.ping();
        if (redisConnected && redis) await redis.ping();
        res.status(200).json({ status: 'ready', postgres: 'ok', redis: redisConnected ? 'ok' : 'degraded' });
    } catch (error) {
        res.status(503).json({ status: 'not-ready', postgres: 'error', redis: redisConnected ? 'ok' : 'degraded' });
    }
});

const PORT = config.port;
// Iniciar Cron Jobs
module.exports = { app, pool, firestoreDb, admin, ensureSgpCredentials, callSgpApi, formatSgpUrl };
if (require.main === module) {
    app.use((error, _req, res, _next) => {
        console.error("[proxy] request failed", error.message);
        res.status(error.status || 500).json({ error: { message: error.status === 503 ? "Serviço temporariamente indisponível." : "Falha ao processar requisição." } });
    });
    app.listen(PORT, () => { console.log(`✅ Proxy SGP rodando na porta ${PORT}`); });
}
