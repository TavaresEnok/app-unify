// Após um deploy os chunks antigos deixam de existir (nginx devolve 404).
// Uma aba aberta antes do deploy recarrega uma única vez para buscar o index novo.
const RELOAD_FLAG = "unify:chunk-reload-at";
const RELOAD_WINDOW_MS = 60_000;

export function isChunkLoadError(error: unknown): boolean {
  const message = error instanceof Error ? `${error.name} ${error.message}` : String(error ?? "");
  return /Failed to fetch dynamically imported module|error loading dynamically imported module|Importing a module script failed|ChunkLoadError|Loading chunk [\w-]+ failed/i.test(message);
}

interface ReloadDeps {
  storage?: Pick<Storage, "getItem" | "setItem"> | null;
  now?: () => number;
  reload?: () => void;
}

/** Recarrega a página uma vez por minuto no máximo. Devolve true se recarregou. */
export function reloadOnceForChunkError(deps: ReloadDeps = {}): boolean {
  const now = (deps.now ?? Date.now)();
  let storage = deps.storage;
  if (storage === undefined) {
    try { storage = typeof sessionStorage === "undefined" ? null : sessionStorage; } catch { storage = null; }
  }
  // Sem sessionStorage não há como evitar loop: não recarrega.
  if (!storage) return false;
  try {
    const last = Number(storage.getItem(RELOAD_FLAG) || 0);
    if (Number.isFinite(last) && now - last < RELOAD_WINDOW_MS) return false;
    storage.setItem(RELOAD_FLAG, String(now));
  } catch {
    return false;
  }
  (deps.reload ?? (() => window.location.reload()))();
  return true;
}
