import { Router } from "express";
import { canAccessProvider, verifyToken, verifyAdmin } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { firestore, serverTimestamp, firebaseAuth } from "../services/firebaseAdmin";
import { recordAdminAudit } from "../services/auditService";

import { parseProviderInput, publicProviderData, parsePrivateIntegration } from "../services/providerConfig";

export const providersRouter = Router();
providersRouter.use(verifyToken, verifyAdmin);

function serialize(id: string, input: FirebaseFirestore.DocumentData) {
  const data = { ...input };
  for (const key of ["createdAt", "updatedAt"]) {
    if (data[key]?.toDate) data[key] = data[key].toDate().toISOString();
  }
  delete data.integrations;
  if (data.config && typeof data.config === "object" && !Array.isArray(data.config)) {
    data.config = { ...data.config };
    delete data.config.integrations;
  }
  return { ...publicProviderData(data), id };
}

providersRouter.get("/", asyncRoute(async (req, res) => {
  if (req.user?.superAdmin === true) {
    const snapshot = await firestore.collection("provedores").get();
    return res.json({ data: snapshot.docs.map((provider) => serialize(provider.id, provider.data())) });
  }
  const providerId = typeof req.user?.providerId === "string" ? req.user.providerId : "";
  if (!providerId) throw new ApiError(403, "Sem permissão para listar provedores.", "permission-denied");
  const provider = await firestore.collection("provedores").doc(providerId).get();
  return res.json({ data: provider.exists ? [serialize(provider.id, provider.data() || {})] : [] });
}));

providersRouter.post("/", asyncRoute(async (req, res) => {
  if (!req.body || typeof req.body !== "object" || Array.isArray(req.body) ||
      (req.body.id !== undefined && typeof req.body.id !== "string")) {
    throw new ApiError(400, "Configuração inválida.", "invalid-argument");
  }
  const id = typeof req.body?.id === "string" ? req.body.id.trim() : "";
  if (!id && req.user?.superAdmin !== true) throw new ApiError(403, "Apenas Super Admin pode criar provedores.", "permission-denied");
  if (id && !canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão para alterar este provedor.", "permission-denied");
  if (id && !/^[a-z0-9_-]+$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");

  const { id: _id, ...input } = req.body;
  let data: Record<string, unknown>;
  try { data = parseProviderInput(input, req.user?.superAdmin === true); }
  catch { throw new ApiError(400, "Configuração inválida ou campo não permitido.", "invalid-argument"); }
  data.updatedAt = serverTimestamp();
  if (id) {
    await firestore.collection("provedores").doc(id).set(data, { merge: true });
    await recordAdminAudit({ type: "UPDATE_PROVIDER", requesterUid: req.user!.uid, providerId: id, correlationId: req.correlationId, payload: data });
    return res.json({ success: true, id });
  }
  data.createdAt = serverTimestamp();
  const provider = await firestore.collection("provedores").add(data);
  await recordAdminAudit({ type: "CREATE_PROVIDER", requesterUid: req.user!.uid, providerId: provider.id, correlationId: req.correlationId, payload: data });
  return res.status(201).json({ success: true, id: provider.id });
}));

providersRouter.post("/:providerId/integration", asyncRoute(async (req, res) => {
  if (req.user?.superAdmin !== true) throw new ApiError(403, "Apenas SaaS pode substituir integração.", "permission-denied");
  const token = req.headers.authorization?.slice(7) || "";
  let current;
  try {
    const verified = await firebaseAuth.verifyIdToken(token, true);
    current = await firebaseAuth.getUser(verified.uid);
    if (current.disabled || current.customClaims?.superAdmin !== true || !verified.auth_time || Date.now() / 1000 - verified.auth_time > 300) throw new Error("reauthentication");
  } catch { throw new ApiError(403, "Autentique-se novamente para substituir a integração.", "permission-denied"); }
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]+$/i.test(id)) throw new ApiError(400, "ID inválido.", "invalid-argument");
  let integrations: Record<string, string>;
  try { integrations = parsePrivateIntegration(req.body); }
  catch { throw new ApiError(400, "Integração inválida.", "invalid-argument"); }
  const provider = firestore.collection("provedores").doc(id);
  if (!(await provider.get()).exists) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  await provider.collection("secrets").doc("sgp").set({ integrations }, { merge: true });
  await recordAdminAudit({ type: "REPLACE_PROVIDER_INTEGRATION", requesterUid: req.user!.uid, providerId: id, payload: { replaced: true } });
  res.json({ success: true });
}));
