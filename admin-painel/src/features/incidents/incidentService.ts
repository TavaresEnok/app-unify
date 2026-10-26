import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  type Unsubscribe,
} from "firebase/firestore";
import { db } from "@/firebase/config";

export interface Incident {
  id: string;
  title: string;
  message: string;
  area?: string;
  active: boolean;
  createdAt?: { toDate: () => Date };
  resolvedAt?: { toDate: () => Date } | null;
}

export function subscribeIncidents(
  providerId: string,
  onValue: (items: Incident[]) => void,
  onError: (error: Error) => void,
): Unsubscribe {
  const incidents = query(
    collection(db, "provedores", providerId, "incidents"),
    orderBy("createdAt", "desc"),
  );
  return onSnapshot(
    incidents,
    (snapshot) => onValue(snapshot.docs.map((d) => ({ id: d.id, ...d.data() }) as Incident)),
    onError,
  );
}

export function createIncident(
  providerId: string,
  data: { title: string; message: string; area?: string },
): Promise<unknown> {
  return addDoc(collection(db, "provedores", providerId, "incidents"), {
    title: data.title.trim(),
    message: data.message.trim(),
    area: data.area?.trim() || null,
    active: true,
    createdAt: serverTimestamp(),
    resolvedAt: null,
  });
}

export function setIncidentActive(
  providerId: string,
  incidentId: string,
  active: boolean,
): Promise<void> {
  return updateDoc(doc(db, "provedores", providerId, "incidents", incidentId), {
    active,
    resolvedAt: active ? null : serverTimestamp(),
  });
}

export function deleteIncident(providerId: string, incidentId: string): Promise<void> {
  return deleteDoc(doc(db, "provedores", providerId, "incidents", incidentId));
}
