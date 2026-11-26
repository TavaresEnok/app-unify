// @ts-nocheck
'use strict';
// Canonical SGP boundary. Copies are checked by scripts/check-contracts.mjs.
const dns = require('node:dns/promises');
const net = require('node:net');
const tls = require('node:tls');
const http = require('node:http');
const https = require('node:https');

function denied() { return Object.assign(new Error('Destino SGP inválido ou interno; integração indisponível.'), { status: 503 }); }
// Falha de DNS não é destino inválido: vira 503 próprio, não conta para o
// disjuntor do ERP e é registrada com o nome do host para o operador.
const DNS_UNAVAILABLE_MESSAGE = 'Não foi possível falar com o sistema do provedor agora. Tente novamente em instantes.';
function dnsUnavailable(hostname) {
    return Object.assign(new Error(DNS_UNAVAILABLE_MESSAGE), { status: 503, code: 'dns-unavailable', dnsFailure: true, publicMessage: DNS_UNAVAILABLE_MESSAGE, hostname });
}

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

const ERP_TYPES = ['sgp', 'ixc'];

function privateIntegration(value) {
    const erp = value && value.erp !== undefined ? String(value.erp).trim().toLowerCase() : 'sgp';
    // IXC autentica só pelo token do usuário de API; `appName` é conceito do SGP.
    const required = erp === 'ixc' ? ['sgpBaseUrl', 'apiToken'] : ['sgpBaseUrl', 'apiToken', 'appName'];
    if (!value || !ERP_TYPES.includes(erp) || !required.every(k => typeof value[k] === 'string' && value[k].trim())) throw denied();
    return { baseUrl: parseSgpUrl(value.sgpBaseUrl.trim()).href.replace(/\/$/, ''), token: value.apiToken.trim(), app: typeof value.appName === 'string' ? value.appName.trim() : '', erp };
}

// Único conjunto de cabeçalhos que um chamador pode definir (autenticação do ERP).
const ALLOWED_HEADERS = ['authorization', 'ixcsoft'];
function safeHeaders(headers) {
    if (headers === undefined) return {};
    if (!headers || typeof headers !== 'object' || Array.isArray(headers)) throw denied();
    const out = {};
    for (const [name, value] of Object.entries(headers)) {
        if (!ALLOWED_HEADERS.includes(name.toLowerCase()) || typeof value !== 'string' || !value || value.length > 4096 || /[\r\n]/.test(value)) throw denied();
        out[name.toLowerCase()] = value;
    }
    return out;
}

function createSgpTransport({ lookup = (...args) => dns.lookup(...args), connect = options => net.connect(options), tlsConnect = options => tls.connect(options),
    dnsCacheMs = 5 * 60 * 1000, dnsStaleMs = 60 * 60 * 1000, dnsTimeoutMs = 4000, dnsAttempts = 2, now = () => Date.now(), log = message => console.warn(message),
    idleSocketMs = 4000 } = {}) {
    let active = 0;
    const perHost = new Map();
    // Cache só de endereços já aprovados por publicAddress(). Cada uso passa de
    // novo pela checagem e o socket continua preso ao IP aprovado (sem DNS
    // implícito), então a proteção contra SSRF/rebinding não muda.
    const dnsCache = new Map();
    const safeAddresses = addresses => Array.isArray(addresses) && addresses.length > 0 && addresses.every(item => publicAddress(item?.address));
    async function lookupOnce(hostname) {
        let timer;
        try {
            return await Promise.race([
                Promise.resolve().then(() => lookup(hostname, { all: true, verbatim: true })),
                new Promise((_, reject) => { timer = setTimeout(() => reject(dnsUnavailable(hostname)), dnsTimeoutMs); }),
            ]);
        } finally { clearTimeout(timer); }
    }
    async function lookupHost(hostname) {
        const cached = dnsCache.get(hostname);
        if (cached && dnsCacheMs > 0 && now() - cached.at < dnsCacheMs && safeAddresses(cached.addresses)) return cached.addresses;
        for (let attempt = 0; attempt < Math.max(1, dnsAttempts); attempt++) {
            let addresses;
            try { addresses = await lookupOnce(hostname); } catch { continue; }
            // Resposta que aponta para faixa interna é recusa definitiva: nunca cai no cache antigo.
            if (!safeAddresses(addresses)) throw denied();
            if (dnsCacheMs > 0) {
                if (!dnsCache.has(hostname) && dnsCache.size >= 256) dnsCache.delete(dnsCache.keys().next().value);
                dnsCache.set(hostname, { addresses, at: now() });
            }
            return addresses;
        }
        if (cached && dnsStaleMs > 0 && now() - cached.at < dnsStaleMs && safeAddresses(cached.addresses)) {
            log(`[sgp-outbound] DNS indisponível para ${hostname}; usando endereço aprovado em cache.`);
            return cached.addresses;
        }
        log(`[sgp-outbound] DNS indisponível para ${hostname}.`);
        throw dnsUnavailable(hostname);
    }
    async function resolve(value) {
        const url = parseSgpUrl(value);
        const hostname = url.hostname.replace(/^\[|\]$/g, '');
        const addresses = net.isIP(hostname) ? [{ address: hostname, family: net.isIP(hostname) }] : await lookupHost(hostname);
        if (!safeAddresses(addresses)) throw denied();
        return { url, hostname, address: addresses[0].address, family: net.isIP(addresses[0].address) };
    }

    async function assertSafeSgpBaseUrl(value) { return (await resolve(value)).url.href.replace(/\/$/, ''); }

    // Um agente keep-alive por host+porta+IP aprovado: conexões TLS ao ERP são
    // reaproveitadas entre pedidos (o IXC/SGP fica bem mais rápido em rajadas).
    // Cada socket só entra no pool depois de validar o IP remoto (o mesmo que o
    // DNS aprovou) e o certificado; um IP novo gera outro agente, nunca reusa.
    const agents = new Map();
    function agentFor({ encrypted, hostname, address, family, port }) {
        const key = `${encrypted ? 'https' : 'http'}|${hostname}|${port}|${address}`;
        const existing = agents.get(key);
        if (existing) { agents.delete(key); agents.set(key, existing); return existing; }
        const agent = encrypted
            ? new https.Agent({ keepAlive: true, keepAliveMsecs: 1000, maxSockets: 16, maxFreeSockets: 8, timeout: idleSocketMs, scheduling: 'lifo' })
            : new http.Agent({ keepAlive: true, keepAliveMsecs: 1000, maxSockets: 16, maxFreeSockets: 8, timeout: idleSocketMs, scheduling: 'lifo' });
        agent.createConnection = (_options, callback) => {
            const socketOptions = { host: address, family, port };
            const socket = encrypted ? tlsConnect({ ...socketOptions, servername: net.isIP(hostname) ? undefined : hostname,
                rejectUnauthorized: true, checkServerIdentity: (_host, cert) => tls.checkServerIdentity(hostname, cert) }) : connect(socketOptions);
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
        // Agente antigo sai do mapa sem destruir: pedidos em curso terminam e os
        // sockets ociosos fecham sozinhos pelo `timeout`.
        if (agents.size >= 64) agents.delete(agents.keys().next().value);
        agents.set(key, agent);
        return agent;
    }

    async function request(value, body, options = {}) {
        // No axios config, adapter, destination, agent, lookup, proxy or header
        // overrides enter this boundary. Proxy environment is never consulted.
        if (Object.keys(options).some(k => !['method', 'encoding', 'params', 'timeout', 'headers'].includes(k))) throw denied();
        const { url, hostname, address, family } = await resolve(value);
        const method = options.method || 'POST';
        if (!['POST', 'GET'].includes(method) || (options.encoding && !['form', 'json'].includes(options.encoding))) throw denied();
        const extraHeaders = safeHeaders(options.headers);
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
        // O agente limita os sockets simultâneos (fila); este teto só barra excesso.
        if (active >= 256 || (perHost.get(url.host) || 0) >= 64) throw denied();
        active++; perHost.set(url.host, (perHost.get(url.host) || 0) + 1);
        // Return the socket only AFTER peer validation / TLS authentication.
        // Request bytes (including GET query secrets) cannot precede this gate.
        const agent = agentFor({ encrypted, hostname, address, family, port: Number(url.port) || (encrypted ? 443 : 80) });
        const send = retried => new Promise((accept, reject) => {
            let timer;
            let responded = false;
            let settled = false;
            let req;
            const fail = error => { clearTimeout(timer); req?.destroy(); if (!settled) { settled = true; reject(error); } };
            req = (encrypted ? https : http).request(url, { method, agent, headers: {
                'User-Agent': 'Unify-SGP/1.0',
                ...extraHeaders,
                ...(method === 'POST' ? { 'Content-Type': form ? 'application/x-www-form-urlencoded' : 'application/json', 'Content-Length': Buffer.byteLength(payload) } : {}),
            } }, res => {
                responded = true;
                // No redirect is followed, even within the same origin.
                if (res.statusCode < 200 || res.statusCode >= 300) {
                    if (res.statusCode >= 400 && res.statusCode < 500) {
                        const errChunks = [];
                        let errSize = 0;
                        res.on('data', chunk => {
                            if (errSize < 4096) {
                                errChunks.push(chunk.subarray(0, 4096 - errSize));
                                errSize += chunk.length;
                            }
                        });
                        res.on('error', () => fail(Object.assign(new Error(`SGP retornou HTTP ${res.statusCode}`), { response: { status: res.statusCode } })));
                        res.on('end', () => {
                            clearTimeout(timer);
                            const rawErr = Buffer.concat(errChunks).toString('utf8');
                            let errData;
                            try { errData = JSON.parse(rawErr); } catch { errData = undefined; }
                            settled = true;
                            reject(Object.assign(new Error(`SGP retornou HTTP ${res.statusCode}`), { response: { status: res.statusCode, data: errData } }));
                        });
                        return;
                    }
                    res.resume(); return fail(Object.assign(new Error(`SGP retornou HTTP ${res.statusCode}`), { response: { status: res.statusCode } }));
                }
                let size = 0;
                const chunks = [];
                res.on('data', chunk => { size += chunk.length; if (size > 8 * 1024 * 1024) fail(new Error('Resposta SGP excede limite.')); else chunks.push(chunk); });
                res.on('error', fail);
                res.on('end', () => {
                    clearTimeout(timer);
                    const raw = Buffer.concat(chunks).toString('utf8');
                    let data = raw;
                    try { data = JSON.parse(raw); } catch { /* preserve text response */ }
                    if (settled) return;
                    settled = true;
                    accept({ data, status: res.statusCode, headers: res.headers });
                });
            });
            timer = setTimeout(() => fail(new Error('Timeout SGP.')), timeout);
            req.on('error', error => {
                // Conexão ociosa fechada pelo ERP antes de ler o pedido: repete uma
                // vez num socket novo (nenhuma resposta chegou, nada foi processado).
                if (!retried && !responded && !settled && req.reusedSocket && ['ECONNRESET', 'EPIPE'].includes(error.code)) {
                    clearTimeout(timer);
                    settled = true;
                    send(true).then(accept, reject);
                    return;
                }
                fail(error);
            });
            req.end(payload);
        });
        return send(false).finally(() => {
            active--;
            const count = perHost.get(url.host) - 1;
            if (count) perHost.set(url.host, count); else perHost.delete(url.host);
        });
    }
    // Para testes e para o operador forçar nova resolução.
    function clearDnsCache() { dnsCache.clear(); }
    // Fecha conexões keep-alive (testes e desligamento).
    function closeIdleConnections() { for (const agent of agents.values()) agent.destroy(); agents.clear(); }
    return { assertSafeSgpBaseUrl, request, clearDnsCache, closeIdleConnections };
}

module.exports = { publicAddress, parseSgpUrl, formatSgpUrl, privateIntegration, safeHeaders, createSgpTransport, dnsUnavailable, DNS_UNAVAILABLE_MESSAGE, ...createSgpTransport() };
