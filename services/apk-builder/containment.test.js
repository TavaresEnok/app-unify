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

const { fixture, row, registry } = require('./authorization-propagation.test');
test('HTTP denies non SaaS, tenant B, old role/disabled/revoked/stale/outage before all effects', async t => {
    const f = await fixture(t);
    for (const role of ['subscriber', 'provider', 'tenant-b', 'old-claim', 'disabled', 'revoked', 'stale', 'outage']) {
        f.state.access = role;
        assert.equal((await f.post(role)).status, role === 'outage' ? 503 : 403);
    }
    assert.equal(f.state.spawns, 0); assert.equal(f.state.downloads, 0);
    assert.equal(fs.existsSync(f.config.APK_PRIVATE_DIR), false);
});
test('current SaaS publishes verified immutable path, polls, preserves identity and private logs', async t => {
    const f = await fixture(t);
    process.env.SGP_TOKEN = 'synthetic-secret'; process.env.GOOGLE_APPLICATION_CREDENTIALS = '/synthetic/admin';
    t.after(() => { delete process.env.SGP_TOKEN; delete process.env.GOOGLE_APPLICATION_CREDENTIALS; });
    const response = await f.post(); assert.equal(response.status, 200);
    const result = await response.json(); assert.match(result.downloadUrl, /isp-a\/\d+\/[a-f0-9-]+\/app.apk/);
    assert.equal(fs.readFileSync(path.join(f.config.APK_OUTPUT_DIR, result.downloadUrl.replace('/public_apks/', '')), 'utf8'), 'synthetic binary');
    assert.deepEqual(f.state.env, childEnvironment()); assert.doesNotMatch(JSON.stringify(f.state.env), /secret|Bearer|CREDENTIALS|SGP/);
    assert.equal(f.state.args[f.state.args.indexOf('--package') + 1], row.applicationId);
    const job = [...f.jobs.jobs.values()][0];
    const poll = await fetch(f.base + '/jobs/' + job.id, { headers: { Authorization: 'Bearer saas' } });
    assert.equal((await poll.json()).status, 'succeeded');
    assert.doesNotMatch(fs.readFileSync(path.join(f.dir, 'jobs.json'), 'utf8'), /Bearer|private log|synthetic-secret/);
    assert.equal((await fetch(f.base + '/jobs/' + job.id, { headers: { Authorization: 'Bearer provider' } })).status, 403);
    assert.equal((await fetch(f.base + '/jobs/absent')).status, 404);
});
test('accepted then revoked during preparation never spawns', async t => {
    const f = await fixture(t); f.state.revokeAfterLogo = true;
    assert.equal((await f.post()).status, 403); assert.equal(f.state.spawns, 0);
    assert.equal([...f.jobs.jobs.values()][0].status, 'failed');
    assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
});
test('revocation before release prevents public artifact and async polling reports failure', async t => {
    const f = await fixture(t); f.state.revokeAt = 'publish';
    const response = await f.post('saas', { async: true }); assert.equal(response.status, 202);
    const accepted = await response.json();
    for (let i = 0; i < 100 && f.jobs.get(accepted.jobId).status === 'running'; i++) await new Promise(r => setTimeout(r, 5));
    assert.equal(f.jobs.get(accepted.jobId).status, 'failed'); assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
    f.state.access = 'saas'; f.state.revokeAt = '';
    const poll = await fetch(f.base + '/jobs/' + accepted.jobId, { headers: { Authorization: 'Bearer saas' } });
    assert.equal((await poll.json()).success, false);
});
test('corrupt terminal receipt never releases and old release survives', async t => {
    const f = await fixture(t); f.state.corrupt = true;
    fs.mkdirSync(f.config.APK_OUTPUT_DIR); fs.writeFileSync(path.join(f.config.APK_OUTPUT_DIR, 'old.apk'), 'old release');
    assert.equal((await f.post()).status, 403);
    assert.deepEqual(fs.readdirSync(f.config.APK_OUTPUT_DIR), ['old.apk']);
});
test('cancel accepted running job prevents release and has stable terminal polling', async t => {
    const f = await fixture(t); f.state.defer = true;
    const response = await f.post('saas', { async: true }); const { jobId } = await response.json();
    const cancel = await fetch(f.base + '/jobs/' + jobId + '/cancel', { method: 'POST', headers: { Authorization: 'Bearer saas' } });
    assert.equal(cancel.status, 200); assert.equal(f.jobs.get(jobId).error, 'build-cancelled');
    assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
    assert.equal((await fetch(f.base + '/jobs/' + jobId + '/cancel', { method: 'POST', headers: { Authorization: 'Bearer saas' } })).status, 409);
});
test('same tenant and version builds receive distinct paths and preserve previous release', async t => {
    const f = await fixture(t);
    const a = await (await f.post()).json(); const first = path.join(f.config.APK_OUTPUT_DIR, a.downloadUrl.replace('/public_apks/', ''));
    const b = await (await f.post()).json();
    assert.notEqual(a.downloadUrl, b.downloadUrl); assert.equal(fs.readFileSync(first, 'utf8'), 'synthetic binary');
});
test('partial publication copy stays private, is cleaned on failure and preserves old release', async t => {
    const f = await fixture(t);
    fs.mkdirSync(f.config.APK_OUTPUT_DIR); const old = path.join(f.config.APK_OUTPUT_DIR, 'old.apk');
    fs.writeFileSync(old, 'old release');
    let pending;
    f.state.copyArtifact = (_source, destination) => {
        pending = destination;
        fs.writeFileSync(destination, 'part');
        assert.ok(destination.startsWith(f.config.APK_PRIVATE_DIR + path.sep));
        assert.deepEqual(fs.readdirSync(f.config.APK_OUTPUT_DIR), ['old.apk']);
        assert.equal([...f.jobs.jobs.values()][0].status, 'running');
        throw Object.assign(Error('synthetic partial copy'), { code: 'EIO' });
    };
    const response = await f.post(); assert.equal(response.status, 403);
    assert.equal((await response.json()).error, 'build-release-denied');
    assert.equal([...f.jobs.jobs.values()][0].status, 'failed');
    assert.equal(fs.existsSync(pending), false);
    assert.deepEqual(fs.readdirSync(f.config.APK_OUTPUT_DIR), ['old.apk']);
    assert.equal(fs.readFileSync(old, 'utf8'), 'old release');
});
test('complete verified copy becomes visible only at atomic exclusive link', async t => {
    const f = await fixture(t); let pending, destination;
    f.state.copyArtifact = (source, target, flags) => {
        pending = target; fs.writeFileSync(target, 'part');
        assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
        fs.rmSync(target); fs.copyFileSync(source, target, flags);
        assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
    };
    f.state.publishLink = (source, target) => {
        destination = target;
        assert.equal(fs.existsSync(target), false);
        assert.equal(fs.readFileSync(source, 'utf8'), 'synthetic binary');
        assert.equal(f.state.checks.at(-1).purpose, 'publish');
        fs.linkSync(source, target);
        assert.equal(fs.readFileSync(target, 'utf8'), 'synthetic binary');
        assert.throws(() => fs.linkSync(source, target), { code: 'EEXIST' });
    };
    assert.equal((await f.post()).status, 200);
    assert.equal(fs.existsSync(pending), false);
    assert.equal(fs.readFileSync(destination, 'utf8'), 'synthetic binary');
    assert.equal([...f.jobs.jobs.values()][0].status, 'succeeded');
});
test('dedicated release store serves only public subtree with configured URL prefix', async t => {
    const f = await fixture(t, { dedicatedStore: true });
    const response = await f.post(); assert.equal(response.status, 200);
    const result = await response.json(); assert.match(result.downloadUrl, /^\/public_apks\/f1\/isp-a\//);
    assert.equal(fs.readFileSync(path.join(f.config.APK_OUTPUT_DIR, result.downloadUrl.replace('/public_apks/f1/', '')), 'utf8'), 'synthetic binary');
    assert.deepEqual(fs.readdirSync(f.config.APK_PUBLICATION_DIR), []);
    assert.equal(fs.statSync(f.config.APK_PUBLICATION_DIR).mode & 0o777, 0o700);
});
test('corrupt private publication copy and revocation during copy never release', async t => {
    const f = await fixture(t);
    f.state.copyArtifact = (_source, target) => fs.writeFileSync(target, 'corrupt');
    assert.equal((await f.post()).status, 403);
    assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
    f.state.copyArtifact = (...args) => { fs.copyFileSync(...args); f.state.access = 'revoked'; };
    assert.equal((await f.post()).status, 403);
    assert.equal(fs.existsSync(f.config.APK_OUTPUT_DIR), false);
    assert.equal([...f.jobs.jobs.values()].every(job => job.status === 'failed'), true);
    assert.equal(fs.readdirSync(f.config.APK_PRIVATE_DIR).some(name => name.startsWith('publication-')), false);
});
test('link failure never falls back to public copy; colliding release survives', async t => {
    const f = await fixture(t); let target;
    f.state.publishLink = (source, destination) => {
        target = destination;
        throw Object.assign(Error('synthetic cross-device failure'), { code: 'EXDEV' });
    };
    assert.equal((await f.post()).status, 403);
    assert.equal(fs.existsSync(target), false);
    f.state.publishLink = (source, destination) => {
        target = destination; fs.writeFileSync(destination, 'existing release');
        fs.linkSync(source, destination);
    };
    assert.equal((await f.post()).status, 403);
    assert.equal(fs.readFileSync(target, 'utf8'), 'existing release');
    assert.equal([...f.jobs.jobs.values()].every(job => job.status === 'failed'), true);
    assert.equal(fs.readdirSync(f.config.APK_PRIVATE_DIR).some(name => name.startsWith('publication-')), false);
});
test('registry absent, normalized tenant/name collisions and package duplication fail closed', async t => {
    const f = await fixture(t);
    assert.equal(identity(f.config.APK_IDENTITY_REGISTRY, row.providerId, row.appName).applicationId, row.applicationId);
    for (const other of [{ ...row, providerId: 'ispa', appName: 'Other', applicationId: 'br.com.other' },
        { ...row, providerId: 'other', applicationId: 'br.com.other' }, { ...row, providerId: 'other', appName: 'Other' }]) {
        registry(f.config.APK_IDENTITY_REGISTRY, [row, other]);
        assert.equal((await f.post()).status, 409);
    }
    fs.rmSync(f.config.APK_IDENTITY_REGISTRY); assert.equal((await f.post()).status, 409);
    assert.equal(f.state.spawns, 0);
});
test('declared builder mounts and network do not restore administrative access', () => {
    const compose = fs.readFileSync(path.join(__dirname, '../../docker-compose.yml'), 'utf8');
    const builder = compose.split('\n  apk-builder:\n')[1].split('\n  redis-state:')[0];
    assert.doesNotMatch(builder, /service-account|GOOGLE_|env_file|docker.sock|painel_net|network_mode/);
    assert.match(builder, /apk_build_edge/); assert.match(builder, /Sdk:\/opt\/android-sdk-linux:ro/);
    assert.match(builder, /\.\/apk\/releases:\/home\/app\/projects\/painel_provedores\/apk\/releases\n/);
    assert.match(builder, /APK_PUBLICATION_DIR=.*\/apk\/releases\/private/);
    assert.match(builder, /APK_OUTPUT_DIR=.*\/apk\/releases\/public/);
    assert.doesNotMatch(builder, /\.\/public_apks:/);
    assert.match(compose, /\.\/apk\/releases\/public:\/usr\/share\/nginx\/html\/public_apks\/f1:ro/);
    assert.doesNotMatch(fs.readFileSync(path.join(__dirname, 'index.js'), 'utf8'), /firebase-admin|\.\.\.process.env/);
});
