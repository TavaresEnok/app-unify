import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { accessSync, constants, existsSync, mkdirSync, readFileSync, readdirSync, realpathSync, rmSync, watch } from 'node:fs';
import { delimiter, dirname, relative, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// Only pre-provisioned public artifacts. This entry point never installs an SDK.
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const cache = resolve(root, 'node_modules/.paseo-mobile-cache');
const flutter = resolve(cache, 'flutter');
const pubCache = resolve(cache, 'pub-cache');
const dart = resolve(flutter, 'bin/cache/dart-sdk/bin/dart');
const snapshot = resolve(flutter, 'bin/cache/flutter_tools.snapshot');
const flutterTools = resolve(flutter, 'packages/flutter_tools');
const temporary = resolve(cache, 'mobile-check-tmp');
const apps = ['unified', 'admin_app'];
const flags = ['--suppress-analytics', '--no-version-check'];
const deadline = Date.now() + 110_000; // Leave margin for the controller's 120s limit.
const hash = (path) => createHash('sha256').update(readFileSync(path)).digest('hex');

function requireFile(path, executable = false) {
  try {
    accessSync(path, executable ? constants.R_OK | constants.X_OK : constants.R_OK);
  } catch {
    throw new Error(`Pré-requisito ausente/inacessível: ${relative(root, path)}. Encaminhar ao controlador; não baixar.`);
  }
}

function insideRoot(path) {
  // Resolve symlinks as well: a relocated config must not reach the old host
  // through a link whose lexical path happens to be inside this checkout.
  const part = relative(realpathSync(root), realpathSync(path));
  return part !== '..' && !part.startsWith(`..${sep}`) && !part.startsWith(sep);
}

let env;
let activeChild;
const sourceWrites = new Set();
const sourceWatchers = [];
const sourcePaths = new Set();

function verifyOriginals() {
  for (const [path, original] of originals) {
    if (!existsSync(path) || hash(path) !== original) {
      throw new Error(`Arquivo alterado pela ferramenta: ${relative(root, path)}`);
    }
  }
  if (sourceWrites.size) {
    throw new Error(`Escrita em fonte rastreada durante subprocesso: ${[...sourceWrites].join(', ')}`);
  }
}

function protectSources() {
  // All currently tracked Dart files are in lib/test (checked against git at
  // implementation time). Protect the entire trees, including local additions,
  // without relying on worktree .git pointers that cannot relocate to /work.
  // Never walk credentials, ignored build trees or the old host's gitdir.
  function collect(directory) {
    if (!insideRoot(directory)) throw new Error(`Fontes fora da raiz atual: ${relative(root, directory)}`);
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const path = resolve(directory, entry.name);
      if (entry.isSymbolicLink()) throw new Error(`Link em árvore de fontes não suportado: ${relative(root, path)}`);
      if (entry.isDirectory()) collect(path);
      else if (entry.isFile() && entry.name.endsWith('.dart')) {
        originals.set(path, hash(path));
        sourcePaths.add(path);
      }
    }
  }
  for (const app of apps) {
    for (const name of ['lib', 'test']) {
      const directory = resolve(root, 'app-flutter', app, name);
      if (existsSync(directory)) collect(directory);
    }
  }
  if (!sourcePaths.size || !sourcePaths.has(resolve(root, 'app-flutter/admin_app/lib/l10n/app_localizations.dart'))) {
    throw new Error('Inventário de fontes rastreadas incompleto: localização admin_app obrigatória.');
  }
  // Observe writes while the child runs, including writes whose bytes might
  // later be restored. A final matching hash alone is not preservation proof.
  for (const directory of new Set([...sourcePaths].map(dirname))) {
    const watcher = watch(directory, (event, name) => {
      const path = name === null ? null : resolve(directory, name.toString());
      if (path === null || sourcePaths.has(path)) {
        sourceWrites.add(relative(root, path || directory));
        activeChild?.kill('SIGKILL');
      }
    });
    watcher.on('error', (error) => {
      sourceWrites.add(`monitor indisponível: ${error.message}`);
      activeChild?.kill('SIGKILL');
    });
    sourceWatchers.push(watcher);
  }
  console.log(`[mobile-check] Proteção ativa: ${sourcePaths.size} fontes Dart em lib/test, incluindo fontes rastreadas e localizações; sem restauração.`);
  const localization = resolve(root, 'app-flutter/admin_app/lib/l10n/app_localizations.dart');
  console.log(`[mobile-check] original SHA-256 ${relative(root, localization)} ${originals.get(localization)}`);
}

async function run(args, cwd = root, directDart = false) {
  verifyOriginals();
  const remaining = deadline - Date.now();
  if (remaining <= 0) throw new Error('Limite total de 110s excedido.');
  console.log(`\n[mobile-check] ${relative(root, cwd) || '.'}: ${directDart ? 'dart' : 'flutter'} ${args.join(' ')}`);
  const result = await new Promise((resolveResult, reject) => {
    activeChild = spawn(dart, directDart ? args : [snapshot, ...flags, ...args], {
      cwd, env, stdio: 'inherit', timeout: remaining, killSignal: 'SIGKILL',
    });
    activeChild.once('error', reject);
    activeChild.once('close', (status, signal) => resolveResult({ status, signal }));
  });
  activeChild = undefined;
  await new Promise((done) => setImmediate(done));
  verifyOriginals();
  if (result.status !== 0) {
    throw new Error(`Ferramenta falhou: exit=${result.status}, sinal=${result.signal || 'nenhum'}`);
  }
}

function resetConfig(cwd) {
  // Never accept a package_config copied from a different mount/host.
  for (const name of ['package_config.json', 'package_graph.json']) {
    rmSync(resolve(cwd, '.dart_tool', name), { force: true });
  }
}

function verifyConfig(cwd, label) {
  const configPath = resolve(cwd, '.dart_tool/package_config.json');
  requireFile(configPath);
  const config = JSON.parse(readFileSync(configPath, 'utf8'));
  if (config.configVersion !== 2 || !config.packages?.length) {
    throw new Error(`${label}: package_config inválido/vazio.`);
  }
  for (const pkg of config.packages) {
    const uri = new URL(pkg.rootUri, pathToFileURL(configPath));
    if (uri.protocol !== 'file:') throw new Error(`${label}: pacote não local: ${pkg.name}`);
    const path = fileURLToPath(uri);
    if (!existsSync(path) || !insideRoot(path)) {
      throw new Error(`${label}: pacote ausente ou fora da raiz atual: ${pkg.name}`);
    }
  }
  console.log(`[mobile-check] ${label}: ${config.packages.length} pacotes locais; package_config regenerado.`);
}

async function prepare(app) {
  const cwd = resolve(root, 'app-flutter', app);
  resetConfig(cwd);
  // Flutter pub get runs GenerateLocalizationsTarget for generate:true apps.
  // Dart resolves the same locked dependencies without generating app sources.
  await run(['pub', '--suppress-analytics', '--directory', cwd,
    'get', '--offline', '--enforce-lockfile'], root, true);
  verifyConfig(cwd, app);
  return cwd;
}

const originals = new Map();
try {
  const [mode, action, ...extra] = process.argv.slice(2);
  if (extra.length || !((mode === 'probe' && action === undefined)
      || (apps.includes(mode) && ['analyze', 'test-compat'].includes(action)))) {
    throw new Error('Uso: node scripts/diagnostics/mobile-check.mjs probe | {unified|admin_app} {analyze|test-compat}');
  }
  requireFile(dart, true);
  requireFile(snapshot);
  requireFile(resolve(pubCache, 'hosted'));
  requireFile(resolve(pubCache, 'hosted-hashes'));
  for (const path of [dart, snapshot, flutterTools, pubCache, ...apps.map((app) => resolve(root, 'app-flutter', app))]) {
    if (!insideRoot(path)) throw new Error(`Pré-requisito fora da raiz atual: ${relative(root, path)}`);
  }
  const versionPath = resolve(flutter, 'bin/cache/flutter.version.json');
  requireFile(versionPath);
  const version = JSON.parse(readFileSync(versionPath, 'utf8'));
  if (version.frameworkVersion !== '3.38.4' || version.dartSdkVersion !== '3.10.3') {
    throw new Error('Cache incompatível: exigidos Flutter 3.38.4 / Dart 3.10.3; não atualizar.');
  }
  for (const path of [versionPath, dart, snapshot]) {
    originals.set(path, hash(path));
    console.log(`[mobile-check] SHA-256 ${relative(root, path)} ${originals.get(path)}`);
  }
  for (const cwd of [flutterTools, ...apps.map((app) => resolve(root, 'app-flutter', app))]) {
    for (const name of ['pubspec.yaml', 'pubspec.lock']) {
      const path = resolve(cwd, name);
      requireFile(path);
      if (!insideRoot(path)) throw new Error(`Pubspec/lockfile fora da raiz atual: ${relative(root, path)}`);
      originals.set(path, hash(path));
      console.log(`[mobile-check] original SHA-256 ${relative(root, path)} ${originals.get(path)}`);
    }
  }
  mkdirSync(temporary, { recursive: true });
  // Allowlist avoids inheriting cloud credentials, proxy settings or tool overrides.
  // HOME is preserved, never repurposed. Config and large temporaries stay in /work.
  env = {
    PATH: [resolve(flutter, 'bin/cache/dart-sdk/bin'), '/usr/bin', '/bin'].join(delimiter),
    ...(process.env.HOME ? { HOME: process.env.HOME } : {}),
    LANG: 'C.UTF-8', CI: 'true', FLUTTER_ROOT: flutter, PUB_CACHE: pubCache,
    TMPDIR: temporary, TMP: temporary, TEMP: temporary,
    XDG_CONFIG_HOME: resolve(temporary, 'config'),
    XDG_CACHE_HOME: resolve(temporary, 'cache'),
    DART_SUPPRESS_ANALYTICS: 'true', FLUTTER_SUPPRESS_ANALYTICS: 'true',
    FLUTTER_SKIP_UPDATE_CHECK: 'true', PUB_ENVIRONMENT: 'paseo_offline_validation',
  };
  protectSources();
  // Flutter may bootstrap flutter_tools with an online pub get if its own
  // package_config still references the source host. Always relocate it first
  // using Dart directly, before starting any Flutter snapshot operation.
  resetConfig(flutterTools);
  await run(['pub', '--suppress-analytics', '--directory', flutterTools,
    'get', '--offline', '--enforce-lockfile'], root, true);
  verifyConfig(flutterTools, 'flutter_tools');
  if (mode === 'probe') {
    await run(['--version'], root, true);
    await run(['--version']); // Actual Flutter process, not just cached metadata.
    for (const app of apps) await prepare(app);
  } else {
    if (action === 'test-compat') {
      requireFile(resolve(root, 'app-flutter', mode, 'test/compatibility_v2_test.dart'));
      requireFile(resolve(flutter, 'bin/cache/artifacts/engine/linux-x64/flutter_tester'), true);
      requireFile(resolve(flutter, 'bin/cache/artifacts/engine/linux-x64/frontend_server_aot.dart.snapshot'));
      requireFile(resolve(flutter, 'bin/cache/artifacts/engine/linux-x64/icudtl.dat'));
    }
    const cwd = await prepare(mode);
    if (action === 'analyze') {
      await run(['analyze', '--no-pub', '--no-fatal-infos', '--no-fatal-warnings', 'lib'], cwd);
    } else {
      await run(['test', '--no-pub', 'test/compatibility_v2_test.dart'], cwd);
    }
  }
  // The finally block must also pass before reporting success.
} catch (error) {
  console.error(`[mobile-check] FAIL: ${error.message}`);
  process.exitCode = 1;
} finally {
  try {
    verifyOriginals();
  } catch (error) {
    console.error(`[mobile-check] FAIL: ${error.message}`);
    process.exitCode = 1;
  }
  for (const watcher of sourceWatchers) watcher.close();
}
if (!process.exitCode) console.log('[mobile-check] PASS: comando real concluído; ferramentas/pubspecs/lockfiles/fontes Dart preservados; nenhuma escrita em fonte rastreada observada.');
