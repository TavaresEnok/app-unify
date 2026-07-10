import { Router } from "express";
import { canAccessProvider, verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { firestore, serverTimestamp } from "../services/firebaseAdmin";
import { recordAdminAudit } from "../services/auditService";

export const providersRouter = Router();
providersRouter.use(verifyToken);

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
  return { id, ...data };
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
  const id = typeof req.body?.id === "string" ? req.body.id.trim() : "";
  if (!id && req.user?.superAdmin !== true) throw new ApiError(403, "Apenas Super Admin pode criar provedores.", "permission-denied");
  if (id && !canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão para alterar este provedor.", "permission-denied");
  if (id && !/^[a-z0-9_-]+$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");

  const data = { ...req.body };
  delete data.id;
  delete data.integrations;
  delete data.apiToken;
  delete data.token;
  delete data.password;
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
