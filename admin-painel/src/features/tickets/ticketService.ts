import { collection, doc, onSnapshot, type Unsubscribe } from "firebase/firestore";
import { db } from "@/firebase/config";

export interface TicketDocument {
  id: string;
  subject: string;
  status: "Aberto" | "Em Andamento" | "Fechado";
  createdBy?: string;
  createdByUid?: string;
  providerName: string;
  updatedAt?: { seconds: number; nanoseconds: number };
}

export interface TicketMessageDocument {
  id: string;
  senderEmail: string;
  message?: string;
  imageUrl?: string;
  timestamp: { seconds: number; nanoseconds: number };
}

function timestampMillis(value: unknown): number {
  if (value && typeof value === "object" && "seconds" in value) {
    return Number((value as { seconds: number }).seconds) * 1000;
  }
  return 0;
}

export function subscribeTicket(
  ticketId: string,
  handlers: {
    onTicket: (ticket: TicketDocument | null) => void;
    onMessages: (messages: TicketMessageDocument[]) => void;
    onError: (error: Error) => void;
  },
): Unsubscribe {
  const ticketRef = doc(db, "tickets", ticketId);
  const stopTicket = onSnapshot(ticketRef, (snapshot) => {
    handlers.onTicket(snapshot.exists() ? ({ id: snapshot.id, ...snapshot.data() } as TicketDocument) : null);
  }, handlers.onError);
  const stopMessages = onSnapshot(collection(ticketRef, "messages"), (snapshot) => {
    const messages = snapshot.docs.map((message) => {
      const data = message.data();
      return {
        id: message.id,
        ...data,
        timestamp: data.createdAt || data.timestamp || { seconds: 0, nanoseconds: 0 },
      } as TicketMessageDocument;
    }).sort((left, right) => timestampMillis(left.timestamp) - timestampMillis(right.timestamp));
    handlers.onMessages(messages);
  }, handlers.onError);
  return () => { stopTicket(); stopMessages(); };
}
