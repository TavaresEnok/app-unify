import { Suspense, lazy } from 'react';
import { Routes, Route, Navigate, useParams } from "react-router-dom";
import { AuthProvider, useAuth } from "@/contexts/AuthContext";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import MainLayout from "@/components/MainLayout";
import ProtectedRoute from "@/components/ProtectedRoute";
import ProviderSettingsLayout from "@/components/ProviderSettingsLayout";
import { Loader2 } from 'lucide-react';
import { loadGlobalDashboardPage, loadProviderDashboardPage } from '@/app/dashboardPreload';

// Lazy Imports for Performance
const ProviderWorkspace = lazy(() => import("@/components/ProviderWorkspace"));
const DashboardBuilder = lazy(() => import('./pages/provider-settings/DashboardBuilder'));
const NotificationsManager = lazy(() => import('./pages/provider-settings/NotificationsManager'));
const PromotionsManager = lazy(() => import('./pages/provider-settings/PromotionsManager'));
const SplashLoginConfig = lazy(() => import('./pages/provider-settings/SplashLoginConfig'));
const DashboardPage = lazy(loadGlobalDashboardPage);
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
const ApplicationSettings = lazy(() => import("@/pages/provider-settings/ApplicationSettings"));
const PrivacySettings = lazy(() => import("@/pages/provider-settings/PrivacySettings"));
const AttendanceLayout = lazy(() => import("@/pages/provider/AttendanceLayout"));
const CommunicationsLayout = lazy(() => import("@/pages/provider/CommunicationsLayout"));
const CompanyLayout = lazy(() => import("@/pages/provider/CompanyLayout"));
const ApplicationPage = lazy(() => import("@/pages/provider/ApplicationPage"));
const BackupSettings = lazy(() => import("@/pages/provider-settings/BackupSettings"));
const IntegrationsSettings = lazy(() => import("@/pages/provider-settings/IntegrationsSettings"));
const PersonalizedTextsSettings = lazy(() => import("@/pages/provider-settings/PersonalizedTextsSettings"));
const TermsOfUseSettings = lazy(() => import("@/pages/provider-settings/TermsOfUseSettings"));
const ForceUpdate = lazy(() => import("@/pages/provider-settings/ForceUpdate"));
const ProviderDashboardPage = lazy(loadProviderDashboardPage);
const NotificationSenderPage = lazy(() => import("./pages/provider/NotificationSenderPage"));
const DiagnosticHistoryPage = lazy(() => import("./pages/provider/DiagnosticHistoryPage"));
const IncidentsPage = lazy(() => import("./pages/provider/IncidentsPage"));
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

function LegacyTicketRedirect() {
  const { ticketId } = useParams();
  return <Navigate to={`/provedor/atendimento/chamados/${encodeURIComponent(ticketId || "")}`} replace />;
}

function LegacyNotificationsRedirect() {
  const { userRole, providerId: authProviderId } = useAuth();
  const { providerId: routeProviderId } = useParams();
  const providerId = userRole === "superAdmin" ? routeProviderId : authProviderId;
  return <Navigate to={userRole === "superAdmin" ? `/provedores/${providerId}/comunicados/modelos` : "/provedor/comunicados/modelos"} replace />;
}

const CommunicationsRoutes = (
  <Route element={<CommunicationsLayout />}>
    <Route index element={<Navigate to="notificacoes" replace />} />
    <Route path="notificacoes" element={<NotificationSenderPage />} />
    <Route path="historico" element={<NotificationSenderPage historyOnly />} />
    <Route path="modelos" element={<NotificationsManager />} />
    <Route path="instabilidades" element={<IncidentsPage />} />
  </Route>
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
    <Route path="integrations" element={<ProtectedRoute requiredRole="superAdmin"><IntegrationsSettings /></ProtectedRoute>} />
    <Route path="support" element={<SupportSettings />} />
    <Route path="carousel" element={<CarouselSettings />} />
    <Route path="social" element={<SocialNetworksSettings />} />
    <Route path="tips" element={<TipsSettings />} />
    <Route path="faq" element={<FaqSettings />} />
    <Route path="messages" element={<MessagesSettings />} />
    <Route path="other" element={<Navigate to="../application-settings" replace />} />
    <Route path="application-settings" element={<ApplicationSettings />} />
    <Route path="privacy" element={<PrivacySettings />} />
    <Route path="backup" element={<BackupSettings />} />
    <Route path="dashboard-builder" element={<DashboardBuilder />} />
    <Route path="notifications" element={<LegacyNotificationsRedirect />} />
    <Route path="promotions" element={<PromotionsManager />} />
    <Route path="splash-login" element={<SplashLoginConfig />} />
    <Route path="texts" element={<PersonalizedTextsSettings />} />
    <Route path="terms" element={<TermsOfUseSettings />} />
    <Route path="force-update" element={<ForceUpdate />} />
    <Route path="app-build" element={<ProtectedRoute requiredRole="superAdmin"><AndroidBuilderPage /></ProtectedRoute>} />
  </Route>
);

// Force HMR Update
export default function App() {
  return (
    <ThemeProvider defaultTheme="light" storageKey="vite-ui-theme">
      <AuthProvider>
        <Suspense fallback={<LoadingFallback />}>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/" element={<ProtectedRoute><PostLoginRedirect /></ProtectedRoute>} />
            <Route path="/" element={<ProtectedRoute><MainLayout /></ProtectedRoute>}>
              <Route path="dashboard" element={<ProtectedRoute requiredRole="superAdmin"><DashboardPage /></ProtectedRoute>} />
              <Route path="provedores" element={<ProtectedRoute requiredRole="superAdmin"><ProvidersPage /></ProtectedRoute>} />
              <Route path="utilizadores" element={<ProtectedRoute requiredRole="superAdmin"><UsersPage /></ProtectedRoute>} />
              <Route path="tickets" element={<ProtectedRoute requiredRole="superAdmin"><AdminTicketsPage /></ProtectedRoute>} />
              <Route path="tickets/:ticketId" element={<ProtectedRoute requiredRole="superAdmin"><TicketDetailPage /></ProtectedRoute>} />
              <Route path="provedores/:providerId" element={<ProtectedRoute requiredRole="superAdmin"><ProviderDetailPage /></ProtectedRoute>}>
                {ProviderSettingsRoutes}
                <Route path="comunicados">{CommunicationsRoutes}</Route>
                <Route path="aplicativo" element={<ApplicationPage />} />
              </Route>
              <Route path="provedor/dashboard" element={<ProviderDashboardPage />} />
              <Route path="provedor/notificacoes" element={<Navigate to="/provedor/comunicados/notificacoes" replace />} />
              <Route path="provedor/clientes/*" element={<Navigate to="/provedor/dashboard" replace />} />
              <Route element={<ProviderWorkspace />}>
                <Route path="provedor/comunicados">{CommunicationsRoutes}</Route>
                <Route path="provedor/aplicativo" element={<ApplicationPage />} />
                <Route path="provedor/minha-empresa" element={<CompanyLayout />}>
                  <Route index element={<Navigate to="dados" replace />} />
                  <Route path="dados" element={<MyCompanyPage />} />
                  <Route path="contatos" element={<SupportSettings />} />
                  <Route path="redes-sociais" element={<SocialNetworksSettings />} />
                </Route>
              </Route>
              <Route path="provedor/atendimento" element={<AttendanceLayout />}>
                <Route index element={<Navigate to="chamados" replace />} />
                <Route path="chamados" element={<ProviderTicketsPage />} />
                <Route path="chamados/:ticketId" element={<TicketDetailPage />} />
                <Route path="diagnosticos" element={<DiagnosticHistoryPage />} />
              </Route>
              <Route path="provedor/tickets" element={<Navigate to="/provedor/atendimento/chamados" replace />} />
              <Route path="provedor/diagnosticos" element={<Navigate to="/provedor/atendimento/diagnosticos" replace />} />
              <Route path="provedor/instabilidades" element={<Navigate to="/provedor/comunicados/instabilidades" replace />} />
              <Route path="provedor/tickets/:ticketId" element={<LegacyTicketRedirect />} />
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
