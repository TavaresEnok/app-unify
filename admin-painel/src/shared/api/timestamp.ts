export type TimestampValue = { toDate(): Date } | { _seconds: number } | { seconds: number } | string;

export function timestampDate(value: TimestampValue | undefined): Date | null {
  if (!value) return null;
  const date = typeof value === 'string' ? new Date(value)
    : 'toDate' in value ? value.toDate()
    : new Date(('_seconds' in value ? value._seconds : value.seconds) * 1000);
  return Number.isNaN(date.getTime()) ? null : date;
}
