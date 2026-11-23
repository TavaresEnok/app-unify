import express from 'express';
import request from 'supertest';
import { beforeEach, expect, it, vi } from 'vitest';
import { Timestamp } from 'firebase-admin/firestore';
const state = vi.hoisted(() => ({ docs: [] as any[], limits: [] as number[] }));
const claims = (uid: string) => uid === 'root' ? { superAdmin: true } : { role: uid === 'sub' ? 'subscriber' : 'providerAdmin', providerId: uid };
function query(name: string, filters: any[] = [], orders: any[] = [], after: any[] = [], size?: number): any {
  return {
    where: (...filter: any[]) => query(name, [...filters, filter], orders, after, size),
    orderBy: (...order: any[]) => query(name, filters, [...orders, order], after, size),
    startAfter: (...cursor: any[]) => query(name, filters, orders, cursor, size),
    limit: (limit: number) => { state.limits.push(limit); return query(name, filters, orders, after, limit); },
    get: async () => {
      if (!size || size > 101) throw Error('Unbounded read');
      const field = (doc: any, key: string) => key === '__name__' ? doc.id : doc.data[key];
      const compare = (a: any, b: any) => a instanceof Timestamp ? a.toMillis() - b.toMillis() : String(a).localeCompare(String(b));
      const order = (a: any, b: any) => { for (const [key, dir] of orders) { const diff = compare(field(a,key),field(b,key)); if (diff) return diff * (dir === 'desc' ? -1 : 1); } return 0; };
      let docs = state.docs.filter(d => d.collection === name && filters.every(([key, op, value]) => op === 'in' ? value.includes(d.data[key]) : d.data[key] === value)).sort(order);
      if (after.length) docs = docs.filter(d => {
        const cursor = { id: after[after.length - 1], data: Object.fromEntries(orders.map(([key], i) => [key, after[i]])) };
        return order(d, cursor) > 0;
      });
      return { docs: docs.slice(0,size).map(d => ({ id: d.id, data: () => d.data })) };
    },
  };
}
vi.mock('../services/firebaseAdmin', () => ({ firestore: { collection: query }, serverTimestamp: () => null, firebaseAuth: {
  verifyIdToken: async (token: string) => ({ uid: token, ...claims(token) }),
  getUser: async (uid: string) => ({ customClaims: claims(uid) }),
} }));
import { ticketsRouter } from './tickets.routes';
import { usersRouter } from './users.routes';
import { errorHandler } from '../middlewares/errorHandler';
const app = express(); app.use('/tickets', ticketsRouter); app.use('/users', usersRouter); app.use(errorHandler);
const get = (path: string, user = 'root') => request(app).get(path).set('Authorization', `Bearer ${user}`);
beforeEach(() => {
  state.limits = [];
  state.docs = Array.from({ length: 10000 }, (_, i) => ({ collection: 'tickets', id: String(i).padStart(5,'0'), data: { subject: `Ticket ${i}`, providerId: i % 2 ? 'b' : 'a', updatedAt: Timestamp.fromMillis(1000) } }));
  state.docs.push(...Array.from({ length: 60 }, (_, i) => ({ collection: 'users', id: `u${String(i).padStart(2,'0')}`, data: { role: i === 59 ? 'subscriber' : 'providerAdmin', email: `${i}@example.test` } })));
});
it('paginates 5000 tenant tickets with stable tie ordering and a bounded read', async () => {
  const first = await get('/tickets/page', 'a').expect(200);
  const second = await get(`/tickets/page?cursor=${first.body.nextCursor}`, 'a').expect(200);
  expect(first.body.data).toHaveLength(25); expect(second.body.data).toHaveLength(25);
  expect(new Set([...first.body.data,...second.body.data].map(d => d.id)).size).toBe(50);
  expect([...first.body.data,...second.body.data].every(d => d.providerId === 'a')).toBe(true);
  expect(state.limits).toEqual([26,26]);
  await get(`/tickets/page?cursor=${first.body.nextCursor}`, 'b').expect(400);
  await get(`/tickets/page?cursor=${first.body.nextCursor}`, 'root').expect(400);
  await get('/tickets/page', 'sub').expect(403);
  expect(state.limits).toHaveLength(2);
});
it('rejects malformed limits and cursors before querying', async () => {
  for (const suffix of ['limit=0','limit=1000','limit=-1','limit=1.5','limit=abc','cursor=malformed']) await get(`/tickets/page?${suffix}`).expect(400);
  expect(state.limits).toEqual([]);
});
it('pages all administrators beyond the first page, excludes subscribers and denies provider access', async () => {
  let cursor = null; const ids: string[] = [];
  do { const response = await get('/users/page?limit=25'+(cursor ? `&cursor=${cursor}` : '')).expect(200); ids.push(...response.body.data.map((u: any) => u.uid)); cursor = response.body.nextCursor; } while(cursor);
  expect(ids).toHaveLength(59); expect(new Set(ids).size).toBe(59); expect(state.limits).toEqual([26,26,26]);
  await get('/users/page','a').expect(403);
});
