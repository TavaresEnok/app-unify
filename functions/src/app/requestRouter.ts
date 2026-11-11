import * as logger from "firebase-functions/logger";
import type { FunctionRequestType } from "../contracts";
import { AppError } from "./errors";
import { toRequestContext, type RequestHandler } from "./request";
import { failureResponse, successResponse } from "./writeResponse";
import { recordAudit } from "./audit";
import { requireSession } from "./permissions";
import { failedBeforeEffect, withAuthorizationPrelude } from "./authorizationPrelude";
import { claimRequest, finishRequest, heartbeat, LeaseLost, startRequest, UNKNOWN_MESSAGE } from "./requestLease";

export type HandlerRegistry = { [T in FunctionRequestType]: RequestHandler<T> };

export class RetryableRpcError extends Error {
  constructor() { super("RPC execution incomplete; retry delivery with the same request ID."); }
}

export function createRequestRouter(registry: HandlerRegistry, now: () => number = () => Date.now()) {
  const execute = async (requestId: string, rawRequest: unknown): Promise<void> => {
    // Database failures propagate for retry; only a successful read establishes a duplicate.
    const lease = await claimRequest(requestId, rawRequest, now());
    if (!lease) return;
    const request = lease.request;
    const handler = registry[request.type] as RequestHandler | undefined;
    if (typeof handler !== "function") throw new Error("RPC handler unavailable");
    await startRequest(lease, now());
    const renewal = heartbeat(lease, now);
    let response: Record<string, unknown>;
    let uncertain = false;
    let outcome: "success" | "failure" = "success";
    let authorized = false;
    try {
      await requireSession(request.requesterUid, request.session);
      authorized = true;
      // Real handlers re-read current Auth/domain records before any effect.
      const result = await withAuthorizationPrelude(() => handler(toRequestContext(requestId, request)));
      response = successResponse(request.requesterUid, result);
    } catch (error) {
      outcome = "failure";
      uncertain = authorized && lease.policy === "uncertain-effect" && !failedBeforeEffect(error);
      if (uncertain) {
        response = failureResponse(request.requesterUid, UNKNOWN_MESSAGE, "conflict", true);
      } else if (error instanceof AppError) {
        response = failureResponse(request.requesterUid, error.message, error.code);
      } else {
        throw error;
      }
    } finally {
      await renewal.stop();
    }
    // Failed persistence after an effect leaves running durable. Never turn it
    // into a safe-looking handler failure or overwrite another owner's response.
    await finishRequest(lease, response, uncertain, now());
    await recordAudit({ requestId, type: request.type, requesterUid: request.requesterUid,
      payload: {}, outcome }).catch(() => logger.error("RPC audit unavailable", { requestId }));
    logger.info("RPC terminal state persisted", { requestId, type: request.type, uncertain });
  };
  return async (requestId: string, rawRequest: unknown): Promise<void> => {
    try { await execute(requestId, rawRequest); } catch (error) {
      // The runtime logs rejected invocations too. Never attach a private
      // handler/SDK error or cause, while still rejecting for transport retry.
      if (error instanceof LeaseLost) throw error;
      throw new RetryableRpcError();
    }
  };
}
