import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { onAuthStateChanged, User } from 'firebase/auth';
import { auth } from '../firebase/config';
import { Spin } from 'antd';

// Define o formato das informações de autenticação que vamos armazenar
interface AuthContextType {
  user: User | null;
  userRole: 'superAdmin' | 'providerAdmin' | null;
  providerId: string | null;
  loading: boolean;
}

// Cria o nosso contexto
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Cria o componente "Provedor" do nosso contexto
export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [userRole, setUserRole] = useState<'superAdmin' | 'providerAdmin' | null>(null);
  const [providerId, setProviderId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Escuta por mudanças no estado de login (login, logout)
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setLoading(true);
      if (currentUser) {
        setUser(currentUser);
        // Força a atualização do token para pegar as permissões mais recentes
        const tokenResult = await currentUser.getIdTokenResult(true);
        
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
      } else {
        setUser(null);
        setUserRole(null);
        setProviderId(null);
      }
      setLoading(false);
    });

    // Limpa o "escutador" quando o componente é desmontado
    return () => unsubscribe();
  }, []);

  // Enquanto carrega as informações, mostra um spinner
  if (loading) {
    return <Spin size="large" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }} />;
  }

  return (
    <AuthContext.Provider value={{ user, userRole, providerId, loading }}>
      {children}
    </AuthContext.Provider>
  );
};

// Hook customizado para facilitar o uso do nosso contexto
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
