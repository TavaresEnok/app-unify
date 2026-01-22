import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getAuth } from "firebase-admin/auth";
import * as logger from "firebase-functions/logger";
import * as os from "os";
import * as path from "path";
import * as fs from "fs";
import { spawn } from "child_process";
import * as https from "https";

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

// --- 6. FUNÇÃO PARA ENVIAR PUSH NOTIFICATION ---
// Envia notificação para um cliente específico ou para todos
export const handleSendPushNotificationRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'SEND_PUSH_NOTIFICATION') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;
    const payload = requestData.payload || {};

    try {
        if (!requesterUid) {
            throw new Error("RequesterUID é obrigatório.");
        }

        // Validação de Permissões
        const user = await auth.getUser(requesterUid);
        const isSuperAdmin = user.customClaims?.superAdmin === true;
        const userProviderId = user.customClaims?.providerId;

        if (!isSuperAdmin && !userProviderId) {
            throw new Error("Permissão negada.");
        }

        const providerId = payload.providerId || userProviderId;
        const { title, body, category, targetAll, targetCpf, route } = payload;

        if (!title || !body) {
            throw new Error("Título e mensagem são obrigatórios.");
        }

        // Import messaging dynamically
        const { getMessaging } = await import("firebase-admin/messaging");
        const messaging = getMessaging();

        let successCount = 0;
        let failureCount = 0;

        if (targetCpf) {
            // Enviar para cliente específico
            const clientDoc = await db.collection('clientes').doc(targetCpf).get();
            if (clientDoc.exists) {
                const fcmToken = clientDoc.data()?.fcmToken;
                if (fcmToken) {
                    try {
                        await messaging.send({
                            token: fcmToken,
                            notification: { title, body },
                            data: { route: route || '', category: category || 'info' },
                            android: {
                                priority: 'high',
                                notification: {
                                    channelId: 'high_importance_channel',
                                    priority: 'high' as const,
                                }
                            }
                        });
                        successCount = 1;
                    } catch (e: any) {
                        logger.warn(`Falha ao enviar para ${targetCpf}: ${e.message}`);
                        failureCount = 1;
                    }
                } else {
                    failureCount = 1;
                }
            } else {
                throw new Error(`Cliente ${targetCpf} não encontrado.`);
            }
        } else if (targetAll) {
            // Enviar para todos os clientes do provedor via topic
            try {
                await messaging.send({
                    topic: `provider_${providerId}`,
                    notification: { title, body },
                    data: { route: route || '', category: category || 'info' },
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'high_importance_channel',
                            priority: 'high' as const,
                        }
                    }
                });
                successCount = 1;
                logger.info(`Notificação enviada para topic provider_${providerId}`);
            } catch (e: any) {
                logger.error(`Erro ao enviar para topic: ${e.message}`);
                failureCount = 1;
            }
        } else {
            // Buscar todos os clientes com token FCM
            const clientsSnapshot = await db.collection('clientes')
                .where('providerId', '==', providerId)
                .get();

            const tokens: string[] = [];
            clientsSnapshot.forEach(doc => {
                const token = doc.data().fcmToken;
                if (token) tokens.push(token);
            });

            if (tokens.length > 0) {
                const response = await messaging.sendEachForMulticast({
                    tokens,
                    notification: { title, body },
                    data: { route: route || '', category: category || 'info' },
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'high_importance_channel',
                            priority: 'high' as const,
                        }
                    }
                });
                successCount = response.successCount;
                failureCount = response.failureCount;
            }
        }

        // Salvar notificação no histórico
        await db.collection('notifications').add({
            providerId,
            title,
            body,
            category: category || 'info',
            targetAll: !!targetAll,
            targetCpf: targetCpf || null,
            successCount,
            failureCount,
            sentBy: requesterUid,
            createdAt: FieldValue.serverTimestamp()
        });

        logger.info(`Notificação enviada: ${successCount} sucesso, ${failureCount} falhas`);

        await writeResponse(responseRef, {
            result: {
                success: true,
                message: `Notificação enviada! ${successCount} entregue(s), ${failureCount} falha(s).`,
                successCount,
                failureCount
            }
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em SEND_PUSH_NOTIFICATION ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});

// TEMPORARY: Fix Vibe Provider Document
import { onRequest } from "firebase-functions/v2/https";

export const fixVibeProvider = onRequest(async (req, res) => {
    try {
        logger.info("🔧 Fixing Vibe provider document...");

        // 1. Copy document
        const sourceDoc = await db.collection('provedores').doc('3kdrQFcCkRga234iB1YX').get();
        if (!sourceDoc.exists) {
            throw new Error('Source document not found');
        }

        const data = sourceDoc.data();
        await db.collection('provedores').doc('vibe').set(data!);
        logger.info("✅ Document copied to provedores/vibe");

        // 2. Update user token
        const user = await auth.getUserByEmail('vibe@gmail.com');
        await auth.setCustomUserClaims(user.uid, { providerId: 'vibe' });
        logger.info("✅ Token updated for vibe@gmail.com");

        res.json({
            success: true,
            message: "Provider fixed! Logout and login again."
        });
    } catch (error: any) {
        logger.error("❌ Error:", error);
        res.status(500).json({ error: error.message });
    }
});

// --- 8. FUNÇÃO PARA DASHBOARD DO PROVEDOR (ESPECÍFICO) ---
export const handleGetProviderDashboardDataRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'GET_PROVIDER_DASHBOARD_DATA') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;
    const providerId = requestData.payload?.providerId;

    try {
        if (!providerId || !requesterUid) throw new Error("ProviderID e RequesterUID são obrigatórios.");

        // 1. Contar Clientes (simulado ou real se tiver subcoleção)
        // Tentamos ler da subcoleção 'clientes' (padronizada)
        let clientCount = 0;
        const clientsSnap = await db.collection(`provedores/${providerId}/clientes`).get();
        clientCount = clientsSnap.size;

        // Se tiver 0, tenta ler de subcoleção antiga 'users' se existir
        if (clientCount === 0) {
            const usersSnap = await db.collection(`provedores/${providerId}/users`).get();
            clientCount += usersSnap.size;
        }

        // 2. Contar Tickets
        let openTicketsCount = 0;
        // Tickets podem estar na raiz com providerId ou em subcoleção
        const ticketsSnap = await db.collection('tickets')
            .where('providerId', '==', providerId)
            .where('status', 'in', ['Aberto', 'Em Andamento'])
            .get();
        openTicketsCount = ticketsSnap.size;

        // 3. Tickets Recentes
        const recentTicketsSnap = await db.collection('tickets')
            .where('providerId', '==', providerId)
            .orderBy('updatedAt', 'desc')
            .limit(5)
            .get();

        const recentTickets = recentTicketsSnap.docs.map(doc => {
            const d = doc.data();
            return {
                id: doc.id,
                subject: d.subject || 'Sem assunto',
                status: d.status || 'Aberto',
                updatedAt: d.updatedAt
            };
        });

        await writeResponse(responseRef, {
            result: {
                stats: {
                    totalClients: clientCount,
                    openTicketsCount: openTicketsCount
                },
                recentTickets
            }
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em GET_PROVIDER_DASHBOARD_DATA ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});

// --- 9. FUNÇÃO PROXY SGP (REAL SYNC) ---
// Trata sincronização e listagem de clientes conectando-se ao SGP Externo
export const handleSgpApiProxyRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1",
    timeoutSeconds: 300, // Aumentado para suportar sincronização demorada
    memory: "512MiB"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'SGP_API_PROXY') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;
    const payload = requestData.payload || {};
    const { action, providerId, params } = payload;

    try {
        if (!providerId) throw new Error("ProviderID obrigatório.");

        // 1. Buscar Credenciais do SGP no Provedor
        const providerDoc = await db.collection('provedores').doc(providerId).get();
        if (!providerDoc.exists) throw new Error("Provedor não encontrado.");

        const pData = providerDoc.data() || {};
        const config = {
            url: pData.integrations?.sgpBaseUrl || pData.details?.systemUrl || pData.sgpBaseUrl,
            token: pData.integrations?.apiToken || pData.details?.apiToken || pData.apiToken,
            app: pData.integrations?.appName || pData.details?.appName || pData.appName || 'APP-PROVEDOR'
        };

        if (!config.url || !config.token) {
            throw new Error("Configurações do SGP (URL/Token) incompletas no cadastro do provedor.");
        }

        // callSgp removido - agora usamos o proxy local

        if (action === 'sync') {
            // Lógica de Sincronização VIA PROXY LOCAL (para bypass de IP)
            logger.info(`[SYNC] Iniciando sincronização VIA PROXY para ${providerId}...`);
            await writeResponse(responseRef, { status: "running", message: "Sincronizando via proxy..." }, requesterUid);

            const clientsRef = db.collection(`provedores/${providerId}/clientes`);
            const PROXY_URL = 'http://168.194.13.18:3005';
            const PROXY_SECRET = 'CHAVE_SECRETA_MUITO_FORTE_12345';

            try {
                // 1. Chamar o proxy para sincronizar com SGP (proxy tem acesso liberado)
                // Usar AbortController para timeout de 5 minutos (tempo suficiente para ~200 páginas)
                logger.info(`[SYNC] Chamando proxy /sync-clients (timeout 5min)...`);
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), 5 * 60 * 1000); // 5 minutos

                const syncResponse = await fetch(`${PROXY_URL}/sync-clients`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        secret: PROXY_SECRET,
                        providerId: providerId,
                        sgpBaseUrl: config.url,
                        params: {
                            token: config.token,
                            app: config.app
                        }
                    }),
                    signal: controller.signal
                });

                clearTimeout(timeoutId);

                if (!syncResponse.ok && syncResponse.status !== 409) {
                    const errorText = await syncResponse.text();
                    throw new Error(`Proxy sync failed: ${syncResponse.status} - ${errorText}`);
                }

                const syncResult: any = await syncResponse.json();
                logger.info(`[SYNC] Proxy sincronizou ${syncResult.count || 0} clientes com SGP.`);

                // 2. Buscar clientes do cache do proxy (em lotes)
                let totalSynced = 0;
                let offset = 0;
                const limit = 100;

                while (true) {
                    logger.info(`[SYNC] Buscando do proxy: offset=${offset}, limit=${limit}...`);
                    const getResponse = await fetch(`${PROXY_URL}/get-cached-clients`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            secret: PROXY_SECRET,
                            providerId: providerId,
                            params: { limit, offset }
                        })
                    });

                    if (!getResponse.ok) {
                        throw new Error(`Proxy get-cached-clients failed: ${getResponse.status}`);
                    }

                    const getData: any = await getResponse.json();
                    const clientes = getData.clientes || [];

                    if (clientes.length === 0) break;

                    // Batch Write no Firestore
                    const batches = [];
                    let currentBatch = db.batch();
                    let count = 0;

                    for (const client of clientes) {
                        const docId = client.cpfcnpj ? client.cpfcnpj.replace(/[^0-9]/g, '') : null;
                        if (!docId) continue;

                        const clientDocRef = clientsRef.doc(docId);
                        currentBatch.set(clientDocRef, {
                            ...client,
                            id: client.id,
                            nome: client.nome,
                            cpfcnpj: client.cpfcnpj,
                            contratos: client.contratos || [],
                            updatedAt: FieldValue.serverTimestamp(),
                            providerId: providerId
                        }, { merge: true });

                        count++;
                        if (count >= 400) {
                            batches.push(currentBatch.commit());
                            currentBatch = db.batch();
                            count = 0;
                        }
                    }
                    if (count > 0) batches.push(currentBatch.commit());

                    await Promise.all(batches);
                    totalSynced += clientes.length;

                    if (clientes.length < limit) break;
                    offset += limit;
                }

                logger.info(`[SYNC] Total Sincronizado no Firestore: ${totalSynced}`);

                await writeResponse(responseRef, {
                    result: {
                        count: totalSynced,
                        message: `Sincronização via proxy concluída! ${totalSynced} clientes atualizados.`
                    }
                }, requesterUid);

            } catch (error: any) {
                logger.error(`[SYNC] Erro na sincronização via proxy: ${error.message}`);
                await writeResponse(responseRef, { status: "error", message: `Erro: ${error.message}` }, requesterUid);
            }

        } else if (action === 'get') {
            // Listagem de clientes do Firestore (Inalterado, mas agora com dados reais)
            const limit = params?.limit || 25;
            const offset = params?.offset || 0;
            const searchTerm = params?.searchTerm || '';

            let query: FirebaseFirestore.Query = db.collection(`provedores/${providerId}/clientes`);

            if (searchTerm) {
                query = query.where('nome', '>=', searchTerm).where('nome', '<=', searchTerm + '\uf8ff');
            }

            query = query.orderBy('nome');

            // Aviso: Offset em queries grandes é caro, mas ok para MVP Admin
            if (offset > 0) query = query.offset(offset);
            query = query.limit(limit);

            const snapshot = await query.get();

            // Contagem total
            const countQuery = db.collection(`provedores/${providerId}/clientes`);
            const countSnap = await countQuery.count().get();
            const total = countSnap.data().count;

            const clientes = snapshot.docs.map(doc => doc.data());

            // Fallback se Firestore vazio: Tenta buscar 1 página do SGP em tempo real (opcional)
            // Se o usuário nunca clicou em sync, vai estar vazio.
            if (total === 0 && !searchTerm) {
                logger.info("Cache vazio. Tentando sync rápido da primeira página...");
                // (Opcional - mas pode demorar a resposta. Melhor deixar o usuário clicar em sync explícito)
            }

            await writeResponse(responseRef, {
                result: {
                    clientes,
                    paginacao: { total, limit, offset }
                }
            }, requesterUid);
        } else {
            throw new Error(`Ação '${action}' não suportada.`);
        }

    } catch (error: any) {
        logger.error(`Erro em SGP_API_PROXY ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});

// --- 10. FUNÇÃO PARA LISTAR TICKETS (PROVEDOR) ---
export const handleGetProviderTicketsRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'GET_PROVIDER_TICKETS') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;
    const providerId = requestData.payload?.providerId;

    try {
        if (!providerId) throw new Error("ProviderID obrigatório.");

        // Buscar tickets do provedor
        const ticketsSnap = await db.collection('tickets')
            .where('providerId', '==', providerId)
            .orderBy('updatedAt', 'desc')
            .get();

        const tickets = ticketsSnap.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        await writeResponse(responseRef, {
            tickets
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em GET_PROVIDER_TICKETS ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});

import { onCall, HttpsError } from "firebase-functions/v2/https";

// ===========================================
// APK GENERATOR (SUPER ADMIN ONLY)
// ===========================================

export const generateApk = onCall(
    {
        timeoutSeconds: 540, // 9 minutes (Build takes time)
        memory: "256MiB", // Standard memory for spawning process
        region: "southamerica-east1",
    },
    async (request) => {
        // 1. Auth Check
        if (!request.auth || !request.auth.token.superAdmin) {
            throw new HttpsError(
                "permission-denied",
                "Apenas Super Admin pode gerar APKs."
            );
        }

        const { providerId, appName, logoUrl } = request.data;
        if (!providerId || !appName || !logoUrl) {
            throw new HttpsError(
                "invalid-argument",
                "providerId, appName e logoUrl são obrigatórios."
            );
        }

        logger.info(`Starting APK Generation for ${providerId} (${appName})...`);

        // 2. Download Logo to Temp
        const tempFilePath = path.join(os.tmpdir(), `logo_${providerId}_${Date.now()}.png`);

        await new Promise<void>((resolve, reject) => {
            const file = fs.createWriteStream(tempFilePath);
            https.get(logoUrl, (response) => {
                response.pipe(file);
                file.on('finish', () => {
                    file.close();
                    resolve();
                });
            }).on('error', (err) => {
                fs.unlink(tempFilePath, () => { });
                reject(err);
            });
        });

        // 3. Run Python Script
        const scriptPath = "/home/app/painel-provedores-projeto/admin-script/gerar_apk.py";
        const projectRoot = "/home/app/painel-provedores-projeto"; // CWD for script

        return new Promise((resolve, reject) => {
            const pythonProcess = spawn(
                "python3",
                [
                    scriptPath,
                    "--id",
                    providerId,
                    "--nome",
                    appName,
                    "--logo",
                    tempFilePath,
                ],
                { cwd: projectRoot }
            );

            let output = "";
            let errorOutput = "";

            pythonProcess.stdout.on("data", (data) => {
                const str = data.toString();
                output += str;
                logger.info(`[APK Gen]: ${str}`);
            });

            pythonProcess.stderr.on("data", (data) => {
                const str = data.toString();
                errorOutput += str;
                logger.error(`[APK Gen Error]: ${str}`);
            });

            pythonProcess.on("close", (code) => {
                // Cleanup temp logo
                fs.unlink(tempFilePath, () => { });

                if (code === 0) {
                    // Parse output to find final path if needed, or just return success
                    // Extract generated APK path from logs if possible, but for now just return success
                    resolve({
                        success: true,
                        message: "APK Gerado com sucesso!",
                        logs: output
                    });
                } else {
                    reject(new HttpsError("internal", `Falha no script (Exit ${code})`, { logs: output, error: errorOutput }));
                }
            });
        });
    }
);

// ===========================================
// ADMIN USER MANAGEMENT
// ===========================================

export const handleListAdminUsersRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'LIST_ADMIN_USERS') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;

    try {
        if (!requesterUid) throw new Error("RequesterUID obrigatório.");

        // Check Permissions (Super Admin only for full list)
        const user = await auth.getUser(requesterUid);
        const isSuperAdmin = user.customClaims?.superAdmin === true;

        if (!isSuperAdmin) {
            throw new Error("Permissão negada. Apenas Super Admin.");
        }

        // List users (limit 1000 for MVP)
        const listUsersResult = await auth.listUsers(1000);

        const users = listUsersResult.users.map(u => ({
            uid: u.uid,
            email: u.email,
            superAdmin: u.customClaims?.superAdmin === true,
            providerId: u.customClaims?.providerId || null
        }));

        await writeResponse(responseRef, {
            result: { users }
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em LIST_ADMIN_USERS ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});

export const handleDeleteAdminUserRequest = onDocumentCreated({
    document: "function_requests/{requestId}",
    region: "southamerica-east1"
}, async (event) => {
    const requestId = event.params.requestId;
    const requestData = event.data?.data();

    if (!requestData || requestData.type !== 'DELETE_ADMIN_USER') { return null; }

    const responseRef = db.collection('function_responses').doc(requestId);
    const requesterUid = requestData.requesterUid;
    const targetUid = requestData.payload?.uid;

    try {
        if (!requesterUid || !targetUid) throw new Error("Dados incompletos.");

        // Check Permissions
        const user = await auth.getUser(requesterUid);
        if (!user.customClaims?.superAdmin) throw new Error("Permissão negada.");

        if (requesterUid === targetUid) throw new Error("Você não pode se apagar.");

        await auth.deleteUser(targetUid);

        await writeResponse(responseRef, {
            result: { success: true, message: "Usuário apagado." }
        }, requesterUid);

    } catch (error: any) {
        logger.error(`Erro em DELETE_ADMIN_USER ${requestId}:`, error);
        await writeResponse(responseRef, { error: error.message }, requesterUid);
    }
    return null;
});



