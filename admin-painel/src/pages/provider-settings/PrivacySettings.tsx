import { useSettings } from "@/contexts/SettingsContext";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { SettingsPage, SettingsSection } from "@/components/settings/SettingsPage";

export default function PrivacySettings() {
  const { config, setConfig } = useSettings();
  return <SettingsPage title="Privacidade" description="Defina a política de privacidade disponibilizada no aplicativo.">
    <SettingsSection title="Política de privacidade">
      <Label htmlFor="privacyPolicyUrl">URL da política de privacidade</Label>
      <Input id="privacyPolicyUrl" type="url" placeholder="https://seuprovedor.com/privacidade" value={config.other?.privacyPolicyUrl || ""}
        onChange={event => setConfig(previous => ({ ...previous, other: { ...previous.other, privacyPolicyUrl: event.target.value } }))} />
    </SettingsSection>
  </SettingsPage>;
}
