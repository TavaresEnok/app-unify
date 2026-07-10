import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const apply = process.argv.includes("--apply");
const removeLegacy = process.argv.includes("--remove-legacy");
initializeApp();
const db = getFirestore();
const providers = await db.collection("provedores").get();
let changed = 0;

for (const provider of providers.docs) {
  const data = provider.data();
  const legacy = data.config && typeof data.config === "object" ? data.config : {};
  const additions = Object.fromEntries(Object.entries(legacy).filter(([key]) => data[key] === undefined && key !== "integrations"));
  const integrations = (data.integrations && typeof data.integrations === "object" ? data.integrations : null) ||
    (legacy.integrations && typeof legacy.integrations === "object" ? legacy.integrations : null);
  if (!Object.keys(additions).length && !integrations && !(removeLegacy && data.config)) continue;
  changed += 1;
  console.log(`${apply ? "APPLY" : "DRY-RUN"} ${provider.id}: ${Object.keys(additions).join(", ") || "sem campos novos"}`);
  if (!apply) continue;

  const backupRef = provider.ref.collection("migration_backups").doc("provider-config-v1");
  const batch = db.batch();
  batch.set(backupRef, {
    migration: "provider-config-v1",
    providerData: data,
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: false });
  batch.set(provider.ref, {
    ...additions,
    ...(removeLegacy ? { config: FieldValue.delete(), integrations: FieldValue.delete() } : {}),
    schemaVersion: 1,
    migratedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (integrations) {
    batch.set(provider.ref.collection("secrets").doc("sgp"), { integrations }, { merge: true });
  }
  await batch.commit();
}

console.log(`${changed} provedor(es) ${apply ? "migrados" : "com migração pendente"}.`);
