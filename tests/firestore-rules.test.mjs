import { readFile } from "node:fs/promises";
import { after, before, beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { deleteObject, getBytes, ref, uploadBytes } from "firebase/storage";

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: process.env.GCLOUD_PROJECT || "app-ajust-provedor",
    firestore: { rules: await readFile("firestore.rules", "utf8") },
    storage: { rules: await readFile("storage.rules", "utf8") },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "provedores", "alpha"), { name: "Alpha", details: { systemUrl: "https://sgp.example" } });
    await setDoc(doc(db, "provedores", "alpha", "secrets", "sgp"), { integrations: { apiToken: "secret" } });
    await setDoc(doc(db, "provedores", "alpha", "backups", "old"), { secrets: { apiToken: "secret" } });
    await setDoc(doc(db, "notifications", "alpha-notification"), { providerId: "alpha", title: "A" });
    await setDoc(doc(db, "notifications", "beta-notification"), { providerId: "beta", title: "B" });
    await setDoc(doc(db, "audit_logs", "entry"), { type: "DELETE_PROVIDER" });
    await setDoc(doc(db, "clientes", "client-alpha"), { providerId: "alpha", authUid: "client-alpha" });
    await uploadBytes(ref(context.storage(), "providers/alpha/logo.png"), new Uint8Array([1, 2, 3]), { contentType: "image/png" });
  });
});

after(async () => {
  await environment.cleanup();
});

test("provider public config is readable but secrets are restricted", async () => {
  const anonymous = environment.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(anonymous, "provedores", "alpha")));
  await assertFails(getDoc(doc(anonymous, "provedores", "alpha", "secrets", "sgp")));
  const admin = environment.authenticatedContext("admin-alpha", { providerId: "alpha", role: "providerAdmin" }).firestore();
  await assertFails(getDoc(doc(admin, "provedores", "alpha", "secrets", "sgp")));
  await assertFails(setDoc(doc(admin, "provedores", "alpha", "secrets", "sgp"), { integrations: {} }));
  await assertFails(getDoc(doc(admin, "provedores", "alpha", "backups", "old")));
  await assertFails(setDoc(doc(admin, "provedores", "alpha", "backups", "old"), { providerData: {} }));
  await assertFails(setDoc(doc(admin, "provedores", "alpha"), { sgpBaseUrl: "https://attacker.example" }, { merge: true }));
  await assertFails(setDoc(doc(admin, "provedores", "alpha"), { details: { systemUrl: "https://attacker.example" } }, { merge: true }));
  await assertFails(setDoc(doc(admin, "provedores", "alpha"), { name: "replacement" }));
  await assertSucceeds(setDoc(doc(admin, "provedores", "alpha"), { themeColor: "#ffffff" }, { merge: true }));
  const root = environment.authenticatedContext("root", { superAdmin: true }).firestore();
  await assertSucceeds(getDoc(doc(root, "provedores", "alpha", "secrets", "sgp")));
  await assertFails(getDoc(doc(root, "provedores", "alpha", "backups", "old")));
  await assertFails(setDoc(doc(admin, "provedores", "alpha"), {
    integrations: { apiToken: "must-not-be-public" },
  }, { merge: true }));
  for (const data of [{ details: { apiToken: "private" } }, { config: { password: "private" } }, { token: "private" }]) {
    await assertFails(setDoc(doc(admin, "provedores", "alpha"), data, { merge: true }));
  }
});

test("function request creation is bound to the authenticated uid", async () => {
  const db = environment.authenticatedContext("requester", { role: "providerAdmin", providerId: "alpha" }).firestore();
  await assertSucceeds(setDoc(doc(db, "function_requests", "valid"), {
    type: "GET_DASHBOARD_DATA",
    requesterUid: "requester",
    payload: {},
  }));
  await assertFails(setDoc(doc(db, "function_requests", "spoofed"), {
    type: "GET_DASHBOARD_DATA",
    requesterUid: "another-user",
    payload: {},
  }));
  // Forja de identidade: requesterUid de topo aponta para uma vítima (ex.: um
  // super admin) enquanto o payload satisfaz a regra pelo próprio uid. Deve
  // falhar — o topo é a identidade canônica usada na autorização.
  await assertFails(setDoc(doc(db, "function_requests", "forged"), {
    type: "SET_SUPER_ADMIN_BY_EMAIL",
    requesterUid: "victim-super-admin",
    payload: { requesterUid: "requester", email: "attacker@example.com" },
  }));
});

test("notifications and audits remain tenant scoped", async () => {
  const alpha = environment.authenticatedContext("admin-alpha", { providerId: "alpha", role: "providerAdmin" }).firestore();
  await assertSucceeds(getDoc(doc(alpha, "notifications", "alpha-notification")));
  await assertFails(getDoc(doc(alpha, "notifications", "beta-notification")));
  await assertFails(getDoc(doc(alpha, "audit_logs", "entry")));
  const superAdmin = environment.authenticatedContext("root", { superAdmin: true }).firestore();
  const audit = await assertSucceeds(getDoc(doc(superAdmin, "audit_logs", "entry")));
  assert.equal(audit.exists(), true);
});

test("storage keeps public assets readable and ticket attachments private", async () => {
  const anonymous = environment.unauthenticatedContext().storage();
  await assertSucceeds(getBytes(ref(anonymous, "providers/alpha/logo.png")));
  const client = environment.authenticatedContext("client-alpha", { role: "subscriber", providerId: "alpha", cpfCnpj: "12345678901" }).storage();
  await assertSucceeds(uploadBytes(
    ref(client, "providers/alpha/ticket_attachments/evidence.png"),
    new Uint8Array([1, 2, 3]),
    { contentType: "image/png" },
  ));
  await assertFails(getBytes(ref(anonymous, "providers/alpha/ticket_attachments/evidence.png")));
  await assertFails(uploadBytes(
    ref(anonymous, "providers/alpha/public_assets/banner.png"),
    new Uint8Array([1, 2, 3]),
    { contentType: "image/png" },
  ));
  const admin = environment.authenticatedContext("admin-alpha", { providerId: "alpha", role: "providerAdmin" }).storage();
  await assertSucceeds(deleteObject(ref(admin, "providers/alpha/logo.png")));
});


test("subscriber and legacy tenant claims cannot grant administration", async () => {
  for (const claims of [{ providerId: "alpha" }, { providerId: "alpha", role: "subscriber", cpfCnpj: "12345678901" }]) {
    const db = environment.authenticatedContext("subscriber", claims).firestore();
    await assertFails(getDoc(doc(db, "provedores", "alpha", "secrets", "sgp")));
    await assertFails(setDoc(doc(db, "provedores", "alpha"), { name: "forged" }, { merge: true }));
    await assertFails(getDoc(doc(db, "clientes", "client-alpha")));
    await assertFails(setDoc(doc(db, "provedores", "alpha", "incidents", "forged"), { active: true }));
  }
});


test("subscriber cannot submit administrative queue work", async () => {
  const db = environment.authenticatedContext("subscriber", { role: "subscriber", providerId: "alpha", cpfCnpj: "12345678901" }).firestore();
  await assertFails(setDoc(doc(db, "function_requests", "subscriber-admin"), { type: "UPDATE_PROVIDER_CONFIG", requesterUid: "subscriber", payload: { providerId: "alpha" } }));
  await assertSucceeds(setDoc(doc(db, "function_requests", "subscriber-ticket"), { type: "CREATE_TICKET", requesterUid: "subscriber", payload: { providerId: "alpha" } }));
});
