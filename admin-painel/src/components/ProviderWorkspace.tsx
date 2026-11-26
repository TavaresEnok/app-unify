import { Navigate, Outlet, useParams } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { SettingsProvider, useSettings } from "@/contexts/SettingsContext";
import { Button } from "@/components/ui/button";

export default function ProviderWorkspace() {
  const { providerId: routeId } = useParams();
  const { userRole, providerId } = useAuth();
  const id = userRole === "superAdmin" ? routeId : providerId;
  // Super Admin abre a base de um provedor por /provedores/:id/clientes.
  if (!id && userRole === "superAdmin") return <Navigate to="/provedores" replace />;
  if (!id) return <p>Não foi possível identificar o provedor.</p>;
  return <SettingsProvider providerId={id}><WorkspaceContent /></SettingsProvider>;
}

/** Falha ao carregar: não mostra telas com valores padrão que poderiam ser salvos por cima dos reais. */
function WorkspaceContent() {
  const { provider, loadError, retryLoad } = useSettings();
  if (!provider && loadError) {
    return (
      <div role="alert" className="flex flex-col items-center gap-3 p-8 text-center">
        <h2 className="text-lg font-semibold text-destructive">Não foi possível carregar o provedor.</h2>
        <p className="text-sm text-muted-foreground">{loadError}</p>
        <Button onClick={retryLoad}>Tentar novamente</Button>
      </div>
    );
  }
  return <Outlet />;
}
