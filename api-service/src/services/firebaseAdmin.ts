import * as admin from "firebase-admin";
import fs from "node:fs";

export type FcmMessaging = admin.messaging.Messaging;

let messagingInstance: FcmMessaging | null = null;
let initialized = false;

function initMessagingIfConfigured(): FcmMessaging | null {
  if (initialized) return messagingInstance;
  initialized = true;
  if (process.env.NODE_ENV === "test") return null;

  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS?.trim();
  if (credentialsPath && !fs.existsSync(credentialsPath)) {
    console.warn(`[WARN] Credencial FCM não encontrada em ${credentialsPath}; envio de push ficará desativado.`);
    return null;
  }
  if (!credentialsPath && !process.env.GOOGLE_CLOUD_PROJECT) {
    return null;
  }

  try {
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: process.env.GOOGLE_CLOUD_PROJECT || undefined,
      });
    }
    messagingInstance = admin.messaging();
    return messagingInstance;
  } catch (error) {
    console.warn(`[WARN] FCM indisponível: ${error instanceof Error ? error.message : String(error)}`);
    return null;
  }
}

export function getMessaging(): FcmMessaging | null {
  return initMessagingIfConfigured();
}

export const messaging = initMessagingIfConfigured();
