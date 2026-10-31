import { expect, it, vi } from 'vitest';
vi.mock('./dashboard', () => ({ clearDashboardPrefetch: vi.fn() }));
import { createDashboardController, measuredCount } from './dashboardState';

const deferred = <T>() => {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>(done => { resolve = done; });
  return { promise, resolve };
};
it('distinguishes initial loading, failure, measured zero/empty, refresh and stale with explicit retry', async () => {
  const controller = createDashboardController<object>(true);
  const notified = vi.fn();
  const unsubscribe = controller.subscribe(notified);
  expect(controller.getSnapshot()).toEqual({ status: 'loading' });
  const fail = async () => { throw new Error('synthetic'); };
  await controller.load(fail);
  expect(controller.getSnapshot()).toEqual({ status: 'error', data: undefined });
  const measured = { stats: { clientCount: 0 }, recentTickets: [] };
  await controller.load(async () => measured);
  expect(controller.getSnapshot()).toEqual({ status: 'ready', data: measured });
  const refresh = deferred<object>();
  const loading = controller.load(() => refresh.promise);
  expect(controller.getSnapshot()).toEqual({ status: 'loading', data: measured });
  refresh.resolve(measured); await loading;
  await controller.load(fail);
  expect(controller.getSnapshot()).toEqual({ status: 'stale', data: measured });
  await controller.load(async () => ({ stats: { clientCount: 8 } }));
  expect(controller.getSnapshot().status).toBe('ready');
  expect(notified).toHaveBeenCalled();
  unsubscribe();
});
it('ignores superseded requests and cancelled identity A after tenant B/logout/role revocation', async () => {
  const a = createDashboardController<object>(true);
  const old = deferred<object>();
  const pending = a.load(() => old.promise);
  await a.load(async () => ({ tenant: 'a-new' }));
  old.resolve({ tenant: 'a-old' }); await pending;
  expect(a.getSnapshot().data).toEqual({ tenant: 'a-new' });
  const late = deferred<object>();
  const oldIdentity = a.load(() => late.promise);
  a.cancel();
  const b = createDashboardController<object>(true);
  const denied = createDashboardController<object>(false);
  const request = vi.fn();
  await denied.load(request);
  expect(request).not.toHaveBeenCalled();
  expect(denied.getSnapshot()).toEqual({ status: 'denied' });
  await b.load(async () => ({ tenant: 'b' }));
  late.resolve({ tenant: 'a' }); await oldIdentity;
  expect(b.getSnapshot()).toEqual({ status: 'ready', data: { tenant: 'b' } });
  expect(denied.getSnapshot().data).toBeUndefined();
});
it('never coerces missing or invalid counts to zero, rejects missing response', async () => {
  for (const value of [undefined, null, '', -1, NaN, Infinity, 0.5]) expect(measuredCount(value)).toBe('N/D');
  expect(measuredCount(0)).toBe(0);
  const controller = createDashboardController<unknown>(true);
  await controller.load(async () => undefined);
  expect(controller.getSnapshot().status).toBe('error');
});
