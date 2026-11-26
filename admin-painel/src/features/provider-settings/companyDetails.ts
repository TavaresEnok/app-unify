export interface CompanyDetails {
  razaoSocial?: string;
  nomeFantasia?: string;
  cnpj?: string;
  email?: string;
  telefone?: string;
}

const text = (value: unknown): string | undefined => (typeof value === "string" ? value : undefined);

/**
 * Lê os dados da empresa. Os provedores migrados do Firestore usam
 * razaoSocial/nomeFantasia/telefone; cadastros novos podem ter
 * commercialName/phone. Prefere os nomes do formulário e cai nos outros.
 */
export function companyDetailsFromProvider(details: unknown): CompanyDetails {
  const source = details && typeof details === "object" ? (details as Record<string, unknown>) : {};
  return {
    razaoSocial: text(source.razaoSocial),
    nomeFantasia: text(source.nomeFantasia) ?? text(source.commercialName),
    cnpj: text(source.cnpj),
    email: text(source.email),
    telefone: text(source.telefone) ?? text(source.phone),
  };
}

/** Corpo do PATCH /admin/providers/:id/details: só strings, sem campos vazios indefinidos. */
export function companyDetailsPayload(details: CompanyDetails): Record<string, string> {
  const entries = (["razaoSocial", "nomeFantasia", "cnpj", "email", "telefone"] as const)
    .map((key) => [key, details[key]] as const)
    .filter((entry): entry is readonly [typeof entry[0], string] => typeof entry[1] === "string")
    .map(([key, value]) => [key, value.trim()] as const);
  return Object.fromEntries(entries);
}
