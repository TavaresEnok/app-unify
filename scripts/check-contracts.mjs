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

if (stale.length) {
  console.error(`Contratos desatualizados: ${stale.join(", ")}. Execute npm run contracts:sync.`);
  process.exit(1);
}

console.log("Shared contracts are synchronized.");
