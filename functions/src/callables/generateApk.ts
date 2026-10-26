import { spawn } from "node:child_process";
import { promises as fs } from "node:fs";
import { lookup } from "node:dns/promises";
import * as os from "node:os";
import * as path from "node:path";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { apkProjectRoot, apkScriptPath } from "../app/config";
import { recordAudit } from "../app/audit";

function isPrivateIpv4(ip: string): boolean {
  const m = ip.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (!m) return false;
  const [a, b] = m.slice(1).map(Number);
  return a === 10 || a === 127 || a === 0 ||
    (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) ||
    (a === 169 && b === 254) || (a === 100 && b >= 64 && b <= 127) || a >= 224;
}

async function assertPublicHttpsUrl(url: string): Promise<URL> {
  const parsed = new URL(url);
  if (parsed.protocol !== "https:") throw new HttpsError("invalid-argument", "A logo deve usar HTTPS.");
  const host = parsed.hostname.toLowerCase();
  if (host === "localhost" || host.endsWith(".localhost")) throw new HttpsError("invalid-argument", "URL da logo não permitida.");
  const resolved = await lookup(host, { all: true }).catch(() => [] as { address: string }[]);
  if (!resolved.length) throw new HttpsError("invalid-argument", "URL da logo não pôde ser resolvida.");
  for (const { address } of resolved) {
    if (isPrivateIpv4(address)) throw new HttpsError("invalid-argument", "URL da logo aponta para rede interna.");
  }
  return parsed;
}

async function downloadLogo(url: string, target: string): Promise<void> {
  const parsed = await assertPublicHttpsUrl(url);
  // redirect: "manual" — um redirecionamento para http://169.254.169.254 ou host
  // interno NÃO é seguido (SSRF). Recusamos qualquer resposta de redirect.
  const response = await fetch(parsed, { redirect: "manual" });
  if (response.type === "opaqueredirect" || (response.status >= 300 && response.status < 400)) {
    throw new HttpsError("invalid-argument", "Redirecionamentos não são permitidos para a logo.");
  }
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
  // Impede injeção de argumento no gerador Python: um appName iniciando com "-"
  // poderia ser interpretado como flag (ex.: --nome "--help").
  if (appName.length > 100 || /^-/.test(appName) || /[\r\n\t\0]/.test(appName)) {
    throw new HttpsError("invalid-argument", "Nome do aplicativo inválido.");
  }

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
    // Não expõe stderr/detalhes internos do subprocesso ao cliente (M5/M6).
    throw new HttpsError("internal", "Falha ao gerar o aplicativo. Consulte os logs do servidor.");
  } finally {
    await fs.unlink(logoPath).catch(() => undefined);
  }
});
