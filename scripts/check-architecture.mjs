import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, statSync } from "node:fs";
import { extname } from "node:path";

const tracked = execFileSync("git", ["ls-files", "-co", "--exclude-standard", "-z"])
  .toString("utf8")
  .split("\0")
  .filter(Boolean);
const failures = [];

const forbidden = new Set([
  ".gitmodules",
  "pubspec.yaml",
  "proxy-sgp/app.py",
  "proxy-sgp/proxy.php",
  "proxy-sgp/docker-compose.yml",
]);
for (const file of tracked) {
  if (!existsSync(file)) continue;
  if (forbidden.has(file)) failures.push(`${file}: arquivo legado proibido`);
  if (file.startsWith("functions/lib/")) failures.push(`${file}: artefato compilado versionado`);
  if (file.startsWith("lib/") && extname(file) === ".dart") failures.push(`${file}: Flutter duplicado na raiz`);
  if (/\.(?:js|mjs|cjs|ts|tsx|dart|py|php)$/.test(file) && statSync(file).size > 65 * 1024) {
    failures.push(`${file}: fonte maior que 65 KiB; modularize antes de ampliar`);
  }
  if (/\.(?:js|mjs|cjs|ts|tsx|dart|py|php|ya?ml)$/.test(file)) {
    const content = readFileSync(file, "utf8");
    if (/168\.194\.13\.18|45\.176\.56\.70/.test(content)) failures.push(`${file}: endpoint de producao fixo`);
  }
}

if (failures.length) {
  console.error(`Falhas de arquitetura:\n${failures.join("\n")}`);
  process.exit(1);
}
console.log(`Architecture check passed (${tracked.length} repository files).`);
