"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const axios_1 = __importDefault(require("axios"));
const https = __importStar(require("https"));
const admin = __importStar(require("firebase-admin"));
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
// Inicializa Firebase Admin via Application Default Credentials (ADC)
admin.initializeApp();
const app = (0, express_1.default)();
const port = Number(process.env.PORT) || 9136;
// =========================================================================
// VARIÁVEIS DE AMBIENTE — nunca hardcodar aqui, usar .env ou ADC
// =========================================================================
const SGP_TOKEN = process.env.SGP_TOKEN;
const SGP_APP_NAME = process.env.SGP_APP_NAME;
const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY;
const APK_SCRIPT_PATH = process.env.APK_SCRIPT_PATH || '/home/app/projects/painel_provedores/admin-script/gerar_apk.py';
const APK_PROJECT_ROOT = process.env.APK_PROJECT_ROOT || '/home/app/projects/painel_provedores';
const APK_OUTPUT_DIR = process.env.APK_OUTPUT_DIR || '/home/app/projects/painel_provedores/public_apks';
if (!SGP_TOKEN || !SGP_APP_NAME) {
    console.warn('[WARN] SGP_TOKEN ou SGP_APP_NAME não definidos. Endpoints SGP falharão.');
}
if (!FIREBASE_API_KEY) {
    console.warn('[WARN] FIREBASE_API_KEY não definida. Endpoint de login admin falhará.');
}
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// =========================================================================
// RATE LIMITING
// =========================================================================
// Limite global: 200 req/minuto por IP
const globalLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000,
    max: 200,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: { message: 'Muitas requisições. Tente novamente em 1 minuto.' } },
});
// Limite restrito para login: 10 tentativas/minuto por IP (brute force)
const loginLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000,
    max: 10,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: { message: 'Muitas tentativas de login. Tente novamente em 1 minuto.' } },
});
// Limite para SGP (cada chamada consulta API externa): 30 req/minuto por IP
const sgpLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000,
    max: 30,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: { message: 'Limite de consultas SGP atingido. Tente novamente em 1 minuto.' } },
});
// Limite para geração de APK: 5 req/hora por IP (operação pesada)
const apkLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 60 * 1000,
    max: 5,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: { message: 'Limite de geração de APK atingido. Tente novamente em 1 hora.' } },
});
app.use(globalLimiter);
// =========================================================================
// MIDDLEWARES DE AUTENTICAÇÃO
// =========================================================================
const verifyToken = async (req, res, next) => {
    var _a;
    const token = (_a = req.headers.authorization) === null || _a === void 0 ? void 0 : _a.split('Bearer ')[1];
    if (!token)
        return res.status(401).json({ error: { message: 'Token não fornecido' } });
    try {
        req.user = await admin.auth().verifyIdToken(token);
        next();
    }
    catch (_b) {
        return res.status(403).json({ error: { message: 'Token inválido' } });
    }
};
const verifySuperAdmin = async (req, res, next) => {
    var _a;
    const token = (_a = req.headers.authorization) === null || _a === void 0 ? void 0 : _a.split('Bearer ')[1];
    if (!token)
        return res.status(401).json({ error: { message: 'Token não fornecido' } });
    try {
        const decoded = await admin.auth().verifyIdToken(token);
        if (decoded.superAdmin !== true) {
            return res.status(403).json({ error: { message: 'Apenas Super Admin pode executar esta operação' } });
        }
        req.user = decoded;
        next();
    }
    catch (_b) {
        return res.status(403).json({ error: { message: 'Token inválido' } });
    }
};
// =========================================================================
// AUTH
// =========================================================================
app.post('/admin/auth/login', loginLimiter, async (req, res) => {
    var _a, _b, _c, _d;
    try {
        if (!FIREBASE_API_KEY) {
            return res.status(503).json({ error: { message: 'Serviço de autenticação não configurado.' } });
        }
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: { message: 'Email e senha são obrigatórios.' } });
        }
        const authUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;
        const authResponse = await axios_1.default.post(authUrl, { email, password, returnSecureToken: true });
        const { idToken, localId, email: userEmail } = authResponse.data;
        res.json({ token: idToken, user: { uid: localId, email: userEmail } });
    }
    catch (error) {
        console.error('Erro no login admin:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
        const errorMessage = ((_d = (_c = (_b = error.response) === null || _b === void 0 ? void 0 : _b.data) === null || _c === void 0 ? void 0 : _c.error) === null || _d === void 0 ? void 0 : _d.message) || 'Falha na autenticação.';
        res.status(401).json({ error: { message: errorMessage } });
    }
});
// =========================================================================
// PROVEDORES
// =========================================================================
app.get('/admin/providers', verifyToken, async (req, res) => {
    try {
        const snapshot = await admin.firestore().collection('provedores').get();
        const providers = snapshot.docs.map(doc => {
            var _a, _b;
            const data = doc.data();
            if ((_a = data.createdAt) === null || _a === void 0 ? void 0 : _a.toDate)
                data.createdAt = data.createdAt.toDate().toISOString();
            if ((_b = data.updatedAt) === null || _b === void 0 ? void 0 : _b.toDate)
                data.updatedAt = data.updatedAt.toDate().toISOString();
            return Object.assign({ id: doc.id }, data);
        });
        res.json({ data: providers });
    }
    catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
app.post('/admin/providers', verifyToken, async (req, res) => {
    try {
        const _a = req.body, { id } = _a, data = __rest(_a, ["id"]);
        const now = admin.firestore.FieldValue.serverTimestamp();
        if (!data.createdAt)
            data.createdAt = now;
        data.updatedAt = now;
        if (id) {
            delete data.createdAt;
            await admin.firestore().collection('provedores').doc(id).set(data, { merge: true });
            res.json({ success: true, id });
        }
        else {
            const docRef = await admin.firestore().collection('provedores').add(data);
            res.json({ success: true, id: docRef.id });
        }
    }
    catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
// =========================================================================
// TICKETS
// =========================================================================
app.get('/admin/tickets', verifyToken, async (req, res) => {
    try {
        const snapshot = await admin.firestore().collection('tickets').orderBy('updatedAt', 'desc').get();
        const tickets = snapshot.docs.map(doc => {
            var _a, _b;
            const data = doc.data();
            if ((_a = data.createdAt) === null || _a === void 0 ? void 0 : _a.toDate)
                data.createdAt = data.createdAt.toDate().toISOString();
            if ((_b = data.updatedAt) === null || _b === void 0 ? void 0 : _b.toDate)
                data.updatedAt = data.updatedAt.toDate().toISOString();
            return Object.assign({ id: doc.id }, data);
        });
        res.json({ data: tickets });
    }
    catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
app.get('/admin/tickets/:id/messages', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;
        const snapshot = await admin.firestore()
            .collection('tickets').doc(id)
            .collection('messages').orderBy('createdAt', 'asc').get();
        const messages = snapshot.docs.map(doc => {
            var _a;
            const data = doc.data();
            if ((_a = data.createdAt) === null || _a === void 0 ? void 0 : _a.toDate)
                data.createdAt = data.createdAt.toDate().toISOString();
            return Object.assign({ id: doc.id }, data);
        });
        res.json({ data: messages });
    }
    catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
app.patch('/admin/tickets/:id', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;
        const updates = Object.assign(Object.assign({}, req.body), { updatedAt: admin.firestore.FieldValue.serverTimestamp() });
        await admin.firestore().collection('tickets').doc(id).update(updates);
        res.json({ success: true });
    }
    catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
app.post('/admin/tickets/:id/reply', verifyToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { message, authorId, authorName } = req.body;
        const ticketRef = admin.firestore().collection('tickets').doc(id);
        await ticketRef.collection('messages').add({
            message,
            authorId: authorId || 'admin',
            authorName: authorName || 'Administrador',
            senderType: 'admin',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
        });
        await ticketRef.update({
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'Em Andamento',
            lastMessage: message,
        });
        res.json({ success: true });
    }
    catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
// =========================================================================
// USUÁRIOS
// =========================================================================
app.get('/admin/users', verifyToken, async (req, res) => {
    try {
        const snapshot = await admin.firestore().collection('users').orderBy('email').limit(100).get();
        const users = snapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
        res.json({ data: users });
    }
    catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
// =========================================================================
// DASHBOARD
// =========================================================================
app.get('/admin/dashboard', verifyToken, async (req, res) => {
    try {
        const db = admin.firestore();
        const [providersSnap, ticketsOpenSnap, ticketsTotalSnap] = await Promise.all([
            db.collection('provedores').count().get(),
            db.collection('tickets').where('status', '==', 'Aberto').count().get(),
            db.collection('tickets').count().get(),
        ]);
        res.json({
            data: {
                totalProviders: providersSnap.data().count,
                totalTickets: ticketsTotalSnap.data().count,
                openTickets: ticketsOpenSnap.data().count,
                totalUsers: 0,
            },
        });
    }
    catch (error) {
        res.status(500).json({ error: { message: error.message } });
    }
});
// =========================================================================
// SGP — ENDPOINTS DO APP DO ASSINANTE
// =========================================================================
function requireSgpCredentials(res) {
    if (!SGP_TOKEN || !SGP_APP_NAME) {
        res.status(503).json({ error: { message: 'Credenciais do SGP não configuradas no servidor.' } });
        return false;
    }
    return true;
}
function createSgpSession() {
    return axios_1.default.create({
        httpsAgent: new https.Agent({ rejectUnauthorized: false }),
        headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json' },
    });
}
app.post('/getClientData', sgpLimiter, async (req, res) => {
    var _a, _b, _c, _d;
    if (!requireSgpCredentials(res))
        return;
    try {
        const { cpfCnpj } = req.body;
        if (!cpfCnpj) {
            return res.status(400).json({ error: { message: 'CPF/CNPJ é obrigatório.' } });
        }
        const baseUrl = 'https://vibetelecom.sgp.net.br';
        const session = createSgpSession();
        const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
            token: SGP_TOKEN,
            app: SGP_APP_NAME,
            cpfcnpj: cpfCnpj,
        });
        if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
            throw new Error('Nenhum contrato encontrado para este cliente.');
        }
        const contrato = consultaResponse.data.contratos[0];
        const hoje = new Date();
        const mesAtual = hoje.getMonth() + 1;
        const anoAtual = hoje.getFullYear();
        let connectionStatus = 'Offline';
        try {
            const contratoId = contrato.contratoId || contrato.contrato_id || contrato.id;
            const cpfLimpo = cpfCnpj.replace(/\D/g, '');
            const senhaCentral = contrato.contratoCentralSenha || contrato.central_senha || '';
            if (contratoId && senhaCentral) {
                const verificaResponse = await session.post(`${baseUrl}/api/central/verificaacesso/`, {
                    cpfcnpj: cpfLimpo,
                    senha: senhaCentral,
                    contrato: contratoId,
                });
                const data = verificaResponse.data;
                if (data) {
                    if (data.online === true || data.online === 1 || data.online === '1') {
                        connectionStatus = 'Online';
                    }
                    else if (((_a = data.status) === null || _a === void 0 ? void 0 : _a.toLowerCase()) === 'online' || ((_b = data.status) === null || _b === void 0 ? void 0 : _b.toLowerCase()) === 'ativo') {
                        connectionStatus = 'Online';
                    }
                    else if (data.disponivel === true || data.disponivel === 1) {
                        connectionStatus = 'Online';
                    }
                    else if (data.ativo === true || data.ativo === 1) {
                        connectionStatus = 'Online';
                    }
                    else if (typeof data === 'object' && Object.keys(data).length > 0 && !data.error) {
                        connectionStatus = 'Online';
                    }
                }
            }
        }
        catch (verificaError) {
            console.error('[verificaacesso] Erro ao consultar status:', ((_c = verificaError === null || verificaError === void 0 ? void 0 : verificaError.response) === null || _c === void 0 ? void 0 : _c.data) || verificaError.message);
        }
        res.json({
            data: {
                cpfCnpj: contrato.cpfCnpj,
                senha: contrato.contratoCentralSenha,
                userName: contrato.razaoSocial,
                userPlan: contrato.servico_plano,
                userStatus: connectionStatus,
                billValue: `R$ ${parseFloat(contrato.contratoValorAberto || 0).toFixed(2).replace('.', ',')}`,
                billDueDate: `Vence em ${contrato.cobVencimento}/${mesAtual}/${anoAtual}`,
                contratoId: contrato.contratoId || contrato.contrato_id || contrato.id,
            },
        });
    }
    catch (error) {
        console.error('Erro detalhado na getClientData:', ((_d = error.response) === null || _d === void 0 ? void 0 : _d.data) || error.message);
        const errorMessage = error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.';
        res.status(500).json({ error: { message: `Erro ao buscar dados do cliente: ${errorMessage}` } });
    }
});
app.post('/getConsumptionData', sgpLimiter, async (req, res) => {
    var _a;
    if (!requireSgpCredentials(res))
        return;
    try {
        const { cpfCnpj, senha } = req.body;
        if (!cpfCnpj || !senha) {
            return res.status(400).json({ error: { message: 'CPF/CNPJ e Senha da Central são obrigatórios.' } });
        }
        const baseUrl = 'https://vibetelecom.sgp.net.br';
        const session = createSgpSession();
        const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
            token: SGP_TOKEN,
            app: SGP_APP_NAME,
            cpfcnpj: cpfCnpj,
        });
        if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
            throw new Error('Nenhum contrato encontrado para este cliente.');
        }
        const contratoId = consultaResponse.data.contratos[0].contratoId;
        const hoje = new Date();
        const mes = hoje.getMonth() + 1;
        const ano = hoje.getFullYear();
        const extratoPayload = new URLSearchParams();
        extratoPayload.append('cpfcnpj', cpfCnpj);
        extratoPayload.append('senha', senha);
        extratoPayload.append('contrato', contratoId.toString());
        extratoPayload.append('mes', mes.toString());
        extratoPayload.append('ano', ano.toString());
        const extratoResponse = await session.post(`${baseUrl}/api/central/extratouso/`, extratoPayload);
        const consumoData = extratoResponse.data;
        const totalBytes = consumoData.total || 0;
        const usedGb = totalBytes / (1024 * 1024 * 1024);
        const planoCliente = consumoData.plano || 'Plano não informado';
        const match = planoCliente.match(/(\d+)/);
        const totalGb = match ? parseFloat(match[1]) : 1000;
        res.json({
            data: {
                totalGb,
                usedGb,
                averageSpeed: 'N/A',
                period: `${mes.toString().padStart(2, '0')}/${ano}`,
            },
        });
    }
    catch (error) {
        console.error('Erro detalhado na getConsumptionData:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
        const errorMessage = error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.';
        res.status(500).json({ error: { message: `Erro ao buscar dados de consumo: ${errorMessage}` } });
    }
});
app.post('/getInvoices', sgpLimiter, async (req, res) => {
    var _a, _b, _c;
    if (!requireSgpCredentials(res))
        return;
    try {
        const { cpfCnpj } = req.body;
        if (!cpfCnpj) {
            return res.status(400).json({ error: { message: 'CPF/CNPJ é obrigatório.' } });
        }
        const baseUrl = 'https://vibetelecom.sgp.net.br';
        const session = createSgpSession();
        const [responseAbertos, responsePagos] = await Promise.all([
            session.post(`${baseUrl}/api/ura/titulos/`, { token: SGP_TOKEN, app: SGP_APP_NAME, cpfcnpj: cpfCnpj, status: 'abertos' }),
            session.post(`${baseUrl}/api/ura/titulos/`, { token: SGP_TOKEN, app: SGP_APP_NAME, cpfcnpj: cpfCnpj, status: 'pagos' }),
        ]);
        const formatInvoice = (invoice, pago) => ({
            pago,
            vencimento: invoice.dataVencimento,
            valor: parseFloat(invoice.valor || 0).toFixed(2).replace('.', ','),
            linha_digitavel: invoice.linhaDigitavel,
            linha_digitavel_pix: invoice.codigoPix,
            link: invoice.link,
            id: invoice.id,
            numero_documento: invoice.numeroDocumento,
        });
        const abertos = Array.isArray((_a = responseAbertos.data) === null || _a === void 0 ? void 0 : _a.titulos)
            ? responseAbertos.data.titulos.map((i) => formatInvoice(i, false))
            : [];
        const pagos = Array.isArray((_b = responsePagos.data) === null || _b === void 0 ? void 0 : _b.titulos)
            ? responsePagos.data.titulos.map((i) => formatInvoice(i, true))
            : [];
        res.json({ data: [...abertos, ...pagos] });
    }
    catch (error) {
        console.error('Erro detalhado na getInvoices:', ((_c = error.response) === null || _c === void 0 ? void 0 : _c.data) || error.message);
        const errorMessage = error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.';
        res.status(500).json({ error: { message: `Erro ao buscar faturas: ${errorMessage}` } });
    }
});
app.post('/makePaymentPromise', sgpLimiter, async (req, res) => {
    var _a, _b;
    if (!requireSgpCredentials(res))
        return;
    try {
        const { cpfCnpj } = req.body;
        if (!cpfCnpj) {
            return res.status(400).json({ error: { message: 'CPF/CNPJ é obrigatório.' } });
        }
        const baseUrl = 'https://vibetelecom.sgp.net.br';
        const session = createSgpSession();
        const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
            token: SGP_TOKEN,
            app: SGP_APP_NAME,
            cpfcnpj: cpfCnpj,
        });
        if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
            throw new Error('Contrato não encontrado para este cliente.');
        }
        const contratoId = consultaResponse.data.contratos[0].contratoId;
        const promessaResponse = await session.post(`${baseUrl}/api/ura/liberacaopromessa/`, {
            token: SGP_TOKEN,
            app: SGP_APP_NAME,
            contrato: contratoId,
        });
        if (((_a = promessaResponse.data) === null || _a === void 0 ? void 0 : _a.status) === false) {
            throw new Error(promessaResponse.data.msg || 'O SGP retornou um erro ao tentar realizar a promessa.');
        }
        res.json({
            success: true,
            message: promessaResponse.data.msg || 'Promessa de pagamento realizada com sucesso!',
        });
    }
    catch (error) {
        console.error('Erro detalhado na makePaymentPromise:', ((_b = error.response) === null || _b === void 0 ? void 0 : _b.data) || error.message);
        const errorMessage = error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.';
        res.status(500).json({ error: { message: `Erro ao realizar promessa: ${errorMessage}` } });
    }
});
// =========================================================================
// DIAGNÓSTICO — ONU Signal e Traceroute
// =========================================================================
app.post('/diagnostic/onu-signal', sgpLimiter, async (req, res) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t;
    try {
        const { cpfCnpj, sgpParams } = req.body;
        if (!cpfCnpj) {
            return res.status(400).json({ error: { message: 'CPF/CNPJ é obrigatório.' } });
        }
        const sgpBaseUrl = (sgpParams === null || sgpParams === void 0 ? void 0 : sgpParams.sgpBaseUrl) || 'https://vibetelecom.sgp.net.br';
        const token = SGP_TOKEN || (sgpParams === null || sgpParams === void 0 ? void 0 : sgpParams.apiToken) || (sgpParams === null || sgpParams === void 0 ? void 0 : sgpParams.token);
        const appName = SGP_APP_NAME || (sgpParams === null || sgpParams === void 0 ? void 0 : sgpParams.appName);
        const session = axios_1.default.create({
            httpsAgent: new https.Agent({ rejectUnauthorized: false }),
            headers: { 'User-Agent': 'Mozilla/5.0' },
        });
        const onuResponse = await session.get(`${sgpBaseUrl}/api/fttx/onu/list/`, {
            params: { token, app: appName, cpfcnpj: cpfCnpj, signal: 1, connection: 1, address: 1 },
        });
        let onus = [];
        if (Array.isArray(onuResponse.data)) {
            onus = onuResponse.data;
        }
        else if (onuResponse.data && typeof onuResponse.data === 'object') {
            onus = [onuResponse.data];
        }
        if (onus.length === 0) {
            return res.status(404).json({ error: { message: 'Nenhuma ONU encontrada para este cliente.' } });
        }
        const onu = onus[0];
        const rawConnection = ((_b = (_a = onu.connection) === null || _a === void 0 ? void 0 : _a.toString()) === null || _b === void 0 ? void 0 : _b.toLowerCase()) || '';
        const isOnline = onu.online === true ||
            rawConnection === 'online' ||
            rawConnection === '1' ||
            rawConnection === 'true';
        res.json({
            data: {
                connectionStatus: isOnline ? 'Online' : (onu.status_display || onu.connection || 'Offline'),
                isOnline,
                oltId: onu.olt_id || onu.olt || 0,
                oltName: onu.olt_name || onu.olt_display || null,
                slot: onu.slot || 0,
                pon: onu.pon || 0,
                onuId: onu.onuid || onu.onuidreal || 0,
                model: onu.model || onu.onutype_display || 'Desconhecido',
                signalRx: (_f = (_e = (_d = (_c = onu.signal) === null || _c === void 0 ? void 0 : _c.rx_power) !== null && _d !== void 0 ? _d : onu.rx_power) !== null && _e !== void 0 ? _e : onu.info_rx) !== null && _f !== void 0 ? _f : null,
                signalTx: (_k = (_j = (_h = (_g = onu.signal) === null || _g === void 0 ? void 0 : _g.tx_power) !== null && _h !== void 0 ? _h : onu.tx_power) !== null && _j !== void 0 ? _j : onu.info_tx) !== null && _k !== void 0 ? _k : null,
                temperature: (_o = (_m = (_l = onu.signal) === null || _l === void 0 ? void 0 : _l.temperature) !== null && _m !== void 0 ? _m : onu.temperature) !== null && _o !== void 0 ? _o : null,
                voltage: (_r = (_q = (_p = onu.signal) === null || _p === void 0 ? void 0 : _p.voltage) !== null && _q !== void 0 ? _q : onu.voltage) !== null && _r !== void 0 ? _r : null,
                serialNumber: onu.phy_addr || onu.serial || null,
                mode: onu.mode_display || onu.mode || null,
                vlan: onu.vlan || null,
                cto: onu.splitter_name || onu.cto_name || null,
                lastUpdate: ((_s = onu.signal) === null || _s === void 0 ? void 0 : _s.updated_at) || onu.updated_at || onu.info_date || null,
            },
        });
    }
    catch (error) {
        console.error('[ONU-Signal] Erro:', ((_t = error.response) === null || _t === void 0 ? void 0 : _t.data) || error.message);
        const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
        res.status(500).json({ error: { message: `Erro ao buscar sinal da ONU: ${errorMessage}` } });
    }
});
app.post('/diagnostic/traceroute', async (req, res) => {
    try {
        const { target = '8.8.8.8', maxHops = 15 } = req.body;
        const { exec } = await Promise.resolve().then(() => __importStar(require('child_process')));
        const { promisify } = await Promise.resolve().then(() => __importStar(require('util')));
        const execAsync = promisify(exec);
        try {
            const { stdout } = await execAsync(`traceroute -n -m ${maxHops} -w 2 ${target}`, { timeout: 30000 });
            const lines = stdout.split('\n').filter(line => line.trim());
            const hops = [];
            for (const line of lines) {
                if (line.includes('traceroute to'))
                    continue;
                const match = line.match(/^\s*(\d+)\s+(\S+)\s+(.+)/);
                if (match) {
                    const timeMatch = match[3].match(/(\d+\.?\d*)\s*ms/);
                    hops.push({ hop: parseInt(match[1]), ip: match[2], time: timeMatch ? `${timeMatch[1]} ms` : '*' });
                }
            }
            res.json({ data: { target, hops, raw: stdout } });
        }
        catch (_a) {
            res.status(500).json({ error: { message: 'Traceroute não disponível no servidor.' } });
        }
    }
    catch (error) {
        res.status(500).json({ error: { message: `Erro no traceroute: ${error.message}` } });
    }
});
app.post('/cpe/wifi/list', (_req, res) => {
    res.status(501).json({
        error: { message: 'Gerenciamento de WiFi via TR069 não configurado para este provedor.' },
    });
});
// =========================================================================
// GERAÇÃO DE APK
// =========================================================================
const child_process_1 = require("child_process");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const os = __importStar(require("os"));
app.post('/admin/generate-apk', apkLimiter, verifySuperAdmin, async (req, res) => {
    try {
        const { providerId, appName, logoUrl, format = 'apk' } = req.body;
        if (!providerId || !appName || !logoUrl) {
            return res.status(400).json({ success: false, error: 'providerId, appName e logoUrl são obrigatórios.' });
        }
        const tempLogoPath = path.join(os.tmpdir(), `logo_${providerId}_${Date.now()}.png`);
        try {
            const httpsModule = await Promise.resolve().then(() => __importStar(require('https')));
            const logoFile = fs.createWriteStream(tempLogoPath);
            await new Promise((resolve, reject) => {
                httpsModule.get(logoUrl, response => {
                    response.pipe(logoFile);
                    logoFile.on('finish', () => { logoFile.close(); resolve(); });
                }).on('error', err => { fs.unlink(tempLogoPath, () => { }); reject(err); });
            });
        }
        catch (downloadErr) {
            return res.status(400).json({ success: false, error: `Falha ao baixar logo: ${downloadErr.message}` });
        }
        const safeProviderId = providerId.replace(/[^a-z0-9]/gi, '').toLowerCase();
        const packageName = `br.com.provedores.${safeProviderId}`;
        const pythonArgs = [
            APK_SCRIPT_PATH,
            '--id', providerId,
            '--nome', appName,
            '--logo', tempLogoPath,
            '--output', APK_OUTPUT_DIR,
            '--package', packageName,
        ];
        if (format === 'aab') {
            pythonArgs.push('--format', 'aab', '--obfuscate');
        }
        const pythonProcess = (0, child_process_1.spawn)('python3', pythonArgs, { cwd: APK_PROJECT_ROOT });
        let stdout = '';
        let stderr = '';
        pythonProcess.stdout.on('data', (data) => { stdout += data.toString(); });
        pythonProcess.stderr.on('data', (data) => { stderr += data.toString(); });
        pythonProcess.on('close', code => {
            fs.unlink(tempLogoPath, () => { });
            if (code === 0) {
                const safeAppName = appName.replace(/[^a-zA-Z0-9]/g, '_');
                const extension = format === 'aab' ? 'aab' : 'apk';
                res.json({ success: true, message: `${format.toUpperCase()} gerado!`, downloadUrl: `/public_apks/app_${safeAppName}.${extension}`, logs: stdout });
            }
            else {
                res.status(500).json({ success: false, error: `Falha no script (Exit ${code})`, logs: stdout, errorLogs: stderr });
            }
        });
        pythonProcess.on('error', err => {
            fs.unlink(tempLogoPath, () => { });
            res.status(500).json({ success: false, error: `Erro ao executar script: ${err.message}` });
        });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// =========================================================================
// HEALTH CHECK
// =========================================================================
app.get('/health', (_req, res) => {
    res.json({ status: 'ok', ts: new Date().toISOString() });
});
app.listen(port, () => {
    console.log(`✅ API Service rodando na porta ${port}`);
});
