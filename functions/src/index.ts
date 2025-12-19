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

// --- 4. FUNÇÃO PARA OBTER DADOS DO DASHBOARD (SuperAdmin) ---
export const handleGetDashboardDataRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'GET_DASHBOARD_DATA') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;

    try {
        if (!requesterUid) {
            throw new Error("RequesterUID é obrigatório.");
        }

        // Validação de Permissões - Apenas SuperAdmin
        const user = await auth.getUser(requesterUid);
        const isSuperAdmin = user.customClaims?.superAdmin === true;

        if (!isSuperAdmin) {
            throw new Error("Permissão negada. Apenas SuperAdmin.");
        }

        // Buscar estatísticas
        const providersSnapshot = await db.collection("provedores").get();
        const providerCount = providersSnapshot.size;

        // Contar clientes (usuários com providerId)
        let clientCount = 0;
        const usersSnapshot = await db.collection("users").get();
        usersSnapshot.forEach(doc => {
            const userData = doc.data();
            if (userData.providerId) {
                clientCount++;
            }
        });

        // Contar tickets abertos
        let openTicketsCount = 0;
        const ticketsSnapshot = await db.collection("tickets")
            .where("status", "in", ["Aberto", "Em Andamento"])
            .get();
        openTicketsCount = ticketsSnapshot.size;

        // Notificações nas últimas 24h
        const oneDayAgo = new Date();
        oneDayAgo.setDate(oneDayAgo.getDate() - 1);
        const notificationsSnapshot = await db.collection("notifications")
            .where("createdAt", ">=", oneDayAgo)
            .get();
        const notificationCount = notificationsSnapshot.size;

        // Dados do gráfico (clientes por provedor)
        const chartData: { name: string; clientes: number }[] = [];
        for (const providerDoc of providersSnapshot.docs) {
            const providerData = providerDoc.data();
            const providerName = providerData.name || providerDoc.id;
            const clientsInProvider = usersSnapshot.docs.filter(
                u => u.data().providerId === providerDoc.id
            ).length;
            chartData.push({ name: providerName, clientes: clientsInProvider });
        }

        // Tickets recentes
        const recentTicketsSnapshot = await db.collection("tickets")
            .orderBy("updatedAt", "desc")
            .limit(5)
            .get();

        const recentTickets = recentTicketsSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                subject: data.subject || "Sem assunto",
                providerName: data.providerName || "Desconhecido",
                status: data.status || "Aberto",
                updatedAt: data.updatedAt
            };
        });

        logger.info(`Dashboard data: ${providerCount} provedores, ${clientCount} clientes`);

        await writeResponse(responseRef, {
            result: {
                stats: {
                    providerCount,
                    clientCount,
                    notificationCount,
                    openTicketsCount
                },
                chartData,
                recentTickets
            }
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em GET_DASHBOARD_DATA ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});

// --- 5. FUNÇÃO PARA DELETAR PROVEDOR ---
export const handleDeleteProviderRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'DELETE_PROVIDER') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;
    const providerId = requestData.payload?.providerId;

    try {
        if (!providerId || !requesterUid) {
            throw new Error("ProviderID e RequesterUID são obrigatórios.");
        }

        // Validação de Permissões - Apenas SuperAdmin pode deletar
        const user = await auth.getUser(requesterUid);
        const isSuperAdmin = user.customClaims?.superAdmin === true;

        if (!isSuperAdmin) {
            throw new Error("Permissão negada. Apenas SuperAdmin pode deletar provedores.");
        }

        const providerRef = db.collection("provedores").doc(providerId);
        const providerDoc = await providerRef.get();

        if (!providerDoc.exists) {
            throw new Error(`Provedor '${providerId}' não encontrado.`);
        }

        const providerName = providerDoc.data()?.name || providerId;

        // 1. Deletar usuários associados (opcional - mas importante para limpeza)
        const usersSnapshot = await db.collection("users")
            .where("providerId", "==", providerId)
            .get();

        const batch = db.batch();
        usersSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        // 2. Deletar tickets associados
        const ticketsSnapshot = await db.collection("tickets")
            .where("providerId", "==", providerId)
            .get();

        ticketsSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        // 3. Deletar o provedor
        batch.delete(providerRef);

        await batch.commit();

        logger.info(`Provedor '${providerName}' (${providerId}) deletado. Removidos ${usersSnapshot.size} usuários e ${ticketsSnapshot.size} tickets.`);

        await writeResponse(responseRef, {
            result: {
                success: true,
                message: `Provedor '${providerName}' apagado com sucesso! (${usersSnapshot.size} usuários e ${ticketsSnapshot.size} tickets removidos)`,
                providerId
            }
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em DELETE_PROVIDER ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});
