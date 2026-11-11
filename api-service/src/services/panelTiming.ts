type Timing = { flow: 'login' | 'restore'; totalMs: number; authMs: number; apiMs: number };
const samples: Array<Timing & { role: string; recordedAt: string }> = [];

export function recordPanelTiming(input: unknown, role: string): boolean {
  if (!input || typeof input !== 'object') return false;
  const data = input as Record<string, unknown>;
  if (Object.keys(data).some(key => !['flow', 'totalMs', 'authMs', 'apiMs'].includes(key))) return false;
  if (!['login', 'restore'].includes(String(data.flow))) return false;
  if (!['totalMs', 'authMs', 'apiMs'].every(key => typeof data[key] === 'number' && Number.isFinite(data[key]) && Number(data[key]) >= 0 && Number(data[key]) <= 120000)) return false;
  if (Number(data.authMs) > Number(data.totalMs) || Number(data.apiMs) > Number(data.totalMs)) return false;
  samples.push({ flow: data.flow as Timing['flow'], totalMs: Math.round(Number(data.totalMs)),
    authMs: Math.round(Number(data.authMs)), apiMs: Math.round(Number(data.apiMs)), role, recordedAt: new Date().toISOString() });
  if (samples.length > 100) samples.shift();
  return true;
}
export function panelTimings() {
  const cutoff = Date.now() - 86400000;
  return samples.filter(sample => Date.parse(sample.recordedAt) > cutoff);
}
