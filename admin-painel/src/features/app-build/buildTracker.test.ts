import { beforeEach, describe, expect, it, vi } from 'vitest';
import { currentBuildState, readStoredBuild, subscribeBuild, trackBuild } from './buildTracker';

class MemoryStorage {
    private data = new Map<string, string>();
    getItem(k: string) { return this.data.get(k) ?? null; }
    setItem(k: string, v: string) { this.data.set(k, v); }
    removeItem(k: string) { this.data.delete(k); }
}

const noSleep = () => Promise.resolve();

describe('buildTracker', () => {
    beforeEach(() => {
        vi.stubGlobal('window', { localStorage: new MemoryStorage(), setTimeout });
    });

    it('persiste o job em andamento e guarda o resultado ao terminar', async () => {
        const responses = [
            { ok: true, status: 200, body: { success: true, status: 'running' as const } },
            { ok: true, status: 200, body: { success: true, status: 'succeeded' as const, downloadUrl: '/public_apks/x.apk' } },
        ];
        const fetchJob = vi.fn(async () => responses.shift()!);
        const states: string[] = [];
        subscribeBuild('p1', (s) => states.push(s.kind));

        const run = trackBuild('p1', 'job-1', 'apk', async () => 't', fetchJob, { sleep: noSleep });
        expect(readStoredBuild('p1')?.jobId).toBe('job-1');
        expect(currentBuildState('p1').kind).toBe('running');

        const result = await run;
        expect(result.success).toBe(true);
        expect(result.downloadUrl).toBe('/public_apks/x.apk');
        const state = currentBuildState('p1');
        expect(state.kind).toBe('done');
        expect(states).toEqual(['running', 'done']);
    });

    it('não duplica o polling para o mesmo provedor', async () => {
        const fetchJob = vi.fn(async () => ({ ok: true, status: 200, body: { success: true, status: 'succeeded' as const } }));
        const a = trackBuild('p2', 'job-2', 'aab', async () => 't', fetchJob, { sleep: noSleep });
        const b = trackBuild('p2', 'job-2', 'aab', async () => 't', fetchJob, { sleep: noSleep });
        expect(a).toBe(b);
        await a;
        expect(fetchJob).toHaveBeenCalledTimes(1);
    });

    it('marca falha quando o job expirou no servidor (404)', async () => {
        const fetchJob = vi.fn(async () => ({ ok: false, status: 404, body: { success: false, error: 'Geração não encontrada ou expirada.' } }));
        const result = await trackBuild('p3', 'job-3', 'apk', async () => 't', fetchJob, { sleep: noSleep });
        expect(result.success).toBe(false);
        expect(result.error).toContain('expirada');
    });

    it('mantém o job salvo após falhas de rede para retomar depois', async () => {
        const fetchJob = vi.fn(async () => { throw new Error('offline'); });
        await expect(trackBuild('p4', 'job-4', 'apk', async () => 't', fetchJob, { sleep: noSleep })).rejects.toThrow('offline');
        expect(currentBuildState('p4').kind).toBe('running');
    });
});
