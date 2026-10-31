const { test } = require('node:test');
const assert = require('node:assert/strict');
const { selectExpiredRuns } = require('./backup-retention.cjs');
test('retention preserves last three complete backups and ignores unrelated paths', () => {
    const names = ['20260101T030000Z-1', '20260102T030000Z-2', '20260103T030000Z-3', '20260104T030000Z-4'];
    const objects = names.map(name => `backend_backups/runs/${name}/manifest.json`);
    objects.push('backend_backups/runs/20260105T030000Z-5/partial.rdb', 'backend_backups/runs/unrelated/manifest.json');
    assert.deepEqual([...selectExpiredRuns(objects, Date.parse('2026-03-01T00:00:00Z'))].sort(), [names[0], '20260105T030000Z-5'].sort());
    assert.equal(selectExpiredRuns(objects, Date.parse('2026-01-06T00:00:00Z')).size, 0);
});
