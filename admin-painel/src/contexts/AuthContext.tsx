import React, { useContext, useState, useEffect } from 'react';
import { onAuthStateChanged, User } from 'firebase/auth';
import { auth } from '@/firebase/config';
import { Loader2 } from 'lucide-react';

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
        const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
            if (currentUser) {
                await currentUser.getIdToken(true);
                const tokenResult = await currentUser.getIdTokenResult();

                setUser(currentUser);
                if (tokenResult.claims.superAdmin) {
                    setUserRole('superAdmin');
                    setProviderId(null);
                } else if (tokenResult.claims.providerId) {
                    setUserRole('providerAdmin');
                    setProviderId(tokenResult.claims.providerId as string);
                } else {
                    setUserRole(null);
                    setProviderId(null);
                }
                console.log('[AuthContext] User:', currentUser.email, 'Role:', tokenResult.claims.superAdmin ? 'super' : 'provider', 'ProviderID:', tokenResult.claims.providerId);
            } else {
                console.log('[AuthContext] No User');
                setUser(null);
                setUserRole(null);
                setProviderId(null);
            }
            setLoading(false);
        });
        return () => unsubscribe();
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
