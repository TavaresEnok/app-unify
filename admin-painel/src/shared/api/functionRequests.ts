import {
  collection,
  doc,
  onSnapshot,
  serverTimestamp,
  setDoc,
  type Firestore,
} from "firebase/firestore";
import type {
  FunctionRequestPayloadMap,
  FunctionRequestType,
  FunctionResponse,
  FunctionResultMap,
} from "@/shared/contracts";

export const DEFAULT_FUNCTION_TIMEOUT_MS = 45_000;

export class FunctionRequestError extends Error {
  constructor(
    message: string,
    readonly code = "internal",
    readonly requestId?: string,
  ) {
    super(message);
    this.name = "FunctionRequestError";
  }
}

export interface FunctionRequestContext {
  requesterUid: string;
  providerId?: string | null;
  forceProviderScope?: boolean;
}

export function callFunctionRequest<T extends FunctionRequestType>(
  firestore: Firestore,
  type: T,
  payload: FunctionRequestPayloadMap[T],
  context: FunctionRequestContext,
  options: { timeoutMs?: number; signal?: AbortSignal } = {},
): Promise<FunctionResultMap[T]> {
  const requestId = doc(collection(firestore, "function_requests")).id;
  const requestRef = doc(firestore, "function_requests", requestId);
  const responseRef = doc(firestore, "function_responses", requestId);
  const timeoutMs = options.timeoutMs ?? DEFAULT_FUNCTION_TIMEOUT_MS;

  return new Promise((resolve, reject) => {
    let settled = false;
    let unsubscribe = () => undefined;

    const finish = (callback: () => void) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      options.signal?.removeEventListener("abort", abort);
      unsubscribe();
      callback();
    };

    const abort = () => finish(() => reject(
      new FunctionRequestError("Operação cancelada.", "cancelled", requestId),
    ));

    const timer = window.setTimeout(() => finish(() => reject(
      new FunctionRequestError("O servidor demorou para responder. Tente novamente.", "timeout", requestId),
    )), timeoutMs);

    options.signal?.addEventListener("abort", abort, { once: true });
    if (options.signal?.aborted) {
      abort();
      return;
    }

    unsubscribe = onSnapshot(responseRef, (snapshot) => {
      if (!snapshot.exists()) return;
      const response = snapshot.data() as FunctionResponse<T>;
      if (response.error) {
        finish(() => reject(new FunctionRequestError(response.error!, response.code, requestId)));
        return;
      }
      finish(() => resolve(response.result as FunctionResultMap[T]));
    }, (error) => finish(() => reject(
      new FunctionRequestError(error.message, error.code, requestId),
    )));

    const scopedPayload = context.forceProviderScope && context.providerId
      ? { ...payload, providerId: context.providerId }
      : payload;

    setDoc(requestRef, {
      type,
      requesterUid: context.requesterUid,
      payload: scopedPayload,
      createdAt: serverTimestamp(),
    }).catch((error: Error) => finish(() => reject(
      new FunctionRequestError(error.message, "request-write-failed", requestId),
    )));
  });
}
