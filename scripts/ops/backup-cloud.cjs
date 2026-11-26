const admin = require('firebase-admin');
const { createHash } = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { selectExpiredRuns } = require('./backup-retention.cjs');
const { firestoreScope } = require('./backup-scope.cjs');
const { legacyExportEnabled, isFullFirestoreDay } = require('./backup-plan.cjs');
const runDir = process.argv[2];
const bucketName = process.env.PAINEL_BACKUP_BUCKET;
if (!runDir || !bucketName) throw new Error('Diretório e PAINEL_BACKUP_BUCKET são obrigatórios.');
admin.initializeApp();
const bucket = admin.storage().bucket(bucketName);
const runId = path.basename(runDir);
if (!/^\d{8}T\d{6}Z-\d+$/.test(runId)) throw new Error('Identificador de backup inválido.');
const prefix = `backend_backups/runs/${runId}/`;
const projectId = process.env.GOOGLE_CLOUD_PROJECT || 'app-ajust-provedor';
let firestoreAdmin = null;
async function upload(file, name) {
    const [object] = await bucket.upload(file, { destination: prefix + name, validation: 'crc32c',
        metadata: { cacheControl: 'no-store', contentType: 'application/octet-stream' } });
    const [metadata] = await object.getMetadata();
    return { name, bytes: Number(metadata.size), generation: metadata.generation };
}
// Firebase Auth legado (apps antigos até a transição acabar). Falha aqui não
// impede o envio do PostgreSQL, dos uploads e das chaves.
async function exportLegacyAuth() {
    // Password hashes/salts and claims remain private along with integration secrets.
    let pageToken; const users = [];
    do {
        const page = await admin.auth().listUsers(1000, pageToken);
        users.push(...page.users.map(user => user.toJSON())); pageToken = page.pageToken;
    } while (pageToken);
    await fs.writeFile(path.join(runDir, 'auth-users.json'), JSON.stringify({ users }), { mode: 0o600 });
    const { access_token: accessToken } = await admin.credential.applicationDefault().getAccessToken();
    const authConfig = await fetch(`https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`, { headers: { Authorization: `Bearer ${accessToken}` } });
    if (!authConfig.ok) throw new Error(`Não foi possível salvar a configuração Auth: HTTP ${authConfig.status}`);
    const config = await authConfig.json();
    if (users.some(user => user.passwordHash) && !config.signIn?.hashConfig?.signerKey) throw new Error('Configuração de hashes Auth ausente.');
    await fs.writeFile(path.join(runDir, 'auth-config.json'), JSON.stringify(config), { mode: 0o600 });
    return { users: users.length, hashConfigIncluded: !!config.signIn?.hashConfig?.signerKey };
}
async function startFirestoreExport(full) {
    const { v1: { FirestoreAdminClient } } = require('@google-cloud/firestore');
    firestoreAdmin = new FirestoreAdminClient();
    const collectionIds = firestoreScope((await admin.firestore().listCollections()).map(collection => collection.id), { full });
    const [operation] = await firestoreAdmin.exportDocuments({
        name: `projects/${projectId}/databases/(default)`,
        outputUriPrefix: `gs://${bucketName}/${prefix}firestore`,
        collectionIds,
    });
    console.log(JSON.stringify({ firestoreExportStarted: true, operation: operation.name }));
    await fs.writeFile(path.join(runDir, 'firestore-operation.json'), JSON.stringify({ name: operation.name }), { mode: 0o600 });
    return { operation, collectionIds };
}
async function backup() {
    const warnings = [];
    const legacy = legacyExportEnabled(process.env);
    const full = isFullFirestoreDay(new Date(), process.env);
    let auth = null; let firestore = null;
    if (legacy) {
        try { auth = await exportLegacyAuth(); } catch (error) { warnings.push(`auth: ${error.message}`); }
        try { firestore = await startFirestoreExport(full); } catch (error) { warnings.push(`firestore: ${error.message}`); }
    }
    const files = [];
    for (const name of (await fs.readdir(runDir)).filter(name => name !== 'manifest.json' && name !== 'manifest.pending.json')) {
        const file = path.join(runDir, name);
        const digest = createHash('sha256').update(await fs.readFile(file)).digest('hex');
        files.push({ ...await upload(file, name), sha256: digest });
    }
    let firestoreOutput = null;
    if (firestore) {
        try {
            const [result] = await firestore.operation.promise();
            firestoreOutput = result.outputUriPrefix;
        } catch (error) { warnings.push(`firestore: ${error.message}`); }
    }
    const manifest = { version: 2, runId, completedAt: new Date().toISOString(), files,
        firestoreOutput, authUsers: auth ? auth.users : null,
        limitations: ['Exports are not an atomic snapshot across services.'], authHashConfigIncluded: auth ? auth.hashConfigIncluded : null,
        legacyFirebaseExport: legacy, firestoreScope: !legacy ? 'disabled' : full ? 'full' : 'business-collections',
        firestoreCollections: firestore ? firestore.collectionIds : [], warnings };
    const file = path.join(runDir, 'manifest.pending.json');
    await fs.writeFile(file, JSON.stringify(manifest, null, 2), { mode: 0o600 });
    await upload(file, 'manifest.json'); // A run is valid only after this completion marker.
    await fs.rename(file, path.join(runDir, 'manifest.json'));
    console.log(JSON.stringify({ backupComplete: true, runId, files: files.length, authUsers: manifest.authUsers, warnings }));
    // Delete only our timestamped run namespace; never affect deployment snapshots.
    const [objects] = await bucket.getFiles({ prefix: 'backend_backups/runs/' });
    const expired = selectExpiredRuns(objects.map(object => object.name), Date.now(), 30, 3);
    for (const object of objects) if (expired.has(object.name.split('/')[2])) await object.delete({ ignoreNotFound: true });
    const localRoot = path.dirname(runDir);
    for (const name of await fs.readdir(localRoot)) {
        const age = Date.now() - (await fs.stat(path.join(localRoot, name))).mtimeMs;
        if (/^\d{8}T\d{6}Z-\d+$/.test(name) && name !== runId && age > 7 * 86400000) await fs.rm(path.join(localRoot, name), { recursive: true });
    }
    console.log(JSON.stringify({ remoteRetentionDays: 30, localRetentionDays: 7, expiredRunsRemoved: expired.size }));
}
backup().catch(error => { console.error(JSON.stringify({ backupFailed: true, message: error.message })); process.exitCode = 1; })
    .finally(() => firestoreAdmin?.close());
