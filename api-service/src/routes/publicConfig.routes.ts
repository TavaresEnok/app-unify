import { Router } from "express";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { publicConfigLimiter } from "../middlewares/rateLimits";
import { firestore } from "../services/firebaseAdmin";
import { publicProviderData } from "../services/providerConfig";
import { publicConfigCache } from "../services/publicConfigCache";

// O app do assinante carrega marca/menus antes do login. As regras do Firestore
// só liberam a projeção plana de marca, então a configuração rica sai daqui,
// pela mesma lista permitida do backend: nada de integração, token ou destino SGP.
export const publicConfigRouter = Router();

export function clearPublicConfigCache() { publicConfigCache.clear(); }

async function loadPublicConfig(providerId: string) {
  return publicConfigCache.get(providerId, async () => {
    const doc = await firestore.collection("provedores").doc(providerId).get();
    return doc.exists ? { ...publicProviderData(doc.data() || {}), id: providerId } : null;
  });
}

publicConfigRouter.get("/providers/:providerId/config", publicConfigLimiter, asyncRoute(async (req, res) => {
  const providerId = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(providerId)) throw new ApiError(400, "Provedor inválido.", "invalid-argument");
  const data = await loadPublicConfig(providerId);
  if (!data) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  res.set("Cache-Control", "public, max-age=30");
  res.json({ data });
}));
