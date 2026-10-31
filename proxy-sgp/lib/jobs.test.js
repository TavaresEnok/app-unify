'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('crypto');
const Redis = require('ioredis');
const { Queue, Worker, QueueEvents } = require('bullmq');

test('queued work survives reconnects and retries resume persisted progress', { skip: !process.env.REDIS_TEST_URL }, async () => {
    const name = `test-jobs-${randomUUID()}`;
    const connection = new Redis(process.env.REDIS_TEST_URL, { maxRetriesPerRequest: null });
    const queue = new Queue(name, { connection });
    const events = new QueueEvents(name, { connection });
    await events.waitUntilReady();
    let worker;
    try {
        const created = await queue.add('sync', { providerId: 'alpha', page: 1 }, { attempts: 2, backoff: { type: 'fixed', delay: 20 } });
        await queue.close();
        const reopened = new Queue(name, { connection });
        const restored = await reopened.getJob(created.id);
        assert.equal(restored.data.providerId, 'alpha');
        const pages = [];
        worker = new Worker(name, async job => {
            pages.push(job.data.page);
            if (job.data.page === 1) { await job.updateData({ ...job.data, page: 2 }); throw new Error('simulated interruption'); }
            return { count: 5000 };
        }, { connection });
        const result = await restored.waitUntilFinished(events, 10000);
        assert.deepEqual(pages, [1, 2]);
        assert.equal(result.count, 5000);
        await worker.close(); worker = null;
        await reopened.obliterate(); await reopened.close();
    } finally { if (worker) await worker.close(); await events.close(); await queue.close(); await connection.quit(); }
});
