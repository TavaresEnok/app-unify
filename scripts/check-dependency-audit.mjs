import { spawnSync } from 'node:child_process';

const workspaces = ['.', 'admin-painel', 'functions', 'api-service', 'proxy-sgp', 'services/apk-builder'];
// npm 11 exports this user-only option during npm run, then rejects it in a
// project-scoped child command. Audit never executes install scripts.
const auditEnv = { ...process.env };
for (const key of Object.keys(auditEnv)) if (key.toLowerCase() === 'npm_config_allow_scripts') delete auditEnv[key];
let failed = false;
for (const cwd of workspaces) {
  const result = spawnSync('npm', ['--userconfig=/dev/null', 'audit', '--json'], { cwd, encoding: 'utf8', env: auditEnv });
  let report;
  try { report = JSON.parse(result.stdout); } catch { throw new Error(`Auditoria indisponível em ${cwd}: ${result.stderr}`); }
  if (report.error || result.error) throw new Error(`Auditoria falhou em ${cwd}.`);
  const vulnerabilities = Object.keys(report.vulnerabilities || {});
  if (vulnerabilities.length) { failed = true; console.error(`${cwd}: vulnerabilidades bloqueantes: ${vulnerabilities.join(', ')}`); }
  else console.log(`${cwd}: sem vulnerabilidades reportadas`);
}
if (failed) process.exit(1);
