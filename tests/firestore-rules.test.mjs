import { readFile } from "node:fs/promises";
import { after, before, beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { deleteObject, getBytes, ref, uploadBytes } from "firebase/storage";

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-private-attachments",
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
  await assertFails(setDoc(doc(admin, "provedores", "alpha"), {
    integrations: { apiToken: "must-not-be-public" },
  }, { merge: true }));
  for (const data of [{ details: { apiToken: "private" } }, { config: { password: "private" } }, { token: "private" }]) {
    await assertFails(setDoc(doc(admin, "provedores", "alpha"), data, { merge: true }));
  }
});

test("function request creation is bound to the authenticated uid", async () => {
  const db = environment.authenticatedContext("requester", { role: "providerAdmin", providerId: "alpha", auth_time: 100, iat: 101 }).firestore();
  await assertSucceeds(setDoc(doc(db, "function_requests", "valid"), {
    type: "GET_DASHBOARD_DATA",
    requesterUid: "requester",
    payload: {},
    createdAt: serverTimestamp(), session: { authTime: 100, issuedAt: 101, role: 'providerAdmin', providerId: 'alpha', superAdmin: false },
  }));
  const valid = { type: 'GET_DASHBOARD_DATA', requesterUid: 'requester', payload: {}, createdAt: serverTimestamp(), session: { authTime: 100, issuedAt: 101, role: 'providerAdmin', providerId: 'alpha', superAdmin: false } };
  for (const [index, session] of [undefined, { ...valid.session, authTime: 102 }, { ...valid.session, issuedAt: 102 }, { ...valid.session, providerId: 'beta' }, { ...valid.session, superAdmin: true }].entries()) {
    const { session: omitted, ...base } = valid;
    await assertFails(setDoc(doc(db, 'function_requests', 'session-forged-' + index), { ...base, ...(session ? { session } : {}) }));
  }
  await assertFails(setDoc(doc(db, 'function_requests', 'forged-created'), { ...valid, createdAt: new Date(0) }));
  await assertFails(setDoc(doc(db, "function_requests", "spoofed"), {
    ...valid,
    type: "GET_DASHBOARD_DATA",
    requesterUid: "another-user",
    payload: {},
  }));
  // Forja de identidade: requesterUid de topo aponta para uma vítima (ex.: um
  // super admin) enquanto o payload satisfaz a regra pelo próprio uid. Deve
  // falhar — o topo é a identidade canônica usada na autorização.
  await assertFails(setDoc(doc(db, "function_requests", "forged"), {
    ...valid,
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
  await assertFails(uploadBytes(
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
  const db = environment.authenticatedContext("subscriber", { role: "subscriber", providerId: "alpha", cpfCnpj: "12345678901", auth_time: 100, iat: 101 }).firestore();
  await assertFails(setDoc(doc(db, "function_requests", "subscriber-admin"), { type: "UPDATE_PROVIDER_CONFIG", requesterUid: "subscriber", payload: { providerId: "alpha" }, createdAt: serverTimestamp(), session: { authTime: 100, issuedAt: 101, role: 'subscriber', providerId: 'alpha', superAdmin: false } }));
  await assertSucceeds(setDoc(doc(db, "function_requests", "subscriber-ticket"), { type: "CREATE_TICKET", requesterUid: "subscriber", payload: { providerId: "alpha" }, createdAt: serverTimestamp(), session: { authTime: 100, issuedAt: 101, role: 'subscriber', providerId: 'alpha', superAdmin: false } }));
});

test("config direct writes and all overlapping legacy secret/backup paths are closed", async () => {
  const users = [
    { role: "providerAdmin", providerId: "alpha", auth_time: 100, iat: 101 },
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
    createdAt: serverTimestamp(), session: { authTime: 100, issuedAt: 101, role: 'providerAdmin', providerId: 'alpha', superAdmin: false },
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

test('E9 diagnostics bind SDK creation to uid and tenant; no client URL/ref/update bypass', async () => {
  const own = environment.authenticatedContext('a1', { role: 'subscriber', providerId: 'alpha' }).firestore();
  const valid = { schemaVersion: 2, createdByUid: 'a1', providerId: 'alpha', createdAt: serverTimestamp(), severity: 'ok', measurements: {} };
  const path = 'provedores/alpha/diagnostic_results/r1';
  await environment.withSecurityRulesDisabled(context => setDoc(doc(context.firestore(), 'provedores/alpha/diagnostic_results/legacy'), { createdByUid: 'unknown', reportUrl: 'https://legacy.invalid' }));
  await assertSucceeds(setDoc(doc(own, path), valid));
  // Creation does not establish legacy-proof provenance for direct SDK reads.
  await assertFails(getDoc(doc(own, path)));
  for (const claims of [{ role: 'subscriber', providerId: 'alpha' }, { role: 'subscriber', providerId: 'beta' }, { role: 'providerAdmin', providerId: 'beta' }]) {
    const db = environment.authenticatedContext('a2', claims).firestore();
    await assertFails(getDoc(doc(db, path)));
    await assertFails(setDoc(doc(db, path), { reportAttachmentId: 'forged' }, { merge: true }));
  }
  for (const [index, forged] of [{ createdByUid: 'a2' }, { providerId: 'beta' }, { reportUrl: 'https://outside.invalid' }, { reportAttachmentId: 'forged' }, { status: 'approved' }].entries())
    await assertFails(setDoc(doc(own, 'provedores/alpha/diagnostic_results/forged-' + index), { ...valid, ...forged }));
  await assertFails(setDoc(doc(own, path), { measurements: { speed: 999 } }, { merge: true }));
  for (const claims of [{ role: 'providerAdmin', providerId: 'alpha' }, { superAdmin: true }]) {
    const db = environment.authenticatedContext('admin', claims).firestore();
    await assertSucceeds(getDoc(doc(db, path)));
    await assertSucceeds(getDoc(doc(db, 'provedores/alpha/diagnostic_results/legacy')));
    await assertFails(setDoc(doc(db, path), { reportUrl: 'https://outside.invalid' }, { merge: true }));
    for (const root of ['provedores', 'providers']) {
      await assertFails(setDoc(doc(db, `${root}/alpha/diagnostic_results/r1/private_attachments/up1`), { state: 'committed' }));
      await assertFails(getDoc(doc(db, `${root}/alpha/diagnostic_results/r1/private_attachments/up1`)));
    }
    await assertFails(setDoc(doc(db, 'tickets/t1/private_attachments/up1'), { state: 'committed' }));
  }
});

test('E9 legacy forged owner, tenant, schema and timestamp never grant subscriber reads', async () => {
  const paths = ['legacy-owner', 'legacy-schema', 'legacy-full'].map(id => `provedores/alpha/diagnostic_results/${id}`);
  await environment.withSecurityRulesDisabled(async context => {
    for (const [index, path] of paths.entries()) {
      await setDoc(doc(context.firestore(), path), {
        providerId: 'alpha', createdByUid: 'a1', measurements: { speed: 123 },
        ...(index >= 1 ? { schemaVersion: 2, createdAt: new Date('2099-01-01') } : {}),
        ...(index >= 2 ? { reportUrl: 'https://legacy.invalid/private.pdf', reportAttachmentId: 'forged' } : {}),
      });
    }
  });
  for (const [uid, claims, allowed] of [
    ['a1', { role: 'subscriber', providerId: 'alpha' }, false],
    ['a2', { role: 'subscriber', providerId: 'alpha' }, false],
    ['b1', { role: 'subscriber', providerId: 'beta' }, false],
    ['pb', { role: 'providerAdmin', providerId: 'beta' }, false],
    ['pa', { role: 'providerAdmin', providerId: 'alpha' }, true],
    ['saas', { superAdmin: true }, true],
  ]) {
    const db = environment.authenticatedContext(uid, claims).firestore();
    for (const path of paths) await (allowed ? assertSucceeds : assertFails)(getDoc(doc(db, path)));
  }
});

test('E9 tickets require uid and tenant; legacy CPF does not authorize SDK reads', async () => {
  await environment.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'tickets/t1'), { createdByUid: 'a1', providerId: 'alpha' });
    await setDoc(doc(db, 'tickets/legacy'), { createdByUid: '123', providerId: 'alpha' });
  });
  for (const [uid, providerId, succeeds] of [['a1','alpha',true], ['a2','alpha',false], ['a1','beta',false]]) {
    const db = environment.authenticatedContext(uid, { role: 'subscriber', providerId, cpfCnpj: '123' }).firestore();
    await (succeeds ? assertSucceeds : assertFails)(getDoc(doc(db, 'tickets/t1')));
    await assertFails(getDoc(doc(db, 'tickets/legacy')));
  }
});

test('E9 private v2 is backend-only and v1 grants no subscriber tenant-wide access', async () => {
  const paths = ['private_v2/alpha/tickets/t1/up1', 'private_v2/alpha/results/r1/up1',
    'providers/alpha/ticket_attachments/old.png', 'providers/alpha/diagnostic_reports/old.pdf'];
  await environment.withSecurityRulesDisabled(async context => {
    for (const path of paths) await uploadBytes(ref(context.storage(), path), new Uint8Array([1]), { contentType: 'image/png' });
  });
  for (const [uid, claims] of [['a1', { role: 'subscriber', providerId: 'alpha' }], ['a2', { role: 'subscriber', providerId: 'alpha' }], ['b1', { role: 'subscriber', providerId: 'beta' }], ['pa', { role: 'providerAdmin', providerId: 'alpha' }], ['saas', { superAdmin: true }]]) {
    const storage = environment.authenticatedContext(uid, claims).storage();
    for (const path of paths) {
      if (path.startsWith('private_v2/') || claims.role !== 'providerAdmin' && !claims.superAdmin) {
        await assertFails(getBytes(ref(storage, path)));
        await assertFails(deleteObject(ref(storage, path)));
      }
      await assertFails(uploadBytes(ref(storage, path), new Uint8Array([1]), { contentType: 'image/png' }));
    }
  }
});
