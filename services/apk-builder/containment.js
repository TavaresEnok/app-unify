const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const normalized = value => value.normalize('NFKD').replace(/[^a-z0-9]/gi, '').toLowerCase();
function identity(registryPath, tenant, name) {
    const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));
    if (registry.schema !== 1 || registry.reviewed !== true || !Array.isArray(registry.identities)) throw Error('identity-registry-required');
    const rows = registry.identities;
    const tenants = new Set(), packages = new Set(), names = new Set(), normalizedIds = new Set();
    for (const row of rows) {
        if (!/^[a-z0-9_-]{1,64}$/i.test(row.providerId) || typeof row.appName !== 'string' ||
            !/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(row.applicationId) ||
            !/^[a-f0-9]{64}$/i.test(row.signingCertificateSha256) || row.inventoryReviewed !== true) throw Error('identity-registry-invalid');
        const n = normalized(row.appName), id = normalized(row.providerId);
        if (!n || !id || tenants.has(row.providerId) || packages.has(row.applicationId) || names.has(n) || normalizedIds.has(id)) throw Error('identity-registry-conflict');
        tenants.add(row.providerId); packages.add(row.applicationId); names.add(n); normalizedIds.add(id);
    }
    const row = rows.find(row => row.providerId === tenant);
    if (!row || row.appName !== name) throw Error('identity-inventory-required');
    return row;
}
function childEnvironment() {
    // Explicit allowlist, including fixed tool paths. No inherited bearer/ADC/SGP.
    return { PATH: '/sdks/flutter/bin:/opt/flutter/bin:/usr/local/flutter/bin:/usr/local/bin:/usr/bin:/bin',
        HOME: '/root', ANDROID_HOME: '/opt/android-sdk-linux', ANDROID_SDK_ROOT: '/opt/android-sdk-linux',
        PUB_CACHE: '/home/app/.pub-cache', LANG: 'C.UTF-8',
        GRADLE_OPTS: '-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx1536m' };
}
const digest = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
function verifyOutput(dir, expected) {
    const manifest = JSON.parse(fs.readFileSync(path.join(dir, 'manifest.json'), 'utf8'));
    for (const key of ['providerId', 'applicationId', 'versionCode', 'buildId', 'format']) {
        if (manifest[key] !== expected[key]) throw Error('invalid-build-manifest');
    }
    if (!Array.isArray(manifest.files) || !manifest.files.length) throw Error('invalid-build-manifest');
    for (const entry of manifest.files) {
        if (typeof entry.path !== 'string' || entry.path.includes('..') || path.isAbsolute(entry.path)) throw Error('invalid-build-file');
        const file = path.join(dir, entry.path);
        if (fs.lstatSync(file).isSymbolicLink() || !fs.statSync(file).isFile() || fs.statSync(file).size === 0 || digest(file) !== entry.sha256) throw Error('invalid-build-checksum');
    }
    const artifact = `artifact.${expected.format}`;
    if (!manifest.files.some(f => f.path === artifact) || (expected.format === 'aab' && !manifest.files.some(f => f.path.startsWith('symbols/')))) throw Error('missing-build-output');
    return path.join(dir, artifact);
}
async function authorize(endpoint, bearer, binding, fetcher = fetch) {
    if (typeof bearer !== 'string' || !bearer.startsWith('Bearer ')) throw Error('build-authorization-denied');
    let response, result;
    try {
        const url = new URL(endpoint);
        if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) throw Error();
        response = await fetcher(url, { method: 'POST', redirect: 'error', signal: AbortSignal.timeout(10_000),
            headers: { Authorization: bearer, 'Content-Type': 'application/json' }, body: JSON.stringify(binding) });
        if (response.status === 401 || response.status === 403) throw Error('build-authorization-denied');
        if (!response.ok) throw Error();
        result = await response.json();
    } catch (error) {
        if (response?.status === 401 || response?.status === 403) throw Error('build-authorization-denied');
        throw Object.assign(Error('authorization-unavailable'), { code: 'authorization-unavailable', status: 503 });
    }
    if (!result || typeof result.authorized !== 'boolean' || (result.authorized && (typeof result.uid !== 'string' || !result.uid))) {
        throw Object.assign(Error('authorization-unavailable'), { code: 'authorization-unavailable', status: 503 });
    }
    if (result.authorized !== true || Object.keys(binding).some(k => result[k] !== binding[k])) throw Error('build-authorization-denied');
    return result.uid;
}
module.exports = { identity, childEnvironment, verifyOutput, authorize, digest };
