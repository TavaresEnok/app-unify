import { useLocation } from "react-router-dom";
import WorkspaceTabs from "@/components/WorkspaceTabs";
import { Button } from "@/components/ui/button";
import { useSettings } from "@/contexts/SettingsContext";

export default function CompanyLayout() {
  const { saveConfig, isSaving } = useSettings();
  const { pathname } = useLocation();
  return <div className="space-y-4">
    {!pathname.endsWith("/dados") && <div className="flex justify-end"><Button disabled={isSaving} onClick={() => void saveConfig().catch(() => {})}>Salvar contatos e redes sociais</Button></div>}
    <WorkspaceTabs title="Minha empresa" description="Dados da empresa e canais de contato exibidos no aplicativo." tabs={[
      { label: "Dados da empresa", to: "/provedor/minha-empresa/dados" },
      { label: "Canais de suporte", to: "/provedor/minha-empresa/contatos" },
      { label: "Redes sociais", to: "/provedor/minha-empresa/redes-sociais" },
    ]} />
  </div>;
}
