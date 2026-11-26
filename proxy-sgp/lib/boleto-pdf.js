'use strict';
// Boleto em PDF de fatura em aberto (IXC: get_boleto). Faturas SGP já trazem o
// link do boleto, então aqui respondem "não disponível". Cota por assinante
// (o IXC gera/registra o arquivo a cada emissão) e cache curto por
// assinante+contrato+fatura para toques repetidos não chegarem ao ERP.
// Nunca registra CPF, nome ou o PDF.
const { createHash } = require('crypto');
const { createRateLimiter } = require('./rate-limiter');
const { publicError } = require('./proxy-errors');
const { ixcUrl } = require('./ixc-gateway');

const CACHE_TTL_MS = 10 * 60 * 1000;
const LOCAL_CACHE_MAX = 32;
const hash = value => createHash('sha256').update(value).digest('hex').slice(0, 40);
const isPdf = value => Buffer.isBuffer(value) && value.length > 8 && value.subarray(0, 5).toString('latin1') === '%PDF-';

function createBoletoPdf({ getStateRedis, getCacheRedis, perHour = 20, ensureSgpCredentials, requireSgpClientCredentials, upstream, ixcGatewayFor, limits, now = Date.now }) {
    const local = new Map();
    const limiter = createRateLimiter({ getRedis: getStateRedis, windowMs: 60 * 60 * 1000, maxRequests: perHour, now,
        getClientId: req => `boleto:${hash(`${req.body?.providerId || ''}:${req.user?.uid || ''}:${String(req.body?.cpfCnpj || '').replace(/\D/g, '')}`)}`,
    });

    async function cached(key, load) {
        const hit = local.get(key);
        if (hit && hit.expires > now()) return hit.pdf;
        const redis = getCacheRedis();
        const shared = redis ? await redis.getBuffer(key).catch(() => null) : null;
        if (isPdf(shared)) return shared;
        const pdf = await load();
        if (local.size >= LOCAL_CACHE_MAX) local.delete(local.keys().next().value);
        local.set(key, { pdf, expires: now() + CACHE_TTL_MS });
        if (redis) await redis.set(key, pdf, 'PX', CACHE_TTL_MS).catch(() => undefined);
        return pdf;
    }

    async function handler(req, res) {
        const fail = (status, code, message) => res.status(status).json({ error: { code, message } });
        const cpfCnpj = String(req.body.cpfCnpj || '').replace(/\D/g, '');
        const faturaId = String(req.body.faturaId ?? '').trim();
        if (!/^\d{1,12}$/.test(faturaId)) return fail(400, 'invalid-argument', 'Fatura inválida.');
        const contrato = req.body.contratoId == null || req.body.contratoId === '' ? null : String(req.body.contratoId);
        if (contrato !== null && !/^\d{1,12}$/.test(contrato)) return fail(400, 'invalid-argument', 'Contrato inválido.');
        try {
            const credentials = await ensureSgpCredentials(req.body);
            if (!requireSgpClientCredentials(credentials.sgpParams, res)) return;
            if (credentials.erp !== 'ixc') return fail(404, 'boleto-unavailable', 'Boleto não disponível.');
            const key = `boleto:pdf:${hash(`${req.body.providerId}:${cpfCnpj}:${contrato || ''}:${faturaId}`)}`;
            const pdf = await cached(key, () => upstream.execute({ providerId: req.body.providerId, url: ixcUrl(credentials.sgpBaseUrl, 'get_boleto'),
                body: { faturaId }, ttl: 0, limits },
            async () => (await ixcGatewayFor(credentials).boletoPdf({ cpfcnpj: cpfCnpj, faturaId, ...(contrato ? { contrato } : {}) })).pdf));
            res.set({ 'Content-Type': 'application/pdf', 'Content-Length': String(pdf.length), 'Cache-Control': 'private, no-store',
                'Content-Disposition': `inline; filename="boleto-${faturaId}.pdf"`, 'X-Content-Type-Options': 'nosniff' });
            return res.status(200).end(pdf);
        } catch (error) {
            if (error?.code && error.publicMessage) return fail(error.status || 404, error.code, error.publicMessage);
            console.error('Erro na rota /invoice/boleto-pdf:', String(error?.message || '').slice(0, 120));
            const mapped = publicError(error, 'Não foi possível gerar o boleto agora.');
            return mapped.status === 404
                ? fail(502, 'boleto-failed', 'Não foi possível gerar o boleto agora.')
                : fail(mapped.status, 'boleto-failed', mapped.message);
        }
    }

    return { limiter, handler };
}

module.exports = { createBoletoPdf };
