import type { ErrorCode } from "../contracts";

export class AppError extends Error {
  constructor(readonly code: ErrorCode, message: string) {
    super(message);
    this.name = "AppError";
  }
}

export function toAppError(error: unknown): AppError {
  if (error instanceof AppError) return error;
  if (error instanceof Error) return new AppError("internal", error.message);
  return new AppError("internal", "Falha interna inesperada.");
}
