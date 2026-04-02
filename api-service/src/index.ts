import express from 'express';
import cors from 'cors';
import axios from 'axios';
import * as https from 'https';
import * as admin from 'firebase-admin';
import rateLimit from 'express-rate-limit';

// Inicializa Firebase Admin via Application Default Credentials (ADC)
admin.initializeApp();

const app = express();
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
const APK_FLUTTER_PROJECT = process.env.APK_FLUTTER_PROJECT || '/home/app/projects/painel_provedores/app-flutter/unified';

if (!SGP_TOKEN || !SGP_APP_NAME) {
  console.warn('[WARN] SGP_TOKEN ou SGP_APP_NAME não definidos. Endpoints SGP falharão.');
}
if (!FIREBASE_API_KEY) {
  console.warn('[WARN] FIREBASE_API_KEY não definida. Endpoint de login admin falhará.');
}

app.use(cors());
app.use(express.json());

// =========================================================================
// RATE LIMITING
// =========================================================================

// Limite global: 200 req/minuto por IP
const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { message: 'Muitas requisições. Tente novamente em 1 minuto.' } },
});

// Limite restrito para login: 10 tentativas/minuto por IP (brute force)
const loginLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { message: 'Muitas tentativas de login. Tente novamente em 1 minuto.' } },
});

// Limite para SGP (cada chamada consulta API externa): 30 req/minuto por IP
const sgpLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { message: 'Limite de consultas SGP atingido. Tente novamente em 1 minuto.' } },
});

// Limite para geração de APK: 5 req/hora por IP (operação pesada)
const apkLimiter = rateLimit({
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

const verifyToken = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).json({ error: { message: 'Token não fornecido' } });
  try {
    (req as any).user = await admin.auth().verifyIdToken(token);
    next();
  } catch {
    return res.status(403).json({ error: { message: 'Token inválido' } });
  }
};

const verifySuperAdmin = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).json({ error: { message: 'Token não fornecido' } });
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    if (decoded.superAdmin !== true) {
      return res.status(403).json({ error: { message: 'Apenas Super Admin pode executar esta operação' } });
    }
    (req as any).user = decoded;
    next();
  } catch {
    return res.status(403).json({ error: { message: 'Token inválido' } });
  }
};

// =========================================================================
// AUTH
// =========================================================================

app.post('/admin/auth/login', loginLimiter, async (req, res) => {
  try {
    if (!FIREBASE_API_KEY) {
      return res.status(503).json({ error: { message: 'Serviço de autenticação não configurado.' } });
    }
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: { message: 'Email e senha são obrigatórios.' } });
    }

    const authUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;
    const authResponse = await axios.post(authUrl, { email, password, returnSecureToken: true });
    const { idToken, localId, email: userEmail } = authResponse.data;

    res.json({ token: idToken, user: { uid: localId, email: userEmail } });
  } catch (error: any) {
    console.error('Erro no login admin:', error.response?.data || error.message);
    const errorMessage = error.response?.data?.error?.message || 'Falha na autenticação.';
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
      const data = doc.data();
      if (data.createdAt?.toDate) data.createdAt = data.createdAt.toDate().toISOString();
      if (data.updatedAt?.toDate) data.updatedAt = data.updatedAt.toDate().toISOString();
      return { id: doc.id, ...data };
    });
    res.json({ data: providers });
  } catch (error: any) {
    res.status(500).json({ error: { message: error.message } });
  }
});

app.post('/admin/providers', verifyToken, async (req, res) => {
  try {
    const { id, ...data } = req.body;
    const now = admin.firestore.FieldValue.serverTimestamp();
    if (!data.createdAt) data.createdAt = now;
    data.updatedAt = now;

    if (id) {
      delete data.createdAt;
      await admin.firestore().collection('provedores').doc(id).set(data, { merge: true });
      res.json({ success: true, id });
    } else {
      const docRef = await admin.firestore().collection('provedores').add(data);
      res.json({ success: true, id: docRef.id });
    }
  } catch (error: any) {
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
      const data = doc.data();
      if (data.createdAt?.toDate) data.createdAt = data.createdAt.toDate().toISOString();
      if (data.updatedAt?.toDate) data.updatedAt = data.updatedAt.toDate().toISOString();
      return { id: doc.id, ...data };
    });
    res.json({ data: tickets });
  } catch (error: any) {
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
      const data = doc.data();
      if (data.createdAt?.toDate) data.createdAt = data.createdAt.toDate().toISOString();
      return { id: doc.id, ...data };
    });
    res.json({ data: messages });
  } catch (error: any) {
    res.status(500).json({ error: { message: error.message } });
  }
});

app.patch('/admin/tickets/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const updates = { ...req.body, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
    await admin.firestore().collection('tickets').doc(id).update(updates);
    res.json({ success: true });
  } catch (error: any) {
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
  } catch (error: any) {
    res.status(500).json({ error: { message: error.message } });
  }
});

// =========================================================================
// USUÁRIOS
// =========================================================================

app.get('/admin/users', verifyToken, async (req, res) => {
  try {
    const snapshot = await admin.firestore().collection('users').orderBy('email').limit(100).get();
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ data: users });
  } catch (error: any) {
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
  } catch (error: any) {
    res.status(500).json({ error: { message: error.message } });
  }
});

// =========================================================================
// SGP — ENDPOINTS DO APP DO ASSINANTE
// =========================================================================

function requireSgpCredentials(res: express.Response): boolean {
  if (!SGP_TOKEN || !SGP_APP_NAME) {
    res.status(503).json({ error: { message: 'Credenciais do SGP não configuradas no servidor.' } });
    return false;
  }
  return true;
}

function createSgpSession() {
  return axios.create({
    httpsAgent: new https.Agent({ rejectUnauthorized: false }),
    headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json' },
  });
}

app.post('/getClientData', sgpLimiter, async (req, res) => {
  if (!requireSgpCredentials(res)) return;
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
          } else if (data.status?.toLowerCase() === 'online' || data.status?.toLowerCase() === 'ativo') {
            connectionStatus = 'Online';
          } else if (data.disponivel === true || data.disponivel === 1) {
            connectionStatus = 'Online';
          } else if (data.ativo === true || data.ativo === 1) {
            connectionStatus = 'Online';
          } else if (typeof data === 'object' && Object.keys(data).length > 0 && !data.error) {
            connectionStatus = 'Online';
          }
        }
      }
    } catch (verificaError: any) {
      console.error('[verificaacesso] Erro ao consultar status:', verificaError?.response?.data || verificaError.message);
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
  } catch (error: any) {
    console.error('Erro detalhado na getClientData:', error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.';
    res.status(500).json({ error: { message: `Erro ao buscar dados do cliente: ${errorMessage}` } });
  }
});

app.post('/getConsumptionData', sgpLimiter, async (req, res) => {
  if (!requireSgpCredentials(res)) return;
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

    const totalBytes = (consumoData.total as number) || 0;
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
  } catch (error: any) {
    console.error('Erro detalhado na getConsumptionData:', error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.';
    res.status(500).json({ error: { message: `Erro ao buscar dados de consumo: ${errorMessage}` } });
  }
});

app.post('/getInvoices', sgpLimiter, async (req, res) => {
  if (!requireSgpCredentials(res)) return;
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

    const formatInvoice = (invoice: any, pago: boolean) => ({
      pago,
      vencimento: invoice.dataVencimento,
      valor: parseFloat(invoice.valor || 0).toFixed(2).replace('.', ','),
      linha_digitavel: invoice.linhaDigitavel,
      linha_digitavel_pix: invoice.codigoPix,
      link: invoice.link,
      id: invoice.id,
      numero_documento: invoice.numeroDocumento,
    });

    const abertos = Array.isArray(responseAbertos.data?.titulos)
      ? responseAbertos.data.titulos.map((i: any) => formatInvoice(i, false))
      : [];
    const pagos = Array.isArray(responsePagos.data?.titulos)
      ? responsePagos.data.titulos.map((i: any) => formatInvoice(i, true))
      : [];

    res.json({ data: [...abertos, ...pagos] });
  } catch (error: any) {
    console.error('Erro detalhado na getInvoices:', error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.';
    res.status(500).json({ error: { message: `Erro ao buscar faturas: ${errorMessage}` } });
  }
});

app.post('/makePaymentPromise', sgpLimiter, async (req, res) => {
  if (!requireSgpCredentials(res)) return;
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

    if (promessaResponse.data?.status === false) {
      throw new Error(promessaResponse.data.msg || 'O SGP retornou um erro ao tentar realizar a promessa.');
    }

    res.json({
      success: true,
      message: promessaResponse.data.msg || 'Promessa de pagamento realizada com sucesso!',
    });
  } catch (error: any) {
    console.error('Erro detalhado na makePaymentPromise:', error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.';
    res.status(500).json({ error: { message: `Erro ao realizar promessa: ${errorMessage}` } });
  }
});

// =========================================================================
// DIAGNÓSTICO — ONU Signal e Traceroute
// =========================================================================

app.post('/diagnostic/onu-signal', sgpLimiter, async (req, res) => {
  try {
    const { cpfCnpj, sgpParams } = req.body;
    if (!cpfCnpj) {
      return res.status(400).json({ error: { message: 'CPF/CNPJ é obrigatório.' } });
    }

    const sgpBaseUrl = sgpParams?.sgpBaseUrl || 'https://vibetelecom.sgp.net.br';
    const token = SGP_TOKEN || sgpParams?.apiToken || sgpParams?.token;
    const appName = SGP_APP_NAME || sgpParams?.appName;

    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0' },
    });

    const onuResponse = await session.get(`${sgpBaseUrl}/api/fttx/onu/list/`, {
      params: { token, app: appName, cpfcnpj: cpfCnpj, signal: 1, connection: 1, address: 1 },
    });

    let onus: any[] = [];
    if (Array.isArray(onuResponse.data)) {
      onus = onuResponse.data;
    } else if (onuResponse.data && typeof onuResponse.data === 'object') {
      onus = [onuResponse.data];
    }

    if (onus.length === 0) {
      return res.status(404).json({ error: { message: 'Nenhuma ONU encontrada para este cliente.' } });
    }

    const onu = onus[0];
    const rawConnection = onu.connection?.toString()?.toLowerCase() || '';
    const isOnline =
      onu.online === true ||
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
        signalRx: onu.signal?.rx_power ?? onu.rx_power ?? onu.info_rx ?? null,
        signalTx: onu.signal?.tx_power ?? onu.tx_power ?? onu.info_tx ?? null,
        temperature: onu.signal?.temperature ?? onu.temperature ?? null,
        voltage: onu.signal?.voltage ?? onu.voltage ?? null,
        serialNumber: onu.phy_addr || onu.serial || null,
        mode: onu.mode_display || onu.mode || null,
        vlan: onu.vlan || null,
        cto: onu.splitter_name || onu.cto_name || null,
        lastUpdate: onu.signal?.updated_at || onu.updated_at || onu.info_date || null,
      },
    });
  } catch (error: any) {
    console.error('[ONU-Signal] Erro:', error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : 'Erro desconhecido';
    res.status(500).json({ error: { message: `Erro ao buscar sinal da ONU: ${errorMessage}` } });
  }
});

app.post('/diagnostic/traceroute', async (req, res) => {
  try {
    const { target = '8.8.8.8', maxHops = 15 } = req.body;
    const { exec } = await import('child_process');
    const { promisify } = await import('util');
    const execAsync = promisify(exec);

    try {
      const { stdout } = await execAsync(`traceroute -n -m ${maxHops} -w 2 ${target}`, { timeout: 30000 });
      const lines = stdout.split('\n').filter(line => line.trim());
      const hops: { hop: number; ip: string; time: string }[] = [];

      for (const line of lines) {
        if (line.includes('traceroute to')) continue;
        const match = line.match(/^\s*(\d+)\s+(\S+)\s+(.+)/);
        if (match) {
          const timeMatch = match[3].match(/(\d+\.?\d*)\s*ms/);
          hops.push({ hop: parseInt(match[1]), ip: match[2], time: timeMatch ? `${timeMatch[1]} ms` : '*' });
        }
      }

      res.json({ data: { target, hops, raw: stdout } });
    } catch {
      res.status(500).json({ error: { message: 'Traceroute não disponível no servidor.' } });
    }
  } catch (error: any) {
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
import { spawn } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

app.post('/admin/generate-apk', apkLimiter, verifySuperAdmin, async (req, res) => {
  try {
    const { providerId, appName, logoUrl, format = 'apk' } = req.body;
    if (!providerId || !appName || !logoUrl) {
      return res.status(400).json({ success: false, error: 'providerId, appName e logoUrl são obrigatórios.' });
    }

    const tempLogoPath = path.join(os.tmpdir(), `logo_${providerId}_${Date.now()}.png`);
    try {
      const httpsModule = await import('https');
      const logoFile = fs.createWriteStream(tempLogoPath);
      await new Promise<void>((resolve, reject) => {
        httpsModule.get(logoUrl, response => {
          response.pipe(logoFile);
          logoFile.on('finish', () => { logoFile.close(); resolve(); });
        }).on('error', err => { fs.unlink(tempLogoPath, () => {}); reject(err); });
      });
    } catch (downloadErr: any) {
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
      '--flutter-project', APK_FLUTTER_PROJECT,
      '--package', packageName,
    ];
    if (format === 'aab') {
      pythonArgs.push('--format', 'aab', '--obfuscate');
    }

    const pythonProcess = spawn('python3', pythonArgs, { cwd: APK_PROJECT_ROOT });
    let stdout = '';
    let stderr = '';

    pythonProcess.stdout.on('data', (data) => { stdout += data.toString(); });
    pythonProcess.stderr.on('data', (data) => { stderr += data.toString(); });

    pythonProcess.on('close', code => {
      fs.unlink(tempLogoPath, () => {});
      if (code === 0) {
        const safeAppName = appName.replace(/[^a-zA-Z0-9]/g, '_');
        const extension = format === 'aab' ? 'aab' : 'apk';
        res.json({ success: true, message: `${format.toUpperCase()} gerado!`, downloadUrl: `/public_apks/app_${safeAppName}.${extension}`, logs: stdout });
      } else {
        res.status(500).json({ success: false, error: `Falha no script (Exit ${code})`, logs: stdout, errorLogs: stderr });
      }
    });

    pythonProcess.on('error', err => {
      fs.unlink(tempLogoPath, () => {});
      res.status(500).json({ success: false, error: `Erro ao executar script: ${err.message}` });
    });
  } catch (error: any) {
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
