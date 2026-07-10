import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { createRequestRouter } from "./app/requestRouter";
import { proxySecretParam, proxyUrlSecret } from "./app/config";
import { db } from "./app/firebase";
import { handlers } from "./handlers";

export { uploadProviderLogo } from "./callables/uploadProviderLogo";
export { generateApk } from "./callables/generateApk";

const routeRequest = createRequestRouter(handlers);

export const handleFunctionRequest = onDocumentCreated({
  document: "function_requests/{requestId}",
  region: "southamerica-east1",
  timeoutSeconds: 540,
  memory: "512MiB",
  secrets: [proxyUrlSecret, proxySecretParam],
}, async (event) => {
  await routeRequest(event.params.requestId, event.data?.data());
});

export const cleanupFunctionDocuments = onSchedule({
  schedule: "every day 03:00",
  region: "southamerica-east1",
  timeZone: "America/Sao_Paulo",
}, async () => {
  const threshold = Timestamp.now();
  for (const collectionName of ["function_requests", "function_responses"] as const) {
    const field = collectionName === "function_requests" ? "createdAt" : "expiresAt";
    const cutoff = collectionName === "function_requests"
      ? Timestamp.fromMillis(Date.now() - 7 * 24 * 60 * 60 * 1000)
      : threshold;
    while (true) {
      const snapshot = await db.collection(collectionName).where(field, "<=", cutoff).limit(400).get();
      if (snapshot.empty) break;
      const batch = db.batch();
      snapshot.docs.forEach((document) => batch.delete(document.ref));
      await batch.commit();
      if (snapshot.size < 400) break;
    }
  }
  await db.collection("maintenance_logs").add({
    job: "cleanupFunctionDocuments",
    completedAt: FieldValue.serverTimestamp(),
  });
});
