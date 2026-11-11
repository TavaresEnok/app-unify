import { useState, useCallback, useMemo } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from "sonner";
import type { FunctionRequestPayloadMap, FunctionRequestType, FunctionResultMap } from '@/shared/contracts';
import { fetchDashboard } from '@/shared/api/dashboard';

export function useApi() {
  const { user, userRole, providerId: authProviderId } = useAuth();
  const [loading, setLoading] = useState(false);

  const callFunction = useCallback(async <T extends FunctionRequestType>(
    type: T,
    payload: FunctionRequestPayloadMap[T],
    options: { silent?: boolean } = {},
  ): Promise<FunctionResultMap[T]> => {
    if (!user) {
      const error = new Error("Utilizador não autenticado.");
      toast.error("Erro de autenticação", { description: error.message });
      throw error;
    }

    setLoading(true);
    try {
      let result: FunctionResultMap[T];
      if (type === 'GET_DASHBOARD_DATA' || type === 'GET_PROVIDER_DASHBOARD_DATA') {
        const providerId = type === 'GET_PROVIDER_DASHBOARD_DATA'
          ? (userRole === 'providerAdmin' ? authProviderId : (payload as { providerId: string }).providerId)
          : undefined;
        if (type === 'GET_PROVIDER_DASHBOARD_DATA' && !providerId) throw new Error('Provedor não identificado.');
        result = await fetchDashboard(user, providerId || undefined) as FunctionResultMap[T];
      } else {
        const [{ db }, { callFunctionRequest }] = await Promise.all([
          import('@/firebase/config'), import('@/shared/api/functionRequests'),
        ]);
        result = await callFunctionRequest(db, type, payload, {
          requesterUid: user.uid,
          user,
          providerId: authProviderId,
          forceProviderScope: userRole === "providerAdmin",
        });
      }
      if (!options.silent && !type.startsWith("GET_") && !type.startsWith("LIST_") && !(type === "SGP_API_PROXY" && ["get", "get_single", "status"].includes(String((payload as { action?: string }).action)))) {
        const message = typeof result === "object" && result && "message" in result
          ? String(result.message)
          : "Operação concluída.";
        toast.success("Sucesso!", { description: message });
      }
      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : "Falha inesperada.";
      if (!options.silent) toast.error("Erro no servidor", { description: message });
      throw error;
    } finally {
      setLoading(false);
    }
  }, [user, userRole, authProviderId]);

  return useMemo(() => ({ callFunction, loading }), [callFunction, loading]);
}
