import { useState, useCallback, useMemo } from 'react';
import { toast } from 'sonner';
import { useAuth } from '@/contexts/AuthContext';
import type {
  FunctionRequestPayloadMap,
  FunctionRequestType,
  FunctionResultMap,
} from '@/shared/contracts';
import { clearPanelReads, panelRequest, readPanel } from '@/shared/api/panelHttp';

interface UseApiOptions {
  silent?: boolean;
  timeoutMs?: number;
  signal?: AbortSignal;
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error && error.message) return error.message;
  return 'Ocorreu um erro desconhecido ao comunicar com o servidor.';
}

async function dispatchRestFunction<T extends FunctionRequestType>(
  type: T,
  payload: FunctionRequestPayloadMap[T],
  scopedProviderId: string | null,
): Promise<FunctionResultMap[T]> {
  switch (type) {
    case 'GET_DASHBOARD_DATA': {
      const res = await readPanel<{ data: Record<string, unknown> }>('/admin/dashboard/panel');
      return res.data as FunctionResultMap[T];
    }
    case 'GET_PROVIDER_DASHBOARD_DATA': {
      const p = payload as FunctionRequestPayloadMap['GET_PROVIDER_DASHBOARD_DATA'];
      const target = scopedProviderId || p.providerId;
      const res = await readPanel<{ data: Record<string, unknown> }>(
        `/admin/dashboard/panel/providers/${encodeURIComponent(target)}`,
      );
      return res.data as FunctionResultMap[T];
    }
    case 'CREATE_PROVIDER': {
      const p = payload as FunctionRequestPayloadMap['CREATE_PROVIDER'];
      const res = await panelRequest<Record<string, unknown>>('/admin/providers', {
        method: 'POST',
        body: { providerId: p.providerId, name: p.name },
      });
      clearPanelReads();
      return { success: true, message: 'Provedor criado com sucesso.', providerId: String(res.id || p.providerId) } as FunctionResultMap[T];
    }
    case 'UPDATE_PROVIDER_CONFIG': {
      const p = payload as FunctionRequestPayloadMap['UPDATE_PROVIDER_CONFIG'];
      const target = scopedProviderId || p.providerId;
      await panelRequest(`/admin/providers/${encodeURIComponent(target)}/config`, {
        method: 'PATCH',
        body: p.config,
      });
      clearPanelReads();
      return { success: true, message: 'Configurações atualizadas com sucesso.', providerId: target } as FunctionResultMap[T];
    }
    case 'UPDATE_PROVIDER_DETAILS': {
      const p = payload as FunctionRequestPayloadMap['UPDATE_PROVIDER_DETAILS'];
      const target = scopedProviderId || p.providerId;
      await panelRequest(`/admin/providers/${encodeURIComponent(target)}/details`, {
        method: 'PATCH',
        body: p.details,
      });
      clearPanelReads();
      return { success: true, message: 'Detalhes do provedor atualizados com sucesso.', providerId: target } as FunctionResultMap[T];
    }
    case 'DELETE_PROVIDER': {
      const p = payload as FunctionRequestPayloadMap['DELETE_PROVIDER'];
      await panelRequest(`/admin/providers/${encodeURIComponent(p.providerId)}`, { method: 'DELETE' });
      clearPanelReads();
      return { success: true, message: 'Provedor excluído com sucesso.' } as FunctionResultMap[T];
    }
    case 'GET_ALL_TICKETS': {
      const res = await readPanel<{ data: unknown[] }>('/admin/tickets');
      return (Array.isArray(res.data) ? res.data : []) as FunctionResultMap[T];
    }
    case 'GET_PROVIDER_TICKETS': {
      const res = await readPanel<{ data: unknown[] }>('/admin/tickets');
      return (Array.isArray(res.data) ? res.data : []) as FunctionResultMap[T];
    }
    case 'CREATE_TICKET': {
      const p = payload as FunctionRequestPayloadMap['CREATE_TICKET'];
      const target = scopedProviderId || p.providerId;
      const res = await panelRequest<{ success: true; ticketId: string }>('/admin/tickets', {
        method: 'POST',
        body: {
          subject: p.subject,
          message: p.message,
          providerId: target,
          providerName: p.providerName,
          userEmail: p.userEmail,
        },
      });
      clearPanelReads();
      return { success: true, message: 'Ticket aberto com sucesso.', ticketId: res.ticketId } as FunctionResultMap[T];
    }
    case 'REPLY_TO_TICKET': {
      const p = payload as FunctionRequestPayloadMap['REPLY_TO_TICKET'];
      await panelRequest(`/admin/tickets/${encodeURIComponent(p.ticketId)}/reply`, {
        method: 'POST',
        body: { message: p.message },
      });
      clearPanelReads();
      if (typeof window !== 'undefined') window.dispatchEvent(new CustomEvent('unify:refresh-ticket'));
      return { success: true, message: 'Resposta enviada.' } as FunctionResultMap[T];
    }
    case 'UPDATE_TICKET_STATUS': {
      const p = payload as FunctionRequestPayloadMap['UPDATE_TICKET_STATUS'];
      await panelRequest(`/admin/tickets/${encodeURIComponent(p.ticketId)}`, {
        method: 'PATCH',
        body: { status: p.status },
      });
      clearPanelReads();
      if (typeof window !== 'undefined') window.dispatchEvent(new CustomEvent('unify:refresh-ticket'));
      return { success: true, message: 'Status atualizado.' } as FunctionResultMap[T];
    }
    case 'DELETE_TICKET': {
      const p = payload as FunctionRequestPayloadMap['DELETE_TICKET'];
      await panelRequest(`/admin/tickets/${encodeURIComponent(p.ticketId)}`, { method: 'DELETE' });
      clearPanelReads();
      return { success: true, message: 'Ticket excluído.' } as FunctionResultMap[T];
    }
    case 'LIST_ADMIN_USERS': {
      const res = await readPanel<{ data: unknown[] }>('/admin/users');
      return (Array.isArray(res.data) ? res.data : []) as FunctionResultMap[T];
    }
    case 'CREATE_ADMIN_USER': {
      const p = payload as FunctionRequestPayloadMap['CREATE_ADMIN_USER'];
      const res = await panelRequest<{ success: true; uid: string }>('/admin/users', {
        method: 'POST',
        body: p,
      });
      clearPanelReads();
      return { success: true, message: 'Administrador criado com sucesso.', uid: res.uid } as FunctionResultMap[T];
    }
    case 'DELETE_ADMIN_USER': {
      const p = payload as FunctionRequestPayloadMap['DELETE_ADMIN_USER'];
      await panelRequest(`/admin/users/${encodeURIComponent(p.uid)}`, { method: 'DELETE' });
      clearPanelReads();
      return { success: true, message: 'Administrador removido.' } as FunctionResultMap[T];
    }
    case 'SET_SUPER_ADMIN_BY_EMAIL': {
      const p = payload as FunctionRequestPayloadMap['SET_SUPER_ADMIN_BY_EMAIL'];
      const res = await panelRequest<{ success: true; uid: string }>('/admin/users/super-admin', {
        method: 'POST',
        body: { email: p.email },
      });
      clearPanelReads();
      return { success: true, message: 'Super Admin definido com sucesso.', uid: res.uid } as FunctionResultMap[T];
    }
    case 'LIST_PROVIDER_BACKUPS': {
      const p = payload as FunctionRequestPayloadMap['LIST_PROVIDER_BACKUPS'];
      const target = scopedProviderId || p.providerId;
      const res = await readPanel<{ data: Array<Record<string, unknown>> }>(
        `/admin/providers/${encodeURIComponent(target)}/backups`,
      );
      return (Array.isArray(res.data) ? res.data : []) as FunctionResultMap[T];
    }
    case 'BACKUP_PROVIDER_CONFIG': {
      const p = payload as FunctionRequestPayloadMap['BACKUP_PROVIDER_CONFIG'];
      const target = scopedProviderId || p.providerId;
      const res = await panelRequest<{ success: true; id: string }>(
        `/admin/providers/${encodeURIComponent(target)}/backups`,
        { method: 'POST', body: {} },
      );
      clearPanelReads();
      return { success: true, message: 'Backup criado com sucesso.', backupId: res.id } as FunctionResultMap[T];
    }
    case 'RESTORE_PROVIDER_CONFIG': {
      const p = payload as FunctionRequestPayloadMap['RESTORE_PROVIDER_CONFIG'];
      const target = scopedProviderId || p.providerId;
      await panelRequest(
        `/admin/providers/${encodeURIComponent(target)}/backups/${encodeURIComponent(p.backupId)}/restore`,
        { method: 'POST', body: {} },
      );
      clearPanelReads();
      return { success: true, message: 'Configuração restaurada com sucesso.' } as FunctionResultMap[T];
    }
    case 'DELETE_PROVIDER_BACKUP': {
      const p = payload as FunctionRequestPayloadMap['DELETE_PROVIDER_BACKUP'];
      const target = scopedProviderId || p.providerId;
      await panelRequest(
        `/admin/providers/${encodeURIComponent(target)}/backups/${encodeURIComponent(p.backupId)}`,
        { method: 'DELETE' },
      );
      clearPanelReads();
      return { success: true, message: 'Backup removido.' } as FunctionResultMap[T];
    }
    case 'LIST_PROVIDER_CLIENTS': {
      const p = payload as FunctionRequestPayloadMap['LIST_PROVIDER_CLIENTS'];
      const target = scopedProviderId || p.providerId;
      const params = new URLSearchParams({ providerId: target });
      if (p.limit) params.set('limit', String(p.limit));
      if (p.cursor) params.set('cursor', p.cursor);
      if (p.search) params.set('search', p.search);
      const res = await readPanel<FunctionResultMap['LIST_PROVIDER_CLIENTS']>(
        `/admin/clients?${params.toString()}`,
      );
      return res as FunctionResultMap[T];
    }
    default:
      throw new Error(`Operação não suportada na API REST: ${type}`);
  }
}

export function useApi() {
  const { user, userRole, providerId } = useAuth();
  const [loading, setLoading] = useState(false);

  const callFunction = useCallback(async <T extends FunctionRequestType>(
    type: T,
    payload: FunctionRequestPayloadMap[T],
    options: UseApiOptions = {},
  ): Promise<FunctionResultMap[T]> => {
    setLoading(true);
    try {
      if (!user) {
        throw new Error('Autenticação necessária para realizar esta operação.');
      }
      const scopedProviderId = userRole === 'providerAdmin' ? providerId : null;
      const result = await dispatchRestFunction(type, payload, scopedProviderId);

      const maybeSuccess = result && typeof result === 'object' ? result as { success?: boolean; message?: string } : null;
      if (!options.silent && maybeSuccess?.success && maybeSuccess.message) {
        toast.success(maybeSuccess.message);
      }

      return result;
    } catch (err: unknown) {
      const message = getErrorMessage(err);
      if (!options.silent) {
        toast.error(message);
      }
      throw err;
    } finally {
      setLoading(false);
    }
  }, [user, userRole, providerId]);

  return useMemo(() => ({ callFunction, loading }), [callFunction, loading]);
}
