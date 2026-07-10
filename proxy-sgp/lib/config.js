function positiveInteger(value, fallback) {
    const parsed = Number(value);
    return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

function commaSeparated(value, fallback) {
    return (value || fallback.join(','))
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean);
}

function loadConfig(env = process.env) {
    const enableDevMock = env.ENABLE_DEV_CPF_MOCK === 'true';
    return Object.freeze({
        port: positiveInteger(env.PORT, 3002),
        redisUrl: env.REDIS_URL || 'redis://localhost:6379',
        databaseUrl: env.DATABASE_URL || 'postgresql://sgp_user:sgp_password@localhost:5432/sgp_cache',
        proxySecret: env.PROXY_SECRET || env.PROXY_SECRET_KEY || '',
        allowedOrigins: commaSeparated(env.ALLOWED_ORIGINS, [
            'http://localhost:5173',
            'http://localhost:8031',
            'http://127.0.0.1:8031',
        ]),
        rateLimitWindowMs: positiveInteger(env.RATE_LIMIT_WINDOW_MS, 60_000),
        rateLimitMaxRequests: positiveInteger(env.RATE_LIMIT_MAX_REQUESTS, 60),
        cacheTtlMs: positiveInteger(env.CACHE_TTL_MS, 300_000),
        devCpf: enableDevMock ? (env.DEV_MOCK_CPF || '').replace(/\D/g, '') : '',
    });
}

module.exports = { commaSeparated, loadConfig, positiveInteger };
