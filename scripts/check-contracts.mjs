import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

const source = await readFile(resolve("shared/contracts/index.ts"), "utf8");
const targets = [
  "admin-painel/src/shared/contracts/index.ts",
  "functions/src/contracts/index.ts",
  "api-service/src/contracts/index.ts",
];
const expected = `// Generated from shared/contracts/index.ts. Do not edit directly.\n${source}`;
const stale = [];

for (const target of targets) {
  const contents = await readFile(resolve(target), "utf8").catch(() => "");
  if (contents !== expected) stale.push(target);
}

const runtime = await readFile(resolve("shared/runtime/upstream.js"), "utf8");
for (const target of ["proxy-sgp/lib/upstream.js", "api-service/src/services/upstream-runtime.js"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== runtime) stale.push(target);
}

const invoiceAmount = await readFile(resolve("shared/runtime/invoice-amount.js"), "utf8");
for (const target of ["proxy-sgp/lib/invoice-amount.js", "api-service/src/services/invoice-amount.js"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== invoiceAmount) stale.push(target);
}
const dashboard = await readFile(resolve("shared/runtime/dashboard.ts"), "utf8");
for (const target of ["functions/src/app/dashboardData.ts"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== dashboard) stale.push(target);
}

const sgp = await readFile(resolve("shared/runtime/sgp-outbound.js"), "utf8");
for (const target of ["proxy-sgp/lib/sgp-outbound.js", "api-service/src/services/sgp-outbound.ts"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== (target.endsWith('.ts') ? sgp.replace('module.exports =', 'export default') : sgp)) stale.push(target);
}
const segmentsDdl = await readFile(resolve("shared/runtime/subscriber-segments-ddl.js"), "utf8");
for (const target of ["proxy-sgp/lib/subscriber-segments-ddl.js", "api-service/src/services/subscriber-segments-ddl.js"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== segmentsDdl) stale.push(target);
}

const ixcGateway = await readFile(resolve("shared/runtime/ixc-gateway.js"), "utf8");
for (const target of ["proxy-sgp/lib/ixc-gateway.js", "api-service/src/services/ixc-gateway.js"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== ixcGateway) stale.push(target);
}
const coreSchemaDdl = await readFile(resolve("shared/runtime/core-schema-ddl.js"), "utf8");
for (const target of ["proxy-sgp/lib/core-schema-ddl.js", "api-service/src/services/core-schema-ddl.js"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== coreSchemaDdl) stale.push(target);
}
const legacyAuth = await readFile(resolve("shared/runtime/legacy-firebase-auth.js"), "utf8");
for (const target of ["proxy-sgp/lib/legacy-firebase-auth.js", "api-service/src/services/legacy-firebase-auth.js"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== legacyAuth) stale.push(target);
}
const selfAuth = await readFile(resolve("shared/runtime/self-auth.js"), "utf8");
for (const target of ["proxy-sgp/lib/self-auth.js", "api-service/src/services/self-auth.js"]) {
  if (await readFile(resolve(target), "utf8").catch(() => "") !== selfAuth) stale.push(target);
}

if (stale.length) {
  console.error(`Contratos desatualizados: ${stale.join(", ")}. Execute npm run contracts:sync.`);
  process.exit(1);
}

console.log("Shared contracts are synchronized.");
