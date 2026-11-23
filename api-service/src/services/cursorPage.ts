import { Timestamp } from 'firebase-admin/firestore';
import { ApiError } from '../middlewares/errorHandler';

type Cursor = { scope: string; id: string; seconds?: number; nanos?: number };
export function pageSize(value: unknown): number {
  if (value === undefined) return 25;
  if (typeof value !== 'string' || !/^[1-9]\d*$/.test(value) || Number(value) > 100) throw new ApiError(400, 'Tamanho de página inválido.', 'invalid-argument');
  return Number(value);
}
export function decodeCursor(value: unknown, scope: string, timestamp = false): Cursor | null {
  if (value === undefined) return null;
  try {
    if (typeof value !== 'string' || value.length > 2048 || !/^[A-Za-z0-9_-]+$/.test(value)) throw Error();
    const cursor = JSON.parse(Buffer.from(value, 'base64url').toString()) as Cursor;
    if (cursor.scope !== scope || typeof cursor.id !== 'string' || !cursor.id || cursor.id.includes('/') || cursor.id.length > 1500) throw Error();
    if (timestamp && (!Number.isInteger(cursor.seconds) || cursor.seconds! < 0 || cursor.seconds! > 253402300799 || !Number.isInteger(cursor.nanos) || cursor.nanos! < 0 || cursor.nanos! > 999999999)) throw Error();
    return cursor;
  } catch { throw new ApiError(400, 'Cursor inválido para esta consulta.', 'invalid-argument'); }
}
export function cursorTimestamp(cursor: Cursor) { return new Timestamp(cursor.seconds!, cursor.nanos!); }
export function encodeCursor(scope: string, doc: FirebaseFirestore.QueryDocumentSnapshot, timeField?: string): string {
  const time = timeField ? doc.data()[timeField] as Timestamp : undefined;
  return Buffer.from(JSON.stringify({ scope, id: doc.id, ...(time ? { seconds: time.seconds, nanos: time.nanoseconds } : {}) })).toString('base64url');
}
