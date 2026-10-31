import { HttpsError, onCall } from "firebase-functions/v2/https";
import { apkBuilderUrl } from "../app/config";

export async function forwardGenerateApk(request: any) {
  const endpoint = apkBuilderUrl.value();
  const bearer = request.rawRequest?.headers?.authorization;
  if (!request.auth || typeof bearer !== "string" || !bearer.startsWith("Bearer ")) {
    throw new HttpsError("permission-denied", "Autenticação obrigatória.");
  }
  // Fixed backend configuration only. No Python, signing or fallback in Functions.
  if (!endpoint) throw new HttpsError("failed-precondition", "Gerador de aplicativo não configurado.");
  let url: URL;
  try { url = new URL(endpoint); }
  catch { throw new HttpsError("failed-precondition", "Gerador de aplicativo não configurado."); }
  if (url.protocol !== "https:" || url.username || url.password || url.search || url.hash) {
    throw new HttpsError("failed-precondition", "Gerador de aplicativo não configurado.");
  }
  try {
    const { providerId, appName, logoUrl, format } = request.data || {};
    const response = await fetch(new URL("generate-apk", url.href.replace(/\/?$/, "/")), {
      method: "POST", redirect: "error", signal: AbortSignal.timeout(30_000),
      headers: { Authorization: bearer, "Content-Type": "application/json" },
      body: JSON.stringify({ providerId, appName, logoUrl, format, async: true }),
    });
    if (!response.ok) throw new HttpsError(response.status === 503 ? "unavailable" : response.status === 403 || response.status === 401 ? "permission-denied" : "failed-precondition", response.status === 503 ? "authorization-unavailable" : "Geração não autorizada ou indisponível.");
    const result = await response.json();
    return { success: result.success, jobId: result.jobId, status: result.status };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("unavailable", "Gerador indisponível.");
  }
}
export const generateApk = onCall({ timeoutSeconds: 60, memory: "256MiB", region: "southamerica-east1" }, forwardGenerateApk);
