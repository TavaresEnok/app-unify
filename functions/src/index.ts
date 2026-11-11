import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { createRequestRouter } from "./app/requestRouter";
import { proxySecretParam, proxyUrlSecret } from "./app/config";
import { cleanupCompletedRequests, recoverRequests } from "./app/requestRecovery";
import { handlers } from "./handlers";

export { uploadProviderLogo } from "./callables/uploadProviderLogo";
export { generateApk } from "./callables/generateApk";

const routeRequest = createRequestRouter(handlers);

export const handleFunctionRequest = onDocumentCreated({
  document: "function_requests/{requestId}",
  retry: true,
  region: "southamerica-east1",
  maxInstances: 10,
  concurrency: 20,
  timeoutSeconds: 540,
  memory: "512MiB",
  secrets: [proxyUrlSecret, proxySecretParam],
}, async (event) => {
  await routeRequest(event.params.requestId, event.data?.data());
});

export const recoverFunctionRequests = onSchedule({
  schedule: "every 5 minutes",
  region: "southamerica-east1",
  timeoutSeconds: 540,
  maxInstances: 1,
  secrets: [proxyUrlSecret, proxySecretParam],
}, async () => {
  await recoverRequests(routeRequest);
});

export const cleanupFunctionDocuments = onSchedule({
  schedule: "every day 03:00",
  region: "southamerica-east1",
  timeZone: "America/Sao_Paulo",
}, async () => {
  await cleanupCompletedRequests();
});
