'use strict';
const http = require('http');
const { isIP } = require('net');
const CHUNK = Buffer.alloc(128 * 1024);
function createServer(options = {}) {
    const maxConcurrent = Number(options.maxConcurrent || process.env.SPEED_TEST_MAX_CONCURRENT || 4);
    const maxMbps = Number(options.maxMbps || process.env.SPEED_TEST_MAX_MBPS || 300);
    const maxDuration = Number(options.maxDuration || process.env.SPEED_TEST_MAX_DURATION_MS || 20000);
    const byteLimit = 512 * 1024 * 1024;
    const clients = new Map();
    const transfers = new Set();
    const timer = setInterval(() => {
        // Um orçamento GLOBAL impede que mais conexões multipliquem o limite de banda.
        let budget = maxMbps * 1000000 / 8 / 20;
        const share = Math.max(1, Math.floor(budget / Math.max(1, transfers.size)));
        for (const transfer of transfers) {
            if (transfer.res.destroyed || Date.now() - transfer.start >= maxDuration) { transfer.res.end(); transfers.delete(transfer); continue; }
            let available = share;
            while (available > 0 && transfer.bytes < byteLimit && transfer.res.writableLength < 256 * 1024) {
                const size = Math.min(CHUNK.length, available, byteLimit - transfer.bytes);
                transfer.res.write(CHUNK.subarray(0, size)); transfer.bytes += size; available -= size;
            }
            if (transfer.bytes >= byteLimit) { transfer.res.end(); transfers.delete(transfer); }
        }
    }, 50);
    timer.unref();
    let active = 0;
    const server = http.createServer((req, res) => {
        const path = new URL(req.url, 'http://localhost').pathname;
        res.setHeader('Cache-Control', 'no-store');
        if (path === '/health' || path === '/capabilities') {
            res.setHeader('Content-Type', 'application/json');
            return res.end(JSON.stringify({ status: 'ok', active, maxConcurrent, maxMbps, maxDurationMs: maxDuration, sharedBandwidth: true }));
        }
        const origins = (process.env.ALLOWED_ORIGINS || '').split(',').map(value => value.trim());
        const origin = req.headers.origin;
        if (origin && !origins.includes(origin)) { res.writeHead(403); return res.end(); }
        res.setHeader('Access-Control-Allow-Origin', origin || '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET,POST,HEAD,OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        res.setHeader('Access-Control-Expose-Headers', 'X-SpeedTest-Limit-Mbps');
        res.setHeader('X-SpeedTest-Limit-Mbps', String(maxMbps));
        if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); }
        if (req.method === 'HEAD') { res.writeHead(200); return res.end(); }
        if (!['GET', 'POST'].includes(req.method)) { res.writeHead(405); return res.end(); }
        const remote = req.socket.remoteAddress || '';
        const forwarded = String(req.headers['x-forwarded-for'] || '').split(',')[0].trim();
        const trustedProxy = /^(::ffff:)?(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)/.test(remote) || remote === '::1';
        const ip = trustedProxy && isIP(forwarded) ? forwarded : remote;
        const prior = clients.get(ip);
        if (active >= maxConcurrent || (prior?.active || 0) >= maxConcurrent || (prior?.count || 0) >= 60) {
            res.writeHead(429, { 'Retry-After': '30' }); return res.end('Teste ocupado. Tente novamente.');
        }
        const record = prior || { active: 0, count: 0, since: Date.now() };
        record.active++; record.count++; clients.set(ip, record); active++;
        let released = false;
        const release = () => { if (released) return; released = true; active--; record.active--; };
        res.once('close', release);
        const timeout = setTimeout(() => { req.destroy(); res.destroy(); }, maxDuration + 1000);
        res.once('close', () => clearTimeout(timeout));
        res.setHeader('Content-Type', 'application/octet-stream');
        if (req.method === 'GET') {
            const transfer = { res, bytes: 0, start: Date.now() };
            transfers.add(transfer);
            res.once('close', () => transfers.delete(transfer));
        } else {
            let received = 0;
            // Aplica backpressure também ao upload: não drena a interface sem limite.
            const started = Date.now();
            req.on('data', chunk => {
                received += chunk.length;
                if (received > byteLimit) { req.destroy(); return; }
                const expectedMs = received / (maxMbps * 1000000 / 8 / Math.max(1, active)) * 1000;
                const delay = expectedMs - (Date.now() - started);
                if (delay > 0) { req.pause(); const resume = setTimeout(() => req.resume(), Math.min(delay, 1000)); resume.unref(); }
            });
            req.on('end', () => res.end('OK'));
        }
    });
    const prune = setInterval(() => { for (const [ip, value] of clients) if (!value.active && Date.now() - value.since > 60000) clients.delete(ip); }, 60000);
    prune.unref();
    server.on('close', () => { clearInterval(timer); clearInterval(prune); for (const transfer of transfers) transfer.res.destroy(); });
    server.headersTimeout = 10000;
    server.requestTimeout = maxDuration + 5000;
    server.maxConnections = maxConcurrent * 10;
    return server;
}
if (require.main === module) createServer().listen(3001, '0.0.0.0');
module.exports = { createServer };
