'use strict';

// INCR + PEXPIRE no mesmo script Lua: atômico no Redis. Também aplica o TTL
// quando a chave existe sem expiração (PTTL -1), recuperando chaves que
// ficaram presas por uma versão anterior não-atômica.
const INCR_WITH_TTL_SCRIPT = `
local count = redis.call('INCR', KEYS[1])
local ttl = redis.call('PTTL', KEYS[1])
if ttl < 0 then
    redis.call('PEXPIRE', KEYS[1], ARGV[1])
    ttl = tonumber(ARGV[1])
end
return { count, ttl }
`;

const DEFAULT_EXEMPT_PATHS = ['/health', '/ready'];

function createRateLimiter({ getRedis, windowMs, maxRequests, exemptPaths = DEFAULT_EXEMPT_PATHS, now = Date.now }) {
    const fallbackStore = new Map();
    const exempt = new Set(exemptPaths);

    function reject(res, retryAfterMs) {
        const retryAfter = Math.max(1, Math.ceil(retryAfterMs / 1000));
        res.set('Retry-After', retryAfter.toString());
        res.set('X-RateLimit-Limit', maxRequests.toString());
        res.set('X-RateLimit-Remaining', '0');
        return res.status(429).json({
            error: { message: 'Muitas requisições. Tente novamente em alguns segundos.', retryAfter }
        });
    }

    function accept(res, count, next) {
        res.set('X-RateLimit-Limit', maxRequests.toString());
        res.set('X-RateLimit-Remaining', Math.max(0, maxRequests - count).toString());
        return next();
    }

    function hitFallback(clientId) {
        const current = now();
        const entry = fallbackStore.get(clientId);
        if (!entry || current - entry.startTime > windowMs) {
            fallbackStore.set(clientId, { count: 1, startTime: current });
            return { count: 1, ttl: windowMs };
        }
        entry.count++;
        return { count: entry.count, ttl: entry.startTime + windowMs - current };
    }

    async function rateLimiter(req, res, next) {
        if (exempt.has(req.path)) return next();

        const clientId = req.ip || req.headers['x-forwarded-for'] || 'unknown';
        let hit = null;

        const redis = getRedis();
        if (redis) {
            try {
                const [count, ttl] = await redis.eval(INCR_WITH_TTL_SCRIPT, 1, `rl:${clientId}`, windowMs);
                hit = { count: Number(count), ttl: Number(ttl) };
            } catch (err) {
                // Fallback silencioso para in-memory
            }
        }
        if (!hit) hit = hitFallback(clientId);

        if (hit.count > maxRequests) return reject(res, hit.ttl);
        return accept(res, hit.count, next);
    }

    // Remove entradas antigas do fallback in-memory
    rateLimiter.pruneFallback = () => {
        const current = now();
        for (const [clientId, data] of fallbackStore.entries()) {
            if (current - data.startTime > windowMs * 5) {
                fallbackStore.delete(clientId);
            }
        }
    };

    return rateLimiter;
}

module.exports = { createRateLimiter, INCR_WITH_TTL_SCRIPT };
