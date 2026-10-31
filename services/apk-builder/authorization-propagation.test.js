const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { EventEmitter } = require('node:events');
const { PassThrough } = require('node:stream');
const { createApp } = require('./index');
const { identity, childEnvironment, digest } = require('./containment');
const { BuildJobStore } = require('./job-store');

const row = { providerId: 'isp-a', appName: 'Synthetic ISP', applicationId: 'br.com.existing.unchanged',
    signingCertificateSha256: 'a'.repeat(64), inventoryReviewed: true };
function registry(file, rows = [row]) { fs.writeFileSync(file, JSON.stringify({ schema: 1, reviewed: true, identities: rows })); }

async function fixture(t, { dedicatedStore = false } = {}) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'build-containment-'));
    const state = { access: 'saas', downloads: 0, spawns: 0, checks: [], revokeAt: '', code: 0 };
    const config = { APK_PROJECT_ROOT: dir, APK_PRIVATE_DIR: path.join(dir, 'private'), APK_OUTPUT_DIR: path.join(dir, 'public'),
        APK_IDENTITY_REGISTRY: path.join(dir, 'identities.json'), APK_AUTHORIZATION_URL: 'https://authority.test/authorize' };
    if (dedicatedStore) Object.assign(config, {
        APK_OUTPUT_DIR: path.join(dir, 'release-store', 'public'),
        APK_PUBLICATION_DIR: path.join(dir, 'release-store', 'private'), APK_PUBLIC_URL_PREFIX: '/public_apks/f1',
    });
    registry(config.APK_IDENTITY_REGISTRY);
    const jobs = new BuildJobStore(undefined, path.join(dir, 'jobs.json'));
    const authority = async (_url, options) => {
        const binding = JSON.parse(options.body); state.checks.push(binding);
        if (!state.failureAt || binding.purpose === state.failureAt) {
            if (state.failure === 'transport' || state.failure === 'timeout') throw Error('private network detail');
            if (state.failure === 'invalid-json') return { ok: true, status: 200, json: async () => { throw Error('private payload'); } };
            if (state.failure === 'invalid-body') return { ok: true, status: 200, json: async () => ({}) };
            if (typeof state.failure === 'number') return { ok: false, status: state.failure };
        }
        if (binding.purpose === state.revokeAt) state.access = 'revoked';
        const allowed = options.headers.Authorization === 'Bearer saas' && state.access === 'saas';
        if (state.access === 'outage') throw Error('outage');
        return { ok: allowed, status: allowed ? 200 : 403, json: async () => ({ authorized: allowed, uid: state.otherOwner ? 'other-user' : 'saas-user', ...binding,
            ...(state.badBinding ? { providerId: 'isp-b' } : {}) }) };
    };
    const app = createApp({ config, jobs, disableRateLimit: true, fetch: authority,
        copyArtifact: (...args) => state.copyArtifact ? state.copyArtifact(...args) : fs.copyFileSync(...args),
        publishLink: (...args) => state.publishLink ? state.publishLink(...args) : fs.linkSync(...args),
        logos: { download: async (_url, file) => { state.downloads++; fs.writeFileSync(file, 'synthetic logo'); if (state.revokeAfterLogo) state.access = state.revokeAfterLogo === 'outage' ? 'outage' : 'revoked'; } },
        spawn: (_cmd, args, options) => {
            state.spawns++; state.env = options.env; state.args = args;
            const child = new EventEmitter(); child.stdout = new PassThrough(); child.stderr = new PassThrough(); child.kill = () => { setImmediate(() => child.emit('close', 1)); };
            const arg = key => args[args.indexOf(key) + 1];
            setImmediate(() => {
                const staging = arg('--output'); fs.mkdirSync(staging, { recursive: true });
                const artifact = path.join(staging, 'artifact.apk'); fs.writeFileSync(artifact, 'synthetic binary');
                fs.writeFileSync(path.join(staging, 'manifest.json'), JSON.stringify({
                    providerId: arg('--id'), applicationId: arg('--package'), versionCode: arg('--version-code'),
                    buildId: arg('--build-id'), format: 'apk', files: [{ path: 'artifact.apk', sha256: state.corrupt ? 'bad' : digest(artifact) }],
                }));
                child.stdout.end('synthetic private log'); child.stderr.end();
                if (!state.defer) child.emit('close', state.code);
            });
            return child;
        } });
    const server = app.listen(0, '127.0.0.1'); await new Promise(resolve => server.once('listening', resolve));
    const base = `http://127.0.0.1:${server.address().port}`;
    t.after(async () => { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); fs.rmSync(dir, { recursive: true, force: true }); });
    const post = async (token = 'saas', extra = {}) => fetch(base + '/generate-apk', { method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
        body: JSON.stringify({ providerId: 'isp-a', appName: row.appName, logoUrl: 'https://logo.test/a', ...extra }) });
    return { dir, state, config, jobs, base, post };
}

module.exports = { fixture, row, registry };

// The same HTTP harness is imported by the Functions suite. Register Node tests
// only when this file is the test entrypoint, avoiding duplicate suite execution.
if (require.main === module) {
    test('authority unavailability stays 503 before request/download/spawn/publication', async t => {
        const f = await fixture(t);
        for (const failure of [503, 500, 'transport', 'timeout', 'invalid-json', 'invalid-body']) {
            for (const purpose of ['request', 'spawn', 'publish']) {
                f.state.failure = failure; f.state.failureAt = purpose;
                const before = { downloads: f.state.downloads, spawns: f.state.spawns };
                const response = await f.post();
                assert.equal(response.status, 503, `${failure}/${purpose}`);
                assert.deepEqual(await response.json(), { success: false, error: 'authorization-unavailable' });
                if (purpose !== 'publish') {
                    assert.equal(f.state.downloads, before.downloads);
                    assert.equal(f.state.spawns, before.spawns);
                }
                assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
            }
        }
    });
    test('second spawn check after logo download preserves outage and prevents spawn', async t => {
        const f = await fixture(t);
        f.state.revokeAfterLogo = 'outage';
        const response = await f.post();
        assert.equal(response.status, 503); assert.equal(f.state.downloads, 1); assert.equal(f.state.spawns, 0);
    });
    test('poll and cancel outages expose no state and do not cancel; current owner can retry explicitly', async t => {
        const f = await fixture(t); f.state.defer = true;
        const { jobId } = await (await f.post('saas', { async: true })).json();
        for (const failure of [503, 'transport', 'invalid-json', 401, 403]) {
            f.state.failure = failure; f.state.failureAt = '';
            for (const [suffix, method] of [['', 'GET'], ['/cancel', 'POST']]) {
                const response = await fetch(f.base + '/jobs/' + jobId + suffix, { method, headers: { Authorization: 'Bearer saas' } });
                assert.equal(response.status, typeof failure === 'number' && failure !== 503 ? 403 : 503);
                const result = await response.json();
                assert.deepEqual(Object.keys(result).sort(), ['error', 'success']);
                assert.equal(f.jobs.get(jobId).status, 'running');
            }
        }
        f.state.failure = undefined;
        f.state.otherOwner = true;
        for (const [suffix, method] of [['', 'GET'], ['/cancel', 'POST']]) {
            assert.equal((await fetch(f.base + '/jobs/' + jobId + suffix, { method, headers: { Authorization: 'Bearer saas' } })).status, 403);
            assert.equal(f.jobs.get(jobId).status, 'running');
        }
        f.state.otherOwner = false;
        assert.equal((await fetch(f.base + '/jobs/' + jobId + '/cancel', { method: 'POST', headers: { Authorization: 'Bearer saas' } })).status, 200);
    });
    test('proven denials and binding mismatch never download or spawn', async t => {
        const f = await fixture(t);
        for (const failure of [401, 403, undefined]) {
            f.state.failure = failure; f.state.badBinding = failure === undefined;
            assert.equal((await f.post()).status, 403);
        }
        assert.equal(f.state.downloads, 0); assert.equal(f.state.spawns, 0);
    });
    test('asynchronous publication outage has safe terminal receipt and no release', async t => {
        const f = await fixture(t); f.state.failure = 503; f.state.failureAt = 'publish';
        const { jobId } = await (await f.post('saas', { async: true })).json();
        for (let i = 0; i < 100 && f.jobs.get(jobId).status === 'running'; i++) await new Promise(r => setTimeout(r, 5));
        assert.equal(f.jobs.get(jobId).error, 'authorization-unavailable');
        const result = await (await fetch(f.base + '/jobs/' + jobId, { headers: { Authorization: 'Bearer saas' } })).json();
        assert.equal(result.status, 'failed'); assert.equal(result.error, 'authorization-unavailable');
        assert.equal(result.downloadUrl, undefined); assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
    });
}

