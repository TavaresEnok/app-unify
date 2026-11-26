'use strict';
if (!process.env.UV_THREADPOOL_SIZE) process.env.UV_THREADPOOL_SIZE = '16';
const { Worker, DelayedError } = require('bullmq');
const http = require('http');
const fs = require('fs');
const { getQueue, connection, jobId, queueName } = require('./lib/jobs');
const { sanitize } = require('./lib/sanitize-client');
const { validateSyncPage, syncParameters, hasNextSyncPage } = require('./lib/sync-page');
const { shouldPrune, withPageRetry, nextDelay, syncFailureLog } = require('./lib/sync-guard');
const { pool, ensureCoreTables, ensureSgpCredentials, callSgpApi, formatSgpUrl } = require('./index');
const queue = getQueue();
const timezone = 'America/Fortaleza';
function localDay(date = new Date()) { return new Intl.DateTimeFormat('en-CA', { timeZone: timezone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(date); }

const {
    ensureClientCache,
    bulkUpsertClientsAndSegments,
    pruneStaleAfterFullSync,
    runRetentionCleanup,
} = require('./lib/client-cache');

let messagingClient = null;
let messagingInitDone = false;
function getMessaging() {
    if (messagingInitDone) return messagingClient;
    messagingInitDone = true;
    const credsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (credsPath && !fs.existsSync(credsPath)) {
        console.warn(`[WARN] Credencial FCM ausente em ${credsPath}; push de cobrança ficará desativado.`);
        return null;
    }
    if (!credsPath && !process.env.GOOGLE_CLOUD_PROJECT) return null;
    try {
        const admin = require('firebase-admin');
        if (!admin.apps.length) {
            admin.initializeApp({ projectId: process.env.GOOGLE_CLOUD_PROJECT || undefined });
        }
        messagingClient = admin.messaging();
    } catch (error) {
        console.warn('[WARN] FCM indisponível no worker:', error.message);
    }
    return messagingClient;
}

function targetDateIso(offsetDays) {
    return localDay(new Date(Date.now() + offsetDays * 86400000));
}

function dayOfMonthFromIso(isoDate) {
    return Number(String(isoDate || '').slice(8, 10)) || 0;
}

function billingPushMessage(offsetDays, formattedValue) {
    if (offsetDays > 1) {
        return {
            title: `Fatura vence em ${offsetDays} dias`,
            body: `Sua fatura de R$ ${formattedValue} vence em ${offsetDays} dias. Pague via PIX ou boleto pelo app.`,
        };
    }
    if (offsetDays === 1) {
        return {
            title: 'Fatura vencendo amanhã',
            body: `Sua fatura de R$ ${formattedValue} vence amanhã. Toque para pagar com PIX ou boleto.`,
        };
    }
    if (offsetDays === 0) {
        return {
            title: 'Sua fatura vence hoje',
            body: `Evite bloqueio: sua fatura de R$ ${formattedValue} vence hoje. Pague em segundos pelo app.`,
        };
    }
    const overdue = Math.abs(offsetDays);
    return {
        title: `Fatura em aberto há ${overdue} ${overdue === 1 ? 'dia' : 'dias'}`,
        body: `Identificamos uma fatura de R$ ${formattedValue} em aberto. Regularize ou faça promessa de pagamento no app.`,
    };
}

async function seedReminders(job) {
    const { day, offset = 0 } = job.data;
    const tableCheck = await pool.query(`
      SELECT
        to_regclass('public.subscriber_devices') IS NOT NULL AS has_devices,
        to_regclass('public.subscriber_segments') IS NOT NULL AS has_segments,
        to_regclass('public.billing_push_rules') IS NOT NULL AS has_rules
    `).catch(() => ({ rows: [{ has_devices: false, has_segments: false, has_rules: false }] }));
    const flags = tableCheck.rows[0] || {};
    if (!flags.has_devices) return { scanned: 0, queued: 0, source: 'pg-empty' };

    const rulesByProvider = new Map();
    if (flags.has_rules) {
        const rulesRes = await pool.query(`SELECT provider_id, enabled, days_before, days_after FROM billing_push_rules`);
        for (const r of rulesRes.rows) {
            rulesByProvider.set(r.provider_id, {
                enabled: r.enabled !== false,
                daysBefore: Array.isArray(r.days_before) ? r.days_before.map(Number).filter(n => Number.isInteger(n) && n >= 0 && n <= 15) : [1],
                daysAfter: Array.isArray(r.days_after) ? r.days_after.map(Number).filter(n => Number.isInteger(n) && n >= 1 && n <= 30) : [],
            });
        }
    }

    // Um job por assinante com TODOS os aparelhos dele (até 10 mais recentes):
    // famílias com dois celulares recebem nos dois.
    const pgPage = await pool.query(
        flags.has_segments
            ? `SELECT d.provider_id, d.cpfcnpj,
                      (ARRAY_AGG(d.fcm_token ORDER BY d.updated_at DESC))[1:10] AS fcm_tokens,
                      COALESCE(
                        (SELECT ARRAY_AGG(DISTINCT s.due_day) FROM subscriber_segments s
                          WHERE s.provider_id = d.provider_id AND s.cpfcnpj = d.cpfcnpj AND s.due_day > 0),
                        ARRAY[]::smallint[]
                      ) AS due_days
                 FROM subscriber_devices d
                WHERE d.fcm_token <> ''
                  AND d.provider_id IN (SELECT id FROM providers WHERE NOT (COALESCE(data, '{}'::jsonb) ? 'deletedAt'))
                GROUP BY d.provider_id, d.cpfcnpj
                ORDER BY d.provider_id, d.cpfcnpj
                LIMIT 500 OFFSET $1`
            : `SELECT provider_id, cpfcnpj,
                      (ARRAY_AGG(fcm_token ORDER BY updated_at DESC))[1:10] AS fcm_tokens,
                      ARRAY[]::smallint[] AS due_days
                 FROM subscriber_devices
                WHERE fcm_token <> ''
                  AND provider_id IN (SELECT id FROM providers WHERE NOT (COALESCE(data, '{}'::jsonb) ? 'deletedAt'))
                GROUP BY provider_id, cpfcnpj
                ORDER BY provider_id, cpfcnpj
                LIMIT 500 OFFSET $1`,
        [offset],
    );

    const jobs = [];
    let filteredOut = 0;
    for (const row of pgPage.rows) {
        const rule = rulesByProvider.get(row.provider_id) || { enabled: true, daysBefore: [1], daysAfter: [] };
        if (!rule.enabled) { filteredOut++; continue; }
        const offsets = [
            ...rule.daysBefore.map(d => d),
            ...rule.daysAfter.map(d => -d),
        ];
        if (!offsets.length) { filteredOut++; continue; }

        const dueDays = Array.isArray(row.due_days) ? row.due_days.map(Number).filter(d => d >= 1 && d <= 31) : [];
        if (dueDays.length > 0) {
            const targetDays = new Set(offsets.map(off => dayOfMonthFromIso(targetDateIso(off))));
            const matchesWindow = dueDays.some(dd =>
                targetDays.has(dd) ||
                targetDays.has(dd === 31 ? 1 : dd + 1) ||
                targetDays.has(dd === 1 ? 31 : dd - 1)
            );
            if (!matchesWindow) { filteredOut++; continue; }
        }

        jobs.push({
            name: 'invoice-reminder',
            data: {
                cpf: row.cpfcnpj,
                fcmTokens: Array.isArray(row.fcm_tokens) ? row.fcm_tokens.filter(Boolean) : [],
                providerId: row.provider_id,
                day,
                offsets,
                source: 'pg',
            },
            opts: { jobId: jobId('reminder', day, row.provider_id, row.cpfcnpj), priority: 10 },
        });
    }
    if (jobs.length) await queue.addBulk(jobs);
    if (pgPage.rows.length === 500) {
        await queue.add('seed-reminders', { day, offset: offset + 500 }, { jobId: jobId('seed-pg', day, offset + 500), priority: 1 });
    }
    return { scanned: pgPage.rows.length, queued: jobs.length, filteredByDueDay: filteredOut, source: 'pg' };
}

async function invoiceReminder(job) {
    if (job.data.day !== localDay()) return { skipped: 'expired' };
    const providerId = job.data.providerId;
    const cpf = String(job.data.cpf || '').replace(/\D/g, '');
    // Jobs antigos na fila ainda trazem um só fcmToken.
    const fcmTokens = [...new Set((Array.isArray(job.data.fcmTokens) ? job.data.fcmTokens : [job.data.fcmToken])
        .map(token => String(token || '')).filter(Boolean))];
    const offsets = Array.isArray(job.data.offsets) && job.data.offsets.length
        ? job.data.offsets.map(Number).filter(Number.isFinite)
        : [1];

    if (!cpf || !fcmTokens.length) return { skipped: 'missing-cpf' };
    const fcm = getMessaging();
    if (!fcm) return { skipped: 'fcm-disabled' };

    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials({ providerId });
    const result = await callSgpApi({ ...sgpParams, url: formatSgpUrl(sgpBaseUrl, '/api/ura/titulos/'), cpfcnpj: cpf, status: 'abertos' });
    const titulos = Array.isArray(result?.titulos) ? result.titulos : [];
    let matchedInvoice = null;
    let matchedOffset = null;
    for (const off of offsets) {
        const target = targetDateIso(off);
        const found = titulos.find(item => String(item.dataVencimento || '').slice(0, 10) === target);
        if (found) {
            matchedInvoice = found;
            matchedOffset = off;
            break;
        }
    }
    if (!matchedInvoice) return { skipped: 'no-due-invoice' };
    const formattedValue = Number(matchedInvoice.valor || 0).toFixed(2).replace('.', ',');
    const copy = billingPushMessage(matchedOffset, formattedValue);
    // Idempotência por aparelho: um reenvio do job não repete push já entregue.
    const delivered = new Set(Array.isArray(job.data.deliveredTokens) ? job.data.deliveredTokens : []);
    let sent = 0; let invalid = 0; let lastError = null;
    for (const fcmToken of fcmTokens) {
        if (delivered.has(fcmToken)) continue;
        try {
            await fcm.send({
                token: fcmToken,
                notification: { title: copy.title, body: copy.body },
                data: { route: '/faturas' },
                android: { collapseKey: `invoice-${targetDateIso(matchedOffset)}` },
            });
            sent++;
            delivered.add(fcmToken);
        } catch (error) {
            if (['messaging/invalid-registration-token', 'messaging/registration-token-not-registered'].includes(error.code)) {
                await pool.query('DELETE FROM subscriber_devices WHERE provider_id = $1 AND fcm_token = $2', [providerId, fcmToken]).catch(() => undefined);
                invalid++;
                continue;
            }
            lastError = error;
        }
    }
    if (lastError) {
        await job.updateData({ ...job.data, deliveredTokens: [...delivered] }).catch(() => undefined);
        throw lastError;
    }
    if (!sent && invalid) return { skipped: 'invalid-token', invalid };
    return { sent: sent > 0, devices: sent, invalid, offsetDays: matchedOffset };
}

async function syncClients(job) {
    try { return await syncClientsOnce(job); }
    catch (error) { console.error(syncFailureLog(job, error)); throw error; }
}

async function syncClientsOnce(job) {
    const { providerId } = job.data;
    const { sgpParams, sgpBaseUrl } = await ensureSgpCredentials({ providerId });
    await Promise.all([ensureClientCache(pool), ensureCoreTables()]);
    let { page = 1, count = 0, fetched = 0, erpTotal = null, lastPageHash, syncStartedAt = new Date().toISOString() } = job.data;

    while (true) {
        const result = await withPageRetry(() => callSgpApi({ ...sgpParams, url: formatSgpUrl(sgpBaseUrl, '/api/ura/clientes/'), ...syncParameters(page) }));
        const clients = result?.clientes;
        const reportedTotal = Number(result?.paginacao?.total);
        if (Number.isFinite(reportedTotal) && reportedTotal > 0) erpTotal = reportedTotal;
        lastPageHash = validateSyncPage(page, clients, lastPageHash);

        const rows = [];
        for (const raw of clients) {
            const client = sanitize(raw);
            const cpf = String(client.cpfcnpj || client.cpfCnpj || '').replace(/\D/g, '');
            if (!cpf) continue;
            const nome = client.nome || client.razaoSocial || 'Cliente';
            const clientId = String(client.id ?? client.clienteId ?? cpf);
            rows.push({ clientId, nome, cpf, contratos: client.contratos || [] });
        }

        await bulkUpsertClientsAndSegments(pool, providerId, rows);

        count += rows.length;
        fetched += clients.length;
        page++;
        await job.updateData({ providerId, page, count, fetched, erpTotal, lastPageHash, syncStartedAt });
        await job.updateProgress({ count, page: page - 1 });
        if (!hasNextSyncPage(page, clients.length, result.paginacao)) break;
        await new Promise(resolve => setTimeout(resolve, 250));
    }

    let pruned = { prunedClients: 0, prunedSegments: 0 };
    const previous = await pool.query(`SELECT data->'syncedClientCount' AS synced FROM providers WHERE id = $1`, [providerId]).catch(() => ({ rows: [] }));
    const previousCount = Number(previous.rows[0]?.synced);
    const decision = shouldPrune({ count, fetched, erpTotal, previousCount });
    if (decision.prune) {
        pruned = await pruneStaleAfterFullSync(pool, providerId, syncStartedAt);
    } else {
        console.warn(JSON.stringify({ event: 'sync.prune-skipped', providerId, reason: decision.reason, count, fetched, erpTotal, previousCount: Number.isFinite(previousCount) ? previousCount : null }));
    }

    // Só registra a contagem como "boa" quando a sincronização foi completa.
    const summary = decision.prune || !(previousCount > 0)
        ? { syncedClientCount: count, lastClientSyncAt: new Date().toISOString() }
        : { lastClientSyncAt: new Date().toISOString(), lastClientSyncPartial: true };
    await pool.query(
        `UPDATE providers
            SET data = (data - 'lastClientSyncPartial') || $2::jsonb,
                updated_at = NOW()
          WHERE id = $1`,
        [providerId, JSON.stringify(summary)],
    ).catch(() => undefined);

    return { count, fetched, erpTotal, pruneSkipped: decision.prune ? undefined : decision.reason, ...pruned };
}

async function scheduleAllProviderSyncs() {
    await ensureCoreTables();
    const res = await pool.query(`SELECT id, active FROM providers WHERE active = TRUE`);
    let queued = 0;
    for (const doc of res.rows) {
        const providerId = doc.id;
        try {
            await ensureSgpCredentials({ providerId });
        } catch {
            continue;
        }
        const id = jobId('sync', providerId);
        const previous = await queue.getJob(id);
        if (previous && ['completed', 'failed'].includes(await previous.getState())) {
            await previous.remove();
        }
        await queue.add(
            'sync-clients',
            { providerId, page: 1, count: 0, syncStartedAt: new Date().toISOString() },
            { jobId: id, delay: queued * 45_000, priority: 5 },
        );
        queued++;
    }
    return { queued };
}

async function retentionCleanup() {
    await ensureCoreTables();
    const res = await pool.query(`SELECT id FROM providers`);
    const activeProviderIds = res.rows.map(r => r.id);
    return runRetentionCleanup(pool, {
        deviceMaxAgeDays: Number(process.env.RETENTION_DEVICES_DAYS || 120),
        campaignMaxAgeDays: Number(process.env.RETENTION_CAMPAIGNS_DAYS || 180),
        activeProviderIds,
    });
}

const handlers = {
    'seed-reminders': seedReminders,
    'invoice-reminder': invoiceReminder,
    'sync-clients': syncClients,
    'schedule-all-syncs': scheduleAllProviderSyncs,
    'retention-cleanup': retentionCleanup,
};
const worker = new Worker(queueName, async (job, token) => {
    if (!handlers[job.name]) throw new Error('Tipo de trabalho desconhecido.');
    try { return await handlers[job.name](job); }
    catch (error) {
        if (error.status === 503) {
            const delayedCount = Number(job.data?.delayedCount || 0);
            const delay = nextDelay(delayedCount);
            if (delay !== null) {
                await job.updateData({ ...job.data, delayedCount: delayedCount + 1 });
                await job.moveToDelayed(Date.now() + delay, token);
                throw new DelayedError();
            }
            console.error(JSON.stringify({ event: 'job.delay-limit', name: job.name, id: job.id, delayedCount }));
        }
        throw error;
    }
}, { connection: connection(), concurrency: 6, limiter: { max: 40, duration: 1000 }, lockDuration: 180000 });
worker.on('failed', (job, error) => console.error(JSON.stringify({ event: 'job.failed', name: job?.name, id: job?.id, error: error.message })));
worker.on('error', error => console.error('[worker]', error.message));

async function schedule() {
    await queue.upsertJobScheduler('daily-invoice-reminders', { pattern: '0 9 * * *', tz: timezone }, {
        name: 'seed-daily', data: {}, opts: { attempts: 5 },
    });
    await queue.upsertJobScheduler('biweekly-client-sync', { pattern: '0 3 * * 2,5', tz: timezone }, {
        name: 'schedule-all-syncs', data: {}, opts: { attempts: 3 },
    });
    await queue.upsertJobScheduler('weekly-retention-cleanup', { pattern: '0 4 * * 0', tz: timezone }, {
        name: 'retention-cleanup', data: {}, opts: { attempts: 3 },
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
