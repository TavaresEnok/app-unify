import { expect, it, vi } from 'vitest';
import { TicketDraft } from './ticketDraft';
it('retries upload only, with stable ticket and attachment, after a real partial failure', async () => {
  const draft = new TicketDraft();
  const create = vi.fn().mockResolvedValue({ ticketId: 'canonical' });
  const upload = vi.fn().mockRejectedValueOnce(new Error('offline')).mockResolvedValue(undefined);
  await expect(draft.save(create, upload, true, () => true)).rejects.toThrow('offline');
  expect(draft.ticketId).toBe('canonical');
  await draft.save(create, upload, true, () => true);
  expect(create).toHaveBeenCalledTimes(1);
  expect(upload.mock.calls[0][0]).toBe(upload.mock.calls[1][0]);
  expect(upload.mock.calls[0][1]).toBe(upload.mock.calls[1][1]);
});
it.each(['cancel','identity'])('does not upload when %s changes during ticket creation', async kind => {
  const draft = new TicketDraft(); let resolve!: (value: any) => void; let current = true;
  const upload = vi.fn();
  const task = draft.save(() => new Promise(r => { resolve = r; }), upload, true, () => current);
  if (kind === 'cancel') draft.cancel(); else current = false;
  resolve({ ticketId: 'created' }); await expect(task).rejects.toThrow('cancelado');
  expect(upload).not.toHaveBeenCalled(); expect(draft.ticketId).toBe('created');
});
