import axios from "axios";
import { env } from "../config/env";
import { ApiError } from "../middlewares/errorHandler";

export async function proxyToSgp(path: string, body: unknown, authorization?: string): Promise<{ status: number; data: unknown }> {
  try {
    const response = await axios.post(`${env.proxySgpUrl}${path}`, body, {
      headers: {
        "Content-Type": "application/json",
        ...(authorization ? { Authorization: authorization } : {}),
      },
      timeout: 30_000,
    });
    return { status: response.status, data: response.data };
  } catch (error) {
    if (axios.isAxiosError(error)) {
      throw new ApiError(error.response?.status || 502, error.response?.data?.error?.message || "Falha ao consultar o proxy SGP.", "upstream-error");
    }
    throw error;
  }
}
