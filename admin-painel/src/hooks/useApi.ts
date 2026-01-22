import { useState, useCallback, useMemo } from 'react';
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { db } from '@/firebase/config';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from "sonner";

// Lista de todas as ações possíveis
type ApiAction =
  | 'UPDATE_PROVIDER_CONFIG'
  | 'SEND_SCOPED_NOTIFICATION'
  | 'SEND_SCOPED_NOTIFICATION_SEGMENTED'
  | 'SGP_API_PROXY'
  | 'GET_DASHBOARD_DATA'
  | 'LIST_ADMIN_USERS'
  | 'CREATE_PROVIDER'
  | 'DELETE_PROVIDER'
  | 'UPDATE_PROVIDER_DETAILS'
  | 'CREATE_ADMIN_USER'
  | 'DELETE_ADMIN_USER'
  | 'SET_SUPER_ADMIN_BY_EMAIL'
  | 'GET_PROVIDER_DASHBOARD_DATA'
  | 'GET_ALL_TICKETS'
  | 'GET_PROVIDER_TICKETS'
  | 'CREATE_TICKET'
  | 'REPLY_TO_TICKET'
  | 'UPDATE_TICKET_STATUS'
  | 'DELETE_TICKET'
  | 'LIST_PROVIDER_CLIENTS'
  | 'DELETE_CLIENT'
  | 'GET_CLIENT_DETAILS'
  | 'BACKUP_PROVIDER_CONFIG'
  | 'LIST_PROVIDER_BACKUPS'
  | 'RESTORE_PROVIDER_CONFIG'
  | 'DELETE_PROVIDER_BACKUP';

export function useApi() {
  const { user, userRole, providerId: authProviderId } = useAuth();
  const [loading, setLoading] = useState(false);

  const callFunction = useCallback(<T extends object>(type: ApiAction, payload: T): Promise<any> => {
    return new Promise((resolve, reject) => {
      if (!user) {
        toast.error("Erro de autenticação", { description: "Utilizador não encontrado. Por favor, faça login novamente." });
        reject(new Error("Utilizador não autenticado."));
        return;
      }

      setLoading(true);
      const requestId = doc(collection(db, 'function_requests')).id;
      const requestDocRef = doc(db, 'function_requests', requestId);
      const responseDocRef = doc(db, 'function_responses', requestId);

      const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
        if (docSnap.exists()) {
          unsubscribe();
          setLoading(false);
          const response = docSnap.data();
          if (response.error) {
            toast.error("Erro no servidor", { description: response.error });
            reject(new Error(response.error));
          } else {
            if (type.startsWith('GET_') || type.startsWith('LIST_')) {
              resolve(response.result);
            } else {
              toast.success("Sucesso!", { description: response.result?.message || "Operação concluída." });
              resolve(response.result);
            }
          }
        }
      });

      let finalPayload: any = { ...payload };
      if (userRole === 'providerAdmin' && authProviderId) {
        finalPayload.providerId = authProviderId;
      }

      setDoc(requestDocRef, {
        type,
        createdAt: serverTimestamp(),
        requesterUid: user.uid,
        payload: finalPayload,
      }).catch(error => {
        unsubscribe();
        setLoading(false);
        toast.error("Erro ao solicitar a operação", { description: error.message });
        reject(error);
      });
    });
  }, [user, userRole, authProviderId]);

  return useMemo(() => ({ callFunction, loading }), [callFunction, loading]);
}
