import { test, expect } from "vitest";
import { publicProviderData } from './publicProviderData';

test('removes integration credentials from nested public settings while preserving branding', () => {
  expect(publicProviderData({ name: 'ISP', themeColor: '#fff', integrations: { apiToken: 'private' },
    details: { apiToken: 'private', token: 'private', systemUrl: 'https://isp.test', password: 'private' },
    config: { integrations: { apiToken: 'private' }, items: [{ senha: 'private', label: 'Menu' }] },
  })).toEqual({ name: 'ISP', themeColor: '#fff', details: { systemUrl: 'https://isp.test' }, config: { items: [{ label: 'Menu' }] } });
});

test('preserves Firestore-like values and removes alternate secret spellings in arrays', () => {
  class Timestamp { constructor(public seconds: number) {} }
  const timestamp = new Timestamp(123);
  expect(publicProviderData({ createdAt: timestamp, list: [[{ api_token: 'hidden', secrets: {}, label: 'ok' }]] }))
    .toEqual({ createdAt: timestamp, list: [[{ label: 'ok' }]] });
});
