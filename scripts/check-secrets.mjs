import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const patterns = [
  { name: "private key", value: /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/ },
  { name: "service account private key", value: /["']private_key["']\s*:\s*["'][^-\n]*-----BEGIN/ },
  { name: "GitHub token", value: /\bgh[pousr]_[A-Za-z0-9_]{30,}\b/ },
  { name: "Slack token", value: /\bxox[baprs]-[A-Za-z0-9-]{20,}\b/ },
  { name: "AWS access key", value: /\bAKIA[0-9A-Z]{16}\b/ },
  {
    name: "hardcoded shell credential",
    files: /\.sh$/,
    value: /\b(?:PASSWORD|PASS|PASSWD|SENHA|TOKEN|SECRET|API_KEY)\s*=\s*["'](?!\$|<|example|changeme|replace|your-)[^"'\n]{8,}["']/i,
  },
  {
    name: "hardcoded sshpass credential",
    files: /\.sh$/,
    value: /\bsshpass\s+-p\s+["'](?!\$|<)[^"'\n]{8,}["']/i,
  },
];

const repositories = [".", "app-flutter/unified"].filter((root) =>
  existsSync(join(root, ".git")),
);
const files = repositories.flatMap((root) =>
  execFileSync("git", ["ls-files", "-co", "--exclude-standard", "-z"], {
    cwd: root,
  })
    .toString("utf8")
    .split("\0")
    .filter(Boolean)
    .map((file) => (root === "." ? file : join(root, file))),
);
const findings = [];
for (const file of files) {
  let content;
  try {
    content = readFileSync(file, "utf8");
  } catch {
    continue;
  }
  for (const pattern of patterns) {
    if (pattern.files && !pattern.files.test(file)) continue;
    if (pattern.value.test(content)) findings.push(`${file}: ${pattern.name}`);
  }
}

if (findings.length) {
  console.error(`Possiveis secrets versionados:\n${findings.join("\n")}`);
  process.exit(1);
}
console.log(`Secret scan passed (${files.length} tracked/untracked files).`);
