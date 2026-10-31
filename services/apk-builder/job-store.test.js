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

test('preserves history and reports interrupted builds after restart', () => {
    const fs = require('fs');
    const os = require('os');
    const path = require('path');
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'unify-build-jobs-'));
    try {
        const file = path.join(directory, 'jobs.json');
        const first = new BuildJobStore(undefined, file);
        first.create('completed', { ownerUid: 'admin', providerId: 'alpha' });
        first.update('completed', { status: 'succeeded', completedAt: Date.now() });
        first.create('interrupted', { providerId: 'beta' });
        const restored = new BuildJobStore(undefined, file);
        assert.equal(restored.get('completed').status, 'succeeded');
        assert.equal(restored.get('interrupted').status, 'failed');
        assert.match(restored.get('interrupted').error, /reinício/);
    } finally { fs.rmSync(directory, { recursive: true, force: true }); }
});
