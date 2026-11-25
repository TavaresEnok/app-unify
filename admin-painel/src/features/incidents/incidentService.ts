import { clearPanelReads, panelRequest, readPanel } from "@/shared/api/panelHttp";

export type IncidentSeverity = "info" | "warning" | "critical";

export interface Incident {
  id: string;
  title: string;
  message: string;
  area?: string | null;
  severity?: IncidentSeverity;
  estimatedResolution?: string | null;
  active: boolean;
  createdAt?: { toDate: () => Date };
  resolvedAt?: { toDate: () => Date } | null;
}

interface RawIncident {
  id: string;
  title: string;
  message: string;
  area?: string | null;
  severity?: IncidentSeverity;
  estimatedResolution?: string | null;
  active: boolean;
  createdAt?: string | null;
  resolvedAt?: string | null;
}

function toTimestampAdapter(iso?: string | null): { toDate: () => Date } | undefined {
  if (!iso) return undefined;
  const parsed = new Date(iso);
  if (Number.isNaN(parsed.getTime())) return undefined;
  return { toDate: () => parsed };
}

function mapIncident(raw: RawIncident): Incident {
  return {
    id: raw.id,
    title: raw.title,
    message: raw.message,
    area: raw.area ?? null,
    severity: raw.severity ?? "warning",
    estimatedResolution: raw.estimatedResolution ?? null,
    active: Boolean(raw.active),
    createdAt: toTimestampAdapter(raw.createdAt),
    resolvedAt: toTimestampAdapter(raw.resolvedAt) ?? null,
  };
}

export async function listIncidents(providerId: string): Promise<Incident[]> {
  const body = await readPanel<{ data: RawIncident[] }>(`/admin/incidents?providerId=${encodeURIComponent(providerId)}`);
  return Array.isArray(body.data) ? body.data.map(mapIncident) : [];
}

export function subscribeIncidents(
  providerId: string,
  onValue: (items: Incident[]) => void,
  onError: (error: Error) => void,
): () => void {
  let stopped = false;
  let pending = false;
  let lastSerialized = "";

  const refresh = async () => {
    if (stopped || pending || document.visibilityState === "hidden") return;
    pending = true;
    try {
      const body = await readPanel<{ data: RawIncident[] }>(`/admin/incidents?providerId=${encodeURIComponent(providerId)}`);
      const raw = Array.isArray(body.data) ? body.data : [];
      const serialized = JSON.stringify(raw);
      if (!stopped && serialized !== lastSerialized) {
        lastSerialized = serialized;
        onValue(raw.map(mapIncident));
      }
    } catch (error) {
      if (!stopped) onError(error instanceof Error ? error : new Error("Erro ao carregar instabilidades."));
    } finally {
      pending = false;
    }
  };

  void refresh();
  const timer = setInterval(() => { void refresh(); }, 15_000);
  const resume = () => { if (document.visibilityState === "visible") void refresh(); };
  const onRefresh = () => { lastSerialized = ""; void refresh(); };
  document.addEventListener("visibilitychange", resume);
  if (typeof window !== "undefined") window.addEventListener("unify:refresh-incidents", onRefresh);
  return () => {
    stopped = true;
    clearInterval(timer);
    document.removeEventListener("visibilitychange", resume);
    if (typeof window !== "undefined") window.removeEventListener("unify:refresh-incidents", onRefresh);
  };
}

export async function createIncident(
  providerId: string,
  data: {
    title: string;
    message: string;
    area?: string;
    severity?: IncidentSeverity;
    estimatedResolution?: string;
  },
): Promise<unknown> {
  const res = await panelRequest("/admin/incidents", {
    method: "POST",
    body: {
      providerId,
      title: data.title.trim(),
      message: data.message.trim(),
      area: data.area?.trim() || null,
      severity: data.severity || "warning",
      estimatedResolution: data.estimatedResolution?.trim() || null,
    },
  });
  clearPanelReads();
  if (typeof window !== "undefined") window.dispatchEvent(new CustomEvent("unify:refresh-incidents"));
  return res;
}

export async function setIncidentActive(
  providerId: string,
  incidentId: string,
  active: boolean,
): Promise<void> {
  await panelRequest(`/admin/incidents/${encodeURIComponent(incidentId)}?providerId=${encodeURIComponent(providerId)}`, {
    method: "PATCH",
    body: { providerId, active },
  });
  clearPanelReads();
  if (typeof window !== "undefined") window.dispatchEvent(new CustomEvent("unify:refresh-incidents"));
}

export async function deleteIncident(providerId: string, incidentId: string): Promise<void> {
  await panelRequest(`/admin/incidents/${encodeURIComponent(incidentId)}?providerId=${encodeURIComponent(providerId)}`, {
    method: "DELETE",
  });
  clearPanelReads();
  if (typeof window !== "undefined") window.dispatchEvent(new CustomEvent("unify:refresh-incidents"));
}
