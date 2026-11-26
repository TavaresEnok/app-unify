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
