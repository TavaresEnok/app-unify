// Minimal Firestore transport fixture; no connections to Firebase are made.
export const collection = (_db: unknown, ...path: string[]) => path.join('/');
export const doc = collection;
export const query = (reference: string, ..._filters: unknown[]) => reference;
export const where = (...args: unknown[]) => args;
export const orderBy = (...args: unknown[]) => args;
export const limit = (...args: unknown[]) => args;
export const deleteField = () => null;
export const serverTimestamp = () => new Date();
export class Timestamp { toDate() { return new Date('2026-01-01'); } }
export function onSnapshot(reference: string, callback: (snapshot: unknown) => void) {
  let active = true;
  const docs = reference === 'notifications' ? [{ id: 'notification', data: () => ({ title: 'Aviso de teste', targetCpf: null, successCount: 1, createdAt: new Timestamp() }) }] : [];
  queueMicrotask(() => { if (active) callback({ docs }); });
  return () => { active = false; };
}
export const deleteDoc = async () => {};
export const updateDoc = async () => {};
export const addDoc = async () => ({ id: 'fixture' });
