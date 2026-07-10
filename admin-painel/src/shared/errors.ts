export function getErrorMessage(error: unknown, fallback = "Falha inesperada."): string {
  if (error instanceof Error && error.message) return error.message;
  if (typeof error !== "object" || error === null) return fallback;

  const candidate = error as { message?: unknown; code?: unknown };
  if (typeof candidate.message === "string" && candidate.message) return candidate.message;
  if (typeof candidate.code === "string" && candidate.code) return candidate.code;
  return fallback;
}
