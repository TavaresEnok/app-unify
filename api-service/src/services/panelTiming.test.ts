import { beforeEach, expect, it, vi } from 'vitest';
let timings: typeof import('./panelTiming');
beforeEach(async () => { vi.resetModules(); timings = await import('./panelTiming'); });
it('keeps only bounded numeric timings and rejects identity/customer fields', () => {
  const valid = { flow: 'login', totalMs: 1800, authMs: 1200, apiMs: 350 };
  expect(timings.recordPanelTiming(valid, 'providerAdmin')).toBe(true);
  for (const invalid of [{ ...valid, email: 'private@example.test' }, { ...valid, totalMs: Infinity }, { ...valid, apiMs: -1 }, { ...valid, authMs: 2000 }, { ...valid, flow: 'other' }]) {
    expect(timings.recordPanelTiming(invalid, 'providerAdmin')).toBe(false);
  }
  expect(timings.panelTimings()).toHaveLength(1);
  for (let i = 0; i < 120; i++) timings.recordPanelTiming(valid, 'providerAdmin');
  expect(timings.panelTimings()).toHaveLength(100);
});
