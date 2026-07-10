import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db, storage } from "../app/firebase";
import { requireProviderAccess } from "../app/permissions";

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
    const message = error instanceof Error ? error.message : "Falha ao enviar a imagem.";
    logger.error("Logo upload failed", { providerId, requesterUid: request.auth.uid, error: message });
    if (message.toLowerCase().includes("permiss")) throw new HttpsError("permission-denied", message);
    throw new HttpsError("internal", message);
  }
});
