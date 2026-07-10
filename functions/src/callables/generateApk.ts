import { spawn } from "node:child_process";
import { promises as fs } from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { apkProjectRoot, apkScriptPath } from "../app/config";
import { recordAudit } from "../app/audit";

async function downloadLogo(url: string, target: string): Promise<void> {
  const parsed = new URL(url);
  if (parsed.protocol !== "https:") throw new HttpsError("invalid-argument", "A logo deve usar HTTPS.");
  const response = await fetch(parsed, { redirect: "follow" });
  if (!response.ok) throw new HttpsError("invalid-argument", "Não foi possível baixar a logo.");
  const buffer = Buffer.from(await response.arrayBuffer());
  if (!buffer.length || buffer.length > 5 * 1024 * 1024) throw new HttpsError("invalid-argument", "Logo inválida ou maior que 5 MB.");
  await fs.writeFile(target, buffer);
}

export const generateApk = onCall({
  timeoutSeconds: 540,
  memory: "512MiB",
  region: "southamerica-east1",
}, async (request) => {
  if (!request.auth?.token.superAdmin) throw new HttpsError("permission-denied", "Apenas Super Admin pode gerar aplicativos.");
  const providerId = typeof request.data?.providerId === "string" ? request.data.providerId : "";
  const appName = typeof request.data?.appName === "string" ? request.data.appName : "";
  const logoUrl = typeof request.data?.logoUrl === "string" ? request.data.logoUrl : "";
  const format = request.data?.format === "aab" ? "aab" : "apk";
  if (!providerId || !appName || !logoUrl) throw new HttpsError("invalid-argument", "ProviderID, nome e logo são obrigatórios.");
  if (!/^[a-z0-9_-]+$/i.test(providerId)) throw new HttpsError("invalid-argument", "ProviderID inválido.");

  const script = apkScriptPath.value();
  const root = apkProjectRoot.value();
  if (!script || !root) throw new HttpsError("failed-precondition", "Gerador de aplicativo não configurado.");
  const logoPath = path.join(os.tmpdir(), `unify-logo-${providerId}-${Date.now()}.png`);

  try {
    await downloadLogo(logoUrl, logoPath);
    const packageName = `br.com.provedores.${providerId.replace(/[^a-z0-9]/gi, "").toLowerCase()}`;
    const args = [script, "--id", providerId, "--nome", appName, "--logo", logoPath, "--package", packageName];
    if (format === "aab") args.push("--format", "aab", "--obfuscate");

    const logs = await new Promise<string>((resolve, reject) => {
      const process = spawn("python3", args, { cwd: root });
      let stdout = "";
      let stderr = "";
      process.stdout.on("data", (chunk) => { stdout += String(chunk); });
      process.stderr.on("data", (chunk) => { stderr += String(chunk); });
      process.on("error", reject);
      process.on("close", (code) => code === 0 ? resolve(stdout) : reject(new Error(`Gerador encerrou com código ${code}: ${stderr.slice(-2000)}`)));
    });
    await recordAudit({
      requestId: `callable-generate-apk-${Date.now()}`,
      type: "GENERATE_APK",
      requesterUid: request.auth.uid,
      providerId,
      payload: { appName, format },
      outcome: "success",
    }).catch((error) => logger.error("Audit write failed", { providerId, error: String(error) }));
    return { success: true, message: "Aplicativo gerado com sucesso.", logs };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Falha ao gerar aplicativo.";
    logger.error("APK generation failed", { providerId, requesterUid: request.auth.uid, error: message });
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", message);
  } finally {
    await fs.unlink(logoPath).catch(() => undefined);
  }
});
