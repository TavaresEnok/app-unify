// Isolated UI fixtures. This module is only aliased by workspace.vite.config.ts.
import type { ReactNode } from 'react';
import { DEFAULT_PROVIDER_CONFIG } from '../../src/features/provider-settings/defaults';
const provider = { id: 'fixture', name: 'Provedor Teste', details: { cnpj: '00.000.000/0001-00' }, themeColor: '#673AB7' };
const config = { ...DEFAULT_PROVIDER_CONFIG, notifications: { list: [{ id: 'welcome', title: 'Boas-vindas', message: 'Mensagem salva', category: 'info', createdAt: '2026-01-01' }] }, other: { privacyPolicyUrl: 'https://example.test/privacidade', customDomain: 'app.example.test', speedTestUrl: 'https://speed.example.test' } };
const subscribers = new Set<(value: { config: typeof config; provider: typeof provider }) => void>();
export const auth = { currentUser: null };
export const db = {};
export const functions = {};
export const storage = {};
export function AuthProvider({ children }: { children: ReactNode }) { return children; }
const user = { uid: 'fixture-user', email: 'admin@example.test', getIdToken: async () => 'fixture-token' };
export function useAuth() {
  const userRole = localStorage.getItem('workspaceRole') === 'superAdmin' ? 'superAdmin' : 'providerAdmin';
  return { user, userRole, providerId: userRole === 'superAdmin' ? null : 'fixture', loading: false };
}
export async function subscribeProviderSettings(_id: string, onValue: (value: { config: typeof config; provider: typeof provider }) => void) {
  subscribers.add(onValue);
  queueMicrotask(() => { if (subscribers.has(onValue)) onValue({ config: structuredClone(config), provider }); });
  return () => { subscribers.delete(onValue); };
}
export async function saveProviderSettings(_id: string, next: typeof config) {
  Object.assign(config, structuredClone(next));
  subscribers.forEach(callback => callback({ config: structuredClone(config), provider }));
}
const calls: unknown[] = [];
Object.assign(window, { workspaceCalls: calls });
async function callFunction(type: string, payload: unknown) {
  calls.push({ type, payload });
  if (type === 'GET_PROVIDER_DASHBOARD_DATA') return { stats: { totalClients: 10, openTicketsCount: 2, notificationCount: 3 }, recentTickets: [] };
  if (type === 'GET_DASHBOARD_DATA') return { stats: { providerCount: 1, clientCount: 10, openTicketsCount: 2, notificationCount: 3 }, chartData: [], recentTickets: [] };
  if (type === 'GET_PROVIDER_TICKETS' || type === 'LIST_PROVIDER_BACKUPS') return [];
  return { success: true, message: 'Operação concluída.' };
}
export function useApi() { return { callFunction, loading: false }; }
export function subscribeProvider(_id: string, onValue: (value: typeof provider) => void) { queueMicrotask(() => onValue(provider)); return () => {}; }
export async function getProvider() { return provider; }
export function subscribeProviders(onValue: (value: Array<typeof provider>) => void) { queueMicrotask(() => onValue([provider])); return () => {}; }
