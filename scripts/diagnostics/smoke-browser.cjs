// Authenticated browser checks using temporary custom-token sessions, not passwords.
const admin = require('firebase-admin');
const fs = require('fs');
const { randomUUID } = require('crypto');
const { chromium, expect } = require('../../admin-painel/node_modules/@playwright/test');
const args = process.argv.slice(2);
const arg = name => args[args.indexOf(name) + 1];
const base = process.env.SMOKE_BASE_URL;
if (!base?.startsWith('https://')) throw new Error('SMOKE_BASE_URL HTTPS é obrigatório.');
const config = fs.readFileSync('admin-painel/src/firebase/auth.ts', 'utf8');
const apiKey = config.match(/apiKey:\s*"([^"]+)"/)[1];
admin.initializeApp();
async function fixture(uid) {
    const user = await admin.auth().getUser(uid);
    const customToken = await admin.auth().createCustomToken(uid);
    const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    });
    if (!response.ok) throw new Error(`Custom login HTTP ${response.status}`);
    const tokens = await response.json();
    return { uid, email: user.email || null, emailVerified: user.emailVerified, isAnonymous: false,
        providerData: user.providerData.map(info => info.toJSON()), apiKey, appName: '[DEFAULT]',
        stsTokenManager: { refreshToken: tokens.refreshToken, accessToken: tokens.idToken, expirationTime: Date.now() + 3500000 },
    };
}
(async () => {
    const browser = await chromium.launch({ headless: true });
    const temporaryUid = `browser-security-check-${randomUUID()}`;
    await admin.auth().createUser({ uid: temporaryUid });
    try {
        await admin.auth().setCustomUserClaims(temporaryUid, { role: 'subscriber', providerId: arg('--provider'), cpfCnpj: '00000000000' });
        for (const [email, path, role] of [
            [arg('--super-email'), '/painel/dashboard', 'superAdmin'],
            [arg('--provider-email'), '/painel/provedor/dashboard', 'providerAdmin'],
            [null, '/painel/login', 'subscriber'],
        ]) {
            const uid = email ? (await admin.auth().getUserByEmail(email)).uid : temporaryUid;
            const value = await fixture(uid);
            const page = await browser.newPage(); const errors = [];
            page.on('pageerror', error => errors.push(error.message));
            await page.addInitScript(({ key, value }) => localStorage.setItem(key, JSON.stringify(value)), { key: `firebase:authUser:${apiKey}:[DEFAULT]`, value });
            await page.goto(`${base}/painel/login`);
            await expect(page).toHaveURL(`${base}${path}`, { timeout: 45000 });
            if (role === 'subscriber') {
                try { await expect(page.getByLabel(/e-mail|email/i)).toBeVisible({ timeout: 45000 }); }
                catch { console.error(JSON.stringify({ role, path: new URL(page.url()).pathname, text: (await page.locator('body').innerText()).slice(0, 160), browserErrors: errors })); throw new Error('Subscriber login rendering failed'); }
            }
            else await expect(page.locator('body')).not.toHaveText('');
            await page.waitForTimeout(1500);
            if (errors.length) throw new Error(`${role}: browser error ${errors[0]}`);
            console.log(JSON.stringify({ role, path: new URL(page.url()).pathname, errors: 0 }));
            await page.close();
        }
    } finally { await browser.close(); await admin.auth().deleteUser(temporaryUid); }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
