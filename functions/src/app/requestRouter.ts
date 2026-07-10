import * as logger from "firebase-functions/logger";
import { assertFunctionRequest, isRecord, type FunctionRequest, type FunctionRequestType } from "../contracts";
import { toAppError } from "./errors";
import type { RequestHandler } from "./request";
import { toRequestContext } from "./request";
import { writeFailure, writeSuccess } from "./writeResponse";
import { recordAudit } from "./audit";
import { db } from "./firebase";

export type HandlerRegistry = { [T in FunctionRequestType]: RequestHandler<T> };

export function createRequestRouter(registry: HandlerRegistry) {
  return async (requestId: string, rawRequest: unknown): Promise<void> => {
    if ((await db.collection("function_responses").doc(requestId).get()).exists) {
      logger.info("Function request already completed", { requestId });
      return;
    }

    let request: FunctionRequest;
    try {
      const normalized = isRecord(rawRequest) && isRecord(rawRequest.payload) &&
        typeof rawRequest.requesterUid !== "string" && typeof rawRequest.payload.requesterUid === "string"
        ? { ...rawRequest, requesterUid: rawRequest.payload.requesterUid }
        : rawRequest;
      assertFunctionRequest(normalized);
      request = normalized;
    } catch (error) {
      logger.warn("Invalid function request ignored", { requestId, error: String(error) });
      const requesterUid = isRecord(rawRequest) && typeof rawRequest.requesterUid === "string"
        ? rawRequest.requesterUid
        : isRecord(rawRequest) && isRecord(rawRequest.payload) && typeof rawRequest.payload.requesterUid === "string"
          ? rawRequest.payload.requesterUid
          : undefined;
      if (requesterUid) {
        await writeFailure(requestId, requesterUid, "Requisição inválida.", "invalid-argument");
      }
      return;
    }

    const context = toRequestContext(requestId, request);
    const providerId = typeof (request.payload as { providerId?: unknown }).providerId === "string"
      ? (request.payload as { providerId: string }).providerId
      : undefined;

    logger.info("Function request started", {
      requestId,
      type: request.type,
      requesterUid: request.requesterUid,
      providerId,
    });

    try {
      const handler = registry[request.type] as RequestHandler;
      const result = await handler(context);
      await writeSuccess(requestId, request.requesterUid, result);
      await recordAudit({
        requestId,
        type: request.type,
        requesterUid: request.requesterUid,
        providerId,
        payload: request.payload,
        outcome: "success",
      }).catch((auditError) => logger.error("Audit write failed", {
        requestId,
        type: request.type,
        error: auditError instanceof Error ? auditError.message : String(auditError),
      }));
      logger.info("Function request completed", { requestId, type: request.type, providerId });
    } catch (error) {
      const appError = toAppError(error);
      await writeFailure(requestId, request.requesterUid, appError.message, appError.code);
      await recordAudit({
        requestId,
        type: request.type,
        requesterUid: request.requesterUid,
        providerId,
        outcome: "failure",
        errorCode: appError.code,
      }).catch((auditError) => logger.error("Audit write failed", {
        requestId,
        type: request.type,
        error: auditError instanceof Error ? auditError.message : String(auditError),
      }));
      logger.error("Function request failed", {
        requestId,
        type: request.type,
        providerId,
        code: appError.code,
        error: appError.message,
      });
    }
  };
}
