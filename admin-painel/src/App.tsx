import { Suspense, lazy } from 'react';
import { Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, useAuth } from "@/contexts/AuthContext";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import MainLayout from "@/components/MainLayout";
import ProtectedRoute from "@/components/ProtectedRoute";
import ProviderSettingsLayout from "@/components/ProviderSettingsLayout";
import { Loader2 } from 'lucide-react';

// Lazy Imports for Performance
const DashboardBuilder = lazy(() => import('./pages/provider-settings/DashboardBuilder'));
const NotificationsManager = lazy(() => import('./pages/provider-settings/NotificationsManager'));
const PromotionsManager = lazy(() => import('./pages/provider-settings/PromotionsManager'));
const SplashLoginConfig = lazy(() => import('./pages/provider-settings/SplashLoginConfig'));
const DashboardPage = lazy(() => import("@/pages/DashboardPage"));
const ProvidersPage = lazy(() => import("@/pages/ProvidersPage"));
const ProviderDetailPage = lazy(() => import("@/pages/ProviderDetailPage"));
const UsersPage = lazy(() => import("@/pages/UsersPage"));
const LoginPage = lazy(() => import("@/pages/LoginPage"));
const AppearanceSettings = lazy(() => import("@/pages/provider-settings/AppearanceSettings"));
const TypographySettings = lazy(() => import("@/pages/provider-settings/TypographySettings"));
const IconPackSettings = lazy(() => import("@/pages/provider-settings/IconPackSettings"));
const FeaturesSettings = lazy(() => import("@/pages/provider-settings/FeaturesSettings"));
const SupportSettings = lazy(() => import("@/pages/provider-settings/SupportSettings"));
const CarouselSettings = lazy(() => import("@/pages/provider-settings/CarouselSettings"));
const TipsSettings = lazy(() => import("@/pages/provider-settings/TipsSettings"));
const FaqSettings = lazy(() => import("@/pages/provider-settings/FaqSettings"));
const ImagesIconsSettings = lazy(() => import("@/pages/provider-settings/ImagesIconsSettings"));
const MessagesSettings = lazy(() => import("@/pages/provider-settings/MessagesSettings"));
const SocialNetworksSettings = lazy(() => import("@/pages/provider-settings/SocialNetworksSettings"));
const OtherSettings = lazy(() => import("@/pages/provider-settings/OtherSettings"));
const BackupSettings = lazy(() => import("@/pages/provider-settings/BackupSettings"));
const IntegrationsSettings = lazy(() => import("@/pages/provider-settings/IntegrationsSettings"));
const PersonalizedTextsSettings = lazy(() => import("@/pages/provider-settings/PersonalizedTextsSettings"));
const ProviderDashboardPage = lazy(() => import("./pages/provider/ProviderDashboardPage"));
const NotificationSenderPage = lazy(() => import("./pages/provider/NotificationSenderPage"));
const ProviderClientsPage = lazy(() => import("./pages/provider/ProviderClientsPage"));
const DiagnosticHistoryPage = lazy(() => import("./pages/provider/DiagnosticHistoryPage"));
const ClientDetailPage = lazy(() => import("./pages/provider/ClientDetailPage"));
const AdminTicketsPage = lazy(() => import("./pages/AdminTicketsPage"));
const ProviderTicketsPage = lazy(() => import("./pages/provider/ProviderTicketsPage"));
const TicketDetailPage = lazy(() => import("./pages/TicketDetailPage"));
const MyCompanyPage = lazy(() => import("./pages/provider/MyCompanyPage"));
const MenusSettingsPage = lazy(() => import("./pages/provider-settings/MenusSettingsPage"));
const AndroidBuilderPage = lazy(() => import("./pages/provider-settings/AndroidBuilder_Final"));

function PostLoginRedirect() {
  const { userRole } = useAuth();
  if (userRole === 'superAdmin') return <Navigate to="/dashboard" replace />;
  if (userRole === 'providerAdmin') return <Navigate to="/provedor/dashboard" replace />;
  return <Navigate to="/login" replace />;
}

const LoadingFallback = () => (
  <div className="flex items-center justify-center h-screen w-full bg-background">
    <div className="flex flex-col items-center gap-2">
      <Loader2 className="h-8 w-8 animate-spin text-primary" />
      <p className="text-sm text-muted-foreground">Carregando...</p>
    </div>
  </div>
);

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
    <Route path="app-build" element={<AndroidBuilderPage />} />
  </Route>
);

// Force HMR Update
export default function App() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="vite-ui-theme">
      <AuthProvider>
        <Suspense fallback={<LoadingFallback />}>
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
              <Route path="provedor/diagnosticos" element={<DiagnosticHistoryPage />} />
              <Route path="provedor/tickets/:ticketId" element={<TicketDetailPage />} />
              <Route path="provedor/personalizacao" element={<ProviderDetailPage />}>
                {ProviderSettingsRoutes}
              </Route>
            </Route>
          </Routes>
        </Suspense>
      </AuthProvider>
      <Toaster />
    </ThemeProvider>
  );
}
