import type { ErrorCode } from "../contracts";

export class AppError extends Error {
  constructor(readonly code: ErrorCode, message: string) {
    super(message);
    this.name = "AppError";
  }
}

export function toAppError(error: unknown): AppError {
  if (error instanceof AppError) return error;
  // Erros não-AppError (ex.: Firestore/Node) podem conter caminhos, dicas de
  // índice e fragmentos de stack. Devolvemos uma mensagem genérica ao cliente;
  // o detalhe real é logado no servidor pelo requestRouter (M5).
  return new AppError("internal", "Falha interna inesperada. Tente novamente.");
}
