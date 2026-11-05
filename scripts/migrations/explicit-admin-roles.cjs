#!/usr/bin/env node
// Run inside api-service (Firebase Admin + ADC). Default is read-only.
const admin = require('firebase-admin');
if (!admin.apps.length) admin.initializeApp();
async function migrate({ apply = false, providerEmail, superEmail }) {
    if (!providerEmail || !superEmail) throw new Error('Informe os emails administrativos verificados; não promovemos usuários por providerId.');
    for (const [email, role] of [[superEmail, 'superAdmin'], [providerEmail, 'providerAdmin']]) {
        const user = await admin.auth().getUserByEmail(email);
        const claims = { ...(user.customClaims || {}) };
        if (role === 'superAdmin' && claims.superAdmin !== true) throw new Error('A conta indicada não é superAdmin.');
        if (role === 'providerAdmin' && (!claims.providerId || !user.providerData.some(item => item.providerId === 'password'))) throw new Error('A conta indicada não é um administrador conhecido com senha.');
        claims.role = role;
        if (apply) {
            await admin.auth().setCustomUserClaims(user.uid, claims);
            await admin.firestore().collection('users').doc(user.uid).set({ email, ...claims, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
        }
        console.log(JSON.stringify({ email, role, applied: apply }));
    }
}
const args = process.argv.slice(2);
const arg = name => args.includes(name) ? args[args.indexOf(name) + 1] : undefined;
migrate({ apply: args.includes('--apply'), providerEmail: arg('--provider-email'), superEmail: arg('--super-email') }).catch(error => { console.error(error.message); process.exitCode = 1; });
