'use strict';
const { Queue } = require('bullmq');
const Redis = require('ioredis');
const { createHash } = require('crypto');
const queueName = process.env.JOBS_QUEUE_NAME || 'provider-jobs';
let queue;
function connection() {
    if (!process.env.JOBS_REDIS_URL) throw new Error('JOBS_REDIS_URL é obrigatório para trabalhos persistentes.');
    return new Redis(process.env.JOBS_REDIS_URL, { maxRetriesPerRequest: null });
}
function getQueue() {
    if (!queue) queue = new Queue(queueName, { connection: connection(), defaultJobOptions: {
        attempts: 5, backoff: { type: 'exponential', delay: 3000 },
        removeOnComplete: { age: 2 * 86400 }, removeOnFail: { age: 7 * 86400 },
    } });
    return queue;
}
function jobId(...parts) { return createHash('sha256').update(JSON.stringify(parts)).digest('hex'); }
async function enqueueSync(providerId) {
    if (typeof providerId !== 'string' || !/^[a-z0-9_-]{1,64}$/i.test(providerId)) throw new Error('Provedor inválido.');
    const id = jobId('sync', providerId);
    const queue = getQueue();
    const previous = await queue.getJob(id);
    if (previous && ['completed', 'failed'].includes(await previous.getState())) await previous.remove();
    return queue.add('sync-clients', { providerId, page: 1, count: 0 }, { jobId: id });
}
module.exports = { queueName, connection, getQueue, enqueueSync, jobId };
