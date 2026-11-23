// Isolated UI fixtures. This module is only aliased by workspace.vite.config.ts.
import type { ReactNode } from 'react';
import { DEFAULT_PROVIDER_CONFIG } from '../../src/features/provider-settings/defaults';
import { toFirestoreProviderConfig } from '../../src/features/provider-settings/normalizers';
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
  const saved = localStorage.getItem('workspaceProviderConfig');
  if (saved) Object.assign(config, JSON.parse(saved));
  queueMicrotask(() => { if (subscribers.has(onValue)) onValue({ config: structuredClone(config), provider }); });
  return () => { subscribers.delete(onValue); };
}
export async function saveProviderSettings(_id: string, next: typeof config) {
  if (localStorage.getItem('workspaceSaveFailure')) throw new Error('Falha de teste ao salvar.');
  const { publicConfig } = toFirestoreProviderConfig(next);
  calls.push({ type: 'UPDATE_PROVIDER_CONFIG', payload: { providerId: _id, config: publicConfig } });
  Object.assign(config, structuredClone(next));
  localStorage.setItem('workspaceProviderConfig', JSON.stringify(config));
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

export function clearPanelReads() {}
export function resetPanelSession() {}
export async function readPanel(path: string) {
  if (localStorage.getItem('workspaceReadFailure')) throw new Error('Falha ao carregar.');
  const cursor = new URL(path, 'http://fixture').searchParams.get('cursor');
  const tickets = path.includes('/tickets/');
  const data = tickets ? [{ id: cursor ? 'ticket-2' : 'ticket-1', subject: cursor ? 'Segundo chamado' : 'Primeiro chamado', providerName: 'Provedor Teste', status: 'Aberto', updatedAt: '2026-11-12T12:00:00Z' }] : [{ uid: cursor ? 'user-2' : 'user-1', email: cursor ? 'segundo@example.test' : 'primeiro@example.test', providerId: 'fixture', superAdmin: false }];
  return { data, nextCursor: cursor ? null : 'next-page' };
}
