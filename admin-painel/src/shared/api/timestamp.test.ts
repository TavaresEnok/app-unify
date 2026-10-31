import { expect, it } from 'vitest';
import { timestampDate } from './timestamp';
it('renders timestamps from HTTP and legacy Firestore snapshots', () => {
  const date = new Date('2026-10-29T10:00:00Z'), seconds = date.getTime() / 1000;
  for (const value of [{ _seconds: seconds }, { seconds }, { toDate: () => date }, date.toISOString()]) {
    expect(timestampDate(value)?.toISOString()).toBe(date.toISOString());
  }
  expect(timestampDate(undefined)).toBeNull(); expect(timestampDate('invalid')).toBeNull();
});
