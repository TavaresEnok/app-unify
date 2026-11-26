import { useEffect, useState } from "react";
import { AlertTriangle, Smartphone } from "lucide-react";
import { useSettings } from "@/contexts/SettingsContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { SettingsPage, SettingsSection } from "@/components/settings/SettingsPage";
import { appVersionFormFromConfig, buildAppVersion, mergeAppVersion, type AppVersionForm } from "@/features/provider-settings/appVersion";

export default function ForceUpdate() {
  const { config, saveConfig, isSaving } = useSettings();
  const [form, setForm] = useState<AppVersionForm>(() => appVersionFormFromConfig(config));
  const [error, setError] = useState("");

  useEffect(() => {
    setForm(appVersionFormFromConfig(config));
    // Recarrega só quando o valor salvo muda.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [config.appVersion]);

  const update = (patch: Partial<AppVersionForm>) => {
    setForm((current) => ({ ...current, ...patch }));
    setError("");
  };

  const handleSave = async () => {
    const result = buildAppVersion(form);
    if (!result.ok) {
      setError(result.error);
      return;
    }
    try {
      // Salva direto (não depende do botão do topo) e só esta parte da configuração.
      await saveConfig({ ...config, appVersion: mergeAppVersion(config.appVersion, result.value) });
      setError("");
    } catch {
      // saveConfig já mostrou o erro.
    }
  };

  return (
    <SettingsPage
      title="Versão do app"
      description="Peça para o assinante atualizar o aplicativo quando sair uma versão nova."
      icon={Smartphone}
      actions={<Button onClick={() => void handleSave()} disabled={isSaving}>Salvar versão</Button>}
    >
      {error && (
        <div role="alert" className="flex items-center gap-2 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
          <AlertTriangle className="h-4 w-4" aria-hidden="true" />{error}
        </div>
      )}
      <SettingsSection title="Versões" description="Use o formato 1.2.3. Deixe em branco para não pedir atualização.">
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-1.5">
            <Label htmlFor="minVersion">Versão mínima (bloqueia)</Label>
            <Input id="minVersion" inputMode="decimal" placeholder="1.0.0" value={form.minVersion} onChange={(event) => update({ minVersion: event.target.value })} />
            <p className="text-xs text-muted-foreground">Abaixo desta versão o app mostra a tela "Atualize o app" e não deixa continuar.</p>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="latestVersion">Última versão (aviso)</Label>
            <Input id="latestVersion" inputMode="decimal" placeholder="1.0.5" value={form.latestVersion} onChange={(event) => update({ latestVersion: event.target.value })} />
            <p className="text-xs text-muted-foreground">Abaixo desta versão o app mostra só um aviso, sem bloquear.</p>
          </div>
        </div>
      </SettingsSection>
      <SettingsSection title="Loja" description="Para onde o botão Atualizar leva o assinante.">
        <div className="space-y-1.5">
          <Label htmlFor="storeUrl">Link da loja (Google Play)</Label>
          <Input id="storeUrl" type="url" placeholder="https://play.google.com/store/apps/details?id=..." value={form.storeUrl} onChange={(event) => update({ storeUrl: event.target.value })} />
        </div>
      </SettingsSection>
    </SettingsPage>
  );
}
