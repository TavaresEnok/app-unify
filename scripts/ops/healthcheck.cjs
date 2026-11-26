// Monitor do painel_provedores (ops-9): site/API/proxy no ar, containers
// saudáveis, disco abaixo do limite e backup em dia. Quando algo muda (falha
// nova ou recuperação) ou a falha continua por horas, avisa no webhook
// PAINEL_ALERT_WEBHOOK_URL (JSON {text} no Google Chat, {content} no Discord,
// {text, content} nos demais: Slack, n8n...). Sem webhook, só registra no log.
//
//   node scripts/ops/healthcheck.cjs            # roda as checagens (cron a cada 5 min)
//   node scripts/ops/healthcheck.cjs --alert "texto"   # envia um aviso avulso
//
// Configuração opcional em /home/app/.secrets/painel_provedores/alert.env:
//   PAINEL_ALERT_WEBHOOK_URL=https://...
//   PAINEL_DISK_ALERT_PERCENT=90
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { evaluateBackup, backupRoot } = require('./backup-status.cjs');

const DEFAULT_URLS = [
    'https://appisp.com.br/api/ready',
    'https://appisp.com.br/sgp/ready',
    'https://appisp.com.br/speedtest/health',
    'https://appisp.com.br/painel/',
    'https://appisp.com.br/',
];
const REPEAT_MS = 6 * 3600 * 1000;

function parseEnvFile(text) {
    const env = {};
    for (const line of String(text).split(/\r?\n/)) {
        const match = /^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/.exec(line);
        if (!match || line.trim().startsWith('#')) continue;
        env[match[1]] = match[2].replace(/^(['"])(.*)\1$/, '$2');
    }
    return env;
}

function loadConfig(env = process.env) {
    const file = env.PAINEL_ALERT_ENV_FILE || '/home/app/.secrets/painel_provedores/alert.env';
    let fromFile = {};
    try { fromFile = parseEnvFile(fs.readFileSync(file, 'utf8')); } catch { /* opcional */ }
    const merged = { ...fromFile, ...env };
    return {
        webhook: merged.PAINEL_ALERT_WEBHOOK_URL || '',
        diskPercent: Number(merged.PAINEL_DISK_ALERT_PERCENT) || 90,
        urls: merged.PAINEL_HEALTH_URLS ? merged.PAINEL_HEALTH_URLS.split(',').map(s => s.trim()).filter(Boolean) : DEFAULT_URLS,
        stateFile: merged.PAINEL_HEALTH_STATE || path.join(merged.PAINEL_BACKUP_DIR || '/home/app/.backups/painel_provedores', 'health-state.json'),
        composeProject: merged.PAINEL_COMPOSE_PROJECT || 'painel_provedores',
    };
}

function diskCheck(stats, threshold) {
    const total = Number(stats.blocks) * Number(stats.bsize);
    const free = Number(stats.bavail) * Number(stats.bsize);
    const usedPercent = total > 0 ? Math.round(((total - free) / total) * 1000) / 10 : 0;
    return { key: 'disk', ok: usedPercent < threshold, detail: `disco em ${usedPercent}% (limite ${threshold}%)` };
}

// Saída de: docker ps -a --format '{{.Names}}\t{{.Status}}'
function containerProblems(psOutput) {
    return String(psOutput).split('\n').map(line => line.trim()).filter(Boolean).map(line => {
        const [name, status = ''] = line.split('\t');
        return { name, status };
    }).filter(({ status }) => /unhealthy|restarting|^exited|^dead|^created/i.test(status))
        .map(({ name, status }) => ({ key: `container:${name}`, ok: false, detail: `${name}: ${status}` }));
}

function decideNotification(previous, failures, now) {
    const keys = failures.map(f => f.key).sort();
    const before = Array.isArray(previous?.failing) ? [...previous.failing].sort() : [];
    const changed = keys.join('|') !== before.join('|');
    const lastAlertAt = Number(previous?.lastAlertAt) || 0;
    const repeat = keys.length > 0 && now - lastAlertAt >= REPEAT_MS;
    const recovered = before.filter(key => !keys.includes(key));
    return { notify: changed || repeat, failing: keys, recovered };
}

function formatMessage(failures, recovered) {
    const lines = [];
    if (failures.length) lines.push('[ALERTA] Painel ISP com problema:', ...failures.map(f => `- ${f.detail}`));
    else lines.push('[OK] Painel ISP normalizado.');
    if (recovered.length && failures.length) lines.push(`Voltou ao normal: ${recovered.join(', ')}`);
    return lines.join('\n');
}

// Google Chat recusa campos desconhecidos (HTTP 400) e o Discord só lê
// "content"; os demais (Slack, n8n...) aceitam os dois.
function alertPayload(webhook, text) {
    let host = '';
    try { host = new URL(webhook).hostname.toLowerCase(); } catch { /* URL inválida: cai no padrão */ }
    if (host === 'chat.googleapis.com') return { text };
    if (host === 'discord.com' || host.endsWith('.discord.com') || host === 'discordapp.com' || host.endsWith('.discordapp.com')) return { content: text };
    return { text, content: text };
}

async function sendAlert(webhook, text) {
    if (!webhook) { console.error(JSON.stringify({ alert: 'sem webhook configurado', text })); return false; }
    try {
        const response = await fetch(webhook, { method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(alertPayload(webhook, text)), signal: AbortSignal.timeout(10000) });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return true;
    } catch (error) {
        console.error(JSON.stringify({ alert: 'falha ao enviar aviso', message: error.message }));
        return false;
    }
}

async function checkUrl(url) {
    const started = Date.now();
    try {
        const response = await fetch(url, { redirect: 'manual', signal: AbortSignal.timeout(10000), headers: { 'User-Agent': 'painel-healthcheck' } });
        return { key: `url:${url}`, ok: response.status === 200, detail: `${url} respondeu ${response.status} em ${Date.now() - started} ms` };
    } catch (error) {
        return { key: `url:${url}`, ok: false, detail: `${url} sem resposta (${error.name === 'TimeoutError' ? 'tempo esgotado' : error.message})` };
    }
}

async function runChecks(config) {
    const results = await Promise.all(config.urls.map(checkUrl));
    try { results.push(diskCheck(fs.statfsSync('/'), config.diskPercent)); } catch (error) {
        results.push({ key: 'disk', ok: false, detail: `disco: ${error.message}` });
    }
    try {
        const ps = execFileSync('docker', ['ps', '-a', '--filter', `label=com.docker.compose.project=${config.composeProject}`,
            '--format', '{{.Names}}\t{{.Status}}'], { encoding: 'utf8', timeout: 15000 });
        results.push(...containerProblems(ps));
    } catch (error) {
        results.push({ key: 'docker', ok: false, detail: `docker: ${error.message.split('\n')[0]}` });
    }
    let backup;
    try { backup = evaluateBackup(backupRoot()); } catch (error) { backup = { status: 'unavailable', message: error.message }; }
    results.push({ key: 'backup', ok: backup.status === 'ok', detail: backup.message || 'backup em dia' });
    return results;
}

async function main(argv) {
    const config = loadConfig();
    const alertIndex = argv.indexOf('--alert');
    if (alertIndex >= 0) {
        const sent = await sendAlert(config.webhook, String(argv[alertIndex + 1] || 'Aviso do painel.'));
        process.exitCode = sent ? 0 : 1;
        return;
    }
    const results = await runChecks(config);
    const failures = results.filter(r => !r.ok);
    let previous = {};
    try { previous = JSON.parse(fs.readFileSync(config.stateFile, 'utf8')); } catch { /* primeira execução */ }
    const now = Date.now();
    const decision = decideNotification(previous, failures, now);
    let lastAlertAt = Number(previous.lastAlertAt) || 0;
    if (decision.notify) {
        console.log(JSON.stringify({ at: new Date(now).toISOString(), failing: failures.map(f => f.detail), recovered: decision.recovered }));
        await sendAlert(config.webhook, formatMessage(failures, decision.recovered));
        lastAlertAt = now; // repete no máximo a cada 6 h enquanto a falha continuar
    }
    try {
        fs.writeFileSync(config.stateFile, JSON.stringify({ failing: decision.failing, lastAlertAt, checkedAt: new Date(now).toISOString() }), { mode: 0o600 });
    } catch (error) { console.error(JSON.stringify({ state: 'não salvo', message: error.message })); }
    if (failures.length) process.exitCode = 1;
}

if (require.main === module) {
    main(process.argv.slice(2)).catch(error => {
        console.error(JSON.stringify({ healthcheck: 'falhou', message: error.message }));
        process.exitCode = 1;
    });
}

module.exports = { parseEnvFile, diskCheck, containerProblems, decideNotification, formatMessage, loadConfig, alertPayload };
