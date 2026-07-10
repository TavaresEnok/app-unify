import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();

export const firebaseAuth = admin.auth();
export const firestore = admin.firestore();
export const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;
export { admin };
