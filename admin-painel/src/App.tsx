import { Routes, Route, Navigate } from "react-router-dom";
import DashboardBuilder from './pages/provider-settings/DashboardBuilder';
import NotificationsManager from './pages/provider-settings/NotificationsManager';
import PromotionsManager from './pages/provider-settings/PromotionsManager';
import SplashLoginConfig from './pages/provider-settings/SplashLoginConfig';
import { AuthProvider, useAuth } from "@/contexts/AuthContext";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import MainLayout from "@/components/MainLayout";
import DashboardPage from "@/pages/DashboardPage";
import ProvidersPage from "@/pages/ProvidersPage";
import ProviderDetailPage from "@/pages/ProviderDetailPage";
import UsersPage from "@/pages/UsersPage";
import LoginPage from "@/pages/LoginPage";
import ProtectedRoute from "@/components/ProtectedRoute";
import ProviderSettingsLayout from "@/components/ProviderSettingsLayout";
import AppearanceSettings from "@/pages/provider-settings/AppearanceSettings";
import TypographySettings from "@/pages/provider-settings/TypographySettings";
import IconPackSettings from "@/pages/provider-settings/IconPackSettings";
import FeaturesSettings from "@/pages/provider-settings/FeaturesSettings";
import SupportSettings from "@/pages/provider-settings/SupportSettings";
import CarouselSettings from "@/pages/provider-settings/CarouselSettings";
import TipsSettings from "@/pages/provider-settings/TipsSettings";
import FaqSettings from "@/pages/provider-settings/FaqSettings";
import ImagesIconsSettings from "@/pages/provider-settings/ImagesIconsSettings";
import MessagesSettings from "@/pages/provider-settings/MessagesSettings";
import SocialNetworksSettings from "@/pages/provider-settings/SocialNetworksSettings";
import OtherSettings from "@/pages/provider-settings/OtherSettings";
import BackupSettings from "@/pages/provider-settings/BackupSettings";
import IntegrationsSettings from "@/pages/provider-settings/IntegrationsSettings";
import PersonalizedTextsSettings from "@/pages/provider-settings/PersonalizedTextsSettings";
import ProviderDashboardPage from "./pages/provider/ProviderDashboardPage";
import NotificationSenderPage from "./pages/provider/NotificationSenderPage";
import ProviderClientsPage from "./pages/provider/ProviderClientsPage";
import ClientDetailPage from "./pages/provider/ClientDetailPage";
import AdminTicketsPage from "./pages/AdminTicketsPage";
import ProviderTicketsPage from "./pages/provider/ProviderTicketsPage";
import TicketDetailPage from "./pages/TicketDetailPage";
import MyCompanyPage from "./pages/provider/MyCompanyPage";
import MenusSettingsPage from "./pages/provider-settings/MenusSettingsPage";
import AppBuildSettings from "./pages/provider-settings/AppBuildSettings";

function PostLoginRedirect() {
  const { userRole } = useAuth();
  if (userRole === 'superAdmin') return <Navigate to="/dashboard" replace />;
  if (userRole === 'providerAdmin') return <Navigate to="/provedor/dashboard" replace />;
  return <Navigate to="/login" replace />;
}

const ProviderSettingsRoutes = (
  <Route element={<ProviderSettingsLayout />}>
    <Route index element={<Navigate to="appearance" replace />} />
    <Route path="appearance" element={<AppearanceSettings />} />
    <Route path="typography" element={<TypographySettings />} />
    <Route path="icon-pack" element={<IconPackSettings />} />
    <Route path="images" element={<ImagesIconsSettings />} />
    <Route path="menus" element={<MenusSettingsPage />} />
    <Route path="features" element={<FeaturesSettings />} />
    <Route path="integrations" element={<IntegrationsSettings />} />
    <Route path="support" element={<SupportSettings />} />
    <Route path="carousel" element={<CarouselSettings />} />
    <Route path="social" element={<SocialNetworksSettings />} />
    <Route path="tips" element={<TipsSettings />} />
    <Route path="faq" element={<FaqSettings />} />
    <Route path="messages" element={<MessagesSettings />} />
    <Route path="other" element={<OtherSettings />} />
    <Route path="backup" element={<BackupSettings />} />
    <Route path="dashboard-builder" element={<DashboardBuilder />} />
    <Route path="notifications" element={<NotificationsManager />} />
    <Route path="promotions" element={<PromotionsManager />} />
    <Route path="splash-login" element={<SplashLoginConfig />} />
    <Route path="texts" element={<PersonalizedTextsSettings />} />
    <Route path="app-build" element={<AppBuildSettings />} />
  </Route>
);

export default function App() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="vite-ui-theme">
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/" element={<ProtectedRoute><PostLoginRedirect /></ProtectedRoute>} />
          <Route path="/" element={<ProtectedRoute><MainLayout /></ProtectedRoute>}>
            <Route path="dashboard" element={<DashboardPage />} />
            <Route path="provedores" element={<ProvidersPage />} />
            <Route path="utilizadores" element={<UsersPage />} />
            <Route path="tickets" element={<AdminTicketsPage />} />
            <Route path="tickets/:ticketId" element={<TicketDetailPage />} />
            <Route path="provedores/:providerId" element={<ProviderDetailPage />}>
              {ProviderSettingsRoutes}
            </Route>
            <Route path="provedor/dashboard" element={<ProviderDashboardPage />} />
            <Route path="provedor/notificacoes" element={<NotificationSenderPage />} />
            <Route path="provedor/clientes" element={<ProviderClientsPage />} />
            <Route path="provedor/clientes/:clientId" element={<ClientDetailPage />} />
            <Route path="provedor/minha-empresa" element={<MyCompanyPage />} />
            <Route path="provedor/tickets" element={<ProviderTicketsPage />} />
            <Route path="provedor/tickets/:ticketId" element={<TicketDetailPage />} />
            <Route path="provedor/personalizacao" element={<ProviderDetailPage />}>
              {ProviderSettingsRoutes}
            </Route>
          </Route>
        </Routes>
      </AuthProvider>
      <Toaster />
    </ThemeProvider>
  );
}
