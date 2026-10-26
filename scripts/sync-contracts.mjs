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
