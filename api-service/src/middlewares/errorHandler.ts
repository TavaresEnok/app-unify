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

// Erros do body-parser (JSON malformado/grande demais) são erro do cliente,
// não do servidor.
function clientBodyError(error: unknown): ApiError | null {
  const type = (error as { type?: string } | null)?.type;
  if (type === "entity.parse.failed") return new ApiError(400, "JSON inválido.", "invalid-argument");
  if (type === "entity.too.large") return new ApiError(413, "Corpo da requisição muito grande.", "invalid-argument");
  if (type === "encoding.unsupported" || type === "charset.unsupported") return new ApiError(415, "Formato da requisição não suportado.", "invalid-argument");
  return null;
}

export const errorHandler: ErrorRequestHandler = (error, req, res, _next) => {
  const apiError = error instanceof ApiError ? error : clientBodyError(error) || new ApiError(500, "Erro interno do servidor.");
  const originalMessage = error instanceof Error ? error.message : String(error);
  console.error(JSON.stringify({
    severity: apiError.status >= 500 ? "ERROR" : "WARNING",
    message: originalMessage,
    code: apiError.code,
    status: apiError.status,
    correlationId: req.correlationId,
    method: req.method,
    path: req.path,
  }));
  if (apiError.status === 503) res.setHeader("Retry-After", "3");
  res.status(apiError.status).json({
    error: { message: apiError.message, code: apiError.code, correlationId: req.correlationId },
  });
};

export function asyncRoute(handler: (req: any, res: any, next: any) => Promise<unknown>): RequestHandler {
  return (req, res, next) => { Promise.resolve(handler(req, res, next)).catch(next); };
}
