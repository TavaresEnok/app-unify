'use strict';
// Synthetic transport fixtures, reused by the actual API and proxy runtimes.
const assert = require('node:assert/strict');
const http = require('node:http');
const https = require('node:https');
const net = require('node:net');
const tls = require('node:tls');
const { once } = require('node:events');
const { mkdtempSync, readFileSync, rmSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { execFileSync } = require('node:child_process');

const PUBLIC = '8.8.8.8';
const records = () => [{ address: PUBLIC, family: 4 }];
function peer(socket, address = PUBLIC) { Object.defineProperty(socket, 'remoteAddress', { get: () => address }); return socket; }
async function listening(server) { server.listen(0, '127.0.0.1'); await once(server, 'listening'); return server.address().port; }
async function close(server) { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }

function scenarios(runtime) {
    return {
        'rejects reserved IPv6 allocations and gaps, including mixed DNS, before either connector': async () => {
            let connections = 0;
            const stop = () => { connections++; throw new Error('unexpected connector'); };
            const denied = ['2000::1', '2001:1000::1', '2001:11ff::1', '2001:4e00::1',
                '2001:6000::1', '2001:c000::1', '2003:4000::1', '2004::1', '23ff::1',
                '2420::1', '25ff::1', '2610:200::1', '2611::1', '2620:200::1', '2621::1',
                '2640::1', '2810::1', '2a20::1', '2c10::1', '2d00::1', '2e00::1',
                '3000::1', '3800::1', '3c00::1', '3e00::1', '3f00::1', '3f80::1',
                '3fc0::1', '3fe0::1', '3ff0::1', '3ff8::1', '3ffc::1', '3ffe::1', '3fff:ffff::1'];
            for (const address of denied) for (const scheme of ['http', 'https']) {
                const transport = runtime.createSgpTransport({ lookup: async () => [...records(), { address, family: 6 }], connect: stop, tlsConnect: stop });
                await assert.rejects(transport.request(`${scheme}://[${address}]/`, { token: 'synthetic-denied' }));
                await assert.rejects(transport.request(`${scheme}://sgp.test/`, { token: 'synthetic-denied' }));
                await assert.rejects(transport.assertSafeSgpBaseUrl(`${scheme}://sgp.test/`));
            }
            assert.equal(connections, 0);
            // Positive allocation boundaries guard against denying ordinary IPv6.
            const transport = runtime.createSgpTransport();
            for (const address of ['2001:200::1', '2001:fff::1', '2001:1200::1', '2001:3fff::1',
                '2001:4dff::1', '2001:5000::1', '2001:8000::1', '2001:bfff::1',
                '2003:3fff::1', '241f::1', '260f::1', '2610:1ff::1', '2620:1ff::1',
                '263f::1', '280f::1', '2a1f::1', '2c0f::1']) {
                assert.ok(await transport.assertSafeSgpBaseUrl(`https://[${address}]/`));
            }
        },
        'rejects literals, normalizations, reserved ranges, URL authority and DNS failures before connecting': async () => {
            let connections = 0;
            const transport = runtime.createSgpTransport({ lookup: records, connect: () => { connections++; throw new Error('unexpected socket'); } });
            for (const host of ['127.1', '2130706433', '0x7f000001', '10.1.2.3', '172.31.0.1', '192.168.0.1', '169.254.169.254', '100.64.0.1', '0.0.0.0', '224.0.0.1', '240.0.0.1', '192.0.2.1', '198.18.0.1', '198.51.100.2', '203.0.113.1', '[::]', '[::1]', '[fc00::1]', '[fe80::1]', '[ff02::1]', '[::ffff:8.8.8.8]', '[::ffff:7f00:1]', '[64:ff9b::808:808]', '[2001:db8::1]', '[2002:808:808::1]', '[3fff::1]']) {
                await assert.rejects(transport.request(`http://${host}/`, { token: 'synthetic-denied' }));
            }
            for (const url of ['https://user:pass@sgp.test/', 'https://@sgp.test/', 'https:sgp.test', 'https://sgp.test/?', 'https://sgp.test/#', 'https://sgp.test/?url=x', 'https://sgp.test/#x', 'ftp://sgp.test/', 'https://sgp.test/%2fsecret', 'https://sgp.test/\\evil']) await assert.rejects(transport.request(url, { token: 'synthetic-denied' }));
            for (const lookup of [async () => [], async () => { throw new Error('DNS failure'); }, async () => [...records(), { address: '10.0.0.1', family: 4 }], async () => [...records(), { address: 'fd00::1', family: 6 }]]) {
                await assert.rejects(runtime.createSgpTransport({ lookup, connect: () => { connections++; } }).request('https://sgp.test/', { token: 'synthetic-denied' }));
            }
            assert.equal(connections, 0);
            for (const path of ['//evil.test/', '/a/../b/', '/a?x=y', '/a#b', '/a/%2f/', '/a\\b/', 'https://evil.test/']) assert.throws(() => runtime.formatSgpUrl('https://sgp.test/prefix', path));
            assert.equal(runtime.formatSgpUrl('https://sgp.test/prefix/', '/api/ura/clientes/'), 'https://sgp.test/prefix/api/ura/clientes/');
        },
        'pins approved DNS until the socket, keeps Host, supports GET/form/JSON and ignores env proxies': async () => {
            const received = [];
            const server = http.createServer(async (req, res) => {
                let body = ''; for await (const chunk of req) body += chunk;
                received.push({ method: req.method, host: req.headers.host, type: req.headers['content-type'], url: req.url, body });
                res.end(JSON.stringify({ ok: true }));
            });
            const port = await listening(server);
            let lookups = 0;
            const targets = [];
            const transport = runtime.createSgpTransport({ lookup: async () => { lookups++; return lookups % 2 ? records() : [{ address: '127.0.0.1', family: 4 }]; }, connect: options => {
                targets.push(options); return peer(net.connect({ host: '127.0.0.1', port }));
            } });
            const before = Object.fromEntries(['HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'NO_PROXY'].map(k => [k, process.env[k]]));
            Object.assign(process.env, { HTTP_PROXY: 'http://127.0.0.1:1', HTTPS_PROXY: 'http://127.0.0.1:1', ALL_PROXY: 'http://127.0.0.1:1', NO_PROXY: '' });
            try {
                // DNS changes on the next lookup: one approved lookup per request,
                // no implicit DNS by the underlying socket.
                for (const [body, options] of [[{ token: 'synthetic-json' }, { encoding: 'json' }], [new URLSearchParams({ token: 'synthetic-form' }), {}], [undefined, { method: 'GET', params: { token: 'synthetic-get' } }]]) {
                    const base = `http://sgp.synthetic.test:${port}/api/test/`;
                    assert.equal((await transport.request(base, body, options)).data.ok, true);
                    await assert.rejects(transport.request(base, { token: 'synthetic-denied' }));
                }
                assert.equal(lookups, 6); assert.equal(targets.length, 3);
                assert.ok(targets.every(target => target.host === PUBLIC && target.family === 4));
                assert.ok(received.every(item => item.host === `sgp.synthetic.test:${port}`));
                assert.equal(received[0].body, '{"token":"synthetic-json"}');
                assert.equal(received[1].body, 'token=synthetic-form');
                assert.equal(received[1].type, 'application/x-www-form-urlencoded');
                assert.equal(received[2].method, 'GET'); assert.match(received[2].url, /token=synthetic-get/);
            } finally { for (const [key, value] of Object.entries(before)) if (value === undefined) delete process.env[key]; else process.env[key] = value; await close(server); }
        },
        'rejects peer mismatch and redirects without secret bytes at the forbidden receiver': async () => {
            let forbidden = 0;
            const receiver = http.createServer((_req, res) => { forbidden++; res.end('{}'); });
            const receiverPort = await listening(receiver);
            let initial = 0;
            const redirect = http.createServer((_req, res) => { initial++; res.writeHead(307, { Location: `http://127.0.0.1:${receiverPort}/capture` }); res.end(); });
            const port = await listening(redirect);
            try {
                const mismatch = runtime.createSgpTransport({ lookup: records, connect: () => net.connect({ host: '127.0.0.1', port: receiverPort }) });
                await assert.rejects(mismatch.request('http://sgp.test/', { token: 'synthetic-denied' }));
                const transport = runtime.createSgpTransport({ lookup: records, connect: () => peer(net.connect({ host: '127.0.0.1', port })) });
                await assert.rejects(transport.request('http://sgp.test/', { token: 'synthetic-redirect' }), /307/);
                assert.equal(initial, 1); assert.equal(forbidden, 0);
                for (const options of [{ agent: {} }, { proxy: false }, { url: 'http://evil/' }, { socketPath: '/tmp/x' }, { headers: { Host: 'evil' } }, { adapter: () => {} }, { lookup: records }]) await assert.rejects(transport.request('http://sgp.test/', { token: 'synthetic-denied' }, options));
                assert.equal(initial, 1);
            } finally { await close(redirect); await close(receiver); }
        },
        'preserves TLS SNI and hostname verification, rejects wrong certificates before HTTP bytes': async () => {
            // Ephemeral test CA/key only. Never reads host/application credentials.
            const dir = mkdtempSync(join(tmpdir(), 'sgp-tls-synthetic-'));
            let server;
            try {
                execFileSync('openssl', ['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1', '-subj', '/CN=sgp.synthetic.test', '-addext', 'subjectAltName=DNS:sgp.synthetic.test', '-keyout', join(dir, 'key'), '-out', join(dir, 'cert')], { stdio: 'ignore' });
                const cert = readFileSync(join(dir, 'cert'));
                let bytes = 0; const names = [];
                server = https.createServer({ key: readFileSync(join(dir, 'key')), cert }, (_req, res) => { bytes++; res.end('{"ok":true}'); });
                server.on('secureConnection', socket => names.push(socket.servername));
                server.on('tlsClientError', () => {});
                const port = await listening(server);
                const optionsSeen = [];
                const transport = runtime.createSgpTransport({ lookup: records, tlsConnect: options => {
                    optionsSeen.push(options);
                    return peer(tls.connect({ ...options, host: '127.0.0.1', port, ca: cert }));
                } });
                assert.equal((await transport.request('https://sgp.synthetic.test/', { token: 'synthetic-tls' })).data.ok, true);
                await assert.rejects(transport.request('https://wrong.synthetic.test/', { token: 'synthetic-denied' }));
                assert.equal(bytes, 1); assert.equal(names[0], 'sgp.synthetic.test');
                assert.equal(optionsSeen[0].host, PUBLIC); assert.equal(optionsSeen[0].rejectUnauthorized, true);
                assert.equal(optionsSeen[0].servername, 'sgp.synthetic.test');
                const untrusted = runtime.createSgpTransport({ lookup: records, tlsConnect: options => peer(tls.connect({ ...options, host: '127.0.0.1', port })) });
                await assert.rejects(untrusted.request('https://sgp.synthetic.test/', { token: 'synthetic-denied' }));
                assert.equal(bytes, 1);
            } finally { if (server) await close(server); rmSync(dir, { recursive: true, force: true }); }
        },
        'allows public IPv4/IPv6 literals without DNS, denies incomplete private integration': async () => {
            let lookups = 0; const targets = [];
            const transport = runtime.createSgpTransport({ lookup: async () => { lookups++; throw new Error('unexpected DNS'); }, connect: options => {
                targets.push(options); const socket = new net.Socket(); queueMicrotask(() => socket.destroy(new Error('synthetic stop'))); return socket;
            } });
            for (const host of [PUBLIC, '[2606:4700:4700::1111]']) await assert.rejects(transport.request(`http://${host}/`, {}), /synthetic stop/);
            assert.equal(lookups, 0); assert.equal(targets.length, 2); assert.equal(targets[1].family, 6);
            for (const integration of [undefined, {}, { apiToken: 'synthetic' }, { apiToken: 'synthetic', sgpBaseUrl: 'https://sgp.test/' }]) assert.throws(() => runtime.privateIntegration(integration));
        },
    };
}
module.exports = { scenarios };
