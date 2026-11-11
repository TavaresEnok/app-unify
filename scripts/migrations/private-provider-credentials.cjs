// Moves historical public SGP credentials to the private backend document.
// Default is read-only. Backups use migration_backups (denied to client SDKs).
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();
const apply = process.argv.includes('--apply');
const sensitive = ['apiToken', 'api_token', 'token', 'password', 'senha', 'secret'];
(async () => {
    for (const snapshot of (await db.collection('provedores').get()).docs) {
        const changed = await db.runTransaction(async transaction => {
            const ref = snapshot.ref;
            const secretRef = ref.collection('secrets').doc('sgp');
            const [current, secret] = await Promise.all([transaction.get(ref), transaction.get(secretRef)]);
            const data = current.data();
            const updates = {};
            for (const parent of ['', 'details.', 'config.']) {
                const value = parent === '' ? data : parent === 'details.' ? data.details : data.config;
                for (const key of [...sensitive, 'integrations']) {
                    if (value && Object.hasOwn(value, key)) updates[parent + key] = admin.firestore.FieldValue.delete();
                }
            }
            if (!Object.keys(updates).length) return false;
            const integrations = {
                ...(data.details?.apiToken ? { apiToken: data.details.apiToken, appName: data.details.appName, sgpBaseUrl: data.details.systemUrl } : {}),
                ...data.config?.integrations, ...data.integrations, ...secret.data()?.integrations,
            };
            for (const key of Object.keys(integrations)) if (integrations[key] === undefined) delete integrations[key];
            if (!integrations.apiToken || !integrations.sgpBaseUrl) throw new Error('Credenciais privadas incompletas; migração interrompida.');
            if (apply) {
                transaction.set(ref.collection('migration_backups').doc('public-credentials-v1'), {
                    integrations: data.integrations || null, config: data.config || null, details: data.details || null,
                    migratedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                transaction.set(secretRef, { integrations }, { merge: true });
                transaction.update(ref, updates);
            }
            return true;
        });
        console.log(JSON.stringify({ providerId: snapshot.id, credentialsFound: changed, applied: apply && changed }));
    }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
