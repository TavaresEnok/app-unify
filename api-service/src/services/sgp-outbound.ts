// @ts-nocheck
'use strict';
// Canonical SGP boundary. Copies are checked by scripts/check-contracts.mjs.
const dns = require('node:dns/promises');
const net = require('node:net');
const tls = require('node:tls');
const http = require('node:http');
const https = require('node:https');

function denied() { return Object.assign(new Error('Destino SGP inválido ou interno; integração indisponível.'), { status: 503 }); }

function publicAddress(address) {
    if (net.isIP(address) === 4) {
        const [a, b, c] = address.split('.').map(Number);
        return !(a === 0 || a === 10 || a === 127 || a >= 224 ||
            (a === 100 && b >= 64 && b <= 127) || (a === 169 && b === 254) ||
            (a === 172 && b >= 16 && b <= 31) ||
            (a === 192 && (b === 168 || b === 0 || (b === 88 && c === 99))) ||
            (a === 198 && (b === 18 || b === 19 || (b === 51 && c === 100))) ||
            (a === 203 && b === 0 && c === 113));
    }
    if (net.isIP(address) !== 6) return false;
    // Fail closed outside allocated ordinary unicast, including unlisted gaps.
    // IANA ipv6-unicast-address-assignments (2025-10-10), checked 2026-10-31:
    // https://www.iana.org/assignments/ipv6-unicast-address-assignments/
    // Future allocations require an explicit policy update; no live registry fetch.
    const normalized = new URL(`http://[${address}]/`).hostname.slice(1, -1);
    const groups = normalized.split(':');
    const first = parseInt(groups[0], 16);
    const second = parseInt(groups[1] || '0', 16);
    if (!Number.isFinite(first) || !Number.isFinite(second)) return false;
    if (first === 0x2001) {
        // Exclude special-purpose 2001::/23 and documentation 2001:db8::/32.
        return second !== 0xdb8 && [[0x200, 0xfff], [0x1200, 0x3fff],
            [0x4000, 0x4dff], [0x5000, 0x5fff], [0x8000, 0xbfff]]
            .some(([start, end]) => second >= start && second <= end);
    }
    if (first === 0x2003) return second < 0x4000; // 2003::/18
    if (first === 0x2610 || first === 0x2620) return second < 0x200; // /23
    return [[0x2400, 0x241f], [0x2600, 0x260f], [0x2630, 0x263f],
        [0x2800, 0x280f], [0x2a00, 0x2a1f], [0x2c00, 0x2c0f]]
        .some(([start, end]) => first >= start && first <= end);
}

function parseSgpUrl(value) {
    if (typeof value !== 'string' || value !== value.trim() || /[\\\s]/.test(value) || /(?:^|\/)\.{1,2}(?:\/|$)/.test(value)) throw denied();
    let url;
    try { url = new URL(value); } catch { throw denied(); }
    if (!/^https?:\/\//i.test(value) || /^https?:\/\/[^/?#]*@/i.test(value) || !['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash || /[?#]/.test(value)) throw denied();
    const host = url.hostname.replace(/^\[|\]$/g, '');
    if (!host || host === 'localhost' || host.endsWith('.localhost') || (net.isIP(host) && !publicAddress(host))) throw denied();
    // No encoded separators/dot traversal in configured prefixes or final paths.
    if (/%(?:2e|2f|5c|25|00)/i.test(url.pathname)) throw denied();
    return url;
}

function formatSgpUrl(base, path) {
    const url = parseSgpUrl(base);
    if (typeof path !== 'string' || !/^\/(?:[a-z0-9_-]+\/)*[a-z0-9_-]*\/?$/i.test(path)) throw denied();
    return `${url.href.replace(/\/$/, '')}${path}`;
}

function privateIntegration(value) {
    if (!value || !['sgpBaseUrl', 'apiToken', 'appName'].every(k => typeof value[k] === 'string' && value[k].trim())) throw denied();
    return { baseUrl: parseSgpUrl(value.sgpBaseUrl.trim()).href.replace(/\/$/, ''), token: value.apiToken.trim(), app: value.appName.trim() };
}

function createSgpTransport({ lookup = (...args) => dns.lookup(...args), connect = options => net.connect(options), tlsConnect = options => tls.connect(options) } = {}) {
    let active = 0;
    const perHost = new Map();
    async function resolve(value) {
        const url = parseSgpUrl(value);
        const hostname = url.hostname.replace(/^\[|\]$/g, '');
        let addresses;
        let timer;
        try { addresses = net.isIP(hostname) ? [{ address: hostname, family: net.isIP(hostname) }] : await Promise.race([
            lookup(hostname, { all: true, verbatim: true }),
            new Promise((_, reject) => { timer = setTimeout(() => reject(denied()), 5000); }),
        ]); }
        catch { throw denied(); }
        finally { clearTimeout(timer); }
        if (!Array.isArray(addresses) || !addresses.length || addresses.some(item => !publicAddress(item.address))) throw denied();
        return { url, hostname, address: addresses[0].address, family: net.isIP(addresses[0].address) };
    }

    async function assertSafeSgpBaseUrl(value) { return (await resolve(value)).url.href.replace(/\/$/, ''); }

    async function request(value, body, options = {}) {
        // No axios config, adapter, destination, agent, lookup, proxy or header
        // overrides enter this boundary. Proxy environment is never consulted.
        if (Object.keys(options).some(k => !['method', 'encoding', 'params', 'timeout'].includes(k))) throw denied();
        const { url, hostname, address, family } = await resolve(value);
        const method = options.method || 'POST';
        if (!['POST', 'GET'].includes(method) || (options.encoding && !['form', 'json'].includes(options.encoding))) throw denied();
        const timeout = options.timeout || 30000;
        if (!Number.isFinite(timeout) || timeout < 1 || timeout > 60000) throw denied();
        if (options.params) {
            if (method !== 'GET') throw denied();
            for (const [key, val] of Object.entries(options.params)) if (val !== undefined && val !== null) url.searchParams.append(key, String(val));
        }
        const form = body instanceof URLSearchParams || options.encoding === 'form';
        const payload = method === 'GET' ? '' : form ? (body instanceof URLSearchParams ? body.toString() : new URLSearchParams(Object.entries(body || {}).filter(([, v]) => v !== undefined && v !== null).map(([k, v]) => [k, String(v)])).toString()) : JSON.stringify(body ?? {});
        if (Buffer.byteLength(payload) > 1024 * 1024) throw denied();
        const encrypted = url.protocol === 'https:';
        if (active >= 128 || (perHost.get(url.host) || 0) >= 16) throw denied();
        active++; perHost.set(url.host, (perHost.get(url.host) || 0) + 1);
        const agent = encrypted ? new https.Agent({ maxSockets: 16 }) : new http.Agent({ maxSockets: 16 });
        // Return the socket only AFTER peer validation / TLS authentication.
        // Request bytes (including GET query secrets) cannot precede this gate.
        let connection;
        agent.createConnection = (_options, callback) => {
            const socketOptions = { host: address, family, port: Number(url.port) || (encrypted ? 443 : 80) };
            const socket = encrypted ? tlsConnect({ ...socketOptions, servername: net.isIP(hostname) ? undefined : hostname,
                rejectUnauthorized: true, checkServerIdentity: (_host, cert) => tls.checkServerIdentity(hostname, cert) }) : connect(socketOptions);
            connection = socket;
            let done = false;
            const finish = error => { if (done) return; done = true; if (error) socket.destroy(); callback(error, error ? undefined : socket); };
            socket.once('error', finish);
            socket.once(encrypted ? 'secureConnect' : 'connect', () => {
                const peer = socket.remoteAddress?.replace(/^::ffff:/, '');
                let same = peer === address;
                if (net.isIP(peer) === 6 && family === 6) same = new URL(`http://[${peer}]`).hostname === new URL(`http://[${address}]`).hostname;
                if (!same || (encrypted && !socket.authorized)) return finish(denied());
                finish(null);
            });
            return undefined;
        };
        return new Promise((accept, reject) => {
            let timer;
            const fail = error => { clearTimeout(timer); connection?.destroy(); agent.destroy(); reject(error); };
            const req = (encrypted ? https : http).request(url, { method, agent, headers: {
                'User-Agent': 'Unify-SGP/1.0',
                ...(method === 'POST' ? { 'Content-Type': form ? 'application/x-www-form-urlencoded' : 'application/json', 'Content-Length': Buffer.byteLength(payload) } : {}),
            } }, res => {
                // No redirect is followed, even within the same origin.
                if (res.statusCode < 200 || res.statusCode >= 300) {
                    res.resume(); return fail(Object.assign(new Error(`SGP retornou HTTP ${res.statusCode}`), { response: { status: res.statusCode } }));
                }
                let size = 0;
                const chunks = [];
                res.on('data', chunk => { size += chunk.length; if (size > 8 * 1024 * 1024) { req.destroy(); fail(new Error('Resposta SGP excede limite.')); } else chunks.push(chunk); });
                res.on('error', fail);
                res.on('end', () => {
                    clearTimeout(timer); agent.destroy();
                    const raw = Buffer.concat(chunks).toString('utf8');
                    let data = raw;
                    try { data = JSON.parse(raw); } catch { /* preserve text response */ }
                    accept({ data, status: res.statusCode, headers: res.headers });
                });
            });
            timer = setTimeout(() => { const error = new Error('Timeout SGP.'); req.destroy(error); fail(error); }, timeout);
            req.on('error', fail);
            req.end(payload);
        }).finally(() => {
            active--;
            const count = perHost.get(url.host) - 1;
            if (count) perHost.set(url.host, count); else perHost.delete(url.host);
        });
    }
    return { assertSafeSgpBaseUrl, request };
}

export default { publicAddress, parseSgpUrl, formatSgpUrl, privateIntegration, createSgpTransport, ...createSgpTransport() };
