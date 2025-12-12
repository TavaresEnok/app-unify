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
Object.defineProperty(exports, "__esModule", { value: true });
// ==========================================================
// CORREÇÃO 1: Removido 'Response' desta linha de import
// ==========================================================
const https_1 = require("firebase-functions/v2/https");
const firebase_functions_1 = require("firebase-functions");
const admin = __importStar(require("firebase-admin"));
const { FirestoreAdminClient } = require("@google-cloud/firestore").v1;
const { Storage } = require("@google-cloud/storage");
admin.initializeApp();
const firestoreClient = new FirestoreAdminClient();
const storage = new Storage();
const db = admin.firestore();
const auth = admin.auth();
const messaging = admin.messaging();
// ... (todo o resto do código permanece igual até a função sendTestNotification)
// --- Funções de Backup ---
exports.createFirestoreBackup = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem criar backups.");
    }
    const projectId = process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId;
    const databaseName = firestoreClient.databasePath(projectId, "(default)");
    const bucket = `gs://${projectId}.appspot.com`;
    const timestamp = new Date().toISOString().replace(/:/g, "-").replace(/\..+/, "");
    const path = `${bucket}/backups/${timestamp}`;
    try {
        firebase_functions_1.logger.info(`Iniciando backup do banco de dados '${databaseName}' para o bucket '${path}'`);
        await firestoreClient.exportDocuments({
            name: databaseName,
            outputUriPrefix: path,
            collectionIds: [],
        });
        return { success: true, message: "Processo de backup iniciado com sucesso. Pode levar alguns minutos para aparecer na lista." };
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao criar backup do Firestore:", error);
        throw new https_1.HttpsError("internal", "Falha ao iniciar o processo de backup.");
    }
});
exports.listBackups = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem listar backups.");
    }
    const bucketName = `${process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId}.appspot.com`;
    try {
        const [files] = await storage.bucket(bucketName).getFiles({ prefix: "backups/" });
        const backupFolders = new Set();
        files.forEach((file) => {
            if (file.name.endsWith(".overall_export_metadata")) {
                const parts = file.name.split("/");
                if (parts.length > 1) {
                    backupFolders.add(parts[1]);
                }
            }
        });
        const backups = Array.from(backupFolders).map((name) => ({
            name: String(name),
            fullPath: `backups/${name}`,
        }));
        return backups.sort((a, b) => b.name.localeCompare(a.name));
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao listar backups:", error);
        throw new https_1.HttpsError("internal", "Falha ao listar os backups.");
    }
});
exports.generateBackupDownloadUrl = (0, https_1.onCall)({ region: "southamerica-east1", timeoutSeconds: 300 }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem baixar backups.");
    }
    const { folderPath } = request.data;
    if (!folderPath) {
        throw new https_1.HttpsError("invalid-argument", "O caminho da pasta de backup e obrigatorio.");
    }
    const bucketName = `${process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId}.appspot.com`;
    const mainMetadataFile = `${folderPath.split("/").pop()}.overall_export_metadata`;
    const filePath = `${folderPath}/${mainMetadataFile}`;
    try {
        const options = { version: "v4", action: "read", expires: Date.now() + 15 * 60 * 1000 };
        const [url] = await storage.bucket(bucketName).file(filePath).getSignedUrl(options);
        return { downloadUrl: url };
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao gerar URL de download:", error);
        throw new https_1.HttpsError("internal", "Nao foi possivel gerar o link para download.");
    }
});
exports.deleteBackupFolder = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem apagar backups.");
    }
    const { folderPath } = request.data;
    if (!folderPath) {
        throw new https_1.HttpsError("invalid-argument", "O caminho da pasta de backup e obrigatorio.");
    }
    const bucketName = `${process.env.GCLOUD_PROJECT || admin.instanceId().app.options.projectId}.appspot.com`;
    try {
        await storage.bucket(bucketName).deleteFiles({ prefix: `${folderPath}/` });
        firebase_functions_1.logger.info(`Backup na pasta ${folderPath} apagado com sucesso.`);
        return { success: true, message: "Backup apagado com sucesso." };
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao apagar a pasta de backup:", error);
        throw new https_1.HttpsError("internal", "Falha ao apagar o backup.");
    }
});
// --- Funções de Provedores e Utilizadores ---
exports.getProviders = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem listar provedores.");
    }
    try {
        const snapshot = await db.collection("provedores").get();
        const providers = snapshot.docs.map((doc) => (Object.assign({ id: doc.id }, doc.data())));
        return providers;
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao buscar provedores:", error);
        throw new https_1.HttpsError("internal", "Nao foi possivel buscar os provedores.");
    }
});
exports.createProvider = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem criar provedores.");
    }
    const { providerId, providerName } = request.data;
    if (!providerId || !providerName) {
        throw new https_1.HttpsError("invalid-argument", "Os campos providerId e providerName sao obrigatorios.");
    }
    try {
        const providerRef = db.collection("provedores").doc(providerId);
        const defaultConfig = {
            id: providerId, nome_provedor: providerName, logo_url: "",
            carrossel_imagens: [], dicas: [], faq: [],
            tema: { cor_primaria: "#673AB7", cor_secundaria: "#9575CD" },
            suporte: { whatsapp: "", endereco: "", horario_atendimento: "" },
            funcionalidades: { pagar_fatura_ativado: true, notificacoes_ativadas: true, carrossel_ativado: true, dicas_uteis_ativadas: true, ferramenta_dicas_ativada: true, ferramenta_faq_ativada: true, ferramenta_meuip_ativada: true, ferramenta_velocidade_ativada: true, ferramenta_down_detector_ativada: true },
        };
        await providerRef.set(defaultConfig);
        return { success: true, message: `Provedor ${providerName} criado com sucesso!` };
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao criar provedor:", error);
        throw new https_1.HttpsError("internal", "Nao foi possivel criar o provedor.");
    }
});
exports.getProviderById = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Autenticacao necessaria.");
    }
    const { providerId } = request.data;
    if (!providerId) {
        throw new https_1.HttpsError("invalid-argument", "providerId e obrigatorio.");
    }
    try {
        const doc = await db.collection("provedores").doc(providerId).get();
        if (!doc.exists) {
            throw new https_1.HttpsError("not-found", "Provedor nao encontrado.");
        }
        return Object.assign({ id: doc.id }, doc.data());
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao buscar provedor por ID:", error);
        throw new https_1.HttpsError("internal", "Erro ao buscar dados do provedor.");
    }
});
exports.updateProviderConfig = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Autenticacao necessaria.");
    }
    const { providerId, configData } = request.data;
    if (!providerId || !configData) {
        throw new https_1.HttpsError("invalid-argument", "providerId e configData sao obrigatorios.");
    }
    try {
        await db.collection("provedores").doc(providerId).set(configData, { merge: true });
        return { success: true, message: "Configuracao salva com sucesso." };
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao atualizar provedor:", error);
        throw new https_1.HttpsError("internal", "Erro ao salvar configuracao.");
    }
});
exports.deleteProvider = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem apagar provedores.");
    }
    const { providerId } = request.data;
    if (!providerId) {
        throw new https_1.HttpsError("invalid-argument", "providerId e obrigatorio.");
    }
    try {
        await db.collection("provedores").doc(providerId).delete();
        return { success: true, message: "Provedor apagado com sucesso." };
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao apagar provedor:", error);
        throw new https_1.HttpsError("internal", "Erro ao apagar provedor.");
    }
});
exports.setSuperAdmin = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    const { email } = request.data;
    if (!email) {
        throw new https_1.HttpsError("invalid-argument", "O campo 'email' e obrigatorio.");
    }
    try {
        const user = await auth.getUserByEmail(email);
        await auth.setCustomUserClaims(user.uid, { superAdmin: true });
        return { message: `Sucesso! O utilizador ${email} agora e Super Admin.` };
    }
    catch (error) {
        firebase_functions_1.logger.error(`Erro ao tornar ${email} Super Admin:`, error);
        throw new https_1.HttpsError("internal", "Erro ao definir permissao de Super Admin.");
    }
});
exports.listUsers = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem listar utilizadores.");
    }
    try {
        const listUsersResult = await auth.listUsers(1000);
        const users = listUsersResult.users.map((userRecord) => ({ uid: userRecord.uid, email: userRecord.email, customClaims: userRecord.customClaims || {} }));
        return users;
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao listar utilizadores:", error);
        throw new https_1.HttpsError("internal", "Erro ao listar utilizadores.");
    }
});
exports.createProviderAdminUser = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem criar utilizadores.");
    }
    const { email, password, providerId } = request.data;
    if (!email || !password || !providerId) {
        throw new https_1.HttpsError("invalid-argument", "Email, password e providerId sao obrigatorios.");
    }
    try {
        const userRecord = await auth.createUser({ email, password });
        await auth.setCustomUserClaims(userRecord.uid, { providerId: providerId });
        return { success: true, uid: userRecord.uid };
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao criar utilizador admin de provedor:", error);
        throw new https_1.HttpsError("internal", "Erro ao criar utilizador.");
    }
});
exports.deleteUser = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    if (!request.auth || !request.auth.token.superAdmin) {
        throw new https_1.HttpsError("permission-denied", "Apenas Super Admins podem apagar utilizadores.");
    }
    const { uid } = request.data;
    if (!uid) {
        throw new https_1.HttpsError("invalid-argument", "O UID do utilizador e obrigatorio.");
    }
    try {
        await auth.deleteUser(uid);
        return { success: true, message: "Utilizador apagado com sucesso." };
    }
    catch (error) {
        firebase_functions_1.logger.error("Erro ao apagar utilizador:", error);
        throw new https_1.HttpsError("internal", "Erro ao apagar utilizador.");
    }
});
// ==========================================================
// Funções de Placeholder (Restantes)
// ==========================================================
const placeholderFunction = (name) => (0, https_1.onCall)({ region: "southamerica-east1" }, () => {
    firebase_functions_1.logger.info(`Funcao ${name} foi chamada, mas esta sem implementacao.`);
    throw new https_1.HttpsError("unimplemented", `A funcao ${name} ainda nao foi restaurada.`);
});
exports.setProviderAdmin = placeholderFunction("setProviderAdmin");
exports.getClientData = placeholderFunction("getClientData");
exports.getConsumptionData = placeholderFunction("getConsumptionData");
exports.sendNotificationToTopic = placeholderFunction("sendNotificationToTopic");
exports.testConnection = placeholderFunction("testConnection");
// ==========================================================
// Funções de Notificação (Completas)
// ==========================================================
// ==========================================================
// CORREÇÃO 2: Alterado o tipo de 'response' para 'any' para resolver o erro de import
// ==========================================================
exports.sendTestNotification = (0, https_1.onRequest)({ region: "southamerica-east1" }, async (request, response) => {
    var _a;
    const cpf = request.query.cpf;
    if (!cpf) {
        response.status(400).send("Erro: Forneca um CPF.");
        return;
    }
    try {
        const userDoc = await db.collection("clientes").doc(String(cpf)).get();
        if (!userDoc.exists) {
            response.status(404).send(`Erro: Cliente com CPF ${cpf} nao encontrado.`);
            return;
        }
        const fcmToken = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
        if (!fcmToken) {
            response.status(404).send(`Erro: Cliente ${cpf} nao tem token.`);
            return;
        }
        const message = { token: fcmToken, notification: { title: "Teste de Notificacao! 🚀", body: "Se voce recebeu esta mensagem, a configuracao esta a funcionar!" } };
        await messaging.send(message);
        response.status(200).send(`Sucesso! Notificacao enviada para ${cpf}`);
    }
    catch (error) {
        response.status(500).send(`Erro ao enviar notificacao: ${error}`);
    }
});
exports.sendBroadcastNotification = (0, https_1.onCall)({ region: "southamerica-east1" }, async (request) => {
    var _a;
    firebase_functions_1.logger.info("--- DEBUG: sendBroadcastNotification INICIADA ---");
    firebase_functions_1.logger.info("--- DEBUG: Auth do Utilizador:", (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid);
    firebase_functions_1.logger.info("--- DEBUG: Dados recebidos:", request.data);
    if (!request.auth) {
        firebase_functions_1.logger.error("--- DEBUG: FALHA - Utilizador não autenticado.");
        throw new https_1.HttpsError("unauthenticated", "A funcao so pode ser chamada por um utilizador autenticado.");
    }
    const { title, body } = request.data;
    const { providerId: providerIdFromToken, superAdmin } = request.auth.token;
    if (!title || !body) {
        firebase_functions_1.logger.error("--- DEBUG: FALHA - Título ou corpo da mensagem em falta.");
        throw new https_1.HttpsError("invalid-argument", "A funcao precisa dos campos 'title' e 'body'.");
    }
    try {
        firebase_functions_1.logger.info("--- DEBUG: Passo 1 - A construir a query do Firestore.");
        let query = db.collection("clientes");
        if (!superAdmin && providerIdFromToken) {
            firebase_functions_1.logger.info(`--- DEBUG: A filtrar por providerId: ${providerIdFromToken}`);
            query = query.where("providerId", "==", providerIdFromToken);
        }
        const snapshot = await query.get();
        firebase_functions_1.logger.info(`--- DEBUG: Passo 2 - Query executada. ${snapshot.size} documentos encontrados.`);
        if (snapshot.empty) {
            firebase_functions_1.logger.warn("--- DEBUG: Nenhum cliente encontrado. A encerrar de forma limpa.");
            return { success: false, message: "Nenhum cliente encontrado para notificar." };
        }
        const allTokens = snapshot.docs.map((doc) => doc.data().fcmToken).filter(Boolean);
        firebase_functions_1.logger.info(`--- DEBUG: Passo 3 - Mapeamento concluído. ${allTokens.length} tokens válidos encontrados.`);
        if (allTokens.length === 0) {
            firebase_functions_1.logger.warn("--- DEBUG: Nenhum token válido na base de dados. A encerrar de forma limpa.");
            return { success: false, message: "Nenhum cliente com token de notificação válido." };
        }
        firebase_functions_1.logger.info(`--- DEBUG: Passo 4 - A preparar o envio de ${allTokens.length} tokens em lotes de 500.`);
        const messageChunks = [];
        for (let i = 0; i < allTokens.length; i += 500) {
            const chunk = allTokens.slice(i, i + 500);
            const message = {
                notification: { title, body },
                tokens: chunk,
            };
            messageChunks.push(messaging.sendMulticast(message));
        }
        firebase_functions_1.logger.info(`--- DEBUG: Passo 5 - A aguardar o envio de ${messageChunks.length} lote(s) (Promise.all).`);
        const responses = await Promise.all(messageChunks);
        firebase_functions_1.logger.info("--- DEBUG: Passo 6 - Todos os lotes foram processados. A agregar os resultados.");
        let successCount = 0;
        let failureCount = 0;
        responses.forEach((response) => {
            successCount += response.successCount;
            failureCount += response.failureCount;
        });
        firebase_functions_1.logger.info(`--- DEBUG: SUCESSO FINAL - Sucessos: ${successCount}, Falhas: ${failureCount}`);
        return { success: true, message: `Notificações enviadas para ${successCount} clientes. Falhas: ${failureCount}.` };
    }
    catch (error) {
        firebase_functions_1.logger.error("--- DEBUG: ERRO INESPERADO NO BLOCO CATCH PRINCIPAL ---", error);
        throw new https_1.HttpsError("internal", "Ocorreu um erro interno ao processar as notificações.");
    }
});
//# sourceMappingURL=index.js.map