import { clearPanelReads, panelRequest } from './panelHttp';

export interface ProviderClientItem {
  id: string;
  nome: string;
  cpfcnpj: string;
  status: string;
  plano: string;
  cidade: string;
  bairro: string;
  endereco: string;
  oltName: string;
  pon: string;
  cto: string;
  login: string;
  vencimento: string;
  contratoIds: string[];
  hasAppDevice?: boolean;
  contratos: unknown[];
}

export interface ProviderClientsPageData {
  clientes: ProviderClientItem[];
  total: number;
  page: number;
  limit: number;
  lastSyncedAt: string | null;
}

export async function fetchProviderClients(
  providerId: string,
  options: { page?: number; limit?: number; search?: string } = {},
): Promise<ProviderClientsPageData> {
  const params = new URLSearchParams({
    providerId,
    page: String(options.page || 1),
    limit: String(options.limit || 25),
  });
  if (options.search?.trim()) params.set('search', options.search.trim());
  const res = await panelRequest<{ data: ProviderClientsPageData }>(`/admin/clients?${params.toString()}`);
  return res.data;
}

export async function fetchProviderClientDetail(
  providerId: string,
  identifier: string,
): Promise<ProviderClientItem> {
  const params = new URLSearchParams({ providerId });
  const res = await panelRequest<{ data: ProviderClientItem }>(
    `/admin/clients/${encodeURIComponent(identifier)}?${params.toString()}`,
  );
  return res.data;
}

export async function deleteProviderClient(
  providerId: string,
  identifier: string,
): Promise<{ success: boolean; message: string }> {
  const params = new URLSearchParams({ providerId });
  const res = await panelRequest<{ success: boolean; message: string }>(
    `/admin/clients/${encodeURIComponent(identifier)}?${params.toString()}`,
    { method: 'DELETE' },
  );
  clearPanelReads();
  return res;
}

export async function triggerProviderClientsSync(
  providerId: string,
): Promise<{ jobId: string; status: string; message?: string }> {
  return panelRequest('/admin/clients/sync', {
    method: 'POST',
    body: { providerId },
  });
}

export async function getProviderClientsSyncStatus(
  providerId: string,
  jobId: string,
): Promise<{ jobId: string; status: string; progress?: { count?: number; page?: number }; count?: number }> {
  const params = new URLSearchParams({ providerId });
  return panelRequest(`/admin/clients/sync/${encodeURIComponent(jobId)}?${params.toString()}`);
}

