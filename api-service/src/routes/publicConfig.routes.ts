import { Router } from "express";
import fs from "node:fs/promises";
import path from "node:path";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { publicConfigLimiter } from "../middlewares/rateLimits";
import { requirePgPool } from "../services/postgres";
import { getProviderRow, serializeProviderRow } from "../services/providersStore";
import { publicConfigCache } from "../services/publicConfigCache";
import { dataDeletionHtml, privacyPolicyHtml, publicConfigExtras } from "../services/privacyPages";

// O app do assinante carrega marca/menus antes do login pelo PostgreSQL + cache em memória.
export const publicConfigRouter = Router();

export function clearPublicConfigCache() { publicConfigCache.clear(); }

function uploadsPublicDir(): string {
  return path.join(process.env.UPLOADS_DIR?.trim() || "/srv/uploads", "public");
}

function assetMime(filename: string): string {
  if (filename.endsWith(".png")) return "image/png";
  if (filename.endsWith(".webp")) return "image/webp";
  return "image/jpeg";
}

async function loadPublicConfig(providerId: string) {
  return publicConfigCache.get(providerId, async () => {
    const row = await getProviderRow(requirePgPool(), providerId);
    if (!row) return null;
    const data = serializeProviderRow(row);
    const extras = publicConfigExtras(providerId, data);
    const out: Record<string, unknown> = { ...data, ...extras };
    // appVersion só vai ao app normalizado (sem minVersion quando não força).
    if (!extras.appVersion) delete out.appVersion;
    return out;
  });
}

const PAGE_HEADERS = {
  "Content-Type": "text/html; charset=utf-8",
  "Cache-Control": "public, max-age=300",
  "X-Content-Type-Options": "nosniff",
  "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; img-src https: data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  "Referrer-Policy": "no-referrer",
};

function updatedLabel(data: Record<string, unknown>): string {
  const raw = typeof data.updatedAt === "string" ? data.updatedAt : "";
  const date = raw ? new Date(raw) : new Date();
  const valid = Number.isFinite(date.getTime()) ? date : new Date();
  return new Intl.DateTimeFormat("pt-BR", { timeZone: "America/Fortaleza", day: "2-digit", month: "2-digit", year: "numeric" }).format(valid);
}

for (const [slug, render] of [["privacidade", privacyPolicyHtml], ["exclusao-de-dados", dataDeletionHtml]] as const) {
  publicConfigRouter.get(`/providers/:providerId/${slug}`, publicConfigLimiter, asyncRoute(async (req, res) => {
    const providerId = String(req.params.providerId || "");
    if (!/^[a-z0-9_-]{1,64}$/i.test(providerId)) throw new ApiError(400, "Provedor inválido.", "invalid-argument");
    const data = await loadPublicConfig(providerId);
    if (!data) throw new ApiError(404, "Provedor não encontrado.", "not-found");
    res.set(PAGE_HEADERS);
    res.send(render(providerId, data, updatedLabel(data)));
  }));
}

publicConfigRouter.get("/providers/:providerId/config", publicConfigLimiter, asyncRoute(async (req, res) => {
  const providerId = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(providerId)) throw new ApiError(400, "Provedor inválido.", "invalid-argument");
  const data = await loadPublicConfig(providerId);
  if (!data) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  res.set("Cache-Control", "public, max-age=30");
  res.json({ data });
}));

publicConfigRouter.get("/assets/:providerId/:filename", asyncRoute(async (req, res) => {
  const providerId = String(req.params.providerId || "");
  const filename = String(req.params.filename || "");
  if (!/^[a-z0-9_-]{1,64}$/i.test(providerId) || !/^[a-z0-9_-]{1,96}\.(?:png|jpe?g|webp)$/i.test(filename)) {
    throw new ApiError(400, "Asset inválido.", "invalid-argument");
  }
  const baseDir = path.resolve(uploadsPublicDir(), providerId);
  const fullPath = path.resolve(baseDir, filename);
  if (!fullPath.startsWith(`${baseDir}${path.sep}`)) {
    throw new ApiError(400, "Caminho inválido.", "invalid-argument");
  }
  let bytes: Buffer;
  try {
    bytes = await fs.readFile(fullPath);
  } catch {
    throw new ApiError(404, "Asset não encontrado.", "not-found");
  }
  res.set({
    "Content-Type": assetMime(filename.toLowerCase()),
    "X-Content-Type-Options": "nosniff",
    "Cache-Control": "public, max-age=86400",
  });
  res.send(bytes);
}));
