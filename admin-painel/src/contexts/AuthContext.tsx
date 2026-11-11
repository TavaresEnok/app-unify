import React, { useContext, useState, useEffect } from 'react';
import { onIdTokenChanged, User } from 'firebase/auth';
import { auth } from '@/firebase/auth';
import { Loader2 } from 'lucide-react';
import { fetchDashboard, clearDashboardPrefetch } from '@/shared/api/dashboard';
import { preloadDashboardPages } from '@/app/dashboardPreload';
import { markPanelAuthReady } from '@/shared/api/panelTiming';

interface AuthContextType {
    user: User | null;
    userRole: 'superAdmin' | 'providerAdmin' | null;
    providerId: string | null;
    loading: boolean;
}

const AuthContext = React.createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<User | null>(null);
    const [userRole, setUserRole] = useState<'superAdmin' | 'providerAdmin' | null>(null);
    const [providerId, setProviderId] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // onIdTokenChanged (em vez de onAuthStateChanged) também dispara quando o
        // token é renovado, então mudanças de custom claims (ex.: revogação de
        // superAdmin) refletem no cliente sem exigir novo login.
        let version = 0;
        const refreshedLegacySessions = new Set<string>();
        const unsubscribe = onIdTokenChanged(auth, async (currentUser) => {
            const currentVersion = ++version;
            try {
                if (currentUser) {
                    let tokenResult = await currentUser.getIdTokenResult();
                    if (!tokenResult.claims.role && tokenResult.claims.providerId && !refreshedLegacySessions.has(currentUser.uid)) {
                        refreshedLegacySessions.add(currentUser.uid);
                        tokenResult = await currentUser.getIdTokenResult(true);
                    }
                    if (currentVersion !== version) return;
                    const claimedProviderId = typeof tokenResult.claims.providerId === 'string'
                        ? tokenResult.claims.providerId
                        : null;

                    setUser(currentUser);
                    if (tokenResult.claims.superAdmin === true) {
                        setUserRole('superAdmin');
                        setProviderId(null);
                    } else if (claimedProviderId && tokenResult.claims.role === 'providerAdmin') {
                        setUserRole('providerAdmin');
                        setProviderId(claimedProviderId);
                    } else {
                        setUserRole(null);
                        setProviderId(null);
                    }

                    const entry = /^\/(?:painel\/)?(?:login|dashboard|provedor\/dashboard)?\/?$/.test(window.location.pathname);
                    if (entry && (tokenResult.claims.superAdmin === true ||
                        (claimedProviderId && tokenResult.claims.role === 'providerAdmin'))) {
                        markPanelAuthReady();
                        preloadDashboardPages();
                        void fetchDashboard(currentUser, tokenResult.claims.superAdmin === true ? undefined : claimedProviderId!).catch(() => undefined);
                    }

                    if (import.meta.env.DEV) {
                        console.debug('[AuthContext]', {
                            role: tokenResult.claims.superAdmin === true ? 'superAdmin' : 'providerAdmin',
                            providerId: claimedProviderId,
                        });
                    }
                } else {
                    clearDashboardPrefetch();
                    setUser(null);
                    setUserRole(null);
                    setProviderId(null);
                }
            } catch (error) {
                if (currentVersion !== version) return;
                console.error('[AuthContext] Falha ao validar a sessão.', error);
                setUser(null);
                setUserRole(null);
                setProviderId(null);
            } finally {
                if (currentVersion === version) setLoading(false);
            }
        });
        // Força a renovação periódica do ID token para que privilégios revogados
        // no servidor não persistam no cliente por até ~1h.
        const refreshTimer = window.setInterval(() => {
            auth.currentUser?.getIdToken(true).catch(() => undefined);
        }, 15 * 60 * 1000);

        return () => {
            version++;
            unsubscribe();
            window.clearInterval(refreshTimer);
        };
    }, []);

    if (loading) {
        return (
            <div className="flex h-screen w-full items-center justify-center bg-background">
                <Loader2 className="h-8 w-8 animate-spin" />
            </div>
        );
    }

    return (
        <AuthContext.Provider value={{ user, userRole, providerId, loading }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
