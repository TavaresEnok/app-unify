function numberEnv(name: string, fallback: number): number {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function listEnv(name: string, fallback: string[]): string[] {
  const value = process.env[name];
  return value ? value.split(",").map((item) => item.trim()).filter(Boolean) : fallback;
}

export const env = {
  port: numberEnv("PORT", 9136),
  nodeEnv: process.env.NODE_ENV || "development",
  firebaseApiKey: process.env.FIREBASE_API_KEY || "",
  proxySgpUrl: (process.env.PROXY_SGP_INTERNAL_URL || "http://backend-proxy:3002").replace(/\/$/, ""),
  allowedOrigins: listEnv("ALLOWED_ORIGINS", [
    "http://localhost:5173",
    "http://localhost:8031",
    "http://127.0.0.1:8031",
  ]),
} as const;

export function environmentWarnings(): string[] {
  const warnings: string[] = [];
  if (!env.firebaseApiKey) warnings.push("FIREBASE_API_KEY ausente; login REST ficará indisponível.");
  return warnings;
}
