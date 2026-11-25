import type { Request } from "express";
import { ApiError } from "../middlewares/errorHandler";
import { ensureCoreSchema, getPgPool } from "./postgres";

function cpfDigits(body: unknown): string {
  const source = body as { cpfCnpj?: unknown; cpf?: unknown } | undefined;
  const raw = typeof source?.cpfCnpj === "string"
    ? source.cpfCnpj
    : typeof source?.cpf === "string" ? source.cpf : "";
  return raw.replace(/\D/g, "");
}

/**
 * Resolve o provedor dono de um CPF consultando `subscribers` e o cache `sgp_clients` no PostgreSQL.
 */
export async function providerOfCpf(digits: string, expectedProvider?: string): Promise<string | undefined> {
  if (!expectedProvider || !digits) return undefined;
  const pool = getPgPool();
  if (!pool) return undefined;
  await ensureCoreSchema(pool);

  const subRes = await pool.query<{ provider_id: string }>(
    `SELECT provider_id FROM subscribers WHERE provider_id = $1 AND cpfcnpj = $2 LIMIT 1`,
    [expectedProvider, digits],
  ).catch(() => ({ rows: [] as Array<{ provider_id: string }> }));
  if (subRes.rows[0]?.provider_id === expectedProvider) return expectedProvider;

  const clientRes = await pool.query<{ provider_id: string }>(
    `SELECT provider_id FROM sgp_clients WHERE provider_id = $1 AND cpfcnpj = $2 LIMIT 1`,
    [expectedProvider, digits],
  ).catch(() => ({ rows: [] as Array<{ provider_id: string }> }));
  return clientRes.rows[0]?.provider_id === expectedProvider ? expectedProvider : undefined;
}

/**
 * Garante que o CPF alvo pertence ao tenant do chamador (M1).
 */
export async function assertCpfInTenant(req: Request): Promise<void> {
  if (req.user?.superAdmin === true) return;

  const digits = cpfDigits(req.body);
  if (!digits) throw new ApiError(400, "CPF/CNPJ é obrigatório.", "invalid-argument");

  if (req.user?.role === "subscriber" && req.user.cpfCnpj === digits && typeof req.user.providerId === "string") return;

  const callerProvider = req.user?.providerId;
  if (req.user?.role !== "providerAdmin" || typeof callerProvider !== "string") {
    throw new ApiError(403, "Você só pode acessar os seus próprios dados.", "permission-denied");
  }

  const owner = await providerOfCpf(digits, callerProvider);
  if (!owner || owner !== callerProvider) {
    throw new ApiError(403, "Este cliente não pertence ao seu provedor.", "permission-denied");
  }
}
