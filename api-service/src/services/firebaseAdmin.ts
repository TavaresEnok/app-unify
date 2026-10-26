import * as admin from "firebase-admin";
import fs from "node:fs";

const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (credentialsPath && !fs.existsSync(credentialsPath)) {
  throw new Error(`Firebase credentials file not found: ${credentialsPath}`);
}

if (!admin.apps.length) {
  admin.initializeApp({ projectId: process.env.GOOGLE_CLOUD_PROJECT || undefined });
}

export const firebaseAuth = admin.auth();
export const firestore = admin.firestore();
export const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;
export { admin };
