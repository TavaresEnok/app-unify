import { useAuth } from "@/contexts/AuthContext";
import { useSettings } from "@/contexts/SettingsContext";
import WorkspaceTabs from "@/components/WorkspaceTabs";

export default function CommunicationsLayout() {
  const { userRole } = useAuth();
  const { providerId } = useSettings();
  const base = userRole === "superAdmin" ? `/provedores/${providerId}/comunicados` : "/provedor/comunicados";
  return <WorkspaceTabs title="Comunicados" description="Envie mensagens e acompanhe os avisos exibidos no aplicativo." tabs={[
    { label: "Enviar notificação", to: `${base}/notificacoes` },
    { label: "Histórico de envios", to: `${base}/historico` },
    { label: "Modelos salvos", to: `${base}/modelos` },
    { label: "Instabilidades", to: `${base}/instabilidades` },
  ]} />;
}
