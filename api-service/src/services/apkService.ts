import { spawn } from "node:child_process";
import { createWriteStream, promises as fs } from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { pipeline } from "node:stream/promises";
import { Readable } from "node:stream";
import { env } from "../config/env";
import { ApiError } from "../middlewares/errorHandler";

export interface GenerateApkInput {
  providerId: string;
  appName: string;
  logoUrl: string;
  format: "apk" | "aab";
}

async function downloadLogo(url: string, output: string): Promise<void> {
  const parsed = new URL(url);
  if (parsed.protocol !== "https:") throw new ApiError(400, "A logo deve usar HTTPS.", "invalid-argument");
  const response = await fetch(parsed, { redirect: "follow" });
  if (!response.ok || !response.body) throw new ApiError(400, "Falha ao baixar logo.", "invalid-argument");
  const length = Number(response.headers.get("content-length") || 0);
  if (length > 5 * 1024 * 1024) throw new ApiError(400, "Logo maior que 5 MB.", "invalid-argument");
  await pipeline(Readable.fromWeb(response.body as any), createWriteStream(output));
  if ((await fs.stat(output)).size > 5 * 1024 * 1024) throw new ApiError(400, "Logo maior que 5 MB.", "invalid-argument");
}

export async function generateApplication(input: GenerateApkInput) {
  if (!/^[a-z0-9_-]+$/i.test(input.providerId)) throw new ApiError(400, "ProviderID inválido.", "invalid-argument");
  const tempLogo = path.join(os.tmpdir(), `unify-logo-${input.providerId}-${Date.now()}.png`);
  try {
    await downloadLogo(input.logoUrl, tempLogo);
    const packageName = `br.com.provedores.${input.providerId.replace(/[^a-z0-9]/gi, "").toLowerCase()}`;
    const args = [
      env.apkScriptPath,
      "--id", input.providerId,
      "--nome", input.appName,
      "--logo", tempLogo,
      "--output", env.apkOutputDir,
      "--flutter-project", env.apkFlutterProject,
      "--package", packageName,
    ];
    if (input.format === "aab") args.push("--format", "aab", "--obfuscate");
    const output = await new Promise<{ stdout: string; stderr: string }>((resolve, reject) => {
      const process = spawn("python3", args, { cwd: env.apkProjectRoot });
      let stdout = "";
      let stderr = "";
      process.stdout.on("data", (chunk) => { stdout += String(chunk); });
      process.stderr.on("data", (chunk) => { stderr += String(chunk); });
      process.on("error", reject);
      process.on("close", (code) => code === 0 ? resolve({ stdout, stderr }) : reject(new ApiError(500, `Gerador encerrou com código ${code}.`, "build-failed")));
    });
    const safeName = input.appName.replace(/[^a-zA-Z0-9]/g, "_");
    return {
      success: true,
      message: `${input.format.toUpperCase()} gerado!`,
      downloadUrl: `/public_apks/app_${safeName}.${input.format}`,
      logs: output.stdout,
    };
  } finally {
    await fs.unlink(tempLogo).catch(() => undefined);
  }
}
