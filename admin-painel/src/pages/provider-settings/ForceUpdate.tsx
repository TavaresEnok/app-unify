import { useState } from "react";
import { AlertTriangle, Smartphone } from "lucide-react";
import { useSettings } from "@/contexts/SettingsContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { SettingsPage, SettingsSection } from "@/components/settings/SettingsPage";
import { toast } from "sonner";

interface ForceUpdateConfig {
  minVersion: string;
  latestVersion: string;
  forceUpdate: boolean;
  updateMessage: { pt_BR: { title: string; message: string; buttonText: string } };
  storeUrls: { android: string; ios: string };
}

const DEFAULT_FORCE_UPDATE: ForceUpdateConfig = {
  minVersion: "1.0.0",
  latestVersion: "1.0.0",
  forceUpdate: false,
  updateMessage: {
    pt_BR: {
      title: "Atualização necessária",
      message: "Uma nova versão está disponível. Atualize para continuar.",
      buttonText: "Atualizar agora",
    },
  },
  storeUrls: { android: "", ios: "" },
};

function compareVersions(left: string, right: string): number {
  const a = left.split(".").map(Number);
  const b = right.split(".").map(Number);
  for (let index = 0; index < 3; index += 1) {
    if (a[index] !== b[index]) return a[index] > b[index] ? 1 : -1;
  }
  return 0;
}

export default function ForceUpdate() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  const [version, setVersion] = useState<ForceUpdateConfig>(() => ({
    ...DEFAULT_FORCE_UPDATE,
    ...(config.appVersion || {}),
    updateMessage: config.appVersion?.updateMessage || DEFAULT_FORCE_UPDATE.updateMessage,
    storeUrls: { ...DEFAULT_FORCE_UPDATE.storeUrls, ...(config.appVersion?.storeUrls || {}) },
  }));
  const [error, setError] = useState("");
  const versionWarning = compareVersions(version.minVersion, version.latestVersion) > 0;

  const handleSave = async () => {
    if (!/^\d+\.\d+\.\d+$/.test(version.minVersion) || !/^\d+\.\d+\.\d+$/.test(version.latestVersion)) {
      setError("Use versões no formato X.Y.Z.");
      return;
    }
    if (versionWarning) {
      setError("A versão mínima não pode ser maior que a última versão.");
      return;
    }
    if (version.forceUpdate && !version.storeUrls.android && !version.storeUrls.ios) {
      setError("Informe pelo menos um link de loja.");
      return;
    }
    const next = { ...config, appVersion: version };
    setConfig(next);
    await saveConfig(next);
    setError("");
    toast.success("Configuração de atualização salva.");
  };

  return (
    <SettingsPage title="Atualização do app" description="Defina versões aceitas e links das lojas." icon={Smartphone} actions={<Button onClick={handleSave} disabled={isSaving || versionWarning}>Salvar alterações</Button>}>
      {error && <div className="flex items-center gap-2 rounded-md border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800"><AlertTriangle className="h-4 w-4" />{error}</div>}
      <SettingsSection title="Controle de versão" description="Bloqueie versões abaixo da mínima quando necessário.">
        <div className="flex items-center justify-between gap-4"><div><Label htmlFor="forceUpdate">Forçar atualização</Label><p className="text-xs text-muted-foreground">O usuário precisará atualizar antes de continuar.</p></div><Switch id="forceUpdate" checked={version.forceUpdate} onCheckedChange={(forceUpdate) => setVersion({ ...version, forceUpdate })} /></div>
        <div className="mt-4 grid gap-4 sm:grid-cols-2"><div className="space-y-1.5"><Label htmlFor="minVersion">Versão mínima</Label><Input id="minVersion" value={version.minVersion} onChange={(event) => setVersion({ ...version, minVersion: event.target.value })} /></div><div className="space-y-1.5"><Label htmlFor="latestVersion">Última versão</Label><Input id="latestVersion" value={version.latestVersion} onChange={(event) => setVersion({ ...version, latestVersion: event.target.value })} /></div></div>
      </SettingsSection>
      <SettingsSection title="Mensagem" description="Texto exibido quando a atualização for exigida.">
        <div className="grid gap-4"><div className="space-y-1.5"><Label htmlFor="updateTitle">Título</Label><Input id="updateTitle" value={version.updateMessage.pt_BR.title} onChange={(event) => setVersion({ ...version, updateMessage: { pt_BR: { ...version.updateMessage.pt_BR, title: event.target.value } } })} /></div><div className="space-y-1.5"><Label htmlFor="updateMessage">Mensagem</Label><Textarea id="updateMessage" value={version.updateMessage.pt_BR.message} onChange={(event) => setVersion({ ...version, updateMessage: { pt_BR: { ...version.updateMessage.pt_BR, message: event.target.value } } })} /></div><div className="space-y-1.5"><Label htmlFor="buttonText">Texto do botão</Label><Input id="buttonText" value={version.updateMessage.pt_BR.buttonText} onChange={(event) => setVersion({ ...version, updateMessage: { pt_BR: { ...version.updateMessage.pt_BR, buttonText: event.target.value } } })} /></div></div>
      </SettingsSection>
      <SettingsSection title="Lojas" description="Destinos usados pelo botão de atualização.">
        <div className="grid gap-4 sm:grid-cols-2"><div className="space-y-1.5"><Label htmlFor="androidStore">Google Play</Label><Input id="androidStore" value={version.storeUrls.android} onChange={(event) => setVersion({ ...version, storeUrls: { ...version.storeUrls, android: event.target.value } })} placeholder="https://play.google.com/store/apps/details?id=..." /></div><div className="space-y-1.5"><Label htmlFor="iosStore">App Store</Label><Input id="iosStore" value={version.storeUrls.ios} onChange={(event) => setVersion({ ...version, storeUrls: { ...version.storeUrls, ios: event.target.value } })} placeholder="https://apps.apple.com/app/..." /></div></div>
      </SettingsSection>
    </SettingsPage>
  );
}
