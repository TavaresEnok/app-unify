import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { expect, it, vi } from 'vitest';
const h = vi.hoisted(() => ({ slots: [] as any[], cursor: 0, effects: [] as Array<() => void>,
  user: { uid: 'a1' }, tenant: 'A', dispose: vi.fn(), load: vi.fn() }));
vi.mock('react', async original => ({ ...await original<typeof import('react')>(),
  useState: (initial: any) => { const i = h.cursor++; if (!(i in h.slots)) h.slots[i] = initial;
    return [h.slots[i], (value: any) => { h.slots[i] = typeof value === 'function' ? value(h.slots[i]) : value; }]; },
  useEffect: (effect: any, deps: any[]) => { const i = h.cursor++, previous = h.slots[i];
    if (!previous || deps.some((v, j) => v !== previous.deps[j])) h.effects.push(() => { previous?.cleanup?.(); h.slots[i] = { deps, cleanup: effect() }; }); },
}));
vi.mock('@/contexts/AuthContext', () => ({ useAuth: () => ({ user: h.user, providerId: h.tenant }) }));
vi.mock('@/shared/api/privateAttachments', () => ({ PrivateBlob: class { dispose = h.dispose; load = h.load; } }));
import PrivateAttachment from './PrivateAttachment';
function render() {
  h.cursor = 0;
  const element = PrivateAttachment({ resource: { ticketId: 't1' }, attachmentId: 'up1' });
  const html = renderToStaticMarkup(element); h.effects.splice(0).forEach(effect => effect());
  return { html, click: () => element.props.children[0].props.onClick() };
}
it('renders only fetched local capability and disposes it on identity change/unmount', async () => {
  h.load.mockResolvedValue({ url: 'blob:private', mime: 'image/png' });
  const initial = render(); expect(initial.html).not.toContain('blob:'); initial.click(); render(); await Promise.resolve();
  expect(render().html).toContain('blob:private'); expect(render().html).toContain('download=');
  h.user = { uid: 'b1' }; h.tenant = 'B';
  expect(render().html).not.toContain('blob:private'); expect(h.dispose).toHaveBeenCalled();
  render().click(); let resolve!: (value: any) => void;
  h.load.mockImplementation(() => new Promise(r => { resolve = r; })); render();
  h.slots.forEach(slot => slot?.cleanup?.());
  resolve({ url: 'blob:late', mime: 'application/pdf' }); await Promise.resolve();
  expect(render().html).not.toContain('blob:late');
});
