const cron = require('node-cron');
const express = require('express');
const crypto = require('crypto');

// Comparação em tempo constante que não vaza se o segredo está (des)configurado.
function secretMatches(provided) {
    const expected = process.env.PROXY_SECRET || process.env.PROXY_SECRET_KEY;
    if (!expected || typeof provided !== 'string' || provided.length === 0) return false;
    const a = Buffer.from(provided);
    const b = Buffer.from(expected);
    return a.length === b.length && crypto.timingSafeEqual(a, b);
}

module.exports = function(app, { admin, firestoreDb, ensureSgpCredentials, callSgpApi }) {
    // Roda todos os dias às 09:00 (hora do servidor)
    cron.schedule('0 9 * * *', async () => {
    console.log('[CRON] Iniciando rotina diária de Push Notifications para Faturas a Vencer...');

    try {
        // 1. Busca todos os clientes que possuem fcmToken no Firestore
        const snapshot = await firestoreDb.collection('clientes').where('fcmToken', '!=', null).get();
        if (snapshot.empty) {
            console.log('[CRON] Nenhum cliente com fcmToken encontrado.');
            return;
        }

        const clientesDocs = snapshot.docs;
        console.log(`[CRON] Total de clientes com fcmToken: ${clientesDocs.length}`);

        // 2. Agrupa por providerId para cachear as credenciais e evitar chamadas repetidas
        const providerCache = {};
        const amanha = new Date();
        amanha.setDate(amanha.getDate() + 1);
        const amanhaISO = amanha.toISOString().split('T')[0]; // Formato YYYY-MM-DD

        for (const doc of clientesDocs) {
            const data = doc.data();
            const providerId = data.providerId;
            const fcmToken = data.fcmToken;
            const cpfCnpj = doc.id;

            if (!providerId || !fcmToken) continue;

            try {
                // Preenche o cache de credenciais do provider
                if (!providerCache[providerId]) {
                    const creds = await ensureSgpCredentials({ providerId });
                    providerCache[providerId] = creds;
                }
                const { sgpParams, sgpBaseUrl } = providerCache[providerId];

                // 3. Busca faturas do cliente no SGP
                // Formatando a URL exatamente como o proxy faz
                const urlTitulos = (sgpBaseUrl.endsWith('/') ? sgpBaseUrl.slice(0, -1) : sgpBaseUrl) + '/api/ura/titulos/';
                
                const responseSgp = await callSgpApi({
                    url: urlTitulos,
                    app: sgpParams.app,
                    token: sgpParams.token,
                    cpfcnpj: cpfCnpj,
                    status: 'abertos'
                });

                if (responseSgp && responseSgp.titulos && Array.isArray(responseSgp.titulos)) {
                    // Verifica se existe alguma fatura aberta que vence amanhã.
                    // O SGP usa o campo `dataVencimento` (parseável por Date); o
                    // filtro antigo usava `t.vencimento`/`t.situacao` (campos
                    // inexistentes), então nunca disparava.
                    const faturasAmanha = responseSgp.titulos.filter(t => {
                        if (!t.dataVencimento) return false;
                        const d = new Date(t.dataVencimento);
                        return !isNaN(d.getTime()) && d.toISOString().split('T')[0] === amanhaISO;
                    });

                    if (faturasAmanha.length > 0) {
                        const valorFormatado = parseFloat(faturasAmanha[0].valor || 0).toFixed(2).replace('.', ',');
                        
                        console.log(`[CRON] Fatura de ${cpfCnpj} vence amanhã. Enviando Push...`);

                        // 4. Envia a notificação Push via FCM
                        const payload = {
                            notification: {
                                title: '💰 Fatura Vencendo Amanhã!',
                                body: `Sua fatura de R$ ${valorFormatado} vence amanhã. Clique aqui para copiar o PIX.`,
                            },
                            data: {
                                route: '/faturas'
                            },
                            token: fcmToken,
                        };

                        try {
                            const responseFCM = await admin.messaging().send(payload);
                            console.log(`[CRON] Push enviado com sucesso para ${cpfCnpj}. ID: ${responseFCM}`);
                        } catch (fcmError) {
                            console.error(`[CRON] Erro ao enviar Push para ${cpfCnpj}:`, fcmError.message);
                            // Se o erro for de token inválido/desinstalado, poderíamos deletá-lo do Firestore
                            if (fcmError.code === 'messaging/invalid-registration-token' || fcmError.code === 'messaging/registration-token-not-registered') {
                                console.log(`[CRON] Removendo token inválido do cliente ${cpfCnpj}.`);
                                await doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
                            }
                        }
                    }
                }
            } catch (err) {
                console.error(`[CRON] Erro ao processar cliente ${cpfCnpj}:`, err.message);
            }

            // Delay de 300ms entre as requisições SGP para não derrubar a API do provedor
            await new Promise(r => setTimeout(r, 300));
        }

        console.log('[CRON] Rotina diária de Push Notifications finalizada com sucesso.');
    } catch (error) {
        console.error('[CRON] Erro fatal na rotina:', error);
    }
    });

    // Endpoint opcional para testar manualmente via requisição secreta (somente dev/admin)
    const router = express.Router();
    router.post('/trigger-cron', (req, res) => {
        // Fail-closed: se o segredo não está configurado, o endpoint fica
        // indisponível em vez de aceitar qualquer requisição (fail-open).
        if (!process.env.PROXY_SECRET && !process.env.PROXY_SECRET_KEY) {
            return res.status(503).json({ error: 'Endpoint indisponível: segredo não configurado.' });
        }
        if (!secretMatches(req.body?.secret)) {
            return res.status(403).json({ error: 'Acesso negado.' });
        }
        
        console.log('[CRON] Gatilho manual disparado!');
        // Não usamos await para não prender a requisição HTTP
        cron.getTasks().forEach(t => t.now());
        
        res.json({ message: 'Rotina iniciada em background.' });
    });

    app.use('/admin-cron', router);
};
