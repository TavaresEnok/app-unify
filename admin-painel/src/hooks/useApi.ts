import { useState, useCallback, useMemo } from 'react';
import { db } from '@/firebase/config';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from "sonner";
import type { FunctionRequestPayloadMap, FunctionRequestType, FunctionResultMap } from '@/shared/contracts';
import { callFunctionRequest } from '@/shared/api/functionRequests';

export function useApi() {
  const { user, userRole, providerId: authProviderId } = useAuth();
  const [loading, setLoading] = useState(false);

  const callFunction = useCallback(async <T extends FunctionRequestType>(
    type: T,
    payload: FunctionRequestPayloadMap[T],
  ): Promise<FunctionResultMap[T]> => {
    if (!user) {
      const error = new Error("Utilizador não autenticado.");
      toast.error("Erro de autenticação", { description: error.message });
      throw error;
    }

    setLoading(true);
    try {
      const result = await callFunctionRequest(db, type, payload, {
        requesterUid: user.uid,
        providerId: authProviderId,
        forceProviderScope: userRole === "providerAdmin",
      });
      if (!type.startsWith("GET_") && !type.startsWith("LIST_")) {
        const message = typeof result === "object" && result && "message" in result
          ? String(result.message)
          : "Operação concluída.";
        toast.success("Sucesso!", { description: message });
      }
      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : "Falha inesperada.";
      toast.error("Erro no servidor", { description: message });
      throw error;
    } finally {
      setLoading(false);
    }
  }, [user, userRole, authProviderId]);

  return useMemo(() => ({ callFunction, loading }), [callFunction, loading]);
}
