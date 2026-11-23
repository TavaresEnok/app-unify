// Loaded only by the isolated workspace browser tests.
export async function needsBuildConfirmation() {
    return localStorage.getItem('workspaceBuildStale') === 'true';
}

export async function confirmBuildSession(_user: unknown, password: string) {
    if (password !== 'fixture-password') throw Object.assign(new Error('Invalid credentials'), { code: 'auth/invalid-credential' });
    localStorage.removeItem('workspaceBuildStale');
}
