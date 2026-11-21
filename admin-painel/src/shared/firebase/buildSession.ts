import { EmailAuthProvider, reauthenticateWithCredential, type User } from 'firebase/auth';

// Leave time for saving settings and preparing the logo before the backend's
// five-minute authentication window ends. Token refresh keeps auth_time intact.
const BUILD_LOGIN_MAX_AGE_SECONDS = 240;

export async function needsBuildConfirmation(user: Pick<User, 'getIdTokenResult'>): Promise<boolean> {
    const { claims } = await user.getIdTokenResult();
    const now = Date.now() / 1000;
    const authTime = claims.auth_time;
    return typeof authTime !== 'number' || !Number.isFinite(authTime) || authTime <= 0 ||
        authTime > now + 30 || now - authTime >= BUILD_LOGIN_MAX_AGE_SECONDS;
}

export async function confirmBuildSession(user: User, password: string): Promise<void> {
    if (!user.email) throw new Error('Esta conta não permite confirmação por senha. Entre novamente no painel.');
    await reauthenticateWithCredential(user, EmailAuthProvider.credential(user.email, password));
}
