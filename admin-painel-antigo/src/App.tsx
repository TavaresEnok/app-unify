// ARQUIVO: admin-painel/src/App.tsx

import React from 'react';
import { Routes, Route } from 'react-router-dom';
// IMPORTAÇÃO ADICIONADA AQUI
import { App as AntApp, ConfigProvider, theme } from 'antd';
import ptBR from 'antd/locale/pt_BR';
import { AuthProvider } from './contexts/AuthContext';

import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ProvidersPage from './pages/ProvidersPage';
import ProviderConfigPage from './pages/ProviderConfigPage';
import UsersPage from './pages/UsersPage';
import ProtectedRoute from './components/ProtectedRoute';
import MainLayout from './components/MainLayout';

import 'antd/dist/reset.css';

const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/" element={<ProtectedRoute><MainLayout /></ProtectedRoute>}>
        <Route index element={<DashboardPage />} />
        <Route path="providers" element={<ProvidersPage />} />
        <Route path="provider/:providerId" element={<ProviderConfigPage />} />
        <Route path="users" element={<UsersPage />} />
      </Route>
    </Routes>
  );
};

const App: React.FC = () => {
  return (
    // O ConfigProvider agora envolve tudo e define o tema
    <ConfigProvider
      locale={ptBR}
      theme={{
        // A "magia" acontece aqui. Ativamos o algoritmo do tema escuro.
        algorithm: theme.darkAlgorithm,
        token: {
          // Cores personalizadas para combinar com a sua referência
          colorPrimary: '#722ED1',
          colorBgBase: '#141414', // Cor de fundo base mais escura
        },
      }}
    >
      <AntApp>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </AntApp>
    </ConfigProvider>
  );
};

export default App;
