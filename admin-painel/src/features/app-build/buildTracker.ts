// Acompanha gerações de APK/AAB fora do ciclo de vida da página: o build
// continua no apk-builder mesmo se o admin sair da tela, então guardamos o
// jobId (por provedor) e retomamos o acompanhamento ao voltar ou recarregar.

export type BuildFormat = 'apk' | 'aab';

export interface TrackedBuildResult {
    success: boolean;
    jobId?: string;
    status?: 'preparing' | 'running' | 'succeeded' | 'failed' | 'interrupted';
    format?: BuildFormat;
    error?: string;
    downloadUrl?: string;
    versionName?: string;
    versionCode?: string | number;
}

export interface StoredBuild {
    jobId: string;
    format: BuildFormat;
    startedAt: number;
    result?: TrackedBuildResult;
}

export type BuildState =
    | { kind: 'idle' }
    | { kind: 'running'; jobId: string; format: BuildFormat; startedAt: number }
    | { kind: 'done'; result: TrackedBuildResult };

const STORAGE_PREFIX = 'painel.apkBuild.';
const POLL_INTERVAL_MS = 2_000;
const POLL_TIMEOUT_MS = 30 * 60 * 1_000;
const RESULT_TTL_MS = 24 * 60 * 60 * 1_000;

type Fetcher = (jobId: string, token: string) => Promise<{ ok: boolean; status: number; body: TrackedBuildResult }>;
type Listener = (state: BuildState) => void;

const listeners = new Map<string, Set<Listener>>();
const active = new Map<string, Promise<TrackedBuildResult>>();

function storage(): Storage | null {
    try { return window.localStorage; } catch { return null; }
}

export function readStoredBuild(providerId: string, now = Date.now()): StoredBuild | null {
    try {
        const raw = storage()?.getItem(STORAGE_PREFIX + providerId);
        if (!raw) return null;
        const parsed = JSON.parse(raw) as StoredBuild;
        if (!parsed || typeof parsed.jobId !== 'string' || !parsed.jobId) return null;
        if (parsed.result && now - parsed.startedAt > RESULT_TTL_MS) return null;
        if (!parsed.result && now - parsed.startedAt > POLL_TIMEOUT_MS) return null;
        return parsed;
    } catch {
        return null;
    }
}

function writeStoredBuild(providerId: string, value: StoredBuild | null) {
    try {
        const s = storage();
        if (!s) return;
        if (value) s.setItem(STORAGE_PREFIX + providerId, JSON.stringify(value));
        else s.removeItem(STORAGE_PREFIX + providerId);
    } catch { /* armazenamento indisponível: só perde a retomada */ }
}

export function currentBuildState(providerId: string): BuildState {
    const stored = readStoredBuild(providerId);
    if (!stored) return { kind: 'idle' };
    if (stored.result) return { kind: 'done', result: stored.result };
    return { kind: 'running', jobId: stored.jobId, format: stored.format, startedAt: stored.startedAt };
}

function emit(providerId: string) {
    const state = currentBuildState(providerId);
    listeners.get(providerId)?.forEach((listener) => listener(state));
}

export function subscribeBuild(providerId: string, listener: Listener): () => void {
    let set = listeners.get(providerId);
    if (!set) { set = new Set(); listeners.set(providerId, set); }
    set.add(listener);
    return () => { set?.delete(listener); };
}

export function clearBuildResult(providerId: string) {
    const stored = readStoredBuild(providerId);
    if (stored?.result) { writeStoredBuild(providerId, null); emit(providerId); }
}

export function isBuildTracked(providerId: string) {
    return active.has(providerId);
}

/**
 * Acompanha um job até terminar. Chamadas repetidas para o mesmo provedor
 * reutilizam o mesmo acompanhamento (sem polling duplicado).
 */
export function trackBuild(
    providerId: string,
    jobId: string,
    format: BuildFormat,
    getToken: () => Promise<string>,
    fetchJob: Fetcher,
    options: { startedAt?: number; sleep?: (ms: number) => Promise<void>; now?: () => number } = {},
): Promise<TrackedBuildResult> {
    const existing = active.get(providerId);
    if (existing) return existing;
    const now = options.now ?? Date.now;
    const sleep = options.sleep ?? ((ms: number) => new Promise<void>((r) => window.setTimeout(r, ms)));
    const startedAt = options.startedAt ?? now();
    writeStoredBuild(providerId, { jobId, format, startedAt });
    emit(providerId);

    const finish = (result: TrackedBuildResult) => {
        writeStoredBuild(providerId, { jobId, format, startedAt, result: { ...result, format } });
        active.delete(providerId);
        emit(providerId);
        return { ...result, format };
    };

    const run = (async () => {
        const deadline = startedAt + POLL_TIMEOUT_MS;
        let networkErrors = 0;
        while (now() < deadline) {
            await sleep(POLL_INTERVAL_MS);
            let response;
            try {
                response = await fetchJob(jobId, await getToken());
                networkErrors = 0;
            } catch (error) {
                networkErrors += 1;
                if (networkErrors >= 5) {
                    // Falha de rede persistente: mantém o job salvo para retomar depois.
                    active.delete(providerId);
                    emit(providerId);
                    throw error;
                }
                continue;
            }
            const body = response.body || { success: false };
            if (!response.ok) {
                return finish({ success: false, error: body.error || `HTTP ${response.status}` });
            }
            if (body.status === 'succeeded') return finish({ ...body, success: true });
            if (body.status === 'failed' || body.status === 'interrupted') {
                return finish({ ...body, success: false, error: body.error || 'A geração do aplicativo falhou.' });
            }
        }
        return finish({ success: false, error: 'A geração excedeu o tempo máximo de 30 minutos.' });
    })();
    active.set(providerId, run);
    return run;
}
