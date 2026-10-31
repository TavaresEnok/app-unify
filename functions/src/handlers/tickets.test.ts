import { beforeEach, expect, it, vi } from 'vitest';
const state = vi.hoisted(() => ({ docs: new Map<string, any>(), users: new Map<string, any>(), effects: 0 }));
function ref(path: string): any {
  const result = { id: path.split('/').pop(), get: async () => ({ exists: state.docs.has(path), data: () => state.docs.get(path), ref: result }),
    set: async (data: any) => { state.effects++; state.docs.set(path, data); },
    collection: (name: string) => collection(`${path}/${name}`) };
  return result;
}
function collection(path: string): any { return { doc: (key: string) => ref(`${path}/${key}`), add: async (data: any) => ref(`${path}/new`).set(data) }; }
vi.mock('../app/firebase', () => ({ db: { collection }, auth: { getUser: async (uid: string) => {
  const user = state.users.get(uid); if (!user) throw new Error('authority unavailable'); return user;
} } }));
vi.mock('firebase-admin/firestore', () => ({ FieldValue: { serverTimestamp: () => 'now' } }));
import { createTicket, replyToTicket, updateTicketStatus } from './tickets';
beforeEach(() => {
  state.docs.clear(); state.users.clear(); state.effects = 0;
  for (const [uid, role, providerId] of [['a1','subscriber','A'],['a2','subscriber','A'],['b1','subscriber','B'],['pa','providerAdmin','A'],['pb','providerAdmin','B']])
    state.users.set(uid, { uid, customClaims: { role, providerId, cpfCnpj: 'legacyCPF' } });
  state.users.set('saas', { uid: 'saas', customClaims: { superAdmin: true } });
  state.docs.set('tickets/t1', { providerId: 'A', createdByUid: 'a1' });
});
const context = (uid: string, payload: any): any => ({ requesterUid: uid, requestId: 'new-ticket', payload });
it.each(['a2','b1','pb'])('denies third-party association and reply from %s', async uid => {
  await expect(replyToTicket(context(uid, { ticketId: 't1', message: 'reply' }))).rejects.toMatchObject({ code: 'permission-denied' });
  expect(state.effects).toBe(0);
});
it.each(['a1','pa','saas'])('preserves authorized reply from %s', async uid => {
  await expect(replyToTicket(context(uid, { ticketId: 't1', message: 'reply' }))).resolves.toMatchObject({ success: true });
});
it('rejects URLs, paths, refs and owners at real handlers before effects', async () => {
  for (const key of ['imageUrl','attachmentId','path','ownerUid','reportUrl']) {
    await expect(createTicket(context('a1', { providerId: 'A', subject: 's', message: 'm', [key]: 'forged' }))).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(replyToTicket(context('a1', { ticketId: 't1', message: 'm', [key]: 'forged' }))).rejects.toMatchObject({ code: 'invalid-argument' });
  }
  expect(state.effects).toBe(0);
});
it('does not trust CPF legacy ownership or owner from payload', async () => {
  state.docs.get('tickets/t1').createdByUid = 'legacyCPF';
  await expect(replyToTicket(context('a1', { ticketId: 't1', message: 'm' }))).rejects.toMatchObject({ code: 'permission-denied' });
  state.docs.get('tickets/t1').createdByUid = 'a1';
  await expect(updateTicketStatus(context('a1', { ticketId: 't1', status: 'Fechado' }))).rejects.toMatchObject({ code: 'permission-denied' });
});
it('creates canonical ownership and tenant, denies revoked or unavailable authority', async () => {
  await createTicket(context('a1', { providerId: 'A', subject: 's', message: 'm' }));
  expect(state.docs.get('tickets/new-ticket')).toMatchObject({ createdByUid: 'a1', providerId: 'A' });
  state.users.get('a1').disabled = true;
  await expect(replyToTicket(context('a1', { ticketId: 't1', message: 'm' }))).rejects.toMatchObject({ code: 'unauthenticated' });
  state.users.delete('a1');
  await expect(replyToTicket(context('a1', { ticketId: 't1', message: 'm' }))).rejects.toMatchObject({ code: 'authorization-unavailable' });
});
