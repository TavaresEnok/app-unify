import express from 'express';
import cors from 'cors';
import axios from 'axios';
import * as https from 'https';
import * as admin from 'firebase-admin';

// Inicializa Firebase Admin
const serviceAccount = require('./config/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const app = express();
// <-- MUDANÇA: Porta alterada para 9136 para corresponder ao seu ambiente.
const port = 9136;

app.use(cors());
app.use(express.json());

// ATENÇÃO: Configure estas variáveis no seu ambiente de servidor!
const SGP_TOKEN = process.env.SGP_TOKEN || "SEU_TOKEN_AQUI";
const SGP_APP_NAME = process.env.SGP_APP_NAME || "SEU_APP_NAME_AQUI";
const FIREBASE_API_KEY = "AIzaSyBcLSCsZsTSd4fcBQubZ8E4_JHOxuIs6is"; // Hardcoded for simplified BFF setup (from firebase_options)

// --- NOVAS ROTAS ADMIN BFF ---

// Endpoint de Login (Proxy para Identity Toolkit)
app.post('/admin/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: { message: "Email e senha são obrigatórios." } });
    }

    // Chama Identity Toolkit para verificar senha e obter tokens
    const authUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;
    const authResponse = await axios.post(authUrl, {
      email,
      password,
      returnSecureToken: true
    });

    const { idToken, localId, email: userEmail } = authResponse.data;

    // (Opcional) Verificar se é admin no Firestore
    // const userDoc = await admin.firestore().collection('user_profiles').doc(localId).get();
    // if (!userDoc.exists || userDoc.data()?.role !== 'admin') { ... }

    res.json({
      token: idToken,
      user: {
        uid: localId,
        email: userEmail
      }
    });
  } catch (error: any) {
    console.error("Erro no login admin:", error.response?.data || error.message);
    const errorMessage = error.response?.data?.error?.message || "Falha na autenticação.";
    res.status(401).json({ error: { message: errorMessage } });
  }
});

// --- REGRAS DE SEGURANÇA (Middleware simplificado) ---
const verifyToken = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).json({ error: { message: "Token não fornecido" } });
  try {
    await admin.auth().verifyIdToken(token);
    next();
  } catch (error) {
    return res.status(403).json({ error: { message: "Token inválido" } });
  }
};

// --- ENDPOINTS DE PROVEDORES ---

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
    // Ensure we don't save ISO strings back as strings if we want timestamps?
    // Actually, save as standard Firestore data. 
    // If input has ISO strings, we might want to convert them to Timestamps if needed.
    // But for simplicity, we can store regular fields. 
    // Ideally we assume frontend sends data safe for storage (or we let Firestore store strings/maps).
    // But for consistency:
    const now = admin.firestore.FieldValue.serverTimestamp();
    if (!data.createdAt) data.createdAt = now;
    data.updatedAt = now;

    if (id) {
      delete data.createdAt; // Don't overwrite creation date on update
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

// --- ENDPOINTS DE TICKETS ---

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

// --- ENDPOINTS DE USUÁRIOS ---

app.get('/admin/users', verifyToken, async (req, res) => {
  try {
    const snapshot = await admin.firestore().collection('users').orderBy('email').limit(100).get();
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ data: users });
  } catch (error: any) {
    res.status(500).json({ error: { message: error.message } });
  }
});

app.get('/admin/tickets/:id/messages', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const snapshot = await admin.firestore()
      .collection('tickets')
      .doc(id)
      .collection('messages')
      .orderBy('createdAt', 'asc')
      .get();

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
    const updates = req.body;

    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

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
      read: false
    });

    await ticketRef.update({
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'Em Andamento',
      lastMessage: message
    });

    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: { message: error.message } });
  }
});

// --- ENDPOINT DASHBOARD ---

app.get('/admin/dashboard', verifyToken, async (req, res) => {
  try {
    const db = admin.firestore();
    const providersSnap = await db.collection('provedores').count().get();
    const ticketsOpenSnap = await db.collection('tickets').where('status', '==', 'Aberto').count().get();
    const ticketsTotalSnap = await db.collection('tickets').count().get();

    // Simulação de "Users" (Clientes) - Ajustar se tiver coleção de users
    const usersSnap = { data: { count: 0 } }; // await db.collection('users').count().get();

    res.json({
      data: {
        totalProviders: providersSnap.data().count,
        totalTickets: ticketsTotalSnap.data().count,
        openTickets: ticketsOpenSnap.data().count,
        totalUsers: 1540 // Mock ou query real
      }
    });
  } catch (error: any) {
    res.status(500).json({ error: { message: error.message } });
  }
});


// Endpoint para dados do cliente (Login) - Sem alterações
app.post('/getClientData', async (req, res) => {
  try {
    const { cpfCnpj } = req.body;
    if (!cpfCnpj) {
      return res.status(400).json({ error: { message: "CPF/CNPJ é obrigatório." } });
    }
    if (!SGP_TOKEN || !SGP_APP_NAME) {
      throw new Error("Credenciais do SGP não configuradas no servidor.");
    }

    const baseUrl = "https://vibetelecom.sgp.net.br";
    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json' }
    });

    const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      cpfcnpj: cpfCnpj,
    });

    if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
      throw new Error("Nenhum contrato encontrado para este cliente.");
    }

    const contrato = consultaResponse.data.contratos[0];
    const hoje = new Date();
    const mesAtual = hoje.getMonth() + 1;
    const anoAtual = hoje.getFullYear();

    // ========================================================================
    // CONSULTA DE STATUS DE CONEXÃO REAL (verificaacesso)
    // ========================================================================
    let connectionStatus = 'Offline'; // Default
    try {
      const contratoId = contrato.contratoId || contrato.contrato_id || contrato.id;
      const cpfLimpo = cpfCnpj.replace(/\D/g, '');
      const senhaCentral = contrato.contratoCentralSenha || contrato.central_senha || '';

      if (contratoId && senhaCentral) {
        console.log(`[verificaacesso] Consultando status para contrato ${contratoId}`);

        const verificaResponse = await session.post(`${baseUrl}/api/central/verificaacesso/`, {
          cpfcnpj: cpfLimpo,
          senha: senhaCentral,
          contrato: contratoId,
        });

        console.log('[verificaacesso] Resposta:', JSON.stringify(verificaResponse.data).substring(0, 500));

        // A API retorna o status de disponibilidade da conexão
        // Campos possíveis: online, status, disponivel, ativo
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
            // Se retornou dados sem erro, provavelmente está online
            // Alguns SGPs retornam apenas os dados de uso quando está online
            connectionStatus = 'Online';
          }
        }
      } else {
        console.log('[verificaacesso] Dados insuficientes para consulta:', { contratoId, senhaCentral: senhaCentral ? '***' : 'null' });
      }
    } catch (verificaError: any) {
      console.error('[verificaacesso] Erro ao consultar status:', verificaError?.response?.data || verificaError.message);
      // Em caso de erro, mantém Offline como fallback seguro
    }
    console.log(`[verificaacesso] Status final: ${connectionStatus}`);
    // ========================================================================

    const clientData = {
      cpfCnpj: contrato.cpfCnpj,
      senha: contrato.contratoCentralSenha,
      userName: contrato.razaoSocial,
      userPlan: contrato.servico_plano,
      userStatus: connectionStatus, // Agora usa o status real de conexão!
      billValue: `R$ ${parseFloat(contrato.contratoValorAberto || 0).toFixed(2).replace('.', ',')}`,
      billDueDate: `Vence em ${contrato.cobVencimento}/${mesAtual}/${anoAtual}`,
      contratoId: contrato.contratoId || contrato.contrato_id || contrato.id,
    };

    res.json({ data: clientData });

  } catch (error: any) {
    console.error("Erro detalhado na getClientData:", error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : "Ocorreu um erro desconhecido.";
    res.status(500).json({ error: { message: `Erro ao buscar dados do cliente: ${errorMessage}` } });
  }
});


// =========================================================================
// CORREÇÃO APLICADA AQUI
// =========================================================================
app.post('/getConsumptionData', async (req, res) => {
  try {
    const { cpfCnpj, senha } = req.body;
    if (!cpfCnpj || !senha) {
      return res.status(400).json({ error: { message: "CPF/CNPJ e Senha da Central são obrigatórios." } });
    }

    const baseUrl = "https://vibetelecom.sgp.net.br";
    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0' }
    });

    // --- ETAPA 1: USAR O MÉTODO CONFIÁVEL PARA OBTER O ID DO CONTRATO ---
    // Em vez de usar /api/central/contratos, usamos o mesmo endpoint do login, que é mais robusto.
    const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      cpfcnpj: cpfCnpj,
    });

    if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
      throw new Error("Nenhum contrato encontrado para este cliente.");
    }

    // Agora pegamos o ID do contrato de forma confiável
    const contratoId = consultaResponse.data.contratos[0].contratoId;

    // --- ETAPA 2: CONTINUAR COM A BUSCA DO EXTRATO, AGORA COM O ID CORRETO ---
    const hoje = new Date();
    const mes = hoje.getMonth() + 1;
    const ano = hoje.getFullYear();

    const extratoPayload = new URLSearchParams();
    extratoPayload.append('cpfcnpj', cpfCnpj);
    extratoPayload.append('senha', senha);
    extratoPayload.append('contrato', contratoId.toString()); // Garantir que é string
    extratoPayload.append('mes', mes.toString());
    extratoPayload.append('ano', ano.toString());

    const extratoResponse = await session.post(`${baseUrl}/api/central/extratouso/`, extratoPayload);

    const consumoData = extratoResponse.data;

    const totalBytes = consumoData.total as number || 0;
    const usedGb = totalBytes / (1024 * 1024 * 1024);

    const planoCliente = consumoData.plano || "Plano não informado";
    // Lógica para extrair o total de GB do nome do plano (ex: "VIBE 500 MEGA")
    const match = planoCliente.match(/(\d+)/);
    // Se não encontrar um número, assume um valor alto para o gráfico não quebrar.
    const totalGb = match ? parseFloat(match[1]) : 1000;

    const realData = {
      totalGb: totalGb,
      usedGb: usedGb,
      averageSpeed: "N/A", // API não fornece essa informação
      period: `${mes.toString().padStart(2, '0')}/${ano}`,
    };

    res.json({ data: realData });

  } catch (error: any) {
    console.error("Erro detalhado na getConsumptionData:", error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : "Ocorreu um erro desconhecido.";
    res.status(500).json({ error: { message: `Erro ao buscar dados de consumo: ${errorMessage}` } });
  }
});


// Endpoint de Faturas
app.post('/getInvoices', async (req, res) => {
  try {
    const { cpfCnpj } = req.body;
    if (!cpfCnpj) {
      return res.status(400).json({ error: { message: "CPF/CNPJ é obrigatório." } });
    }

    const baseUrl = "https://vibetelecom.sgp.net.br";
    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json' }
    });

    const responseAbertos = await session.post(`${baseUrl}/api/ura/titulos/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      cpfcnpj: cpfCnpj,
      status: 'abertos'
    });

    const titulos = responseAbertos.data?.titulos;
    let formattedInvoices: any[] = [];

    if (titulos && Array.isArray(titulos)) {
      formattedInvoices = titulos.map((invoice: any) => ({
        pago: invoice.dataPagamento !== null && invoice.dataPagamento !== "",
        vencimento: invoice.dataVencimento,
        valor: parseFloat(invoice.valor || 0).toFixed(2).replace('.', ','),
        linha_digitavel: invoice.linhaDigitavel,
        linha_digitavel_pix: invoice.codigoPix,
        link: invoice.link,
        id: invoice.id,
        numero_documento: invoice.numeroDocumento,
      }));
    }

    const responsePagos = await session.post(`${baseUrl}/api/ura/titulos/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      cpfcnpj: cpfCnpj,
      status: 'pagos'
    });

    const titulosPagos = responsePagos.data?.titulos;
    if (titulosPagos && Array.isArray(titulosPagos)) {
      const formattedPagos = titulosPagos.map((invoice: any) => ({
        pago: true,
        vencimento: invoice.dataVencimento,
        valor: parseFloat(invoice.valor || 0).toFixed(2).replace('.', ','),
        linha_digitavel: invoice.linhaDigitavel,
        linha_digitavel_pix: invoice.codigoPix,
        link: invoice.link,
        id: invoice.id,
        numero_documento: invoice.numeroDocumento,
      }));
      formattedInvoices.push(...formattedPagos);
    }

    res.json({ data: formattedInvoices });

  } catch (error: any) {
    console.error("Erro detalhado na getInvoices:", error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : "Ocorreu um erro desconhecido.";
    res.status(500).json({ error: { message: `Erro ao buscar faturas: ${errorMessage}` } });
  }
});

// Endpoint para Promessa de Pagamento
app.post('/makePaymentPromise', async (req, res) => {
  try {
    const { cpfCnpj } = req.body;
    if (!cpfCnpj) {
      return res.status(400).json({ error: { message: "CPF/CNPJ é obrigatório." } });
    }

    if (!SGP_TOKEN || !SGP_APP_NAME) {
      throw new Error("Credenciais do SGP não configuradas no servidor.");
    }

    const baseUrl = "https://vibetelecom.sgp.net.br";
    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0', 'Content-Type': 'application/json' }
    });

    const consultaResponse = await session.post(`${baseUrl}/ws/ura/consultacliente/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      cpfcnpj: cpfCnpj,
    });

    if (!consultaResponse.data || !Array.isArray(consultaResponse.data.contratos) || consultaResponse.data.contratos.length === 0) {
      throw new Error("Contrato não encontrado para este cliente.");
    }
    const contratoId = consultaResponse.data.contratos[0].contratoId;

    const promessaResponse = await session.post(`${baseUrl}/api/ura/liberacaopromessa/`, {
      token: SGP_TOKEN,
      app: SGP_APP_NAME,
      contrato: contratoId
    });

    if (promessaResponse.data?.status === false) {
      throw new Error(promessaResponse.data.msg || "O SGP retornou um erro ao tentar realizar a promessa.");
    }

    res.json({
      success: true,
      message: promessaResponse.data.msg || "Promessa de pagamento realizada com sucesso!"
    });

  } catch (error: any) {
    console.error("Erro detalhado na makePaymentPromise:", error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : "Ocorreu um erro desconhecido.";
    res.status(500).json({ error: { message: `Erro ao realizar promessa: ${errorMessage}` } });
  }
});

// =========================================================================
// GERAÇÃO DE APK - ENDPOINT LOCAL
// =========================================================================
import { spawn } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

// Middleware para verificar superAdmin
const verifySuperAdmin = async (req: express.Request, res: express.Response, next: express.NextFunction) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).json({ error: { message: "Token não fornecido" } });
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    if (decoded.superAdmin !== true) {
      return res.status(403).json({ error: { message: "Apenas Super Admin pode gerar APKs" } });
    }
    (req as any).user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: { message: "Token inválido" } });
  }
};

app.post('/admin/generate-apk', verifySuperAdmin, async (req, res) => {
  try {
    const { providerId, appName, logoUrl, format = 'apk' } = req.body;

    if (!providerId || !appName || !logoUrl) {
      return res.status(400).json({
        success: false,
        error: "providerId, appName e logoUrl são obrigatórios."
      });
    }

    console.log(`[APK Gen] Starting for ${providerId} (${appName}). Format: ${format}`);

    // 1. Download logo to temp file
    const tempLogoPath = path.join(os.tmpdir(), `logo_${providerId}_${Date.now()}.png`);

    try {
      const https = await import('https');
      const logoFile = fs.createWriteStream(tempLogoPath);

      await new Promise<void>((resolve, reject) => {
        https.get(logoUrl, (response) => {
          response.pipe(logoFile);
          logoFile.on('finish', () => {
            logoFile.close();
            resolve();
          });
        }).on('error', (err) => {
          fs.unlink(tempLogoPath, () => { });
          reject(err);
        });
      });
    } catch (downloadErr: any) {
      return res.status(400).json({
        success: false,
        error: `Falha ao baixar logo: ${downloadErr.message}`
      });
    }

    // 2. Build Python command
    const scriptPath = '/home/app/projects/painel_provedores/admin-script/gerar_apk.py';
    const projectRoot = '/home/app/projects/painel_provedores';

    // Generate package name
    const safeProviderId = providerId.replace(/[^a-z0-9]/gi, '').toLowerCase();
    const packageName = `br.com.provedores.${safeProviderId}`;

    const pythonArgs = [
      scriptPath,
      '--id', providerId,
      '--nome', appName,
      '--logo', tempLogoPath,
      '--output', '/home/app/projects/painel_provedores/public_apks',
      '--package', packageName
    ];

    if (format === 'aab') {
      pythonArgs.push('--format', 'aab');
      pythonArgs.push('--obfuscate');
    }

    // 3. Execute Python script
    const pythonProcess = spawn('python3', pythonArgs, { cwd: projectRoot });

    let stdout = '';
    let stderr = '';

    pythonProcess.stdout.on('data', (data) => {
      const str = data.toString();
      stdout += str;
      console.log(`[APK Gen]: ${str}`);
    });

    pythonProcess.stderr.on('data', (data) => {
      const str = data.toString();
      stderr += str;
      console.error(`[APK Gen Error]: ${str}`);
    });

    pythonProcess.on('close', (code) => {
      // Cleanup temp logo
      fs.unlink(tempLogoPath, () => { });

      if (code === 0) {
        // Extract APK path from output
        const safeAppName = appName.replace(/[^a-zA-Z0-9]/g, '_');
        const extension = format === 'aab' ? 'aab' : 'apk';
        const apkPath = `/public_apks/app_${safeAppName}.${extension}`;

        res.json({
          success: true,
          message: `${format.toUpperCase()} gerado com sucesso!`,
          downloadUrl: apkPath,
          logs: stdout
        });
      } else {
        res.status(500).json({
          success: false,
          error: `Falha no script (Exit ${code})`,
          logs: stdout,
          errorLogs: stderr
        });
      }
    });

    pythonProcess.on('error', (err) => {
      fs.unlink(tempLogoPath, () => { });
      res.status(500).json({
        success: false,
        error: `Erro ao executar script: ${err.message}`
      });
    });

  } catch (error: any) {
    console.error('[APK Gen] Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// =========================================================================
// ENDPOINTS DE DIAGNÓSTICO - ONU Signal e Traceroute
// =========================================================================

// Endpoint para buscar sinal da ONU via SGP
app.post('/diagnostic/onu-signal', async (req, res) => {
  try {
    const { cpfCnpj, senha, contrato, sgpParams } = req.body;

    console.log('[ONU-Signal] Recebido:', { cpfCnpj, contrato, sgpParams });

    if (!cpfCnpj) {
      return res.status(400).json({ error: { message: "CPF/CNPJ é obrigatório." } });
    }

    const sgpBaseUrl = sgpParams?.sgpBaseUrl || "https://vibetelecom.sgp.net.br";
    // PRIORIDADE: SGP_TOKEN (Env) > sgpParams (App)
    // Isso garante que nossas correções no backend funcionem mesmo que o app envie lixo
    const token = SGP_TOKEN || sgpParams?.apiToken || sgpParams?.token;
    const appName = SGP_APP_NAME || sgpParams?.appName;

    console.log('[ONU-Signal] Usando:', { sgpBaseUrl, token: token?.substring(0, 10) + '...', appName });

    const session = axios.create({
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      headers: { 'User-Agent': 'Mozilla/5.0' }
    });

    // Buscar ONU do cliente via API SGP
    // Buscar ONU do cliente via API SGP
    // REVERT: Voltar para GET, pois POST retornou 405 Method Not Allowed.
    // O endpoint /api/fttx/onu/list/ parece exigir GET.
    const onuResponse = await session.get(`${sgpBaseUrl}/api/fttx/onu/list/`, {
      params: {
        token,
        app: appName,
        cpfcnpj: cpfCnpj,
        signal: 1,
        connection: 1,
        address: 1
      }
    });

    console.log('[ONU-Signal] Resposta SGP status:', onuResponse.status);
    // Log truncado se for muito grande
    const logData = JSON.stringify(onuResponse.data);
    console.log('[ONU-Signal] Resposta SGP data (trunc):', logData.substring(0, 500));

    console.log('[ONU-Signal] Resposta SGP status:', onuResponse.status);
    // Log truncado se for muito grande, mas suficiente para ver a estrutura
    console.log('[ONU-Signal] Resposta SGP data:', JSON.stringify(onuResponse.data, null, 2));

    // -------------------------------------------------------------------------
    // Tratamento de resposta flexível (Array ou Objeto Único)
    let onus: any[] = [];
    if (Array.isArray(onuResponse.data)) {
      onus = onuResponse.data;
    } else if (onuResponse.data && typeof onuResponse.data === 'object') {
      // SGP as vezes retorna o objeto direto se for busca por ID ou um único resultado
      onus = [onuResponse.data];
    }

    console.error('[ONU-Signal] ONUs encontradas:', onus.length);

    if (onus.length === 0) {
      return res.status(404).json({
        error: { message: "Nenhuma ONU encontrada para este cliente." }
      });
    }

    const onu = onus[0];

    // Determinar status de conexão
    // SGP field: 'online' (boolean) or 'connection' (string)
    const rawConnection = onu.connection?.toString()?.toLowerCase() || '';
    const isOnline = onu.online === true ||
      rawConnection === 'online' ||
      rawConnection === '1' ||
      rawConnection === 'true';

    // Status para exibição
    const connectionStatus = isOnline ? 'Online' : (onu.status_display || onu.connection || 'Offline');

    // Formatar resposta para o app Flutter (campos devem corresponder ao OnuData.fromJson)
    const onuData = {
      // Campos obrigatórios do OnuData
      connectionStatus: connectionStatus,
      isOnline: isOnline,
      oltId: onu.olt_id || onu.olt || 0,
      oltName: onu.olt_name || onu.olt_display || null,
      slot: onu.slot || 0,
      pon: onu.pon || 0,
      onuId: onu.onuid || onu.onuidreal || 0,
      model: onu.model || onu.onutype_display || 'Desconhecido',

      // Campos opcionais de sinal
      signalRx: onu.signal?.rx_power ?? onu.rx_power ?? onu.info_rx ?? null,
      signalTx: onu.signal?.tx_power ?? onu.tx_power ?? onu.info_tx ?? null,
      temperature: onu.signal?.temperature ?? onu.temperature ?? null,
      voltage: onu.signal?.voltage ?? onu.voltage ?? null,

      // Campos adicionais
      serialNumber: onu.phy_addr || onu.serial || null,
      mode: onu.mode_display || onu.mode || null,
      vlan: onu.vlan || null,
      cto: onu.splitter_name || onu.cto_name || null,
      lastUpdate: onu.signal?.updated_at || onu.updated_at || onu.info_date || null,
    };

    console.log('[ONU-Signal] Dados retornados:', onuData);
    res.json({ data: onuData });

  } catch (error: any) {
    console.error("[ONU-Signal] Erro:", error.response?.data || error.message);
    const errorMessage = error instanceof Error ? error.message : "Erro desconhecido";
    res.status(500).json({
      error: { message: `Erro ao buscar sinal da ONU: ${errorMessage}` }
    });
  }
});

// Endpoint para Traceroute real
app.post('/diagnostic/traceroute', async (req, res) => {
  try {
    const { target = '8.8.8.8', maxHops = 15 } = req.body;

    console.log(`[Traceroute] Iniciando para ${target} com max ${maxHops} hops`);

    // Executa traceroute no servidor
    const { exec } = await import('child_process');
    const { promisify } = await import('util');
    const execAsync = promisify(exec);

    // Tenta traceroute (Linux) ou tracert (Windows) 
    let command = `traceroute -n -m ${maxHops} -w 2 ${target}`;

    try {
      const { stdout, stderr } = await execAsync(command, { timeout: 30000 });

      // Parse output do traceroute
      const lines = stdout.split('\n').filter(line => line.trim());
      const hops: { hop: number; ip: string; time: string }[] = [];

      for (const line of lines) {
        // Skip header line
        if (line.includes('traceroute to')) continue;

        // Parse formato: " 1  192.168.1.1  1.234 ms  1.456 ms  1.789 ms"
        const match = line.match(/^\s*(\d+)\s+(\S+)\s+(.+)/);
        if (match) {
          const hopNum = parseInt(match[1]);
          const ip = match[2];
          const times = match[3];

          // Extrai primeiro tempo válido
          const timeMatch = times.match(/(\d+\.?\d*)\s*ms/);
          const time = timeMatch ? `${timeMatch[1]} ms` : '*';

          hops.push({ hop: hopNum, ip, time });
        }
      }

      console.log(`[Traceroute] Concluído com ${hops.length} hops`);
      res.json({
        data: {
          target,
          hops,
          raw: stdout
        }
      });

    } catch (execError: any) {
      // Traceroute pode não estar instalado
      console.error('[Traceroute] Erro na execução:', execError.message);
      res.status(500).json({
        error: { message: "Traceroute não disponível no servidor." }
      });
    }

  } catch (error: any) {
    console.error("[Traceroute] Erro:", error.message);
    res.status(500).json({
      error: { message: `Erro no traceroute: ${error.message}` }
    });
  }
});

// Endpoint para WiFi via TR069/CPE (se disponível)
app.post('/cpe/wifi/list', async (req, res) => {
  // Este endpoint depende de integração TR069 que pode não estar disponível
  // Por ora retorna mensagem informativa
  res.status(501).json({
    error: {
      message: "Gerenciamento de WiFi via TR069 não configurado para este provedor."
    }
  });
});

app.listen(port, () => {
  console.log(`✅ API Service a rodar na porta ${port}`);
});
