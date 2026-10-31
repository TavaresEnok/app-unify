'use strict';
async function migrateSubscriberProfile(db, identity, profile, serverTimestamp) {
    const { providerId, cpfCnpj } = identity.claims;
    const current = db.collection('clientes').doc(identity.uid);
    const legacy = db.collection('clientes').doc(cpfCnpj);
    await db.runTransaction(async transaction => {
        const [next, previous] = await Promise.all([transaction.get(current), transaction.get(legacy)]);
        const old = previous.exists && previous.data().providerId === providerId ? previous.data() : null;
        const fcmToken = next.data()?.fcmToken || old?.fcmToken;
        transaction.set(current, {
            authUid: identity.uid, cpfCnpj, providerId,
            nome: profile.nome || 'Cliente', plano: profile.plano || '', status: profile.status || '',
            ...(fcmToken ? { fcmToken } : {}), lastUpdated: serverTimestamp(),
        }, { merge: true });
        if (old) {
            const backup = db.collection('provedores').doc(providerId).collection('migration_backups').doc(`legacy-client-${cpfCnpj}`);
            transaction.set(backup, { profile: old, migratedTo: identity.uid, migratedAt: serverTimestamp() });
            transaction.delete(legacy);
        }
    });
}
module.exports = { migrateSubscriberProfile };
