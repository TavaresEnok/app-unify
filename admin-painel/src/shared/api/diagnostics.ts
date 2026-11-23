import { clearPanelReads, panelRequest } from './panelHttp';

export interface DiagnosticSummary {
  downloadMbps?: number;
  uploadMbps?: number;
  pingMs?: number;
  lossPercent?: number;
  onuRxDbm?: number;
  onuStatus?: string;
  connectionType?: string;
  needsProviderSupport?: boolean;
  [key: string]: unknown;
}

export interface DiagnosticResultItem {
  id: string;
  providerId: string;
  cpfCnpj: string;
  contratoId: string;
  clientName: string;
  planName: string;
  mode: string;
  verdict: 'healthy' | 'degraded' | 'critical' | 'unknown' | string;
  verdictHeadline: string;
  cause: string;
  summary: DiagnosticSummary;
  oltName: string;
  bairro: string;
  cidade: string;
  createdAt: string;
}

export async function fetchProviderDiagnostics(
  providerId: string,
  limit = 150,
): Promise<DiagnosticResultItem[]> {
  const params = new URLSearchParams({
    providerId,
    limit: String(limit),
  });
  const res = await panelRequest<{ data: DiagnosticResultItem[] }>(
    `/admin/diagnostics?${params.toString()}`,
  );
  return Array.isArray(res.data) ? res.data : [];
}

export interface OutageCluster {
  scope: 'olt' | 'bairro';
  areaName: string;
  cidade: string;
  distinctSubscribers: number;
  criticalCount: number;
  degradedCount: number;
  totalDiagnostics: number;
  lastSeenAt: string;
}

export async function fetchOutageRadar(
  providerId: string,
  options: { windowMinutes?: number; minSubscribers?: number } = {},
): Promise<OutageCluster[]> {
  const params = new URLSearchParams({ providerId });
  if (options.windowMinutes) params.set('windowMinutes', String(options.windowMinutes));
  if (options.minSubscribers) params.set('minSubscribers', String(options.minSubscribers));
  const res = await panelRequest<{ data: OutageCluster[] }>(
    `/admin/diagnostics/outage-radar?${params.toString()}`,
  );
  return Array.isArray(res.data) ? res.data : [];
}

export async function deleteProviderDiagnostic(
  providerId: string,
  id: string,
): Promise<{ success: boolean }> {
  const params = new URLSearchParams({ providerId });
  const res = await panelRequest<{ success: boolean }>(
    `/admin/diagnostics/${encodeURIComponent(id)}?${params.toString()}`,
    { method: 'DELETE' },
  );
  clearPanelReads();
  return res;
}

