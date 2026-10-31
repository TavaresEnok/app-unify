export class TicketDraft {
  ticketId?: string;
  private attachmentId = crypto.randomUUID();
  private abort = new AbortController();
  private busy = false;
  cancel() { this.abort.abort(); }
  async save(create: () => Promise<{ ticketId: string }>, upload: (ticketId: string, attachmentId: string, signal: AbortSignal) => Promise<unknown>, hasFile: boolean, current: () => boolean) {
    if (this.busy) throw new Error('Envio em andamento.');
    this.busy = true;
    try {
      if (!current() || this.abort.signal.aborted) throw new Error('Envio cancelado.');
      if (!this.ticketId) this.ticketId = (await create()).ticketId;
      if (!current() || this.abort.signal.aborted) throw new Error('Envio cancelado.');
      if (hasFile) await upload(this.ticketId, this.attachmentId, this.abort.signal);
      if (!current() || this.abort.signal.aborted) throw new Error('Envio cancelado.');
    } finally { this.busy = false; }
  }
}
