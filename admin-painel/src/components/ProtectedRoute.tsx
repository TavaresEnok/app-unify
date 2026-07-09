import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Loader2 } from 'lucide-react';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRole?: 'superAdmin' | 'providerAdmin';
}

export default function ProtectedRoute({ children, requiredRole }: ProtectedRouteProps) {
  const { user, userRole, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex h-screen w-full items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // Verifica se o usuário tem uma role válida
  if (!userRole) {
    console.warn('[ProtectedRoute] Usuário autenticado sem role válida:', user.email);
    return <Navigate to="/login" replace />;
  }

  // Se uma role específica é exigida, verifica
  if (requiredRole && userRole !== requiredRole && userRole !== 'superAdmin') {
    console.warn(`[ProtectedRoute] Role "${userRole}" insuficiente. Requerido: "${requiredRole}"`);
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}
