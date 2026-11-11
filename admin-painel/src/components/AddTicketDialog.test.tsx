import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { beforeEach, expect, it, vi } from 'vitest';

// Render harness for actual component handlers. State/ref/effect slots persist
// across renders; UI primitives only expose their props, no DOM dependency.
const h = vi.hoisted(() => ({ slots: [] as any[], cursor: 0, effects: [] as Array<() => void>,
  user: { uid: 'a1', email: 'a@test' }, tenant: 'A', rpc: vi.fn(), upload: vi.fn(), buttons: [] as any[], inputs: [] as any[] }));
vi.mock('react', async original => ({ ...await original<typeof import('react')>(),
  useState: (initial: any) => { const i = h.cursor++; if (!(i in h.slots)) h.slots[i] = typeof initial === 'function' ? initial() : initial;
    return [h.slots[i], (value: any) => { h.slots[i] = typeof value === 'function' ? value(h.slots[i]) : value; }]; },
  useRef: (initial: any) => { const i = h.cursor++; return h.slots[i] ||= { current: initial }; },
  useEffect: (effect: any, deps: any[]) => { const i = h.cursor++, previous = h.slots[i];
    if (!previous || deps.some((v, j) => v !== previous.deps[j])) h.effects.push(() => { previous?.cleanup?.(); h.slots[i] = { deps, cleanup: effect() }; }); },
}));
vi.mock('@/contexts/AuthContext', () => ({ useAuth: () => ({ user: h.user, providerId: h.tenant }) }));
vi.mock('@/hooks/useApi', () => ({ useApi: () => ({ callFunction: h.rpc }) }));
vi.mock('@/shared/api/privateAttachments', () => ({ privateAttachmentRequest: (...args: any[]) => h.upload(...args) }));
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn(), loading: vi.fn() } }));
vi.mock('@/components/ui/button', () => ({ Button: (props: any) => { h.buttons.push(props); return <button>{props.children}</button>; } }));
vi.mock('@/components/ui/input', () => ({ Input: (props: any) => { h.inputs.push(props); return <input value={props.value} readOnly />; } }));
vi.mock('@/components/ui/textarea', () => ({ Textarea: (props: any) => { h.inputs.push(props); return <textarea value={props.value} readOnly />; } }));
vi.mock('@/components/ui/dialog', () => {
  const Box = ({ children }: any) => <div>{children}</div>;
  return { Dialog: Box, DialogContent: Box, DialogDescription: Box, DialogFooter: Box, DialogHeader: Box, DialogTitle: Box, DialogTrigger: Box };
});
import AddTicketDialog from './AddTicketDialog';
let fileProps: any;
function walk(element: any) {
  if (!element || typeof element !== 'object') return;
  if (element.type === 'input' && element.props.type === 'file') fileProps = element.props;
  React.Children.forEach(element.props?.children, walk);
}
function render() {
  h.cursor = 0; h.buttons = []; h.inputs = [];
  const element = AddTicketDialog({ providerName: 'A', onTicketCreated: vi.fn() });
  walk(element); const html = renderToStaticMarkup(element);
  const effects = h.effects.splice(0); effects.forEach(effect => effect());
  return html;
}
function send() { return h.buttons.find(button => React.Children.toArray(button.children).includes('Enviar Ticket')).onClick(); }
beforeEach(() => {
  h.slots.forEach(slot => slot?.cleanup?.()); h.slots = []; h.effects = []; h.tenant = 'A';
  h.user = { uid: 'a1', email: 'a@test' };
  h.rpc.mockReset().mockResolvedValue({ ticketId: 't1' }); h.upload.mockReset();
});
it('renders pending ticket after upload failure and retries only its stable upload', async () => {
  render(); render();
  h.inputs.find(input => input.id === 'subject').onChange({ target: { value: 'Problem' } });
  h.inputs.find(input => input.id === 'message').onChange({ target: { value: 'Details' } });
  const create = vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:preview');
  const revoke = vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => {});
  fileProps.onChange({ target: { files: [new File(['file'], 'image.png', { type: 'image/png' })] } });
  render(); h.upload.mockRejectedValueOnce(new Error('offline'));
  await send();
  expect(render()).toContain('Ticket t1 criado. Anexo pendente');
  expect(h.inputs.find(input => input.id === 'subject').disabled).toBe(true);
  await send(); render();
  expect(h.rpc).toHaveBeenCalledTimes(1); expect(h.rpc.mock.calls[0][1]).not.toHaveProperty('imageUrl');
  expect(h.upload).toHaveBeenCalledTimes(2);
  expect(h.upload.mock.calls[0][1]).toEqual({ ticketId: 't1' });
  expect(h.upload.mock.calls[0][2]).toBe(h.upload.mock.calls[1][2]);
  expect(revoke).toHaveBeenCalledWith('blob:preview'); create.mockRestore(); revoke.mockRestore();
});
it.each(['identity','cancel'])('drops late creation response after %s change, without uploading under another tenant', async kind => {
  render(); render(); h.inputs[0].onChange({ target: { value: 'Subject' } });
  const create = vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:preview');
  const revoke = vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => {});
  fileProps.onChange({ target: { files: [new File(['file'], 'image.png', { type: 'image/png' })] } });
  render(); let resolve!: (value: any) => void;
  h.rpc.mockImplementation(() => new Promise(r => { resolve = r; }));
  const pending = send();
  if (kind === 'identity') { h.user = { uid: 'b1', email: 'b@test' }; h.tenant = 'B'; render(); }
  else h.buttons.find(button => button.children === 'Cancelar').onClick();
  resolve({ ticketId: 'already-created' }); await pending; render();
  expect(h.upload).not.toHaveBeenCalled(); expect(render()).not.toContain('already-created');
  expect(revoke).toHaveBeenCalledWith('blob:preview'); create.mockRestore(); revoke.mockRestore();
});
