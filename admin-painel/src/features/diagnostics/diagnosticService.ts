import { clearPanelReads, panelRequest, readPanel } from "@/shared/api/panelHttp";

export type Unsubscribe = () => void;

export function subscribeDiagnostics<T>(
  providerId: string,
  onValue: (items: T[]) => void,
  onError: (error: Error) => void,
  maxItems = 150,
): Unsubscribe {
  let stopped = false;
  let pending = false;

  const refresh = async () => {
    if (stopped || pending || document.visibilityState === "hidden") return;
    pending = true;
    try {
      const body = await readPanel<{ items?: T[]; data?: T[] }>(
        `/admin/diagnostics?providerId=${encodeURIComponent(providerId)}&limit=${maxItems}`,
      );
      const items = Array.isArray(body.items) ? body.items : Array.isArray(body.data) ? body.data : [];
      if (!stopped) onValue(items);
    } catch (error) {
      if (!stopped) onError(error instanceof Error ? error : new Error("Erro ao carregar diagnósticos."));
    } finally {
      pending = false;
    }
  };

  void refresh();
  const timer = setInterval(() => { void refresh(); }, 15_000);
  const resume = () => { if (document.visibilityState === "visible") void refresh(); };
  document.addEventListener("visibilitychange", resume);
  return () => {
    stopped = true;
    clearInterval(timer);
    document.removeEventListener("visibilitychange", resume);
  };
}

export async function deleteDiagnostic(providerId: string, resultId: string): Promise<void> {
  await panelRequest(
    `/admin/diagnostics/${encodeURIComponent(resultId)}?providerId=${encodeURIComponent(providerId)}`,
    { method: "DELETE" },
  );
  clearPanelReads();
}
