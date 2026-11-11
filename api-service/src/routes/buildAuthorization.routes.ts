import { Router } from "express";
import { firebaseAuth, firestore } from "../services/firebaseAdmin";

// This endpoint is the only authority used by the credential-free builder.
// Never accept identity, role or tenant membership supplied by the caller.
export const buildAuthorizationRouter = Router();
// Only bindings are retained, never bearer tokens. API restart also fails closed.
const accepted = new Map<string, { uid: string; providerId: string; until: number }>();
buildAuthorizationRouter.post("/authorize", async (req, res) => {
  const { providerId, jobId, purpose } = req.body || {};
  if (typeof providerId !== "string" || !/^[a-z0-9_-]{1,64}$/i.test(providerId) ||
      typeof jobId !== "string" || !/^[a-zA-Z0-9_-]{1,100}$/.test(jobId) ||
      !["request", "spawn", "publish", "poll"].includes(purpose)) {
    res.status(400).json({ success: false, error: "invalid-argument" }); return;
  }
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith("Bearer ")) throw new Error("denied");
    const token = await firebaseAuth.verifyIdToken(header.slice(7), true);
    const current = await firebaseAuth.getUser(token.uid);
    const now = Math.floor(Date.now() / 1000);
    if (current.disabled || token.superAdmin !== true || current.customClaims?.superAdmin !== true ||
        ["subscriber", "providerAdmin"].includes(token.role) || ["subscriber", "providerAdmin"].includes(current.customClaims?.role) ||
        typeof token.auth_time !== "number" || token.auth_time > now + 30 ||
        (["request", "spawn"].includes(purpose) && now - token.auth_time > 300)) throw new Error("denied");
    // SaaS has global tenant scope; existence and active state are server data.
    const tenant = await firestore.collection("provedores").doc(providerId).get();
    if (!tenant.exists || tenant.data()?.active === false) throw new Error("denied");
    for (const [key, value] of accepted) if (value.until < now) accepted.delete(key);
    if (purpose === "request") {
      if (accepted.size >= 10000 && !accepted.has(jobId)) throw new Error("denied");
      const previous = accepted.get(jobId);
      if (previous && (previous.uid !== current.uid || previous.providerId !== providerId)) throw new Error("denied");
      accepted.set(jobId, { uid: current.uid, providerId, until: now + 1800 });
    } else if (["spawn", "publish"].includes(purpose)) {
      const proof = accepted.get(jobId);
      if (!proof || proof.uid !== current.uid || proof.providerId !== providerId) throw new Error("denied");
    }
    res.json({ authorized: true, uid: current.uid, providerId, jobId, purpose });
  } catch (error) {
    const denied = (error instanceof Error && error.message === "denied") ||
      ["auth/id-token-revoked", "auth/id-token-expired", "auth/invalid-id-token", "auth/argument-error", "auth/user-disabled", "auth/user-not-found"].includes((error as { code: string }).code);
    res.status(denied ? 403 : 503).json({ success: false, error: denied ? "build-authorization-denied" : "authorization-unavailable" });
  }
});
