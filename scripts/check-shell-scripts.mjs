import { execFileSync } from "node:child_process";
import { existsSync, statSync } from "node:fs";
import { join } from "node:path";

const repositories = [".", "app-flutter/unified"].filter((root) =>
  existsSync(join(root, ".git")),
);
const findings = [];
let checked = 0;

for (const root of repositories) {
  const files = execFileSync(
    "git",
    ["ls-files", "-co", "--exclude-standard", "-z", "*.sh"],
    { cwd: root },
  )
    .toString("utf8")
    .split("\0")
    .filter(Boolean);

  for (const file of files) {
    const path = join(root, file);
    if (!existsSync(path)) continue;
    checked += 1;

    if (!file.startsWith("scripts/")) {
      findings.push(`${path}: deve ficar dentro de scripts/`);
    }
    if ((statSync(path).mode & 0o111) === 0) {
      findings.push(`${path}: nao esta marcado como executavel`);
    }
    try {
      execFileSync("bash", ["-n", path], { stdio: "pipe" });
    } catch {
      findings.push(`${path}: sintaxe bash invalida`);
    }
  }
}

if (findings.length) {
  console.error(`Scripts shell invalidos:\n${findings.join("\n")}`);
  process.exit(1);
}

console.log(`Shell script check passed (${checked} scripts).`);
