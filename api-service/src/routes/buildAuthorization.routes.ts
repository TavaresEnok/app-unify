import { Router } from "express";
import { requirePgPool } from "../services/postgres";
import { getProviderRow } from "../services/providersStore";
import { verifyLiveSession } from "../services/self-auth";

export const buildAuthorizationRouter = Router();
const accepted = new Map<string, { uid: string; providerId: string; until: number }>();

const DENIED_CODES = new Set([
  "auth/id-token-revoked",
  "auth/id-token-expired",
  "auth/invalid-id-token",
  "auth/argument-error",
  "auth/user-disabled",
  "auth/user-not-found",
  "access/scope-changed",
  "access/identity-conflict",
]);

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
    const pool = requirePgPool();
    const identity = await verifyLiveSession(pool, header.slice(7).trim());
    const now = Math.floor(Date.now() / 1000);
    if (identity.superAdmin !== true ||
        ["subscriber", "providerAdmin", "client"].includes(identity.role) ||
        typeof identity.auth_time !== "number" || identity.auth_time > now + 30 ||
        (["request", "spawn"].includes(purpose) && now - identity.auth_time > 300)) {
      throw new Error("denied");
    }
    const tenant = await getProviderRow(pool, providerId);
    if (!tenant || tenant.active === false) throw new Error("denied");

    for (const [key, value] of accepted) if (value.until < now) accepted.delete(key);
    if (purpose === "request") {
      if (accepted.size >= 10000 && !accepted.has(jobId)) throw new Error("denied");
      const previous = accepted.get(jobId);
      if (previous && (previous.uid !== identity.uid || previous.providerId !== providerId)) throw new Error("denied");
      accepted.set(jobId, { uid: identity.uid, providerId, until: now + 1800 });
    } else if (["spawn", "publish"].includes(purpose)) {
      const proof = accepted.get(jobId);
      if (!proof || proof.uid !== identity.uid || proof.providerId !== providerId) throw new Error("denied");
    }
    res.json({ authorized: true, uid: identity.uid, providerId, jobId, purpose });
  } catch (error) {
    const code = (error as { code?: string }).code || "";
    const denied = (error instanceof Error && error.message === "denied") || DENIED_CODES.has(code);
    res.status(denied ? 403 : 503).json({ success: false, error: denied ? "build-authorization-denied" : "authorization-unavailable" });
  }
});
