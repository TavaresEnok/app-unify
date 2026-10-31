import { test, expect } from "vitest";
import { publicProviderData } from './publicProviderData';

test('removes integration credentials from nested public settings while preserving branding', () => {
  expect(publicProviderData({ name: 'ISP', themeColor: '#fff', integrations: { apiToken: 'private' },
    details: { apiToken: 'private', token: 'private', systemUrl: 'https://isp.test', password: 'private' },
    config: { integrations: { apiToken: 'private' }, items: [{ senha: 'private', label: 'Menu' }] },
  })).toEqual({ name: 'ISP', themeColor: '#fff', details: { systemUrl: 'https://isp.test' }, config: { items: [{ label: 'Menu' }] } });
});
