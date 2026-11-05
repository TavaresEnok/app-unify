// Explicit production smoke check. Creates only read-only queue work and one
// temporary Auth user; never sends notifications or mutates subscriber data.
const admin = require('firebase-admin');
const fs = require('fs');
const { randomUUID } = require('crypto');
const args = process.argv.slice(2);
const arg = name => args.includes(name) ? args[args.indexOf(name) + 1] : undefined;
const base = process.env.SMOKE_BASE_URL;
if (!base || !base.startsWith('https://')) throw new Error('SMOKE_BASE_URL HTTPS é obrigatório.');
const publicConfig = fs.readFileSync('admin-painel/src/firebase/auth.ts', 'utf8');
const apiKey = publicConfig.match(/apiKey:\s*"([^"]+)"/)[1];
const project = publicConfig.match(/projectId:\s*"([^"]+)"/)[1];
admin.initializeApp();
const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
async function tokenFor(uid) {
    const customToken = await admin.auth().createCustomToken(uid);
    const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    });
    if (!response.ok) throw new Error(`Firebase sign-in HTTP ${response.status}`);
    return (await response.json()).idToken;
}
const headers = token => ({ Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' });
function field(value) {
    if (typeof value === 'string') return { stringValue: value };
    if (typeof value === 'number') return { integerValue: String(value) };
    return { mapValue: { fields: Object.fromEntries(Object.entries(value).map(([key, value]) => [key, field(value)])) } };
}
function decode(value) {
    if (value.mapValue) return Object.fromEntries(Object.entries(value.mapValue.fields || {}).map(([key, value]) => [key, decode(value)]));
    if (value.arrayValue) return (value.arrayValue.values || []).map(decode);
    if (value.integerValue !== undefined) return Number(value.integerValue);
    return value.stringValue ?? value.doubleValue ?? value.booleanValue ?? null;
}
async function callQueue(token, uid, type, payload) {
    const id = `smoke-${randomUUID()}`;
    const created = await fetch(`${firestoreUrl}/function_requests?documentId=${id}`, {
        method: 'POST', headers: headers(token), body: JSON.stringify({ fields: {
            type: field(type), requesterUid: field(uid), payload: field(payload), createdAt: { timestampValue: new Date().toISOString() },
        } }),
    });
    if (!created.ok) throw new Error(`${type}: queue HTTP ${created.status}`);
    for (let i = 0; i < 90; i++) {
        const response = await fetch(`${firestoreUrl}/function_responses/${id}`, { headers: headers(token) });
        if (response.ok) {
            const data = (await response.json()).fields;
            if (data.error) throw new Error(`${type}: ${data.error.stringValue}`);
            return decode(data.result);
        }
        if (response.status !== 404) throw new Error(`${type}: response HTTP ${response.status}`);
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    throw new Error(`${type}: timeout`);
}
(async () => {
    const providerId = arg('--provider');
    for (const [email, provider] of [[arg('--super-email'), null], [arg('--provider-email'), providerId]]) {
        const user = await admin.auth().getUserByEmail(email);
        const token = await tokenFor(user.uid);
        const response = await fetch(`${base}/api/admin/providers`, { headers: headers(token) });
        if (response.status !== 200) throw new Error(`Admin providers HTTP ${response.status}`);
        const providers = (await response.json()).data;
        if (provider && providers.some(item => item.id !== provider)) throw new Error('Tenant isolation failed');
        const data = await callQueue(token, user.uid, provider ? 'GET_PROVIDER_DASHBOARD_DATA' : 'GET_DASHBOARD_DATA', provider ? { providerId: provider } : {});
        if (!data.stats) throw new Error('Dashboard missing stats');
        const panel = await fetch(`${base}/api/admin/dashboard/panel${provider ? `/providers/${encodeURIComponent(provider)}` : ''}`, { headers: headers(token) });
        if (!panel.ok || !(await panel.json()).data?.stats) throw new Error(`Direct dashboard HTTP ${panel.status}`);
        if (provider) {
            const page = await callQueue(token, user.uid, 'SGP_API_PROXY', { providerId: provider, action: 'get', params: { limit: 25 } });
            if (page.clientes.length > 25) throw new Error('Client pagination exceeded limit');
            console.log(JSON.stringify({ role: 'providerAdmin', dashboard: 'ok', clientsReturned: page.clientes.length, clientsTotal: page.paginacao.total }));
            if (args.includes('--sync')) {
                const sync = await callQueue(token, user.uid, 'SGP_API_PROXY', { providerId: provider, action: 'sync' });
                console.log(JSON.stringify({ sync: 'queued', jobId: sync.jobId }));
                let completed = false;
                for (let i = 0; i < 120; i++) {
                    await new Promise(resolve => setTimeout(resolve, 5000));
                    const status = await callQueue(token, user.uid, 'SGP_API_PROXY', { providerId: provider, action: 'status', params: { jobId: sync.jobId } });
                    if (status.status === 'failed') throw new Error('Provider synchronization failed; inspect worker logs.');
                    if (status.status === 'completed') { console.log(JSON.stringify({ sync: 'completed', count: status.count })); completed = true; break; }
                }
                if (!completed) throw new Error('Provider synchronization timeout');
            }
        } else console.log(JSON.stringify({ role: 'superAdmin', dashboard: 'ok' }));
    }
    if (args.includes('--security-probe')) {
        const uid = `security-check-${randomUUID()}`;
        await admin.auth().createUser({ uid });
        try {
            await admin.auth().setCustomUserClaims(uid, { role: 'subscriber', providerId, cpfCnpj: '00000000000' });
            const token = await tokenFor(uid);
            for (const url of [`${base}/api/admin/providers`, `${base}/api/admin/dashboard/panel`, `${base}/api/admin/dashboard/panel/providers/${encodeURIComponent(providerId)}`, `${firestoreUrl}/provedores/${providerId}/secrets/sgp`]) {
                const response = await fetch(url, { headers: headers(token) });
                if (response.status !== 403) throw new Error(`Subscriber permission regression: HTTP ${response.status}`);
            }
            const response = await fetch(`${base}/api/getClientData`, { method: 'POST', headers: headers(token), body: JSON.stringify({ cpfCnpj: '99999999999' }) });
            if (response.status !== 403) throw new Error(`Peer access regression: HTTP ${response.status}`);
            console.log(JSON.stringify({ role: 'subscriber', adminDenied: true, secretsDenied: true, peerDenied: true }));
        } finally { await admin.auth().deleteUser(uid); }
    }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
