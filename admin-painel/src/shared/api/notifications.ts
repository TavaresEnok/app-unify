import { clearPanelReads, panelRequest } from './panelHttp';

export interface SegmentFilters {
  oltNames?: string[];
  ponKeys?: string[];
  ctos?: string[];
  cidades?: string[];
  bairros?: string[];
  popIds?: string[];
  statuses?: string[];
  planos?: string[];
  targetCpf?: string;
  search?: string;
}

export interface SegmentOption {
  value: string;
  count: number;
  meta?: string;
}

export interface SegmentOptionsData {
  olts: SegmentOption[];
  pons: SegmentOption[];
  ctos: SegmentOption[];
  cidades: SegmentOption[];
  bairros: SegmentOption[];
  pops: SegmentOption[];
  planos: SegmentOption[];
  statuses: SegmentOption[];
  totals: {
    totalSubscribers: number;
    subscribersWithDevice: number;
    totalDevices: number;
  };
}

export interface AudiencePreviewData {
  matchedSubscribers: number;
  reachableDevices: number;
  hasFilters: boolean;
  filters: Required<SegmentFilters>;
}

export interface CampaignHistoryItem {
  id: string;
  providerId: string;
  title: string;
  body: string;
  category: string;
  route: string;
  filters: Required<SegmentFilters>;
  matchedSubscribers: number;
  targetedDevices: number;
  successCount: number;
  failureCount: number;
  deliveryMode: 'topic' | 'multicast';
  sentBy: string;
  status?: 'sent' | 'scheduled' | 'processing' | 'cancelled' | 'failed';
  scheduledFor?: string | null;
  createdAt: string;
}

export interface BillingPushRule {
  providerId: string;
  enabled: boolean;
  daysBefore: number[];
  daysAfter: number[];
  updatedAt: string | null;
}

export async function fetchNotificationSegments(
  providerId: string,
  context?: Pick<SegmentFilters, 'oltNames' | 'ponKeys' | 'cidades' | 'bairros'>,
): Promise<SegmentOptionsData> {
  const params = new URLSearchParams({ providerId });
  if (context?.oltNames?.length) params.set('olt', context.oltNames.join(','));
  if (context?.ponKeys?.length) params.set('pon', context.ponKeys.join(','));
  if (context?.cidades?.length) params.set('cidade', context.cidades.join(','));
  if (context?.bairros?.length) params.set('bairro', context.bairros.join(','));
  const res = await panelRequest<{ data: SegmentOptionsData }>(`/admin/notifications/segments?${params.toString()}`);
  return res.data;
}

export async function previewNotificationAudience(
  providerId: string,
  filters: SegmentFilters,
): Promise<AudiencePreviewData> {
  const res = await panelRequest<{ data: AudiencePreviewData }>('/admin/notifications/preview', {
    method: 'POST',
    body: { providerId, filters },
  });
  return res.data;
}

export async function sendNotificationCampaign(payload: {
  providerId: string;
  title: string;
  body: string;
  category: string;
  route: string;
  filters: SegmentFilters;
  scheduledFor?: string | null;
}): Promise<{ success: boolean; message: string; data: CampaignHistoryItem }> {
  const res = await panelRequest<{ success: boolean; message: string; data: CampaignHistoryItem }>(
    '/admin/notifications/send',
    { method: 'POST', body: payload },
  );
  clearPanelReads();
  return res;
}

export async function cancelScheduledNotification(
  providerId: string,
  id: string,
): Promise<{ success: boolean; message: string }> {
  const params = new URLSearchParams({ providerId });
  const res = await panelRequest<{ success: boolean; message: string }>(
    `/admin/notifications/scheduled/${encodeURIComponent(id)}?${params.toString()}`,
    { method: 'DELETE' },
  );
  clearPanelReads();
  return res;
}

export async function fetchBillingPushRule(providerId: string): Promise<BillingPushRule> {
  const params = new URLSearchParams({ providerId });
  const res = await panelRequest<{ data: BillingPushRule }>(`/admin/notifications/billing-rules?${params.toString()}`);
  return res.data;
}

export async function saveBillingPushRule(
  providerId: string,
  input: { enabled: boolean; daysBefore: number[]; daysAfter: number[] },
): Promise<{ success: boolean; message: string; data: BillingPushRule }> {
  const res = await panelRequest<{ success: boolean; message: string; data: BillingPushRule }>(
    '/admin/notifications/billing-rules',
    { method: 'PUT', body: { providerId, ...input } },
  );
  clearPanelReads();
  return res;
}

export async function fetchNotificationHistory(
  providerId: string,
  limit = 30,
): Promise<CampaignHistoryItem[]> {
  const params = new URLSearchParams({ providerId, limit: String(limit) });
  const res = await panelRequest<{ data: CampaignHistoryItem[] }>(`/admin/notifications/history?${params.toString()}`);
  return res.data;
}

export async function syncNotificationSegments(
  providerId: string,
  importLegacyTokens = false,
): Promise<{ success: boolean; message: string; data: { projected: number; importedTokens: number; totals: SegmentOptionsData['totals'] } }> {
  return panelRequest('/admin/notifications/sync-segments', {
    method: 'POST',
    body: { providerId, importLegacyTokens },
  });
}

