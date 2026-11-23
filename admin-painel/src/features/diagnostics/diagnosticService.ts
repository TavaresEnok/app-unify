import { collection, deleteDoc, doc, limit, onSnapshot, orderBy, query, type Unsubscribe } from "firebase/firestore";
import { db } from "@/firebase/config";

export function subscribeDiagnostics<T>(
  providerId: string,
  onValue: (items: T[]) => void,
  onError: (error: Error) => void,
  maxItems = 150,
): Unsubscribe {
  const diagnostics = query(
    collection(db, "provedores", providerId, "diagnostic_results"),
    orderBy("createdAt", "desc"),
    limit(maxItems),
  );
  return onSnapshot(diagnostics, (snapshot) => {
    onValue(snapshot.docs.map((result) => ({ id: result.id, ...result.data() }) as T));
  }, onError);
}

export function deleteDiagnostic(providerId: string, resultId: string): Promise<void> {
  return deleteDoc(doc(db, "provedores", providerId, "diagnostic_results", resultId));
}
