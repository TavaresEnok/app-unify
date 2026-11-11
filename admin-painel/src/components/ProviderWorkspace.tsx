import { Outlet, useParams } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { SettingsProvider } from "@/contexts/SettingsContext";

export default function ProviderWorkspace() {
  const { providerId: routeId } = useParams();
  const { userRole, providerId } = useAuth();
  const id = userRole === "superAdmin" ? routeId : providerId;
  if (!id) return <p>Não foi possível identificar o provedor.</p>;
  return <SettingsProvider providerId={id}><Outlet /></SettingsProvider>;
}
