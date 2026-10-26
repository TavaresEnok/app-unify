const test = require('node:test');
const assert = require('node:assert/strict');
const { BuildJobStore } = require('./job-store');

test('tracks a build from preparation to completion', () => {
    const store = new BuildJobStore();
    store.create('job-1', { providerId: 'vibe' });
    store.update('job-1', { status: 'running', startedAt: Date.now() });
    store.update('job-1', {
        status: 'succeeded',
        completedAt: Date.now(),
        result: { downloadUrl: '/public_apks/app.apk' },
    });

    assert.equal(store.get('job-1').status, 'succeeded');
    assert.equal(store.get('job-1').result.downloadUrl, '/public_apks/app.apk');
});

test('expires completed jobs after the configured retention period', () => {
    const store = new BuildJobStore(10);
    store.create('job-1', { providerId: 'vibe' });
    store.update('job-1', { completedAt: Date.now() - 20 });

    assert.equal(store.get('job-1'), null);
});
