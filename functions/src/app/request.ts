import type {
  FunctionRequest,
  FunctionRequestPayloadMap,
  FunctionRequestType,
} from "../contracts";
import { AppError } from "./errors";
import { assertFunctionRequest, isRecord } from "../contracts";

export function normalizeRequest(raw: unknown): FunctionRequest {
  if (isRecord(raw) && isRecord(raw.payload) && typeof raw.requesterUid === "string" &&
      typeof raw.payload.requesterUid === "string" && raw.requesterUid !== raw.payload.requesterUid) {
    throw new AppError("invalid-argument", "Requisição inválida.");
  }
  const normalized = isRecord(raw) && isRecord(raw.payload) && raw.requesterUid === undefined &&
    typeof raw.payload.requesterUid === "string" ? { ...raw, requesterUid: raw.payload.requesterUid } : raw;
  assertFunctionRequest(normalized);
  const { requesterUid: _legacyUid, ...payload } = normalized.payload as Record<string, unknown>;
  return { type: normalized.type, requesterUid: normalized.requesterUid, payload,
    ...(normalized.session !== undefined ? { session: normalized.session } : {}) } as FunctionRequest;
}

export function requirePayloadFields(payload: object, allowed: string[]): void {
  if (Object.keys(payload).some(key => !allowed.includes(key))) {
    throw new AppError("invalid-argument", "Campo de configuração não permitido.");
  }
}

export interface RequestContext<T extends FunctionRequestType = FunctionRequestType> {
  requestId: string;
  type: T;
  requesterUid: string;
  payload: FunctionRequestPayloadMap[T];
}

export type RequestHandler<T extends FunctionRequestType = FunctionRequestType> = (
  context: RequestContext<T>,
) => Promise<unknown>;

export function toRequestContext<T extends FunctionRequestType>(
  requestId: string,
  request: FunctionRequest<T>,
): RequestContext<T> {
  return {
    requestId,
    type: request.type,
    requesterUid: request.requesterUid,
    payload: request.payload,
  };
}
