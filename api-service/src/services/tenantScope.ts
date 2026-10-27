import type { Request } from "express";
import { ApiError } from "../middlewares/errorHandler";
import { firestore } from "./firebaseAdmin";

function cpfDigits(body: unknown): string {
  const source = body as { cpfCnpj?: unknown; cpf?: unknown } | undefined;
  const raw = typeof source?.cpfCnpj === "string"
    ? source.cpfCnpj
    : typeof source?.cpf === "string" ? source.cpf : "";
  return raw.replace(/\D/g, "");
}

/**
 * Resolve o provedor dono de um CPF a partir da coleção `clientes` (id do
 * documento = CPF apenas dígitos, com fallback por campo `cpfCnpj`).
 */
export async function providerOfCpf(digits: string): Promise<string | undefined> {
  const direct = await firestore.collection("clientes").doc(digits).get();
  if (direct.exists) {
    const providerId = direct.data()?.providerId;
    return typeof providerId === "string" ? providerId : undefined;
  }
  const matches = await firestore.collection("clientes")
    .where("cpfCnpj", "==", digits).limit(1).get();
  const providerId = matches.docs[0]?.data()?.providerId;
  return typeof providerId === "string" ? providerId : undefined;
}

/**
 * Garante que o CPF alvo pertence ao tenant do chamador (M1).
 *
 * - superAdmin: acesso irrestrito.
 * - assinante: só o próprio CPF (uid do token é o CPF em dígitos).
 * - providerAdmin: apenas CPFs cujo `clientes/{cpf}.providerId` seja o seu.
 *
 * Sem isto, um admin do provedor A poderia ler/alterar dados (inclusive Wi-Fi)
 * de assinantes do provedor B, já que as rotas SGP recebem o CPF pelo corpo.
 */
export async function assertCpfInTenant(req: Request): Promise<void> {
  if (req.user?.superAdmin === true) return;

  const digits = cpfDigits(req.body);
  if (!digits) throw new ApiError(400, "CPF/CNPJ é obrigatório.", "invalid-argument");

  // Assinante acessando o próprio contrato — vínculo já vem do token.
  if (req.user?.uid === digits) return;

  const callerProvider = req.user?.providerId;
  if (typeof callerProvider !== "string") {
    throw new ApiError(403, "Você só pode acessar os seus próprios dados.", "permission-denied");
  }

  const owner = await providerOfCpf(digits);
  if (!owner || owner !== callerProvider) {
    throw new ApiError(403, "Este cliente não pertence ao seu provedor.", "permission-denied");
  }
}
