import { Outlet, useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, ExternalLink, Save, Smartphone, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { SettingsProvider, useSettings } from "@/contexts/SettingsContext";
import { useAuth } from "@/contexts/AuthContext";

function ProviderDetailContent() {
  const navigate = useNavigate();
  const { userRole } = useAuth();
  const { providerId, provider, config, saveConfig, isSaving } = useSettings();

  if (!provider) {
    return <div className="p-8 text-center"><h2 className="text-xl font-semibold text-destructive">Provedor não encontrado.</h2></div>;
  }

  const displayName = String(provider.name || providerId);
  const initials = displayName.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join("").toUpperCase();
  const cnpj = String(provider.cnpj || provider.document || providerId);
  const plan = String(provider.plan || provider.plano || "Standard");
  const status = String(provider.appStatus || provider.statusApp || "Publicado");
  const avatarColor = String(provider.themeColor || config.themeColor || "#10324B");

  const handleSave = async () => {
    try {
      await saveConfig();
    } catch (error) {
      console.error("Falha ao salvar configurações", error);
    }
  };

  return (
    <div className="flex h-full flex-col gap-5">
      {userRole === "superAdmin" && (
        <button type="button" onClick={() => navigate("/provedores")} className="inline-flex w-fit items-center gap-1.5 text-[12.5px] font-semibold text-[#687181] transition-colors hover:text-primary">
          <ArrowLeft className="h-3.5 w-3.5" />
          Voltar para provedores
        </button>
      )}

      <div className="flex flex-col gap-4 rounded-xl border border-[#E6E9EF] bg-white p-[18px] shadow-[0_1px_2px_rgba(16,24,40,.04)] sm:flex-row sm:items-center">
        <div className="grid h-[46px] w-[46px] shrink-0 place-items-center rounded-[10px] text-[15px] font-bold text-white" style={{ backgroundColor: avatarColor }}>
          {initials}
        </div>
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-[16.5px] font-bold tracking-normal text-[#0E1320]">{displayName}</h2>
          <div className="mt-1 flex flex-wrap items-center gap-2">
            <span className="rounded-[5px] bg-[#F2F4F7] px-2 py-0.5 font-mono text-[11px] text-[#687181]">{cnpj}</span>
            <span className="rounded-md bg-[#EEF0F4] px-2 py-0.5 text-[11.5px] font-semibold text-[#4A5364]">{plan}</span>
            <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-semibold text-emerald-700">
              <span className="h-1.5 w-1.5 rounded-full bg-current" />{status}
            </span>
          </div>
        </div>
        <div className="flex flex-wrap gap-2 sm:justify-end">
          <Button variant="outline" className="gap-2" onClick={() => toast.info("A URL pública deve ser definida nas configurações do provedor.")}>
            <ExternalLink className="h-3.5 w-3.5" />Ver app publicado
          </Button>
          <Button variant="outline" onClick={() => navigate(`${userRole === "superAdmin" ? `/provedores/${providerId}` : "/provedor/personalizacao"}/app-build`)} className="gap-2">
            <Smartphone className="h-3.5 w-3.5" />Gerar APK
          </Button>
          <Button onClick={handleSave} disabled={isSaving} className="gap-2">
            {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            Salvar alterações
          </Button>
        </div>
      </div>

      <Outlet />
    </div>
  );
}

export default function ProviderDetailPage() {
  const { providerId: routeProviderId } = useParams<{ providerId: string }>();
  const { userRole, providerId: authProviderId } = useAuth();
  const providerId = userRole === "superAdmin" ? routeProviderId : authProviderId;
  if (!providerId) return <div className="p-8 text-center text-destructive">ID do provedor não identificado.</div>;
  return <SettingsProvider providerId={providerId}><ProviderDetailContent /></SettingsProvider>;
}
