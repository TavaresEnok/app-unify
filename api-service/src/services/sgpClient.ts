import axios, { type AxiosInstance } from "axios";
import * as https from "node:https";
import { env } from "../config/env";
import { ApiError } from "../middlewares/errorHandler";

export interface ContractCredentials {
  contrato: Record<string, any>;
  contratoId: string | number;
  senhaCentral: string;
}

export function requireSgpCredentials(): void {
  if (!env.sgpToken || !env.sgpAppName) throw new ApiError(503, "Credenciais do SGP não configuradas no servidor.", "service-unavailable");
}

export function createSgpSession(): AxiosInstance {
  return axios.create({
    timeout: 30_000,
    httpsAgent: new https.Agent({ rejectUnauthorized: env.sgpRejectUnauthorized }),
    headers: { "User-Agent": "Unify-API/1.0", "Content-Type": "application/json" },
  });
}

export async function resolveContractCredentials(
  session: AxiosInstance,
  cpfCnpj: string,
): Promise<ContractCredentials> {
  requireSgpCredentials();
  const response = await session.post(`${env.sgpBaseUrl}/ws/ura/consultacliente/`, {
    token: env.sgpToken,
    app: env.sgpAppName,
    cpfcnpj: cpfCnpj,
  });
  const contracts = response.data?.contratos;
  if (!Array.isArray(contracts) || !contracts.length) throw new ApiError(404, "Nenhum contrato encontrado para este cliente.", "not-found");
  const contrato = contracts[0] as Record<string, any>;
  const contratoId = contrato.contratoId || contrato.contrato_id || contrato.id;
  if (!contratoId) throw new ApiError(502, "Contrato retornado pelo SGP sem identificador.", "invalid-upstream-response");
  return {
    contrato,
    contratoId,
    senhaCentral: contrato.contratoCentralSenha || contrato.central_senha || "",
  };
}

export function externalErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError(error)) {
    const upstream = error.response?.data?.msg || error.response?.data?.message;
    return typeof upstream === "string" && upstream ? upstream : fallback;
  }
  return error instanceof Error ? error.message : fallback;
}
