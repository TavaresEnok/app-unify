import { ApiError } from "../middlewares/errorHandler";

export type Cursor = { scope: string; id: string; seconds?: number; nanos?: number };

export function pageSize(value: unknown): number {
  if (value === undefined) return 25;
  if (typeof value !== "string" || !/^[1-9]\d*$/.test(value) || Number(value) > 100) {
    throw new ApiError(400, "Tamanho de página inválido.", "invalid-argument");
  }
  return Number(value);
}

export function decodeCursor(value: unknown, scope: string, timestamp = false): Cursor | null {
  if (value === undefined) return null;
  try {
    if (typeof value !== "string" || value.length > 2048 || !/^[A-Za-z0-9_-]+$/.test(value)) throw Error();
    const cursor = JSON.parse(Buffer.from(value, "base64url").toString()) as Cursor;
    if (cursor.scope !== scope || typeof cursor.id !== "string" || !cursor.id || cursor.id.includes("/") || cursor.id.length > 1500) throw Error();
    if (timestamp && (!Number.isInteger(cursor.seconds) || cursor.seconds! < 0 || cursor.seconds! > 253402300799 || !Number.isInteger(cursor.nanos) || cursor.nanos! < 0 || cursor.nanos! > 999999999)) throw Error();
    return cursor;
  } catch {
    throw new ApiError(400, "Cursor inválido para esta consulta.", "invalid-argument");
  }
}

export function cursorDate(cursor: Cursor): Date {
  return new Date(cursor.seconds! * 1000 + Math.floor((cursor.nanos || 0) / 1_000_000));
}

export function encodeCursor(scope: string, id: string, timeValue?: Date | string | null): string {
  if (!timeValue) {
    return Buffer.from(JSON.stringify({ scope, id })).toString("base64url");
  }
  const ms = timeValue instanceof Date ? timeValue.getTime() : Date.parse(String(timeValue));
  const seconds = Math.floor(ms / 1000);
  const nanos = (ms % 1000) * 1_000_000;
  return Buffer.from(JSON.stringify({ scope, id, seconds, nanos })).toString("base64url");
}
