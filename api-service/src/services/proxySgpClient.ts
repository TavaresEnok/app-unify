import axios from "axios";
import { env } from "../config/env";
import { ApiError } from "../middlewares/errorHandler";

// clientIp: IP real do assinante (o Caddy já o coloca em req.ip). Vai em
// X-Forwarded-For para o proxy limitar por cliente, e não por este container.
export async function proxyToSgp(
  path: string,
  body: unknown,
  authorization?: string,
  clientIp?: string,
  options: { timeoutMs?: number } = {},
): Promise<{ status: number; data: unknown }> {
  const timeout = Number.isFinite(options.timeoutMs) && Number(options.timeoutMs) > 0 ? Math.min(Number(options.timeoutMs), 60_000) : 30_000;
  const forwarded = typeof clientIp === "string" && /^[0-9a-f:.]{2,45}$/i.test(clientIp.trim()) ? clientIp.trim() : "";
  try {
    const response = await axios.post(`${env.proxySgpUrl}${path}`, body, {
      headers: {
        "Content-Type": "application/json",
        ...(authorization ? { Authorization: authorization } : {}),
        ...(forwarded ? { "X-Forwarded-For": forwarded } : {}),
      },
      timeout,
      maxRedirects: 0,
      proxy: false,
    });
    return { status: response.status, data: response.data };
  } catch (error) {
    if (axios.isAxiosError(error)) {
      throw new ApiError(error.response?.status || 502, error.response?.data?.error?.message || "Falha ao consultar o proxy SGP.", "upstream-error");
    }
    throw error;
  }
}

export const BOLETO_FAILED_MESSAGE = "Não foi possível gerar o boleto agora. Tente de novo ou use o PIX.";
const MAX_BOLETO_BYTES = 5 * 1024 * 1024;

function proxyErrorBody(data: unknown): { message?: string; code?: string } {
  try {
    const text = Buffer.isBuffer(data) ? data.toString("utf8") : data instanceof ArrayBuffer ? Buffer.from(data).toString("utf8") : null;
    const parsed = text === null ? data : JSON.parse(text);
    const error = (parsed as { error?: { message?: unknown; code?: unknown } } | null)?.error;
    return {
      message: typeof error?.message === "string" ? error.message : undefined,
      code: typeof error?.code === "string" ? error.code : undefined,
    };
  } catch {
    return {};
  }
}

/** PDF do boleto (proxy-sgp `/invoice/boleto-pdf`); erros viram mensagens para o assinante. */
export async function proxyBoletoPdf(
  body: Record<string, unknown>,
  authorization: string | undefined,
  clientIp?: string,
): Promise<Buffer> {
  const forwarded = typeof clientIp === "string" && /^[0-9a-f:.]{2,45}$/i.test(clientIp.trim()) ? clientIp.trim() : "";
  try {
    const response = await axios.post(`${env.proxySgpUrl}/invoice/boleto-pdf`, body, {
      headers: {
        "Content-Type": "application/json",
        ...(authorization ? { Authorization: authorization } : {}),
        ...(forwarded ? { "X-Forwarded-For": forwarded } : {}),
      },
      responseType: "arraybuffer",
      maxContentLength: MAX_BOLETO_BYTES + 1024,
      timeout: 45_000,
      maxRedirects: 0,
      proxy: false,
    });
    const pdf = Buffer.from(response.data as ArrayBuffer);
    if (pdf.length < 8 || pdf.subarray(0, 5).toString("latin1") !== "%PDF-") {
      throw new ApiError(502, BOLETO_FAILED_MESSAGE, "boleto-failed");
    }
    return pdf;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    if (!axios.isAxiosError(error)) throw error;
    const status = error.response?.status;
    const detail = proxyErrorBody(error.response?.data);
    if (status === 404) {
      throw new ApiError(404, detail.message || "Boleto não disponível para esta fatura.", detail.code || "boleto-unavailable");
    }
    if (status === 400 || status === 401 || status === 403) {
      throw new ApiError(status, detail.message || "Não foi possível abrir o boleto.", status === 400 ? "invalid-argument" : status === 401 ? "unauthenticated" : "permission-denied");
    }
    if (status === 429) {
      throw new ApiError(429, "Você pediu o boleto muitas vezes. Tente de novo mais tarde ou use o PIX.", "resource-exhausted");
    }
    throw new ApiError(502, BOLETO_FAILED_MESSAGE, "boleto-failed");
  }
}
