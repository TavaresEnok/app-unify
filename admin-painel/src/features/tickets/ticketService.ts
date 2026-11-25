import { readPanel } from "@/shared/api/panelHttp";

export type Unsubscribe = () => void;

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
  attachmentId?: string;
  timestamp: { seconds: number; nanoseconds: number };
}

function isoToSecondsTimestamp(value: unknown): { seconds: number; nanoseconds: number } {
  if (value && typeof value === "object" && "seconds" in value) {
    return { seconds: Number((value as { seconds: number }).seconds) || 0, nanoseconds: 0 };
  }
  if (typeof value === "string" || typeof value === "number") {
    const ms = new Date(value).getTime();
    if (!Number.isNaN(ms)) return { seconds: Math.floor(ms / 1000), nanoseconds: 0 };
  }
  return { seconds: 0, nanoseconds: 0 };
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
  let stopped = false;
  let pending = false;
  let lastSerialized = "";

  const refresh = async () => {
    if (stopped || pending || (typeof document !== "undefined" && document.visibilityState === "hidden")) return;
    pending = true;
    try {
      const encodedId = encodeURIComponent(ticketId);
      const [ticketRes, messagesRes] = await Promise.all([
        readPanel<{ data?: Record<string, unknown> }>(`/admin/tickets/${encodedId}`),
        readPanel<{ data?: Record<string, unknown>[] }>(`/admin/tickets/${encodedId}/messages`),
      ]);

      const rawTicket = ticketRes.data || null;
      const rawMessages = Array.isArray(messagesRes.data) ? messagesRes.data : [];
      const serialized = JSON.stringify({ rawTicket, rawMessages });
      if (stopped || serialized === lastSerialized) return;
      lastSerialized = serialized;

      if (rawTicket) {
        handlers.onTicket({
          id: String(rawTicket.id || ticketId),
          subject: String(rawTicket.subject || ""),
          status: (rawTicket.status as TicketDocument["status"]) || "Aberto",
          createdBy: typeof rawTicket.createdBy === "string" ? rawTicket.createdBy : undefined,
          createdByUid: typeof rawTicket.createdByUid === "string" ? rawTicket.createdByUid : undefined,
          providerName: String(rawTicket.providerName || ""),
          updatedAt: isoToSecondsTimestamp(rawTicket.updatedAt),
        });
      } else {
        handlers.onTicket(null);
      }

      const mappedMessages = rawMessages.map((msg) => ({
        id: String(msg.id || ""),
        senderEmail: String(msg.senderEmail || ""),
        message: typeof msg.message === "string" ? msg.message : undefined,
        imageUrl: typeof msg.imageUrl === "string" ? msg.imageUrl : undefined,
        attachmentId: typeof msg.attachmentId === "string" ? msg.attachmentId : undefined,
        timestamp: isoToSecondsTimestamp(msg.createdAt ?? msg.timestamp),
      })).sort((a, b) => timestampMillis(a.timestamp) - timestampMillis(b.timestamp));

      handlers.onMessages(mappedMessages);
    } catch (error) {
      if (!stopped) handlers.onError(error instanceof Error ? error : new Error("Erro ao carregar ticket."));
    } finally {
      pending = false;
    }
  };

  void refresh();
  const timer = setInterval(() => { void refresh(); }, 5_000);
  const onVisible = () => { if (document.visibilityState === "visible") void refresh(); };
  const onCustomRefresh = () => { lastSerialized = ""; void refresh(); };
  if (typeof document !== "undefined") document.addEventListener("visibilitychange", onVisible);
  if (typeof window !== "undefined") window.addEventListener("unify:refresh-ticket", onCustomRefresh);

  return () => {
    stopped = true;
    clearInterval(timer);
    if (typeof document !== "undefined") document.removeEventListener("visibilitychange", onVisible);
    if (typeof window !== "undefined") window.removeEventListener("unify:refresh-ticket", onCustomRefresh);
  };
}
