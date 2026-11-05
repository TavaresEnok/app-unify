// Real password-login UI timing with short-lived test accounts; no credentials
// or subscriber data are emitted. Requires an explicit provider argument.
const admin = require('firebase-admin');
const { randomUUID, randomBytes } = require('node:crypto');
const { performance } = require('node:perf_hooks');
const fs = require('node:fs');
const { chromium } = require('../../admin-painel/node_modules/@playwright/test');
const base = process.env.SMOKE_BASE_URL;
const args = process.argv.slice(2), provider = args[args.indexOf('--provider') + 1];
if (!base?.startsWith('https://') || !args.includes('--provider') || !provider) throw Error('SMOKE_BASE_URL HTTPS e --provider são obrigatórios.');
admin.initializeApp();
(async () => {
    const browser = await chromium.launch({ headless: true }); const results = [];
    try {
        for (const role of ['superAdmin', 'providerAdmin']) {
            const uid = `panel-timing-${randomUUID()}`, email = `${uid}@example.invalid`, password = randomBytes(24).toString('base64url');
            await admin.auth().createUser({ uid, email, password });
            try {
                await admin.auth().setCustomUserClaims(uid, role === 'superAdmin' ? { role, superAdmin: true } : { role, providerId: provider });
                const context = await browser.newContext(), page = await context.newPage();
                const errors = [], dashboardResponses = [], authRequests = new Map(), network = []; let authMs;
                await page.addInitScript(() => {
                    document.addEventListener('submit', () => performance.mark('panel-submit'), { capture: true });
                    new MutationObserver(() => {
                        if (!performance.getEntriesByName('panel-submit').length) return;
                        if (document.querySelector('aside') && !performance.getEntriesByName('panel-shell').length) performance.mark('panel-shell');
                        if ([...document.querySelectorAll('h2')].some(node => node.textContent === 'Visão geral') && !performance.getEntriesByName('panel-data').length) performance.mark('panel-data');
                    }).observe(document, { childList: true, subtree: true });
                });
                page.on('pageerror', error => errors.push(error.message));
                page.on('request', request => { if (request.url().includes('accounts:signInWithPassword')) authRequests.set(request, performance.now()); });
                page.on('requestfinished', request => {
                    if (authRequests.has(request)) authMs = Math.round(performance.now() - authRequests.get(request));
                    const url = new URL(request.url());
                    if (url.protocol.startsWith('http')) network.push({ host: url.hostname, path: url.pathname, ...request.timing() });
                });
                page.on('response', response => { if (response.url().includes('/api/admin/dashboard/panel')) dashboardResponses.push(response.status()); });
                const start = performance.now();
                await page.goto(`${base}/painel/login`);
                await page.getByLabel(/e-mail|email/i).waitFor({ state: 'visible' });
                const loginPageMs = Math.round(performance.now() - start);
                await page.getByLabel(/e-mail|email/i).fill(email); await page.getByLabel(/senha/i).fill(password);
                const timingReported = page.waitForResponse(response => response.url().includes('/admin/performance') && response.status() === 204, { timeout: 45000 });
                const clicked = performance.now();
                await page.getByRole('button', { name: /entrar/i }).click();
                const [shellMs, dashboardMs] = await Promise.all([
                    page.locator('aside').waitFor({ state: 'visible', timeout: 45000 }).then(() => Math.round(performance.now() - clicked)),
                    page.getByRole('heading', { name: 'Visão geral', exact: true }).waitFor({ state: 'visible', timeout: 45000 }).then(() => Math.round(performance.now() - clicked)),
                ]);
                if (errors.length || dashboardResponses.length !== 1 || dashboardResponses[0] !== 200) throw Error('Falha no dashboard autenticado.');
                await timingReported;
                const marks = await page.evaluate(() => ({ origin: performance.timeOrigin, marks: Object.fromEntries(performance.getEntriesByType('mark').map(entry => [entry.name, entry.startTime])) }));
                const submitted = marks.origin + marks.marks['panel-submit'];
                const result = { role, loginPageMs, authenticationMs: authMs, clickToShellMs: shellMs, clickToDashboardDataMs: dashboardMs,
                    submitToShellMs: Math.round(marks.marks['panel-shell'] - marks.marks['panel-submit']), submitToDataMs: Math.round(marks.marks['panel-data'] - marks.marks['panel-submit']),
                    requestsAfterSubmit: network.filter(item => item.startTime >= submitted - 2).map(item => ({ host: item.host, path: item.path, startMs: Math.round(item.startTime - submitted), totalMs: Math.round(item.responseEnd) })),
                    dashboardHttp: 200, browserErrors: errors.length };
                results.push(result); console.log(JSON.stringify(result)); await context.close();
            } finally { await admin.auth().deleteUser(uid); }
        }
    } finally { await browser.close(); fs.writeFileSync('/tmp/painel-login-timing.json', JSON.stringify({ measuredAt: new Date().toISOString(), results }, null, 2), { mode: 0o600 }); }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
