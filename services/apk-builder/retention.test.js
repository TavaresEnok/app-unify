const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { pruneProviderReleases } = require('./retention');

function release(root, provider, version, id, format = 'apk', mtime = Date.now()) {
    const dir = path.join(root, provider, String(version), id);
    fs.mkdirSync(dir, { recursive: true });
    const file = path.join(dir, `app.${format}`);
    fs.writeFileSync(file, 'x');
    fs.utimesSync(file, new Date(mtime), new Date(mtime));
    return file;
}

test('mantém os 3 APKs mais recentes e apaga os antigos com as pastas vazias', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ret-'));
    const files = [1, 2, 3, 4, 5].map(v => release(root, 'vibe', 100 + v, `b${v}`));
    const removed = pruneProviderReleases(root, 'vibe', { keep: 3 });
    assert.deepEqual(removed.map(r => r.buildId).sort(), ['b1', 'b2']);
    assert.equal(fs.existsSync(files[0]), false);
    assert.equal(fs.existsSync(path.join(root, 'vibe', '101')), false);
    for (const f of files.slice(2)) assert.equal(fs.existsSync(f), true);
});

test('APK e AAB contam separado, e outro provedor não é tocado', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ret-'));
    const aab = release(root, 'vibe', 10, 'aab1', 'aab');
    [11, 12, 13, 14].forEach(v => release(root, 'vibe', v, `a${v}`));
    const other = release(root, 'insnet', 1, 'old');
    const removed = pruneProviderReleases(root, 'vibe', { keep: 3 });
    assert.deepEqual(removed.map(r => r.buildId), ['a11']);
    assert.equal(fs.existsSync(aab), true);
    assert.equal(fs.existsSync(other), true);
});

test('nunca apaga o build recém-publicado, mesmo com versão menor', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ret-'));
    [20, 21, 22].forEach(v => release(root, 'vibe', v, `n${v}`));
    const fresh = release(root, 'vibe', 5, 'fresh');
    pruneProviderReleases(root, 'vibe', { keep: 3, protectBuildId: 'fresh' });
    assert.equal(fs.existsSync(fresh), true);
});

test('mesma versão: decide pela data do arquivo', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ret-'));
    const old = release(root, 'vibe', 7, 'old', 'apk', Date.now() - 60_000);
    const fresh = release(root, 'vibe', 7, 'new', 'apk', Date.now());
    pruneProviderReleases(root, 'vibe', { keep: 1 });
    assert.equal(fs.existsSync(old), false);
    assert.equal(fs.existsSync(fresh), true);
});

test('ignora id de provedor inválido e pasta inexistente', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ret-'));
    assert.deepEqual(pruneProviderReleases(root, '../etc'), []);
    assert.deepEqual(pruneProviderReleases(root, 'nada'), []);
});

test('staging fica só para builds ainda publicados (e o recém-publicado)', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ret-'));
    const out = path.join(root, 'public'); const staging = path.join(root, 'staging');
    [1, 2, 3, 4].forEach(v => release(out, 'vibe', v, `b${v}`));
    for (const [v, id] of [[1, 'b1'], [3, 'b3'], [4, 'b4'], [9, 'failed'], [5, 'fresh']]) {
        fs.mkdirSync(path.join(staging, 'vibe', String(v), id), { recursive: true });
    }
    pruneProviderReleases(out, 'vibe', { keep: 2, protectBuildId: 'fresh', stagingRoot: staging });
    const left = fs.readdirSync(path.join(staging, 'vibe')).flatMap(v => fs.readdirSync(path.join(staging, 'vibe', v)));
    assert.deepEqual(left.sort(), ['b3', 'b4', 'fresh']);
    assert.equal(fs.existsSync(path.join(staging, 'vibe', '9')), false);
});
