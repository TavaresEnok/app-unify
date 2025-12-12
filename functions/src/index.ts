import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getAuth } from "firebase-admin/auth";
import * as logger from "firebase-functions/logger";

// Inicialização do Firebase Admin
initializeApp();
const db = getFirestore();
const auth = getAuth();

// --- 1. PADRÕES DE AUTORIDADE DO SISTEMA ---
// Estes valores garantem que NUNCA falte uma cor ou configuração.
const DEFAULT_PROVIDER_CONFIG = {
    // Cores Padrão (Visual)
    themeColor: '#673AB7',       // Roxo Principal
    secondaryColor: '#9575CD',   // Roxo Secundário
    textColor: '#FFFFFF',        // Texto Global
    invoiceColor: '#10B981',     // Verde (Fatura)
    actionColor: '#E11D48',      // Vermelho (Ações/Botões)
    cardColor: '#F8F8F8',        // Fundo Cards
    cardTextColor: '#333333',    // Texto Cards

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
const writeResponse = (ref: FirebaseFirestore.DocumentReference, payload: any, requesterUid?: string) => {
    const responseData = {
        ...payload,
        requesterUid: requesterUid || null,
        completedAt: FieldValue.serverTimestamp()
    };
    return ref.set(responseData);
};

// --- 2. FUNÇÃO DE ATUALIZAÇÃO INTELIGENTE ---
// Detecta existência, Cria se necessário, Atualiza se existir.
export const handleUpdateProviderConfigRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'UPDATE_PROVIDER_CONFIG') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.payload?.requesterUid;
    const providerId = requestData.payload?.providerId;
    const incomingConfig = requestData.payload?.config || {};

    try {
        if (!providerId || !requesterUid) {
            throw new Error("ProviderID e RequesterUID são obrigatórios.");
        }

        // Validação de Permissões
        const user = await auth.getUser(requesterUid);
        const isSuperAdmin = user.customClaims?.superAdmin === true;
        const isOwner = user.customClaims?.providerId === providerId;

        if (!isSuperAdmin && !isOwner) {
            throw new Error("Permissão negada.");
        }

        const providerRef = db.collection("provedores").doc(providerId);
        const providerDoc = await providerRef.get();

        let finalDataToSave: any = {};

        if (!providerDoc.exists) {
            logger.info(`[CRIANDO] Provedor ${providerId} não existe. Inicializando com Defaults.`);

            // LÓGICA DE AUTO-CRIAÇÃO
            // Mistura os defaults com o que veio do painel
            finalDataToSave = {
                ...DEFAULT_PROVIDER_CONFIG,
                ...incomingConfig,
                name: incomingConfig.name || `Provedor ${providerId}`,
                createdAt: FieldValue.serverTimestamp(),
                active: true,
                // Garante que as cores críticas existam na raiz
                actionColor: incomingConfig.actionColor || DEFAULT_PROVIDER_CONFIG.actionColor,
                invoiceColor: incomingConfig.invoiceColor || DEFAULT_PROVIDER_CONFIG.invoiceColor
            };
        } else {
            logger.info(`[ATUALIZANDO] Provedor ${providerId} existe. Aplicando alterações.`);

            // LÓGICA DE ATUALIZAÇÃO
            finalDataToSave = {
                ...incomingConfig,
                updatedAt: FieldValue.serverTimestamp()
            };
        }

        // --- ESTRATÉGIA ESPELHO (MIRRORING) ---
        // Garante compatibilidade total salvando na raiz E no objeto config

        // 1. Remove recursão se já existir
        if (finalDataToSave.config) delete finalDataToSave.config;

        // 2. Cria o espelho
        finalDataToSave.config = { ...finalDataToSave };

        // 3. Grava no Firestore
        await providerRef.set(finalDataToSave, { merge: true });

        await writeResponse(responseRef, {
            result: {
                success: true,
                message: providerDoc.exists ? "Configurações atualizadas." : "Provedor criado com sucesso.",
                providerId
            }
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em UPDATE_PROVIDER_CONFIG ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});

// --- 3. FUNÇÃO PARA ATUALIZAR DETALHES DO PROVEDOR (usado pelo EditProviderDialog) ---
export const handleUpdateProviderDetailsRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'UPDATE_PROVIDER_DETAILS') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;
    const providerId = requestData.payload?.providerId;
    const details = requestData.payload?.details || {};

    try {
        if (!providerId || !requesterUid) {
            throw new Error("ProviderID e RequesterUID são obrigatórios.");
        }

        // Validação de Permissões
        const user = await auth.getUser(requesterUid);
        const isSuperAdmin = user.customClaims?.superAdmin === true;
        const isOwner = user.customClaims?.providerId === providerId;

        if (!isSuperAdmin && !isOwner) {
            throw new Error("Permissão negada.");
        }

        const providerRef = db.collection("providers").doc(providerId);

        // Prepara dados para atualização
        const updateData: any = {
            updatedAt: FieldValue.serverTimestamp()
        };

        // Salva nome na raiz
        if (details.name) {
            updateData.name = details.name;
        }

        // Salva apiUrl na raiz (importante para o app!)
        if (details.apiUrl) {
            updateData.apiUrl = details.apiUrl;
        }

        // Salva detalhes no objeto 'details'
        updateData.details = {
            appName: details.appName || '',
            apiToken: details.apiToken || '',
            systemUrl: details.systemUrl || '',
            systemType: details.systemType || '',
            apiUrl: details.apiUrl || '',
            city: details.city || '',
            state: details.state || '',
            hasAndroidApp: details.hasAndroidApp || false,
            hasIosApp: details.hasIosApp || false
        };

        // Também salva no objeto 'integrations' para retrocompatibilidade
        updateData.integrations = {
            appName: details.appName || '',
            apiToken: details.apiToken || '',
            sgpBaseUrl: details.systemUrl || ''
        };

        await providerRef.set(updateData, { merge: true });

        await writeResponse(responseRef, {
            result: {
                success: true,
                message: "Provedor atualizado com sucesso.",
                providerId
            }
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em UPDATE_PROVIDER_DETAILS ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});
