import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Loader2 } from 'lucide-react';

export default function LandingPage() {
    const { userRole, providerId, loading } = useAuth();

    if (loading) {
        return <div className="flex h-screen w-full items-center justify-center"><Loader2 className="h-8 w-8 animate-spin" /></div>;
    }

    if (userRole === 'superAdmin') {
        return <Navigate to="/dashboard" replace />;
    }

    if (userRole === 'providerAdmin' && providerId) {
        return <Navigate to={`/provedores/${providerId}`} replace />;
    }
    
    // Se não tiver papel, volta para o login
    return <Navigate to="/login" replace />;
}
