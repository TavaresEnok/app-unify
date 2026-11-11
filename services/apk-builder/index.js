const express = require('express');
const cors = require('cors');
const { rateLimit, ipKeyGenerator } = require('express-rate-limit');
const fs = require('node:fs');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const { spawn } = require('node:child_process');
const { BuildJobStore } = require('./job-store');
const { createLogoPolicy } = require('./security');
const { identity, childEnvironment, verifyOutput, authorize, digest } = require('./containment');

function createApp(options = {}) {
    const config = options.config || process.env;
    const root = config.APK_PROJECT_ROOT || process.cwd();
    const privateDir = config.APK_PRIVATE_DIR || path.join(root, 'apk', 'private');
    const output = config.APK_OUTPUT_DIR || path.join(root, 'public_apks');
    const publicationRoot = config.APK_PUBLICATION_DIR || privateDir;
    const jobs = options.jobs || new BuildJobStore(undefined, config.APK_JOB_STATE_PATH || path.join(privateDir, 'jobs.json'));
    const run = options.spawn || spawn;
    const logos = options.logos || createLogoPolicy((config.APK_LOGO_HOSTS || 'storage.googleapis.com,firebasestorage.googleapis.com').split(','));
    const check = (bearer, binding) => authorize(config.APK_AUTHORIZATION_URL, bearer, binding, options.fetch);
    let active = null;
    let activeChild = null;
    const app = express();
    app.disable('x-powered-by');
    app.use(cors({ origin: (config.ALLOWED_ORIGINS || 'http://localhost:5173,http://localhost:8031').split(',') }));
    app.use(express.json({ limit: '1mb' }));
    const limiter = rateLimit({ windowMs: 3600000, limit: 5, validate: false,
        keyGenerator: req => req.buildUid || ipKeyGenerator(req.ip), skip: () => options.disableRateLimit === true });
    const deny = res => res.status(403).json({ success: false, error: 'build-authorization-denied' });
    const unavailable = error => error?.code === 'authorization-unavailable';
    const authorizationFailure = (res, error) => unavailable(error)
        ? res.status(503).json({ success: false, error: 'authorization-unavailable' }) : deny(res);
    app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'apk-builder' }));
    app.get('/jobs/:jobId', async (req, res) => {
        const job = jobs.get(req.params.jobId);
        if (!job) return res.status(404).json({ success: false, error: 'Geração não encontrada ou expirada.' });
        try {
            const uid = await check(req.headers.authorization, { providerId: job.providerId, jobId: job.id, purpose: 'poll' });
            if (uid !== job.ownerUid) return deny(res);
        } catch (error) { return authorizationFailure(res, error); }
        return res.json({ success: !['failed', 'interrupted'].includes(job.status), jobId: job.id, status: job.status,
            providerId: job.providerId, createdAt: job.createdAt, startedAt: job.startedAt || null, completedAt: job.completedAt || null,
            ...(job.result || {}), ...(job.error ? { error: job.error } : {}) });
    });
    app.post('/jobs/:jobId/cancel', async (req, res) => {
        const job = jobs.get(req.params.jobId);
        if (!job) return res.status(404).json({ success: false, error: 'Geração não encontrada ou expirada.' });
        try {
            const uid = await check(req.headers.authorization, { providerId: job.providerId, jobId: job.id, purpose: 'request' });
            if (uid !== job.ownerUid) return deny(res);
        } catch (error) { return authorizationFailure(res, error); }
        if (!['preparing', 'running'].includes(job.status)) return res.status(409).json({ success: false, error: 'build-already-terminal' });
        jobs.update(job.id, { status: 'failed', completedAt: Date.now(), error: 'build-cancelled' });
        if (active === job.id && activeChild) {
            try { process.kill(-activeChild.pid, 'SIGKILL'); } catch { activeChild.kill('SIGKILL'); }
        }
        return res.json({ success: true, jobId: job.id, status: 'failed' });
    });
    app.post('/generate-apk', async (req, res, next) => {
        const { providerId } = req.body || {};
        req.buildId = randomUUID();
        try {
            req.buildUid = await check(req.headers.authorization, { providerId, jobId: req.buildId, purpose: 'request' });
            next();
        } catch (error) { authorizationFailure(res, error); }
    }, limiter, async (req, res) => {
        const { providerId, appName, logoUrl, format = 'apk', async: asynchronous = false } = req.body;
        if (!/^[a-z0-9_-]{1,64}$/i.test(providerId) || typeof appName !== 'string' || !appName || appName.length > 80 || /^-/.test(appName) ||
            /[\r\n\t\0]/.test(appName) || typeof logoUrl !== 'string' || !['apk', 'aab'].includes(format)) {
            return res.status(400).json({ success: false, error: 'Parâmetros de geração inválidos.' });
        }
        if (active) return res.status(409).json({ success: false, error: 'Já existe uma geração em andamento. Aguarde a conclusão.' });
        let registered;
        try { registered = identity(config.APK_IDENTITY_REGISTRY || path.join(privateDir, 'identities.json'), providerId, appName); }
        catch { return res.status(409).json({ success: false, error: 'identity-inventory-required' }); }
        const id = req.buildId;
        // The requester bearer lives only in this closure, never in jobs or children.
        const bearer = req.headers.authorization;
        const owner = req.buildUid;
        const revalidate = async purpose => {
            if (jobs.get(id)?.status === 'failed') throw Error('build-cancelled');
            if (await check(bearer, { providerId, jobId: id, purpose }) !== owner) throw Error('build-authorization-denied');
            if (jobs.get(id)?.status === 'failed') throw Error('build-cancelled');
        };
        const versionCode = String(Math.floor(Date.now() / 1000));
        const expected = { providerId, applicationId: registered.applicationId, versionCode, buildId: id, format };
        const staging = path.join(privateDir, 'staging', providerId, versionCode, id);
        const logo = path.join(privateDir, 'logos', `${id}.png`);
        active = id;
        jobs.create(id, { ownerUid: owner, providerId, appName, format, versionCode });
        let timer, child, finished = false;
        const fail = (code = 500, error = 'build-failed') => {
            if (finished) return;
            finished = true; clearTimeout(timer);
            if (child) { try { process.kill(-child.pid, 'SIGKILL'); } catch { child.kill('SIGKILL'); } }
            fs.rmSync(logo, { force: true });
            jobs.update(id, { status: 'failed', completedAt: Date.now(), error: jobs.get(id)?.error || error });
            active = null; activeChild = null;
            if (!res.headersSent) res.status(code).json({ success: false, error });
        };
        try {
            await revalidate('spawn'); // before logo download or private build output
            fs.mkdirSync(path.dirname(logo), { recursive: true, mode: 0o700 });
            await logos.download(logoUrl, logo);
            await revalidate('spawn'); // accepted then revoked must not spawn
            const args = [config.APK_SCRIPT_PATH || path.join(root, 'scripts/build/generate-apk.py'),
                '--id', providerId, '--nome', appName, '--logo', logo, '--output', staging,
                '--flutter-project', config.APK_FLUTTER_PROJECT || path.join(root, 'app-flutter/unified'),
                '--package', registered.applicationId, '--build-id', id, '--identity-registry', config.APK_IDENTITY_REGISTRY || path.join(privateDir, 'identities.json'),
                '--version-code', versionCode, '--version-name', `1.0.${versionCode}`, '--format', format, '--arm64'];
            if (format === 'aab') args.push('--obfuscate');
            if (config.PUBLIC_API_URL) args.push('--api-url', config.PUBLIC_API_URL);
            child = run(config.PYTHON_BIN || '/usr/bin/python3', args, { cwd: root, env: childEnvironment(), detached: true });
            activeChild = child;
            jobs.update(id, { status: 'running', startedAt: Date.now() });
            // Logs remain private and are never included in polling/public releases.
            const logDir = path.join(privateDir, 'logs'); fs.mkdirSync(logDir, { recursive: true, mode: 0o700 });
            const log = fs.createWriteStream(path.join(logDir, `${id}.log`), { flags: 'wx', mode: 0o600 });
            child.stdout.pipe(log, { end: false }); child.stderr.pipe(log, { end: false });
            log.on('error', () => { child.kill('SIGKILL'); fail(); });
            timer = setTimeout(() => {
                try { process.kill(-child.pid, 'SIGKILL'); } catch { child.kill('SIGKILL'); }
                fail(504, 'build-timeout');
            }, Number(config.APK_BUILD_TIMEOUT_MS || 1500000));
            child.on('error', () => { log.end(); fail(); });
            child.on('close', async code => {
                log.end(); clearTimeout(timer);
                if (finished) return;
                if (code !== 0) return fail();
                let publicationDir;
                try {
                    const artifact = verifyOutput(staging, expected);
                    // Prepare a complete, independent inode outside the served tree.
                    // A failed/partial copy can never become a public release.
                    const checksum = digest(artifact);
                    fs.mkdirSync(publicationRoot, { recursive: true, mode: 0o700 });
                    fs.chmodSync(publicationRoot, 0o700);
                    publicationDir = fs.mkdtempSync(path.join(publicationRoot, 'publication-'));
                    const prepared = path.join(publicationDir, `app.${format}`);
                    (options.copyArtifact || fs.copyFileSync)(artifact, prepared, fs.constants.COPYFILE_EXCL);
                    fs.chmodSync(prepared, 0o600);
                    if (!fs.lstatSync(prepared).isFile() || fs.statSync(prepared).size === 0 || digest(prepared) !== checksum) {
                        throw Error('invalid-publication-copy');
                    }
                    const fd = fs.openSync(prepared, 'r');
                    try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
                    // Readers need the final binary; the containing private directory
                    // remains 0700 until the verified inode is linked into public output.
                    fs.chmodSync(prepared, 0o644);
                    await revalidate('publish');
                    const releaseDir = path.join(output, providerId, versionCode, id);
                    fs.mkdirSync(releaseDir, { recursive: true });
                    // Atomic and exclusive: link fails on EEXIST or EXDEV. Never
                    // fall back to copying into the served tree or replacing a release.
                    (options.publishLink || fs.linkSync)(prepared, path.join(releaseDir, `app.${format}`));
                    const result = { success: true, downloadUrl: `${config.APK_PUBLIC_URL_PREFIX || '/public_apks'}/${providerId}/${versionCode}/${id}/app.${format}`,
                        versionCode, versionName: `1.0.${versionCode}` };
                    jobs.update(id, { status: 'succeeded', completedAt: Date.now(), result });
                    finished = true; active = null; activeChild = null; fs.rmSync(logo, { force: true });
                    if (!res.headersSent) res.json(result);
                } catch (error) { fail(unavailable(error) ? 503 : 403, unavailable(error) ? 'authorization-unavailable' : 'build-release-denied'); }
                finally {
                    // Unlinking the private copy cannot affect an already linked release.
                    // Cleanup failure must not misreport a completed public effect.
                    if (publicationDir) { try { fs.rmSync(publicationDir, { recursive: true, force: true }); } catch {} }
                }
            });
            if (asynchronous === true) res.status(202).json({ success: true, jobId: id, status: 'running' });
        } catch (error) { fail(unavailable(error) ? 503 : 403, unavailable(error) ? 'authorization-unavailable' : 'build-authorization-or-preparation-failed'); }
    });
    return app;
}
if (require.main === module) createApp().listen(Number(process.env.APK_BUILDER_PORT || 8035));
module.exports = { createApp };
