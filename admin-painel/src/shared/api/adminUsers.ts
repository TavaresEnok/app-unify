import { clearPanelReads, panelRequest } from './panelHttp';
import { withRecentLogin } from '@/shared/auth/recentLogin';

/** Super Admin redefine a senha de outro administrador (PATCH /admin/users/:uid/password). */
export async function resetAdminUserPassword(uid: string, password: string): Promise<void> {
  // O servidor exige login recente: pede a senha do Super Admin e repete.
  await withRecentLogin(() => panelRequest(`/admin/users/${encodeURIComponent(uid)}/password`, {
    method: 'PATCH',
    body: { password },
  }));
  clearPanelReads();
}
