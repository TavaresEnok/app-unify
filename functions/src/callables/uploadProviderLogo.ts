import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { auth, db, storage } from "../app/firebase";
import { requireProviderAccess, requireSession } from "../app/permissions";
import { AppError } from "../app/errors";

const MAX_LOGO_BYTES = 5 * 1024 * 1024;

export const uploadProviderLogo = onCall({
  region: "southamerica-east1",
  maxInstances: 10,
}, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Utilizador não autenticado.");
  const providerId = typeof request.data?.providerId === "string" ? request.data.providerId : "";
  const imageBase64 = typeof request.data?.imageBase64 === "string" ? request.data.imageBase64 : "";
  if (!providerId || !imageBase64) throw new HttpsError("invalid-argument", "Imagem e ProviderID são obrigatórios.");

  try {
    const bearer = request.rawRequest?.headers.authorization;
    if (typeof bearer !== "string" || !bearer.startsWith("Bearer ")) throw new HttpsError("unauthenticated", "Sessão obrigatória.");
    let token;
    try { token = await auth.verifyIdToken(bearer.slice(7), true); }
    catch (error) {
      const denied = ["auth/id-token-revoked", "auth/id-token-expired", "auth/invalid-id-token", "auth/argument-error", "auth/user-disabled", "auth/user-not-found"].includes((error as { code: string }).code);
      throw new HttpsError(denied ? "unauthenticated" : "unavailable", denied ? "Sessão inválida." : "authorization-unavailable");
    }
    if (token.uid !== request.auth.uid) throw new HttpsError("unauthenticated", "Sessão divergente.");
    await requireSession(token.uid, { authTime: token.auth_time, issuedAt: token.iat,
      role: token.role || "", providerId: token.providerId || "", superAdmin: token.superAdmin === true });
    await requireProviderAccess(request.auth.uid, providerId);
    const match = imageBase64.match(/^data:image\/(png|jpeg|webp);base64,([\s\S]+)$/);
    if (!match) throw new HttpsError("invalid-argument", "Formato de imagem inválido.");
    const extension = match[1] === "jpeg" ? "jpg" : match[1];
    const buffer = Buffer.from(match[2], "base64");
    if (!buffer.length || buffer.length > MAX_LOGO_BYTES) {
      throw new HttpsError("invalid-argument", "A imagem deve ter no máximo 5 MB.");
    }

    const bucket = storage.bucket();
    const filePath = `providers/${providerId}/logo.${extension}`;
    await bucket.file(filePath).save(buffer, {
      metadata: {
        contentType: `image/${match[1]}`,
        cacheControl: "public, max-age=31536000, immutable",
      },
    });
    const url = `https://storage.googleapis.com/${bucket.name}/${filePath}`;
    await db.collection("provedores").doc(providerId).set({ logoUrl: url }, { merge: true });
    return { success: true, url };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error instanceof AppError) throw new HttpsError(error.code === "authorization-unavailable" ? "unavailable" : error.code === "unauthenticated" ? "unauthenticated" : "permission-denied", error.message);
    logger.error("Logo upload failed", { providerId, requesterUid: request.auth.uid });
    throw new HttpsError("internal", "Falha ao enviar a imagem.");
  }
});
