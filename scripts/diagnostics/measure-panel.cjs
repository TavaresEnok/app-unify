// Explicit read-only production timing. Credentials/tokens never enter reports.
const admin = require('firebase-admin');
const fs = require('node:fs');
const { performance } = require('node:perf_hooks');
const { chromium } = require('../../admin-painel/node_modules/@playwright/test');
const args = process.argv.slice(2), arg = name => args[args.indexOf(name) + 1];
const base = process.env.SMOKE_BASE_URL;
if (!base?.startsWith('https://')) throw Error('SMOKE_BASE_URL HTTPS obrigatório.');
const apiKey = fs.readFileSync('admin-painel/src/firebase/auth.ts', 'utf8').match(/apiKey:\s*"([^"]+)"/)[1];
admin.initializeApp();
async function session(email) {
    const user = await admin.auth().getUserByEmail(email);
    const custom = await admin.auth().createCustomToken(user.uid);
    const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: custom, returnSecureToken: true }) });
    if (!response.ok) throw Error(`Sign-in HTTP ${response.status}`);
    const tokens = await response.json();
    return { uid: user.uid, email: user.email, emailVerified: user.emailVerified, isAnonymous: false,
        providerData: user.providerData.map(item => item.toJSON()), apiKey, appName: '[DEFAULT]',
        stsTokenManager: { refreshToken: tokens.refreshToken, accessToken: tokens.idToken, expirationTime: Date.now() + 3500000 } };
}
(async () => {
    const browser = await chromium.launch({ headless: true });
    const report = { measuredAt: new Date().toISOString(), measurements: [], limitation: 'Fresh browser with an already authenticated Firebase session; excludes email/password submission time and user network conditions.' };
    try {
        for (const [email, role] of [[arg('--super-email'), 'superAdmin'], [arg('--provider-email'), 'providerAdmin']]) {
            const value = await session(email);
            for (let run = 0; run < 2; run++) {
                const context = await browser.newContext(); const page = await context.newPage();
                const errors = [], timings = [];
                page.on('pageerror', error => errors.push(error.message));
                const starts = new Map();
                page.on('request', request => starts.set(request, performance.now()));
                page.on('requestfinished', request => {
                    const url = new URL(request.url());
                    if (url.protocol.startsWith('http')) timings.push({ host: url.hostname, path: url.pathname, ms: Math.round(performance.now() - starts.get(request)) });
                });
                await page.addInitScript(({ key, value }) => localStorage.setItem(key, JSON.stringify(value)), { key: `firebase:authUser:${apiKey}:[DEFAULT]`, value });
                const began = performance.now();
                await page.goto(`${base}/painel/login`, { waitUntil: 'domcontentloaded' });
                const [shellMs, dataMs] = await Promise.all([
                    page.locator('aside').waitFor({ state: 'visible', timeout: 90000 }).then(() => Math.round(performance.now() - began)),
                    page.getByRole('heading', { name: 'Visão geral', exact: true }).waitFor({ state: 'visible', timeout: 90000 }).then(() => Math.round(performance.now() - began)),
                ]);
                const metrics = { role, run: run + 1, shellMs, dataMs, errors, slowResources: timings.sort((a, b) => b.ms - a.ms).slice(0, 12) };
                report.measurements.push(metrics); console.log(JSON.stringify(metrics));
                await context.close();
            }
            const start = performance.now();
            const response = await fetch(`${base}/api/admin/dashboard`, { headers: { Authorization: `Bearer ${value.stsTokenManager.accessToken}` } });
            await response.arrayBuffer();
            console.log(JSON.stringify({ role, existingDashboardApiMs: Math.round(performance.now() - start), status: response.status }));
        }
    } finally { await browser.close(); fs.writeFileSync(process.env.PANEL_REPORT || '/tmp/painel-panel-timing.json', JSON.stringify(report, null, 2), { mode: 0o600 }); }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
