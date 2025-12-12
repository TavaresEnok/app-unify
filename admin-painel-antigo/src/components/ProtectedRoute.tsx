import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

interface ProtectedRouteProps {
  children: JSX.Element;
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { user, userRole, providerId, loading } = useAuth();
  const location = useLocation();

  // Se ainda estiver a carregar os dados de autenticação, não faz nada
  if (loading) {
    return null; // A tela de loading já é mostrada pelo AuthProvider
  }

  // Se não há utilizador logado, redireciona para a página de login
  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Se é um Admin de Provedor, e está a tentar aceder a qualquer página
  // que não seja a sua, redireciona-o para a página correta.
  if (userRole === 'providerAdmin' && providerId && location.pathname !== `/provider/${providerId}`) {
    return <Navigate to={`/provider/${providerId}`} replace />;
  }
  
  // Se for Super Admin, ou se for um Admin de Provedor na sua página correta,
  // permite o acesso.
  return children;
};

export default ProtectedRoute;
