const cron = require('node-cron');
const express = require('express');

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
                    cpfcnpj: cpfCnpj
                });

                if (responseSgp && responseSgp.titulos && Array.isArray(responseSgp.titulos)) {
                    // Verifica se existe alguma fatura aberta que vence amanhã
                    const faturasAmanha = responseSgp.titulos.filter(t => t.vencimento === amanhaISO && t.situacao === 'ABERTO');

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
        const { secret } = req.body;
        if (secret !== process.env.PROXY_SECRET_KEY && secret !== process.env.PROXY_SECRET) {
            return res.status(403).json({ error: 'Acesso negado.' });
        }
        
        console.log('[CRON] Gatilho manual disparado!');
        // Não usamos await para não prender a requisição HTTP
        cron.getTasks().forEach(t => t.now());
        
        res.json({ message: 'Rotina iniciada em background.' });
    });

    app.use('/admin-cron', router);
};
