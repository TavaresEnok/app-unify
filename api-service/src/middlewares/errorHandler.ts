import type { ErrorRequestHandler, RequestHandler } from "express";
import { randomUUID } from "node:crypto";

export class ApiError extends Error {
  constructor(readonly status: number, message: string, readonly code = "internal") {
    super(message);
    this.name = "ApiError";
  }
}

export const correlationId: RequestHandler = (req, res, next) => {
  req.correlationId = req.header("x-correlation-id") || randomUUID();
  res.setHeader("x-correlation-id", req.correlationId);
  next();
};

export const notFoundHandler: RequestHandler = (req, _res, next) => {
  next(new ApiError(404, `Rota não encontrada: ${req.method} ${req.path}`, "not-found"));
};

export const errorHandler: ErrorRequestHandler = (error, req, res, _next) => {
  const apiError = error instanceof ApiError ? error : new ApiError(500, "Erro interno do servidor.");
  const originalMessage = error instanceof Error ? error.message : String(error);
  console.error(JSON.stringify({
    severity: "ERROR",
    message: originalMessage,
    code: apiError.code,
    status: apiError.status,
    correlationId: req.correlationId,
    method: req.method,
    path: req.path,
  }));
  res.status(apiError.status).json({
    error: { message: apiError.message, code: apiError.code, correlationId: req.correlationId },
  });
};

export function asyncRoute(handler: (req: any, res: any, next: any) => Promise<unknown>): RequestHandler {
  return (req, res, next) => { Promise.resolve(handler(req, res, next)).catch(next); };
}
