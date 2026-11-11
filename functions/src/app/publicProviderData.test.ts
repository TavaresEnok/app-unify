import { test, expect } from "vitest";
import { publicProviderData } from './publicProviderData';

test('removes integration credentials from nested public settings while preserving branding', () => {
  expect(publicProviderData({ name: 'ISP', themeColor: '#fff', integrations: { apiToken: 'private' },
    details: { apiToken: 'private', token: 'private', systemUrl: 'https://isp.test', password: 'private' },
    config: { integrations: { apiToken: 'private' }, items: [{ senha: 'private', label: 'Menu' }] },
  })).toEqual({ name: 'ISP', themeColor: '#fff', details: {}, config: {} });
});

test('does not expose legacy internal API destinations or private references', () => {
  expect(publicProviderData({ name: 'ISP', apiUrl: 'https://internal.invalid',
    secretReference: 'private', config: { apiUrl: 'https://internal.invalid' },
  })).toEqual({ name: 'ISP', config: {} });
});

// Com a lista permitida do F1, campos desconhecidos (ex.: `list`) somem; a
// garantia que importa é que grafias alternativas de segredo nunca saiam,
// mesmo dentro de listas de campos permitidos.
test('removes alternate secret spellings inside allowed arrays', () => {
  expect(publicProviderData({ faq: [{ id: '1', question: 'Q', api_token: 'hidden', secrets: {}, Senha: 'x' }], list: [[{ label: 'ok' }]] }))
    .toEqual({ faq: [{ id: '1', question: 'Q' }] });
});
