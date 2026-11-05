export const loadGlobalDashboardPage = () => import('@/pages/DashboardPage');
export const loadProviderDashboardPage = () => import('@/pages/provider/ProviderDashboardPage');

export function preloadDashboardPages() {
  // These contain UI code only. No protected data is fetched before sign-in.
  void loadGlobalDashboardPage().catch(() => undefined);
  void loadProviderDashboardPage().catch(() => undefined);
}
