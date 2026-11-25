import React, { useContext, useState, useEffect } from 'react';
import { Loader2 } from 'lucide-react';
import { subscribeAuth, refreshCurrentUser, getCurrentUser, type SessionUser } from '@/shared/auth/session';
import { fetchDashboard, clearDashboardPrefetch } from '@/shared/api/dashboard';
import { preloadDashboardPages } from '@/app/dashboardPreload';
import { markPanelAuthReady } from '@/shared/api/panelTiming';
import { resetPanelSession } from '@/shared/api/panelHttp';

interface AuthContextType {
    user: SessionUser | null;
    userRole: 'superAdmin' | 'providerAdmin' | null;
    providerId: string | null;
    loading: boolean;
}

const AuthContext = React.createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<SessionUser | null>(null);
    const [userRole, setUserRole] = useState<'superAdmin' | 'providerAdmin' | null>(null);
    const [providerId, setProviderId] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let sessionKey: string | null = null;
        const unsubscribe = subscribeAuth((currentUser) => {
            if (currentUser) {
                const claimedProviderId = currentUser.providerId || null;
                const nextSessionKey = JSON.stringify([
                    currentUser.uid,
                    currentUser.authTime,
                    currentUser.role,
                    claimedProviderId,
                    currentUser.superAdmin === true,
                ]);
                if (sessionKey !== nextSessionKey) {
                    resetPanelSession();
                    sessionKey = nextSessionKey;
                }

                setUser(currentUser);
                if (currentUser.superAdmin === true) {
                    setUserRole('superAdmin');
                    setProviderId(null);
                } else if (claimedProviderId && currentUser.role === 'providerAdmin') {
                    setUserRole('providerAdmin');
                    setProviderId(claimedProviderId);
                } else {
                    setUserRole(null);
                    setProviderId(null);
                }

                const entry = typeof window !== 'undefined'
                    && /^\/(?:painel\/)?(?:login|dashboard|provedor\/dashboard)?\/?$/.test(window.location.pathname);
                if (entry && (currentUser.superAdmin === true || (claimedProviderId && currentUser.role === 'providerAdmin'))) {
                    markPanelAuthReady();
                    preloadDashboardPages();
                    void fetchDashboard(currentUser, currentUser.superAdmin === true ? undefined : claimedProviderId!).catch(() => undefined);
                }
            } else {
                resetPanelSession();
                sessionKey = null;
                clearDashboardPrefetch();
                setUser(null);
                setUserRole(null);
                setProviderId(null);
            }
            setLoading(false);
        });

        const refreshTimer = window.setInterval(() => {
            if (getCurrentUser()) {
                refreshCurrentUser().catch(() => undefined);
            }
        }, 15 * 60 * 1000);

        return () => {
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
