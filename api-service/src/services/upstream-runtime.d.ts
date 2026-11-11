export function createUpstream(options: { getRedis: () => unknown; getCacheRedis?: () => unknown; maxPerProvider?: number; maxPerHost?: number }): {
  execute<T>(input: { providerId: string; url: string; body: unknown; ttl?: number; mutate?: boolean }, operation: () => Promise<T>): Promise<T>;
};
export function readTtl(url: string): number;
