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
    await setDoc(doc(db, "provedores", "alpha"), { name: "Alpha" });
    await setDoc(doc(db, "provedores", "alpha", "secrets", "sgp"), { integrations: { apiToken: "secret" } });
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

test("config direct writes and all overlapping legacy secret/backup paths are closed", async () => {
  const users = [
    { role: "providerAdmin", providerId: "alpha" },
    { role: "providerAdmin", providerId: "beta" },
    { role: "subscriber", providerId: "alpha" },
    { providerId: "alpha" },
  ];
  for (const claims of users) {
    const db = environment.authenticatedContext("actor", claims).firestore();
    for (const root of ["provedores", "providers"]) {
      for (const path of ["secrets/sgp", "secrets/sgp/versions/v1", "backups/old", "backups/old/data/mixed"]) {
        await assertFails(getDoc(doc(db, root + "/alpha/" + path)));
        await assertFails(setDoc(doc(db, root + "/alpha/" + path), { token: "synthetic" }));
      }
      for (const data of [{ themeColor: "#fff" }, { active: false }, { applicationId: "br.forbidden" },
        { config: { faq: [{ question: "Q", token: "synthetic" }] } }]) {
        await assertFails(setDoc(doc(db, root, "alpha"), data, { merge: true }));
      }
    }
  }
  const provider = environment.authenticatedContext("actor", users[0]).firestore();
  await assertSucceeds(setDoc(doc(provider, "function_requests", "personalization"), {
    requesterUid: "actor", type: "UPDATE_PROVIDER_CONFIG", payload: { providerId: "alpha", config: { themeColor: "#fff" } },
  }));
  const saas = environment.authenticatedContext("saas", { superAdmin: true }).firestore();
  await assertFails(getDoc(doc(saas, "provedores/alpha/secrets/sgp")));
  await assertFails(setDoc(doc(saas, "providers/alpha"), { config: { token: "synthetic" } }));
});

test("mixed legacy public documents fail closed instead of returning integration fields", async () => {
  await environment.withSecurityRulesDisabled(async context => {
    for (const root of ["provedores", "providers"])
      await setDoc(doc(context.firestore(), root, "mixed"), { themeColor: "#fff", details: { systemUrl: "https://private.test", appName: "private-app" } });
  });
  for (const context of [environment.unauthenticatedContext(), environment.authenticatedContext("admin", { role: "providerAdmin", providerId: "mixed" })])
    for (const root of ["provedores", "providers"])
      await assertFails(getDoc(doc(context.firestore(), root, "mixed")));
});

test("legacy nested or unknown public fields fail closed at every depth", async () => {
  const mixed = [
    { faq: [{ question: "Q", apiToken: "synthetic" }] },
    { themeColor: { token: "synthetic" } },
    { config: { menuConfig: { items: { invoices: { secretReference: "synthetic" } } } } },
    { apiUrl: "https://internal.invalid" },
    { unknown: { nested: { password: "synthetic" } } },
  ];
  for (const root of ["provedores", "providers"]) {
    for (const [index, data] of mixed.entries()) {
      const path = root + "/mixed-" + index;
      await environment.withSecurityRulesDisabled(context => setDoc(doc(context.firestore(), path), data));
      for (const context of [
        environment.unauthenticatedContext(),
        environment.authenticatedContext("owner", { role: "providerAdmin", providerId: "mixed-" + index }),
      ]) await assertFails(getDoc(doc(context.firestore(), path)));
    }
  }
});

test("storage denies mixed legacy backups/secrets while branding remains usable", async () => {
  await environment.withSecurityRulesDisabled(async context => {
    for (const path of ["providers/alpha/backups/old.json", "providers/alpha/secrets/sgp.json", "provedores/alpha/backups/old.json", "providers/alpha/backup.json"])
      await uploadBytes(ref(context.storage(), path), new Uint8Array([1]), { contentType: "application/json" });
  });
  for (const claims of [{ role: "providerAdmin", providerId: "alpha" }, { role: "providerAdmin", providerId: "beta" }, { role: "subscriber", providerId: "alpha" }]) {
    const storage = environment.authenticatedContext("actor", claims).storage();
    for (const path of ["providers/alpha/backups/old.json", "providers/alpha/secrets/sgp.json", "provedores/alpha/backups/old.json", "providers/alpha/backup.json"]) {
      await assertFails(getBytes(ref(storage, path)));
      await assertFails(uploadBytes(ref(storage, path), new Uint8Array([1]), { contentType: "image/png" }));
    }
  }
  const own = environment.authenticatedContext("admin", { role: "providerAdmin", providerId: "alpha" }).storage();
  await assertSucceeds(uploadBytes(ref(own, "providers/alpha/public_assets/branding.png"), new Uint8Array([1]), { contentType: "image/png" }));
});
