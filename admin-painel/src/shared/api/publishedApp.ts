import { publicDownloadUrl } from "@/shared/config/runtime";

export function applicationDownloadPath(provider: Record<string, unknown>): string | null {
  const details = provider.details as Record<string, unknown> | undefined;
  const name = details?.appName || provider.name;
  if (typeof name !== "string" || !name.trim()) return null;
  return publicDownloadUrl(`/public_apks/app_${name.replace(/[^a-zA-Z0-9]/g, "_")}.apk`);
}

export function externalHttpsUrl(value: unknown): string | null {
  if (typeof value !== "string" || !value) return null;
  try {
    const url = new URL(value);
    return url.protocol === "https:" && !url.username && !url.password ? url.href : null;
  } catch { return null; }
}

export async function checkPublishedApp(url: string, signal: AbortSignal): Promise<boolean> {
  const response = await fetch(url, { method: "HEAD", cache: "no-store", signal });
  if (response.status === 404) return false;
  if (!response.ok) throw new Error("Não foi possível verificar o arquivo publicado.");
  // O servidor pode responder com o HTML da aplicação quando o arquivo não existe.
  const type = response.headers.get("content-type")?.split(";")[0].trim();
  return type === "application/vnd.android.package-archive" || type === "application/octet-stream";
}
