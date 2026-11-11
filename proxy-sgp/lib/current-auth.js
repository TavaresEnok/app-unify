'use strict';
const invalidCodes = new Set(['auth/id-token-revoked', 'auth/id-token-expired', 'auth/invalid-id-token', 'auth/argument-error', 'auth/user-disabled', 'auth/user-not-found']);
function authFailure(error) {
    if (['access/scope-changed', 'access/identity-conflict'].includes(error?.code)) return { status: 403, code: 'permission-denied' };
    const denied = invalidCodes.has(error?.code);
    return { status: denied ? 401 : 503, code: denied ? 'unauthenticated' : 'authorization-unavailable' };
}
async function currentIdentity(auth, token) {
    const identity = await auth.verifyIdToken(token, true);
    const current = await auth.getUser(identity.uid);
    if (current.disabled) throw Object.assign(new Error('Session denied'), { code: 'auth/user-disabled' });
    const claims = current.customClaims || {};
    if (claims.superAdmin === true && ['subscriber', 'providerAdmin'].includes(claims.role)) throw Object.assign(new Error('Conflicting role'), { code: 'access/scope-changed' });
    if ((identity.role || '') !== (claims.role || '') || (identity.providerId || '') !== (claims.providerId || '') ||
        (identity.superAdmin === true) !== (claims.superAdmin === true)) throw Object.assign(new Error('Access changed'), { code: 'access/scope-changed' });
    return { ...current.customClaims, uid: identity.uid };
}
// Called only after SGP password/contract verification. Never adopts another
// tenant or overwrites an administrative account, including in create races.
async function persistSubscriber(auth, identity) {
    let current;
    try { current = await auth.getUser(identity.uid); }
    catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
        try { current = await auth.createUser({ uid: identity.uid }); }
        catch (creation) {
            if (creation.code !== 'auth/uid-already-exists') throw creation;
            current = await auth.getUser(identity.uid);
        }
    }
    if (current.disabled) throw Object.assign(new Error('Session denied'), { code: 'auth/user-disabled' });
    const claims = current.customClaims || {};
    if (claims.superAdmin || (claims.role && claims.role !== 'subscriber') ||
        (claims.providerId && claims.providerId !== identity.claims.providerId) ||
        (claims.cpfCnpj && claims.cpfCnpj !== identity.claims.cpfCnpj)) {
        throw Object.assign(new Error('Identity conflict'), { code: 'access/identity-conflict' });
    }
    await auth.setCustomUserClaims(identity.uid, identity.claims);
    return auth.createCustomToken(identity.uid, identity.claims);
}
module.exports = { currentIdentity, authFailure, persistSubscriber };
