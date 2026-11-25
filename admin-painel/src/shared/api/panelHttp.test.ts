import { afterEach, beforeEach, expect, it, vi } from 'vitest';
const state = vi.hoisted(() => ({ user: { uid: 'a', getIdToken: async () => 'synthetic' } as any }));
vi.mock('@/shared/auth/session', () => ({ auth: { get currentUser() { return state.user; } } }));
import { panelRequest, readPanel, resetPanelSession, clearPanelReads } from './panelHttp';
beforeEach(() => { resetPanelSession(); state.user = { uid:'a', getIdToken: async () => 'synthetic' }; vi.stubGlobal('window', { location: { protocol:'https:', hostname:'panel.test', origin:'https://panel.test', port:'' } }); });
afterEach(() => { vi.unstubAllGlobals(); vi.useRealTimers(); });
it('coalesces reads, expires cache, and invalidates after mutations', async () => {
  vi.useFakeTimers();
  const fetcher = vi.fn(async () => new Response(JSON.stringify({ data: [1] }))); vi.stubGlobal('fetch', fetcher);
  await Promise.all(Array.from({length:50},()=>readPanel('/admin/users/page'))); expect(fetcher).toHaveBeenCalledTimes(1);
  await readPanel('/admin/users/page'); expect(fetcher).toHaveBeenCalledTimes(1);
  await vi.advanceTimersByTimeAsync(15_001); await readPanel('/admin/users/page'); expect(fetcher).toHaveBeenCalledTimes(2);
  clearPanelReads(); await readPanel('/admin/users/page'); expect(fetcher).toHaveBeenCalledTimes(3);
});
it('does not deliver another session response or reuse its data', async () => {
  let finish!: (value: Response) => void;
  const fetcher = vi.fn().mockImplementationOnce(() => new Promise<Response>(resolve => { finish = resolve; })).mockImplementation(async () => new Response(JSON.stringify({data:['b']})));
  vi.stubGlobal('fetch', fetcher);
  const pending = readPanel('/data'); const rejected = expect(pending).rejects.toThrow('Sessão alterada'); await Promise.resolve();
  state.user = { uid:'b', getIdToken: async () => 'other' }; resetPanelSession();
  finish(new Response(JSON.stringify({data:['a']}))); await rejected;
  expect(await readPanel('/data')).toEqual({data:['b']}); expect(fetcher).toHaveBeenCalledTimes(2);
});
it('drops cached data and in-flight replies on role changes of the same Firebase user', async () => {
  let finish!: (value: Response) => void;
  vi.stubGlobal('fetch', vi.fn(()=>new Promise<Response>(resolve=>{finish=resolve;})));
  const pending = readPanel('/data'); const rejected = expect(pending).rejects.toThrow('Sessão alterada'); await Promise.resolve();
  resetPanelSession(); finish(new Response(JSON.stringify({data:['private']}))); await rejected;
});
it('never retries commands and does not cache a denied read', async () => {
  const fetcher = vi.fn(async () => new Response(JSON.stringify({error:{message:'Sem acesso'}}),{status:403})); vi.stubGlobal('fetch',fetcher);
  await expect(panelRequest('/config',{method:'PATCH',body:{themeColor:'#fff'}})).rejects.toThrow('Sem acesso'); expect(fetcher).toHaveBeenCalledTimes(1);
  await expect(readPanel('/data')).rejects.toThrow('Sem acesso'); await expect(readPanel('/data')).rejects.toThrow('Sem acesso'); expect(fetcher).toHaveBeenCalledTimes(3);
});
