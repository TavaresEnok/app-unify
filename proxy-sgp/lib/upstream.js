'use strict';
const { createHash, randomUUID } = require('crypto');
const hash = value => createHash('sha256').update(value).digest('hex');
const ACQUIRE = `
local t=redis.call('TIME'); local now=t[1]*1000+math.floor(t[2]/1000)
for i=1,2 do redis.call('ZREMRANGEBYSCORE',KEYS[i],'-inf',now) end
if redis.call('ZCARD',KEYS[1]) >= tonumber(ARGV[2]) or redis.call('ZCARD',KEYS[2]) >= tonumber(ARGV[3]) then return 0 end
for i=1,2 do redis.call('ZADD',KEYS[i],now+90000,ARGV[1]);redis.call('PEXPIRE',KEYS[i],95000) end
return 1`;
// Vagas esgotadas mesmo após a espera: mensagem amigável que chega ao app.
const BUSY_MESSAGE = 'Muitos acessos agora. Tente novamente em alguns segundos.';
function busyError(message) {
    return Object.assign(new Error(message), { status: 503, code: 'erp-busy', busy: true, publicMessage: BUSY_MESSAGE });
}
const positiveLimit = (value, fallback) => (Number.isInteger(value) && value > 0 ? value : fallback);
function createUpstream({ getRedis, getCacheRedis, maxPerProvider = 4, maxPerHost = 8, slotWaitMs = 0, slotPollMs = 100 }) {
    const pending = new Map();
    // `limits` permite um teto maior por chamada (ex.: IXC aceita mais consultas
    // paralelas que o SGP); os dois tetos — provedor e host — continuam valendo.
    async function execute({ providerId, url, body, ttl = 0, mutate = false, limits = {} }, operation) {
        const providerCap = positiveLimit(limits.maxPerProvider, maxPerProvider);
        const hostCap = positiveLimit(limits.maxPerHost, maxPerHost);
        const redis = getRedis();
        if (!redis) throw Object.assign(new Error('Controle de consultas indisponível.'), { status: 503 });
        const cacheRedis = getCacheRedis?.() || redis;
        const host = hash(new URL(url).host);
        const provider = hash(providerId || host);
        const key = `sgp:read:${provider}:${hash(url + JSON.stringify(body))}`;
        const versionKey = `sgp:version:${provider}`;
        const version = await redis.get(versionKey) || '0';
        const cacheKey = `${key}:${version}`;
        if (ttl) {
            const cached = await cacheRedis.get(cacheKey).catch(() => null);
            if (cached) return JSON.parse(cached);
            if (pending.has(cacheKey)) return pending.get(cacheKey);
        }
        const run = async () => {
            const openKey = `sgp:open:${host}`;
            if (await redis.exists(openKey)) throw Object.assign(new Error('SGP temporariamente indisponível.'), { status: 503 });
            const token = randomUUID();
            const keys = [`sgp:slots:provider:${provider}`, `sgp:slots:host:${host}`];
            // Com todas as vagas ocupadas, espera um pouco por uma vaga em vez
            // de devolver 503 na hora (picos curtos de vários assinantes).
            const deadline = Date.now() + Math.max(0, slotWaitMs);
            while (!await redis.eval(ACQUIRE, 2, ...keys, token, providerCap, hostCap)) {
                if (Date.now() + slotPollMs > deadline) throw busyError('SGP ocupado. Tente novamente em instantes.');
                await new Promise(resolve => setTimeout(resolve, slotPollMs));
            }
            try {
                const value = await operation();
                await redis.del(`sgp:fail:${host}`).catch(() => undefined);
                if (ttl && Buffer.byteLength(JSON.stringify(value)) <= 512000) await cacheRedis.set(cacheKey, JSON.stringify(value), 'PX', ttl).catch(() => undefined);
                // Uma mutação bem-sucedida invalida leituras em ambos os serviços.
                if (mutate) await redis.set(versionKey, randomUUID(), 'EX', 3600).catch(() => undefined);
                return value;
            } catch (error) {
                // Erros de validação/autorização não indicam indisponibilidade do SGP.
                // Falha de DNS local também não: abrir o disjuntor derrubaria o
                // provedor inteiro por um soluço do resolvedor.
                if (!error.dnsFailure && (!error.response || error.response.status >= 500)) {
                    const failures = await redis.incr(`sgp:fail:${host}`);
                    await redis.expire(`sgp:fail:${host}`, 30);
                    if (failures >= 5) await redis.set(openKey, '1', 'EX', 20);
                }
                throw error;
            } finally { await redis.zrem(keys[0], token).catch(() => undefined); await redis.zrem(keys[1], token).catch(() => undefined); }
        };
        if (!ttl) return run();
        // Trava compartilhada evita que duas réplicas consultem a mesma leitura.
        const lock = `${cacheKey}:lock`;
        const lockToken = randomUUID();
        const promise = (async () => {
            if (!await redis.set(lock, lockToken, 'PX', 70000, 'NX')) {
                for (let attempt = 0; attempt < 100; attempt++) {
                    await new Promise(resolve => setTimeout(resolve, 100));
                    const cached = await cacheRedis.get(cacheKey).catch(() => null);
                    if (cached) return JSON.parse(cached);
                    if (!await redis.exists(lock)) break;
                }
                throw busyError('Consulta em andamento. Tente novamente.');
            }
            try { return await run(); }
            finally { await redis.eval("if redis.call('GET',KEYS[1])==ARGV[1] then return redis.call('DEL',KEYS[1]) end return 0", 1, lock, lockToken).catch(() => undefined); }
        })();
        pending.set(cacheKey, promise);
        try { return await promise; } finally { pending.delete(cacheKey); }
    }
    return { execute };
}
function readTtl(url) {
    const path = new URL(url).pathname;
    if (/liberacaopromessa|wifi\/update/.test(path)) return 0;
    if (/titulos|extratouso|consultacliente|verificaacesso/.test(path)) return 30000;
    if (/\/onu\/|wifi\/list/.test(path)) return 10000;
    return 0;
}
module.exports = { createUpstream, readTtl, ACQUIRE, BUSY_MESSAGE };
