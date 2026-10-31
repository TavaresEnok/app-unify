import { useEffect, useMemo, useSyncExternalStore } from 'react';
import { clearDashboardPrefetch } from './dashboard';

export type DashboardState<T> = { status: 'loading' | 'ready' | 'error' | 'stale' | 'denied'; data?: T };

// One controller per authenticated identity/role/tenant. Late responses cannot
// publish into a new controller, including when the same UID logs in again.
export function createDashboardController<T>(allowed: boolean) {
  let state: DashboardState<T> = { status: allowed ? 'loading' : 'denied' };
  let generation = 0;
  const listeners = new Set<() => void>();
  const publish = (next: DashboardState<T>) => { state = next; listeners.forEach(fn => fn()); };
  return {
    getSnapshot: () => state,
    subscribe: (fn: () => void) => { listeners.add(fn); return () => { listeners.delete(fn); }; },
    cancel: () => { generation++; },
    async load(request: () => Promise<T>) {
      if (!allowed) return;
      const current = ++generation;
      publish({ status: 'loading', data: state.data });
      try {
        const data = await request();
        if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('Invalid dashboard response');
        if (current === generation) publish({ status: 'ready', data });
      } catch {
        if (current === generation) publish({ status: state.data ? 'stale' : 'error', data: state.data });
      }
    },
  };
}

export function useDashboardState<T>(identity: unknown, role: string | null, tenant: string | null,
  allowed: boolean, request: () => Promise<T>) {
  const controller = useMemo(() => createDashboardController<T>(allowed), [identity, role, tenant, allowed]);
  const state = useSyncExternalStore(controller.subscribe, controller.getSnapshot, controller.getSnapshot);
  const reload = () => { clearDashboardPrefetch(); return controller.load(request); };
  useEffect(() => {
    clearDashboardPrefetch();
    void controller.load(request);
    return controller.cancel;
  }, [controller, request]);
  return { ...state, reload };
}

export function measuredCount(value: unknown): number | 'N/D' {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0 ? value : 'N/D';
}
