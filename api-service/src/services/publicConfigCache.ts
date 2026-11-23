import { BoundedReadCache } from './boundedReadCache';
export const publicConfigCache = new BoundedReadCache<Record<string, unknown> | null>(500, 30_000);
