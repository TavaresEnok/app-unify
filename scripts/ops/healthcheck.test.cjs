const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { parseEnvFile, diskCheck, containerProblems, decideNotification, formatMessage, alertPayload } = require('./healthcheck.cjs');
const { evaluateBackup } = require('./backup-status.cjs');
const { legacyExportEnabled, isFullFirestoreDay } = require('./backup-plan.cjs');

test('lê o arquivo de configuração do aviso', () => {
    assert.deepEqual(parseEnvFile('# comentário\nPAINEL_ALERT_WEBHOOK_URL="https://exemplo.invalid/x"\nPAINEL_DISK_ALERT_PERCENT=85\n'),
        { PAINEL_ALERT_WEBHOOK_URL: 'https://exemplo.invalid/x', PAINEL_DISK_ALERT_PERCENT: '85' });
});

test('disco acima do limite é falha', () => {
    assert.equal(diskCheck({ blocks: 100, bsize: 4096, bavail: 5 }, 90).ok, false);
    assert.equal(diskCheck({ blocks: 100, bsize: 4096, bavail: 50 }, 90).ok, true);
});

test('só container doente, reiniciando ou parado vira problema', () => {
    const problems = containerProblems('painel_api\tUp 2 hours (healthy)\npainel_proxy_sgp\tUp 3 minutes (unhealthy)\npainel_landing\tRestarting (1) 5 seconds ago\npainel_redis\tExited (0) 1 hour ago\n');
    assert.deepEqual(problems.map(p => p.key), ['container:painel_proxy_sgp', 'container:painel_landing', 'container:painel_redis']);
});

test('avisa quando a falha começa, quando some e a cada 6 h enquanto continua', () => {
    const now = Date.parse('2026-11-26T12:00:00Z');
    const fail = [{ key: 'disk', ok: false, detail: 'disco em 95%' }];
    assert.equal(decideNotification({}, [], now).notify, false);
    assert.equal(decideNotification({}, fail, now).notify, true);
    assert.equal(decideNotification({ failing: ['disk'], lastAlertAt: now - 60000 }, fail, now).notify, false);
    assert.equal(decideNotification({ failing: ['disk'], lastAlertAt: now - 7 * 3600000 }, fail, now).notify, true);
    const recovery = decideNotification({ failing: ['disk'], lastAlertAt: now - 60000 }, [], now);
    assert.equal(recovery.notify, true);
    assert.deepEqual(recovery.recovered, ['disk']);
    assert.match(formatMessage([], recovery.recovered), /normalizado/);
    assert.match(formatMessage(fail, []), /disco em 95%/);
});

test('backup: em dia, atrasado e com avisos', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'painel-backup-'));
    const now = Date.parse('2026-11-26T12:00:00Z');
    assert.equal(evaluateBackup(root, now).status, 'unavailable');
    const run = path.join(root, '20261126T060000Z-1');
    fs.mkdirSync(run);
    fs.writeFileSync(path.join(run, 'manifest.json'), JSON.stringify({ completedAt: '2026-11-26T06:04:00Z', warnings: [] }));
    assert.equal(evaluateBackup(root, now).status, 'ok');
    assert.equal(evaluateBackup(root, now + 30 * 3600000).status, 'unavailable');
    fs.writeFileSync(path.join(run, 'manifest.json'), JSON.stringify({ completedAt: '2026-11-26T06:04:00Z', warnings: ['firestore: falhou'] }));
    assert.equal(evaluateBackup(root, now).status, 'degraded');
    fs.rmSync(root, { recursive: true });
});

test('export legado do Firebase: ligado por padrão, desliga com a flag; completo no domingo', () => {
    assert.equal(legacyExportEnabled({}), true);
    assert.equal(legacyExportEnabled({ PAINEL_BACKUP_FIRESTORE: 'false' }), false);
    assert.equal(isFullFirestoreDay(new Date('2026-11-29T09:00:00Z'), {}), true);
    assert.equal(isFullFirestoreDay(new Date('2026-11-26T09:00:00Z'), {}), false);
    assert.equal(isFullFirestoreDay(new Date('2026-11-26T09:00:00Z'), { PAINEL_BACKUP_FIRESTORE_FULL: 'true' }), true);
});

test('formato do aviso conforme o destino do webhook', () => {
    assert.deepEqual(alertPayload('https://chat.googleapis.com/v1/spaces/x/messages?key=k', 'oi'), { text: 'oi' });
    assert.deepEqual(alertPayload('https://discord.com/api/webhooks/1/abc', 'oi'), { content: 'oi' });
    assert.deepEqual(alertPayload('https://hooks.slack.com/services/x', 'oi'), { text: 'oi', content: 'oi' });
    assert.deepEqual(alertPayload('nao-e-url', 'oi'), { text: 'oi', content: 'oi' });
});
