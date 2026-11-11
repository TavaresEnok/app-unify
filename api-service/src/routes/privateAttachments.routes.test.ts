import express from 'express';
import request from 'supertest';
import { beforeEach, expect, it, vi } from 'vitest';

const state = vi.hoisted(() => ({ docs: new Map<string, any>(), objects: new Map<string, any>(),
  claims: new Map<string, any>(), failUpload: false, failCommit: false, authorityDown: false, revoked: false,
  reads: 0, writes: 0, generation: 0, afterDownload: undefined as undefined | (() => void | Promise<void>) }));
function ref(path: string): any {
  const r = { path, collection: (name: string) => ({ doc: (key: string) => ref(`${path}/${name}/${key}`) }),
    get: async () => ({ exists: state.docs.has(path), data: () => structuredClone(state.docs.get(path)), createTime: { toMillis: () => Date.parse('2026-10-31T00:00:01Z') } }) };
  return r;
}
vi.mock('../services/firebaseAdmin', () => ({
  serverTimestamp: () => 'now',
  firebaseAuth: {
    verifyIdToken: async (token: string, revoked: boolean) => {
      expect(revoked).toBe(true);
      if (state.revoked) throw Object.assign(new Error('revoked'), { code: 'auth/id-token-revoked' });
      const identity = identities[token];
      if (!identity) throw Object.assign(new Error('invalid'), { code: 'auth/invalid-id-token' });
      return identity;
    },
    getUser: async (uid: string) => {
      if (state.authorityDown) throw new Error('authority down');
      return { uid, customClaims: state.claims.get(uid) || {} };
    },
  },
  firestore: { collection: (name: string) => ({ doc: (key: string) => ref(`${name}/${key}`) }),
    runTransaction: async (action: any) => {
      const writes: Array<() => void> = [];
      const result = await action({ get: (r: any) => r.get(),
        create: (r: any, d: any) => writes.push(() => { if (state.docs.has(r.path)) throw new Error('exists'); state.docs.set(r.path, d); }),
        set: (r: any, d: any) => writes.push(() => state.docs.set(r.path, d)),
        update: (r: any, d: any) => writes.push(() => state.docs.set(r.path, { ...state.docs.get(r.path), ...d })) });
      if (state.failCommit && writes.some(String)) { // fail only the object commit, not reservation
        if ([...state.objects.keys()].length) throw new Error('commit failed');
      }
      writes.forEach(w => w()); return result;
    } },
  admin: { storage: () => ({ bucket: () => ({ file: (path: string, options?: any) => ({
    save: async (bytes: Buffer, config: any) => {
      state.writes++;
      expect(config.preconditionOpts.ifGenerationMatch).toBe(0);
      expect(config.metadata.metadata.firebaseStorageDownloadTokens).toBeUndefined();
      if (state.failUpload) throw new Error('offline');
      if (state.objects.has(path)) throw Object.assign(new Error('exists'), { code: 412 });
      state.objects.set(path, { bytes: Buffer.from(bytes), size: bytes.length, contentType: config.metadata.contentType,
        metadata: config.metadata.metadata, generation: String(++state.generation) });
    },
    getMetadata: async () => {
      const value = state.objects.get(path);
      if (!value || (options?.generation && options.generation !== value.generation)) throw new Error('missing generation');
      return [value];
    },
    download: async () => {
      state.reads++;
      const value = state.objects.get(path);
      if (!value || options?.generation !== value.generation) throw new Error('missing');
      const bytes = Buffer.from(value.bytes); await state.afterDownload?.(); return [bytes];
    },
  }) }) }) },
}));

const { privateAttachmentsRouter } = await import('./privateAttachments.routes');
const { errorHandler } = await import('../middlewares/errorHandler');
const app = express(); app.use('/private', privateAttachmentsRouter); app.use(errorHandler);
const identities: Record<string, any> = {
  a1: { uid: 'a1', role: 'subscriber', providerId: 'A' }, a2: { uid: 'a2', role: 'subscriber', providerId: 'A' },
  b1: { uid: 'b1', role: 'subscriber', providerId: 'B' }, pa: { uid: 'pa', role: 'providerAdmin', providerId: 'A' },
  pb: { uid: 'pb', role: 'providerAdmin', providerId: 'B' }, saas: { uid: 'saas', superAdmin: true },
};
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Zl1sAAAAASUVORK5CYII=', 'base64');
const pdf = Buffer.from('%PDF-1.7\nmock document\n%%EOF');
const ticket = '/private/tickets/t1/attachments/up1';
const report = '/private/providers/A/results/r1/reports/up1';
const meta = (kind = 'ticket') => kind === 'ticket' ? 'tickets/t1/private_attachments/up1' : 'provedores/A/diagnostic_results/r1/private_attachments/up1';
function put(path = ticket, who = 'a1', bytes = png, mime = 'image/png') { return request(app).put(path).auth(who, { type: 'bearer' }).set('Content-Type', mime).send(bytes); }
function get(path = ticket, who = 'a1') { return request(app).get(path).auth(who, { type: 'bearer' }); }
beforeEach(() => {
  state.docs.clear(); state.objects.clear(); state.claims.clear();
  for (const identity of Object.values(identities)) { const { uid, ...claims } = identity; state.claims.set(uid, claims); }
  state.docs.set('tickets/t1', { providerId: 'A', createdByUid: 'a1' });
  state.docs.set('provedores/A/diagnostic_results/r1', { schemaVersion: 2, providerId: 'A', createdByUid: 'a1' });
  process.env.PRIVATE_DIAGNOSTIC_RULES_ACTIVE_AFTER = '2026-10-31T00:00:00Z';
  state.failUpload = state.failCommit = state.authorityDown = state.revoked = false;
  state.reads = state.writes = state.generation = 0; state.afterDownload = undefined;
});
it.each([[ticket, png, 'image/png'], [report, pdf, 'application/pdf']])('isolates real HTTP resource %s by current role, owner and tenant', async (path, bytes, mime) => {
  expect((await put(path, 'a1', bytes, mime)).status).toBe(200);
  for (const who of ['a1', 'pa', 'saas']) {
    expect((await put(path, who, bytes, mime)).status).toBe(200);
    expect((await get(path, who)).status).toBe(200);
  }
  for (const who of ['a2', 'b1', 'pb']) {
    const reads = state.reads, writes = state.writes;
    expect((await get(path, who)).status).toBe(403);
    expect((await put(path, who, bytes, mime)).status).toBe(403);
    expect((await request(app).delete(path).auth(who, { type: 'bearer' })).status).toBe(404);
    expect(state.reads).toBe(reads); expect(state.writes).toBe(writes);
  }
  expect(JSON.stringify((await get(path)).headers)).not.toMatch(/downloadtoken|https:/i);
  state.claims.set('a1', { role: 'subscriber', providerId: 'B' });
  expect((await get(path)).status).toBe(403);
});
it('closes revoked, absent and unavailable authority before Storage I/O', async () => {
  expect((await request(app).get(ticket)).status).toBe(401);
  state.revoked = true; expect((await put()).status).toBe(401); state.revoked = false;
  state.authorityDown = true; expect((await put()).status).toBe(503);
  expect(state.writes).toBe(0);
});
it('keeps pending uploads unreadable, recovers exact retry and emits one stable message', async () => {
  state.failUpload = true; expect((await put()).status).toBe(503);
  expect((await get()).status).toBe(409);
  state.failUpload = false; state.failCommit = true; expect((await put()).status).toBe(500);
  expect((await get()).status).toBe(409);
  state.failCommit = false;
  expect((await put()).status).toBe(200); expect((await put()).status).toBe(200);
  expect([...state.docs.keys()].filter(path => path.includes('/messages/'))).toEqual(['tickets/t1/messages/attachment_up1']);
  const changed = Buffer.from(png); changed[23] = 2;
  expect((await put(ticket, 'a1', changed)).status).toBe(409);
});
it.each(['path', 'generation', 'ownerUid', 'providerId', 'resourceId', 'attachmentId', 'checksum', 'state', 'size', 'arbitraryUrl'])('fails closed on forged metadata %s', async key => {
  expect((await put()).status).toBe(200);
  state.docs.get(meta())[key] = key === 'size' ? 999999999 : 'forged';
  expect((await get()).status).not.toBe(200);
});
const inconsistentStates = [
  {}, { state: 'quarantined' }, { state: null },
  { state: 'pending', generation: '1' }, { state: 'pending', generation: null },
  { state: 'committed' }, { state: 'committed', generation: '999' },
  { state: 'committed', generation: 1 }, { state: 'committed', generation: '' },
  { state: 'committed', generation: '0' },
];
it.each([['ticket', ticket, png, 'image/png'], ['report', report, pdf, 'application/pdf']])(
  'rejects inconsistent %s state/generation introduced between reservation and commit', async (kind, path, bytes, mime) => {
    for (const mutation of inconsistentStates) {
      state.docs.delete(meta(kind)); state.objects.clear();
      state.afterDownload = () => {
        const metadata = state.docs.get(meta(kind));
        delete metadata.state; delete metadata.generation;
        Object.assign(metadata, mutation);
      };
      expect((await put(path, 'a1', bytes, mime)).status).toBe(409);
      expect(state.docs.get(meta(kind))).toMatchObject(mutation);
      const rejectedMetadata = structuredClone(state.docs.get(meta(kind)));
      expect(rejectedMetadata.state).toBe(mutation.state);
      expect(state.docs.has('tickets/t1/messages/attachment_up1')).toBe(false);
      expect(state.docs.get('provedores/A/diagnostic_results/r1').reportAttachmentId).toBeUndefined();
      const reads = state.reads;
      expect((await get(path)).status).not.toBe(200);
      expect(state.reads).toBe(reads);
      state.afterDownload = undefined;
      const writes = state.writes;
      expect((await put(path, 'a1', bytes, mime)).status).toBe(409);
      expect(state.docs.get(meta(kind))).toEqual(rejectedMetadata);
      // A syntactically valid committed generation mismatch is checked after I/O.
      expect(state.writes).toBe(writes + (mutation.generation === '999' ? 1 : 0));
    }
  });
it('denies stale ownership, missing object, token capability, changed bytes and mid-read revocation', async () => {
  expect((await put()).status).toBe(200);
  state.docs.get('tickets/t1').createdByUid = 'a2';
  expect((await get()).status).toBe(403); expect((await get(ticket, 'a2')).status).toBe(409);
  state.docs.get('tickets/t1').createdByUid = 'a1';
  const object = [...state.objects.values()][0]; object.metadata.firebaseStorageDownloadTokens = 'forbidden';
  expect((await get()).status).toBe(409); delete object.metadata.firebaseStorageDownloadTokens;
  object.bytes[23] = 2; expect((await get()).status).toBe(409); object.bytes[23] = 1;
  state.afterDownload = () => { state.revoked = true; }; expect((await get()).status).toBe(401);
  state.revoked = false; state.afterDownload = undefined; state.objects.clear(); expect((await get()).status).toBe(500);
});
it('rejects arbitrary destinations, invalid MIME, oversized and forged binary without Storage writes', async () => {
  for (const [bytes, mime] of [[png, 'text/html'], [Buffer.from('fake'), 'image/png'], [Buffer.alloc(5 * 1024 * 1024 + 1), 'image/png']] as const)
    expect((await put(ticket, 'a1', bytes, mime)).status).not.toBe(200);
  expect((await put(ticket + '?path=elsewhere')).status).toBe(400);
  expect((await put('/private/tickets/t1/attachments/bad.path')).status).toBe(400);
  expect((await put(report, 'a1', Buffer.from('%PDF-invalid'), 'application/pdf')).status).toBe(415);
  expect(state.writes).toBe(0);
});
it('does not adopt legacy diagnostics with missing tenant or a forged report association', async () => {
  delete state.docs.get('provedores/A/diagnostic_results/r1').providerId;
  expect((await put(report, 'a1', pdf, 'application/pdf')).status).toBe(400);
  expect(state.writes).toBe(0);
});
it('requires verified Rules cutoff and schema for reports; body flags cannot grant legacy ownership', async () => {
  delete process.env.PRIVATE_DIAGNOSTIC_RULES_ACTIVE_AFTER;
  expect((await put(report, 'a1', pdf, 'application/pdf')).status).toBe(409);
  process.env.PRIVATE_DIAGNOSTIC_RULES_ACTIVE_AFTER = '2026-11-01T00:00:00Z';
  expect((await put(report, 'a1', pdf, 'application/pdf')).status).toBe(409);
  process.env.PRIVATE_DIAGNOSTIC_RULES_ACTIVE_AFTER = '2026-10-31T00:00:00Z';
  delete state.docs.get('provedores/A/diagnostic_results/r1').schemaVersion;
  expect((await put(report, 'a1', pdf, 'application/pdf')).status).toBe(409);
  expect(state.writes).toBe(0);
});
it('bounds concurrent file buffers and releases slots after completion', async () => {
  expect((await put()).status).toBe(200);
  let release!: () => void, entered!: () => void, count = 0;
  const barrier = new Promise<void>(resolve => { release = resolve; });
  const ready = new Promise<void>(resolve => { entered = resolve; });
  state.afterDownload = () => { if (++count === 8) entered(); return barrier; };
  const pending = Array.from({ length: 8 }, () => get().then(response => response.status));
  await ready;
  try { expect((await get()).status).toBe(503); }
  finally { release(); }
  expect(await Promise.all(pending)).toEqual(Array(8).fill(200));
  state.afterDownload = undefined;
  expect((await get()).status).toBe(200);
});
