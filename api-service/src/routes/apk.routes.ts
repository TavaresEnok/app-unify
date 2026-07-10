import { Router } from "express";
import { verifySuperAdmin } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { apkLimiter } from "../middlewares/rateLimits";
import { generateApplication } from "../services/apkService";
import { recordAdminAudit } from "../services/auditService";

export const apkRouter = Router();

apkRouter.post("/generate-apk", apkLimiter, verifySuperAdmin, asyncRoute(async (req, res) => {
  const providerId = typeof req.body?.providerId === "string" ? req.body.providerId.trim() : "";
  const appName = typeof req.body?.appName === "string" ? req.body.appName.trim() : "";
  const logoUrl = typeof req.body?.logoUrl === "string" ? req.body.logoUrl.trim() : "";
  const format = req.body?.format === "aab" ? "aab" : "apk";
  if (!providerId || !appName || !logoUrl) throw new ApiError(400, "ProviderID, nome e logo são obrigatórios.", "invalid-argument");
  const result = await generateApplication({ providerId, appName, logoUrl, format });
  await recordAdminAudit({ type: "GENERATE_APK", requesterUid: req.user!.uid, providerId, correlationId: req.correlationId, payload: { appName, format } });
  res.json(result);
}));
