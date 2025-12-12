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
exports.handleUpdateProviderConfigRequest = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const auth_1 = require("firebase-admin/auth");
const logger = __importStar(require("firebase-functions/logger"));
// Inicialização do Firebase Admin
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const auth = (0, auth_1.getAuth)();
// --- 1. PADRÕES DE AUTORIDADE DO SISTEMA ---
// Estes valores garantem que NUNCA falte uma cor ou configuração.
const DEFAULT_PROVIDER_CONFIG = {
    // Cores Padrão (Visual)
    themeColor: '#673AB7', // Roxo Principal
    secondaryColor: '#9575CD', // Roxo Secundário
    textColor: '#FFFFFF', // Texto Global
    invoiceColor: '#10B981', // Verde (Fatura)
    actionColor: '#E11D48', // Vermelho (Ações/Botões)
    cardColor: '#F8F8F8', // Fundo Cards
    cardTextColor: '#333333', // Texto Cards
    // Configurações Funcionais
    logoUrl: '',
    loginQuote: 'Bem-vindo ao App do Assinante',
    termsOfUse: '',
    features: {
        consumption: true,
        support: true,
        invoices: true
    },
    menuConfig: {
        order: ['invoices', 'support', 'contract'],
        items: {}
    },
    integrations: {
        appName: '',
        apiToken: ''
    },
    socialNetworks: {}
};
// Helper para resposta padronizada
const writeResponse = (ref, payload, requesterUid) => {
    const responseData = Object.assign(Object.assign({}, payload), { requesterUid: requesterUid || null, completedAt: firestore_1.FieldValue.serverTimestamp() });
    return ref.set(responseData);
};
// --- 2. FUNÇÃO DE ATUALIZAÇÃO INTELIGENTE ---
// Detecta existência, Cria se necessário, Atualiza se existir.
exports.handleUpdateProviderConfigRequest = (0, firestore_2.onDocumentCreated)({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const requestId = event.params.requestId;
    const requestData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!requestData || requestData.type !== 'UPDATE_PROVIDER_CONFIG') {
        return null;
    }
    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = (_b = requestData.payload) === null || _b === void 0 ? void 0 : _b.requesterUid;
    const providerId = (_c = requestData.payload) === null || _c === void 0 ? void 0 : _c.providerId;
    const incomingConfig = ((_d = requestData.payload) === null || _d === void 0 ? void 0 : _d.config) || {};
    try {
        if (!providerId || !requesterUid) {
            throw new Error("ProviderID e RequesterUID são obrigatórios.");
        }
        // Validação de Permissões
        const user = await auth.getUser(requesterUid);
        const isSuperAdmin = ((_e = user.customClaims) === null || _e === void 0 ? void 0 : _e.superAdmin) === true;
        const isOwner = ((_f = user.customClaims) === null || _f === void 0 ? void 0 : _f.providerId) === providerId;
        if (!isSuperAdmin && !isOwner) {
            throw new Error("Permissão negada.");
        }
        const providerRef = db.collection("provedores").doc(providerId);
        const providerDoc = await providerRef.get();
        let finalDataToSave = {};
        if (!providerDoc.exists) {
            logger.info(`[CRIANDO] Provedor ${providerId} não existe. Inicializando com Defaults.`);
            // LÓGICA DE AUTO-CRIAÇÃO
            // Mistura os defaults com o que veio do painel
            finalDataToSave = Object.assign(Object.assign(Object.assign({}, DEFAULT_PROVIDER_CONFIG), incomingConfig), { name: incomingConfig.name || `Provedor ${providerId}`, createdAt: firestore_1.FieldValue.serverTimestamp(), active: true, 
                // Garante que as cores críticas existam na raiz
                actionColor: incomingConfig.actionColor || DEFAULT_PROVIDER_CONFIG.actionColor, invoiceColor: incomingConfig.invoiceColor || DEFAULT_PROVIDER_CONFIG.invoiceColor });
        }
        else {
            logger.info(`[ATUALIZANDO] Provedor ${providerId} existe. Aplicando alterações.`);
            // LÓGICA DE ATUALIZAÇÃO
            finalDataToSave = Object.assign(Object.assign({}, incomingConfig), { updatedAt: firestore_1.FieldValue.serverTimestamp() });
        }
        // --- ESTRATÉGIA ESPELHO (MIRRORING) ---
        // Garante compatibilidade total salvando na raiz E no objeto config
        // 1. Remove recursão se já existir
        if (finalDataToSave.config)
            delete finalDataToSave.config;
        // 2. Cria o espelho
        finalDataToSave.config = Object.assign({}, finalDataToSave);
        // 3. Grava no Firestore
        await providerRef.set(finalDataToSave, { merge: true });
        await writeResponse(responseRef, {
            result: {
                success: true,
                message: providerDoc.exists ? "Configurações atualizadas." : "Provedor criado com sucesso.",
                providerId
            }
        }, requesterUid);
    }
    catch (error) {
        logger.error(`Erro em UPDATE_PROVIDER_CONFIG ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});
//# sourceMappingURL=index.js.map