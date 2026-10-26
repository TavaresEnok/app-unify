import * as logger from "firebase-functions/logger";
import { FieldValue } from "firebase-admin/firestore";
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

    // Claim atômico contra dupla execução (TOCTOU): onDocumentCreated é
    // at-least-once, então duas entregas concorrentes poderiam passar pelo
    // check acima antes de qualquer resposta existir. `.create()` falha com
    // ALREADY_EXISTS se outra invocação já reivindicou este requestId (M9).
    try {
      await db.collection("function_locks").doc(requestId).create({ claimedAt: FieldValue.serverTimestamp() });
    } catch {
      logger.info("Function request already claimed", { requestId });
      return;
    }

    let request: FunctionRequest;
    try {
      // Defesa em profundidade contra forja de identidade: se ambos os campos
      // requesterUid (topo e payload) existem e divergem, a requisição é
      // rejeitada — nunca deixamos o campo aninhado sobrescrever o de topo
      // usado na autorização. As regras do Firestore já impõem que ambos sejam
      // o próprio usuário; isto protege caso as regras sejam contornadas.
      if (isRecord(rawRequest) && isRecord(rawRequest.payload) &&
        typeof rawRequest.requesterUid === "string" &&
        typeof rawRequest.payload.requesterUid === "string" &&
        rawRequest.requesterUid !== rawRequest.payload.requesterUid) {
        throw new Error("requesterUid divergente entre topo e payload.");
      }
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
      // Detalhe real do erro fica apenas no servidor; ao cliente vai appError
      // (genérico para falhas não-AppError).
      if (!(error instanceof Error) || error.name !== "AppError") {
        logger.error("Unhandled handler error", {
          requestId,
          type: request.type,
          error: error instanceof Error ? (error.stack || error.message) : String(error),
        });
      }
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
