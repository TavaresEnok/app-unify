export function createUpstream(options: { getRedis: () => unknown; getCacheRedis?: () => unknown; maxPerProvider?: number; maxPerHost?: number; slotWaitMs?: number; slotPollMs?: number }): {
  execute<T>(input: { providerId: string; url: string; body: unknown; ttl?: number; mutate?: boolean; limits?: { maxPerProvider?: number; maxPerHost?: number } }, operation: () => Promise<T>): Promise<T>;
};
export function readTtl(url: string): number;
export const BUSY_MESSAGE: string;
