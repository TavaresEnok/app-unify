import { beforeEach, afterEach, expect, it, vi } from 'vitest';
const state = vi.hoisted(() => ({ user: { uid: 'a1', getIdToken: vi.fn().mockResolvedValue('secret-bearer') } }));
vi.mock('@/firebase/config', () => ({ auth: { get currentUser() { return state.user; } } }));
import { PrivateBlob, privateAttachmentPath, privateAttachmentRequest } from './privateAttachments';
beforeEach(() => { vi.stubGlobal('window', { location: { origin: 'http://localhost', hostname: 'localhost' } }); });
afterEach(() => vi.unstubAllGlobals());
it('keeps bearer in header and fetches only canonical opaque resource paths', async () => {
  const fetcher = vi.fn().mockResolvedValue({ ok: true, blob: async () => new Blob(['png'], { type: 'image/png' }) });
  vi.stubGlobal('fetch', fetcher);
  await privateAttachmentRequest(state.user as any, { ticketId: 't1' }, 'up1', new AbortController().signal);
  expect(fetcher.mock.calls[0][0]).toMatch(/\/private\/tickets\/t1\/attachments\/up1$/);
  expect(fetcher.mock.calls[0][0]).not.toContain('secret-bearer');
  expect(fetcher.mock.calls[0][1].headers.Authorization).toBe('Bearer secret-bearer');
  expect(() => privateAttachmentPath({ ticketId: '../other' }, 'id')).toThrow();
});
it('revokes local URL and aborts capability on disposal, including late responses', async () => {
  const create = vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:local');
  const revoke = vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => {});
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, blob: async () => new Blob(['x'], { type: 'application/pdf' }) }));
  const capability = new PrivateBlob();
  await capability.load(state.user as any, { providerId: 'A', resultId: 'r1' }, 'up1');
  capability.dispose(); expect(revoke).toHaveBeenCalledWith('blob:local');
  let resolve!: (value: any) => void;
  vi.stubGlobal('fetch', vi.fn(() => new Promise(r => { resolve = r; })));
  const late = new PrivateBlob(); const task = late.load(state.user as any, { ticketId: 't1' }, 'up1');
  await Promise.resolve(); late.dispose(); resolve({ ok: true, blob: async () => new Blob(['x'], { type: 'image/png' }) });
  await expect(task).rejects.toThrow(); expect(create).toHaveBeenCalledTimes(1);
  create.mockRestore(); revoke.mockRestore();
});
it('rejects active content and a user changed before obtaining a token', async () => {
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, blob: async () => new Blob(['<script/>'], { type: 'text/html' }) }));
  await expect(privateAttachmentRequest(state.user as any, { ticketId: 't1' }, 'id', new AbortController().signal)).rejects.toThrow('inválido');
  await expect(privateAttachmentRequest({ ...state.user } as any, { ticketId: 't1' }, 'id', new AbortController().signal)).rejects.toThrow('Sessão');
});
