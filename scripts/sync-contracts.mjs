import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const source = resolve(root, "shared/contracts/index.ts");
const targets = [
  "admin-painel/src/shared/contracts/index.ts",
  "functions/src/contracts/index.ts",
  "api-service/src/contracts/index.ts",
];
const banner = "// Generated from shared/contracts/index.ts. Do not edit directly.\n";
const contents = await readFile(source, "utf8");

await Promise.all(targets.map(async (target) => {
  const output = resolve(root, target);
  await mkdir(dirname(output), { recursive: true });
  await writeFile(output, `${banner}${contents}`, "utf8");
}));

console.log(`Contracts synchronized to ${targets.length} projects.`);

const runtime = await readFile(resolve(root, "shared/runtime/upstream.js"), "utf8");
for (const target of ["proxy-sgp/lib/upstream.js", "api-service/src/services/upstream-runtime.js"]) {
  await writeFile(resolve(root, target), runtime);
}
const invoiceAmount = await readFile(resolve(root, "shared/runtime/invoice-amount.js"), "utf8");
for (const target of ["proxy-sgp/lib/invoice-amount.js", "api-service/src/services/invoice-amount.js"]) {
  await writeFile(resolve(root, target), invoiceAmount);
}
const dashboard = await readFile(resolve(root, "shared/runtime/dashboard.ts"), "utf8");
for (const target of ["functions/src/app/dashboardData.ts", "api-service/src/services/dashboardData.ts"]) {
  await writeFile(resolve(root, target), dashboard);
}
const sgp = await readFile(resolve(root, "shared/runtime/sgp-outbound.js"), "utf8");
for (const target of ["proxy-sgp/lib/sgp-outbound.js", "api-service/src/services/sgp-outbound.ts"]) {
  await writeFile(resolve(root, target), target.endsWith('.ts') ? sgp.replace('module.exports =', 'export default') : sgp);
}
const segmentsDdl = await readFile(resolve(root, "shared/runtime/subscriber-segments-ddl.js"), "utf8");
for (const target of ["proxy-sgp/lib/subscriber-segments-ddl.js", "api-service/src/services/subscriber-segments-ddl.js"]) {
  await writeFile(resolve(root, target), segmentsDdl);
}
