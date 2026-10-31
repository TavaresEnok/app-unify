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
