const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createServer } = require('./server');
test('bounds active transfers and exposes the server measurement ceiling', async () => {
    const server = createServer({ maxConcurrent: 1, maxMbps: 1, maxDuration: 1000 });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const url = `http://127.0.0.1:${server.address().port}`;
    const controller = new AbortController();
    try {
        const first = await fetch(`${url}/download`, { signal: controller.signal });
        assert.equal(first.headers.get('X-SpeedTest-Limit-Mbps'), '1');
        const second = await fetch(`${url}/download`);
        assert.equal(second.status, 429);
        const health = await (await fetch(`${url}/health`)).json();
        assert.equal(health.active, 1);
        assert.equal(health.maxMbps, 1);
    } finally {
        controller.abort(); server.closeAllConnections();
        await new Promise(resolve => server.close(resolve));
    }
});

test('sends Content-Length on GET download and accepts POST upload', async () => {
    const server = createServer({ maxConcurrent: 2, maxMbps: 100, maxDuration: 5000, downloadBytes: 128 * 1024 });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const url = `http://127.0.0.1:${server.address().port}`;
    try {
        const down = await fetch(`${url}/`);
        assert.equal(down.status, 200);
        assert.equal(down.headers.get('content-length'), String(128 * 1024));
        const buf = Buffer.from(await down.arrayBuffer());
        assert.equal(buf.length, 128 * 1024);

        const up = await fetch(`${url}/`, { method: 'POST', body: Buffer.alloc(64 * 1024) });
        assert.equal(up.status, 200);
        assert.equal(await up.text(), 'OK');
    } finally {
        server.closeAllConnections();
        await new Promise(resolve => server.close(resolve));
    }
});
