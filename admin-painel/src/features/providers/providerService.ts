import { collection, doc, getDoc, onSnapshot, type Unsubscribe } from "firebase/firestore";
import { db } from "@/firebase/config";
import type { Provider } from "@/shared/contracts";

export function subscribeProviders(
  onValue: (providers: Provider[]) => void,
  onError?: (error: Error) => void,
): Unsubscribe {
  return onSnapshot(collection(db, "provedores"), (snapshot) => {
    onValue(snapshot.docs.map((document) => ({ id: document.id, ...document.data() }) as Provider));
  }, (error) => onError?.(error));
}

export function subscribeProvider(
  providerId: string,
  onValue: (provider: Provider | null) => void,
  onError?: (error: Error) => void,
): Unsubscribe {
  return onSnapshot(doc(db, "provedores", providerId), (snapshot) => {
    onValue(snapshot.exists() ? ({ id: snapshot.id, ...snapshot.data() } as Provider) : null);
  }, (error) => onError?.(error));
}

export async function getProvider(providerId: string): Promise<Provider | null> {
  const snapshot = await getDoc(doc(db, "provedores", providerId));
  return snapshot.exists() ? ({ id: snapshot.id, ...snapshot.data() } as Provider) : null;
}
