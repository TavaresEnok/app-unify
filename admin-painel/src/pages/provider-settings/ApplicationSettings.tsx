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
    <SettingsSection title="Servidor de teste de velocidade" description="Opcional: deixe em branco para usar automaticamente o servidor Ookla Speedtest do seu provedor (ou o mais próximo do cliente). Se preferir, informe sua URL Speedtest (ex.: https://speedtest.seuprovedor.com.br:8080) ou ookla:ID.">
      <Label htmlFor="speedTestUrl">URL ou ID Ookla do servidor</Label>
      <Input id="speedTestUrl" type="text" placeholder="Automático (ou ookla:43431 / https://speedtest.seuprovedor.com.br:8080)" value={config.other?.speedTestUrl || ""} onChange={event => update("speedTestUrl", event.target.value)} />
    </SettingsSection>
  </SettingsPage>;
}
