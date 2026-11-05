'use strict';
const { Worker, DelayedError } = require('bullmq');
const http = require('http');
const { getQueue, connection, jobId, queueName } = require('./lib/jobs');
const { sanitize } = require('./lib/sanitize-client');
const { validateSyncPage, syncParameters } = require('./lib/sync-page');
const { pool, firestoreDb: db, admin, ensureSgpCredentials, callSgpApi, formatSgpUrl } = require('./index');
const queue = getQueue();
const timezone = 'America/Fortaleza';
function localDay(date = new Date()) { return new Intl.DateTimeFormat('en-CA', { timeZone: timezone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(date); }

async function seedReminders(job) {
    const { day, cursor } = job.data;
    let query = db.collection('clientes').orderBy(admin.firestore.FieldPath.documentId()).limit(500);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    const jobs = page.docs.filter(doc => doc.data().fcmToken && doc.data().providerId).map(doc => ({
        name: 'invoice-reminder', data: { clientId: doc.id, providerId: doc.data().providerId, day },
        opts: { jobId: jobId('reminder', day, doc.data().providerId, doc.id), priority: 10 },
    }));
    if (jobs.length) await queue.addBulk(jobs);
    if (page.size === 500) {
        const next = page.docs[page.docs.length - 1].id;
        await queue.add('seed-reminders', { day, cursor: next }, { jobId: jobId('seed', day, next), priority: 1 });
    }
    return { scanned: page.size, queued: jobs.length };
}

async function invoiceReminder(job) {
    if (job.data.day !== localDay()) return { skipped: 'expired' };
    const client = await db.collection('clientes').doc(job.data.clientId).get();
    const data = client.data();
    if (!data?.fcmToken || data.providerId !== job.data.providerId) return { skipped: 'unregistered' };
    const cpf = String(data.cpfCnpj || '').replace(/\D/g, '');
    if (!cpf) return { skipped: 'missing-cpf' };
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials({ providerId: data.providerId });
    const result = await callSgpApi({ ...sgpParams, url: formatSgpUrl(sgpBaseUrl, '/api/ura/titulos/'), cpfcnpj: cpf, status: 'abertos' });
    const tomorrow = localDay(new Date(Date.now() + 86400000));
    const invoice = result?.titulos?.find(item => String(item.dataVencimento || '').slice(0, 10) === tomorrow);
    if (!invoice) return { skipped: 'no-due-invoice' };
    try {
        await admin.messaging().send({ token: data.fcmToken,
            notification: { title: 'Fatura vencendo amanhã', body: `Sua fatura de R$ ${Number(invoice.valor || 0).toFixed(2).replace('.', ',')} vence amanhã.` },
            data: { route: '/faturas' }, android: { collapseKey: `invoice-${tomorrow}` },
        });
    } catch (error) {
        if (['messaging/invalid-registration-token', 'messaging/registration-token-not-registered'].includes(error.code)) {
            await client.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
            return { skipped: 'invalid-token' };
        }
        throw error;
    }
    return { sent: true };
}

async function syncClients(job) {
    const { providerId } = job.data;
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials({ providerId });
    await require('./lib/client-cache').ensureClientCache(pool);
    let { page = 1, count = 0, lastPageHash } = job.data;
    while (true) {
        const result = await callSgpApi({ ...sgpParams, url: formatSgpUrl(sgpBaseUrl, '/api/ura/clientes/'), ...syncParameters(page) });
        const clients = result?.clientes;
        lastPageHash = validateSyncPage(page, clients, lastPageHash);
        const batch = db.batch();
        for (const raw of clients) {
            const client = sanitize(raw);
            const cpf = String(client.cpfcnpj || client.cpfCnpj || '').replace(/\D/g, '');
            if (!cpf) continue;
            await pool.query('INSERT INTO sgp_clients (provider_id,client_id,nome,cpfcnpj,contratos) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (provider_id,client_id) DO UPDATE SET nome=EXCLUDED.nome,cpfcnpj=EXCLUDED.cpfcnpj,contratos=EXCLUDED.contratos', [providerId, String(client.id ?? client.clienteId ?? cpf), client.nome || client.razaoSocial || 'Cliente', cpf, JSON.stringify(client.contratos || [])]);
            batch.set(db.collection('provedores').doc(providerId).collection('clientes').doc(cpf), {
                ...client, nome: client.nome || client.razaoSocial || 'Cliente', cpfCnpj: cpf, cpfcnpj: cpf, providerId, updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
        await batch.commit();
        count += clients.length;
        page++;
        await job.updateData({ providerId, page, count, lastPageHash });
        await job.updateProgress({ count, page: page - 1 });
        if (clients.length < 100 || (result.paginacao?.total_paginas && page > result.paginacao.total_paginas)) break;
        await new Promise(resolve => setTimeout(resolve, 300));
    }
    return { count };
}

const handlers = { 'seed-reminders': seedReminders, 'invoice-reminder': invoiceReminder, 'sync-clients': syncClients };
const worker = new Worker(queueName, async (job, token) => {
    if (!handlers[job.name]) throw new Error('Tipo de trabalho desconhecido.');
    try { return await handlers[job.name](job); }
    catch (error) {
        if (error.status === 503) {
            await job.moveToDelayed(Date.now() + 1500 + Math.floor(Math.random() * 1000), token);
            throw new DelayedError();
        }
        throw error;
    }
}, { connection: connection(), concurrency: 8, limiter: { max: 40, duration: 1000 }, lockDuration: 120000 });
worker.on('failed', (job, error) => console.error(JSON.stringify({ event: 'job.failed', name: job?.name, id: job?.id, error: error.message })));
worker.on('error', error => console.error('[worker]', error.message));

async function schedule() {
    await queue.upsertJobScheduler('daily-invoice-reminders', { pattern: '0 9 * * *', tz: timezone }, {
        name: 'seed-daily', data: {}, opts: { attempts: 5 },
    });
}
handlers['seed-daily'] = async () => {
    const day = localDay();
    await queue.add('seed-reminders', { day }, { jobId: jobId('seed', day) });
};
schedule().catch(error => { console.error(error); process.exitCode = 1; });
const health = http.createServer(async (_req, res) => {
    try {
        await worker.waitUntilReady();
        const counts = await queue.getJobCounts('waiting', 'active', 'failed', 'delayed');
        res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify({ status: 'ok', jobs: counts }));
    } catch { res.writeHead(503); res.end('{"status":"unavailable"}'); }
});
health.listen(3003);
async function stop() { health.close(); await worker.close(); await queue.close(); await pool.end(); process.exit(0); }
process.on('SIGTERM', stop); process.on('SIGINT', stop);
