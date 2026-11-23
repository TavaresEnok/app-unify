import { afterEach, expect, it, vi } from 'vitest';
import { BoundedReadCache } from './boundedReadCache';
afterEach(() => vi.useRealTimers());
it('coalesces bursts, bounds entries, expires from completion and never caches failures', async () => {
  vi.useFakeTimers();
  const cache = new BoundedReadCache<number>(2, 100);
  let resolve!: (value: number) => void;
  const load = vi.fn(() => new Promise<number>(done => { resolve = done; }));
  const burst = Array.from({ length: 100 }, () => cache.get('a', load));
  await vi.advanceTimersByTimeAsync(1000);
  expect(load).toHaveBeenCalledTimes(1);
  resolve(5); expect(await Promise.all(burst)).toEqual(Array(100).fill(5));
  await vi.advanceTimersByTimeAsync(99); expect(await cache.get('a', load)).toBe(5);
  await cache.get('b', async () => 2); await cache.get('c', async () => 3);
  expect(await cache.get('a', async () => 6)).toBe(6);
  await expect(cache.get('error', async () => { throw Error('offline'); })).rejects.toThrow('offline');
  expect(await cache.get('error', async () => 7)).toBe(7);
});
it('invalidation during a read cannot republish its old result', async () => {
  const cache = new BoundedReadCache<number>(2, 1000);
  let resolve!: (value: number) => void;
  const old = cache.get('a', () => new Promise<number>(done => { resolve = done; }));
  await Promise.resolve(); cache.delete('a');
  expect(await cache.get('a', async () => 2)).toBe(2);
  resolve(1); await old;
  expect(await cache.get('a', async () => 3)).toBe(2);
});
