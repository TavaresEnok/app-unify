import Redis from "ioredis";

export const redis = process.env.REDIS_URL ? new Redis(process.env.REDIS_URL, {
  maxRetriesPerRequest: 1,
  connectTimeout: 2000,
  retryStrategy: (attempt) => Math.min(attempt * 200, 2000),
}) : null;
redis?.on("error", () => undefined);

export const cacheRedis = process.env.REDIS_CACHE_URL ? new Redis(process.env.REDIS_CACHE_URL, {
  maxRetriesPerRequest: 1, connectTimeout: 2000,
}) : null;
cacheRedis?.on("error", () => undefined);
