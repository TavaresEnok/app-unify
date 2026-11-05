import { useSettings } from "@/contexts/SettingsContext";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { SettingsPage, SettingsSection } from "@/components/settings/SettingsPage";

export default function ApplicationSettings() {
  const { config, setConfig } = useSettings();
  const update = (key: string, value: string) => setConfig(previous => ({ ...previous, other: { ...previous.other, [key]: value } }));
  return <SettingsPage title="Configurações do aplicativo" description="Configure os endereços usados pelo aplicativo.">
    <SettingsSection title="Domínio personalizado">
      <Label htmlFor="customDomain">Domínio (opcional)</Label>
      <Input id="customDomain" placeholder="app.seuprovedor.com" value={config.other?.customDomain || ""} onChange={event => update("customDomain", event.target.value)} />
    </SettingsSection>
    <SettingsSection title="Servidor de teste de velocidade" description="Endereço do servidor próprio usado para medições no aplicativo.">
      <Label htmlFor="speedTestUrl">URL do servidor</Label>
      <Input id="speedTestUrl" type="url" placeholder="https://velocidade.seuprovedor.com" value={config.other?.speedTestUrl || ""} onChange={event => update("speedTestUrl", event.target.value)} />
    </SettingsSection>
  </SettingsPage>;
}
