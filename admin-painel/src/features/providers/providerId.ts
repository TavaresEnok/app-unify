export const PROVIDER_ID_PATTERN = /^[a-z0-9_-]{1,64}$/;

export function normalizeProviderId(raw: string): string {
  return raw.trim().toLowerCase();
}

/** Erro de validação do ID de um provedor novo, ou null se estiver ok. */
export function newProviderIdError(id: string, existingIds: Iterable<string>): string | null {
  if (!id) return "Informe o ID do provedor.";
  if (!PROVIDER_ID_PATTERN.test(id)) return "Use só letras minúsculas, números, hífen ou sublinhado (até 64).";
  for (const existing of existingIds) {
    if (normalizeProviderId(existing) === id) return "Já existe um provedor com este ID.";
  }
  return null;
}
